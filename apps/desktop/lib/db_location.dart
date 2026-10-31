import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Folder of the database: `EXPENSES_DB_DIR` (tests, demos) or the app
/// support folder (%APPDATA%\\dev.lasagna\\expense-tracker, from the company
/// and product names in `windows/runner/Runner.rc`).
Future<Directory> databaseDirectory() async {
  final override = Platform.environment['EXPENSES_DB_DIR'];
  return override == null ? getApplicationSupportDirectory() : Directory(override);
}

/// Password of a scratch database (demos, `tools\ui-probe.ps1`): read from
/// `EXPENSES_DB_PASSWORD` only together with `EXPENSES_DB_DIR`, so a
/// password left in the environment never opens the real database.
String? scratchPassword() {
  final env = Platform.environment;
  return env['EXPENSES_DB_DIR'] == null ? null : env['EXPENSES_DB_PASSWORD'];
}

Future<String> databasePath() async => p.join((await databaseDirectory()).path, 'expenses.sqlite');
