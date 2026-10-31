import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:core/core.dart';
import 'package:sqlite3/sqlite3.dart';

import 'encryption.dart';

/// Anonymized developer copy of the whole database: what a developer (or a
/// cloud coding agent) may look at to work on real-looking data. One-way: it
/// is never a backup ([Backups.stageRestore] refuses it).
///
/// Built in memory from the database, so no readable copy of the real data
/// is ever written. Words are kept only when they are on a public list
/// (allowlist, not blocklist): the bank's own wording ([keepWords], from the
/// plug-ins' line rules), the categorizer's generic keywords, the default
/// category names and a few common words. Everything else is replaced,
/// consistently across tables:
///
/// - every merchant → `MARCHAND 001`…, known chains too (Costco, IGA: the
///   copy must not tell where the owner shops), people (Interac) → `PERSONNE01`…, cities → `VILLE01`…, cards → `CARTE 1`…;
/// - descriptions keep their allowed words, other words become the line's
///   placeholder, digits become `9`;
/// - notes → `note`; account names, references and file names masked;
/// - every amount multiplied by one random factor (not stored): ratios,
///   equal amounts, recurring payments and splits stay consistent, real
///   figures don't show;
/// - categories, rules, targets, dates, kinds, review state kept (a word of a
///   user category name that also appears in the personal data is masked).
///
/// Before the copy is written, every text cell, then every byte of the file,
/// is checked against the words of the original data that were not allowed:
/// one found = [DevCopyLeak], nothing written. The file is then encrypted
/// with [password] (a password given to the developer, not the owner's).
/// Synchronous and slow (key derivation, whole database): run it in an isolate.
DevCopyReport writeDevCopy({
  required File source,
  required String? sourcePassword,
  required File target,
  required String password,
  Iterable<String> keepWords = const [],
  Iterable<String> extraSecrets = const [],
  Random? random,
}) {
  if (passwordProblem(password) != null) throw ArgumentError('password too short');
  if (target.existsSync()) throw ArgumentError('target exists: ${target.path}');
  if (source.absolute.path == target.absolute.path) throw ArgumentError('target is the database');
  final mem = sqlite3.openInMemory();
  try {
    _load(mem, source, sourcePassword);
    final anonymizer = _Anonymizer(mem, keepWords, random ?? Random.secure());
    final secrets = anonymizer.collectSecrets(extraSecrets);
    final counts = anonymizer.run();
    mem.execute('CREATE TABLE $devCopyTable (made_at TEXT NOT NULL)');
    mem.execute('INSERT INTO $devCopyTable VALUES (?)', [DateTime.now().toIso8601String()]);
    mem.execute('VACUUM');
    final cells = _checkCells(mem, secrets);
    _writeChecked(mem, target, secrets);
    encryptInPlace(target, password);
    return DevCopyReport(
      merchantsReplaced: counts.merchantsReplaced,
      people: counts.people,
      cities: counts.cities,
      notes: counts.notes,
      accounts: counts.accounts,
      checkedCells: cells,
      checkedWords: secrets.length,
      categoryIds: anonymizer.categoryIds,
    );
  } finally {
    mem.close();
  }
}

void _load(Database mem, File source, String? sourcePassword) {
  final src = sourcePassword == null
      ? sqlite3.open(source.path, mode: OpenMode.readOnly)
      : openKeyed(source, sourcePassword, readOnly: true);
  try {
    _copyInto(src, mem);
  } finally {
    src.close();
  }
}

/// Every text cell of [mem] against [secrets]; returns how many were checked.
int _checkCells(Database mem, Set<String> secrets) {
  final leaks = <String>{}, places = <String>{};
  var cells = 0;
  for (final table in _tables(mem)) {
    final rows = mem.select('SELECT * FROM "$table"');
    for (final row in rows) {
      for (final (i, v) in row.values.indexed) {
        if (v is! String) continue;
        cells++;
        for (final w in _words(_withoutIds(v)).where(secrets.contains)) {
          leaks.add(w);
          places.add('$table.${rows.columnNames[i]}');
        }
      }
    }
  }
  if (leaks.isNotEmpty) throw DevCopyLeak(leaks.toList()..sort(), places: places.toList()..sort());
  return cells;
}

