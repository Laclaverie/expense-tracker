// Anonymized developer copy: nothing personal left (allowlist + leak checks),
// everything a developer needs kept (categories, rules, structure, ratios).
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:banks/banks.dart';
import 'package:banks/testing.dart' show loadFixture;
import 'package:core/core.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:storage/storage.dart';
import 'package:test/test.dart';

const owner = 'correct horse battery staple';
const dev = 'developer copy password 2026';

/// Personal texts added on top of the (already anonymized) fixtures.
const note = 'Cadeau pour Ginette Tremblay 514-555-1234';
const secretWords = ['GINETTE', 'TREMBLAY', '5145551234'];

final keepWords = [
  for (final b in banks)
    for (final r in b.lineRules) ...[?r.startsWith, ?r.contains],
];

Map<String, List<Map<String, Object?>>> dump(Database db) => {
  for (final t in ['accounts', 'statements', 'categories', 'merchants', 'rules', 'transactions', 'splits', 'targets'])
    t: [for (final r in db.select('SELECT * FROM $t ORDER BY 1')) Map.of(r)],
};

final uuid = RegExp(r'[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}');

/// Words (upper case, no accents) of a text: letters ≥ 4, digit runs ≥ 5.
Set<String> words(String s) => {
  for (final m in RegExp(r'[A-Z]+|[0-9]+').allMatches(stripAccents(s)))
    if (m[0]!.codeUnitAt(0) >= 65 ? m[0]!.length >= 4 : m[0]!.length >= 5) m[0]!,
};

