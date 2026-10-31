// The same lines read from a PDF statement and from a CSV export (B30,
// docs/11-import-sources-onboarding.md §2): counted once, whatever comes first.
import 'package:banks/desjardins.dart';
import 'package:banks/plugin.dart' show TextInput;
import 'package:core/core.dart';
import 'package:drift/native.dart';
import 'package:storage/storage.dart';
import 'package:test/test.dart';

ImportedLine _line(String ref, int day, int amount, String description, {String? code, String? card}) => ImportedLine(
  accountRef: ref,
  date: DateTime.utc(2026, 9, day),
  amount: amount,
  description: description,
  code: code,
  card: card,
  kind: amount < 0 ? TransactionKind.expense : TransactionKind.income,
  merchantText: description,
);

/// An account statement as the PDF reader returns it: September 1–30.
final _pdfAccount = ImportedStatement(
  institution: 'desjardins',
  format: 'desjardins-account',
  periodStart: DateTime.utc(2026, 9),
  periodEnd: DateTime.utc(2026, 9, 30),
  accounts: const [
    ImportedAccount(ref: 'EOP', name: 'EOP', type: AccountType.checking, currency: 'CAD', closingBalance: 98766),
  ],
  lines: [
    _line('EOP', 2, -1234, 'Achat / ACME CORP', code: 'ACH'),
    _line('EOP', 2, -1234, 'Achat / ACME CORP', code: 'ACH'),
    _line('EOP', 10, 100000, 'Paie / ACME CORP', code: 'DI'),
  ],
  failedChecks: const [],
  checkCount: 3,
);

/// The CSV export of September 2 – October 1: two lines of the PDF's days,
/// one the PDF doesn't have, one after the PDF.
const _csvAccount =
    'Caisse ACME,1234567,EOP,2026/09/02,00011,Achat /ACME CORP,"",12.34,"","","","","","",1000.00,""\n'
    'Caisse ACME,1234567,EOP,2026/09/02,00010,Achat /ACME CORP,"",12.34,"","","","","","",1012.34,""\n'
    'Caisse ACME,1234567,EOP,2026/09/20,00012,Achat /ACME INC,"",5.00,"","","","","","",995.00,""\n'
    'Caisse ACME,1234567,EOP,2026/10/01,00013,Achat /ACME INC,"",5.00,"","","","","","",990.00,""\n';

void main() {
  late ExpenseDatabase db;
  late ImportService importer;

  setUp(() {
    db = ExpenseDatabase(NativeDatabase.memory());
    importer = ImportService(db);
  });
  tearDown(() => db.close());

  Future<ImportResult> csv(String text, String hash) => importer.importStatement(
    const DesjardinsImporter().read(TextInput('export.csv', text, fileType: 'csv')),
    fileHash: hash,
    fileName: 'export.csv',
    fileType: 'csv',
  );

  test('PDF then CSV: lines of covered days matched by date and amount; the others imported and counted', () async {
    await importer.importStatement(_pdfAccount, fileHash: 'pdf', fileName: 'releve.pdf');
    final r = await csv(_csvAccount, 'csv');
    expect((r.newCount, r.duplicateCount, r.unmatchedCount), (2, 2, 1));
    final rows = await db.select(db.transactions).get();
    expect(rows, hasLength(5));
    // The lines already stored (maybe reviewed) are the ones kept.
    expect(rows.where((t) => t.code == 'ACH'), hasLength(2));
    expect(
      {for (final s in await db.select(db.statements).get()) (s.fileType, s.verified)},
      {('pdf', true), ('csv', true)},
    );
  });

  test('CSV then PDF: the same, the other way', () async {
    await csv(_csvAccount, 'csv');
    final r = await importer.importStatement(_pdfAccount, fileHash: 'pdf', fileName: 'releve.pdf');
    // The PDF's payroll line is in days the CSV covers (Sept 2 – Oct 1) but not in it.
    expect((r.newCount, r.duplicateCount, r.unmatchedCount), (1, 2, 1));
    expect(await db.select(db.transactions).get(), hasLength(5));
  });

  test('a card export lands on the card account of the statements; not verified; coverage by its own days', () async {
    final pdf = ImportedStatement(
      institution: 'desjardins',
      format: 'desjardins-card',
      periodStart: DateTime.utc(2026, 8, 21),
      periodEnd: DateTime.utc(2026, 9, 20),
      coversSincePrevious: true,
      accounts: const [ImportedAccount(ref: 'card-3000', name: 'Card', type: AccountType.creditCard, currency: 'CAD')],
      lines: [_line('card-3000', 5, -4567, 'ACME CORP', card: '3026')],
      failedChecks: const [],
      checkCount: 1,
    );
    await importer.importStatement(pdf, fileHash: 'pdf', fileName: 'carte.pdf');
    const export =
        'Odyssee World Elite Mastercard **** 3026,"","",2026/09/25,00002,ACME INC                 MONTREAL     QC ,"","","","","",10.00,""\n'
        'Odyssee World Elite Mastercard **** 3026,"","",2026/09/05,00001,ACME CORP                MONTREAL     QC ,"","","","","",45.67,""\n';
    final r = await csv(export, 'card');
    expect((r.newCount, r.duplicateCount, r.verified), (1, 1, false));
    final accounts = await db.select(db.accounts).get();
    expect(accounts.map((a) => a.ref), ['card-3000']);
    final cov = await ExpenseRepository(db).watchCoverage(const Scope('desjardins', currency: 'CAD')).first;
    expect(cov['desjardins-card'], [
      (DateTime.utc(2026, 8, 21), DateTime.utc(2026, 9, 20)),
      (DateTime.utc(2026, 9, 5), DateTime.utc(2026, 9, 25)),
    ]);
  });
}
