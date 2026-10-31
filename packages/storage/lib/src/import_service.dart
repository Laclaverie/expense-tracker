import 'package:core/core.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'database.dart';
import 'dev_copy.dart' show devCopyTable;
import 'statement_days.dart';

const _uuid = Uuid();

enum ImportStatus {
  imported,

  /// Already imported — see [DuplicateReason]. Nothing written.
  alreadyImported,

  /// The statement failed its own checks. Nothing written.
  invalid,
}

/// Why a file was recognized as already imported.
enum DuplicateReason {
  /// Byte-identical file (possibly renamed).
  sameFile,

  /// Same statement (type and statement date) from a different file, e.g.
  /// downloaded again from the bank.
  sameStatement,

  /// Every line is already in the database (e.g. the same lines exported again).
  sameLines,
}

class ImportResult {
  const ImportResult(
    this.status, {
    this.duplicateReason,
    this.existing,
    this.newCount = 0,
    this.duplicateCount = 0,
    this.reviewCount = 0,
    this.transferCount = 0,
    this.failedChecks = const [],
    this.unmatchedCount = 0,
    this.verified = true,
  });

  final ImportStatus status;

  /// Set when [status] is [ImportStatus.alreadyImported].
  final DuplicateReason? duplicateReason;

  /// The earlier statement this file duplicates (null for [DuplicateReason.sameLines]).
  final Statement? existing;
  final int newCount;

  /// Lines already in the database (overlapping or re-exported statement).
  final int duplicateCount;

  /// New lines waiting in the review queue.
  final int reviewCount;

  /// Transfers paired with their other side during this import.
  final int transferCount;
  final List<String> failedChecks;

  /// New lines on days a file of another type (PDF vs CSV) already covered for
  /// the same account, with no line of the same date and amount there:
  /// imported, but worth a look (one of the two readers may have missed it).
  final int unmatchedCount;

  /// False when the file had nothing to check its lines against.
  final bool verified;
}

/// Writes imported statements into the database.
class ImportService {
  ImportService(this.db, {DateTime Function()? clock}) : _now = clock ?? DateTime.now;

  final ExpenseDatabase db;
  final DateTime Function() _now;

