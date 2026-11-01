import 'package:banks/banks.dart';
import 'package:demo/demo.dart';
import 'package:demo/src/database.dart' show importDay;
import 'package:demo/src/showcase.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:storage/storage.dart';
import 'package:test/test.dart';

/// The showcase database: what a demo starts from, before the card exports
/// are dropped on the Import page.
void main() {
  for (final persona in personas.values) {
    group(persona.id, () {
      late ExpenseDatabase db;
      late Map<String, String> csvs;
      final life = liveHousehold(persona: persona);
      final previous = life.cardStatementDates[life.cardStatementDates.length - 2];

      setUp(() async {
        db = ExpenseDatabase(NativeDatabase.memory());
        csvs = await fillShowcaseDatabase(db, persona);
      });
      tearDown(() => db.close());

      Future<ImportResult> drop(String name, {String? hash}) =>
          ImportService(db, clock: () => importDay).importStatement(
            readStatement(TextInput(name, csvs[name]!, fileType: 'csv')),
            fileHash: hash ?? name,
            fileName: name,
            fileType: 'csv',
          );

      test('nothing to review before the drop', () async {
        final pending = await (db.select(db.transactions)..where((t) => t.needsReview)).get();
        expect(pending, isEmpty);
      });

      test('the dropped lines of merchants left to review wait for review', () async {
        for (final name in csvs.keys) {
          await drop(name);
        }
        final pending = await (db.select(db.transactions)..where((t) => t.needsReview)).get();
        final left = pending.where((t) => persona.show.leftToReview.any(t.description.contains));
        final dropped = {
          for (final text in csvs.values)
            for (final m in persona.show.leftToReview)
              if (text.contains(m)) m,
        };
        expect({for (final t in left) persona.show.leftToReview.firstWhere(t.description.contains)}, dropped);
      });

      test('the held-back card period is not imported', () async {
        final cards = await (db.select(db.accounts)..where((a) => a.type.equals('creditCard'))).get();
        final after = await (db.select(
          db.transactions,
        )..where((t) => t.accountId.isIn(cards.map((a) => a.id)) & t.date.isBiggerThanValue(previous))).get();
        expect(after.where((t) => !t.description.startsWith('PAIEMENT')), isEmpty);
      });

      test('CSV lines join the PDF card account', () async {
        final accounts = (await db.select(db.accounts).get()).length;
        final before = (await db.select(db.transactions).get()).length;
        for (final name in csvs.keys) {
          expect((await drop(name)).status, ImportStatus.imported, reason: name);
        }
        expect((await db.select(db.accounts).get()).length, accounts);
        final added = (await db.select(db.transactions).get()).skip(before).toList();
        expect(added, isNotEmpty);
        expect(added.where((t) => t.categoryId != null).length, greaterThanOrEqualTo(added.length * .8));
      });

      test('importing the CSV again adds nothing', () async {
        for (final name in csvs.keys) {
          await drop(name);
        }
        for (final name in csvs.keys) {
          final again = await drop(name, hash: '$name again');
          expect(again.newCount, 0, reason: name);
        }
      });
    });
  }
}