/// Writes [mem] to [target] (anonymized, before encryption) and reads every
/// byte back (indexes, free pages) against [secrets]; deletes it on a leak.
void _writeChecked(Database mem, File target, Set<String> secrets) {
  mem.execute('VACUUM INTO ${_quoted(target.path)}');
  final text = utf8.decode(target.readAsBytesSync(), allowMalformed: true);
  final leaks = _words(_withoutIds(text)).where((w) => w.length >= 6 && secrets.contains(w)).toSet();
  if (leaks.isEmpty) return;
  target.deleteSync();
  throw DevCopyLeak(leaks.toList()..sort());
}

/// Random ids the app makes (`uuid` v4: line ids, transfer groups): their
/// hex letters sometimes spell an original word (`BEAC`) by chance.
String _withoutIds(String s) =>
    s.replaceAll(RegExp(r'[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}'), ' ');

/// Table marking a developer copy.
const devCopyTable = 'dev_copy';

/// Whether the open database [db] is an anonymized developer copy.
bool isDevCopy(Database db) =>
    db.select("SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = ?", [devCopyTable]).isNotEmpty;

/// Words of the original data found in the copy: nothing was written. Shown
/// to the owner only (they are their data).
class DevCopyLeak implements Exception {
  const DevCopyLeak(this.words, {this.places = const []});

  final List<String> words;

  /// `table.column` where they were found (empty: in the file's bytes).
  final List<String> places;

  @override
  String toString() => 'DevCopyLeak(${words.length} words)';
}

/// What [writeDevCopy] replaced, and how much it checked.
class DevCopyReport {
  const DevCopyReport({
    required this.merchantsReplaced,
    required this.people,
    required this.cities,
    required this.notes,
    required this.accounts,
    required this.checkedCells,
    required this.checkedWords,
    this.categoryIds = const {},
  });

  final int merchantsReplaced;
  final int people;
  final int cities;
  final int notes;
  final int accounts;

  /// Text cells of the copy checked for original words.
  final int checkedCells;

  /// Distinct original words that had to be absent.
  final int checkedWords;

  /// User category id → id in the copy (the owner's side, to read a
  /// developer's findings).
  final Map<String, String> categoryIds;
}

/// Schema, rows and schema version of [src] into the empty [mem] (SQLite's
/// backup API doesn't copy from an encrypted file into memory).
void _copyInto(Database src, Database mem) {
  final schema = src.select(
    "SELECT type, name, sql FROM sqlite_master WHERE sql IS NOT NULL AND name NOT LIKE 'sqlite_%'",
  );
  mem.execute('BEGIN');
  for (final r in schema.where((r) => r['type'] == 'table')) {
    mem.execute(r['sql'] as String);
    final table = r['name'] as String;
    final rows = src.select('SELECT * FROM "$table"');
    if (rows.isEmpty) continue;
    final columns = rows.columnNames.map((c) => '"$c"').join(', ');
    final insert = mem.prepare(
      'INSERT INTO "$table" ($columns) VALUES (${List.filled(rows.columnNames.length, '?').join(', ')})',
    );
    try {
      for (final row in rows) {
        insert.execute(row.values);
      }
    } finally {
      insert.close();
    }
  }
  for (final r in schema.where((r) => r['type'] != 'table')) {
    mem.execute(r['sql'] as String);
  }
  mem.execute('COMMIT');
  mem.execute('PRAGMA user_version = ${src.select('PRAGMA user_version').first.values.first}');
}

/// A digit run already masked (`9999`): not anyone's number.
final _masked = RegExp(r'^9+$');

/// `creditCard` → `credit Card`.
String _splitCamel(String s) => s.replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}');

String _quoted(String s) => "'${s.replaceAll("'", "''")}'";

List<String> _tables(Database db) => [
  for (final r in db.select("SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%'"))
    r['name'] as String,
];

final _wordPattern = RegExp(r"[A-Z]+|[0-9]+");

/// Words to compare: upper case without accents, letters (4 or more) and
/// digit runs (5 or more: account, phone, reference numbers).
Iterable<String> _words(String s) => _wordPattern
    .allMatches(stripAccents(s))
    .map((m) => m[0]!)
    .where((w) => w.codeUnitAt(0) >= 65 ? w.length >= 4 : w.length >= 5);