  /// Imports [s], read from a file of [fileType] (`pdf`, `csv`…). A text
  /// export covers the dates its owner picked: its period doesn't identify a
  /// statement (two downloads on one day end on the same date, with new lines
  /// in the second), so only its lines are compared with what is stored.
  Future<ImportResult> importStatement(
    ImportedStatement s, {
    required String fileHash,
    required String fileName,
    String fileType = 'pdf',
  }) async {
    final sameFile = await (db.select(db.statements)..where((t) => t.fileHash.equals(fileHash))).getSingleOrNull();
    if (sameFile != null) {
      return ImportResult(ImportStatus.alreadyImported, duplicateReason: DuplicateReason.sameFile, existing: sameFile);
    }
    final sameStatement = fileType == 'pdf' ? await findSameStatement(s.format, s.periodEnd) : null;
    if (sameStatement != null) {
      return ImportResult(
        ImportStatus.alreadyImported,
        duplicateReason: DuplicateReason.sameStatement,
        existing: sameStatement,
      );
    }
    if (!s.isValid) return ImportResult(ImportStatus.invalid, failedChecks: s.failedChecks);
    if (s.lines.isNotEmpty && await _allLinesKnown(s)) {
      return const ImportResult(ImportStatus.alreadyImported, duplicateReason: DuplicateReason.sameLines);
    }

    return db.transaction(() async {
      final now = _now();
      final accountIds = {for (final a in s.accounts) a.ref: await _upsertAccount(s, a)};
      final statementId = await db
          .into(db.statements)
          .insert(
            StatementsCompanion.insert(
              institution: s.institution,
              format: s.format,
              periodStart: s.periodStart,
              periodEnd: s.periodEnd,
              coversSincePrevious: Value(s.coversSincePrevious),
              fileHash: fileHash,
              fileName: fileName,
              importedAt: now,
              lineCount: s.lines.length,
              newCount: 0,
              fileType: Value(fileType),
              verified: Value(s.checkCount > 0),
            ),
          );

      // The same lines read from another file type (a PDF statement and a CSV
      // export of the same days) have other descriptions, so other
      // fingerprints: inside the days the other file covers, a line is the
      // one of the same account, date and amount (each matched once).
      final elsewhere = await _daysFromOtherFileTypes(s.institution, fileType);
      final matched = <String>{};

      final categorizer = await _categorizer();
      final occ = occurrences([for (final l in s.lines) (l.accountRef, l.date, l.amount, l.description)]);
      var added = 0, duplicates = 0, review = 0, unmatched = 0;
      for (final (i, line) in s.lines.indexed) {
        final fingerprint = lineFingerprint(
          institution: s.institution,
          accountRef: line.accountRef,
          date: line.date,
          amount: line.amount,
          description: line.description,
          occurrence: occ[i],
        );
        final exists = await (db.select(db.transactions)..where((t) => t.fingerprint.equals(fingerprint))).get();
        if (exists.isNotEmpty) {
          duplicates++;
          continue;
        }
        final accountId = accountIds[line.accountRef]!;
        if (insideDays(line.date, elsewhere[accountId] ?? const [])) {
          final same = await _sameLineElsewhere(accountId, line, fileType, matched);
          if (same != null) {
            matched.add(same);
            duplicates++;
            continue;
          }
          unmatched++;
        }
        final merchant = normalizeMerchant(line.merchantText);
        final merchantId = await _upsertMerchant(merchant);
        final suggestion = await _withPurchase(line, accountId, merchantId, categorizer.categorize(line, merchant));
        final isGroup = suggestion.categoryId != null && !suggestion.categoryId!.contains('.');
        final needsReview = suggestion.categoryId == null || isGroup || suggestion.needsReview;
        if (needsReview) review++;
        final id = _uuid.v4();
        await db
            .into(db.transactions)
            .insert(
              TransactionsCompanion.insert(
                id: id,
                accountId: accountIds[line.accountRef]!,
                date: line.date,
                postedDate: Value(line.postedDate),
                amount: line.amount,
                description: line.description,
                code: Value(line.code),
                location: Value(line.location),
                bonusRate: Value(line.bonusRate),
                foreignCents: Value(line.foreignCents),
                foreignCurrency: Value(line.foreignCurrency),
                fxRate: Value(line.fxRate),
                card: Value(line.card),
                isPerson: Value(line.isPerson),
                kind: line.kind.name,
                merchantId: Value(merchantId),
                categoryId: Value(suggestion.categoryId),
                confidence: suggestion.confidence.name,
                needsReview: needsReview,
                source: 'statement',
                statementId: Value(statementId),
                fingerprint: Value(fingerprint),
                createdAt: now,
                updatedAt: now,
              ),
            );
        added++;
        if (line.categoryHint == 'excluded.cash_withdrawal') {
          await _creditCashWallet(line, id, fingerprint, statementId, now);
        }
      }
      await (db.update(
        db.statements,
      )..where((t) => t.id.equals(statementId))).write(StatementsCompanion(newCount: Value(added)));
      final paired = await matchPendingTransfers(s.institution);
      return ImportResult(
        ImportStatus.imported,
        newCount: added,
        duplicateCount: duplicates,
        reviewCount: review,
        transferCount: paired,
        unmatchedCount: unmatched,
        verified: s.checkCount > 0,
      );
    });
  }

  /// Days covered for each account by statements of [institution] read from
  /// another file type than [fileType].
  Future<Map<int, List<DayRange>>> _daysFromOtherFileTypes(String institution, String fileType) async {
    final statements = await (db.select(db.statements)..where((t) => t.institution.equals(institution))).get();
    final days = statementDays(statements);
    final other = {
      for (final st in statements)
        if (st.fileType != fileType) st.id,
    };
    if (other.isEmpty) return const {};
    final out = <int, List<DayRange>>{};
    final rows = await db
        .customSelect(
          'SELECT DISTINCT account_id AS a, statement_id AS s FROM transactions WHERE statement_id IS NOT NULL',
        )
        .get();
    for (final r in rows) {
      final st = r.read<int>('s');
      if (other.contains(st)) out.putIfAbsent(r.read<int>('a'), () => []).add(days[st]!);
    }
    return out;
  }