void main() {
  late Directory dir;
  late File db;
  late File copy;
  late Map<String, List<Map<String, Object?>>> original;
  late DevCopyReport report;

  setUpAll(() async {
    dir = Directory.systemTemp.createTempSync('expenses-devcopy');
    db = File('${dir.path}/expenses.sqlite');
    final edb = openEncryptedDatabase(db, owner);
    final importer = ImportService(edb);
    final files = Directory('../banks/test/fixtures').listSync(recursive: true).whereType<File>().toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    for (final f in files.where((f) => f.path.contains('.synthetic.'))) {
      await importer.importStatement(readStatement(loadFixture(f.path)), fileHash: f.path, fileName: 'releve-mai.pdf');
    }
    final repo = ExpenseRepository(edb);
    final lines = await edb.select(edb.transactions).get();
    final purchase = lines.firstWhere((t) => t.amount < -5000 && t.merchantId != null);
    await edb.customStatement("UPDATE transactions SET note = ? WHERE id = ?", [note, purchase.id]);
    await edb.customStatement(
      "INSERT INTO categories (id, name_fr, name_en, type, color, sort_order) "
      "VALUES ('user.ginette', 'Chez Ginette', 'At Ginette''s', 'expense', 0, 1000), "
      "('user.velo', 'Vélo', 'Bike', 'expense', 0, 1001)",
    );
    final merchant = (await edb.select(edb.merchants).get()).firstWhere((m) => m.id == purchase.merchantId);
    await edb.customStatement(
      "INSERT INTO rules (category_id, merchant_key, created_at) VALUES ('user.velo', ?, '2026-10-31T09:00:00')",
      [merchant.key],
    );
    await repo.setCategory(purchase.id, 'user.velo');
    await edb.customStatement(
      "INSERT INTO splits (transaction_id, category_id, amount) VALUES (?, 'food.groceries', ?), (?, 'user.velo', ?)",
      [purchase.id, purchase.amount ~/ 3, purchase.id, purchase.amount - purchase.amount ~/ 3],
    );
    await edb.customStatement(
      "INSERT INTO targets (scope, category_id, period, amount, created_at) "
      "VALUES ('desjardins', 'food', 'month', 60000, '2026-10-31T09:00:00')",
    );
    await edb.close();

    final raw = openKeyed(db, owner, readOnly: true);
    original = dump(raw);
    raw.close();
    copy = File('${dir.path}/dev/expenses.sqlite')..parent.createSync();
    report = writeDevCopy(
      source: db,
      sourcePassword: owner,
      target: copy,
      password: dev,
      keepWords: keepWords,
      extraSecrets: const ['Ginette Tremblay'],
      random: Random(7),
    );
  });
  tearDownAll(() {
    try {
      dir.deleteSync(recursive: true);
    } on FileSystemException {
      // Windows may still hold a file a moment.
    }
  });

  Database openCopy() => openKeyed(copy, dev, readOnly: true);

  test('the copy is encrypted with the developer password, not the owner\'s', () {
    expect(databaseFileState(copy), DatabaseFileState.encrypted);
    expect(passwordOpens(copy, owner), isFalse);
    expect(passwordOpens(copy, dev), isTrue);
    expect(passwordOpens(db, owner), isTrue, reason: 'the database itself is untouched');
  });

  test('no word of the personal data is left, in any cell or byte', () {
    // Every word of the original personal texts that a public list doesn't explain.
    final c = openCopy();
    addTearDown(c.close);
    final copyCells = <String>{};
    for (final rows in dump(c).values) {
      for (final r in rows) {
        for (final v in r.values) {
          // Random line ids (uuid) can spell a word by chance: not data.
          if (v is String) copyCells.addAll(words(v.replaceAll(uuid, ' ')));
        }
      }
    }
    for (final w in secretWords) {
      expect(copyCells, isNot(contains(w)), reason: w);
    }
    final personal = <String>{};
    for (final t in original['transactions']!) {
      for (final col in const ['location', 'note', 'card']) {
        if (t[col] case final String s) personal.addAll(words(s));
      }
    }
    for (final a in original['accounts']!) {
      personal.addAll(words('${a['ref']} ${a['name']}'));
    }
    // Words of places, cards, notes and account names left in the copy come from a public list.
    final public = <String>{
      for (final w in keepWords) ...words(w),
      for (final k in keywordCategories) ...words(k.$1),
      for (final c in defaultCategories) ...words('${c.nameFr} ${c.nameEn}'),
      'COMPTE', 'QUEBEC', 'CANADA', // the copy's own common words
    };
    final left = copyCells.intersection(personal).difference(public);
    expect(left, isEmpty, reason: left.join(' '));

    // Raw bytes: decrypt into a plaintext file and read it whole.
    final plain = File('${dir.path}/plain-check.sqlite');
    c.execute("VACUUM INTO '${plain.path}'");
    final raw = utf8.decode(plain.readAsBytesSync(), allowMalformed: true);
    plain.deleteSync();
    for (final w in [...secretWords, 'Ginette', 'Tremblay', 'releve-mai']) {
      expect(raw.contains(w), isFalse, reason: w);
    }
  });

  test('merchants: placeholders kept apart, known chains replaced too, people replaced', () {
    final c = openCopy();
    addTearDown(c.close);
    final after = dump(c);
    expect(after['merchants']!.length, original['merchants']!.length);
    final names = {for (final m in after['merchants']!) m['id']: m['name'] as String};
    final keys = after['merchants']!.map((m) => m['key']).toSet();
    expect(keys.length, after['merchants']!.length, reason: 'one placeholder per merchant');
    final chains = original['merchants']!.where((m) => seedMerchantCategories.containsKey(m['key'])).toList();
    expect(chains, isNotEmpty, reason: 'fixtures have known chains');
    // Where the owner shops: no chain name left anywhere (merchants, descriptions).
    final texts = [
      // Default category names are public (`Alcool (SAQ)`).
      for (final MapEntry(key: table, value: rows) in dump(c).entries)
        if (table != 'categories')
          for (final r in rows)
            for (final v in r.values)
              if (v is String) stripAccents(v).toUpperCase(),
    ];
    for (final m in chains) {
      final key = m['key'] as String;
      final pattern = RegExp('(^|[^A-Z])${RegExp.escape(key)}(\$|[^A-Z])');
      expect(texts.where(pattern.hasMatch), isEmpty, reason: key);
    }
    final people = {
      for (final t in after['transactions']!)
        if (t['is_person'] == 1 && t['merchant_id'] != null) t['merchant_id'],
    };
    expect(people, isNotEmpty);
    for (final id in people) {
      expect(names[id], startsWith('PERSONNE'));
    }
    for (final m in after['merchants']!) {
      final n = m['name'] as String;
      expect(n.startsWith('Marchand ') || n.startsWith('PERSONNE'), isTrue, reason: n);
    }
  });

  test('structure kept: rows, ids, categories, kinds, dates, review state, rules, targets', () {
    final c = openCopy();
    addTearDown(c.close);
    final after = dump(c);
    for (final t in original.keys) {
      expect(after[t]!.length, original[t]!.length, reason: t);
    }
    // Default categories untouched; the user's renamed, names kept but personal words.
    String? mapped(Object? id) => id == null ? null : report.categoryIds[id] ?? id as String;
    expect(report.categoryIds, {'user.ginette': 'custom.c01', 'user.velo': 'custom.c02'});
    final cats = {for (final r in after['categories']!) r['id']: r};
    for (final r in original['categories']!) {
      if (!report.categoryIds.containsKey(r['id'])) expect(cats[r['id']], r);
    }
    expect((cats['custom.c01']!['name_fr'], cats['custom.c01']!['name_en']), ('Chez XXX', "At XXX's"));
    expect(cats['custom.c02']!['name_fr'], 'Vélo', reason: 'a label without personal words is kept');
    for (final (i, t) in original['transactions']!.indexed) {
      final a = after['transactions']![i];
      for (final col in const [
        'id',
        'account_id',
        'date',
        'kind',
        'confidence',
        'needs_review',
        'merchant_id',
        'is_person',
        'transfer_group',
        'statement_id',
        'code',
      ]) {
        expect(a[col], t[col], reason: '$col of ${t['id']}');
      }
      expect(a['category_id'], mapped(t['category_id']));
    }
    final rule = after['rules']!.single;
    expect(rule['category_id'], 'custom.c02');
    expect(after['splits']!.map((s) => s['category_id']), containsAll(['food.groceries', 'custom.c02']));
    expect(
      after['merchants']!.map((m) => m['key']),
      contains(rule['merchant_key']),
      reason: 'the rule still points to its merchant',
    );
    expect(after['targets']!.single['category_id'], 'food');
    expect(after['statements']!.map((s) => s['file_name']), everyElement(startsWith('releve-')));
    expect(after['statements']!.map((s) => s['period_end']), original['statements']!.map((s) => s['period_end']));
  });

  test('amounts: one hidden factor, away from 1; equal amounts stay equal; splits add up', () {
    final c = openCopy();
    addTearDown(c.close);
    final after = dump(c);
    final ratios = <double>[];
    for (final (i, t) in original['transactions']!.indexed) {
      final a = (t['amount'] as int), b = after['transactions']![i]['amount'] as int;
      if (a.abs() >= 10000) ratios.add(b / a);
    }
    final f = ratios.first;
    expect(ratios.every((r) => (r - f).abs() < 0.0002), isTrue);
    expect((f - 1).abs(), greaterThanOrEqualTo(0.08));
    final byOriginal = <int, Set<int>>{};
    for (final (i, t) in original['transactions']!.indexed) {
      byOriginal.putIfAbsent(t['amount'] as int, () => {}).add(after['transactions']![i]['amount'] as int);
    }
    expect(byOriginal.values.every((s) => s.length == 1), isTrue);
    final amounts = {for (final t in after['transactions']!) t['id']: t['amount'] as int};
    final sums = <Object?, int>{};
    for (final s in after['splits']!) {
      sums[s['transaction_id']] = (sums[s['transaction_id']] ?? 0) + (s['amount'] as int);
    }
    for (final e in sums.entries) {
      expect(e.value, amounts[e.key]);
    }
    expect(after['targets']!.single['amount'], isNot(60000));
  });

  test('descriptions keep the bank\'s words and drop the rest', () {
    final c = openCopy();
    addTearDown(c.close);
    final descriptions = [for (final t in dump(c)['transactions']!) t['description'] as String];
    expect(descriptions.where((d) => d.contains('Virement')), isNotEmpty);
    expect(descriptions.where((d) => d.contains('MARCHAND ')), isNotEmpty);
    final glued = descriptions.where((d) => RegExp(r'(MARCHAND [0-9]{3}|PERSONNE[0-9]{2}|XXX)[A-Za-z]').hasMatch(d));
    expect(glued, isEmpty, reason: 'spaces around a placeholder kept');
    final withoutPlaceholders = descriptions.map((d) => d.replaceAll(RegExp(r'(MARCHAND |PERSONNE)[0-9]+'), ''));
    expect(withoutPlaceholders.any((d) => RegExp(r'[0-8]').hasMatch(d)), isFalse, reason: 'digits become 9');
    final notes = [for (final t in dump(c)['transactions']!) t['note']].whereType<String>();
    expect(notes, ['note']);
  });

  test('the app opens the copy and computes statistics on it', () async {
    final app = openEncryptedDatabase(copy, dev);
    addTearDown(app.close);
    final spending = await ExpenseRepository(app)
        .watchSpendingByCategory(const Scope('desjardins'), DateTime.utc(2026), DateTime.utc(2027))
        .first;
    expect(spending, isNotEmpty);
  });

  test('opening the copy keeps the owner\'s categories (rewritten text is not re-categorized)', () async {
    final app = openEncryptedDatabase(copy, dev);
    addTearDown(app.close);
    final before = {for (final t in await app.select(app.transactions).get()) t.id: (t.categoryId, t.needsReview)};
    expect(await ImportService(app).refreshAutomaticCategories(), 0);
    final after = {for (final t in await app.select(app.transactions).get()) t.id: (t.categoryId, t.needsReview)};
    expect(after, before);
  });

  test('a restore refuses the copy: it is never someone\'s data', () {
    final b = Backups(db, password: owner);
    expect(
      () => b.stageRestore(copy, ExpenseDatabase.currentSchemaVersion, filePassword: dev),
      throwsA(isA<RestoreException>().having((e) => e.problem, 'problem', RestoreProblem.devCopy)),
    );
    expect(b.hasPendingRestore, isFalse);
  });

  test('a personal word left in a column refuses the copy, nothing written', () async {
    final leaky = File('${dir.path}/leaky.sqlite');
    final raw = openKeyed(db, owner);
    final code = raw.select('SELECT id, code FROM transactions LIMIT 1').first;
    raw.execute('UPDATE transactions SET code = ? WHERE id = ?', ['GINETTE', code['id']]);
    raw.close();
    addTearDown(() {
      final r = openKeyed(db, owner);
      r.execute('UPDATE transactions SET code = ? WHERE id = ?', [code['code'], code['id']]);
      r.close();
    });
    final target = File('${dir.path}/leak/expenses.sqlite')..parent.createSync();
    expect(
      () => writeDevCopy(
        source: db,
        sourcePassword: owner,
        target: target,
        password: dev,
        extraSecrets: const ['Ginette'],
      ),
      throwsA(isA<DevCopyLeak>().having((e) => e.words, 'words', contains('GINETTE'))),
    );
    expect(target.existsSync(), isFalse);
    expect(leaky.existsSync(), isFalse);
  });

  test('refuses a short password, an existing file or the database itself', () async {
    final target = File('${dir.path}/other.sqlite');
    expect(
      () => writeDevCopy(source: db, sourcePassword: owner, target: target, password: 'short'),
      throwsArgumentError,
    );
    expect(() => writeDevCopy(source: db, sourcePassword: owner, target: copy, password: dev), throwsArgumentError);
    expect(() => writeDevCopy(source: db, sourcePassword: owner, target: db, password: dev), throwsArgumentError);
  });
}
