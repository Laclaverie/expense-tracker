import 'package:drift/drift.dart';

/// One account at one institution. Cash wallets use institution `cash` and
/// ref `cash-CAD`, `cash-EUR`.
@TableIndex(name: 'accounts_ref', columns: {#institution, #ref}, unique: true)
class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// `desjardins`, `lcl`, `cash`. Also the statistics scope.
  TextColumn get institution => text()();

  /// Stable reference inside the institution: `EOP`, `ET 1`, `card-0001`.
  TextColumn get ref => text()();
  TextColumn get name => text()();

  /// `AccountType.name`.
  TextColumn get type => text()();
  TextColumn get currency => text()();

  /// From the most recent statement.
  IntColumn get balance => integer().nullable()();
  DateTimeColumn get balanceDate => dateTime().nullable()();
}

/// An imported statement file. The PDF itself is not kept.
class Statements extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get institution => text()();
  TextColumn get format => text()();
  DateTimeColumn get periodStart => dateTime()();
  DateTimeColumn get periodEnd => dateTime()();

  /// Only the closing date is printed: covers the days since the previous
  /// statement of the same format (`ImportedStatement.coversSincePrevious`).
  BoolColumn get coversSincePrevious => boolean().withDefault(const Constant(false))();

  /// SHA-256 of the file: re-importing the same file is detected.
  TextColumn get fileHash => text().unique()();
  TextColumn get fileName => text()();
  DateTimeColumn get importedAt => dateTime()();
  IntColumn get lineCount => integer()();
  IntColumn get newCount => integer()();

  /// File type it was read from (`pdf`, `csv`…). Lines of the same account and
  /// day read from another file type are the same lines told differently.
  TextColumn get fileType => text().withDefault(const Constant('pdf'))();

  /// False when the file had nothing to check its lines against (a card CSV
  /// export has no balance): shown as not verified.
  BoolColumn get verified => boolean().withDefault(const Constant(true))();
}

@DataClassName('CategoryRow')
class Categories extends Table {
  /// Stable key, e.g. `food.coffee`.
  TextColumn get id => text()();
  TextColumn get parentId => text().nullable()();
  TextColumn get nameFr => text()();
  TextColumn get nameEn => text()();

  /// `CategoryType.name`.
  TextColumn get type => text()();
  IntColumn get color => integer()();

  /// Defaults follow `defaultCategories` order; user categories come after (1000+).
  IntColumn get sortOrder => integer()();

  /// Hidden from pickers; kept so old references still have a name.
  BoolColumn get archived => boolean().withDefault(const Constant(false))();

  /// Left out of the "share without excluded" figures (Statistics → Categories),
  /// e.g. rent or taxes. A group's flag covers its categories.
  BoolColumn get excludedFromShare => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class Merchants extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// From `normalizeMerchant`.
  TextColumn get key => text().unique()();
  TextColumn get name => text()();

  /// Category the user chose for this merchant: applied to future imports.
  TextColumn get categoryId => text().nullable().references(Categories, #id)();
}

@DataClassName('RuleRow')
class Rules extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get categoryId => text().references(Categories, #id)();
  TextColumn get descriptionContains => text().nullable()();
  TextColumn get merchantKey => text().nullable()();
  TextColumn get code => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

@DataClassName('Txn')
@TableIndex(name: 'transactions_account_date', columns: {#accountId, #date})
class Transactions extends Table {
  /// UUID, so entries created on the phone can be merged later.
  TextColumn get id => text()();
  IntColumn get accountId => integer().references(Accounts, #id)();
  DateTimeColumn get date => dateTime()();
  DateTimeColumn get postedDate => dateTime().nullable()();

  /// Signed cents in the account currency. Negative = money out.
  IntColumn get amount => integer()();

  /// Exactly as on the statement (or typed for manual entries). Never edited.
  TextColumn get description => text()();
  TextColumn get code => text().nullable()();
  TextColumn get location => text().nullable()();
  IntColumn get bonusRate => integer().nullable()();
  IntColumn get foreignCents => integer().nullable()();
  TextColumn get foreignCurrency => text().nullable()();
  TextColumn get fxRate => text().nullable()();
  TextColumn get card => text().nullable()();

  /// `TransactionKind.name`.
  TextColumn get kind => text()();
  IntColumn get merchantId => integer().nullable().references(Merchants, #id)();
  TextColumn get categoryId => text().nullable().references(Categories, #id)();

  /// `Confidence.name` of the category; `user` once set by hand.
  TextColumn get confidence => text()();

  /// True while the transaction waits in the review queue.
  BoolColumn get needsReview => boolean()();
  TextColumn get note => text().nullable()();

  /// `statement` or `manual`.
  TextColumn get source => text()();
  IntColumn get statementId => integer().nullable().references(Statements, #id)();

  /// See `lineFingerprint`. Null for manual entries.
  TextColumn get fingerprint => text().nullable().unique()();

  /// Same value on both sides of a matched transfer.
  TextColumn get transferGroup => text().nullable()();

  /// Counterparty is a person (Interac transfer): excluded from merchant rankings.
  BoolColumn get isPerson => boolean().withDefault(const Constant(false))();

  /// Marked "normal" by the user: never an alert, left out of usual amounts.
  BoolColumn get anomalyOk => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Part of a transaction in another category (a Costco receipt: groceries +
/// household). When a transaction has splits, statistics use them instead of
/// the transaction's own category; their amounts add up to the transaction's.
@DataClassName('Split')
class Splits extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get transactionId => text().references(Transactions, #id, onDelete: KeyAction.cascade)();
  TextColumn get categoryId => text().references(Categories, #id)();

  /// Signed cents, same sign as the transaction.
  IntColumn get amount => integer()();
}

/// Spending target for one scope: all spending (no category), a group or a
/// category, per week, month or year.
@DataClassName('TargetRow')
class Targets extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// `Scope.id`: `desjardins`, `cash-CAD`…
  TextColumn get scope => text()();
  TextColumn get categoryId => text().nullable().references(Categories, #id)();

  /// `TargetPeriod.name`.
  TextColumn get period => text()();

  /// Cents, in the scope's currency.
  IntColumn get amount => integer()();
  DateTimeColumn get createdAt => dateTime()();
}

/// The phone this database is paired with (read-only mobile app). At most one
/// row (`id` = 1): pairing again replaces it. The secret is never shown; it
/// lives in this encrypted file and, on the phone, in its own storage.
@DataClassName('PairedPhoneRow')
class PairedPhones extends Table {
  IntColumn get id => integer()();

  /// UUID v4 naming this database for the phone.
  TextColumn get databaseId => text()();

  /// 32 random bytes shared with the phone.
  BlobColumn get secret => blob()();
  DateTimeColumn get pairedAt => dateTime()();
  DateTimeColumn get lastSyncAt => dateTime().nullable()();

  /// SHA-256 of the last copy sent to the phone.
  TextColumn get lastSyncHash => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
