// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $AccountsTable extends Accounts with TableInfo<$AccountsTable, Account> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _institutionMeta = const VerificationMeta('institution');
  @override
  late final GeneratedColumn<String> institution = GeneratedColumn<String>(
    'institution',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _refMeta = const VerificationMeta('ref');
  @override
  late final GeneratedColumn<String> ref = GeneratedColumn<String>(
    'ref',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta('currency');
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _balanceMeta = const VerificationMeta('balance');
  @override
  late final GeneratedColumn<int> balance = GeneratedColumn<int>(
    'balance',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _balanceDateMeta = const VerificationMeta('balanceDate');
  @override
  late final GeneratedColumn<DateTime> balanceDate = GeneratedColumn<DateTime>(
    'balance_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, institution, ref, name, type, currency, balance, balanceDate];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'accounts';
  @override
  VerificationContext validateIntegrity(Insertable<Account> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('institution')) {
      context.handle(_institutionMeta, institution.isAcceptableOrUnknown(data['institution']!, _institutionMeta));
    } else if (isInserting) {
      context.missing(_institutionMeta);
    }
    if (data.containsKey('ref')) {
      context.handle(_refMeta, ref.isAcceptableOrUnknown(data['ref']!, _refMeta));
    } else if (isInserting) {
      context.missing(_refMeta);
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(_typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(_currencyMeta, currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta));
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    if (data.containsKey('balance')) {
      context.handle(_balanceMeta, balance.isAcceptableOrUnknown(data['balance']!, _balanceMeta));
    }
    if (data.containsKey('balance_date')) {
      context.handle(_balanceDateMeta, balanceDate.isAcceptableOrUnknown(data['balance_date']!, _balanceDateMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Account map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Account(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      institution: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}institution'])!,
      ref: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}ref'])!,
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      type: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      currency: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}currency'])!,
      balance: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}balance']),
      balanceDate: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}balance_date']),
    );
  }

  @override
  $AccountsTable createAlias(String alias) {
    return $AccountsTable(attachedDatabase, alias);
  }
}

class Account extends DataClass implements Insertable<Account> {
  final int id;

  /// `desjardins`, `lcl`, `cash`. Also the statistics scope.
  final String institution;

  /// Stable reference inside the institution: `EOP`, `ET 1`, `card-0001`.
  final String ref;
  final String name;

  /// `AccountType.name`.
  final String type;
  final String currency;

  /// From the most recent statement.
  final int? balance;
  final DateTime? balanceDate;
  const Account({
    required this.id,
    required this.institution,
    required this.ref,
    required this.name,
    required this.type,
    required this.currency,
    this.balance,
    this.balanceDate,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['institution'] = Variable<String>(institution);
    map['ref'] = Variable<String>(ref);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    map['currency'] = Variable<String>(currency);
    if (!nullToAbsent || balance != null) {
      map['balance'] = Variable<int>(balance);
    }
    if (!nullToAbsent || balanceDate != null) {
      map['balance_date'] = Variable<DateTime>(balanceDate);
    }
    return map;
  }

  AccountsCompanion toCompanion(bool nullToAbsent) {
    return AccountsCompanion(
      id: Value(id),
      institution: Value(institution),
      ref: Value(ref),
      name: Value(name),
      type: Value(type),
      currency: Value(currency),
      balance: balance == null && nullToAbsent ? const Value.absent() : Value(balance),
      balanceDate: balanceDate == null && nullToAbsent ? const Value.absent() : Value(balanceDate),
    );
  }

  factory Account.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Account(
      id: serializer.fromJson<int>(json['id']),
      institution: serializer.fromJson<String>(json['institution']),
      ref: serializer.fromJson<String>(json['ref']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      currency: serializer.fromJson<String>(json['currency']),
      balance: serializer.fromJson<int?>(json['balance']),
      balanceDate: serializer.fromJson<DateTime?>(json['balanceDate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'institution': serializer.toJson<String>(institution),
      'ref': serializer.toJson<String>(ref),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'currency': serializer.toJson<String>(currency),
      'balance': serializer.toJson<int?>(balance),
      'balanceDate': serializer.toJson<DateTime?>(balanceDate),
    };
  }

  Account copyWith({
    int? id,
    String? institution,
    String? ref,
    String? name,
    String? type,
    String? currency,
    Value<int?> balance = const Value.absent(),
    Value<DateTime?> balanceDate = const Value.absent(),
  }) => Account(
    id: id ?? this.id,
    institution: institution ?? this.institution,
    ref: ref ?? this.ref,
    name: name ?? this.name,
    type: type ?? this.type,
    currency: currency ?? this.currency,
    balance: balance.present ? balance.value : this.balance,
    balanceDate: balanceDate.present ? balanceDate.value : this.balanceDate,
  );
  Account copyWithCompanion(AccountsCompanion data) {
    return Account(
      id: data.id.present ? data.id.value : this.id,
      institution: data.institution.present ? data.institution.value : this.institution,
      ref: data.ref.present ? data.ref.value : this.ref,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      currency: data.currency.present ? data.currency.value : this.currency,
      balance: data.balance.present ? data.balance.value : this.balance,
      balanceDate: data.balanceDate.present ? data.balanceDate.value : this.balanceDate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Account(')
          ..write('id: $id, ')
          ..write('institution: $institution, ')
          ..write('ref: $ref, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('currency: $currency, ')
          ..write('balance: $balance, ')
          ..write('balanceDate: $balanceDate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, institution, ref, name, type, currency, balance, balanceDate);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Account &&
          other.id == this.id &&
          other.institution == this.institution &&
          other.ref == this.ref &&
          other.name == this.name &&
          other.type == this.type &&
          other.currency == this.currency &&
          other.balance == this.balance &&
          other.balanceDate == this.balanceDate);
}

class AccountsCompanion extends UpdateCompanion<Account> {
  final Value<int> id;
  final Value<String> institution;
  final Value<String> ref;
  final Value<String> name;
  final Value<String> type;
  final Value<String> currency;
  final Value<int?> balance;
  final Value<DateTime?> balanceDate;
  const AccountsCompanion({
    this.id = const Value.absent(),
    this.institution = const Value.absent(),
    this.ref = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.currency = const Value.absent(),
    this.balance = const Value.absent(),
    this.balanceDate = const Value.absent(),
  });
  AccountsCompanion.insert({
    this.id = const Value.absent(),
    required String institution,
    required String ref,
    required String name,
    required String type,
    required String currency,
    this.balance = const Value.absent(),
    this.balanceDate = const Value.absent(),
  }) : institution = Value(institution),
       ref = Value(ref),
       name = Value(name),
       type = Value(type),
       currency = Value(currency);
  static Insertable<Account> custom({
    Expression<int>? id,
    Expression<String>? institution,
    Expression<String>? ref,
    Expression<String>? name,
    Expression<String>? type,
    Expression<String>? currency,
    Expression<int>? balance,
    Expression<DateTime>? balanceDate,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (institution != null) 'institution': institution,
      if (ref != null) 'ref': ref,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (currency != null) 'currency': currency,
      if (balance != null) 'balance': balance,
      if (balanceDate != null) 'balance_date': balanceDate,
    });
  }

  AccountsCompanion copyWith({
    Value<int>? id,
    Value<String>? institution,
    Value<String>? ref,
    Value<String>? name,
    Value<String>? type,
    Value<String>? currency,
    Value<int?>? balance,
    Value<DateTime?>? balanceDate,
  }) {
    return AccountsCompanion(
      id: id ?? this.id,
      institution: institution ?? this.institution,
      ref: ref ?? this.ref,
      name: name ?? this.name,
      type: type ?? this.type,
      currency: currency ?? this.currency,
      balance: balance ?? this.balance,
      balanceDate: balanceDate ?? this.balanceDate,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (institution.present) {
      map['institution'] = Variable<String>(institution.value);
    }
    if (ref.present) {
      map['ref'] = Variable<String>(ref.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (balance.present) {
      map['balance'] = Variable<int>(balance.value);
    }
    if (balanceDate.present) {
      map['balance_date'] = Variable<DateTime>(balanceDate.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountsCompanion(')
          ..write('id: $id, ')
          ..write('institution: $institution, ')
          ..write('ref: $ref, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('currency: $currency, ')
          ..write('balance: $balance, ')
          ..write('balanceDate: $balanceDate')
          ..write(')'))
        .toString();
  }
}

class $StatementsTable extends Statements with TableInfo<$StatementsTable, Statement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StatementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _institutionMeta = const VerificationMeta('institution');
  @override
  late final GeneratedColumn<String> institution = GeneratedColumn<String>(
    'institution',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _formatMeta = const VerificationMeta('format');
  @override
  late final GeneratedColumn<String> format = GeneratedColumn<String>(
    'format',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _periodStartMeta = const VerificationMeta('periodStart');
  @override
  late final GeneratedColumn<DateTime> periodStart = GeneratedColumn<DateTime>(
    'period_start',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _periodEndMeta = const VerificationMeta('periodEnd');
  @override
  late final GeneratedColumn<DateTime> periodEnd = GeneratedColumn<DateTime>(
    'period_end',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _coversSincePreviousMeta = const VerificationMeta('coversSincePrevious');
  @override
  late final GeneratedColumn<bool> coversSincePrevious = GeneratedColumn<bool>(
    'covers_since_previous',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("covers_since_previous" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _fileHashMeta = const VerificationMeta('fileHash');
  @override
  late final GeneratedColumn<String> fileHash = GeneratedColumn<String>(
    'file_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _fileNameMeta = const VerificationMeta('fileName');
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _importedAtMeta = const VerificationMeta('importedAt');
  @override
  late final GeneratedColumn<DateTime> importedAt = GeneratedColumn<DateTime>(
    'imported_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lineCountMeta = const VerificationMeta('lineCount');
  @override
  late final GeneratedColumn<int> lineCount = GeneratedColumn<int>(
    'line_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _newCountMeta = const VerificationMeta('newCount');
  @override
  late final GeneratedColumn<int> newCount = GeneratedColumn<int>(
    'new_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileTypeMeta = const VerificationMeta('fileType');
  @override
  late final GeneratedColumn<String> fileType = GeneratedColumn<String>(
    'file_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pdf'),
  );
  static const VerificationMeta _verifiedMeta = const VerificationMeta('verified');
  @override
  late final GeneratedColumn<bool> verified = GeneratedColumn<bool>(
    'verified',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("verified" IN (0, 1))'),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    institution,
    format,
    periodStart,
    periodEnd,
    coversSincePrevious,
    fileHash,
    fileName,
    importedAt,
    lineCount,
    newCount,
    fileType,
    verified,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'statements';
  @override
  VerificationContext validateIntegrity(Insertable<Statement> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('institution')) {
      context.handle(_institutionMeta, institution.isAcceptableOrUnknown(data['institution']!, _institutionMeta));
    } else if (isInserting) {
      context.missing(_institutionMeta);
    }
    if (data.containsKey('format')) {
      context.handle(_formatMeta, format.isAcceptableOrUnknown(data['format']!, _formatMeta));
    } else if (isInserting) {
      context.missing(_formatMeta);
    }
    if (data.containsKey('period_start')) {
      context.handle(_periodStartMeta, periodStart.isAcceptableOrUnknown(data['period_start']!, _periodStartMeta));
    } else if (isInserting) {
      context.missing(_periodStartMeta);
    }
    if (data.containsKey('period_end')) {
      context.handle(_periodEndMeta, periodEnd.isAcceptableOrUnknown(data['period_end']!, _periodEndMeta));
    } else if (isInserting) {
      context.missing(_periodEndMeta);
    }
    if (data.containsKey('covers_since_previous')) {
      context.handle(
        _coversSincePreviousMeta,
        coversSincePrevious.isAcceptableOrUnknown(data['covers_since_previous']!, _coversSincePreviousMeta),
      );
    }
    if (data.containsKey('file_hash')) {
      context.handle(_fileHashMeta, fileHash.isAcceptableOrUnknown(data['file_hash']!, _fileHashMeta));
    } else if (isInserting) {
      context.missing(_fileHashMeta);
    }
    if (data.containsKey('file_name')) {
      context.handle(_fileNameMeta, fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta));
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('imported_at')) {
      context.handle(_importedAtMeta, importedAt.isAcceptableOrUnknown(data['imported_at']!, _importedAtMeta));
    } else if (isInserting) {
      context.missing(_importedAtMeta);
    }
    if (data.containsKey('line_count')) {
      context.handle(_lineCountMeta, lineCount.isAcceptableOrUnknown(data['line_count']!, _lineCountMeta));
    } else if (isInserting) {
      context.missing(_lineCountMeta);
    }
    if (data.containsKey('new_count')) {
      context.handle(_newCountMeta, newCount.isAcceptableOrUnknown(data['new_count']!, _newCountMeta));
    } else if (isInserting) {
      context.missing(_newCountMeta);
    }
    if (data.containsKey('file_type')) {
      context.handle(_fileTypeMeta, fileType.isAcceptableOrUnknown(data['file_type']!, _fileTypeMeta));
    }
    if (data.containsKey('verified')) {
      context.handle(_verifiedMeta, verified.isAcceptableOrUnknown(data['verified']!, _verifiedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Statement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Statement(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      institution: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}institution'])!,
      format: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}format'])!,
      periodStart: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}period_start'])!,
      periodEnd: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}period_end'])!,
      coversSincePrevious: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}covers_since_previous'],
      )!,
      fileHash: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}file_hash'])!,
      fileName: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}file_name'])!,
      importedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}imported_at'])!,
      lineCount: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}line_count'])!,
      newCount: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}new_count'])!,
      fileType: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}file_type'])!,
      verified: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}verified'])!,
    );
  }

  @override
  $StatementsTable createAlias(String alias) {
    return $StatementsTable(attachedDatabase, alias);
  }
}

class Statement extends DataClass implements Insertable<Statement> {
  final int id;
  final String institution;
  final String format;
  final DateTime periodStart;
  final DateTime periodEnd;

  /// Only the closing date is printed: covers the days since the previous
  /// statement of the same format (`ImportedStatement.coversSincePrevious`).
  final bool coversSincePrevious;

  /// SHA-256 of the file: re-importing the same file is detected.
  final String fileHash;
  final String fileName;
  final DateTime importedAt;
  final int lineCount;
  final int newCount;

  /// File type it was read from (`pdf`, `csv`…). Lines of the same account and
  /// day read from another file type are the same lines told differently.
  final String fileType;

  /// False when the file had nothing to check its lines against (a card CSV
  /// export has no balance): shown as not verified.
  final bool verified;
  const Statement({
    required this.id,
    required this.institution,
    required this.format,
    required this.periodStart,
    required this.periodEnd,
    required this.coversSincePrevious,
    required this.fileHash,
    required this.fileName,
    required this.importedAt,
    required this.lineCount,
    required this.newCount,
    required this.fileType,
    required this.verified,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['institution'] = Variable<String>(institution);
    map['format'] = Variable<String>(format);
    map['period_start'] = Variable<DateTime>(periodStart);
    map['period_end'] = Variable<DateTime>(periodEnd);
    map['covers_since_previous'] = Variable<bool>(coversSincePrevious);
    map['file_hash'] = Variable<String>(fileHash);
    map['file_name'] = Variable<String>(fileName);
    map['imported_at'] = Variable<DateTime>(importedAt);
    map['line_count'] = Variable<int>(lineCount);
    map['new_count'] = Variable<int>(newCount);
    map['file_type'] = Variable<String>(fileType);
    map['verified'] = Variable<bool>(verified);
    return map;
  }

  StatementsCompanion toCompanion(bool nullToAbsent) {
    return StatementsCompanion(
      id: Value(id),
      institution: Value(institution),
      format: Value(format),
      periodStart: Value(periodStart),
      periodEnd: Value(periodEnd),
      coversSincePrevious: Value(coversSincePrevious),
      fileHash: Value(fileHash),
      fileName: Value(fileName),
      importedAt: Value(importedAt),
      lineCount: Value(lineCount),
      newCount: Value(newCount),
      fileType: Value(fileType),
      verified: Value(verified),
    );
  }

  factory Statement.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Statement(
      id: serializer.fromJson<int>(json['id']),
      institution: serializer.fromJson<String>(json['institution']),
      format: serializer.fromJson<String>(json['format']),
      periodStart: serializer.fromJson<DateTime>(json['periodStart']),
      periodEnd: serializer.fromJson<DateTime>(json['periodEnd']),
      coversSincePrevious: serializer.fromJson<bool>(json['coversSincePrevious']),
      fileHash: serializer.fromJson<String>(json['fileHash']),
      fileName: serializer.fromJson<String>(json['fileName']),
      importedAt: serializer.fromJson<DateTime>(json['importedAt']),
      lineCount: serializer.fromJson<int>(json['lineCount']),
      newCount: serializer.fromJson<int>(json['newCount']),
      fileType: serializer.fromJson<String>(json['fileType']),
      verified: serializer.fromJson<bool>(json['verified']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'institution': serializer.toJson<String>(institution),
      'format': serializer.toJson<String>(format),
      'periodStart': serializer.toJson<DateTime>(periodStart),
      'periodEnd': serializer.toJson<DateTime>(periodEnd),
      'coversSincePrevious': serializer.toJson<bool>(coversSincePrevious),
      'fileHash': serializer.toJson<String>(fileHash),
      'fileName': serializer.toJson<String>(fileName),
      'importedAt': serializer.toJson<DateTime>(importedAt),
      'lineCount': serializer.toJson<int>(lineCount),
      'newCount': serializer.toJson<int>(newCount),
      'fileType': serializer.toJson<String>(fileType),
      'verified': serializer.toJson<bool>(verified),
    };
  }

  Statement copyWith({
    int? id,
    String? institution,
    String? format,
    DateTime? periodStart,
    DateTime? periodEnd,
    bool? coversSincePrevious,
    String? fileHash,
    String? fileName,
    DateTime? importedAt,
    int? lineCount,
    int? newCount,
    String? fileType,
    bool? verified,
  }) => Statement(
    id: id ?? this.id,
    institution: institution ?? this.institution,
    format: format ?? this.format,
    periodStart: periodStart ?? this.periodStart,
    periodEnd: periodEnd ?? this.periodEnd,
    coversSincePrevious: coversSincePrevious ?? this.coversSincePrevious,
    fileHash: fileHash ?? this.fileHash,
    fileName: fileName ?? this.fileName,
    importedAt: importedAt ?? this.importedAt,
    lineCount: lineCount ?? this.lineCount,
    newCount: newCount ?? this.newCount,
    fileType: fileType ?? this.fileType,
    verified: verified ?? this.verified,
  );
  Statement copyWithCompanion(StatementsCompanion data) {
    return Statement(
      id: data.id.present ? data.id.value : this.id,
      institution: data.institution.present ? data.institution.value : this.institution,
      format: data.format.present ? data.format.value : this.format,
      periodStart: data.periodStart.present ? data.periodStart.value : this.periodStart,
      periodEnd: data.periodEnd.present ? data.periodEnd.value : this.periodEnd,
      coversSincePrevious: data.coversSincePrevious.present ? data.coversSincePrevious.value : this.coversSincePrevious,
      fileHash: data.fileHash.present ? data.fileHash.value : this.fileHash,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      importedAt: data.importedAt.present ? data.importedAt.value : this.importedAt,
      lineCount: data.lineCount.present ? data.lineCount.value : this.lineCount,
      newCount: data.newCount.present ? data.newCount.value : this.newCount,
      fileType: data.fileType.present ? data.fileType.value : this.fileType,
      verified: data.verified.present ? data.verified.value : this.verified,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Statement(')
          ..write('id: $id, ')
          ..write('institution: $institution, ')
          ..write('format: $format, ')
          ..write('periodStart: $periodStart, ')
          ..write('periodEnd: $periodEnd, ')
          ..write('coversSincePrevious: $coversSincePrevious, ')
          ..write('fileHash: $fileHash, ')
          ..write('fileName: $fileName, ')
          ..write('importedAt: $importedAt, ')
          ..write('lineCount: $lineCount, ')
          ..write('newCount: $newCount, ')
          ..write('fileType: $fileType, ')
          ..write('verified: $verified')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    institution,
    format,
    periodStart,
    periodEnd,
    coversSincePrevious,
    fileHash,
    fileName,
    importedAt,
    lineCount,
    newCount,
    fileType,
    verified,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Statement &&
          other.id == this.id &&
          other.institution == this.institution &&
          other.format == this.format &&
          other.periodStart == this.periodStart &&
          other.periodEnd == this.periodEnd &&
          other.coversSincePrevious == this.coversSincePrevious &&
          other.fileHash == this.fileHash &&
          other.fileName == this.fileName &&
          other.importedAt == this.importedAt &&
          other.lineCount == this.lineCount &&
          other.newCount == this.newCount &&
          other.fileType == this.fileType &&
          other.verified == this.verified);
}

class StatementsCompanion extends UpdateCompanion<Statement> {
  final Value<int> id;
  final Value<String> institution;
  final Value<String> format;
  final Value<DateTime> periodStart;
  final Value<DateTime> periodEnd;
  final Value<bool> coversSincePrevious;
  final Value<String> fileHash;
  final Value<String> fileName;
  final Value<DateTime> importedAt;
  final Value<int> lineCount;
  final Value<int> newCount;
  final Value<String> fileType;
  final Value<bool> verified;
  const StatementsCompanion({
    this.id = const Value.absent(),
    this.institution = const Value.absent(),
    this.format = const Value.absent(),
    this.periodStart = const Value.absent(),
    this.periodEnd = const Value.absent(),
    this.coversSincePrevious = const Value.absent(),
    this.fileHash = const Value.absent(),
    this.fileName = const Value.absent(),
    this.importedAt = const Value.absent(),
    this.lineCount = const Value.absent(),
    this.newCount = const Value.absent(),
    this.fileType = const Value.absent(),
    this.verified = const Value.absent(),
  });
  StatementsCompanion.insert({
    this.id = const Value.absent(),
    required String institution,
    required String format,
    required DateTime periodStart,
    required DateTime periodEnd,
    this.coversSincePrevious = const Value.absent(),
    required String fileHash,
    required String fileName,
    required DateTime importedAt,
    required int lineCount,
    required int newCount,
    this.fileType = const Value.absent(),
    this.verified = const Value.absent(),
  }) : institution = Value(institution),
       format = Value(format),
       periodStart = Value(periodStart),
       periodEnd = Value(periodEnd),
       fileHash = Value(fileHash),
       fileName = Value(fileName),
       importedAt = Value(importedAt),
       lineCount = Value(lineCount),
       newCount = Value(newCount);
  static Insertable<Statement> custom({
    Expression<int>? id,
    Expression<String>? institution,
    Expression<String>? format,
    Expression<DateTime>? periodStart,
    Expression<DateTime>? periodEnd,
    Expression<bool>? coversSincePrevious,
    Expression<String>? fileHash,
    Expression<String>? fileName,
    Expression<DateTime>? importedAt,
    Expression<int>? lineCount,
    Expression<int>? newCount,
    Expression<String>? fileType,
    Expression<bool>? verified,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (institution != null) 'institution': institution,
      if (format != null) 'format': format,
      if (periodStart != null) 'period_start': periodStart,
      if (periodEnd != null) 'period_end': periodEnd,
      if (coversSincePrevious != null) 'covers_since_previous': coversSincePrevious,
      if (fileHash != null) 'file_hash': fileHash,
      if (fileName != null) 'file_name': fileName,
      if (importedAt != null) 'imported_at': importedAt,
      if (lineCount != null) 'line_count': lineCount,
      if (newCount != null) 'new_count': newCount,
      if (fileType != null) 'file_type': fileType,
      if (verified != null) 'verified': verified,
    });
  }

  StatementsCompanion copyWith({
    Value<int>? id,
    Value<String>? institution,
    Value<String>? format,
    Value<DateTime>? periodStart,
    Value<DateTime>? periodEnd,
    Value<bool>? coversSincePrevious,
    Value<String>? fileHash,
    Value<String>? fileName,
    Value<DateTime>? importedAt,
    Value<int>? lineCount,
    Value<int>? newCount,
    Value<String>? fileType,
    Value<bool>? verified,
  }) {
    return StatementsCompanion(
      id: id ?? this.id,
      institution: institution ?? this.institution,
      format: format ?? this.format,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      coversSincePrevious: coversSincePrevious ?? this.coversSincePrevious,
      fileHash: fileHash ?? this.fileHash,
      fileName: fileName ?? this.fileName,
      importedAt: importedAt ?? this.importedAt,
      lineCount: lineCount ?? this.lineCount,
      newCount: newCount ?? this.newCount,
      fileType: fileType ?? this.fileType,
      verified: verified ?? this.verified,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (institution.present) {
      map['institution'] = Variable<String>(institution.value);
    }
    if (format.present) {
      map['format'] = Variable<String>(format.value);
    }
    if (periodStart.present) {
      map['period_start'] = Variable<DateTime>(periodStart.value);
    }
    if (periodEnd.present) {
      map['period_end'] = Variable<DateTime>(periodEnd.value);
    }
    if (coversSincePrevious.present) {
      map['covers_since_previous'] = Variable<bool>(coversSincePrevious.value);
    }
    if (fileHash.present) {
      map['file_hash'] = Variable<String>(fileHash.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (importedAt.present) {
      map['imported_at'] = Variable<DateTime>(importedAt.value);
    }
    if (lineCount.present) {
      map['line_count'] = Variable<int>(lineCount.value);
    }
    if (newCount.present) {
      map['new_count'] = Variable<int>(newCount.value);
    }
    if (fileType.present) {
      map['file_type'] = Variable<String>(fileType.value);
    }
    if (verified.present) {
      map['verified'] = Variable<bool>(verified.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StatementsCompanion(')
          ..write('id: $id, ')
          ..write('institution: $institution, ')
          ..write('format: $format, ')
          ..write('periodStart: $periodStart, ')
          ..write('periodEnd: $periodEnd, ')
          ..write('coversSincePrevious: $coversSincePrevious, ')
          ..write('fileHash: $fileHash, ')
          ..write('fileName: $fileName, ')
          ..write('importedAt: $importedAt, ')
          ..write('lineCount: $lineCount, ')
          ..write('newCount: $newCount, ')
          ..write('fileType: $fileType, ')
          ..write('verified: $verified')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTable extends Categories with TableInfo<$CategoriesTable, CategoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta('parentId');
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameFrMeta = const VerificationMeta('nameFr');
  @override
  late final GeneratedColumn<String> nameFr = GeneratedColumn<String>(
    'name_fr',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameEnMeta = const VerificationMeta('nameEn');
  @override
  late final GeneratedColumn<String> nameEn = GeneratedColumn<String>(
    'name_en',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
    'color',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta('archived');
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("archived" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _excludedFromShareMeta = const VerificationMeta('excludedFromShare');
  @override
  late final GeneratedColumn<bool> excludedFromShare = GeneratedColumn<bool>(
    'excluded_from_share',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("excluded_from_share" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    parentId,
    nameFr,
    nameEn,
    type,
    color,
    sortOrder,
    archived,
    excludedFromShare,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(Insertable<CategoryRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(_parentIdMeta, parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta));
    }
    if (data.containsKey('name_fr')) {
      context.handle(_nameFrMeta, nameFr.isAcceptableOrUnknown(data['name_fr']!, _nameFrMeta));
    } else if (isInserting) {
      context.missing(_nameFrMeta);
    }
    if (data.containsKey('name_en')) {
      context.handle(_nameEnMeta, nameEn.isAcceptableOrUnknown(data['name_en']!, _nameEnMeta));
    } else if (isInserting) {
      context.missing(_nameEnMeta);
    }
    if (data.containsKey('type')) {
      context.handle(_typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('color')) {
      context.handle(_colorMeta, color.isAcceptableOrUnknown(data['color']!, _colorMeta));
    } else if (isInserting) {
      context.missing(_colorMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta, sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('archived')) {
      context.handle(_archivedMeta, archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta));
    }
    if (data.containsKey('excluded_from_share')) {
      context.handle(
        _excludedFromShareMeta,
        excludedFromShare.isAcceptableOrUnknown(data['excluded_from_share']!, _excludedFromShareMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CategoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      parentId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}parent_id']),
      nameFr: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name_fr'])!,
      nameEn: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name_en'])!,
      type: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      color: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}color'])!,
      sortOrder: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      archived: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}archived'])!,
      excludedFromShare: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}excluded_from_share'],
      )!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class CategoryRow extends DataClass implements Insertable<CategoryRow> {
  /// Stable key, e.g. `food.coffee`.
  final String id;
  final String? parentId;
  final String nameFr;
  final String nameEn;

  /// `CategoryType.name`.
  final String type;
  final int color;

  /// Defaults follow `defaultCategories` order; user categories come after (1000+).
  final int sortOrder;

  /// Hidden from pickers; kept so old references still have a name.
  final bool archived;

  /// Left out of the "share without excluded" figures (Statistics → Categories),
  /// e.g. rent or taxes. A group's flag covers its categories.
  final bool excludedFromShare;
  const CategoryRow({
    required this.id,
    this.parentId,
    required this.nameFr,
    required this.nameEn,
    required this.type,
    required this.color,
    required this.sortOrder,
    required this.archived,
    required this.excludedFromShare,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    map['name_fr'] = Variable<String>(nameFr);
    map['name_en'] = Variable<String>(nameEn);
    map['type'] = Variable<String>(type);
    map['color'] = Variable<int>(color);
    map['sort_order'] = Variable<int>(sortOrder);
    map['archived'] = Variable<bool>(archived);
    map['excluded_from_share'] = Variable<bool>(excludedFromShare);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      parentId: parentId == null && nullToAbsent ? const Value.absent() : Value(parentId),
      nameFr: Value(nameFr),
      nameEn: Value(nameEn),
      type: Value(type),
      color: Value(color),
      sortOrder: Value(sortOrder),
      archived: Value(archived),
      excludedFromShare: Value(excludedFromShare),
    );
  }

  factory CategoryRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryRow(
      id: serializer.fromJson<String>(json['id']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      nameFr: serializer.fromJson<String>(json['nameFr']),
      nameEn: serializer.fromJson<String>(json['nameEn']),
      type: serializer.fromJson<String>(json['type']),
      color: serializer.fromJson<int>(json['color']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      archived: serializer.fromJson<bool>(json['archived']),
      excludedFromShare: serializer.fromJson<bool>(json['excludedFromShare']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'parentId': serializer.toJson<String?>(parentId),
      'nameFr': serializer.toJson<String>(nameFr),
      'nameEn': serializer.toJson<String>(nameEn),
      'type': serializer.toJson<String>(type),
      'color': serializer.toJson<int>(color),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'archived': serializer.toJson<bool>(archived),
      'excludedFromShare': serializer.toJson<bool>(excludedFromShare),
    };
  }

  CategoryRow copyWith({
    String? id,
    Value<String?> parentId = const Value.absent(),
    String? nameFr,
    String? nameEn,
    String? type,
    int? color,
    int? sortOrder,
    bool? archived,
    bool? excludedFromShare,
  }) => CategoryRow(
    id: id ?? this.id,
    parentId: parentId.present ? parentId.value : this.parentId,
    nameFr: nameFr ?? this.nameFr,
    nameEn: nameEn ?? this.nameEn,
    type: type ?? this.type,
    color: color ?? this.color,
    sortOrder: sortOrder ?? this.sortOrder,
    archived: archived ?? this.archived,
    excludedFromShare: excludedFromShare ?? this.excludedFromShare,
  );
  CategoryRow copyWithCompanion(CategoriesCompanion data) {
    return CategoryRow(
      id: data.id.present ? data.id.value : this.id,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      nameFr: data.nameFr.present ? data.nameFr.value : this.nameFr,
      nameEn: data.nameEn.present ? data.nameEn.value : this.nameEn,
      type: data.type.present ? data.type.value : this.type,
      color: data.color.present ? data.color.value : this.color,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      archived: data.archived.present ? data.archived.value : this.archived,
      excludedFromShare: data.excludedFromShare.present ? data.excludedFromShare.value : this.excludedFromShare,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryRow(')
          ..write('id: $id, ')
          ..write('parentId: $parentId, ')
          ..write('nameFr: $nameFr, ')
          ..write('nameEn: $nameEn, ')
          ..write('type: $type, ')
          ..write('color: $color, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('archived: $archived, ')
          ..write('excludedFromShare: $excludedFromShare')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, parentId, nameFr, nameEn, type, color, sortOrder, archived, excludedFromShare);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryRow &&
          other.id == this.id &&
          other.parentId == this.parentId &&
          other.nameFr == this.nameFr &&
          other.nameEn == this.nameEn &&
          other.type == this.type &&
          other.color == this.color &&
          other.sortOrder == this.sortOrder &&
          other.archived == this.archived &&
          other.excludedFromShare == this.excludedFromShare);
}

class CategoriesCompanion extends UpdateCompanion<CategoryRow> {
  final Value<String> id;
  final Value<String?> parentId;
  final Value<String> nameFr;
  final Value<String> nameEn;
  final Value<String> type;
  final Value<int> color;
  final Value<int> sortOrder;
  final Value<bool> archived;
  final Value<bool> excludedFromShare;
  final Value<int> rowid;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.parentId = const Value.absent(),
    this.nameFr = const Value.absent(),
    this.nameEn = const Value.absent(),
    this.type = const Value.absent(),
    this.color = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.archived = const Value.absent(),
    this.excludedFromShare = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriesCompanion.insert({
    required String id,
    this.parentId = const Value.absent(),
    required String nameFr,
    required String nameEn,
    required String type,
    required int color,
    required int sortOrder,
    this.archived = const Value.absent(),
    this.excludedFromShare = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       nameFr = Value(nameFr),
       nameEn = Value(nameEn),
       type = Value(type),
       color = Value(color),
       sortOrder = Value(sortOrder);
  static Insertable<CategoryRow> custom({
    Expression<String>? id,
    Expression<String>? parentId,
    Expression<String>? nameFr,
    Expression<String>? nameEn,
    Expression<String>? type,
    Expression<int>? color,
    Expression<int>? sortOrder,
    Expression<bool>? archived,
    Expression<bool>? excludedFromShare,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (parentId != null) 'parent_id': parentId,
      if (nameFr != null) 'name_fr': nameFr,
      if (nameEn != null) 'name_en': nameEn,
      if (type != null) 'type': type,
      if (color != null) 'color': color,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (archived != null) 'archived': archived,
      if (excludedFromShare != null) 'excluded_from_share': excludedFromShare,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriesCompanion copyWith({
    Value<String>? id,
    Value<String?>? parentId,
    Value<String>? nameFr,
    Value<String>? nameEn,
    Value<String>? type,
    Value<int>? color,
    Value<int>? sortOrder,
    Value<bool>? archived,
    Value<bool>? excludedFromShare,
    Value<int>? rowid,
  }) {
    return CategoriesCompanion(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      nameFr: nameFr ?? this.nameFr,
      nameEn: nameEn ?? this.nameEn,
      type: type ?? this.type,
      color: color ?? this.color,
      sortOrder: sortOrder ?? this.sortOrder,
      archived: archived ?? this.archived,
      excludedFromShare: excludedFromShare ?? this.excludedFromShare,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (nameFr.present) {
      map['name_fr'] = Variable<String>(nameFr.value);
    }
    if (nameEn.present) {
      map['name_en'] = Variable<String>(nameEn.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (excludedFromShare.present) {
      map['excluded_from_share'] = Variable<bool>(excludedFromShare.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('parentId: $parentId, ')
          ..write('nameFr: $nameFr, ')
          ..write('nameEn: $nameEn, ')
          ..write('type: $type, ')
          ..write('color: $color, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('archived: $archived, ')
          ..write('excludedFromShare: $excludedFromShare, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MerchantsTable extends Merchants with TableInfo<$MerchantsTable, Merchant> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MerchantsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES categories (id)'),
  );
  @override
  List<GeneratedColumn> get $columns => [id, key, name, categoryId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'merchants';
  @override
  VerificationContext validateIntegrity(Insertable<Merchant> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('key')) {
      context.handle(_keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(_categoryIdMeta, categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Merchant map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Merchant(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      key: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      categoryId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}category_id']),
    );
  }

  @override
  $MerchantsTable createAlias(String alias) {
    return $MerchantsTable(attachedDatabase, alias);
  }
}

class Merchant extends DataClass implements Insertable<Merchant> {
  final int id;

  /// From `normalizeMerchant`.
  final String key;
  final String name;

  /// Category the user chose for this merchant: applied to future imports.
  final String? categoryId;
  const Merchant({required this.id, required this.key, required this.name, this.categoryId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['key'] = Variable<String>(key);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    return map;
  }

  MerchantsCompanion toCompanion(bool nullToAbsent) {
    return MerchantsCompanion(
      id: Value(id),
      key: Value(key),
      name: Value(name),
      categoryId: categoryId == null && nullToAbsent ? const Value.absent() : Value(categoryId),
    );
  }

  factory Merchant.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Merchant(
      id: serializer.fromJson<int>(json['id']),
      key: serializer.fromJson<String>(json['key']),
      name: serializer.fromJson<String>(json['name']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'key': serializer.toJson<String>(key),
      'name': serializer.toJson<String>(name),
      'categoryId': serializer.toJson<String?>(categoryId),
    };
  }

  Merchant copyWith({int? id, String? key, String? name, Value<String?> categoryId = const Value.absent()}) => Merchant(
    id: id ?? this.id,
    key: key ?? this.key,
    name: name ?? this.name,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
  );
  Merchant copyWithCompanion(MerchantsCompanion data) {
    return Merchant(
      id: data.id.present ? data.id.value : this.id,
      key: data.key.present ? data.key.value : this.key,
      name: data.name.present ? data.name.value : this.name,
      categoryId: data.categoryId.present ? data.categoryId.value : this.categoryId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Merchant(')
          ..write('id: $id, ')
          ..write('key: $key, ')
          ..write('name: $name, ')
          ..write('categoryId: $categoryId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, key, name, categoryId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Merchant &&
          other.id == this.id &&
          other.key == this.key &&
          other.name == this.name &&
          other.categoryId == this.categoryId);
}

class MerchantsCompanion extends UpdateCompanion<Merchant> {
  final Value<int> id;
  final Value<String> key;
  final Value<String> name;
  final Value<String?> categoryId;
  const MerchantsCompanion({
    this.id = const Value.absent(),
    this.key = const Value.absent(),
    this.name = const Value.absent(),
    this.categoryId = const Value.absent(),
  });
  MerchantsCompanion.insert({
    this.id = const Value.absent(),
    required String key,
    required String name,
    this.categoryId = const Value.absent(),
  }) : key = Value(key),
       name = Value(name);
  static Insertable<Merchant> custom({
    Expression<int>? id,
    Expression<String>? key,
    Expression<String>? name,
    Expression<String>? categoryId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (key != null) 'key': key,
      if (name != null) 'name': name,
      if (categoryId != null) 'category_id': categoryId,
    });
  }

  MerchantsCompanion copyWith({Value<int>? id, Value<String>? key, Value<String>? name, Value<String?>? categoryId}) {
    return MerchantsCompanion(
      id: id ?? this.id,
      key: key ?? this.key,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MerchantsCompanion(')
          ..write('id: $id, ')
          ..write('key: $key, ')
          ..write('name: $name, ')
          ..write('categoryId: $categoryId')
          ..write(')'))
        .toString();
  }
}

class $RulesTable extends Rules with TableInfo<$RulesTable, RuleRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RulesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES categories (id)'),
  );
  static const VerificationMeta _descriptionContainsMeta = const VerificationMeta('descriptionContains');
  @override
  late final GeneratedColumn<String> descriptionContains = GeneratedColumn<String>(
    'description_contains',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _merchantKeyMeta = const VerificationMeta('merchantKey');
  @override
  late final GeneratedColumn<String> merchantKey = GeneratedColumn<String>(
    'merchant_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, categoryId, descriptionContains, merchantKey, code, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rules';
  @override
  VerificationContext validateIntegrity(Insertable<RuleRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('category_id')) {
      context.handle(_categoryIdMeta, categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta));
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('description_contains')) {
      context.handle(
        _descriptionContainsMeta,
        descriptionContains.isAcceptableOrUnknown(data['description_contains']!, _descriptionContainsMeta),
      );
    }
    if (data.containsKey('merchant_key')) {
      context.handle(_merchantKeyMeta, merchantKey.isAcceptableOrUnknown(data['merchant_key']!, _merchantKeyMeta));
    }
    if (data.containsKey('code')) {
      context.handle(_codeMeta, code.isAcceptableOrUnknown(data['code']!, _codeMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RuleRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RuleRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      categoryId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}category_id'])!,
      descriptionContains: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description_contains'],
      ),
      merchantKey: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}merchant_key']),
      code: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}code']),
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $RulesTable createAlias(String alias) {
    return $RulesTable(attachedDatabase, alias);
  }
}

class RuleRow extends DataClass implements Insertable<RuleRow> {
  final int id;
  final String categoryId;
  final String? descriptionContains;
  final String? merchantKey;
  final String? code;
  final DateTime createdAt;
  const RuleRow({
    required this.id,
    required this.categoryId,
    this.descriptionContains,
    this.merchantKey,
    this.code,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['category_id'] = Variable<String>(categoryId);
    if (!nullToAbsent || descriptionContains != null) {
      map['description_contains'] = Variable<String>(descriptionContains);
    }
    if (!nullToAbsent || merchantKey != null) {
      map['merchant_key'] = Variable<String>(merchantKey);
    }
    if (!nullToAbsent || code != null) {
      map['code'] = Variable<String>(code);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  RulesCompanion toCompanion(bool nullToAbsent) {
    return RulesCompanion(
      id: Value(id),
      categoryId: Value(categoryId),
      descriptionContains: descriptionContains == null && nullToAbsent
          ? const Value.absent()
          : Value(descriptionContains),
      merchantKey: merchantKey == null && nullToAbsent ? const Value.absent() : Value(merchantKey),
      code: code == null && nullToAbsent ? const Value.absent() : Value(code),
      createdAt: Value(createdAt),
    );
  }

  factory RuleRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RuleRow(
      id: serializer.fromJson<int>(json['id']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      descriptionContains: serializer.fromJson<String?>(json['descriptionContains']),
      merchantKey: serializer.fromJson<String?>(json['merchantKey']),
      code: serializer.fromJson<String?>(json['code']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'categoryId': serializer.toJson<String>(categoryId),
      'descriptionContains': serializer.toJson<String?>(descriptionContains),
      'merchantKey': serializer.toJson<String?>(merchantKey),
      'code': serializer.toJson<String?>(code),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  RuleRow copyWith({
    int? id,
    String? categoryId,
    Value<String?> descriptionContains = const Value.absent(),
    Value<String?> merchantKey = const Value.absent(),
    Value<String?> code = const Value.absent(),
    DateTime? createdAt,
  }) => RuleRow(
    id: id ?? this.id,
    categoryId: categoryId ?? this.categoryId,
    descriptionContains: descriptionContains.present ? descriptionContains.value : this.descriptionContains,
    merchantKey: merchantKey.present ? merchantKey.value : this.merchantKey,
    code: code.present ? code.value : this.code,
    createdAt: createdAt ?? this.createdAt,
  );
  RuleRow copyWithCompanion(RulesCompanion data) {
    return RuleRow(
      id: data.id.present ? data.id.value : this.id,
      categoryId: data.categoryId.present ? data.categoryId.value : this.categoryId,
      descriptionContains: data.descriptionContains.present ? data.descriptionContains.value : this.descriptionContains,
      merchantKey: data.merchantKey.present ? data.merchantKey.value : this.merchantKey,
      code: data.code.present ? data.code.value : this.code,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RuleRow(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('descriptionContains: $descriptionContains, ')
          ..write('merchantKey: $merchantKey, ')
          ..write('code: $code, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, categoryId, descriptionContains, merchantKey, code, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RuleRow &&
          other.id == this.id &&
          other.categoryId == this.categoryId &&
          other.descriptionContains == this.descriptionContains &&
          other.merchantKey == this.merchantKey &&
          other.code == this.code &&
          other.createdAt == this.createdAt);
}

class RulesCompanion extends UpdateCompanion<RuleRow> {
  final Value<int> id;
  final Value<String> categoryId;
  final Value<String?> descriptionContains;
  final Value<String?> merchantKey;
  final Value<String?> code;
  final Value<DateTime> createdAt;
  const RulesCompanion({
    this.id = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.descriptionContains = const Value.absent(),
    this.merchantKey = const Value.absent(),
    this.code = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  RulesCompanion.insert({
    this.id = const Value.absent(),
    required String categoryId,
    this.descriptionContains = const Value.absent(),
    this.merchantKey = const Value.absent(),
    this.code = const Value.absent(),
    required DateTime createdAt,
  }) : categoryId = Value(categoryId),
       createdAt = Value(createdAt);
  static Insertable<RuleRow> custom({
    Expression<int>? id,
    Expression<String>? categoryId,
    Expression<String>? descriptionContains,
    Expression<String>? merchantKey,
    Expression<String>? code,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (categoryId != null) 'category_id': categoryId,
      if (descriptionContains != null) 'description_contains': descriptionContains,
      if (merchantKey != null) 'merchant_key': merchantKey,
      if (code != null) 'code': code,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  RulesCompanion copyWith({
    Value<int>? id,
    Value<String>? categoryId,
    Value<String?>? descriptionContains,
    Value<String?>? merchantKey,
    Value<String?>? code,
    Value<DateTime>? createdAt,
  }) {
    return RulesCompanion(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      descriptionContains: descriptionContains ?? this.descriptionContains,
      merchantKey: merchantKey ?? this.merchantKey,
      code: code ?? this.code,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (descriptionContains.present) {
      map['description_contains'] = Variable<String>(descriptionContains.value);
    }
    if (merchantKey.present) {
      map['merchant_key'] = Variable<String>(merchantKey.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RulesCompanion(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('descriptionContains: $descriptionContains, ')
          ..write('merchantKey: $merchantKey, ')
          ..write('code: $code, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $TransactionsTable extends Transactions with TableInfo<$TransactionsTable, Txn> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta('accountId');
  @override
  late final GeneratedColumn<int> accountId = GeneratedColumn<int>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES accounts (id)'),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _postedDateMeta = const VerificationMeta('postedDate');
  @override
  late final GeneratedColumn<DateTime> postedDate = GeneratedColumn<DateTime>(
    'posted_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _locationMeta = const VerificationMeta('location');
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bonusRateMeta = const VerificationMeta('bonusRate');
  @override
  late final GeneratedColumn<int> bonusRate = GeneratedColumn<int>(
    'bonus_rate',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _foreignCentsMeta = const VerificationMeta('foreignCents');
  @override
  late final GeneratedColumn<int> foreignCents = GeneratedColumn<int>(
    'foreign_cents',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _foreignCurrencyMeta = const VerificationMeta('foreignCurrency');
  @override
  late final GeneratedColumn<String> foreignCurrency = GeneratedColumn<String>(
    'foreign_currency',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fxRateMeta = const VerificationMeta('fxRate');
  @override
  late final GeneratedColumn<String> fxRate = GeneratedColumn<String>(
    'fx_rate',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cardMeta = const VerificationMeta('card');
  @override
  late final GeneratedColumn<String> card = GeneratedColumn<String>(
    'card',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _merchantIdMeta = const VerificationMeta('merchantId');
  @override
  late final GeneratedColumn<int> merchantId = GeneratedColumn<int>(
    'merchant_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES merchants (id)'),
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES categories (id)'),
  );
  static const VerificationMeta _confidenceMeta = const VerificationMeta('confidence');
  @override
  late final GeneratedColumn<String> confidence = GeneratedColumn<String>(
    'confidence',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _needsReviewMeta = const VerificationMeta('needsReview');
  @override
  late final GeneratedColumn<bool> needsReview = GeneratedColumn<bool>(
    'needs_review',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("needs_review" IN (0, 1))'),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statementIdMeta = const VerificationMeta('statementId');
  @override
  late final GeneratedColumn<int> statementId = GeneratedColumn<int>(
    'statement_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES statements (id)'),
  );
  static const VerificationMeta _fingerprintMeta = const VerificationMeta('fingerprint');
  @override
  late final GeneratedColumn<String> fingerprint = GeneratedColumn<String>(
    'fingerprint',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _transferGroupMeta = const VerificationMeta('transferGroup');
  @override
  late final GeneratedColumn<String> transferGroup = GeneratedColumn<String>(
    'transfer_group',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isPersonMeta = const VerificationMeta('isPerson');
  @override
  late final GeneratedColumn<bool> isPerson = GeneratedColumn<bool>(
    'is_person',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("is_person" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _anomalyOkMeta = const VerificationMeta('anomalyOk');
  @override
  late final GeneratedColumn<bool> anomalyOk = GeneratedColumn<bool>(
    'anomaly_ok',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("anomaly_ok" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    accountId,
    date,
    postedDate,
    amount,
    description,
    code,
    location,
    bonusRate,
    foreignCents,
    foreignCurrency,
    fxRate,
    card,
    kind,
    merchantId,
    categoryId,
    confidence,
    needsReview,
    note,
    source,
    statementId,
    fingerprint,
    transferGroup,
    isPerson,
    anomalyOk,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(Insertable<Txn> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(_accountIdMeta, accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta));
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(_dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('posted_date')) {
      context.handle(_postedDateMeta, postedDate.isAcceptableOrUnknown(data['posted_date']!, _postedDateMeta));
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta, amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('description')) {
      context.handle(_descriptionMeta, description.isAcceptableOrUnknown(data['description']!, _descriptionMeta));
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('code')) {
      context.handle(_codeMeta, code.isAcceptableOrUnknown(data['code']!, _codeMeta));
    }
    if (data.containsKey('location')) {
      context.handle(_locationMeta, location.isAcceptableOrUnknown(data['location']!, _locationMeta));
    }
    if (data.containsKey('bonus_rate')) {
      context.handle(_bonusRateMeta, bonusRate.isAcceptableOrUnknown(data['bonus_rate']!, _bonusRateMeta));
    }
    if (data.containsKey('foreign_cents')) {
      context.handle(_foreignCentsMeta, foreignCents.isAcceptableOrUnknown(data['foreign_cents']!, _foreignCentsMeta));
    }
    if (data.containsKey('foreign_currency')) {
      context.handle(
        _foreignCurrencyMeta,
        foreignCurrency.isAcceptableOrUnknown(data['foreign_currency']!, _foreignCurrencyMeta),
      );
    }
    if (data.containsKey('fx_rate')) {
      context.handle(_fxRateMeta, fxRate.isAcceptableOrUnknown(data['fx_rate']!, _fxRateMeta));
    }
    if (data.containsKey('card')) {
      context.handle(_cardMeta, card.isAcceptableOrUnknown(data['card']!, _cardMeta));
    }
    if (data.containsKey('kind')) {
      context.handle(_kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('merchant_id')) {
      context.handle(_merchantIdMeta, merchantId.isAcceptableOrUnknown(data['merchant_id']!, _merchantIdMeta));
    }
    if (data.containsKey('category_id')) {
      context.handle(_categoryIdMeta, categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta));
    }
    if (data.containsKey('confidence')) {
      context.handle(_confidenceMeta, confidence.isAcceptableOrUnknown(data['confidence']!, _confidenceMeta));
    } else if (isInserting) {
      context.missing(_confidenceMeta);
    }
    if (data.containsKey('needs_review')) {
      context.handle(_needsReviewMeta, needsReview.isAcceptableOrUnknown(data['needs_review']!, _needsReviewMeta));
    } else if (isInserting) {
      context.missing(_needsReviewMeta);
    }
    if (data.containsKey('note')) {
      context.handle(_noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta, source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('statement_id')) {
      context.handle(_statementIdMeta, statementId.isAcceptableOrUnknown(data['statement_id']!, _statementIdMeta));
    }
    if (data.containsKey('fingerprint')) {
      context.handle(_fingerprintMeta, fingerprint.isAcceptableOrUnknown(data['fingerprint']!, _fingerprintMeta));
    }
    if (data.containsKey('transfer_group')) {
      context.handle(
        _transferGroupMeta,
        transferGroup.isAcceptableOrUnknown(data['transfer_group']!, _transferGroupMeta),
      );
    }
    if (data.containsKey('is_person')) {
      context.handle(_isPersonMeta, isPerson.isAcceptableOrUnknown(data['is_person']!, _isPersonMeta));
    }
    if (data.containsKey('anomaly_ok')) {
      context.handle(_anomalyOkMeta, anomalyOk.isAcceptableOrUnknown(data['anomaly_ok']!, _anomalyOkMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta, updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Txn map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Txn(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      accountId: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}account_id'])!,
      date: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
      postedDate: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}posted_date']),
      amount: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}amount'])!,
      description: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      code: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}code']),
      location: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}location']),
      bonusRate: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}bonus_rate']),
      foreignCents: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}foreign_cents']),
      foreignCurrency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}foreign_currency'],
      ),
      fxRate: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}fx_rate']),
      card: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}card']),
      kind: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      merchantId: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}merchant_id']),
      categoryId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}category_id']),
      confidence: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}confidence'])!,
      needsReview: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}needs_review'])!,
      note: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}note']),
      source: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}source'])!,
      statementId: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}statement_id']),
      fingerprint: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}fingerprint']),
      transferGroup: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}transfer_group']),
      isPerson: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}is_person'])!,
      anomalyOk: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}anomaly_ok'])!,
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $TransactionsTable createAlias(String alias) {
    return $TransactionsTable(attachedDatabase, alias);
  }
}

class Txn extends DataClass implements Insertable<Txn> {
  /// UUID, so entries created on the phone can be merged later.
  final String id;
  final int accountId;
  final DateTime date;
  final DateTime? postedDate;

  /// Signed cents in the account currency. Negative = money out.
  final int amount;

  /// Exactly as on the statement (or typed for manual entries). Never edited.
  final String description;
  final String? code;
  final String? location;
  final int? bonusRate;
  final int? foreignCents;
  final String? foreignCurrency;
  final String? fxRate;
  final String? card;

  /// `TransactionKind.name`.
  final String kind;
  final int? merchantId;
  final String? categoryId;

  /// `Confidence.name` of the category; `user` once set by hand.
  final String confidence;

  /// True while the transaction waits in the review queue.
  final bool needsReview;
  final String? note;

  /// `statement` or `manual`.
  final String source;
  final int? statementId;

  /// See `lineFingerprint`. Null for manual entries.
  final String? fingerprint;

  /// Same value on both sides of a matched transfer.
  final String? transferGroup;

  /// Counterparty is a person (Interac transfer): excluded from merchant rankings.
  final bool isPerson;

  /// Marked "normal" by the user: never an alert, left out of usual amounts.
  final bool anomalyOk;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Txn({
    required this.id,
    required this.accountId,
    required this.date,
    this.postedDate,
    required this.amount,
    required this.description,
    this.code,
    this.location,
    this.bonusRate,
    this.foreignCents,
    this.foreignCurrency,
    this.fxRate,
    this.card,
    required this.kind,
    this.merchantId,
    this.categoryId,
    required this.confidence,
    required this.needsReview,
    this.note,
    required this.source,
    this.statementId,
    this.fingerprint,
    this.transferGroup,
    required this.isPerson,
    required this.anomalyOk,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['account_id'] = Variable<int>(accountId);
    map['date'] = Variable<DateTime>(date);
    if (!nullToAbsent || postedDate != null) {
      map['posted_date'] = Variable<DateTime>(postedDate);
    }
    map['amount'] = Variable<int>(amount);
    map['description'] = Variable<String>(description);
    if (!nullToAbsent || code != null) {
      map['code'] = Variable<String>(code);
    }
    if (!nullToAbsent || location != null) {
      map['location'] = Variable<String>(location);
    }
    if (!nullToAbsent || bonusRate != null) {
      map['bonus_rate'] = Variable<int>(bonusRate);
    }
    if (!nullToAbsent || foreignCents != null) {
      map['foreign_cents'] = Variable<int>(foreignCents);
    }
    if (!nullToAbsent || foreignCurrency != null) {
      map['foreign_currency'] = Variable<String>(foreignCurrency);
    }
    if (!nullToAbsent || fxRate != null) {
      map['fx_rate'] = Variable<String>(fxRate);
    }
    if (!nullToAbsent || card != null) {
      map['card'] = Variable<String>(card);
    }
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || merchantId != null) {
      map['merchant_id'] = Variable<int>(merchantId);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    map['confidence'] = Variable<String>(confidence);
    map['needs_review'] = Variable<bool>(needsReview);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || statementId != null) {
      map['statement_id'] = Variable<int>(statementId);
    }
    if (!nullToAbsent || fingerprint != null) {
      map['fingerprint'] = Variable<String>(fingerprint);
    }
    if (!nullToAbsent || transferGroup != null) {
      map['transfer_group'] = Variable<String>(transferGroup);
    }
    map['is_person'] = Variable<bool>(isPerson);
    map['anomaly_ok'] = Variable<bool>(anomalyOk);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      id: Value(id),
      accountId: Value(accountId),
      date: Value(date),
      postedDate: postedDate == null && nullToAbsent ? const Value.absent() : Value(postedDate),
      amount: Value(amount),
      description: Value(description),
      code: code == null && nullToAbsent ? const Value.absent() : Value(code),
      location: location == null && nullToAbsent ? const Value.absent() : Value(location),
      bonusRate: bonusRate == null && nullToAbsent ? const Value.absent() : Value(bonusRate),
      foreignCents: foreignCents == null && nullToAbsent ? const Value.absent() : Value(foreignCents),
      foreignCurrency: foreignCurrency == null && nullToAbsent ? const Value.absent() : Value(foreignCurrency),
      fxRate: fxRate == null && nullToAbsent ? const Value.absent() : Value(fxRate),
      card: card == null && nullToAbsent ? const Value.absent() : Value(card),
      kind: Value(kind),
      merchantId: merchantId == null && nullToAbsent ? const Value.absent() : Value(merchantId),
      categoryId: categoryId == null && nullToAbsent ? const Value.absent() : Value(categoryId),
      confidence: Value(confidence),
      needsReview: Value(needsReview),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      source: Value(source),
      statementId: statementId == null && nullToAbsent ? const Value.absent() : Value(statementId),
      fingerprint: fingerprint == null && nullToAbsent ? const Value.absent() : Value(fingerprint),
      transferGroup: transferGroup == null && nullToAbsent ? const Value.absent() : Value(transferGroup),
      isPerson: Value(isPerson),
      anomalyOk: Value(anomalyOk),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Txn.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Txn(
      id: serializer.fromJson<String>(json['id']),
      accountId: serializer.fromJson<int>(json['accountId']),
      date: serializer.fromJson<DateTime>(json['date']),
      postedDate: serializer.fromJson<DateTime?>(json['postedDate']),
      amount: serializer.fromJson<int>(json['amount']),
      description: serializer.fromJson<String>(json['description']),
      code: serializer.fromJson<String?>(json['code']),
      location: serializer.fromJson<String?>(json['location']),
      bonusRate: serializer.fromJson<int?>(json['bonusRate']),
      foreignCents: serializer.fromJson<int?>(json['foreignCents']),
      foreignCurrency: serializer.fromJson<String?>(json['foreignCurrency']),
      fxRate: serializer.fromJson<String?>(json['fxRate']),
      card: serializer.fromJson<String?>(json['card']),
      kind: serializer.fromJson<String>(json['kind']),
      merchantId: serializer.fromJson<int?>(json['merchantId']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      confidence: serializer.fromJson<String>(json['confidence']),
      needsReview: serializer.fromJson<bool>(json['needsReview']),
      note: serializer.fromJson<String?>(json['note']),
      source: serializer.fromJson<String>(json['source']),
      statementId: serializer.fromJson<int?>(json['statementId']),
      fingerprint: serializer.fromJson<String?>(json['fingerprint']),
      transferGroup: serializer.fromJson<String?>(json['transferGroup']),
      isPerson: serializer.fromJson<bool>(json['isPerson']),
      anomalyOk: serializer.fromJson<bool>(json['anomalyOk']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'accountId': serializer.toJson<int>(accountId),
      'date': serializer.toJson<DateTime>(date),
      'postedDate': serializer.toJson<DateTime?>(postedDate),
      'amount': serializer.toJson<int>(amount),
      'description': serializer.toJson<String>(description),
      'code': serializer.toJson<String?>(code),
      'location': serializer.toJson<String?>(location),
      'bonusRate': serializer.toJson<int?>(bonusRate),
      'foreignCents': serializer.toJson<int?>(foreignCents),
      'foreignCurrency': serializer.toJson<String?>(foreignCurrency),
      'fxRate': serializer.toJson<String?>(fxRate),
      'card': serializer.toJson<String?>(card),
      'kind': serializer.toJson<String>(kind),
      'merchantId': serializer.toJson<int?>(merchantId),
      'categoryId': serializer.toJson<String?>(categoryId),
      'confidence': serializer.toJson<String>(confidence),
      'needsReview': serializer.toJson<bool>(needsReview),
      'note': serializer.toJson<String?>(note),
      'source': serializer.toJson<String>(source),
      'statementId': serializer.toJson<int?>(statementId),
      'fingerprint': serializer.toJson<String?>(fingerprint),
      'transferGroup': serializer.toJson<String?>(transferGroup),
      'isPerson': serializer.toJson<bool>(isPerson),
      'anomalyOk': serializer.toJson<bool>(anomalyOk),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Txn copyWith({
    String? id,
    int? accountId,
    DateTime? date,
    Value<DateTime?> postedDate = const Value.absent(),
    int? amount,
    String? description,
    Value<String?> code = const Value.absent(),
    Value<String?> location = const Value.absent(),
    Value<int?> bonusRate = const Value.absent(),
    Value<int?> foreignCents = const Value.absent(),
    Value<String?> foreignCurrency = const Value.absent(),
    Value<String?> fxRate = const Value.absent(),
    Value<String?> card = const Value.absent(),
    String? kind,
    Value<int?> merchantId = const Value.absent(),
    Value<String?> categoryId = const Value.absent(),
    String? confidence,
    bool? needsReview,
    Value<String?> note = const Value.absent(),
    String? source,
    Value<int?> statementId = const Value.absent(),
    Value<String?> fingerprint = const Value.absent(),
    Value<String?> transferGroup = const Value.absent(),
    bool? isPerson,
    bool? anomalyOk,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Txn(
    id: id ?? this.id,
    accountId: accountId ?? this.accountId,
    date: date ?? this.date,
    postedDate: postedDate.present ? postedDate.value : this.postedDate,
    amount: amount ?? this.amount,
    description: description ?? this.description,
    code: code.present ? code.value : this.code,
    location: location.present ? location.value : this.location,
    bonusRate: bonusRate.present ? bonusRate.value : this.bonusRate,
    foreignCents: foreignCents.present ? foreignCents.value : this.foreignCents,
    foreignCurrency: foreignCurrency.present ? foreignCurrency.value : this.foreignCurrency,
    fxRate: fxRate.present ? fxRate.value : this.fxRate,
    card: card.present ? card.value : this.card,
    kind: kind ?? this.kind,
    merchantId: merchantId.present ? merchantId.value : this.merchantId,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    confidence: confidence ?? this.confidence,
    needsReview: needsReview ?? this.needsReview,
    note: note.present ? note.value : this.note,
    source: source ?? this.source,
    statementId: statementId.present ? statementId.value : this.statementId,
    fingerprint: fingerprint.present ? fingerprint.value : this.fingerprint,
    transferGroup: transferGroup.present ? transferGroup.value : this.transferGroup,
    isPerson: isPerson ?? this.isPerson,
    anomalyOk: anomalyOk ?? this.anomalyOk,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Txn copyWithCompanion(TransactionsCompanion data) {
    return Txn(
      id: data.id.present ? data.id.value : this.id,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      date: data.date.present ? data.date.value : this.date,
      postedDate: data.postedDate.present ? data.postedDate.value : this.postedDate,
      amount: data.amount.present ? data.amount.value : this.amount,
      description: data.description.present ? data.description.value : this.description,
      code: data.code.present ? data.code.value : this.code,
      location: data.location.present ? data.location.value : this.location,
      bonusRate: data.bonusRate.present ? data.bonusRate.value : this.bonusRate,
      foreignCents: data.foreignCents.present ? data.foreignCents.value : this.foreignCents,
      foreignCurrency: data.foreignCurrency.present ? data.foreignCurrency.value : this.foreignCurrency,
      fxRate: data.fxRate.present ? data.fxRate.value : this.fxRate,
      card: data.card.present ? data.card.value : this.card,
      kind: data.kind.present ? data.kind.value : this.kind,
      merchantId: data.merchantId.present ? data.merchantId.value : this.merchantId,
      categoryId: data.categoryId.present ? data.categoryId.value : this.categoryId,
      confidence: data.confidence.present ? data.confidence.value : this.confidence,
      needsReview: data.needsReview.present ? data.needsReview.value : this.needsReview,
      note: data.note.present ? data.note.value : this.note,
      source: data.source.present ? data.source.value : this.source,
      statementId: data.statementId.present ? data.statementId.value : this.statementId,
      fingerprint: data.fingerprint.present ? data.fingerprint.value : this.fingerprint,
      transferGroup: data.transferGroup.present ? data.transferGroup.value : this.transferGroup,
      isPerson: data.isPerson.present ? data.isPerson.value : this.isPerson,
      anomalyOk: data.anomalyOk.present ? data.anomalyOk.value : this.anomalyOk,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Txn(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('date: $date, ')
          ..write('postedDate: $postedDate, ')
          ..write('amount: $amount, ')
          ..write('description: $description, ')
          ..write('code: $code, ')
          ..write('location: $location, ')
          ..write('bonusRate: $bonusRate, ')
          ..write('foreignCents: $foreignCents, ')
          ..write('foreignCurrency: $foreignCurrency, ')
          ..write('fxRate: $fxRate, ')
          ..write('card: $card, ')
          ..write('kind: $kind, ')
          ..write('merchantId: $merchantId, ')
          ..write('categoryId: $categoryId, ')
          ..write('confidence: $confidence, ')
          ..write('needsReview: $needsReview, ')
          ..write('note: $note, ')
          ..write('source: $source, ')
          ..write('statementId: $statementId, ')
          ..write('fingerprint: $fingerprint, ')
          ..write('transferGroup: $transferGroup, ')
          ..write('isPerson: $isPerson, ')
          ..write('anomalyOk: $anomalyOk, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    accountId,
    date,
    postedDate,
    amount,
    description,
    code,
    location,
    bonusRate,
    foreignCents,
    foreignCurrency,
    fxRate,
    card,
    kind,
    merchantId,
    categoryId,
    confidence,
    needsReview,
    note,
    source,
    statementId,
    fingerprint,
    transferGroup,
    isPerson,
    anomalyOk,
    createdAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Txn &&
          other.id == this.id &&
          other.accountId == this.accountId &&
          other.date == this.date &&
          other.postedDate == this.postedDate &&
          other.amount == this.amount &&
          other.description == this.description &&
          other.code == this.code &&
          other.location == this.location &&
          other.bonusRate == this.bonusRate &&
          other.foreignCents == this.foreignCents &&
          other.foreignCurrency == this.foreignCurrency &&
          other.fxRate == this.fxRate &&
          other.card == this.card &&
          other.kind == this.kind &&
          other.merchantId == this.merchantId &&
          other.categoryId == this.categoryId &&
          other.confidence == this.confidence &&
          other.needsReview == this.needsReview &&
          other.note == this.note &&
          other.source == this.source &&
          other.statementId == this.statementId &&
          other.fingerprint == this.fingerprint &&
          other.transferGroup == this.transferGroup &&
          other.isPerson == this.isPerson &&
          other.anomalyOk == this.anomalyOk &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TransactionsCompanion extends UpdateCompanion<Txn> {
  final Value<String> id;
  final Value<int> accountId;
  final Value<DateTime> date;
  final Value<DateTime?> postedDate;
  final Value<int> amount;
  final Value<String> description;
  final Value<String?> code;
  final Value<String?> location;
  final Value<int?> bonusRate;
  final Value<int?> foreignCents;
  final Value<String?> foreignCurrency;
  final Value<String?> fxRate;
  final Value<String?> card;
  final Value<String> kind;
  final Value<int?> merchantId;
  final Value<String?> categoryId;
  final Value<String> confidence;
  final Value<bool> needsReview;
  final Value<String?> note;
  final Value<String> source;
  final Value<int?> statementId;
  final Value<String?> fingerprint;
  final Value<String?> transferGroup;
  final Value<bool> isPerson;
  final Value<bool> anomalyOk;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const TransactionsCompanion({
    this.id = const Value.absent(),
    this.accountId = const Value.absent(),
    this.date = const Value.absent(),
    this.postedDate = const Value.absent(),
    this.amount = const Value.absent(),
    this.description = const Value.absent(),
    this.code = const Value.absent(),
    this.location = const Value.absent(),
    this.bonusRate = const Value.absent(),
    this.foreignCents = const Value.absent(),
    this.foreignCurrency = const Value.absent(),
    this.fxRate = const Value.absent(),
    this.card = const Value.absent(),
    this.kind = const Value.absent(),
    this.merchantId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.confidence = const Value.absent(),
    this.needsReview = const Value.absent(),
    this.note = const Value.absent(),
    this.source = const Value.absent(),
    this.statementId = const Value.absent(),
    this.fingerprint = const Value.absent(),
    this.transferGroup = const Value.absent(),
    this.isPerson = const Value.absent(),
    this.anomalyOk = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionsCompanion.insert({
    required String id,
    required int accountId,
    required DateTime date,
    this.postedDate = const Value.absent(),
    required int amount,
    required String description,
    this.code = const Value.absent(),
    this.location = const Value.absent(),
    this.bonusRate = const Value.absent(),
    this.foreignCents = const Value.absent(),
    this.foreignCurrency = const Value.absent(),
    this.fxRate = const Value.absent(),
    this.card = const Value.absent(),
    required String kind,
    this.merchantId = const Value.absent(),
    this.categoryId = const Value.absent(),
    required String confidence,
    required bool needsReview,
    this.note = const Value.absent(),
    required String source,
    this.statementId = const Value.absent(),
    this.fingerprint = const Value.absent(),
    this.transferGroup = const Value.absent(),
    this.isPerson = const Value.absent(),
    this.anomalyOk = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       accountId = Value(accountId),
       date = Value(date),
       amount = Value(amount),
       description = Value(description),
       kind = Value(kind),
       confidence = Value(confidence),
       needsReview = Value(needsReview),
       source = Value(source),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Txn> custom({
    Expression<String>? id,
    Expression<int>? accountId,
    Expression<DateTime>? date,
    Expression<DateTime>? postedDate,
    Expression<int>? amount,
    Expression<String>? description,
    Expression<String>? code,
    Expression<String>? location,
    Expression<int>? bonusRate,
    Expression<int>? foreignCents,
    Expression<String>? foreignCurrency,
    Expression<String>? fxRate,
    Expression<String>? card,
    Expression<String>? kind,
    Expression<int>? merchantId,
    Expression<String>? categoryId,
    Expression<String>? confidence,
    Expression<bool>? needsReview,
    Expression<String>? note,
    Expression<String>? source,
    Expression<int>? statementId,
    Expression<String>? fingerprint,
    Expression<String>? transferGroup,
    Expression<bool>? isPerson,
    Expression<bool>? anomalyOk,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accountId != null) 'account_id': accountId,
      if (date != null) 'date': date,
      if (postedDate != null) 'posted_date': postedDate,
      if (amount != null) 'amount': amount,
      if (description != null) 'description': description,
      if (code != null) 'code': code,
      if (location != null) 'location': location,
      if (bonusRate != null) 'bonus_rate': bonusRate,
      if (foreignCents != null) 'foreign_cents': foreignCents,
      if (foreignCurrency != null) 'foreign_currency': foreignCurrency,
      if (fxRate != null) 'fx_rate': fxRate,
      if (card != null) 'card': card,
      if (kind != null) 'kind': kind,
      if (merchantId != null) 'merchant_id': merchantId,
      if (categoryId != null) 'category_id': categoryId,
      if (confidence != null) 'confidence': confidence,
      if (needsReview != null) 'needs_review': needsReview,
      if (note != null) 'note': note,
      if (source != null) 'source': source,
      if (statementId != null) 'statement_id': statementId,
      if (fingerprint != null) 'fingerprint': fingerprint,
      if (transferGroup != null) 'transfer_group': transferGroup,
      if (isPerson != null) 'is_person': isPerson,
      if (anomalyOk != null) 'anomaly_ok': anomalyOk,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionsCompanion copyWith({
    Value<String>? id,
    Value<int>? accountId,
    Value<DateTime>? date,
    Value<DateTime?>? postedDate,
    Value<int>? amount,
    Value<String>? description,
    Value<String?>? code,
    Value<String?>? location,
    Value<int?>? bonusRate,
    Value<int?>? foreignCents,
    Value<String?>? foreignCurrency,
    Value<String?>? fxRate,
    Value<String?>? card,
    Value<String>? kind,
    Value<int?>? merchantId,
    Value<String?>? categoryId,
    Value<String>? confidence,
    Value<bool>? needsReview,
    Value<String?>? note,
    Value<String>? source,
    Value<int?>? statementId,
    Value<String?>? fingerprint,
    Value<String?>? transferGroup,
    Value<bool>? isPerson,
    Value<bool>? anomalyOk,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return TransactionsCompanion(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      date: date ?? this.date,
      postedDate: postedDate ?? this.postedDate,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      code: code ?? this.code,
      location: location ?? this.location,
      bonusRate: bonusRate ?? this.bonusRate,
      foreignCents: foreignCents ?? this.foreignCents,
      foreignCurrency: foreignCurrency ?? this.foreignCurrency,
      fxRate: fxRate ?? this.fxRate,
      card: card ?? this.card,
      kind: kind ?? this.kind,
      merchantId: merchantId ?? this.merchantId,
      categoryId: categoryId ?? this.categoryId,
      confidence: confidence ?? this.confidence,
      needsReview: needsReview ?? this.needsReview,
      note: note ?? this.note,
      source: source ?? this.source,
      statementId: statementId ?? this.statementId,
      fingerprint: fingerprint ?? this.fingerprint,
      transferGroup: transferGroup ?? this.transferGroup,
      isPerson: isPerson ?? this.isPerson,
      anomalyOk: anomalyOk ?? this.anomalyOk,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<int>(accountId.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (postedDate.present) {
      map['posted_date'] = Variable<DateTime>(postedDate.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (bonusRate.present) {
      map['bonus_rate'] = Variable<int>(bonusRate.value);
    }
    if (foreignCents.present) {
      map['foreign_cents'] = Variable<int>(foreignCents.value);
    }
    if (foreignCurrency.present) {
      map['foreign_currency'] = Variable<String>(foreignCurrency.value);
    }
    if (fxRate.present) {
      map['fx_rate'] = Variable<String>(fxRate.value);
    }
    if (card.present) {
      map['card'] = Variable<String>(card.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (merchantId.present) {
      map['merchant_id'] = Variable<int>(merchantId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (confidence.present) {
      map['confidence'] = Variable<String>(confidence.value);
    }
    if (needsReview.present) {
      map['needs_review'] = Variable<bool>(needsReview.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (statementId.present) {
      map['statement_id'] = Variable<int>(statementId.value);
    }
    if (fingerprint.present) {
      map['fingerprint'] = Variable<String>(fingerprint.value);
    }
    if (transferGroup.present) {
      map['transfer_group'] = Variable<String>(transferGroup.value);
    }
    if (isPerson.present) {
      map['is_person'] = Variable<bool>(isPerson.value);
    }
    if (anomalyOk.present) {
      map['anomaly_ok'] = Variable<bool>(anomalyOk.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCompanion(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('date: $date, ')
          ..write('postedDate: $postedDate, ')
          ..write('amount: $amount, ')
          ..write('description: $description, ')
          ..write('code: $code, ')
          ..write('location: $location, ')
          ..write('bonusRate: $bonusRate, ')
          ..write('foreignCents: $foreignCents, ')
          ..write('foreignCurrency: $foreignCurrency, ')
          ..write('fxRate: $fxRate, ')
          ..write('card: $card, ')
          ..write('kind: $kind, ')
          ..write('merchantId: $merchantId, ')
          ..write('categoryId: $categoryId, ')
          ..write('confidence: $confidence, ')
          ..write('needsReview: $needsReview, ')
          ..write('note: $note, ')
          ..write('source: $source, ')
          ..write('statementId: $statementId, ')
          ..write('fingerprint: $fingerprint, ')
          ..write('transferGroup: $transferGroup, ')
          ..write('isPerson: $isPerson, ')
          ..write('anomalyOk: $anomalyOk, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SplitsTable extends Splits with TableInfo<$SplitsTable, Split> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SplitsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _transactionIdMeta = const VerificationMeta('transactionId');
  @override
  late final GeneratedColumn<String> transactionId = GeneratedColumn<String>(
    'transaction_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES transactions (id) ON DELETE CASCADE'),
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES categories (id)'),
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, transactionId, categoryId, amount];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'splits';
  @override
  VerificationContext validateIntegrity(Insertable<Split> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('transaction_id')) {
      context.handle(
        _transactionIdMeta,
        transactionId.isAcceptableOrUnknown(data['transaction_id']!, _transactionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_transactionIdMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(_categoryIdMeta, categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta));
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta, amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Split map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Split(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      transactionId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}transaction_id'])!,
      categoryId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}category_id'])!,
      amount: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}amount'])!,
    );
  }

  @override
  $SplitsTable createAlias(String alias) {
    return $SplitsTable(attachedDatabase, alias);
  }
}

class Split extends DataClass implements Insertable<Split> {
  final int id;
  final String transactionId;
  final String categoryId;

  /// Signed cents, same sign as the transaction.
  final int amount;
  const Split({required this.id, required this.transactionId, required this.categoryId, required this.amount});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['transaction_id'] = Variable<String>(transactionId);
    map['category_id'] = Variable<String>(categoryId);
    map['amount'] = Variable<int>(amount);
    return map;
  }

  SplitsCompanion toCompanion(bool nullToAbsent) {
    return SplitsCompanion(
      id: Value(id),
      transactionId: Value(transactionId),
      categoryId: Value(categoryId),
      amount: Value(amount),
    );
  }

  factory Split.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Split(
      id: serializer.fromJson<int>(json['id']),
      transactionId: serializer.fromJson<String>(json['transactionId']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      amount: serializer.fromJson<int>(json['amount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'transactionId': serializer.toJson<String>(transactionId),
      'categoryId': serializer.toJson<String>(categoryId),
      'amount': serializer.toJson<int>(amount),
    };
  }

  Split copyWith({int? id, String? transactionId, String? categoryId, int? amount}) => Split(
    id: id ?? this.id,
    transactionId: transactionId ?? this.transactionId,
    categoryId: categoryId ?? this.categoryId,
    amount: amount ?? this.amount,
  );
  Split copyWithCompanion(SplitsCompanion data) {
    return Split(
      id: data.id.present ? data.id.value : this.id,
      transactionId: data.transactionId.present ? data.transactionId.value : this.transactionId,
      categoryId: data.categoryId.present ? data.categoryId.value : this.categoryId,
      amount: data.amount.present ? data.amount.value : this.amount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Split(')
          ..write('id: $id, ')
          ..write('transactionId: $transactionId, ')
          ..write('categoryId: $categoryId, ')
          ..write('amount: $amount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, transactionId, categoryId, amount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Split &&
          other.id == this.id &&
          other.transactionId == this.transactionId &&
          other.categoryId == this.categoryId &&
          other.amount == this.amount);
}

class SplitsCompanion extends UpdateCompanion<Split> {
  final Value<int> id;
  final Value<String> transactionId;
  final Value<String> categoryId;
  final Value<int> amount;
  const SplitsCompanion({
    this.id = const Value.absent(),
    this.transactionId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.amount = const Value.absent(),
  });
  SplitsCompanion.insert({
    this.id = const Value.absent(),
    required String transactionId,
    required String categoryId,
    required int amount,
  }) : transactionId = Value(transactionId),
       categoryId = Value(categoryId),
       amount = Value(amount);
  static Insertable<Split> custom({
    Expression<int>? id,
    Expression<String>? transactionId,
    Expression<String>? categoryId,
    Expression<int>? amount,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (transactionId != null) 'transaction_id': transactionId,
      if (categoryId != null) 'category_id': categoryId,
      if (amount != null) 'amount': amount,
    });
  }

  SplitsCompanion copyWith({
    Value<int>? id,
    Value<String>? transactionId,
    Value<String>? categoryId,
    Value<int>? amount,
  }) {
    return SplitsCompanion(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (transactionId.present) {
      map['transaction_id'] = Variable<String>(transactionId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SplitsCompanion(')
          ..write('id: $id, ')
          ..write('transactionId: $transactionId, ')
          ..write('categoryId: $categoryId, ')
          ..write('amount: $amount')
          ..write(')'))
        .toString();
  }
}

class $TargetsTable extends Targets with TableInfo<$TargetsTable, TargetRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TargetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _scopeMeta = const VerificationMeta('scope');
  @override
  late final GeneratedColumn<String> scope = GeneratedColumn<String>(
    'scope',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES categories (id)'),
  );
  static const VerificationMeta _periodMeta = const VerificationMeta('period');
  @override
  late final GeneratedColumn<String> period = GeneratedColumn<String>(
    'period',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, scope, categoryId, period, amount, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'targets';
  @override
  VerificationContext validateIntegrity(Insertable<TargetRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('scope')) {
      context.handle(_scopeMeta, scope.isAcceptableOrUnknown(data['scope']!, _scopeMeta));
    } else if (isInserting) {
      context.missing(_scopeMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(_categoryIdMeta, categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta));
    }
    if (data.containsKey('period')) {
      context.handle(_periodMeta, period.isAcceptableOrUnknown(data['period']!, _periodMeta));
    } else if (isInserting) {
      context.missing(_periodMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta, amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TargetRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TargetRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      scope: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}scope'])!,
      categoryId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}category_id']),
      period: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}period'])!,
      amount: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}amount'])!,
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $TargetsTable createAlias(String alias) {
    return $TargetsTable(attachedDatabase, alias);
  }
}

class TargetRow extends DataClass implements Insertable<TargetRow> {
  final int id;

  /// `Scope.id`: `desjardins`, `cash-CAD`…
  final String scope;
  final String? categoryId;

  /// `TargetPeriod.name`.
  final String period;

  /// Cents, in the scope's currency.
  final int amount;
  final DateTime createdAt;
  const TargetRow({
    required this.id,
    required this.scope,
    this.categoryId,
    required this.period,
    required this.amount,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['scope'] = Variable<String>(scope);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    map['period'] = Variable<String>(period);
    map['amount'] = Variable<int>(amount);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  TargetsCompanion toCompanion(bool nullToAbsent) {
    return TargetsCompanion(
      id: Value(id),
      scope: Value(scope),
      categoryId: categoryId == null && nullToAbsent ? const Value.absent() : Value(categoryId),
      period: Value(period),
      amount: Value(amount),
      createdAt: Value(createdAt),
    );
  }

  factory TargetRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TargetRow(
      id: serializer.fromJson<int>(json['id']),
      scope: serializer.fromJson<String>(json['scope']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      period: serializer.fromJson<String>(json['period']),
      amount: serializer.fromJson<int>(json['amount']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'scope': serializer.toJson<String>(scope),
      'categoryId': serializer.toJson<String?>(categoryId),
      'period': serializer.toJson<String>(period),
      'amount': serializer.toJson<int>(amount),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  TargetRow copyWith({
    int? id,
    String? scope,
    Value<String?> categoryId = const Value.absent(),
    String? period,
    int? amount,
    DateTime? createdAt,
  }) => TargetRow(
    id: id ?? this.id,
    scope: scope ?? this.scope,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    period: period ?? this.period,
    amount: amount ?? this.amount,
    createdAt: createdAt ?? this.createdAt,
  );
  TargetRow copyWithCompanion(TargetsCompanion data) {
    return TargetRow(
      id: data.id.present ? data.id.value : this.id,
      scope: data.scope.present ? data.scope.value : this.scope,
      categoryId: data.categoryId.present ? data.categoryId.value : this.categoryId,
      period: data.period.present ? data.period.value : this.period,
      amount: data.amount.present ? data.amount.value : this.amount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TargetRow(')
          ..write('id: $id, ')
          ..write('scope: $scope, ')
          ..write('categoryId: $categoryId, ')
          ..write('period: $period, ')
          ..write('amount: $amount, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, scope, categoryId, period, amount, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TargetRow &&
          other.id == this.id &&
          other.scope == this.scope &&
          other.categoryId == this.categoryId &&
          other.period == this.period &&
          other.amount == this.amount &&
          other.createdAt == this.createdAt);
}

class TargetsCompanion extends UpdateCompanion<TargetRow> {
  final Value<int> id;
  final Value<String> scope;
  final Value<String?> categoryId;
  final Value<String> period;
  final Value<int> amount;
  final Value<DateTime> createdAt;
  const TargetsCompanion({
    this.id = const Value.absent(),
    this.scope = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.period = const Value.absent(),
    this.amount = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  TargetsCompanion.insert({
    this.id = const Value.absent(),
    required String scope,
    this.categoryId = const Value.absent(),
    required String period,
    required int amount,
    required DateTime createdAt,
  }) : scope = Value(scope),
       period = Value(period),
       amount = Value(amount),
       createdAt = Value(createdAt);
  static Insertable<TargetRow> custom({
    Expression<int>? id,
    Expression<String>? scope,
    Expression<String>? categoryId,
    Expression<String>? period,
    Expression<int>? amount,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (scope != null) 'scope': scope,
      if (categoryId != null) 'category_id': categoryId,
      if (period != null) 'period': period,
      if (amount != null) 'amount': amount,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  TargetsCompanion copyWith({
    Value<int>? id,
    Value<String>? scope,
    Value<String?>? categoryId,
    Value<String>? period,
    Value<int>? amount,
    Value<DateTime>? createdAt,
  }) {
    return TargetsCompanion(
      id: id ?? this.id,
      scope: scope ?? this.scope,
      categoryId: categoryId ?? this.categoryId,
      period: period ?? this.period,
      amount: amount ?? this.amount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (scope.present) {
      map['scope'] = Variable<String>(scope.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (period.present) {
      map['period'] = Variable<String>(period.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TargetsCompanion(')
          ..write('id: $id, ')
          ..write('scope: $scope, ')
          ..write('categoryId: $categoryId, ')
          ..write('period: $period, ')
          ..write('amount: $amount, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$ExpenseDatabase extends GeneratedDatabase {
  _$ExpenseDatabase(QueryExecutor e) : super(e);
  $ExpenseDatabaseManager get managers => $ExpenseDatabaseManager(this);
  late final $AccountsTable accounts = $AccountsTable(this);
  late final $StatementsTable statements = $StatementsTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $MerchantsTable merchants = $MerchantsTable(this);
  late final $RulesTable rules = $RulesTable(this);
  late final $TransactionsTable transactions = $TransactionsTable(this);
  late final $SplitsTable splits = $SplitsTable(this);
  late final $TargetsTable targets = $TargetsTable(this);
  late final Index accountsRef = Index(
    'accounts_ref',
    'CREATE UNIQUE INDEX accounts_ref ON accounts (institution, ref)',
  );
  late final Index transactionsAccountDate = Index(
    'transactions_account_date',
    'CREATE INDEX transactions_account_date ON transactions (account_id, date)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables => allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    accounts,
    statements,
    categories,
    merchants,
    rules,
    transactions,
    splits,
    targets,
    accountsRef,
    transactionsAccountDate,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName('transactions', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('splits', kind: UpdateKind.delete)],
    ),
  ]);
  @override
  DriftDatabaseOptions get options => const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$AccountsTableCreateCompanionBuilder = AccountsCompanion Function({
  Value<int> id,
  required String institution,
  required String ref,
  required String name,
  required String type,
  required String currency,
  Value<int?> balance,
  Value<DateTime?> balanceDate,
});
typedef $$AccountsTableUpdateCompanionBuilder = AccountsCompanion Function({
  Value<int> id,
  Value<String> institution,
  Value<String> ref,
  Value<String> name,
  Value<String> type,
  Value<String> currency,
  Value<int?> balance,
  Value<DateTime?> balanceDate,
});

final class $$AccountsTableReferences extends BaseReferences<_$ExpenseDatabase, $AccountsTable, Account> {
  $$AccountsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TransactionsTable, List<Txn>> _transactionsRefsTable(_$ExpenseDatabase db) =>
      MultiTypedResultKey.fromTable(db.transactions, aliasName: 'accounts__id__transactions__account_id');

  $$TransactionsTableProcessedTableManager get transactionsRefs {
    final manager = $$TransactionsTableTableManager(
      $_db,
      $_db.transactions,
    ).filter((f) => f.accountId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_transactionsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$AccountsTableFilterComposer extends Composer<_$ExpenseDatabase, $AccountsTable> {
  $$AccountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get institution =>
      $composableBuilder(column: $table.institution, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ref => $composableBuilder(column: $table.ref, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get balance =>
      $composableBuilder(column: $table.balance, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get balanceDate =>
      $composableBuilder(column: $table.balanceDate, builder: (column) => ColumnFilters(column));

  Expression<bool> transactionsRefs(Expression<bool> Function($$TransactionsTableFilterComposer f) f) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.accountId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$TransactionsTableFilterComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AccountsTableOrderingComposer extends Composer<_$ExpenseDatabase, $AccountsTable> {
  $$AccountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get institution =>
      $composableBuilder(column: $table.institution, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ref =>
      $composableBuilder(column: $table.ref, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get balance =>
      $composableBuilder(column: $table.balance, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get balanceDate =>
      $composableBuilder(column: $table.balanceDate, builder: (column) => ColumnOrderings(column));
}

class $$AccountsTableAnnotationComposer extends Composer<_$ExpenseDatabase, $AccountsTable> {
  $$AccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get institution =>
      $composableBuilder(column: $table.institution, builder: (column) => column);

  GeneratedColumn<String> get ref => $composableBuilder(column: $table.ref, builder: (column) => column);

  GeneratedColumn<String> get name => $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get type => $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get currency => $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<int> get balance => $composableBuilder(column: $table.balance, builder: (column) => column);

  GeneratedColumn<DateTime> get balanceDate =>
      $composableBuilder(column: $table.balanceDate, builder: (column) => column);

  Expression<T> transactionsRefs<T extends Object>(Expression<T> Function($$TransactionsTableAnnotationComposer a) f) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.accountId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$TransactionsTableAnnotationComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AccountsTableTableManager
    extends
        RootTableManager<
          _$ExpenseDatabase,
          $AccountsTable,
          Account,
          $$AccountsTableFilterComposer,
          $$AccountsTableOrderingComposer,
          $$AccountsTableAnnotationComposer,
          $$AccountsTableCreateCompanionBuilder,
          $$AccountsTableUpdateCompanionBuilder,
          (Account, $$AccountsTableReferences),
          Account,
          PrefetchHooks Function({bool transactionsRefs})
        > {
  $$AccountsTableTableManager(_$ExpenseDatabase db, $AccountsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$AccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$AccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$AccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> institution = const Value.absent(),
                Value<String> ref = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<int?> balance = const Value.absent(),
                Value<DateTime?> balanceDate = const Value.absent(),
              }) => AccountsCompanion(
                id: id,
                institution: institution,
                ref: ref,
                name: name,
                type: type,
                currency: currency,
                balance: balance,
                balanceDate: balanceDate,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String institution,
                required String ref,
                required String name,
                required String type,
                required String currency,
                Value<int?> balance = const Value.absent(),
                Value<DateTime?> balanceDate = const Value.absent(),
              }) => AccountsCompanion.insert(
                id: id,
                institution: institution,
                ref: ref,
                name: name,
                type: type,
                currency: currency,
                balance: balance,
                balanceDate: balanceDate,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable<$AccountsTable, Account>(table), $$AccountsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({transactionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (transactionsRefs) db.transactions],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (transactionsRefs)
                    await $_getPrefetchedDataByColumns<Account, $AccountsTable, Txn, $TransactionsTable>(
                      currentTable: table,
                      referencedTable: $$AccountsTableReferences._transactionsRefsTable(db),
                      managerFromTypedResult: (p0) => $$AccountsTableReferences(db, table, p0).transactionsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'account_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$AccountsTableProcessedTableManager =
    ProcessedTableManager<
      _$ExpenseDatabase,
      $AccountsTable,
      Account,
      $$AccountsTableFilterComposer,
      $$AccountsTableOrderingComposer,
      $$AccountsTableAnnotationComposer,
      $$AccountsTableCreateCompanionBuilder,
      $$AccountsTableUpdateCompanionBuilder,
      (Account, $$AccountsTableReferences),
      Account,
      PrefetchHooks Function({bool transactionsRefs})
    >;
typedef $$StatementsTableCreateCompanionBuilder = StatementsCompanion Function({
  Value<int> id,
  required String institution,
  required String format,
  required DateTime periodStart,
  required DateTime periodEnd,
  Value<bool> coversSincePrevious,
  required String fileHash,
  required String fileName,
  required DateTime importedAt,
  required int lineCount,
  required int newCount,
  Value<String> fileType,
  Value<bool> verified,
});
typedef $$StatementsTableUpdateCompanionBuilder = StatementsCompanion Function({
  Value<int> id,
  Value<String> institution,
  Value<String> format,
  Value<DateTime> periodStart,
  Value<DateTime> periodEnd,
  Value<bool> coversSincePrevious,
  Value<String> fileHash,
  Value<String> fileName,
  Value<DateTime> importedAt,
  Value<int> lineCount,
  Value<int> newCount,
  Value<String> fileType,
  Value<bool> verified,
});

final class $$StatementsTableReferences extends BaseReferences<_$ExpenseDatabase, $StatementsTable, Statement> {
  $$StatementsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TransactionsTable, List<Txn>> _transactionsRefsTable(_$ExpenseDatabase db) =>
      MultiTypedResultKey.fromTable(db.transactions, aliasName: 'statements__id__transactions__statement_id');

  $$TransactionsTableProcessedTableManager get transactionsRefs {
    final manager = $$TransactionsTableTableManager(
      $_db,
      $_db.transactions,
    ).filter((f) => f.statementId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_transactionsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$StatementsTableFilterComposer extends Composer<_$ExpenseDatabase, $StatementsTable> {
  $$StatementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get institution =>
      $composableBuilder(column: $table.institution, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get format =>
      $composableBuilder(column: $table.format, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get periodStart =>
      $composableBuilder(column: $table.periodStart, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get periodEnd =>
      $composableBuilder(column: $table.periodEnd, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get coversSincePrevious =>
      $composableBuilder(column: $table.coversSincePrevious, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fileHash =>
      $composableBuilder(column: $table.fileHash, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get importedAt =>
      $composableBuilder(column: $table.importedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lineCount =>
      $composableBuilder(column: $table.lineCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get newCount =>
      $composableBuilder(column: $table.newCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fileType =>
      $composableBuilder(column: $table.fileType, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get verified =>
      $composableBuilder(column: $table.verified, builder: (column) => ColumnFilters(column));

  Expression<bool> transactionsRefs(Expression<bool> Function($$TransactionsTableFilterComposer f) f) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.statementId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$TransactionsTableFilterComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$StatementsTableOrderingComposer extends Composer<_$ExpenseDatabase, $StatementsTable> {
  $$StatementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get institution =>
      $composableBuilder(column: $table.institution, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get format =>
      $composableBuilder(column: $table.format, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get periodStart =>
      $composableBuilder(column: $table.periodStart, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get periodEnd =>
      $composableBuilder(column: $table.periodEnd, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get coversSincePrevious =>
      $composableBuilder(column: $table.coversSincePrevious, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fileHash =>
      $composableBuilder(column: $table.fileHash, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get importedAt =>
      $composableBuilder(column: $table.importedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lineCount =>
      $composableBuilder(column: $table.lineCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get newCount =>
      $composableBuilder(column: $table.newCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fileType =>
      $composableBuilder(column: $table.fileType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get verified =>
      $composableBuilder(column: $table.verified, builder: (column) => ColumnOrderings(column));
}

class $$StatementsTableAnnotationComposer extends Composer<_$ExpenseDatabase, $StatementsTable> {
  $$StatementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get institution =>
      $composableBuilder(column: $table.institution, builder: (column) => column);

  GeneratedColumn<String> get format => $composableBuilder(column: $table.format, builder: (column) => column);

  GeneratedColumn<DateTime> get periodStart =>
      $composableBuilder(column: $table.periodStart, builder: (column) => column);

  GeneratedColumn<DateTime> get periodEnd => $composableBuilder(column: $table.periodEnd, builder: (column) => column);

  GeneratedColumn<bool> get coversSincePrevious =>
      $composableBuilder(column: $table.coversSincePrevious, builder: (column) => column);

  GeneratedColumn<String> get fileHash => $composableBuilder(column: $table.fileHash, builder: (column) => column);

  GeneratedColumn<String> get fileName => $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<DateTime> get importedAt =>
      $composableBuilder(column: $table.importedAt, builder: (column) => column);

  GeneratedColumn<int> get lineCount => $composableBuilder(column: $table.lineCount, builder: (column) => column);

  GeneratedColumn<int> get newCount => $composableBuilder(column: $table.newCount, builder: (column) => column);

  GeneratedColumn<String> get fileType => $composableBuilder(column: $table.fileType, builder: (column) => column);

  GeneratedColumn<bool> get verified => $composableBuilder(column: $table.verified, builder: (column) => column);

  Expression<T> transactionsRefs<T extends Object>(Expression<T> Function($$TransactionsTableAnnotationComposer a) f) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.statementId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$TransactionsTableAnnotationComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$StatementsTableTableManager
    extends
        RootTableManager<
          _$ExpenseDatabase,
          $StatementsTable,
          Statement,
          $$StatementsTableFilterComposer,
          $$StatementsTableOrderingComposer,
          $$StatementsTableAnnotationComposer,
          $$StatementsTableCreateCompanionBuilder,
          $$StatementsTableUpdateCompanionBuilder,
          (Statement, $$StatementsTableReferences),
          Statement,
          PrefetchHooks Function({bool transactionsRefs})
        > {
  $$StatementsTableTableManager(_$ExpenseDatabase db, $StatementsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$StatementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$StatementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$StatementsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> institution = const Value.absent(),
                Value<String> format = const Value.absent(),
                Value<DateTime> periodStart = const Value.absent(),
                Value<DateTime> periodEnd = const Value.absent(),
                Value<bool> coversSincePrevious = const Value.absent(),
                Value<String> fileHash = const Value.absent(),
                Value<String> fileName = const Value.absent(),
                Value<DateTime> importedAt = const Value.absent(),
                Value<int> lineCount = const Value.absent(),
                Value<int> newCount = const Value.absent(),
                Value<String> fileType = const Value.absent(),
                Value<bool> verified = const Value.absent(),
              }) => StatementsCompanion(
                id: id,
                institution: institution,
                format: format,
                periodStart: periodStart,
                periodEnd: periodEnd,
                coversSincePrevious: coversSincePrevious,
                fileHash: fileHash,
                fileName: fileName,
                importedAt: importedAt,
                lineCount: lineCount,
                newCount: newCount,
                fileType: fileType,
                verified: verified,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String institution,
                required String format,
                required DateTime periodStart,
                required DateTime periodEnd,
                Value<bool> coversSincePrevious = const Value.absent(),
                required String fileHash,
                required String fileName,
                required DateTime importedAt,
                required int lineCount,
                required int newCount,
                Value<String> fileType = const Value.absent(),
                Value<bool> verified = const Value.absent(),
              }) => StatementsCompanion.insert(
                id: id,
                institution: institution,
                format: format,
                periodStart: periodStart,
                periodEnd: periodEnd,
                coversSincePrevious: coversSincePrevious,
                fileHash: fileHash,
                fileName: fileName,
                importedAt: importedAt,
                lineCount: lineCount,
                newCount: newCount,
                fileType: fileType,
                verified: verified,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable<$StatementsTable, Statement>(table), $$StatementsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({transactionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (transactionsRefs) db.transactions],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (transactionsRefs)
                    await $_getPrefetchedDataByColumns<Statement, $StatementsTable, Txn, $TransactionsTable>(
                      currentTable: table,
                      referencedTable: $$StatementsTableReferences._transactionsRefsTable(db),
                      managerFromTypedResult: (p0) => $$StatementsTableReferences(db, table, p0).transactionsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'statement_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$StatementsTableProcessedTableManager =
    ProcessedTableManager<
      _$ExpenseDatabase,
      $StatementsTable,
      Statement,
      $$StatementsTableFilterComposer,
      $$StatementsTableOrderingComposer,
      $$StatementsTableAnnotationComposer,
      $$StatementsTableCreateCompanionBuilder,
      $$StatementsTableUpdateCompanionBuilder,
      (Statement, $$StatementsTableReferences),
      Statement,
      PrefetchHooks Function({bool transactionsRefs})
    >;
typedef $$CategoriesTableCreateCompanionBuilder = CategoriesCompanion Function({
  required String id,
  Value<String?> parentId,
  required String nameFr,
  required String nameEn,
  required String type,
  required int color,
  required int sortOrder,
  Value<bool> archived,
  Value<bool> excludedFromShare,
  Value<int> rowid,
});
typedef $$CategoriesTableUpdateCompanionBuilder = CategoriesCompanion Function({
  Value<String> id,
  Value<String?> parentId,
  Value<String> nameFr,
  Value<String> nameEn,
  Value<String> type,
  Value<int> color,
  Value<int> sortOrder,
  Value<bool> archived,
  Value<bool> excludedFromShare,
  Value<int> rowid,
});

final class $$CategoriesTableReferences extends BaseReferences<_$ExpenseDatabase, $CategoriesTable, CategoryRow> {
  $$CategoriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$MerchantsTable, List<Merchant>> _merchantsRefsTable(_$ExpenseDatabase db) =>
      MultiTypedResultKey.fromTable(db.merchants, aliasName: 'categories__id__merchants__category_id');

  $$MerchantsTableProcessedTableManager get merchantsRefs {
    final manager = $$MerchantsTableTableManager(
      $_db,
      $_db.merchants,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_merchantsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$RulesTable, List<RuleRow>> _rulesRefsTable(_$ExpenseDatabase db) =>
      MultiTypedResultKey.fromTable(db.rules, aliasName: 'categories__id__rules__category_id');

  $$RulesTableProcessedTableManager get rulesRefs {
    final manager = $$RulesTableTableManager(
      $_db,
      $_db.rules,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_rulesRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$TransactionsTable, List<Txn>> _transactionsRefsTable(_$ExpenseDatabase db) =>
      MultiTypedResultKey.fromTable(db.transactions, aliasName: 'categories__id__transactions__category_id');

  $$TransactionsTableProcessedTableManager get transactionsRefs {
    final manager = $$TransactionsTableTableManager(
      $_db,
      $_db.transactions,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_transactionsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$SplitsTable, List<Split>> _splitsRefsTable(_$ExpenseDatabase db) =>
      MultiTypedResultKey.fromTable(db.splits, aliasName: 'categories__id__splits__category_id');

  $$SplitsTableProcessedTableManager get splitsRefs {
    final manager = $$SplitsTableTableManager(
      $_db,
      $_db.splits,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_splitsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$TargetsTable, List<TargetRow>> _targetsRefsTable(_$ExpenseDatabase db) =>
      MultiTypedResultKey.fromTable(db.targets, aliasName: 'categories__id__targets__category_id');

  $$TargetsTableProcessedTableManager get targetsRefs {
    final manager = $$TargetsTableTableManager(
      $_db,
      $_db.targets,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_targetsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$CategoriesTableFilterComposer extends Composer<_$ExpenseDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nameFr =>
      $composableBuilder(column: $table.nameFr, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nameEn =>
      $composableBuilder(column: $table.nameEn, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get color => $composableBuilder(column: $table.color, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get excludedFromShare =>
      $composableBuilder(column: $table.excludedFromShare, builder: (column) => ColumnFilters(column));

  Expression<bool> merchantsRefs(Expression<bool> Function($$MerchantsTableFilterComposer f) f) {
    final $$MerchantsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.merchants,
      getReferencedColumn: (t) => t.categoryId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$MerchantsTableFilterComposer(
            $db: $db,
            $table: $db.merchants,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> rulesRefs(Expression<bool> Function($$RulesTableFilterComposer f) f) {
    final $$RulesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rules,
      getReferencedColumn: (t) => t.categoryId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$RulesTableFilterComposer(
            $db: $db,
            $table: $db.rules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> transactionsRefs(Expression<bool> Function($$TransactionsTableFilterComposer f) f) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.categoryId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$TransactionsTableFilterComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> splitsRefs(Expression<bool> Function($$SplitsTableFilterComposer f) f) {
    final $$SplitsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.splits,
      getReferencedColumn: (t) => t.categoryId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$SplitsTableFilterComposer(
            $db: $db,
            $table: $db.splits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> targetsRefs(Expression<bool> Function($$TargetsTableFilterComposer f) f) {
    final $$TargetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.targets,
      getReferencedColumn: (t) => t.categoryId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$TargetsTableFilterComposer(
            $db: $db,
            $table: $db.targets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CategoriesTableOrderingComposer extends Composer<_$ExpenseDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nameFr =>
      $composableBuilder(column: $table.nameFr, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nameEn =>
      $composableBuilder(column: $table.nameEn, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get excludedFromShare =>
      $composableBuilder(column: $table.excludedFromShare, builder: (column) => ColumnOrderings(column));
}

class $$CategoriesTableAnnotationComposer extends Composer<_$ExpenseDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get parentId => $composableBuilder(column: $table.parentId, builder: (column) => column);

  GeneratedColumn<String> get nameFr => $composableBuilder(column: $table.nameFr, builder: (column) => column);

  GeneratedColumn<String> get nameEn => $composableBuilder(column: $table.nameEn, builder: (column) => column);

  GeneratedColumn<String> get type => $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get color => $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<int> get sortOrder => $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get archived => $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<bool> get excludedFromShare =>
      $composableBuilder(column: $table.excludedFromShare, builder: (column) => column);

  Expression<T> merchantsRefs<T extends Object>(Expression<T> Function($$MerchantsTableAnnotationComposer a) f) {
    final $$MerchantsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.merchants,
      getReferencedColumn: (t) => t.categoryId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$MerchantsTableAnnotationComposer(
            $db: $db,
            $table: $db.merchants,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> rulesRefs<T extends Object>(Expression<T> Function($$RulesTableAnnotationComposer a) f) {
    final $$RulesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rules,
      getReferencedColumn: (t) => t.categoryId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$RulesTableAnnotationComposer(
            $db: $db,
            $table: $db.rules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> transactionsRefs<T extends Object>(Expression<T> Function($$TransactionsTableAnnotationComposer a) f) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.categoryId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$TransactionsTableAnnotationComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> splitsRefs<T extends Object>(Expression<T> Function($$SplitsTableAnnotationComposer a) f) {
    final $$SplitsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.splits,
      getReferencedColumn: (t) => t.categoryId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$SplitsTableAnnotationComposer(
            $db: $db,
            $table: $db.splits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> targetsRefs<T extends Object>(Expression<T> Function($$TargetsTableAnnotationComposer a) f) {
    final $$TargetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.targets,
      getReferencedColumn: (t) => t.categoryId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$TargetsTableAnnotationComposer(
            $db: $db,
            $table: $db.targets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CategoriesTableTableManager
    extends
        RootTableManager<
          _$ExpenseDatabase,
          $CategoriesTable,
          CategoryRow,
          $$CategoriesTableFilterComposer,
          $$CategoriesTableOrderingComposer,
          $$CategoriesTableAnnotationComposer,
          $$CategoriesTableCreateCompanionBuilder,
          $$CategoriesTableUpdateCompanionBuilder,
          (CategoryRow, $$CategoriesTableReferences),
          CategoryRow,
          PrefetchHooks Function({
            bool merchantsRefs,
            bool rulesRefs,
            bool transactionsRefs,
            bool splitsRefs,
            bool targetsRefs,
          })
        > {
  $$CategoriesTableTableManager(_$ExpenseDatabase db, $CategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<String> nameFr = const Value.absent(),
                Value<String> nameEn = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int> color = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<bool> excludedFromShare = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion(
                id: id,
                parentId: parentId,
                nameFr: nameFr,
                nameEn: nameEn,
                type: type,
                color: color,
                sortOrder: sortOrder,
                archived: archived,
                excludedFromShare: excludedFromShare,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> parentId = const Value.absent(),
                required String nameFr,
                required String nameEn,
                required String type,
                required int color,
                required int sortOrder,
                Value<bool> archived = const Value.absent(),
                Value<bool> excludedFromShare = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion.insert(
                id: id,
                parentId: parentId,
                nameFr: nameFr,
                nameEn: nameEn,
                type: type,
                color: color,
                sortOrder: sortOrder,
                archived: archived,
                excludedFromShare: excludedFromShare,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (e.readTable<$CategoriesTable, CategoryRow>(table), $$CategoriesTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                merchantsRefs = false,
                rulesRefs = false,
                transactionsRefs = false,
                splitsRefs = false,
                targetsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (merchantsRefs) db.merchants,
                    if (rulesRefs) db.rules,
                    if (transactionsRefs) db.transactions,
                    if (splitsRefs) db.splits,
                    if (targetsRefs) db.targets,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (merchantsRefs)
                        await $_getPrefetchedDataByColumns<CategoryRow, $CategoriesTable, Merchant, $MerchantsTable>(
                          currentTable: table,
                          referencedTable: $$CategoriesTableReferences._merchantsRefsTable(db),
                          managerFromTypedResult: (p0) => $$CategoriesTableReferences(db, table, p0).merchantsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'category_id',
                          typedResults: items,
                        ),
                      if (rulesRefs)
                        await $_getPrefetchedDataByColumns<CategoryRow, $CategoriesTable, RuleRow, $RulesTable>(
                          currentTable: table,
                          referencedTable: $$CategoriesTableReferences._rulesRefsTable(db),
                          managerFromTypedResult: (p0) => $$CategoriesTableReferences(db, table, p0).rulesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'category_id',
                          typedResults: items,
                        ),
                      if (transactionsRefs)
                        await $_getPrefetchedDataByColumns<CategoryRow, $CategoriesTable, Txn, $TransactionsTable>(
                          currentTable: table,
                          referencedTable: $$CategoriesTableReferences._transactionsRefsTable(db),
                          managerFromTypedResult: (p0) => $$CategoriesTableReferences(db, table, p0).transactionsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'category_id',
                          typedResults: items,
                        ),
                      if (splitsRefs)
                        await $_getPrefetchedDataByColumns<CategoryRow, $CategoriesTable, Split, $SplitsTable>(
                          currentTable: table,
                          referencedTable: $$CategoriesTableReferences._splitsRefsTable(db),
                          managerFromTypedResult: (p0) => $$CategoriesTableReferences(db, table, p0).splitsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'category_id',
                          typedResults: items,
                        ),
                      if (targetsRefs)
                        await $_getPrefetchedDataByColumns<CategoryRow, $CategoriesTable, TargetRow, $TargetsTable>(
                          currentTable: table,
                          referencedTable: $$CategoriesTableReferences._targetsRefsTable(db),
                          managerFromTypedResult: (p0) => $$CategoriesTableReferences(db, table, p0).targetsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'category_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$ExpenseDatabase,
      $CategoriesTable,
      CategoryRow,
      $$CategoriesTableFilterComposer,
      $$CategoriesTableOrderingComposer,
      $$CategoriesTableAnnotationComposer,
      $$CategoriesTableCreateCompanionBuilder,
      $$CategoriesTableUpdateCompanionBuilder,
      (CategoryRow, $$CategoriesTableReferences),
      CategoryRow,
      PrefetchHooks Function({
        bool merchantsRefs,
        bool rulesRefs,
        bool transactionsRefs,
        bool splitsRefs,
        bool targetsRefs,
      })
    >;
typedef $$MerchantsTableCreateCompanionBuilder = MerchantsCompanion Function({
  Value<int> id,
  required String key,
  required String name,
  Value<String?> categoryId,
});
typedef $$MerchantsTableUpdateCompanionBuilder = MerchantsCompanion Function({
  Value<int> id,
  Value<String> key,
  Value<String> name,
  Value<String?> categoryId,
});

final class $$MerchantsTableReferences extends BaseReferences<_$ExpenseDatabase, $MerchantsTable, Merchant> {
  $$MerchantsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CategoriesTable _categoryIdTable(_$ExpenseDatabase db) =>
      db.categories.createAlias('merchants__category_id__categories__id');

  $$CategoriesTableProcessedTableManager? get categoryId {
    final $_column = $_itemColumn<String>('category_id');
    if ($_column == null) return null;
    final manager = $$CategoriesTableTableManager($_db, $_db.categories).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$TransactionsTable, List<Txn>> _transactionsRefsTable(_$ExpenseDatabase db) =>
      MultiTypedResultKey.fromTable(db.transactions, aliasName: 'merchants__id__transactions__merchant_id');

  $$TransactionsTableProcessedTableManager get transactionsRefs {
    final manager = $$TransactionsTableTableManager(
      $_db,
      $_db.transactions,
    ).filter((f) => f.merchantId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_transactionsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$MerchantsTableFilterComposer extends Composer<_$ExpenseDatabase, $MerchantsTable> {
  $$MerchantsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get key => $composableBuilder(column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> transactionsRefs(Expression<bool> Function($$TransactionsTableFilterComposer f) f) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.merchantId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$TransactionsTableFilterComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MerchantsTableOrderingComposer extends Composer<_$ExpenseDatabase, $MerchantsTable> {
  $$MerchantsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MerchantsTableAnnotationComposer extends Composer<_$ExpenseDatabase, $MerchantsTable> {
  $$MerchantsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get key => $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get name => $composableBuilder(column: $table.name, builder: (column) => column);

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> transactionsRefs<T extends Object>(Expression<T> Function($$TransactionsTableAnnotationComposer a) f) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.merchantId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$TransactionsTableAnnotationComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MerchantsTableTableManager
    extends
        RootTableManager<
          _$ExpenseDatabase,
          $MerchantsTable,
          Merchant,
          $$MerchantsTableFilterComposer,
          $$MerchantsTableOrderingComposer,
          $$MerchantsTableAnnotationComposer,
          $$MerchantsTableCreateCompanionBuilder,
          $$MerchantsTableUpdateCompanionBuilder,
          (Merchant, $$MerchantsTableReferences),
          Merchant,
          PrefetchHooks Function({bool categoryId, bool transactionsRefs})
        > {
  $$MerchantsTableTableManager(_$ExpenseDatabase db, $MerchantsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$MerchantsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$MerchantsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$MerchantsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> key = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> categoryId = const Value.absent(),
          }) => MerchantsCompanion(id: id, key: key, name: name, categoryId: categoryId),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String key,
            required String name,
            Value<String?> categoryId = const Value.absent(),
          }) => MerchantsCompanion.insert(id: id, key: key, name: name, categoryId: categoryId),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable<$MerchantsTable, Merchant>(table), $$MerchantsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({categoryId = false, transactionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (transactionsRefs) db.transactions],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (categoryId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.categoryId,
                        referencedTable: $$MerchantsTableReferences._categoryIdTable(db),
                        referencedColumn: $$MerchantsTableReferences._categoryIdTable(db).id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (transactionsRefs)
                    await $_getPrefetchedDataByColumns<Merchant, $MerchantsTable, Txn, $TransactionsTable>(
                      currentTable: table,
                      referencedTable: $$MerchantsTableReferences._transactionsRefsTable(db),
                      managerFromTypedResult: (p0) => $$MerchantsTableReferences(db, table, p0).transactionsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'merchant_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$MerchantsTableProcessedTableManager =
    ProcessedTableManager<
      _$ExpenseDatabase,
      $MerchantsTable,
      Merchant,
      $$MerchantsTableFilterComposer,
      $$MerchantsTableOrderingComposer,
      $$MerchantsTableAnnotationComposer,
      $$MerchantsTableCreateCompanionBuilder,
      $$MerchantsTableUpdateCompanionBuilder,
      (Merchant, $$MerchantsTableReferences),
      Merchant,
      PrefetchHooks Function({bool categoryId, bool transactionsRefs})
    >;
typedef $$RulesTableCreateCompanionBuilder = RulesCompanion Function({
  Value<int> id,
  required String categoryId,
  Value<String?> descriptionContains,
  Value<String?> merchantKey,
  Value<String?> code,
  required DateTime createdAt,
});
typedef $$RulesTableUpdateCompanionBuilder = RulesCompanion Function({
  Value<int> id,
  Value<String> categoryId,
  Value<String?> descriptionContains,
  Value<String?> merchantKey,
  Value<String?> code,
  Value<DateTime> createdAt,
});

final class $$RulesTableReferences extends BaseReferences<_$ExpenseDatabase, $RulesTable, RuleRow> {
  $$RulesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CategoriesTable _categoryIdTable(_$ExpenseDatabase db) =>
      db.categories.createAlias('rules__category_id__categories__id');

  $$CategoriesTableProcessedTableManager get categoryId {
    final $_column = $_itemColumn<String>('category_id')!;

    final manager = $$CategoriesTableTableManager($_db, $_db.categories).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$RulesTableFilterComposer extends Composer<_$ExpenseDatabase, $RulesTable> {
  $$RulesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get descriptionContains =>
      $composableBuilder(column: $table.descriptionContains, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get merchantKey =>
      $composableBuilder(column: $table.merchantKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get code => $composableBuilder(column: $table.code, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RulesTableOrderingComposer extends Composer<_$ExpenseDatabase, $RulesTable> {
  $$RulesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get descriptionContains =>
      $composableBuilder(column: $table.descriptionContains, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get merchantKey =>
      $composableBuilder(column: $table.merchantKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RulesTableAnnotationComposer extends Composer<_$ExpenseDatabase, $RulesTable> {
  $$RulesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get descriptionContains =>
      $composableBuilder(column: $table.descriptionContains, builder: (column) => column);

  GeneratedColumn<String> get merchantKey =>
      $composableBuilder(column: $table.merchantKey, builder: (column) => column);

  GeneratedColumn<String> get code => $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RulesTableTableManager
    extends
        RootTableManager<
          _$ExpenseDatabase,
          $RulesTable,
          RuleRow,
          $$RulesTableFilterComposer,
          $$RulesTableOrderingComposer,
          $$RulesTableAnnotationComposer,
          $$RulesTableCreateCompanionBuilder,
          $$RulesTableUpdateCompanionBuilder,
          (RuleRow, $$RulesTableReferences),
          RuleRow,
          PrefetchHooks Function({bool categoryId})
        > {
  $$RulesTableTableManager(_$ExpenseDatabase db, $RulesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$RulesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$RulesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$RulesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> categoryId = const Value.absent(),
                Value<String?> descriptionContains = const Value.absent(),
                Value<String?> merchantKey = const Value.absent(),
                Value<String?> code = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => RulesCompanion(
                id: id,
                categoryId: categoryId,
                descriptionContains: descriptionContains,
                merchantKey: merchantKey,
                code: code,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String categoryId,
                Value<String?> descriptionContains = const Value.absent(),
                Value<String?> merchantKey = const Value.absent(),
                Value<String?> code = const Value.absent(),
                required DateTime createdAt,
              }) => RulesCompanion.insert(
                id: id,
                categoryId: categoryId,
                descriptionContains: descriptionContains,
                merchantKey: merchantKey,
                code: code,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) =>
              p0.map((e) => (e.readTable<$RulesTable, RuleRow>(table), $$RulesTableReferences(db, table, e))).toList(),
          prefetchHooksCallback: ({categoryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (categoryId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.categoryId,
                        referencedTable: $$RulesTableReferences._categoryIdTable(db),
                        referencedColumn: $$RulesTableReferences._categoryIdTable(db).id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$RulesTableProcessedTableManager =
    ProcessedTableManager<
      _$ExpenseDatabase,
      $RulesTable,
      RuleRow,
      $$RulesTableFilterComposer,
      $$RulesTableOrderingComposer,
      $$RulesTableAnnotationComposer,
      $$RulesTableCreateCompanionBuilder,
      $$RulesTableUpdateCompanionBuilder,
      (RuleRow, $$RulesTableReferences),
      RuleRow,
      PrefetchHooks Function({bool categoryId})
    >;
typedef $$TransactionsTableCreateCompanionBuilder = TransactionsCompanion Function({
  required String id,
  required int accountId,
  required DateTime date,
  Value<DateTime?> postedDate,
  required int amount,
  required String description,
  Value<String?> code,
  Value<String?> location,
  Value<int?> bonusRate,
  Value<int?> foreignCents,
  Value<String?> foreignCurrency,
  Value<String?> fxRate,
  Value<String?> card,
  required String kind,
  Value<int?> merchantId,
  Value<String?> categoryId,
  required String confidence,
  required bool needsReview,
  Value<String?> note,
  required String source,
  Value<int?> statementId,
  Value<String?> fingerprint,
  Value<String?> transferGroup,
  Value<bool> isPerson,
  Value<bool> anomalyOk,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$TransactionsTableUpdateCompanionBuilder = TransactionsCompanion Function({
  Value<String> id,
  Value<int> accountId,
  Value<DateTime> date,
  Value<DateTime?> postedDate,
  Value<int> amount,
  Value<String> description,
  Value<String?> code,
  Value<String?> location,
  Value<int?> bonusRate,
  Value<int?> foreignCents,
  Value<String?> foreignCurrency,
  Value<String?> fxRate,
  Value<String?> card,
  Value<String> kind,
  Value<int?> merchantId,
  Value<String?> categoryId,
  Value<String> confidence,
  Value<bool> needsReview,
  Value<String?> note,
  Value<String> source,
  Value<int?> statementId,
  Value<String?> fingerprint,
  Value<String?> transferGroup,
  Value<bool> isPerson,
  Value<bool> anomalyOk,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$TransactionsTableReferences extends BaseReferences<_$ExpenseDatabase, $TransactionsTable, Txn> {
  $$TransactionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AccountsTable _accountIdTable(_$ExpenseDatabase db) =>
      db.accounts.createAlias('transactions__account_id__accounts__id');

  $$AccountsTableProcessedTableManager get accountId {
    final $_column = $_itemColumn<int>('account_id')!;

    final manager = $$AccountsTableTableManager($_db, $_db.accounts).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static $MerchantsTable _merchantIdTable(_$ExpenseDatabase db) =>
      db.merchants.createAlias('transactions__merchant_id__merchants__id');

  $$MerchantsTableProcessedTableManager? get merchantId {
    final $_column = $_itemColumn<int>('merchant_id');
    if ($_column == null) return null;
    final manager = $$MerchantsTableTableManager($_db, $_db.merchants).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_merchantIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static $CategoriesTable _categoryIdTable(_$ExpenseDatabase db) =>
      db.categories.createAlias('transactions__category_id__categories__id');

  $$CategoriesTableProcessedTableManager? get categoryId {
    final $_column = $_itemColumn<String>('category_id');
    if ($_column == null) return null;
    final manager = $$CategoriesTableTableManager($_db, $_db.categories).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static $StatementsTable _statementIdTable(_$ExpenseDatabase db) =>
      db.statements.createAlias('transactions__statement_id__statements__id');

  $$StatementsTableProcessedTableManager? get statementId {
    final $_column = $_itemColumn<int>('statement_id');
    if ($_column == null) return null;
    final manager = $$StatementsTableTableManager($_db, $_db.statements).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_statementIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$SplitsTable, List<Split>> _splitsRefsTable(_$ExpenseDatabase db) =>
      MultiTypedResultKey.fromTable(db.splits, aliasName: 'transactions__id__splits__transaction_id');

  $$SplitsTableProcessedTableManager get splitsRefs {
    final manager = $$SplitsTableTableManager(
      $_db,
      $_db.splits,
    ).filter((f) => f.transactionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_splitsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$TransactionsTableFilterComposer extends Composer<_$ExpenseDatabase, $TransactionsTable> {
  $$TransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get postedDate =>
      $composableBuilder(column: $table.postedDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description =>
      $composableBuilder(column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get code => $composableBuilder(column: $table.code, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get bonusRate =>
      $composableBuilder(column: $table.bonusRate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get foreignCents =>
      $composableBuilder(column: $table.foreignCents, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get foreignCurrency =>
      $composableBuilder(column: $table.foreignCurrency, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fxRate =>
      $composableBuilder(column: $table.fxRate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get card => $composableBuilder(column: $table.card, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kind => $composableBuilder(column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get confidence =>
      $composableBuilder(column: $table.confidence, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get needsReview =>
      $composableBuilder(column: $table.needsReview, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fingerprint =>
      $composableBuilder(column: $table.fingerprint, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get transferGroup =>
      $composableBuilder(column: $table.transferGroup, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isPerson =>
      $composableBuilder(column: $table.isPerson, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get anomalyOk =>
      $composableBuilder(column: $table.anomalyOk, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  $$AccountsTableFilterComposer get accountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MerchantsTableFilterComposer get merchantId {
    final $$MerchantsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.merchantId,
      referencedTable: $db.merchants,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$MerchantsTableFilterComposer(
            $db: $db,
            $table: $db.merchants,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StatementsTableFilterComposer get statementId {
    final $$StatementsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.statementId,
      referencedTable: $db.statements,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$StatementsTableFilterComposer(
            $db: $db,
            $table: $db.statements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> splitsRefs(Expression<bool> Function($$SplitsTableFilterComposer f) f) {
    final $$SplitsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.splits,
      getReferencedColumn: (t) => t.transactionId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$SplitsTableFilterComposer(
            $db: $db,
            $table: $db.splits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TransactionsTableOrderingComposer extends Composer<_$ExpenseDatabase, $TransactionsTable> {
  $$TransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get postedDate =>
      $composableBuilder(column: $table.postedDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description =>
      $composableBuilder(column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get bonusRate =>
      $composableBuilder(column: $table.bonusRate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get foreignCents =>
      $composableBuilder(column: $table.foreignCents, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get foreignCurrency =>
      $composableBuilder(column: $table.foreignCurrency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fxRate =>
      $composableBuilder(column: $table.fxRate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get card =>
      $composableBuilder(column: $table.card, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get confidence =>
      $composableBuilder(column: $table.confidence, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get needsReview =>
      $composableBuilder(column: $table.needsReview, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fingerprint =>
      $composableBuilder(column: $table.fingerprint, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get transferGroup =>
      $composableBuilder(column: $table.transferGroup, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isPerson =>
      $composableBuilder(column: $table.isPerson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get anomalyOk =>
      $composableBuilder(column: $table.anomalyOk, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  $$AccountsTableOrderingComposer get accountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$AccountsTableOrderingComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MerchantsTableOrderingComposer get merchantId {
    final $$MerchantsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.merchantId,
      referencedTable: $db.merchants,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$MerchantsTableOrderingComposer(
            $db: $db,
            $table: $db.merchants,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StatementsTableOrderingComposer get statementId {
    final $$StatementsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.statementId,
      referencedTable: $db.statements,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$StatementsTableOrderingComposer(
            $db: $db,
            $table: $db.statements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionsTableAnnotationComposer extends Composer<_$ExpenseDatabase, $TransactionsTable> {
  $$TransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date => $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<DateTime> get postedDate =>
      $composableBuilder(column: $table.postedDate, builder: (column) => column);

  GeneratedColumn<int> get amount => $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get description =>
      $composableBuilder(column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get code => $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get location => $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<int> get bonusRate => $composableBuilder(column: $table.bonusRate, builder: (column) => column);

  GeneratedColumn<int> get foreignCents => $composableBuilder(column: $table.foreignCents, builder: (column) => column);

  GeneratedColumn<String> get foreignCurrency =>
      $composableBuilder(column: $table.foreignCurrency, builder: (column) => column);

  GeneratedColumn<String> get fxRate => $composableBuilder(column: $table.fxRate, builder: (column) => column);

  GeneratedColumn<String> get card => $composableBuilder(column: $table.card, builder: (column) => column);

  GeneratedColumn<String> get kind => $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get confidence => $composableBuilder(column: $table.confidence, builder: (column) => column);

  GeneratedColumn<bool> get needsReview => $composableBuilder(column: $table.needsReview, builder: (column) => column);

  GeneratedColumn<String> get note => $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get source => $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get fingerprint =>
      $composableBuilder(column: $table.fingerprint, builder: (column) => column);

  GeneratedColumn<String> get transferGroup =>
      $composableBuilder(column: $table.transferGroup, builder: (column) => column);

  GeneratedColumn<bool> get isPerson => $composableBuilder(column: $table.isPerson, builder: (column) => column);

  GeneratedColumn<bool> get anomalyOk => $composableBuilder(column: $table.anomalyOk, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$AccountsTableAnnotationComposer get accountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MerchantsTableAnnotationComposer get merchantId {
    final $$MerchantsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.merchantId,
      referencedTable: $db.merchants,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$MerchantsTableAnnotationComposer(
            $db: $db,
            $table: $db.merchants,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StatementsTableAnnotationComposer get statementId {
    final $$StatementsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.statementId,
      referencedTable: $db.statements,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$StatementsTableAnnotationComposer(
            $db: $db,
            $table: $db.statements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> splitsRefs<T extends Object>(Expression<T> Function($$SplitsTableAnnotationComposer a) f) {
    final $$SplitsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.splits,
      getReferencedColumn: (t) => t.transactionId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$SplitsTableAnnotationComposer(
            $db: $db,
            $table: $db.splits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TransactionsTableTableManager
    extends
        RootTableManager<
          _$ExpenseDatabase,
          $TransactionsTable,
          Txn,
          $$TransactionsTableFilterComposer,
          $$TransactionsTableOrderingComposer,
          $$TransactionsTableAnnotationComposer,
          $$TransactionsTableCreateCompanionBuilder,
          $$TransactionsTableUpdateCompanionBuilder,
          (Txn, $$TransactionsTableReferences),
          Txn,
          PrefetchHooks Function({bool accountId, bool merchantId, bool categoryId, bool statementId, bool splitsRefs})
        > {
  $$TransactionsTableTableManager(_$ExpenseDatabase db, $TransactionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$TransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$TransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$TransactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> accountId = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<DateTime?> postedDate = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String?> code = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<int?> bonusRate = const Value.absent(),
                Value<int?> foreignCents = const Value.absent(),
                Value<String?> foreignCurrency = const Value.absent(),
                Value<String?> fxRate = const Value.absent(),
                Value<String?> card = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<int?> merchantId = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String> confidence = const Value.absent(),
                Value<bool> needsReview = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<int?> statementId = const Value.absent(),
                Value<String?> fingerprint = const Value.absent(),
                Value<String?> transferGroup = const Value.absent(),
                Value<bool> isPerson = const Value.absent(),
                Value<bool> anomalyOk = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionsCompanion(
                id: id,
                accountId: accountId,
                date: date,
                postedDate: postedDate,
                amount: amount,
                description: description,
                code: code,
                location: location,
                bonusRate: bonusRate,
                foreignCents: foreignCents,
                foreignCurrency: foreignCurrency,
                fxRate: fxRate,
                card: card,
                kind: kind,
                merchantId: merchantId,
                categoryId: categoryId,
                confidence: confidence,
                needsReview: needsReview,
                note: note,
                source: source,
                statementId: statementId,
                fingerprint: fingerprint,
                transferGroup: transferGroup,
                isPerson: isPerson,
                anomalyOk: anomalyOk,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int accountId,
                required DateTime date,
                Value<DateTime?> postedDate = const Value.absent(),
                required int amount,
                required String description,
                Value<String?> code = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<int?> bonusRate = const Value.absent(),
                Value<int?> foreignCents = const Value.absent(),
                Value<String?> foreignCurrency = const Value.absent(),
                Value<String?> fxRate = const Value.absent(),
                Value<String?> card = const Value.absent(),
                required String kind,
                Value<int?> merchantId = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                required String confidence,
                required bool needsReview,
                Value<String?> note = const Value.absent(),
                required String source,
                Value<int?> statementId = const Value.absent(),
                Value<String?> fingerprint = const Value.absent(),
                Value<String?> transferGroup = const Value.absent(),
                Value<bool> isPerson = const Value.absent(),
                Value<bool> anomalyOk = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => TransactionsCompanion.insert(
                id: id,
                accountId: accountId,
                date: date,
                postedDate: postedDate,
                amount: amount,
                description: description,
                code: code,
                location: location,
                bonusRate: bonusRate,
                foreignCents: foreignCents,
                foreignCurrency: foreignCurrency,
                fxRate: fxRate,
                card: card,
                kind: kind,
                merchantId: merchantId,
                categoryId: categoryId,
                confidence: confidence,
                needsReview: needsReview,
                note: note,
                source: source,
                statementId: statementId,
                fingerprint: fingerprint,
                transferGroup: transferGroup,
                isPerson: isPerson,
                anomalyOk: anomalyOk,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable<$TransactionsTable, Txn>(table), $$TransactionsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback:
              ({accountId = false, merchantId = false, categoryId = false, statementId = false, splitsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [if (splitsRefs) db.splits],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (accountId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.accountId,
                            referencedTable: $$TransactionsTableReferences._accountIdTable(db),
                            referencedColumn: $$TransactionsTableReferences._accountIdTable(db).id,
                          ) as T;
                        }
                        if (merchantId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.merchantId,
                            referencedTable: $$TransactionsTableReferences._merchantIdTable(db),
                            referencedColumn: $$TransactionsTableReferences._merchantIdTable(db).id,
                          ) as T;
                        }
                        if (categoryId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.categoryId,
                            referencedTable: $$TransactionsTableReferences._categoryIdTable(db),
                            referencedColumn: $$TransactionsTableReferences._categoryIdTable(db).id,
                          ) as T;
                        }
                        if (statementId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.statementId,
                            referencedTable: $$TransactionsTableReferences._statementIdTable(db),
                            referencedColumn: $$TransactionsTableReferences._statementIdTable(db).id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (splitsRefs)
                        await $_getPrefetchedDataByColumns<Txn, $TransactionsTable, Split, $SplitsTable>(
                          currentTable: table,
                          referencedTable: $$TransactionsTableReferences._splitsRefsTable(db),
                          managerFromTypedResult: (p0) => $$TransactionsTableReferences(db, table, p0).splitsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'transaction_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$TransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$ExpenseDatabase,
      $TransactionsTable,
      Txn,
      $$TransactionsTableFilterComposer,
      $$TransactionsTableOrderingComposer,
      $$TransactionsTableAnnotationComposer,
      $$TransactionsTableCreateCompanionBuilder,
      $$TransactionsTableUpdateCompanionBuilder,
      (Txn, $$TransactionsTableReferences),
      Txn,
      PrefetchHooks Function({bool accountId, bool merchantId, bool categoryId, bool statementId, bool splitsRefs})
    >;
typedef $$SplitsTableCreateCompanionBuilder = SplitsCompanion Function({
  Value<int> id,
  required String transactionId,
  required String categoryId,
  required int amount,
});
typedef $$SplitsTableUpdateCompanionBuilder = SplitsCompanion Function({
  Value<int> id,
  Value<String> transactionId,
  Value<String> categoryId,
  Value<int> amount,
});

final class $$SplitsTableReferences extends BaseReferences<_$ExpenseDatabase, $SplitsTable, Split> {
  $$SplitsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TransactionsTable _transactionIdTable(_$ExpenseDatabase db) =>
      db.transactions.createAlias('splits__transaction_id__transactions__id');

  $$TransactionsTableProcessedTableManager get transactionId {
    final $_column = $_itemColumn<String>('transaction_id')!;

    final manager = $$TransactionsTableTableManager($_db, $_db.transactions).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_transactionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static $CategoriesTable _categoryIdTable(_$ExpenseDatabase db) =>
      db.categories.createAlias('splits__category_id__categories__id');

  $$CategoriesTableProcessedTableManager get categoryId {
    final $_column = $_itemColumn<String>('category_id')!;

    final manager = $$CategoriesTableTableManager($_db, $_db.categories).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$SplitsTableFilterComposer extends Composer<_$ExpenseDatabase, $SplitsTable> {
  $$SplitsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => ColumnFilters(column));

  $$TransactionsTableFilterComposer get transactionId {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.transactionId,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$TransactionsTableFilterComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SplitsTableOrderingComposer extends Composer<_$ExpenseDatabase, $SplitsTable> {
  $$SplitsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => ColumnOrderings(column));

  $$TransactionsTableOrderingComposer get transactionId {
    final $$TransactionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.transactionId,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$TransactionsTableOrderingComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SplitsTableAnnotationComposer extends Composer<_$ExpenseDatabase, $SplitsTable> {
  $$SplitsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get amount => $composableBuilder(column: $table.amount, builder: (column) => column);

  $$TransactionsTableAnnotationComposer get transactionId {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.transactionId,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$TransactionsTableAnnotationComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SplitsTableTableManager
    extends
        RootTableManager<
          _$ExpenseDatabase,
          $SplitsTable,
          Split,
          $$SplitsTableFilterComposer,
          $$SplitsTableOrderingComposer,
          $$SplitsTableAnnotationComposer,
          $$SplitsTableCreateCompanionBuilder,
          $$SplitsTableUpdateCompanionBuilder,
          (Split, $$SplitsTableReferences),
          Split,
          PrefetchHooks Function({bool transactionId, bool categoryId})
        > {
  $$SplitsTableTableManager(_$ExpenseDatabase db, $SplitsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$SplitsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$SplitsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$SplitsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> transactionId = const Value.absent(),
            Value<String> categoryId = const Value.absent(),
            Value<int> amount = const Value.absent(),
          }) => SplitsCompanion(id: id, transactionId: transactionId, categoryId: categoryId, amount: amount),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String transactionId,
            required String categoryId,
            required int amount,
          }) => SplitsCompanion.insert(id: id, transactionId: transactionId, categoryId: categoryId, amount: amount),
          withReferenceMapper: (p0) =>
              p0.map((e) => (e.readTable<$SplitsTable, Split>(table), $$SplitsTableReferences(db, table, e))).toList(),
          prefetchHooksCallback: ({transactionId = false, categoryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (transactionId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.transactionId,
                        referencedTable: $$SplitsTableReferences._transactionIdTable(db),
                        referencedColumn: $$SplitsTableReferences._transactionIdTable(db).id,
                      ) as T;
                    }
                    if (categoryId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.categoryId,
                        referencedTable: $$SplitsTableReferences._categoryIdTable(db),
                        referencedColumn: $$SplitsTableReferences._categoryIdTable(db).id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SplitsTableProcessedTableManager =
    ProcessedTableManager<
      _$ExpenseDatabase,
      $SplitsTable,
      Split,
      $$SplitsTableFilterComposer,
      $$SplitsTableOrderingComposer,
      $$SplitsTableAnnotationComposer,
      $$SplitsTableCreateCompanionBuilder,
      $$SplitsTableUpdateCompanionBuilder,
      (Split, $$SplitsTableReferences),
      Split,
      PrefetchHooks Function({bool transactionId, bool categoryId})
    >;
typedef $$TargetsTableCreateCompanionBuilder = TargetsCompanion Function({
  Value<int> id,
  required String scope,
  Value<String?> categoryId,
  required String period,
  required int amount,
  required DateTime createdAt,
});
typedef $$TargetsTableUpdateCompanionBuilder = TargetsCompanion Function({
  Value<int> id,
  Value<String> scope,
  Value<String?> categoryId,
  Value<String> period,
  Value<int> amount,
  Value<DateTime> createdAt,
});

final class $$TargetsTableReferences extends BaseReferences<_$ExpenseDatabase, $TargetsTable, TargetRow> {
  $$TargetsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CategoriesTable _categoryIdTable(_$ExpenseDatabase db) =>
      db.categories.createAlias('targets__category_id__categories__id');

  $$CategoriesTableProcessedTableManager? get categoryId {
    final $_column = $_itemColumn<String>('category_id');
    if ($_column == null) return null;
    final manager = $$CategoriesTableTableManager($_db, $_db.categories).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$TargetsTableFilterComposer extends Composer<_$ExpenseDatabase, $TargetsTable> {
  $$TargetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get scope =>
      $composableBuilder(column: $table.scope, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get period =>
      $composableBuilder(column: $table.period, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TargetsTableOrderingComposer extends Composer<_$ExpenseDatabase, $TargetsTable> {
  $$TargetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get scope =>
      $composableBuilder(column: $table.scope, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get period =>
      $composableBuilder(column: $table.period, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TargetsTableAnnotationComposer extends Composer<_$ExpenseDatabase, $TargetsTable> {
  $$TargetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get scope => $composableBuilder(column: $table.scope, builder: (column) => column);

  GeneratedColumn<String> get period => $composableBuilder(column: $table.period, builder: (column) => column);

  GeneratedColumn<int> get amount => $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TargetsTableTableManager
    extends
        RootTableManager<
          _$ExpenseDatabase,
          $TargetsTable,
          TargetRow,
          $$TargetsTableFilterComposer,
          $$TargetsTableOrderingComposer,
          $$TargetsTableAnnotationComposer,
          $$TargetsTableCreateCompanionBuilder,
          $$TargetsTableUpdateCompanionBuilder,
          (TargetRow, $$TargetsTableReferences),
          TargetRow,
          PrefetchHooks Function({bool categoryId})
        > {
  $$TargetsTableTableManager(_$ExpenseDatabase db, $TargetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$TargetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$TargetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$TargetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> scope = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String> period = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => TargetsCompanion(
                id: id,
                scope: scope,
                categoryId: categoryId,
                period: period,
                amount: amount,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String scope,
                Value<String?> categoryId = const Value.absent(),
                required String period,
                required int amount,
                required DateTime createdAt,
              }) => TargetsCompanion.insert(
                id: id,
                scope: scope,
                categoryId: categoryId,
                period: period,
                amount: amount,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable<$TargetsTable, TargetRow>(table), $$TargetsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({categoryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (categoryId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.categoryId,
                        referencedTable: $$TargetsTableReferences._categoryIdTable(db),
                        referencedColumn: $$TargetsTableReferences._categoryIdTable(db).id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TargetsTableProcessedTableManager =
    ProcessedTableManager<
      _$ExpenseDatabase,
      $TargetsTable,
      TargetRow,
      $$TargetsTableFilterComposer,
      $$TargetsTableOrderingComposer,
      $$TargetsTableAnnotationComposer,
      $$TargetsTableCreateCompanionBuilder,
      $$TargetsTableUpdateCompanionBuilder,
      (TargetRow, $$TargetsTableReferences),
      TargetRow,
      PrefetchHooks Function({bool categoryId})
    >;

class $ExpenseDatabaseManager {
  final _$ExpenseDatabase _db;
  $ExpenseDatabaseManager(this._db);
  $$AccountsTableTableManager get accounts => $$AccountsTableTableManager(_db, _db.accounts);
  $$StatementsTableTableManager get statements => $$StatementsTableTableManager(_db, _db.statements);
  $$CategoriesTableTableManager get categories => $$CategoriesTableTableManager(_db, _db.categories);
  $$MerchantsTableTableManager get merchants => $$MerchantsTableTableManager(_db, _db.merchants);
  $$RulesTableTableManager get rules => $$RulesTableTableManager(_db, _db.rules);
  $$TransactionsTableTableManager get transactions => $$TransactionsTableTableManager(_db, _db.transactions);
  $$SplitsTableTableManager get splits => $$SplitsTableTableManager(_db, _db.splits);
  $$TargetsTableTableManager get targets => $$TargetsTableTableManager(_db, _db.targets);
}
