import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// The unlocked database file, given to the app by the password screen.
class DatabaseSession {
  const DatabaseSession({required this.file, required this.isHome, required this.lock});

  final File file;

  /// The app's own file; another one is named in the top bar.
  final bool isHome;

  /// Closes the database and shows the password screen again.
  final void Function() lock;
}

/// Database files the password screen offers, most recently opened first:
/// the app's own file ([home]) and others opened with "Ouvrir un autre
/// fichier" (an anonymized developer copy, a copy someone shared).
///
/// Stored as plain JSON next to [home] because it is read before any
/// password: paths only, never a password or anything from a database.
class DatabaseList {
  DatabaseList._(this.store, this.home, this._paths);

  /// Reads `databases.json` in [folder], the folder of the app's own
  /// `expenses.sqlite`. A missing or damaged list starts with that file only.
  factory DatabaseList.load(Directory folder) {
    final store = File(p.join(folder.path, 'databases.json'));
    final home = File(p.join(folder.path, 'expenses.sqlite'));
    var paths = <String>[];
    try {
      final json = jsonDecode(store.readAsStringSync());
      paths = [for (final v in (json as Map)['recent'] as List) v as String];
    } on Object {
      // Missing or not ours: start again from the app's own file.
    }
    return DatabaseList._(store, home, paths).._clean();
  }

  /// At most this many files, the app's own one included.
  static const max = 8;

  final File store;

  /// The app's own database, always listed (`%APPDATA%\dev.lasagna\expense-tracker`).
  final File home;
  final List<String> _paths;

  List<File> get files => [for (final path in _paths) File(path)];

  /// Opened at start: the last one unlocked, while it still exists.
  File get last => files.firstWhere((f) => f.existsSync(), orElse: () => home);

  bool isHome(File file) => _same(file.path, home.path);

  /// [file] was unlocked: first in the list.
  void use(File file) {
    _paths.removeWhere((path) => _same(path, file.path));
    _paths.insert(0, p.normalize(p.absolute(file.path)));
    _clean();
    _save();
  }

  /// Off the list (the file itself is left alone); the app's own one stays.
  void forget(File file) {
    if (isHome(file)) return;
    _paths.removeWhere((path) => _same(path, file.path));
    _save();
  }

  static bool _same(String a, String b) => p.equals(p.absolute(a), p.absolute(b));

  void _clean() {
    final seen = <String>[];
    for (final path in _paths) {
      if (path.isNotEmpty && !seen.any((s) => _same(s, path))) seen.add(path);
    }
    if (!seen.any((s) => _same(s, home.path))) seen.add(home.path);
    // Too many: the oldest others go, never the app's own file.
    while (seen.length > max) {
      seen.removeAt(seen.lastIndexWhere((s) => !_same(s, home.path)));
    }
    _paths
      ..clear()
      ..addAll(seen);
  }

  void _save() {
    store.parent.createSync(recursive: true);
    store.writeAsStringSync(const JsonEncoder.withIndent('  ').convert({'recent': _paths}));
  }
}
