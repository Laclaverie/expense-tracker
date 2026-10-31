import 'package:core/core.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'database.dart';
import 'statement_days.dart';

/// Statistics scope: one institution in one currency, or one cash wallet.
/// Never mixed. Optionally narrowed to one account of the institution.
class Scope {
  const Scope(this.institution, {this.currency, this.accountId});

  final String institution;

  /// Currency of the scope's accounts (`cash`: which wallet). Null only in
  /// tests and callers that don't need the filter.
  final String? currency;

  /// One account only; null = every account of the institution.
  final int? accountId;

  /// The whole institution or wallet (targets are set per institution).
  Scope get whole => Scope(institution, currency: currency);

  Scope withAccount(int? accountId) => Scope(institution, currency: currency, accountId: accountId);

  String get id {
    final base = currency == null ? institution : '$institution-$currency';
    return accountId == null ? base : '$base#$accountId';
  }

  @override
  bool operator ==(Object other) => other is Scope && other.id == id;

  @override
  int get hashCode => id.hashCode;

  /// SQL condition on an `accounts` table aliased `a`.
  String get _where =>
      'a.institution = ?${currency == null ? '' : ' AND a.currency = ?'}${accountId == null ? '' : ' AND a.id = ?'}';
  List<Variable> get _vars => [
    Variable.withString(institution),
    if (currency != null) Variable.withString(currency!),
    if (accountId != null) Variable.withInt(accountId!),
  ];
}

class TxnView {
  const TxnView(this.txn, this.account, this.merchant, [this.splits = const []]);

  final Txn txn;
  final Account account;
  final Merchant? merchant;

  /// Empty unless the transaction is split across categories.
  final List<Split> splits;

  bool get isSplit => splits.isNotEmpty;

  String get displayName => merchant?.name ?? txn.description;
}

class TxnFilter {
  const TxnFilter({
    this.scope,
    this.from,
    this.to,
    this.accountId,
    this.categoryId,
    this.merchantId,
    this.search,
    this.onlyReview = false,
  });

  final Scope? scope;
  final DateTime? from;

  /// Exclusive.
  final DateTime? to;
  final int? accountId;

  /// A category, or a group (matches its children).
  final String? categoryId;
  final int? merchantId;
  final String? search;
  final bool onlyReview;
}

/// Amount per key (category, group or merchant), spending as a positive number.
class Amount {
  const Amount(this.key, this.label, this.cents, {this.count = 0, this.month});

  final String key;
  final String label;
  final int cents;
  final int count;

  /// `2026-09` for monthly series.
  final String? month;
}

const _spendingKinds = "('expense', 'fee', 'refund')";

/// Transactions as statistics see them: one row per split for split
/// transactions, one row per transaction otherwise. Aliased `t`.
const _lines =
    '(SELECT t.id, t.account_id, t.date, t.kind, t.merchant_id, t.description, t.is_person, t.anomaly_ok, '
    'COALESCE(s.category_id, t.category_id) AS category_id, COALESCE(s.amount, t.amount) AS amount '
    'FROM transactions t LEFT JOIN splits s ON s.transaction_id = t.id) t';

class ExpenseRepository {
  ExpenseRepository(this.db);

  final ExpenseDatabase db;

  // ------------------------------------------------------------ reference data

  Stream<List<CategoryRow>> watchCategories() =>
      (db.select(db.categories)..orderBy([(c) => OrderingTerm(expression: c.sortOrder)])).watch();

  Stream<List<Account>> watchAccounts() => (db.select(
    db.accounts,
  )..orderBy([(a) => OrderingTerm(expression: a.institution), (a) => OrderingTerm(expression: a.id)])).watch();

  /// Scopes that have accounts: one per institution and currency (cash
  /// wallets included), banks first.
  Stream<List<Scope>> watchScopes() => watchAccounts().map((accounts) {
    final scopes = <Scope>{};
    for (final a in accounts) {
      scopes.add(Scope(a.institution, currency: a.currency));
    }
    return scopes.toList()..sort((a, b) => (a.institution == 'cash' ? 1 : 0) - (b.institution == 'cash' ? 1 : 0));
  });