/// Common words of bank lines and shop names, kept as they are.
const _commonWords = {
  'ACHAT', 'PAIEMENT', 'VIREMENT', 'RETRAIT', 'DEPOT', 'FRAIS', 'INTERET', 'INTERETS', 'INTERAC', 'ACCESD', //
  'GUICHET', 'CARTE', 'PAIE', 'REMBOURSEMENT', 'ANNULATION', 'PRET', 'TAXE', 'TAXES', 'CREDIT', 'DEBIT', //
  'SOLDE', 'COMPTE', 'TRANSFERT', 'ENVOYE', 'RECU', 'FACTURE', 'MENSUEL', 'MENSUELS', 'ANNUEL', 'AUTOMATIQUE', //
  'PREAUTORISE', 'COTISATION', 'ABONNEMENT', 'ONLINE', 'STORE', 'SHOP', 'SERVICE', 'SERVICES', 'CENTRE', //
  'CENTER', 'MARKET', 'GROUP', 'GROUPE', 'CANADA', 'QUEBEC', 'PAYMENT', 'TRANSFER', 'REFUND', 'PURCHASE', //
  'FROM', 'WITH', 'POUR', 'AVEC', 'SANS', 'DANS', 'CHEZ', 'MARCHAND', 'PERSONNE', 'VILLE', 'NOTE', 'RELEVE', //
};

class _Counts {
  int merchantsReplaced = 0, people = 0, cities = 0, notes = 0, accounts = 0;
}

class _Anonymizer {
  _Anonymizer(this.db, Iterable<String> keepWords, Random random)
    // One factor for every amount, away from 1 so no real figure survives.
    : factor = (random.nextBool() ? 1 : -1) * (0.08 + random.nextDouble() * 0.22) + 1 {
    for (final w in [
      ...keepWords,
      ..._commonWords,
      for (final k in keywordCategories) k.$1,
      for (final c in defaultCategories) ...[c.nameFr, c.nameEn],
      // Ids and codes the app or the plug-ins define (`desjardins-account`, `creditCard`, `food.coffee`).
      for (final r in db.select('SELECT institution, format, file_type FROM statements')) ...[
        r['institution'] as String,
        r['format'] as String,
        r['file_type'] as String,
      ],
      for (final r in db.select('SELECT institution, type, currency FROM accounts')) ...[
        r['institution'] as String,
        _splitCamel(r['type'] as String),
        r['currency'] as String,
      ],
      // Default category ids only: a user's own ids are renamed (`custom.c01`).
      for (final c in defaultCategories) c.id,
      ...retiredCategories.keys,
      // The schema (table and column names are in the file too).
      for (final r in db.select('SELECT sql FROM sqlite_master WHERE sql IS NOT NULL')) r['sql'] as String,
    ]) {
      _allowed.addAll(_wordPattern.allMatches(stripAccents(w)).map((m) => m[0]!));
    }
    // Chain names say where the owner shops, even when a public list has the
    // word (`SAQ` in the category `Alcool (SAQ)`); the bank's wording stays.
    final bankWords = {for (final w in keepWords) ..._wordPattern.allMatches(stripAccents(w)).map((m) => m[0]!)};
    _chainWords.addAll(
      {for (final k in seedMerchantCategories.keys) ..._wordPattern.allMatches(stripAccents(k)).map((m) => m[0]!)}
          .difference(bankWords),
    );
  }

  final Database db;
  final double factor;
  final _allowed = <String>{};
  final _chainWords = <String>{};
  final _counts = _Counts();

  final _merchantName = <int, String>{};
  final _merchantKey = <String, String>{};
  final _cities = <String, String>{};
  final _cards = <String, String>{};

  /// Kept in a description: allowed and not a chain's name.
  bool _isAllowed(String upperWord) =>
      (_allowed.contains(upperWord) && !_chainWords.contains(upperWord)) || RegExp(r'^[0-9]+$').hasMatch(upperWord);

  int _scale(int cents) => (cents * factor).round();

  /// Words of the original personal texts that are not allowed: none may
  /// appear in the copy.
  Set<String> collectSecrets(Iterable<String> extra) {
    final texts = <String?>[
      ...extra,
      for (final r in db.select('SELECT description, location, note, card FROM transactions'))
        ...[r['description'], r['location'], r['note'], r['card']].cast<String?>(),
      for (final r in db.select('SELECT key, name FROM merchants')) ...[r['key'] as String, r['name'] as String],
      for (final r in db.select('SELECT ref, name FROM accounts')) ...[r['ref'] as String, r['name'] as String],
      for (final r in db.select('SELECT file_name FROM statements')) r['file_name'] as String,
      for (final r in db.select('SELECT description_contains, merchant_key FROM rules'))
        ...[r['description_contains'], r['merchant_key']].cast<String?>(),
    ];
    return collectSecretsOfOriginal = {
      for (final t in texts.whereType<String>())
        for (final w in _words(t))
          if (!_allowed.contains(w) && !_masked.hasMatch(w)) w,
    };
  }

