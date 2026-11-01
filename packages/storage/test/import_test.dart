import 'dart:convert';
import 'dart:io';

import 'package:core/core.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:banks/desjardins.dart';
import 'package:banks/plugin.dart' show TextInput;
import 'package:pdf_words/pdf_words.dart';
import 'package:storage/storage.dart';
import 'package:test/test.dart';

const fixtures = '../banks/test/fixtures/desjardins';

ImportedStatement load(String name) => toImported(
  parseStatement(
    DocumentWords.fromJson(jsonDecode(File('$fixtures/$name').readAsStringSync()) as Map<String, dynamic>),
  ),
);

List<String> allFixtures() =>
    Directory(fixtures)
        .listSync()
        .map((f) => f.uri.pathSegments.last)
        .where((n) => n.endsWith('.synthetic.json'))
        .toList()
      ..sort();

void main() {
  late ExpenseDatabase db;
  late ImportService importer;
  late ExpenseRepository repo;

  setUp(() {
    db = ExpenseDatabase(NativeDatabase.memory());
    importer = ImportService(db);
    repo = ExpenseRepository(db);
  });
  tearDown(() => db.close());

  Future<ImportResult> import(String name, {String? hash}) =>
      importer.importStatement(load(name), fileHash: hash ?? name, fileName: name);

  Future<int> count([Expression<bool> Function($TransactionsTable t)? where]) async {
    final q = db.select(db.transactions);
    if (where != null) q.where(where);
    return (await q.get()).length;
  }

  test('imports all statements, categorizes, pairs card payments', () async {
    var lines = 0, review = 0, paired = 0;
    for (final name in allFixtures()) {
      final r = await import(name);
      expect(r.status, ImportStatus.imported, reason: name);
      expect(r.duplicateCount, 0, reason: name);
      lines += r.newCount;
      review += r.reviewCount;
      paired += r.transferCount;
    }
    expect(lines, allFixtures().fold(0, (n, f) => n + load(f).lines.length)); // every line of every statement
    // + one cash wallet credit per ATM withdrawal
    final atm = await count(
      (t) => t.code.equals('IRGA') & t.source.equals('statement') & t.amount.isSmallerThanValue(0),
    );
    expect(await count(), lines + atm);

    // Card payments from checking (Apr–Sep) find the card's "PAIEMENT CAISSE";
    // September's is on the October card statement (new layout).
    final payments = await (db.select(
      db.transactions,
    )..where((t) => t.code.equals('PWW') & t.kind.equals('transfer'))).get();
    expect(payments.where((p) => p.transferGroup != null), hasLength(payments.length));
    expect(paired, greaterThanOrEqualTo(payments.length));

    // Most lines are categorized automatically.
    final uncategorized = await count((t) => t.categoryId.isNull());
    expect(uncategorized / lines, lessThan(0.3));
    expect(review, lessThan(lines));
  });

  test('accounts, balances and cash wallet', () async {
    for (final name in allFixtures()) {
      await import(name);
    }
    final accounts = await db.select(db.accounts).get();
    expect(
      accounts.map((a) => (a.institution, a.ref)),
      containsAll([('desjardins', 'EOP'), ('desjardins', 'card-0001'), ('cash', 'cash-CAD')]),
    );
    final eop = accounts.singleWhere((a) => a.ref == 'EOP');
    expect((eop.balance, eop.balanceDate), (890170, DateTime.utc(2026, 9, 30)));
    final cash = accounts.singleWhere((a) => a.ref == 'cash-CAD');
    final cashLines = await (db.select(db.transactions)..where((t) => t.accountId.equals(cash.id))).get();
    expect(cashLines, isNotEmpty);
    expect(cashLines.every((l) => l.amount > 0 && l.transferGroup != null), isTrue);
  });

  test('the same statement is refused: same file renamed, re-downloaded file, same lines', () async {
    await import('desjardins-card-2026-09.synthetic.json');

    // Same bytes under another name.
    final renamed = await importer.importStatement(
      load('desjardins-card-2026-09.synthetic.json'),
      fileHash: 'desjardins-card-2026-09.synthetic.json',
      fileName: 'copie de releve.pdf',
    );
    expect((renamed.status, renamed.duplicateReason), (ImportStatus.alreadyImported, DuplicateReason.sameFile));
    expect(renamed.existing!.fileName, 'desjardins-card-2026-09.synthetic.json');

    // Different bytes (downloaded again), same statement date.
    final redownloaded = await import('desjardins-card-2026-09.synthetic.json', hash: 'other-hash');
    expect(
      (redownloaded.status, redownloaded.duplicateReason),
      (ImportStatus.alreadyImported, DuplicateReason.sameStatement),
    );

    // Same lines, unknown statement date (e.g. an export of the same period).
    final s = load('desjardins-card-2026-09.synthetic.json');
    final shifted = ImportedStatement(
      institution: s.institution,
      format: s.format,
      periodStart: s.periodStart,
      periodEnd: s.periodEnd.add(const Duration(days: 1)),
      accounts: s.accounts,
      lines: s.lines,
      failedChecks: const [],
      checkCount: s.checkCount,
    );
    final sameLines = await importer.importStatement(shifted, fileHash: 'third', fileName: 'export.pdf');
    expect((sameLines.status, sameLines.duplicateReason), (ImportStatus.alreadyImported, DuplicateReason.sameLines));

    expect(await db.select(db.statements).get(), hasLength(1));
    expect(await repo.watchDuplicateStatements().first, isEmpty);
  });

  test('a CSV export downloaded again: known lines skipped, new ones added, even on the same last day', () async {
    const older =
        'Caisse ACME,1234567,EOP,2026/10/02,00011,Achat /ACME CORP,"",12.34,"","","","","","",987.66,""\n'
        'Caisse ACME,1234567,EOP,2026/10/01,00010,Paie /ACME CORP,"","",1000.00,"","","","","",1000.00,""\n';
    const newer =
        'Caisse ACME,1234567,EOP,2026/10/02,00012,Achat /ACME INC,"",7.66,"","","","","","",980.00,""\n'
        '$older';
    Future<ImportResult> importCsv(String text, String hash) => importer.importStatement(
      const DesjardinsImporter().read(TextInput('export.csv', text, fileType: 'csv')),
      fileHash: hash,
      fileName: 'export.csv',
      fileType: 'csv',
    );
    expect((await importCsv(older, 'a')).newCount, 2);
    final again = await importCsv(newer, 'b');
    expect((again.status, again.newCount, again.duplicateCount), (ImportStatus.imported, 1, 2));
    expect((await importCsv(newer, 'c')).duplicateReason, DuplicateReason.sameLines);
    expect(await count(), 3);
    // Two exports ending on the same day are not the same statement: no
    // "imported several times" warning (deleting one would lose its new lines).
    expect(await repo.watchDuplicateStatements().first, isEmpty);
  });

  test('statement failing its checks writes nothing', () async {
    final s = load('desjardins-card-2026-09.synthetic.json');
    final broken = ImportedStatement(
      institution: s.institution,
      format: s.format,
      periodStart: s.periodStart,
      periodEnd: s.periodEnd,
      accounts: s.accounts,
      lines: s.lines,
      failedChecks: ['FAIL new balance'],
      checkCount: s.checkCount,
    );
    final r = await importer.importStatement(broken, fileHash: 'x', fileName: 'x');
    expect(r.status, ImportStatus.invalid);
    expect(r.failedChecks, ['FAIL new balance']);
    expect(await count(), 0);
    expect(await db.select(db.statements).get(), isEmpty);
  });

  test('categorizing a merchant once applies to its other lines and future imports', () async {
    await import('desjardins-card-2026-09.synthetic.json');
    final tim = await (db.select(db.transactions)..where((t) => t.description.like('IGA %'))).get();
    expect(tim, isNotEmpty);
    expect(tim.first.categoryId, 'food.groceries'); // seed
    final changed = await repo.setCategory(tim.first.id, 'food.restaurants', rememberForMerchant: true);
    expect(changed, tim.length);
    await import('desjardins-card-2026-08.synthetic.json');
    final all = await (db.select(db.transactions)..where((t) => t.description.like('IGA %'))).get();
    expect(all.length, greaterThan(tim.length));
    expect(all.every((t) => t.categoryId == 'food.restaurants' && !t.needsReview), isTrue);
  });

  test('stats per scope: spending excludes transfers and income', () async {
    for (final name in allFixtures()) {
      await import(name);
    }
    const scope = Scope('desjardins');
    final from = DateTime.utc(2026, 9, 1), to = DateTime.utc(2026, 10, 1);
    final byCategory = await repo.watchSpendingByCategory(scope, from, to).first;
    final total = byCategory.fold(0, (s, a) => s + a.cents);
    final expected = await db
        .customSelect(
          "SELECT -SUM(amount) AS s FROM transactions WHERE kind IN ('expense','fee','refund') "
          'AND account_id IN (SELECT id FROM accounts WHERE institution = ?) AND date >= ? AND date < ?',
          variables: [Variable.withString('desjardins'), Variable.withDateTime(from), Variable.withDateTime(to)],
        )
        .getSingle();
    expect(total, expected.read<int>('s'));
    expect(byCategory.map((a) => a.key), isNot(contains('excluded.card_payment')));
    final monthly = await repo.watchMonthlyTotals(scope, DateTime.utc(2026, 1, 1), to).first;
    expect(monthly.map((m) => m.$1), contains('2026-09'));
    final top = await repo.watchTopMerchants(scope, from, to, limit: 5).first;
    expect(top, hasLength(5));
    expect(top.first.cents, greaterThanOrEqualTo(top.last.cents));
    // Interac transfers (rent, friends) count as spending but are not merchants.
    expect(top.map((m) => m.label), everyElement(isNot(startsWith('Personne'))));
    expect(byCategory.map((a) => a.key), containsAll(['housing.rent', 'people.sent']));
  });

  test('review queue: bulk category and confirm by hand; frequent categories', () async {
    for (final name in allFixtures()) {
      await import(name);
    }
    final review = await repo.watchTransactions(const TxnFilter(onlyReview: true)).first;
    expect(review.length, greaterThan(3));
    final picked = [for (final v in review.take(2)) v.txn.id];
    expect(await repo.setCategoryMany(picked, 'shopping.gifts'), 2);
    final after = await repo.watchTransactions(const TxnFilter(onlyReview: true)).first;
    expect(after.map((v) => v.txn.id), isNot(contains(picked.first)));
    expect(after, hasLength(review.length - 2));
    final gift = await (db.select(db.transactions)..where((t) => t.id.equals(picked.first))).getSingle();
    expect((gift.categoryId, gift.confidence, gift.needsReview), ('shopping.gifts', 'user', false));

    // Confirming keeps lines without a precise category in the queue.
    final groupOnly = after.where((v) => v.txn.categoryId == null || !v.txn.categoryId!.contains('.'));
    final confirmed = await repo.confirmMany([for (final v in after) v.txn.id]);
    expect(confirmed, after.length - groupOnly.length);
    expect(await repo.watchReviewCount().first, groupOnly.length);

    final frequent = await repo.frequentCategories(limit: 3);
    expect(frequent, hasLength(3));
    expect(frequent.every((c) => c.contains('.')), isTrue);
  });

  test('the classifier learns from reviewed lines only, and at once', () async {
    for (final name in allFixtures()) {
      await import(name);
    }
    final reviewed = await reviewedLines(db).get();
    final inReview = await repo.watchTransactions(const TxnFilter(onlyReview: true)).first;
    expect(reviewed, isNotEmpty);
    expect(reviewed.length + inReview.length, lessThanOrEqualTo(await count()));
    for (final v in inReview) {
      expect(reviewed.where((r) => r.$1 == v.txn.description && r.$3 == v.txn.categoryId), isEmpty);
    }

    final learning = watchClassifier(db);
    final before = (await learning.first).lineCount;
    await repo.setCategory(inReview.first.txn.id, 'shopping.gifts');
    expect((await learning.first).lineCount, before + 1);
  });

  test('manual cash entry', () async {
    final wallet = await importer.cashWallet('EUR');
    await repo.addManual(
      accountId: wallet,
      date: DateTime.utc(2026, 10, 1),
      amount: 450,
      categoryId: 'food.coffee',
      merchantName: 'Café de Flore',
    );
    final rows = await repo.watchTransactions(const TxnFilter(scope: Scope('cash', currency: 'EUR'))).first;
    expect(rows.single.txn.amount, -450);
    expect(rows.single.displayName, 'Café de Flore');
    expect(rows.single.txn.kind, TransactionKind.expense.name);
  });

  test('splits: stats use the parts, filters find them, sums are enforced', () async {
    await import('desjardins-card-2026-02.synthetic.json');
    final costco = (await (db.select(db.transactions)..where((t) => t.description.like('COSTCO%'))).get()).first;
    expect(costco.categoryId, 'food.groceries');
    final groceries = -costco.amount - 5000;
    await repo.setSplits(costco.id, [('food.groceries', groceries), ('health.medical', 5000)]);

    final from = DateTime.utc(costco.date.year, costco.date.month),
        to = DateTime.utc(costco.date.year, costco.date.month + 1);
    final byCategory = {
      for (final a in await repo.watchSpendingByCategory(const Scope('desjardins'), from, to).first) a.key: a.cents,
    };
    expect(byCategory['health.medical'], 5000);
    final lines = await repo.watchSpendingLines(const Scope('desjardins'), from, to).first;
    expect(lines.where((l) => l.$2 == 'health.medical').single.$3, 5000);

    final found = await repo.watchTransactions(const TxnFilter(categoryId: 'health.medical')).first;
    expect(found.single.txn.id, costco.id);
    expect(found.single.splits.map((s) => s.amount), [-groceries, -5000]);

    expect(() => repo.setSplits(costco.id, [('food.groceries', 100)]), throwsArgumentError);
    await repo.setCategory(costco.id, 'shopping.other'); // a single category replaces the split
    expect(await db.select(db.splits).get(), isEmpty);
  });

  test('targets: one per scope, category and period', () async {
    const scope = Scope('desjardins');
    await repo.saveTarget(scope, 'food', TargetPeriod.month, 50000);
    await repo.saveTarget(scope, 'food', TargetPeriod.month, 45000); // replaces
    await repo.saveTarget(scope, null, TargetPeriod.month, 300000);
    await repo.saveTarget(scope, null, TargetPeriod.week, 70000);
    await repo.saveTarget(const Scope('cash', currency: 'CAD'), null, TargetPeriod.month, 20000);
    final targets = await repo.watchTargets(scope).first;
    expect(targets.map((t) => (t.categoryId, t.period, t.amount)), [
      (null, 'month', 300000),
      ('food', 'month', 45000),
      (null, 'week', 70000),
    ]);
    await repo.deleteTarget(targets.first.id);
    expect(await repo.watchTargets(scope).first, hasLength(2));
  });

  test('categories: add, rename, archive with move; new defaults present', () async {
    final all = await db.select(db.categories).get();
    expect(all.map((c) => c.id), containsAll(['food.fast_food', 'sport.gym', 'government.taxes', 'leisure.festivals']));
    expect(all.map((c) => c.id), isNot(contains('finance.government')));

    final group = await repo.addCategory(nameFr: 'Animaux', nameEn: 'Pets');
    final vet = await repo.addCategory(parentId: group, nameFr: 'Vétérinaire');
    expect(vet, startsWith('$group.'));
    final row = await (db.select(db.categories)..where((c) => c.id.equals(vet))).getSingle();
    expect((row.nameEn, row.parentId, row.type), ('Vétérinaire', group, 'expense'));
    await repo.renameCategory(vet, nameFr: 'Vétérinaire', nameEn: 'Vet');

    await import('desjardins-card-2026-09.synthetic.json');
    final line = (await db.select(db.transactions).get()).firstWhere((t) => t.kind == 'expense');
    await repo.setCategory(line.id, vet);
    await repo.saveTarget(const Scope('desjardins'), vet, TargetPeriod.month, 10000);
    expect(await repo.categoryUsage(group), 1);
    expect(() => repo.archiveCategory(group), throwsStateError);
    await repo.archiveCategory(group, moveTo: 'shopping.other');
    final moved = await (db.select(db.transactions)..where((t) => t.id.equals(line.id))).getSingle();
    expect(moved.categoryId, 'shopping.other');
    expect((await repo.watchTargets(const Scope('desjardins')).first).single.categoryId, 'shopping.other');
    final archived = await (db.select(db.categories)..where((c) => c.id.isIn([group, vet]))).get();
    expect(archived.every((c) => c.archived), isTrue);
  });

  test('refreshAutomaticCategories moves automatic lines, never user choices', () async {
    await import('desjardins-card-2026-09.synthetic.json');
    final mcdo = (await (db.select(db.transactions)..where((t) => t.description.like('A&W%'))).get()).first;
    expect(mcdo.categoryId, 'food.fast_food');
    // Simulate a line categorized by an older version, and one set by the user.
    await (db.update(
      db.transactions,
    )..where((t) => t.id.equals(mcdo.id))).write(const TransactionsCompanion(categoryId: Value('food.restaurants')));
    final roots = (await (db.select(
      db.transactions,
    )..where((t) => t.description.like('A&W%').not() & t.kind.equals('expense'))).get()).first;
    await repo.setCategory(roots.id, 'shopping.gifts');

    expect(await importer.refreshAutomaticCategories(), greaterThanOrEqualTo(1));
    final after = await (db.select(db.transactions)..where((t) => t.id.isIn([mcdo.id, roots.id]))).get();
    expect({for (final t in after) t.id: t.categoryId}, {mcdo.id: 'food.fast_food', roots.id: 'shopping.gifts'});
    expect(await importer.refreshAutomaticCategories(), 0); // stable

    // A merchant saved under an older name format is recognized with today's rules.
    await (db.update(db.transactions)..where((t) => t.id.equals(mcdo.id))).write(
      const TransactionsCompanion(categoryId: Value(null), confidence: Value('none')),
    );
    await (db.update(db.merchants)..where((m) => m.id.equals(mcdo.merchantId!))).write(
      const MerchantsCompanion(key: Value("MCDONALD'S OLD KEY"), name: Value("Mcdonald's #29020")),
    );
    await importer.refreshAutomaticCategories();
    final again = await (db.select(db.transactions)..where((t) => t.id.equals(mcdo.id))).getSingle();
    expect(again.categoryId, 'food.fast_food');
  });

  test('a refund takes the category of the purchase it gives back', () async {
    ImportedLine line(int day, int cents, TransactionKind kind, String shop) => ImportedLine(
      accountRef: 'card',
      date: DateTime.utc(2026, 10, day),
      amount: cents,
      description: shop,
      kind: kind,
      merchantText: shop,
    );
    ImportedStatement statement(List<ImportedLine> lines, int day) => ImportedStatement(
      institution: 'desjardins',
      format: 'desjardins-card',
      periodStart: DateTime.utc(2026, 10, 1),
      periodEnd: DateTime.utc(2026, 10, day),
      accounts: const [ImportedAccount(ref: 'card', name: 'Card', type: AccountType.creditCard, currency: 'CAD')],
      lines: lines,
      failedChecks: const [],
      checkCount: 1,
    );
    await importer.importStatement(
      statement([
        line(3, -5000, TransactionKind.expense, 'ACME SHOP'),
        line(4, -900, TransactionKind.expense, 'ACME SHOP'),
      ], 5),
      fileHash: 'a',
      fileName: 'a',
    );
    Future<Txn> byAmount(int cents) => (db.select(db.transactions)..where((t) => t.amount.equals(cents))).getSingle();
    // Not reviewed yet: the refund has nothing to follow and waits for review.
    await importer.importStatement(
      statement([line(10, 5000, TransactionKind.refund, 'ACME SHOP')], 10),
      fileHash: 'b',
      fileName: 'b',
    );
    expect((await byAmount(5000)).categoryId, isNull);

    await repo.setCategory((await byAmount(-5000)).id, 'shopping.clothing');
    await repo.setCategory((await byAmount(-900)).id, 'shopping.gifts');
    expect(await importer.refreshAutomaticCategories(), 1);
    final refund = await byAmount(5000);
    expect((refund.categoryId, refund.confidence, refund.needsReview), ('shopping.clothing', 'purchase', false));

    // The purchase moved: the refund follows at the next refresh.
    await repo.setCategory((await byAmount(-5000)).id, 'shopping.electronics');
    await importer.refreshAutomaticCategories();
    expect((await byAmount(5000)).categoryId, 'shopping.electronics');

    // A partial refund: the latest purchase at least as large.
    await importer.importStatement(
      statement([line(12, 500, TransactionKind.refund, 'ACME SHOP')], 12),
      fileHash: 'c',
      fileName: 'c',
    );
    expect((await byAmount(500)).categoryId, 'shopping.gifts');
  });

  test('spending detail: split-aware lines with merchants and people', () async {
    for (final name in allFixtures()) {
      await import(name);
    }
    const scope = Scope('desjardins');
    final from = DateTime.utc(2026, 9), to = DateTime.utc(2026, 10);
    final lines = await repo.watchSpendingDetail(scope, from, to).first;
    final byCategory = await repo.watchSpendingByCategory(scope, from, to).first;
    expect(lines.fold(0, (s, l) => s + l.cents), byCategory.fold(0, (s, a) => s + a.cents));
    expect(lines.where((l) => l.isPerson), isNotEmpty);
    final netflix = lines.firstWhere((l) => l.merchant == 'Netflix');
    final rows = await repo.watchTransactions(TxnFilter(merchantId: netflix.merchantId)).first;
    expect(rows.every((r) => r.merchant!.name == 'Netflix'), isTrue);
  });

  test('coverage: account statements by period, card statements chained', () async {
    for (final name in allFixtures()) {
      await import(name);
    }
    final cov = await repo.watchCoverage(const Scope('desjardins')).first;
    expect(cov.keys, containsAll(['desjardins-account', 'desjardins-card']));
    final account = cov['desjardins-account']!;
    expect(monthCoverage(account, DateTime.utc(2026, 4)).full, isTrue);
    expect(monthCoverage(account, DateTime.utc(2026, 6)).none, isTrue); // June statement not in fixtures
    expect(monthCoverage(account, DateTime.utc(2026, 3)).none, isTrue);
    final card = cov['desjardins-card']!;
    expect(monthCoverage(card, DateTime.utc(2026, 6)).full, isTrue);
    expect(monthCoverage(card, DateTime.utc(2026, 9)).full, isTrue);
    expect(monthCoverage(card, DateTime.utc(2026, 10)).coveredUntil, DateTime.utc(2026, 10, 20));
    expect(await repo.watchCoverage(const Scope('cash', currency: 'CAD')).first, isEmpty);
  });

  test('one account: spending, transactions and coverage narrowed to it', () async {
    for (final name in allFixtures()) {
      await import(name);
    }
    final accounts = await db.select(db.accounts).get();
    final eop = accounts.singleWhere((a) => a.ref == 'EOP');
    final card = accounts.singleWhere((a) => a.type == AccountType.creditCard.name);
    const all = Scope('desjardins');
    final from = DateTime.utc(2026), to = DateTime.utc(2026, 10);
    Future<int> spent(Scope s) async =>
        (await repo.watchSpendingDetail(s, from, to).first).fold<int>(0, (t, l) => t + l.cents);
    expect(await spent(all), await spent(all.withAccount(eop.id)) + await spent(all.withAccount(card.id)));
    final rows = await repo.watchTransactions(TxnFilter(scope: all.withAccount(card.id))).first;
    expect(rows.every((r) => r.account.id == card.id), isTrue);
    expect((await repo.watchCoverage(all.withAccount(card.id)).first).keys, ['desjardins-card']);
    expect((await repo.watchCoverage(all.withAccount(eop.id)).first).keys, ['desjardins-account']);
    expect(all.withAccount(eop.id).whole, all);
  });

  test('balance history: accounts holding money, walked back from the last statement', () async {
    for (final name in allFixtures()) {
      await import(name);
    }
    final history = await repo.watchBalanceHistory(const Scope('desjardins')).first;
    expect(history.map((h) => h.$1.ref), ['EOP', 'ET 1', 'ET 2']);
    final (eop, months) = history.first;
    expect(months.last.closing, eop.balance);
    // Fixtures miss March and June: history starts after the last gap.
    expect(months.first.month, DateTime.utc(2026, 7));
    for (final (i, m) in months.indexed.skip(1)) {
      expect(m.closing, months[i - 1].closing + m.net);
    }
  });

  test('older Desjardins codes are reclassified; user choices kept; ATM withdrawals credit cash', () async {
    await import('desjardins-account-2026-09.synthetic.json');
    final eop = await (db.select(db.accounts)..where((a) => a.ref.equals('EOP'))).getSingle();
    Future<void> add(String id, String code, int amount, String kind, {String confidence = 'none'}) => db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            id: id,
            accountId: eop.id,
            date: DateTime.utc(2022, 6, 7),
            amount: amount,
            description: code,
            code: Value(code),
            kind: kind,
            confidence: confidence,
            needsReview: true,
            source: 'statement',
            fingerprint: Value('fp-$id'),
            createdAt: DateTime.utc(2022),
            updatedAt: DateTime.utc(2022),
          ),
        );
    await add('dmd', 'DMD', 50000, 'refund');
    await add('rga', 'RGA', -40000, 'expense');
    await add('ivmw', 'IVMW', 2500, 'refund', confidence: 'user');
    await add('kept', 'BNI', 186, 'income');
    await db.reclassifyOlderDesjardinsCodes();
    Future<Txn> get(String id) => (db.select(db.transactions)..where((t) => t.id.equals(id))).getSingle();
    final dmd = await get('dmd');
    expect((dmd.kind, dmd.categoryId, dmd.needsReview), ('income', 'income.other', false));
    final ivmw = await get('ivmw');
    expect((ivmw.kind, ivmw.categoryId, ivmw.isPerson), ('income', null, true));
    expect((await get('kept')).kind, 'income');
    final rga = await get('rga');
    expect(rga.kind, 'transfer');
    expect(rga.transferGroup, isNotNull);
    final cash = await (db.select(db.transactions)..where((t) => t.fingerprint.equals('fp-rga-cash'))).getSingle();
    expect((cash.amount, cash.transferGroup), (40000, rga.transferGroup));
    await db.reclassifyOlderDesjardinsCodes(); // idempotent
    expect(await count((t) => t.fingerprint.equals('fp-rga-cash')), 1);
  });

  test('scopes carry their currency; coverage of one account comes from the statements that list it', () async {
    for (final name in allFixtures()) {
      await import(name);
    }
    final scopes = await repo.watchScopes().first;
    expect(scopes.map((s) => s.id), ['desjardins-CAD', 'cash-CAD']);
    final share = await (db.select(db.accounts)..where((a) => a.ref.equals('CS'))).getSingle();
    // The qualifying share never has a line: no statement format to require.
    expect(await repo.watchCoverage(scopes.first.withAccount(share.id)).first, isEmpty);
    final statements = await db.select(db.statements).get();
    expect(statements.where((s) => s.coversSincePrevious).map((s) => s.format).toSet(), {'desjardins-card'});
  });
}