  /// Id of a stored line of [accountId] with [line]'s date and amount, read
  /// from another file type than [fileType], not in [taken].
  Future<String?> _sameLineElsewhere(int accountId, ImportedLine line, String fileType, Set<String> taken) async {
    final q =
        db.select(db.transactions).join([
            innerJoin(db.statements, db.statements.id.equalsExp(db.transactions.statementId)),
          ])
          ..where(
            db.transactions.accountId.equals(accountId) &
                db.transactions.date.equals(line.date) &
                db.transactions.amount.equals(line.amount) &
                db.statements.fileType.equals(fileType).not() &
                db.transactions.id.isNotIn(taken),
          )
          ..limit(1);
    return (await q.getSingleOrNull())?.readTable(db.transactions).id;
  }

  /// Re-runs categorization on lines the app categorized by itself (seed
  /// merchants, keywords, Bonidollars hint, nothing), so improved defaults and
  /// new categories apply to past imports. Lines set by the user, remembered
  /// merchants, rules and bank-implied categories are left alone.
  /// Returns how many lines changed.
  ///
  /// Not on an anonymized developer copy ([writeDevCopy]): its descriptions
  /// were rewritten, it keeps the categories the owner had.
  Future<int> refreshAutomaticCategories() => db.transaction(() async {
    final devCopy = await db
        .customSelect(
          "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = ?",
          variables: [Variable(devCopyTable)],
        )
        .get();
    if (devCopy.isNotEmpty) return 0;
    final categorizer = await _categorizer();
    final automatic = [
      Confidence.purchase,
      Confidence.seed,
      Confidence.keyword,
      Confidence.hint,
      Confidence.none,
    ].map((c) => c.name);
    final rows =
        await (db.select(db.transactions).join([
              leftOuterJoin(db.merchants, db.merchants.id.equalsExp(db.transactions.merchantId)),
            ])..where(
              db.transactions.confidence.isIn(automatic) &
                  db.transactions.kind.isIn([TransactionKind.expense.name, TransactionKind.refund.name]),
            ))
            .get();
    var changed = 0;
    for (final r in rows) {
      final t = r.readTable(db.transactions);
      final m = r.readTableOrNull(db.merchants);
      // Re-normalized with today's rules (e.g. a newly known chain).
      final merchant = normalizeMerchant(m?.name ?? t.description);
      final line = ImportedLine(
        accountRef: '',
        date: t.date,
        amount: t.amount,
        description: t.description,
        kind: TransactionKind.values.byName(t.kind),
        merchantText: merchant.display,
        code: t.code,
        bonusRate: t.bonusRate,
      );
      final s = t.merchantId == null
          ? categorizer.categorize(line, merchant)
          : await _withPurchase(line, t.accountId, t.merchantId!, categorizer.categorize(line, merchant));
      if (s.categoryId == t.categoryId && s.confidence.name == t.confidence) continue;
      final isGroup = s.categoryId != null && !s.categoryId!.contains('.');
      await (db.update(db.transactions)..where((x) => x.id.equals(t.id))).write(
        TransactionsCompanion(
          categoryId: Value(s.categoryId),
          confidence: Value(s.confidence.name),
          needsReview: Value(s.categoryId == null || isGroup || s.needsReview),
        ),
      );
      changed++;
    }
    return changed;
  });

  /// A statement of the same type with the same statement date (one
  /// Desjardins member account and one card per format).
  Future<Statement?> findSameStatement(String format, DateTime periodEnd) =>
      (db.select(db.statements)
            ..where((t) => t.format.equals(format) & t.periodEnd.equals(periodEnd))
            ..limit(1))
          .getSingleOrNull();

