// Builds what a demo starts from (docs/13-demo.md): a persona's database with
// every statement but the last card statement, reviewed, and that card period
// as AccèsD exports to drop on the Import page.
//
// Usage: dart run demo:showcase <folder> [--persona couple|freelancer]
//   writes <folder>\expenses.sqlite (encrypted with EXPENSES_DB_PASSWORD or the
//   public demo password) and <folder>\releve-carte-<card>.csv.
//   demo.bat runs it and starts the app on the folder.
import 'dart:io';

import 'package:demo/demo.dart';
import 'package:demo/src/showcase.dart';
import 'package:storage/storage.dart';

Future<void> main(List<String> args) async {
  final rest = [...args];
  var id = 'couple';
  final flag = rest.indexOf('--persona');
  if (flag >= 0) {
    if (flag + 1 >= rest.length) return _usage();
    id = rest[flag + 1];
    rest.removeRange(flag, flag + 2);
  }
  if (rest.length != 1) return _usage();
  final persona = personas[id];
  if (persona == null) {
    stderr.writeln('Unknown persona "$id". Personas: ${personas.keys.join(', ')}.');
    exitCode = 64;
    return;
  }
  final folder = Directory(rest.single)..createSync(recursive: true);
  final file = File('${folder.path}${Platform.pathSeparator}expenses.sqlite');
  if (file.existsSync()) {
    stderr.writeln('${file.path} exists: the demo goes into a new file.');
    exitCode = 73;
    return;
  }
  final password = Platform.environment['EXPENSES_DB_PASSWORD'] ?? demoPassword;
  final db = openEncryptedDatabase(file, password);
  final csvs = await fillShowcaseDatabase(db, persona);
  await db.close();
  stdout.writeln('Demo database (${persona.id}): ${file.path}');
  for (final MapEntry(key: name, value: text) in csvs.entries) {
    final csv = File('${folder.path}${Platform.pathSeparator}$name')..writeAsStringSync(text);
    stdout.writeln('To drop on the Import page: ${csv.path}');
  }
  if (password == demoPassword) stdout.writeln('Password: $demoPassword');
}

void _usage() {
  stderr.writeln('Usage: dart run demo:showcase <folder> [--persona ${personas.keys.join('|')}]');
  exitCode = 64;
}
