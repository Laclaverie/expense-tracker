// Opens databases written by older versions of the app and checks they are
// brought up to date without losing or skewing data.
import 'dart:io';

import 'package:banks/banks.dart';
import 'package:banks/testing.dart' show loadFixture;
import 'package:core/core.dart' show TargetPeriod, monthCoverage;
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:storage/storage.dart';
import 'package:test/test.dart';

const fixtures = '../banks/test/fixtures/desjardins';

void main() {
  late Directory dir;
  late File file;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('expenses-migration');
    file = File('${dir.path}/expenses.sqlite');
  });
  tearDown(() => dir.deleteSync(recursive: true));

  /// A database at the current schema with every fixture imported and a target.
  Future<void> current() async {
    final db = ExpenseDatabase(NativeDatabase(file));
    final importer = ImportService(db);
    for (final f in Directory(fixtures).listSync().whereType<File>()) {
      final name = f.uri.pathSegments.last;
      await importer.importStatement(readStatement(loadFixture(f.path)), fileHash: name, fileName: name);
    }
    await ExpenseRepository(db)
        .saveTarget(const Scope('desjardins', currency: 'CAD'), 'food', TargetPeriod.month, 60000);
    await db.close();
  }

  /// Rewrites the file as schema version [version] would have stored it.
  Future<void> downgradeTo(int version, List<String> statements) async {
    final raw = NativeDatabase(file);
    final db = _Raw(raw);
    for (final s in statements) {
      await db.customStatement(s);
    }
    await db.customStatement('PRAGMA user_version = $version');
    await db.close();
  }

  const v10 = ['DROP TABLE paired_phones'];
  const v9 = [...v10, 'ALTER TABLE categories DROP COLUMN excluded_from_share'];
  const v8 = [...v9, 'ALTER TABLE statements DROP COLUMN file_type', 'ALTER TABLE statements DROP COLUMN verified'];

  test('v9 → v10 adds paired_phones, keeps data', () async {
    await current();
    final before = await _countTransactions(file);
    await downgradeTo(9, v10);

    final db = ExpenseDatabase(NativeDatabase(file));
    addTearDown(db.close);
    expect(await db.select(db.pairedPhones).get(), isEmpty);
    expect(await db.select(db.transactions).get(), hasLength(before));
    await PairingStore(db).pairNew();
    expect(await PairingStore(db).current(), isNotNull);
  });

  test('v8 -> current: no category excluded from shares yet', () async {
    await current();
    await downgradeTo(8, v9);

    final db = ExpenseDatabase(NativeDatabase(file));
    addTearDown(db.close);
    final rows = await db.select(db.categories).get();
    expect(rows, isNotEmpty);
    expect(rows.where((c) => c.excludedFromShare), isEmpty);
    await ExpenseRepository(db).setExcludedFromShare('housing.rent', true);
    final rent = await (db.select(db.categories)..where((c) => c.id.equals('housing.rent'))).getSingle();
    expect(rent.excludedFromShare, isTrue);
  });

  test('v7 -> current: statements so far were verified PDFs', () async {
    await current();
    await downgradeTo(7, v8);

    final db = ExpenseDatabase(NativeDatabase(file));
    addTearDown(db.close);
    final statements = await db.select(db.statements).get();
    expect(statements, isNotEmpty);
    expect({for (final s in statements) (s.fileType, s.verified)}, {('pdf', true)});
  });

  test('v6 -> current: no transaction marked normal yet', () async {
    await current();
    await downgradeTo(6, [...v8, 'ALTER TABLE transactions DROP COLUMN anomaly_ok']);

    final db = ExpenseDatabase(NativeDatabase(file));
    addTearDown(db.close);
    final rows = await db.select(db.transactions).get();
    expect(rows, isNotEmpty);
    expect(rows.where((t) => t.anomalyOk), isEmpty);
  });

  test('v5 -> current: card statements flagged, targets keyed by institution and currency', () async {
    await current();
    await downgradeTo(5, [
      ...v8,
      'ALTER TABLE transactions DROP COLUMN anomaly_ok',
      'ALTER TABLE statements DROP COLUMN covers_since_previous',
      "UPDATE targets SET scope = 'desjardins'",
    ]);

    final db = ExpenseDatabase(NativeDatabase(file));
    addTearDown(db.close);
    final statements = await db.select(db.statements).get();
    expect(
      {for (final s in statements) s.format: s.coversSincePrevious},
      {'desjardins-account': false, 'desjardins-card': true},
    );
    final targets = await db.select(db.targets).get();
    expect(targets.map((t) => t.scope), ['desjardins-CAD']);
    // Data untouched: the same statistics as a fresh import.
    final repo = ExpenseRepository(db);
    final lines = await repo
        .watchSpendingDetail(const Scope('desjardins', currency: 'CAD'), DateTime.utc(2026), DateTime.utc(2026, 10))
        .first;
    expect(lines, isNotEmpty);
    final cov = await repo.watchCoverage(const Scope('desjardins', currency: 'CAD')).first;
    expect(monthCoverage(cov['desjardins-card']!, DateTime.utc(2026, 6)).full, isTrue);
  });

  test('v4 -> current: older Desjardins codes reclassified on the way', () async {
    await current();
    await downgradeTo(4, [
      ...v8,
      'ALTER TABLE transactions DROP COLUMN anomaly_ok',
      'ALTER TABLE statements DROP COLUMN covers_since_previous',
      "UPDATE targets SET scope = 'desjardins'",
      // As imported before codes like DMD (mobile deposit) were known.
      "UPDATE transactions SET kind = 'refund', category_id = NULL, confidence = 'none' WHERE code = 'DI'",
      "UPDATE transactions SET code = 'DMD' WHERE code = 'DI'",
    ]);

    final db = ExpenseDatabase(NativeDatabase(file));
    addTearDown(db.close);
    final deposits = await (db.select(db.transactions)..where((t) => t.code.equals('DMD'))).get();
    expect(deposits, isNotEmpty);
    expect(deposits.every((t) => t.kind == 'income' && t.categoryId == 'income.other'), isTrue);
  });
}

Future<int> _countTransactions(File file) async {
  final db = ExpenseDatabase(NativeDatabase(file));
  try {
    return (await db.select(db.transactions).get()).length;
  } finally {
    await db.close();
  }
}

/// Plain access to the file, without the app's migrations.
class _Raw extends GeneratedDatabase {
  _Raw(super.executor);

  @override
  Iterable<TableInfo<Table, Object?>> get allTables => const [];

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(onCreate: (_) async {}, onUpgrade: (_, _, _) async {});
}