  List<String> _fingerprints(ImportedStatement s) {
    final occ = occurrences([for (final l in s.lines) (l.accountRef, l.date, l.amount, l.description)]);
    return [
      for (final (i, l) in s.lines.indexed)
        lineFingerprint(
          institution: s.institution,
          accountRef: l.accountRef,
          date: l.date,
          amount: l.amount,
          description: l.description,
          occurrence: occ[i],
        ),
    ];
  }

  Future<bool> _allLinesKnown(ImportedStatement s) async {
    final fingerprints = _fingerprints(s);
    final known = await (db.select(db.transactions)..where((t) => t.fingerprint.isIn(fingerprints))).get();
    return known.length == fingerprints.length;
  }

  Future<int> _upsertAccount(ImportedStatement s, ImportedAccount a) async {
    final existing = await (db.select(
      db.accounts,
    )..where((t) => t.institution.equals(s.institution) & t.ref.equals(a.ref))).getSingleOrNull();
    final newerBalance =
        a.closingBalance != null && (existing?.balanceDate == null || !s.periodEnd.isBefore(existing!.balanceDate!));
    final balance = newerBalance
        ? AccountsCompanion(balance: Value(a.closingBalance), balanceDate: Value(s.periodEnd))
        : const AccountsCompanion();
    final same = existing?.id ?? await _sameCardAccount(s, a);
    if (same != null) {
      await (db.update(db.accounts)..where((t) => t.id.equals(same))).write(balance);
      return same;
    }
    return db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(
            institution: s.institution,
            ref: a.ref,
            name: a.name,
            type: a.type.name,
            currency: a.currency,
            balance: balance.balance,
            balanceDate: balance.balanceDate,
          ),
        );
  }

  /// The stored card account [a] is, when its ref is new: a card export
  /// names the card used (`card-<last 4>`), the statements the card account,
  /// whose lines name the card used. Matched both ways; null when no single
  /// account fits.
  Future<int?> _sameCardAccount(ImportedStatement s, ImportedAccount a) async {
    if (a.type != AccountType.creditCard) return null;
    final cards = {
      if (RegExp(r'^card-(\d{4})$').firstMatch(a.ref) case final m?) m[1]!,
      for (final l in s.lines)
        if (l.accountRef == a.ref && l.card != null) l.card!,
    };
    if (cards.isEmpty) return null;
    final marks = List.filled(cards.length, '?').join(',');
    final rows = await db
        .customSelect(
          'SELECT DISTINCT a.id AS id FROM accounts a LEFT JOIN transactions t ON t.account_id = a.id '
          "WHERE a.institution = ? AND a.type = 'creditCard' "
          "AND (t.card IN ($marks) OR a.ref IN ($marks))",
          variables: [
            Variable.withString(s.institution),
            for (final c in cards) Variable.withString(c),
            for (final c in cards) Variable.withString('card-$c'),
          ],
        )
        .get();
    return rows.length == 1 ? rows.single.read<int>('id') : null;
  }

  /// A refund the categorizer can only guess (seed, keyword, nothing) takes
  /// the category of the purchase it gives back: the latest settled purchase
  /// at the same merchant on the same account in the 180 days before, at
  /// least as large (the same amount first). Category and merchant totals
  /// then net the refund out where the purchase counted.
  Future<CategorySuggestion> _withPurchase(
    ImportedLine line,
    int accountId,
    int merchantId,
    CategorySuggestion s,
  ) async {
    if (line.kind != TransactionKind.refund || line.amount <= 0) return s;
    if (s.confidence.index < Confidence.purchase.index) return s;
    final row = await db
        .customSelect(
          'SELECT category_id AS c FROM transactions '
          "WHERE account_id = ? AND merchant_id = ? AND kind = 'expense' AND needs_review = 0 "
          "AND category_id LIKE '%.%' AND amount <= ? AND date <= ? AND date >= ? "
          'ORDER BY CASE WHEN amount = ? THEN 0 ELSE 1 END, date DESC LIMIT 1',
          variables: [
            Variable.withInt(accountId),
            Variable.withInt(merchantId),
            Variable.withInt(-line.amount),
            Variable.withDateTime(line.date),
            Variable.withDateTime(line.date.subtract(const Duration(days: 180))),
            Variable.withInt(-line.amount),
          ],
          readsFrom: {db.transactions},
        )
        .getSingleOrNull();
    final category = row?.read<String>('c');
    return category == null ? s : CategorySuggestion(category, Confidence.purchase);
  }

  Future<int> _upsertMerchant(MerchantName m) async {
    final existing = await (db.select(db.merchants)..where((t) => t.key.equals(m.key))).getSingleOrNull();
    return existing?.id ?? db.into(db.merchants).insert(MerchantsCompanion.insert(key: m.key, name: m.display));
  }

  Future<Categorizer> _categorizer() async {
    final rules = await db.select(db.rules).get();
    final merchants = await (db.select(db.merchants)..where((t) => t.categoryId.isNotNull())).get();
    return Categorizer(
      rules: [
        for (final r in rules)
          Rule(
            id: r.id,
            categoryId: r.categoryId,
            descriptionContains: r.descriptionContains,
            merchantKey: r.merchantKey,
            code: r.code,
          ),
      ],
      merchantCategories: {for (final m in merchants) m.key: m.categoryId!},
    );
  }

  /// ATM withdrawal: the same amount arrives in the cash wallet of that
  /// currency, both sides linked as one transfer.
  Future<void> _creditCashWallet(
    ImportedLine line,
    String withdrawalId,
    String fingerprint,
    int statementId,
    DateTime now,
  ) async {
    final wallet = await cashWallet('CAD');
    final group = _uuid.v4();
    await (db.update(
      db.transactions,
    )..where((t) => t.id.equals(withdrawalId))).write(TransactionsCompanion(transferGroup: Value(group)));
    await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            id: _uuid.v4(),
            accountId: wallet,
            date: line.date,
            amount: -line.amount,
            description: line.description,
            code: Value(line.code),
            kind: TransactionKind.transfer.name,
            categoryId: const Value('excluded.cash_withdrawal'),
            confidence: Confidence.bank.name,
            needsReview: false,
            source: 'statement',
            statementId: Value(statementId),
            fingerprint: Value('$fingerprint-cash'),
            transferGroup: Value(group),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  /// Id of the cash wallet for [currency], created on first use.
  Future<int> cashWallet(String currency) async {
    final ref = 'cash-$currency';
    final existing = await (db.select(
      db.accounts,
    )..where((t) => t.institution.equals('cash') & t.ref.equals(ref))).getSingleOrNull();
    return existing?.id ??
        db
            .into(db.accounts)
            .insert(
              AccountsCompanion.insert(
                institution: 'cash',
                ref: ref,
                name: 'Cash $currency',
                type: AccountType.cash.name,
                currency: currency,
              ),
            );
  }

  /// Pairs unlinked transfers inside [institution] (checking -> card payment,
  /// checking <-> savings). Returns the number of pairs made.
  Future<int> matchPendingTransfers(String institution) async {
    final rows = await db
        .customSelect(
          'SELECT t.id, t.account_id, t.amount, t.date FROM transactions t '
          'JOIN accounts a ON a.id = t.account_id '
          "WHERE t.kind = 'transfer' AND t.transfer_group IS NULL AND a.institution = ?",
          variables: [Variable.withString(institution)],
          readsFrom: {db.transactions, db.accounts},
        )
        .get();
    final candidates = [
      for (final r in rows)
        TransferCandidate(
          r.read<String>('id'),
          r.read<int>('account_id'),
          r.read<int>('amount'),
          r.read<DateTime>('date'),
        ),
    ];
    final pairs = matchTransfers(candidates);
    for (final (a, b) in pairs) {
      final group = _uuid.v4();
      await (db.update(
        db.transactions,
      )..where((t) => t.id.isIn([a.id, b.id]))).write(TransactionsCompanion(transferGroup: Value(group)));
    }
    return pairs.length;
  }
}
