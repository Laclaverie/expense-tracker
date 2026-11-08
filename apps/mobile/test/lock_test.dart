// A lock must close every page above the root: no transaction text stays visible behind the password screen.
import 'dart:io';

import 'package:core/core.dart';
import 'package:expense_mobile/main.dart';
import 'package:expense_mobile/phone_store.dart';
import 'package:expense_mobile/screens/unlock.dart';
import 'package:expense_mobile/session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storage/storage.dart';

import 'helpers.dart';

void main() {
  final originalClock = appClock;
  setUpAll(loadTestFont);
  tearDown(() => appClock = originalClock);

  testWidgets('locking closes the transaction details sheet and shows only the password screen', (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final root = Directory.systemTemp.createTempSync('lock_test_');
    addTearDown(() => root.deleteSync(recursive: true));
    final store = PhoneStore(root);
    await tester.runAsync(() async {
      final db = openEncryptedDatabase(store.database, 'secret');
      await db.customSelect('select 1').get();
      await db.close();
    });
    final demo = (await tester.runAsync(demoDatabase))!;
    final session = Session(
      store,
      check: (path, password) async => passwordOpens(File(path), password),
      open: (file, password) => demo,
    );

    await tester.pumpWidget(MobileApp(session: session, check: () async => null));
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'secret');
    await tester.tap(find.byType(FilledButton));
    await settle(tester);
    expect(session.unlocked, isTrue);

    await tester.tap(find.text('Transactions').last);
    await settle(tester);
    final tile = find.byType(ListTile).first;
    final name = ((tester.widget<ListTile>(tile).title) as Text).data!;
    await tester.tap(tile);
    await settle(tester);
    expect(find.text('Statement text'), findsOneWidget);

    await tester.runAsync(session.lock);
    await settle(tester);
    expect(find.byType(UnlockScreen), findsOneWidget);
    expect(find.text('Statement text'), findsNothing);
    expect(find.text(name), findsNothing);
    expect(find.byType(ListTile), findsNothing);
    await closeApp(tester);
  });
}
