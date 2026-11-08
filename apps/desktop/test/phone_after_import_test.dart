// After an import: a paired phone is offered the new data; nothing is asked when no phone is paired or
// nothing new came in.
import 'dart:async';
import 'dart:io';

import 'package:demo/demo.dart';
import 'package:demo/src/showcase.dart';
import 'package:drift/native.dart';
import 'package:expense_desktop/main.dart';
import 'package:expense_desktop/phone_sync.dart';
import 'package:expense_desktop/screens/import_screen.dart';
import 'package:flutter/services.dart' show ByteData, FontLoader;
import 'package:flutter/widgets.dart' show SizedBox, Size;
import 'package:flutter_test/flutter_test.dart';
import 'package:storage/storage.dart';

const _question = 'Send the new data to your phone?';

void main() {
  // The sync server needs real sockets (the test binding answers every HttpClient with 400).
  setUp(() => HttpOverrides.global = null);

  // Real UI font as the smoke test: the placeholder font overflows the shell.
  setUpAll(() async {
    final font = File('${Platform.environment['WINDIR'] ?? 'C:/Windows'}/Fonts/segoeui.ttf');
    if (!font.existsSync()) return;
    final loader = FontLoader('Roboto')..addFont(font.readAsBytes().then((b) => ByteData.view(b.buffer)));
    await loader.load();
  });

  late Directory dir;
  late ExpenseDatabase db;
  late PhoneSync sync;
  late List<String> csvPaths;

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> start(WidgetTester tester, {required bool paired}) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    dir = Directory.systemTemp.createTempSync('expenses-after-import');
    db = ExpenseDatabase(NativeDatabase.memory());
    final csvs = (await tester.runAsync(() => fillShowcaseDatabase(db, couple)))!;
    csvPaths = [
      for (final MapEntry(key: name, value: text) in csvs.entries)
        (File('${dir.path}/$name')..writeAsStringSync(text)).path,
    ];
    if (paired) await tester.runAsync(() => PairingStore(db).pairNew());
    sync = PhoneSync(
      db,
      Directory('${dir.path}/sync'),
      bindAddress: InternetAddress.loopbackIPv4,
      discoveryPort: 0,
      hosts: () async => ['192.168.1.20'],
    );
    addTearDown(() async {
      await tester.runAsync(() async {
        await sync.stop();
        await db.close();
      });
      sync.dispose();
      try {
        dir.deleteSync(recursive: true);
      } on FileSystemException {
        // Still held for a moment on Windows.
      }
    });
    await tester.runAsync(sync.refresh);
    await tester.pumpWidget(appFor(db, phoneSync: sync));
    await settle(tester);
    await tester.tap(find.text('Import').first);
    await settle(tester);
  }

  /// Drops the tree and lets drift's stream-closing timers run before the test ends.
  Future<void> finish(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await settle(tester);
  }

  /// Imports [paths]; returns whether the call finished (it waits while a dialog is open).
  Future<bool Function()> importing(WidgetTester tester, List<String> paths) async {
    final state = tester.state<ImportScreenState>(find.byType(ImportScreen));
    var done = false;
    unawaited(state.importPaths(paths).whenComplete(() => done = true));
    for (var i = 0; i < 40 && !done && find.text(_question).evaluate().isEmpty; i++) {
      await settle(tester);
    }
    return () => done;
  }

  testWidgets('paired + new lines -> dialog shown', (tester) async {
    await start(tester, paired: true);
    final done = await importing(tester, csvPaths);
    expect(find.text(_question), findsOneWidget);
    await tester.tap(find.text('Not now'));
    await settle(tester);
    expect(done(), isTrue);
    expect(sync.serving, isFalse, reason: 'Not now sends nothing');
    await finish(tester);
  });

  testWidgets('Send starts the session and opens the phone dialog', (tester) async {
    await start(tester, paired: true);
    final done = await importing(tester, csvPaths);
    await tester.tap(find.text('Send'));
    await settle(tester);
    await settle(tester);
    expect(sync.serving, isTrue);
    expect(find.textContaining('Waiting for the phone'), findsOneWidget);
    await tester.tap(find.text('Stop'));
    await settle(tester);
    await tester.tap(find.text('Close'));
    await settle(tester);
    expect(done(), isTrue);
    await finish(tester);
  });

  testWidgets('not paired -> no dialog', (tester) async {
    await start(tester, paired: false);
    final done = await importing(tester, csvPaths);
    for (var i = 0; i < 10 && !done(); i++) {
      await settle(tester);
    }
    expect(done(), isTrue);
    expect(find.text(_question), findsNothing);
    await finish(tester);
  });

  testWidgets('only already-imported files -> no dialog', (tester) async {
    await start(tester, paired: false);
    var done = await importing(tester, csvPaths);
    for (var i = 0; i < 10 && !done(); i++) {
      await settle(tester);
    }
    expect(done(), isTrue);
    // Now paired, and the same files again: nothing new.
    await tester.runAsync(sync.pair);
    done = await importing(tester, csvPaths);
    for (var i = 0; i < 10 && !done(); i++) {
      await settle(tester);
    }
    expect(done(), isTrue);
    expect(find.text(_question), findsNothing);
    await finish(tester);
  });
}
