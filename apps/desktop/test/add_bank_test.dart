// "My bank isn't listed": reads statements, lists the words that could stay
// readable as chips, previews the masked first page.
import 'dart:io';

import 'package:banks/banks.dart' show PdfInput, TextInput;
import 'package:expense_desktop/l10n/app_localizations.dart';
import 'package:expense_desktop/screens/add_bank.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:pdf_words/pdf_words.dart';

const fixtures = '../../packages/banks/test/fixtures/desjardins';

void main() {
  test('masked copy: numbered files, nothing readable but approved words', () {
    final dir = Directory.systemTemp.createTempSync('masked');
    addTearDown(() => dir.deleteSync(recursive: true));
    final inputs = [
      PdfInput(
        'Releve_DUPONT_2026-09.pdf',
        DocumentWords([
          const PageWords(612, 792, [
            Word('DUPONT', 10, 40, 100),
            Word('SOLDE', 50, 80, 100),
            Word('ACME', 90, 120, 100),
          ]),
        ]),
      ),
      TextInput('DUPONT.csv', 'ACME;Dupont;12,34', fileType: 'csv'),
    ];
    expect(saveMaskedCopy(dir.path, inputs, {'ACME'}, readme: 'readme', notes: ' EOP = checking\n'), 6);
    final files = {for (final f in dir.listSync().whereType<File>()) p.basename(f.path): f.readAsStringSync()};
    expect(files.keys.toSet(), {
      'statement-1.shape.txt',
      'statement-1.shape.json',
      'statement-2.shape.txt',
      'reveal.txt',
      'README.txt',
      'notes.txt',
    });
    expect(files.values.join(), isNot(contains(RegExp('dupont|1234|12,34', caseSensitive: false))));
    expect(files['statement-1.shape.txt'], contains('SOLDE'));
    expect(files['statement-2.shape.txt'], contains('ACME;Xxxxxx;99,99'));
    expect(files['reveal.txt'], 'ACME\n');
  });

  testWidgets('word chips, keep / hide all, masked preview', (tester) async {
    tester.view.physicalSize = const Size(1440, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final paths = [
      for (final f in Directory(fixtures).listSync().whereType<File>())
        if (f.path.endsWith('.synthetic.json')) f.path,
    ]..sort();
    expect(paths.length, greaterThanOrEqualTo(2));

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AddBankScreen(initialPaths: paths.take(3).toList()),
      ),
    );
    for (var i = 0; i < 40 && find.byType(FilterChip).evaluate().isEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
    }
    expect(find.text('3 statements read'), findsOneWidget);
    final chips = find.byType(FilterChip);
    expect(chips, findsWidgets);
    final total = chips.evaluate().length;
    expect(
      find.text('0 of $total words readable'),
      findsOneWidget,
      reason: "all hidden at first: the owner's name and street are candidates too",
    );

    // Ticking one word reveals it.
    await tester.tap(chips.first);
    await tester.pump();
    expect(find.text('1 of $total words readable'), findsOneWidget);

    // Hide all: the preview shows no letter outside the built-in statement words.
    await tester.tap(find.text('Hide all'));
    await tester.pump();
    expect(find.text('0 of $total words readable'), findsOneWidget);
    final preview = tester.widget<Text>(find.byWidgetPredicate((w) => w is Text && w.style?.fontFamily == 'Consolas'));
    expect(preview.data, isNotEmpty);
    expect(preview.data, isNot(contains(RegExp('[0-8]'))), reason: 'digits are always masked to 9');

    await tester.tap(find.text('Keep all'));
    await tester.pump();
    expect(find.text('$total of $total words readable'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
