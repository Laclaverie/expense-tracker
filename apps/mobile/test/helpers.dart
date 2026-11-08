import 'dart:io';

import 'package:core/core.dart';
import 'package:demo/src/database.dart' show fillDemoDatabase, importDay;
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show SizedBox;
import 'package:flutter_test/flutter_test.dart';
import 'package:storage/storage.dart';

/// The made-up household's database (no real data), in memory, with the clock fixed two days after the
/// last statement so the figures are stable.
Future<ExpenseDatabase> demoDatabase() async {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  appClock = () => DateTime(importDay.year, importDay.month, importDay.day, 12);
  final db = ExpenseDatabase(NativeDatabase.memory());
  await fillDemoDatabase(db);
  return db;
}

/// Tests draw text with a placeholder font (every letter a wide square), which overflows layouts that fit
/// with real fonts: use Windows' UI font instead when it exists.
Future<void> loadTestFont() async {
  final font = File('${Platform.environment['WINDIR'] ?? 'C:/Windows'}/Fonts/segoeui.ttf');
  if (!font.existsSync()) return;
  final loader = FontLoader('Roboto')..addFont(font.readAsBytes().then((b) => ByteData.view(b.buffer)));
  await loader.load();
}

/// Database work runs on real time, widgets on fake time: alternate both.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Removes the app and lets the streams' cleanup timers run, so no timer is left pending at the end.
Future<void> closeApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await settle(tester);
}
