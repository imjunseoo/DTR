// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $BudgetCyclesTable extends BudgetCycles
    with TableInfo<$BudgetCyclesTable, BudgetCycle> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BudgetCyclesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _configurationMeta = const VerificationMeta(
    'configuration',
  );
  @override
  late final GeneratedColumn<String> configuration = GeneratedColumn<String>(
    'configuration',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, configuration, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'budget_cycles';
  @override
  VerificationContext validateIntegrity(
    Insertable<BudgetCycle> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('configuration')) {
      context.handle(
        _configurationMeta,
        configuration.isAcceptableOrUnknown(
          data['configuration']!,
          _configurationMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_configurationMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BudgetCycle map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BudgetCycle(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      configuration: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}configuration'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $BudgetCyclesTable createAlias(String alias) {
    return $BudgetCyclesTable(attachedDatabase, alias);
  }
}

class BudgetCycle extends DataClass implements Insertable<BudgetCycle> {
  final int id;
  final String configuration;
  final DateTime createdAt;
  const BudgetCycle({
    required this.id,
    required this.configuration,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['configuration'] = Variable<String>(configuration);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  BudgetCyclesCompanion toCompanion(bool nullToAbsent) {
    return BudgetCyclesCompanion(
      id: Value(id),
      configuration: Value(configuration),
      createdAt: Value(createdAt),
    );
  }

  factory BudgetCycle.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BudgetCycle(
      id: serializer.fromJson<int>(json['id']),
      configuration: serializer.fromJson<String>(json['configuration']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'configuration': serializer.toJson<String>(configuration),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  BudgetCycle copyWith({int? id, String? configuration, DateTime? createdAt}) =>
      BudgetCycle(
        id: id ?? this.id,
        configuration: configuration ?? this.configuration,
        createdAt: createdAt ?? this.createdAt,
      );
  BudgetCycle copyWithCompanion(BudgetCyclesCompanion data) {
    return BudgetCycle(
      id: data.id.present ? data.id.value : this.id,
      configuration: data.configuration.present
          ? data.configuration.value
          : this.configuration,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BudgetCycle(')
          ..write('id: $id, ')
          ..write('configuration: $configuration, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, configuration, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BudgetCycle &&
          other.id == this.id &&
          other.configuration == this.configuration &&
          other.createdAt == this.createdAt);
}

class BudgetCyclesCompanion extends UpdateCompanion<BudgetCycle> {
  final Value<int> id;
  final Value<String> configuration;
  final Value<DateTime> createdAt;
  const BudgetCyclesCompanion({
    this.id = const Value.absent(),
    this.configuration = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  BudgetCyclesCompanion.insert({
    this.id = const Value.absent(),
    required String configuration,
    required DateTime createdAt,
  }) : configuration = Value(configuration),
       createdAt = Value(createdAt);
  static Insertable<BudgetCycle> custom({
    Expression<int>? id,
    Expression<String>? configuration,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (configuration != null) 'configuration': configuration,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  BudgetCyclesCompanion copyWith({
    Value<int>? id,
    Value<String>? configuration,
    Value<DateTime>? createdAt,
  }) {
    return BudgetCyclesCompanion(
      id: id ?? this.id,
      configuration: configuration ?? this.configuration,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (configuration.present) {
      map['configuration'] = Variable<String>(configuration.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BudgetCyclesCompanion(')
          ..write('id: $id, ')
          ..write('configuration: $configuration, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $LedgerEntriesTable extends LedgerEntries
    with TableInfo<$LedgerEntriesTable, LedgerEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LedgerEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cycleIdMeta = const VerificationMeta(
    'cycleId',
  );
  @override
  late final GeneratedColumn<int> cycleId = GeneratedColumn<int>(
    'cycle_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES budget_cycles (id)',
    ),
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, cycleId, payload];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ledger_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<LedgerEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('cycle_id')) {
      context.handle(
        _cycleIdMeta,
        cycleId.isAcceptableOrUnknown(data['cycle_id']!, _cycleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cycleIdMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LedgerEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LedgerEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      cycleId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cycle_id'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
    );
  }

  @override
  $LedgerEntriesTable createAlias(String alias) {
    return $LedgerEntriesTable(attachedDatabase, alias);
  }
}

class LedgerEntry extends DataClass implements Insertable<LedgerEntry> {
  final String id;
  final int cycleId;
  final String payload;
  const LedgerEntry({
    required this.id,
    required this.cycleId,
    required this.payload,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['cycle_id'] = Variable<int>(cycleId);
    map['payload'] = Variable<String>(payload);
    return map;
  }

  LedgerEntriesCompanion toCompanion(bool nullToAbsent) {
    return LedgerEntriesCompanion(
      id: Value(id),
      cycleId: Value(cycleId),
      payload: Value(payload),
    );
  }

  factory LedgerEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LedgerEntry(
      id: serializer.fromJson<String>(json['id']),
      cycleId: serializer.fromJson<int>(json['cycleId']),
      payload: serializer.fromJson<String>(json['payload']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'cycleId': serializer.toJson<int>(cycleId),
      'payload': serializer.toJson<String>(payload),
    };
  }

  LedgerEntry copyWith({String? id, int? cycleId, String? payload}) =>
      LedgerEntry(
        id: id ?? this.id,
        cycleId: cycleId ?? this.cycleId,
        payload: payload ?? this.payload,
      );
  LedgerEntry copyWithCompanion(LedgerEntriesCompanion data) {
    return LedgerEntry(
      id: data.id.present ? data.id.value : this.id,
      cycleId: data.cycleId.present ? data.cycleId.value : this.cycleId,
      payload: data.payload.present ? data.payload.value : this.payload,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LedgerEntry(')
          ..write('id: $id, ')
          ..write('cycleId: $cycleId, ')
          ..write('payload: $payload')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, cycleId, payload);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LedgerEntry &&
          other.id == this.id &&
          other.cycleId == this.cycleId &&
          other.payload == this.payload);
}

class LedgerEntriesCompanion extends UpdateCompanion<LedgerEntry> {
  final Value<String> id;
  final Value<int> cycleId;
  final Value<String> payload;
  final Value<int> rowid;
  const LedgerEntriesCompanion({
    this.id = const Value.absent(),
    this.cycleId = const Value.absent(),
    this.payload = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LedgerEntriesCompanion.insert({
    required String id,
    required int cycleId,
    required String payload,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       cycleId = Value(cycleId),
       payload = Value(payload);
  static Insertable<LedgerEntry> custom({
    Expression<String>? id,
    Expression<int>? cycleId,
    Expression<String>? payload,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (cycleId != null) 'cycle_id': cycleId,
      if (payload != null) 'payload': payload,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LedgerEntriesCompanion copyWith({
    Value<String>? id,
    Value<int>? cycleId,
    Value<String>? payload,
    Value<int>? rowid,
  }) {
    return LedgerEntriesCompanion(
      id: id ?? this.id,
      cycleId: cycleId ?? this.cycleId,
      payload: payload ?? this.payload,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (cycleId.present) {
      map['cycle_id'] = Variable<int>(cycleId.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LedgerEntriesCompanion(')
          ..write('id: $id, ')
          ..write('cycleId: $cycleId, ')
          ..write('payload: $payload, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DailySnapshotsTable extends DailySnapshots
    with TableInfo<$DailySnapshotsTable, DailySnapshot> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailySnapshotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _cycleIdMeta = const VerificationMeta(
    'cycleId',
  );
  @override
  late final GeneratedColumn<int> cycleId = GeneratedColumn<int>(
    'cycle_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES budget_cycles (id)',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _allocatedMeta = const VerificationMeta(
    'allocated',
  );
  @override
  late final GeneratedColumn<int> allocated = GeneratedColumn<int>(
    'allocated',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _spentMeta = const VerificationMeta('spent');
  @override
  late final GeneratedColumn<int> spent = GeneratedColumn<int>(
    'spent',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [cycleId, date, allocated, spent];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_snapshots';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailySnapshot> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('cycle_id')) {
      context.handle(
        _cycleIdMeta,
        cycleId.isAcceptableOrUnknown(data['cycle_id']!, _cycleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cycleIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('allocated')) {
      context.handle(
        _allocatedMeta,
        allocated.isAcceptableOrUnknown(data['allocated']!, _allocatedMeta),
      );
    } else if (isInserting) {
      context.missing(_allocatedMeta);
    }
    if (data.containsKey('spent')) {
      context.handle(
        _spentMeta,
        spent.isAcceptableOrUnknown(data['spent']!, _spentMeta),
      );
    } else if (isInserting) {
      context.missing(_spentMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {cycleId, date};
  @override
  DailySnapshot map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailySnapshot(
      cycleId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cycle_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      allocated: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}allocated'],
      )!,
      spent: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}spent'],
      )!,
    );
  }

  @override
  $DailySnapshotsTable createAlias(String alias) {
    return $DailySnapshotsTable(attachedDatabase, alias);
  }
}

class DailySnapshot extends DataClass implements Insertable<DailySnapshot> {
  final int cycleId;
  final String date;
  final int allocated;
  final int spent;
  const DailySnapshot({
    required this.cycleId,
    required this.date,
    required this.allocated,
    required this.spent,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['cycle_id'] = Variable<int>(cycleId);
    map['date'] = Variable<String>(date);
    map['allocated'] = Variable<int>(allocated);
    map['spent'] = Variable<int>(spent);
    return map;
  }

  DailySnapshotsCompanion toCompanion(bool nullToAbsent) {
    return DailySnapshotsCompanion(
      cycleId: Value(cycleId),
      date: Value(date),
      allocated: Value(allocated),
      spent: Value(spent),
    );
  }

  factory DailySnapshot.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailySnapshot(
      cycleId: serializer.fromJson<int>(json['cycleId']),
      date: serializer.fromJson<String>(json['date']),
      allocated: serializer.fromJson<int>(json['allocated']),
      spent: serializer.fromJson<int>(json['spent']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'cycleId': serializer.toJson<int>(cycleId),
      'date': serializer.toJson<String>(date),
      'allocated': serializer.toJson<int>(allocated),
      'spent': serializer.toJson<int>(spent),
    };
  }

  DailySnapshot copyWith({
    int? cycleId,
    String? date,
    int? allocated,
    int? spent,
  }) => DailySnapshot(
    cycleId: cycleId ?? this.cycleId,
    date: date ?? this.date,
    allocated: allocated ?? this.allocated,
    spent: spent ?? this.spent,
  );
  DailySnapshot copyWithCompanion(DailySnapshotsCompanion data) {
    return DailySnapshot(
      cycleId: data.cycleId.present ? data.cycleId.value : this.cycleId,
      date: data.date.present ? data.date.value : this.date,
      allocated: data.allocated.present ? data.allocated.value : this.allocated,
      spent: data.spent.present ? data.spent.value : this.spent,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailySnapshot(')
          ..write('cycleId: $cycleId, ')
          ..write('date: $date, ')
          ..write('allocated: $allocated, ')
          ..write('spent: $spent')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(cycleId, date, allocated, spent);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailySnapshot &&
          other.cycleId == this.cycleId &&
          other.date == this.date &&
          other.allocated == this.allocated &&
          other.spent == this.spent);
}

class DailySnapshotsCompanion extends UpdateCompanion<DailySnapshot> {
  final Value<int> cycleId;
  final Value<String> date;
  final Value<int> allocated;
  final Value<int> spent;
  final Value<int> rowid;
  const DailySnapshotsCompanion({
    this.cycleId = const Value.absent(),
    this.date = const Value.absent(),
    this.allocated = const Value.absent(),
    this.spent = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DailySnapshotsCompanion.insert({
    required int cycleId,
    required String date,
    required int allocated,
    required int spent,
    this.rowid = const Value.absent(),
  }) : cycleId = Value(cycleId),
       date = Value(date),
       allocated = Value(allocated),
       spent = Value(spent);
  static Insertable<DailySnapshot> custom({
    Expression<int>? cycleId,
    Expression<String>? date,
    Expression<int>? allocated,
    Expression<int>? spent,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (cycleId != null) 'cycle_id': cycleId,
      if (date != null) 'date': date,
      if (allocated != null) 'allocated': allocated,
      if (spent != null) 'spent': spent,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DailySnapshotsCompanion copyWith({
    Value<int>? cycleId,
    Value<String>? date,
    Value<int>? allocated,
    Value<int>? spent,
    Value<int>? rowid,
  }) {
    return DailySnapshotsCompanion(
      cycleId: cycleId ?? this.cycleId,
      date: date ?? this.date,
      allocated: allocated ?? this.allocated,
      spent: spent ?? this.spent,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (cycleId.present) {
      map['cycle_id'] = Variable<int>(cycleId.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (allocated.present) {
      map['allocated'] = Variable<int>(allocated.value);
    }
    if (spent.present) {
      map['spent'] = Variable<int>(spent.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailySnapshotsCompanion(')
          ..write('cycleId: $cycleId, ')
          ..write('date: $date, ')
          ..write('allocated: $allocated, ')
          ..write('spent: $spent, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $BudgetCyclesTable budgetCycles = $BudgetCyclesTable(this);
  late final $LedgerEntriesTable ledgerEntries = $LedgerEntriesTable(this);
  late final $DailySnapshotsTable dailySnapshots = $DailySnapshotsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    budgetCycles,
    ledgerEntries,
    dailySnapshots,
  ];
}

typedef $$BudgetCyclesTableCreateCompanionBuilder =
    BudgetCyclesCompanion Function({
      Value<int> id,
      required String configuration,
      required DateTime createdAt,
    });
typedef $$BudgetCyclesTableUpdateCompanionBuilder =
    BudgetCyclesCompanion Function({
      Value<int> id,
      Value<String> configuration,
      Value<DateTime> createdAt,
    });

final class $$BudgetCyclesTableReferences
    extends BaseReferences<_$AppDatabase, $BudgetCyclesTable, BudgetCycle> {
  $$BudgetCyclesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$LedgerEntriesTable, List<LedgerEntry>>
  _ledgerEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.ledgerEntries,
    aliasName: 'budget_cycles__id__ledger_entries__cycle_id',
  );

  $$LedgerEntriesTableProcessedTableManager get ledgerEntriesRefs {
    final manager = $$LedgerEntriesTableTableManager(
      $_db,
      $_db.ledgerEntries,
    ).filter((f) => f.cycleId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_ledgerEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$DailySnapshotsTable, List<DailySnapshot>>
  _dailySnapshotsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.dailySnapshots,
    aliasName: 'budget_cycles__id__daily_snapshots__cycle_id',
  );

  $$DailySnapshotsTableProcessedTableManager get dailySnapshotsRefs {
    final manager = $$DailySnapshotsTableTableManager(
      $_db,
      $_db.dailySnapshots,
    ).filter((f) => f.cycleId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_dailySnapshotsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$BudgetCyclesTableFilterComposer
    extends Composer<_$AppDatabase, $BudgetCyclesTable> {
  $$BudgetCyclesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get configuration => $composableBuilder(
    column: $table.configuration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> ledgerEntriesRefs(
    Expression<bool> Function($$LedgerEntriesTableFilterComposer f) f,
  ) {
    final $$LedgerEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ledgerEntries,
      getReferencedColumn: (t) => t.cycleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgerEntriesTableFilterComposer(
            $db: $db,
            $table: $db.ledgerEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> dailySnapshotsRefs(
    Expression<bool> Function($$DailySnapshotsTableFilterComposer f) f,
  ) {
    final $$DailySnapshotsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.dailySnapshots,
      getReferencedColumn: (t) => t.cycleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DailySnapshotsTableFilterComposer(
            $db: $db,
            $table: $db.dailySnapshots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BudgetCyclesTableOrderingComposer
    extends Composer<_$AppDatabase, $BudgetCyclesTable> {
  $$BudgetCyclesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get configuration => $composableBuilder(
    column: $table.configuration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BudgetCyclesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BudgetCyclesTable> {
  $$BudgetCyclesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get configuration => $composableBuilder(
    column: $table.configuration,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> ledgerEntriesRefs<T extends Object>(
    Expression<T> Function($$LedgerEntriesTableAnnotationComposer a) f,
  ) {
    final $$LedgerEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ledgerEntries,
      getReferencedColumn: (t) => t.cycleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgerEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.ledgerEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> dailySnapshotsRefs<T extends Object>(
    Expression<T> Function($$DailySnapshotsTableAnnotationComposer a) f,
  ) {
    final $$DailySnapshotsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.dailySnapshots,
      getReferencedColumn: (t) => t.cycleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DailySnapshotsTableAnnotationComposer(
            $db: $db,
            $table: $db.dailySnapshots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BudgetCyclesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BudgetCyclesTable,
          BudgetCycle,
          $$BudgetCyclesTableFilterComposer,
          $$BudgetCyclesTableOrderingComposer,
          $$BudgetCyclesTableAnnotationComposer,
          $$BudgetCyclesTableCreateCompanionBuilder,
          $$BudgetCyclesTableUpdateCompanionBuilder,
          (BudgetCycle, $$BudgetCyclesTableReferences),
          BudgetCycle,
          PrefetchHooks Function({
            bool ledgerEntriesRefs,
            bool dailySnapshotsRefs,
          })
        > {
  $$BudgetCyclesTableTableManager(_$AppDatabase db, $BudgetCyclesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BudgetCyclesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BudgetCyclesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BudgetCyclesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> configuration = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => BudgetCyclesCompanion(
                id: id,
                configuration: configuration,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String configuration,
                required DateTime createdAt,
              }) => BudgetCyclesCompanion.insert(
                id: id,
                configuration: configuration,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BudgetCyclesTable, BudgetCycle>(table),
                  $$BudgetCyclesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({ledgerEntriesRefs = false, dailySnapshotsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (ledgerEntriesRefs) db.ledgerEntries,
                    if (dailySnapshotsRefs) db.dailySnapshots,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (ledgerEntriesRefs)
                        await $_getPrefetchedDataByColumns<
                          BudgetCycle,
                          $BudgetCyclesTable,
                          LedgerEntry,
                          $LedgerEntriesTable
                        >(
                          currentTable: table,
                          referencedTable: $$BudgetCyclesTableReferences
                              ._ledgerEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BudgetCyclesTableReferences(
                                db,
                                table,
                                p0,
                              ).ledgerEntriesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'cycle_id',
                          typedResults: items,
                        ),
                      if (dailySnapshotsRefs)
                        await $_getPrefetchedDataByColumns<
                          BudgetCycle,
                          $BudgetCyclesTable,
                          DailySnapshot,
                          $DailySnapshotsTable
                        >(
                          currentTable: table,
                          referencedTable: $$BudgetCyclesTableReferences
                              ._dailySnapshotsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BudgetCyclesTableReferences(
                                db,
                                table,
                                p0,
                              ).dailySnapshotsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'cycle_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$BudgetCyclesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BudgetCyclesTable,
      BudgetCycle,
      $$BudgetCyclesTableFilterComposer,
      $$BudgetCyclesTableOrderingComposer,
      $$BudgetCyclesTableAnnotationComposer,
      $$BudgetCyclesTableCreateCompanionBuilder,
      $$BudgetCyclesTableUpdateCompanionBuilder,
      (BudgetCycle, $$BudgetCyclesTableReferences),
      BudgetCycle,
      PrefetchHooks Function({bool ledgerEntriesRefs, bool dailySnapshotsRefs})
    >;
typedef $$LedgerEntriesTableCreateCompanionBuilder =
    LedgerEntriesCompanion Function({
      required String id,
      required int cycleId,
      required String payload,
      Value<int> rowid,
    });
typedef $$LedgerEntriesTableUpdateCompanionBuilder =
    LedgerEntriesCompanion Function({
      Value<String> id,
      Value<int> cycleId,
      Value<String> payload,
      Value<int> rowid,
    });

final class $$LedgerEntriesTableReferences
    extends BaseReferences<_$AppDatabase, $LedgerEntriesTable, LedgerEntry> {
  $$LedgerEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $BudgetCyclesTable _cycleIdTable(_$AppDatabase db) => db.budgetCycles
      .createAlias('ledger_entries__cycle_id__budget_cycles__id');

  $$BudgetCyclesTableProcessedTableManager get cycleId {
    final $_column = $_itemColumn<int>('cycle_id')!;

    final manager = $$BudgetCyclesTableTableManager(
      $_db,
      $_db.budgetCycles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cycleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LedgerEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $LedgerEntriesTable> {
  $$LedgerEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  $$BudgetCyclesTableFilterComposer get cycleId {
    final $$BudgetCyclesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cycleId,
      referencedTable: $db.budgetCycles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BudgetCyclesTableFilterComposer(
            $db: $db,
            $table: $db.budgetCycles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LedgerEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $LedgerEntriesTable> {
  $$LedgerEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  $$BudgetCyclesTableOrderingComposer get cycleId {
    final $$BudgetCyclesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cycleId,
      referencedTable: $db.budgetCycles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BudgetCyclesTableOrderingComposer(
            $db: $db,
            $table: $db.budgetCycles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LedgerEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LedgerEntriesTable> {
  $$LedgerEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  $$BudgetCyclesTableAnnotationComposer get cycleId {
    final $$BudgetCyclesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cycleId,
      referencedTable: $db.budgetCycles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BudgetCyclesTableAnnotationComposer(
            $db: $db,
            $table: $db.budgetCycles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LedgerEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LedgerEntriesTable,
          LedgerEntry,
          $$LedgerEntriesTableFilterComposer,
          $$LedgerEntriesTableOrderingComposer,
          $$LedgerEntriesTableAnnotationComposer,
          $$LedgerEntriesTableCreateCompanionBuilder,
          $$LedgerEntriesTableUpdateCompanionBuilder,
          (LedgerEntry, $$LedgerEntriesTableReferences),
          LedgerEntry,
          PrefetchHooks Function({bool cycleId})
        > {
  $$LedgerEntriesTableTableManager(_$AppDatabase db, $LedgerEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LedgerEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LedgerEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LedgerEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> cycleId = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LedgerEntriesCompanion(
                id: id,
                cycleId: cycleId,
                payload: payload,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int cycleId,
                required String payload,
                Value<int> rowid = const Value.absent(),
              }) => LedgerEntriesCompanion.insert(
                id: id,
                cycleId: cycleId,
                payload: payload,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LedgerEntriesTable, LedgerEntry>(table),
                  $$LedgerEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({cycleId = false}) {
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
                    if (cycleId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.cycleId,
                        referencedTable: $$LedgerEntriesTableReferences
                            ._cycleIdTable(db),
                        referencedColumn: $$LedgerEntriesTableReferences
                            ._cycleIdTable(db)
                            .id,
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

typedef $$LedgerEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LedgerEntriesTable,
      LedgerEntry,
      $$LedgerEntriesTableFilterComposer,
      $$LedgerEntriesTableOrderingComposer,
      $$LedgerEntriesTableAnnotationComposer,
      $$LedgerEntriesTableCreateCompanionBuilder,
      $$LedgerEntriesTableUpdateCompanionBuilder,
      (LedgerEntry, $$LedgerEntriesTableReferences),
      LedgerEntry,
      PrefetchHooks Function({bool cycleId})
    >;
typedef $$DailySnapshotsTableCreateCompanionBuilder =
    DailySnapshotsCompanion Function({
      required int cycleId,
      required String date,
      required int allocated,
      required int spent,
      Value<int> rowid,
    });
typedef $$DailySnapshotsTableUpdateCompanionBuilder =
    DailySnapshotsCompanion Function({
      Value<int> cycleId,
      Value<String> date,
      Value<int> allocated,
      Value<int> spent,
      Value<int> rowid,
    });

final class $$DailySnapshotsTableReferences
    extends BaseReferences<_$AppDatabase, $DailySnapshotsTable, DailySnapshot> {
  $$DailySnapshotsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $BudgetCyclesTable _cycleIdTable(_$AppDatabase db) => db.budgetCycles
      .createAlias('daily_snapshots__cycle_id__budget_cycles__id');

  $$BudgetCyclesTableProcessedTableManager get cycleId {
    final $_column = $_itemColumn<int>('cycle_id')!;

    final manager = $$BudgetCyclesTableTableManager(
      $_db,
      $_db.budgetCycles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cycleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DailySnapshotsTableFilterComposer
    extends Composer<_$AppDatabase, $DailySnapshotsTable> {
  $$DailySnapshotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get allocated => $composableBuilder(
    column: $table.allocated,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get spent => $composableBuilder(
    column: $table.spent,
    builder: (column) => ColumnFilters(column),
  );

  $$BudgetCyclesTableFilterComposer get cycleId {
    final $$BudgetCyclesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cycleId,
      referencedTable: $db.budgetCycles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BudgetCyclesTableFilterComposer(
            $db: $db,
            $table: $db.budgetCycles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DailySnapshotsTableOrderingComposer
    extends Composer<_$AppDatabase, $DailySnapshotsTable> {
  $$DailySnapshotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get allocated => $composableBuilder(
    column: $table.allocated,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get spent => $composableBuilder(
    column: $table.spent,
    builder: (column) => ColumnOrderings(column),
  );

  $$BudgetCyclesTableOrderingComposer get cycleId {
    final $$BudgetCyclesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cycleId,
      referencedTable: $db.budgetCycles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BudgetCyclesTableOrderingComposer(
            $db: $db,
            $table: $db.budgetCycles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DailySnapshotsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailySnapshotsTable> {
  $$DailySnapshotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get allocated =>
      $composableBuilder(column: $table.allocated, builder: (column) => column);

  GeneratedColumn<int> get spent =>
      $composableBuilder(column: $table.spent, builder: (column) => column);

  $$BudgetCyclesTableAnnotationComposer get cycleId {
    final $$BudgetCyclesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cycleId,
      referencedTable: $db.budgetCycles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BudgetCyclesTableAnnotationComposer(
            $db: $db,
            $table: $db.budgetCycles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DailySnapshotsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DailySnapshotsTable,
          DailySnapshot,
          $$DailySnapshotsTableFilterComposer,
          $$DailySnapshotsTableOrderingComposer,
          $$DailySnapshotsTableAnnotationComposer,
          $$DailySnapshotsTableCreateCompanionBuilder,
          $$DailySnapshotsTableUpdateCompanionBuilder,
          (DailySnapshot, $$DailySnapshotsTableReferences),
          DailySnapshot,
          PrefetchHooks Function({bool cycleId})
        > {
  $$DailySnapshotsTableTableManager(
    _$AppDatabase db,
    $DailySnapshotsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailySnapshotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailySnapshotsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailySnapshotsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> cycleId = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<int> allocated = const Value.absent(),
                Value<int> spent = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailySnapshotsCompanion(
                cycleId: cycleId,
                date: date,
                allocated: allocated,
                spent: spent,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int cycleId,
                required String date,
                required int allocated,
                required int spent,
                Value<int> rowid = const Value.absent(),
              }) => DailySnapshotsCompanion.insert(
                cycleId: cycleId,
                date: date,
                allocated: allocated,
                spent: spent,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DailySnapshotsTable, DailySnapshot>(table),
                  $$DailySnapshotsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({cycleId = false}) {
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
                    if (cycleId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.cycleId,
                        referencedTable: $$DailySnapshotsTableReferences
                            ._cycleIdTable(db),
                        referencedColumn: $$DailySnapshotsTableReferences
                            ._cycleIdTable(db)
                            .id,
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

typedef $$DailySnapshotsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DailySnapshotsTable,
      DailySnapshot,
      $$DailySnapshotsTableFilterComposer,
      $$DailySnapshotsTableOrderingComposer,
      $$DailySnapshotsTableAnnotationComposer,
      $$DailySnapshotsTableCreateCompanionBuilder,
      $$DailySnapshotsTableUpdateCompanionBuilder,
      (DailySnapshot, $$DailySnapshotsTableReferences),
      DailySnapshot,
      PrefetchHooks Function({bool cycleId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$BudgetCyclesTableTableManager get budgetCycles =>
      $$BudgetCyclesTableTableManager(_db, _db.budgetCycles);
  $$LedgerEntriesTableTableManager get ledgerEntries =>
      $$LedgerEntriesTableTableManager(_db, _db.ledgerEntries);
  $$DailySnapshotsTableTableManager get dailySnapshots =>
      $$DailySnapshotsTableTableManager(_db, _db.dailySnapshots);
}
