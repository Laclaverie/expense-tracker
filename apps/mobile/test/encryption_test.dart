import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:storage/storage.dart';

void main() {
  test('sqlite3mc encrypts in the mobile package build', () async {
    final dir = Directory.systemTemp.createTempSync('mobile_enc_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/expenses.sqlite');

    final db = openEncryptedDatabase(file, 'pw-test');
    await db.customSelect('select 1').get();
    await db.close();

    expect(databaseFileState(file), DatabaseFileState.encrypted);
    expect(passwordOpens(file, 'pw-test'), isTrue);
    expect(passwordOpens(file, 'wrong'), isFalse);
  });
}
