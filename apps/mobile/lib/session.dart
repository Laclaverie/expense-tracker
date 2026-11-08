import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:storage/storage.dart';

import 'phone_store.dart';

enum UnlockOutcome { opened, openedPrevious, wrong }

typedef PasswordCheck = Future<bool> Function(String path, String password);
typedef DatabaseOpener = ExpenseDatabase Function(File file, String password);

/// Key derivation is slow on purpose: runs in an isolate. A top-level function, because `Isolate.run` inside
/// a State method would capture `this` (see CLAUDE.md).
Future<bool> checkPasswordInIsolate(String path, String password) =>
    Isolate.run(() => passwordOpens(File(path), password));

/// The open database and its password, in memory only. Locking closes the database and forgets the password.
class Session extends ChangeNotifier {
  Session(this.store, {PasswordCheck? check, DatabaseOpener? open})
    : _check = check ?? checkPasswordInIsolate,
      _open = open ?? openReadOnlyDatabase;

  final PhoneStore store;
  final PasswordCheck _check;
  final DatabaseOpener _open;

  ExpenseDatabase? _db;
  late Locale? _locale = _localeOf(store.readLanguage());
  String? _password;
  bool _usingPrevious = false;

  /// Bumped by [lock]: anything that started before a lock must not reopen the database afterwards.
  int _generation = 0;

  static Locale? _localeOf(String? code) => code == null ? null : Locale(code);

  /// The chosen language; null follows the device.
  Locale? get locale => _locale;

  void setLanguage(String? code) {
    store.saveLanguage(code);
    _locale = _localeOf(code);
    notifyListeners();
  }

  ExpenseDatabase? get db => _db;
  bool get unlocked => _db != null;

  /// The new data is locked with another password: the previous copy is open until it is entered.
  bool get usingPrevious => _usingPrevious;

  Future<UnlockOutcome> unlock(String password) async {
    final generation = _generation;
    final file = store.openable;
    if (file == null) return UnlockOutcome.wrong;
    final opens = await _check(file.path, password);
    if (generation != _generation) return UnlockOutcome.wrong;
    if (opens) {
      _db = _open(file, password);
      _password = password;
      _usingPrevious = false;
      if (file.path == store.database.path) store.dropPrevious();
      notifyListeners();
      return UnlockOutcome.opened;
    }
    if (file.path == store.database.path && store.previous.existsSync()) {
      final previousOpens = await _check(store.previous.path, password);
      if (generation != _generation || !previousOpens) return UnlockOutcome.wrong;
      _db = _open(store.previous, password);
      _password = password;
      _usingPrevious = true;
      notifyListeners();
      return UnlockOutcome.openedPrevious;
    }
    return UnlockOutcome.wrong;
  }

  Future<void> _close() async {
    final db = _db;
    _db = null;
    await db?.close();
  }

  Future<void> lock() async {
    _generation++;
    _password = null;
    await _close();
    _password = null;
    _usingPrevious = false;
    notifyListeners();
  }

  /// Downloads newer data with the database closed (the file is swapped), then reopens it with the same
  /// password; if that no longer opens, the password screen comes back.
  Future<UpdateResult> sync({void Function(int received, int total)? progress}) async {
    final password = _password;
    final generation = _generation;
    await _close();
    try {
      return await store.update(progress: progress);
    } finally {
      // A lock during the transfer wins: never reopen with the password it forgot.
      if (password != null && generation == _generation) {
        final outcome = await unlock(password);
        if (outcome == UnlockOutcome.wrong && generation == _generation) _password = null;
      }
      notifyListeners();
    }
  }
}