  /// Sum of transactions per account (the balance of cash wallets, which have no statements).
  Stream<Map<int, int>> watchAccountTotals() {
    final sum = db.transactions.amount.sum();
    return (db.selectOnly(db.transactions)
          ..addColumns([db.transactions.accountId, sum])
          ..groupBy([db.transactions.accountId]))
        .watch()
        .map((rows) => {for (final r in rows) r.read(db.transactions.accountId)!: r.read(sum) ?? 0});
  }

  /// Date of the most recent transaction, if any.
  Future<DateTime?> latestTransactionDate() async {
    final max = db.transactions.date.max();
    return (db.selectOnly(db.transactions)..addColumns([max])).map((r) => r.read(max)).getSingle();
  }

  Stream<List<Statement>> watchStatements() =>
      (db.select(db.statements)..orderBy([(s) => OrderingTerm.desc(s.periodEnd)])).watch();

  /// Groups of imported statements that are the same statement (same type and
  /// statement date) — should always be empty since imports refuse them, but
  /// lets the user verify the history.
  Stream<List<List<Statement>>> watchDuplicateStatements() => watchStatements().map((all) {
    final groups = <String, List<Statement>>{};
    for (final st in all) {
      groups.putIfAbsent('${st.format}|${st.periodEnd.toIso8601String()}', () => []).add(st);
    }
    return [
      for (final g in groups.values)
        if (g.length > 1) g,
    ];
  });

  /// Days covered by imported statements, per statement format, for
  /// [scope]. Empty for cash wallets (manual entries, no statements). For one
  /// account, only the formats of the statements that list it.
  Stream<Map<String, List<DayRange>>> watchCoverage(Scope scope) =>
      (db.select(db.statements)..where((st) => st.institution.equals(scope.institution))).watch().asyncMap((
        rows,
      ) async {
        if (scope.institution == 'cash') return const <String, List<DayRange>>{};
        final ranges = _coverage(rows);
        if (scope.accountId == null) return ranges;
        final formats = await _formatsOf(scope.accountId!);
        return {
          for (final e in ranges.entries)
            if (formats.contains(e.key)) e.key: e.value,
        };
      });

  /// Days covered per statement format, whatever file type each statement
  /// came from (a card PDF chains from the previous closing date, a card CSV
  /// covers its own dates).
  Map<String, List<DayRange>> _coverage(List<Statement> rows) {
    final days = statementDays(rows);
    final byFormat = <String, List<DayRange>>{};
    for (final st in rows) {
      byFormat.putIfAbsent(st.format, () => []).add(days[st.id]!);
    }
    return byFormat;
  }

  /// Statement formats that listed lines of account [accountId].
  Future<Set<String>> _formatsOf(int accountId) async => {
    for (final r
        in await db
            .customSelect(
              'SELECT DISTINCT s.format AS f FROM transactions t JOIN statements s ON s.id = t.statement_id '
              'WHERE t.account_id = ?',
              variables: [Variable.withInt(accountId)],
            )
            .get())
      r.read<String>('f'),
  };

  Stream<List<RuleRow>> watchRules() => db.select(db.rules).watch();

  // -------------------------------------------------------------- transactions

