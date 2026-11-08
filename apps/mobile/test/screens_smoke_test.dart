// Opens Home, Transactions and Settings on the demo database at two phone sizes, with a real font: fails on
// any exception, layout overflow or error widget.
import 'dart:io';

import 'package:core/core.dart';
import 'package:expense_mobile/main.dart';
import 'package:expense_mobile/phone_store.dart';
import 'package:expense_mobile/screens/stats.dart';
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
      // The first group row opens its merchants.
      await tester.tap(find.byType(ListTile).first);
      await settle(tester);
      expect(tester.takeException(), isNull);
      expect(find.textContaining(': merchants'), findsOneWidget);
      await tester.tapAt(const Offset(5, 5));
      await settle(tester);
      for (final view in const ['Trends', 'Merchants', 'Recurring', 'Balances', 'Categories']) {
        final chip = find.widgetWithText(ChoiceChip, view);
        await tester.ensureVisible(chip);
        await tester.pump();
        await tester.tap(chip);
        await settle(tester);
        expect(tester.takeException(), isNull, reason: view);
        expect(find.byType(ErrorWidget), findsNothing, reason: view);
      }

      await tester.tap(find.text('Settings').last);
      await settle(tester);
      expect(tester.takeException(), isNull);
      expect(find.text('Check for new data'), findsOneWidget);
      expect(find.text('Lock'), findsOneWidget);
      expect(find.byType(ErrorWidget), findsNothing);
      await closeApp(tester);
    });
  }

  Future<void> openView(WidgetTester tester, String view) async {
    final chip = find.widgetWithText(ChoiceChip, view);
    await tester.ensureVisible(chip);
    await tester.pump();
    await tester.tap(chip);
    await settle(tester);
    expect(tester.takeException(), isNull, reason: view);
    expect(find.byType(ErrorWidget), findsNothing, reason: view);
  }

  testWidgets('statistics views show coverage, faded months and recurring payments of the demo data', (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final db = (await tester.runAsync(demoDatabase))!;
    addTearDown(() => tester.runAsync(db.close));

    await tester.pumpWidget(mobileAppFor(db));
    await settle(tester);
    await tester.tap(find.text('Statistics').last);
    await settle(tester);
    expect(find.textContaining(RegExp(r'incomplete months? — counted in totals')), findsOneWidget);

    await openView(tester, 'Trends');
    await tester.scrollUntilVisible(find.textContaining('Faded bars'), 200, scrollable: find.byType(Scrollable).last);
    expect(find.textContaining('Faded bars'), findsOneWidget);

    await openView(tester, 'Recurring');
    expect(find.descendant(of: find.byType(ListTile), matching: find.textContaining('next ')), findsWidgets);
    await closeApp(tester);
  });

  testWidgets('every statistics view opens in French at 360x640', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final db = (await tester.runAsync(demoDatabase))!;
    addTearDown(() => tester.runAsync(db.close));
    final store = PhoneStore(Directory.systemTemp.createTempSync('phone_fr_'))..saveLanguage('fr');

    await tester.pumpWidget(mobileAppFor(db, store: store));
    await settle(tester);
    await tester.tap(find.text('Statistiques').last);
    await settle(tester);
    expect(tester.takeException(), isNull);
    for (final view in const ['Tendances', 'Marchands', 'Récurrents', 'Soldes', 'Catégories']) {
      await openView(tester, view);
    }
    await closeApp(tester);
  });

  testWidgets('categories figures equal desktop StatsData for the same scope and range', (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final db = (await tester.runAsync(demoDatabase))!;
    addTearDown(() => tester.runAsync(db.close));
    final repo = ExpenseRepository(db);
    final scope = (await tester.runAsync(() => repo.watchScopes().first))!.firstWhere((s) => s.institution != 'cash');
    final latest = (await tester.runAsync(() => repo.watchLatestDate(scope).first))!;
    final period = statsPeriod(StatsRange.twelve, DateTime.utc(latest.year, latest.month));
    final (loadFrom, _) = previousPeriod(period.$1, period.$2);
    final lines = (await tester.runAsync(() => repo.watchSpendingDetail(scope, loadFrom, period.$2).first))!;
    final coverage = (await tester.runAsync(() => repo.watchCoverage(scope).first))!;
    final d = statsDataOf(scope, lines, coverage, period);
    final top = breakdown(d.lines, d.from, d.to, keyOf: (x) => groupKey(x.categoryId), labelOf: (k) => k).first;
    expect(top.total, greaterThan(0));

    await tester.pumpWidget(mobileAppFor(db));
    await settle(tester);
    await tester.tap(find.text('Statistics').last);
    await settle(tester);
    expect(find.text(formatMoney(top.total, scope.currency!, languageCode: 'en')), findsWidgets);
    await closeApp(tester);
  });

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