  /// [text] with its allowed words; runs of other words become [placeholder]
  /// once, digits become 9.
  String _text(String text, String placeholder) {
    final out = StringBuffer();
    var replacing = false;
    // Whitespace after a replaced word: written only if the next word is kept.
    var pending = '';
    for (final m in RegExp(r"[\p{L}']+|[0-9]+|[^\p{L}0-9']+", unicode: true).allMatches(text)) {
      final part = m[0]!;
      final isWord = RegExp(r"^[\p{L}']+$", unicode: true).hasMatch(part);
      if (isWord && !_wordPattern.allMatches(stripAccents(part)).map((x) => x[0]!).every(_isAllowed)) {
        if (!replacing) out.write(placeholder);
        replacing = true;
        pending = '';
        continue;
      }
      if (replacing && part.trim().isEmpty) {
        pending = part;
        continue;
      }
      out.write(pending);
      pending = '';
      replacing = false;
      out.write(RegExp(r'^[0-9]+$').hasMatch(part) ? '9' * part.length : part);
    }
    return out.toString().replaceAll(RegExp(r' {2,}'), ' ').trim();
  }

  String _city(String location) {
    final parts = location.trim().split(RegExp(r'\s+'));
    final region = parts.length > 1 && RegExp(r'^[A-Z]{2}$').hasMatch(parts.last) ? parts.removeLast() : null;
    final key = stripAccents(parts.join(' '));
    final city = _cities.putIfAbsent(key, () {
      _counts.cities++;
      return 'VILLE${(_cities.length + 1).toString().padLeft(2, '0')}';
    });
    return region == null ? city : '$city $region';
  }

  _Counts run() {
    _merchants();
    _transactions();
    _splits();
    _accountsAndStatements();
    _rules();
    db.execute('UPDATE targets SET amount = CAST(round(amount * ?) AS INTEGER)', [factor]);
    _userCategories();
    return _counts;
  }

  void _merchants() {
    final people = {
      for (final r in db.select('SELECT DISTINCT merchant_id AS id FROM transactions WHERE is_person = 1'))
        if (r['id'] != null) r['id'] as int,
    };
    var merchants = 0, persons = 0;
    final newKeys = <int, String>{};
    for (final r in db.select('SELECT id, key, name FROM merchants ORDER BY id')) {
      final id = r['id'] as int, key = r['key'] as String;
      String newKey, newName;
      if (people.contains(id)) {
        newKey = newName = 'PERSONNE${(++persons).toString().padLeft(2, '0')}';
        _counts.people++;
      } else {
        final n = (++merchants).toString().padLeft(3, '0');
        newKey = 'MARCHAND $n';
        newName = 'Marchand $n';
        _counts.merchantsReplaced++;
      }
      _merchantName[id] = newName;
      _merchantKey[key] = newKey;
      newKeys[id] = newKey;
      // Temporary unique key: a new key may equal another row's old one.
      db.execute('UPDATE merchants SET key = ?, name = ? WHERE id = ?', ['~$id', newName, id]);
    }
    for (final e in newKeys.entries) {
      db.execute('UPDATE merchants SET key = ? WHERE id = ?', [e.value, e.key]);
    }
  }

  void _transactions() {
    final rows = db.select(
      'SELECT id, description, location, note, card, amount, foreign_cents, merchant_id, is_person, fingerprint '
      'FROM transactions',
    );
    final update = db.prepare(
      'UPDATE transactions SET description = ?, location = ?, note = ?, card = ?, amount = ?, foreign_cents = ?, '
      'fingerprint = ? WHERE id = ?',
    );
    try {
      for (final r in rows) {
        final merchantId = r['merchant_id'] as int?;
        final placeholder = merchantId == null ? 'XXX' : _merchantName[merchantId] ?? 'XXX';
        final location = r['location'] as String?;
        final note = r['note'] as String?;
        final card = r['card'] as String?;
        if (note != null) _counts.notes++;
        update.execute([
          _text(r['description'] as String, placeholder.toUpperCase()),
          location == null || location.trim().isEmpty ? location : _city(location),
          note == null ? null : 'note',
          card == null ? null : _cards.putIfAbsent(card, () => 'CARTE ${_cards.length + 1}'),
          _scale(r['amount'] as int),
          r['foreign_cents'] == null ? null : _scale(r['foreign_cents'] as int),
          r['fingerprint'] == null ? null : 'dev-${r['id']}',
          r['id'],
        ]);
      }
    } finally {
      update.close();
    }
  }