  Stream<List<TxnView>> watchTransactions(TxnFilter f) {
    final t = db.transactions, a = db.accounts, m = db.merchants;
    final q = db.select(t).join([
      innerJoin(a, a.id.equalsExp(t.accountId)),
      leftOuterJoin(m, m.id.equalsExp(t.merchantId)),
    ]);
    if (f.scope != null) {
      q.where(a.institution.equals(f.scope!.institution));
      if (f.scope!.currency != null) q.where(a.currency.equals(f.scope!.currency!));
      if (f.scope!.accountId != null) q.where(a.id.equals(f.scope!.accountId!));
    }
    if (f.from != null) q.where(t.date.isBiggerOrEqualValue(f.from!));
    if (f.to != null) q.where(t.date.isSmallerThanValue(f.to!));
    if (f.accountId != null) q.where(t.accountId.equals(f.accountId!));
    if (f.categoryId != null) {
      final c = f.categoryId!;
      final inSplits = db.selectOnly(db.splits)
        ..addColumns([db.splits.id])
        ..where(
          db.splits.transactionId.equalsExp(t.id) &
              (db.splits.categoryId.equals(c) | db.splits.categoryId.like('$c.%')),
        );
      q.where(t.categoryId.equals(c) | t.categoryId.like('$c.%') | existsQuery(inSplits));
    }
    if (f.merchantId != null) q.where(t.merchantId.equals(f.merchantId!));
    if (f.onlyReview) q.where(t.needsReview.equals(true));
    if (f.search != null && f.search!.trim().isNotEmpty) {
      final s = '%${f.search!.trim()}%';
      q.where(t.description.like(s) | m.name.like(s) | t.note.like(s));
    }
    q.orderBy([OrderingTerm.desc(t.date), OrderingTerm.asc(t.createdAt)]);
    return q.watch().asyncMap((rows) async {
      final ids = [for (final r in rows) r.readTable(t).id];
      final splits = <String, List<Split>>{};
      for (var i = 0; i < ids.length; i += 500) {
        final chunk = ids.sublist(i, i + 500 > ids.length ? ids.length : i + 500);
        for (final s in await (db.select(db.splits)..where((s) => s.transactionId.isIn(chunk))).get()) {
          splits.putIfAbsent(s.transactionId, () => []).add(s);
        }
      }
      return [
        for (final r in rows)
          TxnView(r.readTable(t), r.readTable(a), r.readTableOrNull(m), splits[r.readTable(t).id] ?? const []),
      ];
    });
  }

  Stream<int> watchReviewCount() {
    final count = db.transactions.id.count();
    return (db.selectOnly(db.transactions)
          ..addColumns([count])
          ..where(db.transactions.needsReview.equals(true)))
        .watchSingle()
        .map((r) => r.read(count) ?? 0);
  }

  /// Sets a transaction's category by hand. With [rememberForMerchant], future
  /// imports of the same merchant get this category, and so do this merchant's
  /// past transactions not categorized by hand.
  Future<int> setCategory(String txnId, String categoryId, {bool rememberForMerchant = false}) =>
      db.transaction(() async {
        final txn = await (db.select(db.transactions)..where((t) => t.id.equals(txnId))).getSingle();
        await (db.delete(db.splits)..where((s) => s.transactionId.equals(txnId))).go();
        await (db.update(db.transactions)..where((t) => t.id.equals(txnId))).write(
          TransactionsCompanion(
            categoryId: Value(categoryId),
            confidence: const Value('user'),
            needsReview: const Value(false),
            updatedAt: Value(DateTime.now()),
          ),
        );
        if (!rememberForMerchant || txn.merchantId == null) return 1;
        await (db.update(
          db.merchants,
        )..where((m) => m.id.equals(txn.merchantId!))).write(MerchantsCompanion(categoryId: Value(categoryId)));
        final others =
            await (db.update(db.transactions)..where(
                  (t) =>
                      t.merchantId.equals(txn.merchantId!) &
                      t.confidence.equals('user').not() &
                      t.kind.isIn([TransactionKind.expense.name, TransactionKind.refund.name]),
                ))
                .write(
                  TransactionsCompanion(
                    categoryId: Value(categoryId),
                    confidence: Value(Confidence.merchant.name),
                    needsReview: const Value(false),
                    updatedAt: Value(DateTime.now()),
                  ),
                );
        return 1 + others;
      });

