// The stops of the demo walkthrough (docs/13-demo.md), in order: how to reach
// each one in a widget test. demo_shots_test.dart photographs them;
// demo_doc_test.dart checks the doc names each one.
import 'dart:async';

import 'package:core/core.dart' show defaultCategories;
import 'package:expense_desktop/l10n/app_localizations.dart';
import 'package:expense_desktop/screens/import_screen.dart';
import 'package:flutter/material.dart' show EditableText, Icons;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// What a stop needs: the tester, a settle that lets database work run, the
/// app's strings in the shot's language and the card exports to drop.
typedef StopContext = ({
  WidgetTester tester,
  Future<void> Function() settle,
  AppLocalizations l,
  String language,
  List<String> csvPaths,
});

class DemoStop {
  const DemoStop(this.id, this.reach);

  /// Named in docs/13-demo.md as `` `id` ``.
  final String id;
  final Future<void> Function(StopContext c) reach;
}

Future<void> _tap(StopContext c, String label) async {
  await c.tester.tap(find.text(label).first);
  await c.settle();
}

/// Taps the share bar segment of category [id] (`Groceries 66 %`).
Future<void> _tapShare(StopContext c, String id) async {
  final category = defaultCategories.firstWhere((x) => x.id == id);
  final name = c.language == 'fr' ? category.nameFr : category.nameEn;
  await c.tester.tap(find.textContaining(RegExp('^${RegExp.escape(name)} \\d+[   ]?%\$')).first);
  await c.settle();
}

final List<DemoStop> demoStops = [
  DemoStop('dashboard', (c) => _tap(c, c.l.navDashboard)),
  DemoStop('import', (c) async {
    await _tap(c, c.l.navImport);
    final state = c.tester.state<ImportScreenState>(find.byType(ImportScreen));
    // Not awaited inside runAsync: the import waits on database streams the
    // widgets read on fake time, so both clocks must move until it is done.
    var done = false;
    unawaited(state.importPaths(c.csvPaths).whenComplete(() => done = true));
    for (var i = 0; i < 60 && !done; i++) {
      await c.settle();
    }
    expect(done, isTrue, reason: 'import finished');
    await c.settle();
  }),
  DemoStop('review', (c) => _tap(c, c.l.navReview)),
  DemoStop('categories', (c) async {
    await _tap(c, c.l.navStats);
    await _tap(c, c.l.tabCategories);
    // Food's bar segment, then "analyze only" Groceries: a card per store.
    await _tapShare(c, 'food');
    final groceries = defaultCategories.firstWhere((x) => x.id == 'food.groceries');
    await c.tester.tap(find.byTooltip(c.l.analyzeOnly(c.language == 'fr' ? groceries.nameFr : groceries.nameEn)));
    await c.settle();
  }),
  DemoStop('recurring', (c) async {
    // Back to every category: recurring payments are not groceries.
    await c.tester.tap(find.byIcon(Icons.clear).first);
    await c.settle();
    await _tap(c, c.l.tabRecurring);
  }),

  DemoStop('trends', (c) => _tap(c, c.l.tabCompare)),
  DemoStop('search', (c) async {
    await c.tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await c.tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await c.tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await c.settle();
    await c.tester.enterText(find.byType(EditableText).last, 'costco');
    await c.settle();
  }),
];
