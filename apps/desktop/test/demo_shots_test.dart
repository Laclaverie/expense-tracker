// Photographs the demo walkthrough (docs/13-demo.md) for the README: the
// couple's showcase database, the card exports dropped at the import stop.
// Skipped unless DEMO_SHOTS_OUT names a folder: run tools\demo-shots.ps1.
//   DEMO_SHOTS_OUT     folder for demo-<n>-<id>.png
//   DEMO_SHOTS_LOCALE  en (default) or fr
import 'dart:io';
import 'dart:ui' as ui;

import 'package:demo/demo.dart';
import 'package:demo/src/showcase.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:expense_desktop/app_state.dart';
import 'package:expense_desktop/clock.dart';
import 'package:expense_desktop/l10n/app_localizations.dart';
import 'package:expense_desktop/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:storage/storage.dart';

import 'demo/stops.dart';

void main() {
  final out = Platform.environment['DEMO_SHOTS_OUT'];
  final language = Platform.environment['DEMO_SHOTS_LOCALE'] ?? 'en';
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  // Real fonts: Segoe UI for text (as the smoke test), and the Material icons
  // from the Flutter SDK (tests draw every icon as a box otherwise).
  setUpAll(() async {
    Future<void> load(String family, File font) async {
      if (!font.existsSync()) return;
      final loader = FontLoader(family)..addFont(font.readAsBytes().then((b) => ByteData.view(b.buffer)));
      await loader.load();
    }

    await load('Roboto', File('${Platform.environment['WINDIR'] ?? 'C:/Windows'}/Fonts/segoeui.ttf'));
    final flutter = Platform.environment['FLUTTER_ROOT'];
    if (flutter != null) {
      await load('MaterialIcons', File('$flutter/bin/cache/artifacts/material_fonts/materialicons-regular.otf'));
    }
  });

  testWidgets('demo walkthrough screenshots', skip: out == null, (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final realClock = appClock;
    appClock = () => DateTime(2026, 10, 22, 12);
    addTearDown(() => appClock = realClock);

    final folder = Directory(out!)..createSync(recursive: true);
    final drops = Directory.systemTemp.createTempSync('demo-shots-');
    addTearDown(() => drops.deleteSync(recursive: true));
    final db = ExpenseDatabase(NativeDatabase.memory());
    final csvs = (await tester.runAsync(() => fillShowcaseDatabase(db, couple)))!;
    addTearDown(() => tester.runAsync(db.close));
    final csvPaths = [
      for (final MapEntry(key: name, value: text) in csvs.entries)
        (File('${drops.path}/$name')..writeAsStringSync(text)).path,
    ];

    Future<void> settle() async {
      for (var i = 0; i < 8; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    final shot = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(key: shot, child: appFor(db)));
    await settle();
    tester.element(find.byType(Scaffold).first).read<AppState>().locale = Locale(language);
    await settle();
    final l = lookupAppLocalizations(Locale(language));

    for (final (i, stop) in demoStops.indexed) {
      await stop.reach((tester: tester, settle: settle, l: l, language: language, csvPaths: csvPaths));
      expect(tester.takeException(), isNull, reason: stop.id);
      final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(shot));
      final png = await tester.runAsync(() async {
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        return bytes!.buffer.asUint8List();
      });
      File('${folder.path}/demo-${i + 1}-${stop.id}.png').writeAsBytesSync(png!);
    }

    // Leave the app so its streams and timers stop before the database closes.
    await tester.pumpWidget(const SizedBox());
    await settle();
  });
}