  /// Splits a transaction across categories. [parts] are `(categoryId, cents)`
  /// with cents positive for spending; they must add up to the transaction's
  /// amount. An empty list removes the split.
  Future<void> setSplits(String txnId, List<(String, int)> parts) => db.transaction(() async {
    final txn = await (db.select(db.transactions)..where((t) => t.id.equals(txnId))).getSingle();
    final sign = txn.amount < 0 ? -1 : 1;
    final total = parts.fold(0, (s, p) => s + p.$2);
    if (parts.isNotEmpty && total != txn.amount.abs()) {
      throw ArgumentError('Split parts add up to $total, transaction is ${txn.amount.abs()}');
    }
    await (db.delete(db.splits)..where((s) => s.transactionId.equals(txnId))).go();
    for (final (category, cents) in parts) {
      await db
          .into(db.splits)
          .insert(SplitsCompanion.insert(transactionId: txnId, categoryId: category, amount: sign * cents));
    }
    await (db.update(db.transactions)..where((t) => t.id.equals(txnId))).write(
      TransactionsCompanion(
        confidence: const Value('user'),
        needsReview: const Value(false),
        updatedAt: Value(DateTime.now()),
      ),
    );
  });

  /// Gives [categoryId] to several transactions at once (a choice made by hand
  /// in the review queue): same as [setCategory] without remembering merchants.
  Future<int> setCategoryMany(List<String> txnIds, String categoryId) => db.transaction(() async {
    await (db.delete(db.splits)..where((s) => s.transactionId.isIn(txnIds))).go();
    return (db.update(db.transactions)..where((t) => t.id.isIn(txnIds))).write(
      TransactionsCompanion(
        categoryId: Value(categoryId),
        confidence: const Value('user'),
        needsReview: const Value(false),
        updatedAt: Value(DateTime.now()),
      ),
    );
  });

  /// Accepts the suggested category of several transactions; those without a
  /// precise category (none, or only a group) stay in review.
  Future<int> confirmMany(List<String> txnIds) =>
      (db.update(db.transactions)..where((t) => t.id.isIn(txnIds) & t.categoryId.like('%.%'))).write(
        TransactionsCompanion(needsReview: const Value(false), updatedAt: Value(DateTime.now())),
      );

  /// The spending categories used most over the [days] before the latest
  /// transaction (reviewed lines only), most used first: offered first in the
  /// category picker.
  Future<List<String>> frequentCategories({int limit = 8, int days = 365}) async {
    final t = db.transactions;
    final latest = t.date.max();
    final end = (await (db.selectOnly(t)..addColumns([latest])).getSingle()).read(latest);
    if (end == null) return const [];
    final count = t.id.count();
    final q = db.selectOnly(t)
      ..addColumns([t.categoryId, count])
      ..where(
        t.categoryId.like('%.%') &
            t.needsReview.equals(false) &
            t.kind.isIn([TransactionKind.expense.name, TransactionKind.refund.name]) &
            t.date.isBiggerOrEqualValue(end.subtract(Duration(days: days))),
      )
      ..groupBy([t.categoryId])
      ..orderBy([OrderingTerm.desc(count), OrderingTerm.asc(t.categoryId)])
      ..limit(limit);
    return [for (final r in await q.get()) r.read(t.categoryId)!];
  }

  /// Marks a merchant's lines of one day as normal (or not): an alert about
  /// them goes away and they no longer count in the usual amount.
  Future<int> setAnomalyOk(int merchantId, DateTime day, bool ok) =>
      (db.update(db.transactions)..where((t) => t.merchantId.equals(merchantId) & t.date.equals(day))).write(
        TransactionsCompanion(anomalyOk: Value(ok), updatedAt: Value(DateTime.now())),
      );

  /// Accepts the suggested category.
  Future<void> confirm(String txnId) => (db.update(db.transactions)..where((t) => t.id.equals(txnId))).write(
    TransactionsCompanion(needsReview: const Value(false), updatedAt: Value(DateTime.now())),
  );

  Future<void> setKind(String txnId, TransactionKind kind) =>
      (db.update(db.transactions)..where((t) => t.id.equals(txnId))).write(
        TransactionsCompanion(kind: Value(kind.name), updatedAt: Value(DateTime.now())),
      );

  Future<void> setNote(String txnId, String? note) => (db.update(db.transactions)..where((t) => t.id.equals(txnId)))
      .write(TransactionsCompanion(note: Value(note), updatedAt: Value(DateTime.now())));