  /// Split amounts scaled, then the largest adjusted so they still add up.
  void _splits() {
    final totals = {
      for (final r in db.select('SELECT id, amount FROM transactions')) r['id'] as String: r['amount'] as int,
    };
    final byTxn = <String, List<(int, int)>>{};
    for (final r in db.select('SELECT id, transaction_id, amount FROM splits')) {
      byTxn.putIfAbsent(r['transaction_id'] as String, () => []).add((r['id'] as int, _scale(r['amount'] as int)));
    }
    for (final e in byTxn.entries) {
      final parts = e.value;
      final diff = (totals[e.key] ?? 0) - parts.fold<int>(0, (s, p) => s + p.$2);
      var largest = 0;
      for (var i = 1; i < parts.length; i++) {
        if (parts[i].$2.abs() > parts[largest].$2.abs()) largest = i;
      }
      parts[largest] = (parts[largest].$1, parts[largest].$2 + diff);
      for (final (id, amount) in parts) {
        db.execute('UPDATE splits SET amount = ? WHERE id = ?', [amount, id]);
      }
    }
  }

  void _accountsAndStatements() {
    final perType = <String, int>{};
    for (final r in db.select('SELECT id, type, balance FROM accounts ORDER BY id')) {
      final type = r['type'] as String;
      final n = perType[type] = (perType[type] ?? 0) + 1;
      _counts.accounts++;
      db.execute('UPDATE accounts SET ref = ?, name = ?, balance = ? WHERE id = ?', [
        '$type-${n.toString().padLeft(2, '0')}',
        'Compte ${r['id']} ($type)',
        r['balance'] == null ? null : _scale(r['balance'] as int),
        r['id'],
      ]);
    }
    db.execute("UPDATE statements SET file_hash = 'dev-' || id, file_name = 'releve-' || id || '.' || file_type");
  }

  void _rules() {
    final names = {for (final e in _merchantKey.entries) e.key: e.value};
    for (final r in db.select('SELECT id, description_contains, merchant_key FROM rules')) {
      final key = r['merchant_key'] as String?;
      final contains = r['description_contains'] as String?;
      final mapped = key == null ? null : names[key] ?? 'MARCHAND ?';
      db.execute('UPDATE rules SET merchant_key = ?, description_contains = ? WHERE id = ?', [
        mapped,
        contains == null ? null : _text(contains, names[stripAccents(contains).trim()] ?? 'XXX'),
        r['id'],
      ]);
    }
  }

  /// User categories keep their names, except words that are personal data.
  /// Their ids (which the user may have typed) become `custom.c01`, or
  /// `<default group>.c01` under a default group, everywhere they are used.
  void _userCategories() {
    final defaults = {for (final c in defaultCategories) c.id, ...retiredCategories.keys};
    final personal = collectSecretsOfOriginal;
    String clean(String s) => s.splitMapJoin(
      RegExp(r'[\p{L}]+', unicode: true),
      onMatch: (m) => personal.contains(stripAccents(m[0]!)) ? 'XXX' : m[0]!,
    );
    final rows = db.select('SELECT id, parent_id, name_fr, name_en FROM categories ORDER BY sort_order, id');
    final renamed = <String, String>{};
    var n = 0;
    for (final r in rows) {
      final id = r['id'] as String;
      if (defaults.contains(id)) continue;
      final parent = r['parent_id'] as String?;
      final prefix = parent != null && defaults.contains(parent) ? parent : 'custom';
      renamed[id] = '$prefix.c${(++n).toString().padLeft(2, '0')}';
      db.execute('UPDATE categories SET name_fr = ?, name_en = ? WHERE id = ?', [
        clean(r['name_fr'] as String),
        clean(r['name_en'] as String),
        id,
      ]);
    }
    for (final e in renamed.entries) {
      for (final (table, column) in const [
        ('categories', 'id'),
        ('categories', 'parent_id'),
        ('transactions', 'category_id'),
        ('merchants', 'category_id'),
        ('rules', 'category_id'),
        ('splits', 'category_id'),
        ('targets', 'category_id'),
      ]) {
        db.execute('UPDATE $table SET $column = ? WHERE $column = ?', [e.value, e.key]);
      }
    }
    categoryIds = renamed;
  }

  /// User category id → its id in the copy.
  Map<String, String> categoryIds = const {};

  /// Set by [collectSecrets] (before the data is rewritten).
  Set<String> collectSecretsOfOriginal = const {};
}
