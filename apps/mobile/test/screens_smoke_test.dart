// Opens Home, Transactions and Settings on the demo database at two phone sizes, with a real font: fails on
// any exception, layout overflow or error widget.
import 'package:core/core.dart';
import 'package:expense_mobile/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storage/storage.dart';

import 'helpers.dart';

void main() {
  final costco = find.descendant(
    of: find.byType(ListTile),
    matching: find.textContaining(RegExp('costco', caseSensitive: false)),
  );
  final originalClock = appClock;
  setUpAll(loadTestFont);
  tearDown(() => appClock = originalClock);

  for (final size in const [Size(412, 915), Size(360, 640)]) {
    testWidgets('home, transactions and settings open without error, ${size.width.round()}x${size.height.round()}', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final db = (await tester.runAsync(demoDatabase))!;
      addTearDown(() => tester.runAsync(db.close));

      await tester.pumpWidget(mobileAppFor(db));
      await settle(tester);
      expect(tester.takeException(), isNull);
      expect(find.text('Spent in October 2026'), findsOneWidget);
      // The coverage warning names accounts (no bank labels on the phone).
      expect(find.textContaining('Statements missing or incomplete for'), findsOneWidget);
      expect(find.text('Targets'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Recent transactions'), 200, scrollable: find.byType(Scrollable).first);
      expect(find.text('Recent transactions'), findsOneWidget);

      await tester.tap(find.text('Transactions').last);
      await settle(tester);
      expect(tester.takeException(), isNull);
      await tester.enterText(find.byType(TextField), 'costco');
      await settle(tester);
      expect(tester.takeException(), isNull);
      expect(costco, findsWidgets);

      await tester.tap(costco.first);
      await settle(tester);
      expect(tester.takeException(), isNull);
      expect(find.text('Statement text'), findsOneWidget);
      await tester.tapAt(const Offset(5, 5));
      await settle(tester);

      await tester.tap(find.text('Statistics').last);
      await settle(tester);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Settings').last);
      await settle(tester);
      expect(tester.takeException(), isNull);
      expect(find.text('Check for new data'), findsOneWidget);
      expect(find.text('Lock'), findsOneWidget);
      expect(find.byType(ErrorWidget), findsNothing);
      await closeApp(tester);
    });
  }

  testWidgets('home month total equals repository total for the demo scope', (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final db = (await tester.runAsync(demoDatabase))!;
    addTearDown(() => tester.runAsync(db.close));
    final repo = ExpenseRepository(db);
    final scope = (await tester.runAsync(() => repo.watchScopes().first))!.firstWhere((s) => s.institution != 'cash');
    final totals = (await tester.runAsync(
      () => repo.watchMonthlyTotals(scope, DateTime.utc(2026, 10), DateTime.utc(2026, 11)).first,
    ))!;
    final spent = totals.singleWhere((t) => t.$1 == '2026-10').$2;
    expect(spent, greaterThan(0));

    await tester.pumpWidget(mobileAppFor(db));
    await settle(tester);
    expect(find.text(formatMoney(spent, scope.currency!, languageCode: 'en')), findsWidgets);
    await closeApp(tester);
  });
}