  /// Cash (or any) expense typed by hand. [amount] is positive for spending.
  Future<String> addManual({
    required int accountId,
    required DateTime date,
    required int amount,
    required String categoryId,
    String? merchantName,
    String? note,
    bool isIncome = false,
  }) async {
    final id = const Uuid().v4();
    int? merchantId;
    if (merchantName != null && merchantName.trim().isNotEmpty) {
      final m = normalizeMerchant(merchantName);
      final existing = await (db.select(db.merchants)..where((t) => t.key.equals(m.key))).getSingleOrNull();
      merchantId =
          existing?.id ??
          await db.into(db.merchants).insert(MerchantsCompanion.insert(key: m.key, name: merchantName.trim()));
    }
    final now = DateTime.now();
    await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            id: id,
            accountId: accountId,
            date: date,
            amount: isIncome ? amount : -amount,
            description: merchantName?.trim() ?? '',
            kind: (isIncome ? TransactionKind.income : TransactionKind.expense).name,
            merchantId: Value(merchantId),
            categoryId: Value(categoryId),
            confidence: 'user',
            needsReview: false,
            note: Value(note),
            source: 'manual',
            createdAt: now,
            updatedAt: now,
          ),
        );
    return id;
  }

  Future<void> deleteTransaction(String txnId) =>
      (db.delete(db.transactions)..where((t) => t.id.equals(txnId) & t.source.equals('manual'))).go();

  /// Removes a statement and every transaction it created.
  Future<void> deleteStatement(int statementId) => db.transaction(() async {
    await (db.delete(db.transactions)..where((t) => t.statementId.equals(statementId))).go();
    await (db.delete(db.statements)..where((s) => s.id.equals(statementId))).go();
  });

  // ------------------------------------------------------------------- targets

  Stream<List<TargetRow>> watchTargets(Scope scope) =>
      (db.select(db.targets)
            ..where((t) => t.scope.equals(scope.id))
            ..orderBy([(t) => OrderingTerm(expression: t.period), (t) => OrderingTerm(expression: t.categoryId)]))
          .watch();

  /// Creates or replaces the target for ([scope], [categoryId], [period]).
  Future<void> saveTarget(Scope scope, String? categoryId, TargetPeriod period, int cents) => db.transaction(() async {
    await (db.delete(db.targets)..where(
          (t) =>
              t.scope.equals(scope.id) &
              t.period.equals(period.name) &
              (categoryId == null ? t.categoryId.isNull() : t.categoryId.equals(categoryId)),
        ))
        .go();
    await db
        .into(db.targets)
        .insert(
          TargetsCompanion.insert(
            scope: scope.id,
            categoryId: Value(categoryId),
            period: period.name,
            amount: cents,
            createdAt: DateTime.now(),
          ),
        );
  });

  Future<void> deleteTarget(int id) => (db.delete(db.targets)..where((t) => t.id.equals(id))).go();

  // ---------------------------------------------------------------- categories

  /// Adds a category to group [parentId], or a new group when null. Returns its id.
  Future<String> addCategory({String? parentId, required String nameFr, String? nameEn}) async {
    final suffix = 'u${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';
    final parent = parentId == null
        ? null
        : await (db.select(db.categories)..where((c) => c.id.equals(parentId))).getSingle();
    final count = await db.categories.count().getSingle();
    final id = parent == null ? suffix : '${parent.id}.$suffix';
    await db
        .into(db.categories)
        .insert(
          CategoriesCompanion.insert(
            id: id,
            parentId: Value(parent?.id),
            nameFr: nameFr.trim(),
            nameEn: (nameEn == null || nameEn.trim().isEmpty ? nameFr : nameEn).trim(),
            type: parent?.type ?? CategoryType.expense.name,
            color: parent?.color ?? 0xFF757575,
            sortOrder: 1000 + count,
          ),
        );
    return id;
  }

  Future<void> renameCategory(String id, {required String nameFr, required String nameEn}) =>
      (db.update(db.categories)..where((c) => c.id.equals(id))).write(
        CategoriesCompanion(nameFr: Value(nameFr.trim()), nameEn: Value(nameEn.trim())),
      );

  /// Transactions (or split parts) using [id], or any category of group [id].
  Future<int> categoryUsage(String id) async {
    final r = await db
        .customSelect(
          'SELECT (SELECT COUNT(*) FROM transactions WHERE category_id = ?1 OR category_id LIKE ?2) + '
          '(SELECT COUNT(*) FROM splits WHERE category_id = ?1 OR category_id LIKE ?2) AS n',
          variables: [Variable.withString(id), Variable.withString('$id.%')],
          readsFrom: {db.transactions, db.splits},
        )
        .getSingle();
    return r.read<int>('n');
  }

  /// Hides a category (or a group and its categories). Transactions, split
  /// parts, merchants, rules and targets using it move to [moveTo]; without
  /// [moveTo] the category must be unused (rules and targets on it are removed).
  Future<void> archiveCategory(String id, {String? moveTo}) => db.transaction(() async {
    if (moveTo == null && await categoryUsage(id) > 0) {
      throw StateError('Category $id is used; choose where to move its transactions');
    }
    final ids = [id, for (final c in await (db.select(db.categories)..where((c) => c.parentId.equals(id))).get()) c.id];
    for (final c in ids) {
      await db.moveCategoryReferences(c, moveTo);
    }
    await (db.update(
      db.categories,
    )..where((c) => c.id.isIn(ids))).write(const CategoriesCompanion(archived: Value(true)));
  });

  // --------------------------------------------------------------------- rules

  Future<int> addRule({required String categoryId, String? descriptionContains, String? merchantKey, String? code}) =>
      db
          .into(db.rules)
          .insert(
            RulesCompanion.insert(
              categoryId: categoryId,
              descriptionContains: Value(descriptionContains),
              merchantKey: Value(merchantKey),
              code: Value(code),
              createdAt: DateTime.now(),
            ),
          );

  Future<void> deleteRule(int id) => (db.delete(db.rules)..where((r) => r.id.equals(id))).go();

  /// Merchants with a category chosen by the user.
  Stream<List<Merchant>> watchRememberedMerchants() =>
      (db.select(db.merchants)
            ..where((m) => m.categoryId.isNotNull())
            ..orderBy([(m) => OrderingTerm(expression: m.name)]))
          .watch();

  /// Stops applying a remembered category to future imports.
  Future<void> forgetMerchant(int merchantId) => (db.update(
    db.merchants,
  )..where((m) => m.id.equals(merchantId))).write(const MerchantsCompanion(categoryId: Value(null)));

  Future<void> renameMerchant(int merchantId, String name) =>
      (db.update(db.merchants)..where((m) => m.id.equals(merchantId))).write(MerchantsCompanion(name: Value(name)));

  // --------------------------------------------------------------------- stats

  /// Spending per category in [scope] between [from] and [to] (exclusive).
  Stream<List<Amount>> watchSpendingByCategory(Scope scope, DateTime from, DateTime to, {String lang = 'fr'}) => db
      .customSelect(
        'SELECT c.id AS k, c.name_${lang == 'fr' ? 'fr' : 'en'} AS label, -SUM(t.amount) AS cents, COUNT(*) AS n '
        'FROM $_lines JOIN accounts a ON a.id = t.account_id '
        'LEFT JOIN categories c ON c.id = t.category_id '
        'WHERE ${scope._where} AND t.kind IN $_spendingKinds AND t.date >= ? AND t.date < ? '
        'GROUP BY c.id ORDER BY cents DESC',
        variables: [...scope._vars, Variable.withDateTime(from), Variable.withDateTime(to)],
        readsFrom: {db.transactions, db.splits, db.accounts, db.categories},
      )
      .watch()
      .map(
        (rows) => [
          for (final r in rows)
            Amount(
              r.read<String?>('k') ?? '',
              r.read<String?>('label') ?? '',
              r.read<int>('cents'),
              count: r.read<int>('n'),
            ),
        ],
      );

  /// Spending per category group per month.
  Stream<List<Amount>> watchMonthlyByGroup(Scope scope, DateTime from, DateTime to, {String lang = 'fr'}) => db
      .customSelect(
        "SELECT substr(t.date, 1, 7) AS month, COALESCE(g.id, '') AS k, "
        'g.name_${lang == 'fr' ? 'fr' : 'en'} AS label, -SUM(t.amount) AS cents '
        'FROM $_lines JOIN accounts a ON a.id = t.account_id '
        'LEFT JOIN categories c ON c.id = t.category_id '
        'LEFT JOIN categories g ON g.id = COALESCE(c.parent_id, c.id) '
        'WHERE ${scope._where} AND t.kind IN $_spendingKinds AND t.date >= ? AND t.date < ? '
        'GROUP BY month, k ORDER BY month, cents DESC',
        variables: [...scope._vars, Variable.withDateTime(from), Variable.withDateTime(to)],
        readsFrom: {db.transactions, db.splits, db.accounts, db.categories},
      )
      .watch()
      .map(
        (rows) => [
          for (final r in rows)
            Amount(
              r.read<String>('k'),
              r.read<String?>('label') ?? '',
              r.read<int>('cents'),
              month: r.read<String>('month'),
            ),
        ],
      );

  Stream<List<Amount>> watchTopMerchants(Scope scope, DateTime from, DateTime to, {int limit = 10}) => db
      .customSelect(
        'SELECT m.id AS k, COALESCE(m.name, t.description) AS label, -SUM(t.amount) AS cents, COUNT(*) AS n '
        'FROM transactions t JOIN accounts a ON a.id = t.account_id '
        'LEFT JOIN merchants m ON m.id = t.merchant_id '
        'WHERE ${scope._where} AND t.kind IN $_spendingKinds AND t.date >= ? AND t.date < ? AND NOT t.is_person '
        'GROUP BY COALESCE(m.id, t.description) ORDER BY cents DESC LIMIT ?',
        variables: [...scope._vars, Variable.withDateTime(from), Variable.withDateTime(to), Variable.withInt(limit)],
        readsFrom: {db.transactions, db.accounts, db.merchants},
      )
      .watch()
      .map(
        (rows) => [
          for (final r in rows)
            Amount(
              '${r.read<int?>('k') ?? ''}',
              r.read<String>('label'),
              r.read<int>('cents'),
              count: r.read<int>('n'),
            ),
        ],
      );

  /// Spending lines `(date, categoryId, cents spent)` in [scope] — split-aware
  /// input for target progress.
  Stream<List<(DateTime, String?, int)>> watchSpendingLines(Scope scope, DateTime from, DateTime to) => db
      .customSelect(
        'SELECT t.date AS d, t.category_id AS c, -t.amount AS cents FROM $_lines '
        'JOIN accounts a ON a.id = t.account_id '
        'WHERE ${scope._where} AND t.kind IN $_spendingKinds AND t.date >= ? AND t.date < ?',
        variables: [...scope._vars, Variable.withDateTime(from), Variable.withDateTime(to)],
        readsFrom: {db.transactions, db.splits, db.accounts},
      )
      .watch()
      .map((rows) => [for (final r in rows) (r.read<DateTime>('d'), r.read<String?>('c'), r.read<int>('cents'))]);

  /// Spending lines with their merchant, split-aware, for the statistics page.
  Stream<List<SpendLine>> watchSpendingDetail(Scope scope, DateTime from, DateTime to) => db
      .customSelect(
        'SELECT t.date AS d, t.category_id AS c, t.merchant_id AS mid, COALESCE(m.name, t.description) AS mn, '
        '-t.amount AS cents, t.is_person AS p, t.account_id AS acc, t.anomaly_ok AS ok FROM $_lines '
        'JOIN accounts a ON a.id = t.account_id LEFT JOIN merchants m ON m.id = t.merchant_id '
        'WHERE ${scope._where} AND t.kind IN $_spendingKinds AND t.date >= ? AND t.date < ?',
        variables: [...scope._vars, Variable.withDateTime(from), Variable.withDateTime(to)],
        readsFrom: {db.transactions, db.splits, db.accounts, db.merchants},
      )
      .watch()
      .map(
        (rows) => [
          for (final r in rows)
            SpendLine(
              date: r.read<DateTime>('d'),
              cents: r.read<int>('cents'),
              categoryId: r.read<String?>('c'),
              merchantId: r.read<int?>('mid'),
              merchant: r.read<String>('mn'),
              isPerson: r.read<bool>('p'),
              accountId: r.read<int>('acc'),
              anomalyOk: r.read<bool>('ok'),
            ),
        ],
      );

  /// Date of the most recent transaction in [scope], if any.
  Stream<DateTime?> watchLatestDate(Scope scope) => db
      .customSelect(
        'SELECT MAX(t.date) AS d FROM transactions t JOIN accounts a ON a.id = t.account_id WHERE ${scope._where}',
        variables: scope._vars,
        readsFrom: {db.transactions, db.accounts},
      )
      .watch()
      .map((rows) => rows.single.read<DateTime?>('d'));

  /// Spending and income totals per month: `(month, spending, income)`.
  Stream<List<(String, int, int)>> watchMonthlyTotals(Scope scope, DateTime from, DateTime to) => db
      .customSelect(
        "SELECT substr(t.date, 1, 7) AS month, "
        "-SUM(CASE WHEN t.kind IN $_spendingKinds THEN t.amount ELSE 0 END) AS spending, "
        "SUM(CASE WHEN t.kind IN ('income', 'interest') THEN t.amount ELSE 0 END) AS income "
        'FROM transactions t JOIN accounts a ON a.id = t.account_id '
        'WHERE ${scope._where} AND t.date >= ? AND t.date < ? GROUP BY month ORDER BY month',
        variables: [...scope._vars, Variable.withDateTime(from), Variable.withDateTime(to)],
        readsFrom: {db.transactions, db.accounts},
      )
      .watch()
      .map((rows) => [for (final r in rows) (r.read<String>('month'), r.read<int>('spending'), r.read<int>('income'))]);

  /// Month-end balances and money in / out per month for the accounts of
  /// [scope] that hold money (checking, savings, registered), walked back from
  /// each account's last statement balance over the months statements cover.
  Stream<List<(Account, List<MonthBalance>)>> watchBalanceHistory(Scope scope) => db
      .customSelect(
        'SELECT t.account_id AS id, t.date AS d, t.amount AS amount, t.kind AS kind FROM transactions t '
        'JOIN accounts a ON a.id = t.account_id WHERE ${scope._where}',
        variables: scope._vars,
        readsFrom: {db.transactions, db.accounts, db.statements},
      )
      .watch()
      .asyncMap((rows) async {
        const kept = [AccountType.checking, AccountType.savings, AccountType.registered];
        final accounts =
            await (db.select(db.accounts)
                  ..where(
                    (a) =>
                        a.institution.equals(scope.institution) &
                        a.type.isIn(kept.map((t) => t.name)) &
                        (scope.currency == null ? const Constant(true) : a.currency.equals(scope.currency!)) &
                        (scope.accountId == null ? const Constant(true) : a.id.equals(scope.accountId!)),
                  )
                  ..orderBy([(a) => OrderingTerm(expression: a.id)]))
                .get();
        final statements = await (db.select(
          db.statements,
        )..where((st) => st.institution.equals(scope.institution))).get();
        final coverage = _coverage(statements);
        Future<List<DayRange>> covered(int accountId) async => [
          for (final f in await _formatsOf(accountId)) ...?coverage[f],
        ];
        final byAccount = <int, List<BalanceLine>>{};
        for (final r in rows) {
          byAccount
              .putIfAbsent(r.read<int>('id'), () => [])
              .add(
                BalanceLine(
                  r.read<DateTime>('d'),
                  r.read<int>('amount'),
                  TransactionKind.values.byName(r.read<String>('kind')),
                ),
              );
        }
        final out = <(Account, List<MonthBalance>)>[];
        for (final a in accounts) {
          if (a.balance == null || a.balanceDate == null) continue;
          out.add((
            a,
            balanceHistory(
              balance: a.balance!,
              balanceDate: a.balanceDate!,
              lines: byAccount[a.id] ?? const [],
              covered: await covered(a.id),
            ),
          ));
        }
        return out;
      });
}
