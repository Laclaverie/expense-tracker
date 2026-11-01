// Builds the demo database: two years of a made-up household (no real data),
// imported through the real Desjardins plug-in, then reviewed as its owner
// would have.
//
// Usage: dart run demo:database <folder>\expenses.sqlite
//   then: EXPENSES_DB_DIR=<folder> EXPENSES_DB_PASSWORD=<password> expense_desktop.exe
//   Encrypted like every database, with EXPENSES_DB_PASSWORD or the public demo
//   password (demo data only).
import 'dart:io';

import 'package:demo/src/database.dart';
import 'package:demo/src/showcase.dart' show demoPassword;
import 'package:storage/storage.dart';

Future<void> main(List<String> args) async {
  if (args.length != 1) {
    stderr.writeln('Usage: dart run demo:database <database file>');
    exitCode = 64;
    return;
  }
  final file = File(args.single);
  if (file.existsSync()) {
    stderr.writeln('${file.path} exists: the demo goes into a new file.');
    exitCode = 73;
    return;
  }
  final password = Platform.environment['EXPENSES_DB_PASSWORD'] ?? demoPassword;
  final db = openEncryptedDatabase(file, password);
  await fillDemoDatabase(db);
  await db.close();
  stdout.writeln('Demo database: ${file.path}');
  if (password == demoPassword) stdout.writeln('Password: $demoPassword');
}
