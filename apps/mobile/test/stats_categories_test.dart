// Categories and Trends rules: bills of a category, focus on a group, the average line.
import 'package:core/core.dart';
import 'package:expense_mobile/l10n/app_localizations.dart';
import 'package:expense_mobile/main.dart';
import 'package:expense_mobile/screens/stats/categories.dart';
import 'package:expense_mobile/screens/stats/trends.dart';
import 'package:expense_mobile/screens/stats/widgets.dart';
import 'package:expense_mobile/style.dart' show CategoryIndex;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart' hide Split;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:storage/storage.dart';

import 'helpers.dart';

const _account = Account(id: 1, institution: 'acme', ref: 'ACC 1', name: 'Checking', type: 'checking', currency: 'CAD');

TxnView _txn(String id, int amount, {String? category, String kind = 'expense', List<(String, int)> parts = const []}) {
  final now = DateTime.utc(2026, 10, 5);
  return TxnView(
    Txn(
      id: id,
      accountId: 1,
      date: now,
      amount: amount,
      description: 'ACME CORP $id',
      kind: kind,
      merchantId: 7,
      categoryId: category,
      confidence: 'rule',
      needsReview: false,
      source: 'test',
      isPerson: false,
      anomalyOk: false,
      createdAt: now,
      updatedAt: now,
    ),
    _account,
    null,
    [for (final (i, (c, a)) in parts.indexed) Split(id: i, transactionId: id, categoryId: c, amount: a)],
  );
}

void main() {
  final originalClock = appClock;
  setUpAll(loadTestFont);
  tearDown(() => appClock = originalClock);

  group('billLines', () {
    final rows = [
      _txn('group', -1000, category: 'food'),
      _txn('child', -2000, category: 'food.groceries'),
      _txn('split', -3000, parts: [('food.groceries', -1200), ('leisure.games', -1800)]),
      _txn('none', -400),
      _txn('pay', 5000, category: 'food', kind: 'income'),
    ];

    test('a group-filed key leaves its child categories out', () {
      expect([for (final (v, _) in billLines(rows, 'food')) v.txn.id], ['group']);
    });

    test('a split transaction gives the part of the category, with its amount', () {
      final lines = billLines(rows, 'food.groceries');
      expect([for (final (v, part) in lines) (v.txn.id, part?.$2)], [('child', null), ('split', -1200)]);
    });

    test('uncategorized is the lines without a category (a split part always has one)', () {
      expect([for (final (v, _) in billLines(rows, '')) v.txn.id], ['none']);
    });

    test('only lines that count as spending', () {
      expect(billLines(rows, 'food').any((b) => b.$1.txn.kind == 'income'), isFalse);
    });
  });

  testWidgets('trends without a complete month draws no average line and shows no average', (tester) async {
    final months = [DateTime.utc(2026, 9), DateTime.utc(2026, 10)];
    final d = StatsData(
      const Scope('acme', currency: 'CAD'),
      [
        SpendLine(date: DateTime.utc(2026, 9, 10), cents: 1000, categoryId: 'food.groceries'),
        SpendLine(date: DateTime.utc(2026, 10, 10), cents: 3000, categoryId: 'food.groceries'),
      ],
      months.first,
      DateTime.utc(2026, 11),
      [
        for (final m in months) MonthStatus(m, [('acme-card', const MonthCoverage(10, 30, null))]),
      ],
      false,
    );
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Provider.value(
          value: CategoryIndex(const []),
          child: Scaffold(body: TrendsView(d)),
        ),
      ),
    );
    await tester.pump();
    expect(d.completeMonths, 0);
    final chart = tester.widget<BarChart>(find.byType(BarChart));
    expect(chart.data.extraLinesData.horizontalLines, isEmpty);
    expect(tester.widget<Kpi>(find.widgetWithText(Kpi, 'Monthly average')).value, '—');
  });

  Future<ExpenseDatabase> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final db = (await tester.runAsync(demoDatabase))!;
    addTearDown(() => tester.runAsync(db.close));
    await tester.pumpWidget(mobileAppFor(db));
    await settle(tester);
    await tester.tap(find.text('Statistics').last);
    await settle(tester);
    return db;
  }

  String chipLabel(WidgetTester tester) => (tester.widget<InputChip>(find.byType(InputChip)).label as Text).data!;

  testWidgets('a tap on a slice label inside the ring focuses on that slice group', (tester) async {
    await open(tester);
    final inside = find.byWidgetPredicate(
      (w) => w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('donut-in-'),
    );
    expect(inside, findsWidgets, reason: 'the largest groups carry their name inside the ring');
    await tester.ensureVisible(find.byType(CategoryDonut));
    await tester.pump();
    final name = tester.widgetList<Text>(find.descendant(of: inside.first, matching: find.byType(Text))).first.data!;
    // The label ignores taps: the slice under it gets this one.
    await tester.tapAt(tester.getCenter(inside.first));
    await settle(tester);
    expect(tester.takeException(), isNull);
    expect(chipLabel(tester), name);
    await closeApp(tester);
  });

  testWidgets('the focus survives a range change', (tester) async {
    await open(tester);
    final list = find.descendant(of: find.byType(CategoriesView), matching: find.byType(Scrollable)).first;
    final food = find.descendant(of: find.byType(ListTile), matching: find.text('Food'));
    await tester.scrollUntilVisible(food, 200, scrollable: list);
    await tester.tap(food);
    await settle(tester);
    expect(chipLabel(tester), 'Food');
    await tester.tap(find.text('6 months'));
    await settle(tester);
    expect(tester.takeException(), isNull);
    expect(chipLabel(tester), 'Food');
    await closeApp(tester);
  });

  testWidgets('the average line label is the average shown above the chart', (tester) async {
    await open(tester);
    final chip = find.widgetWithText(ChoiceChip, 'Trends');
    await tester.tap(chip);
    await settle(tester);
    final kpi = tester.widget<Kpi>(find.widgetWithText(Kpi, 'Monthly average'));
    final line = tester.widget<BarChart>(find.byType(BarChart)).data.extraLinesData.horizontalLines.single;
    expect(line.label.labelResolver(line), 'avg ${kpi.value}');
    await closeApp(tester);
  });
}
