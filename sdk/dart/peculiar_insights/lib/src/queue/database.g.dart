// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class QueueItem extends Table with TableInfo<QueueItem, QueueItemData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  QueueItem(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _purposeMeta = const VerificationMeta(
    'purpose',
  );
  late final GeneratedColumn<String> purpose = GeneratedColumn<String>(
    'purpose',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  late final GeneratedColumn<Uint8List> payload = GeneratedColumn<Uint8List>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _consentMeta = const VerificationMeta(
    'consent',
  );
  late final GeneratedColumn<Uint8List> consent = GeneratedColumn<Uint8List>(
    'consent',
    aliasedName,
    true,
    type: DriftSqlType.blob,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    kind,
    purpose,
    payload,
    createdAt,
    consent,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'queue_item';
  @override
  VerificationContext validateIntegrity(
    Insertable<QueueItemData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('purpose')) {
      context.handle(
        _purposeMeta,
        purpose.isAcceptableOrUnknown(data['purpose']!, _purposeMeta),
      );
    } else if (isInserting) {
      context.missing(_purposeMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('consent')) {
      context.handle(
        _consentMeta,
        consent.isAcceptableOrUnknown(data['consent']!, _consentMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  QueueItemData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QueueItemData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      purpose: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}purpose'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}payload'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      consent: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}consent'],
      ),
    );
  }

  @override
  QueueItem createAlias(String alias) {
    return QueueItem(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class QueueItemData extends DataClass implements Insertable<QueueItemData> {
  final String id;
  final String kind;
  final String purpose;
  final Uint8List payload;
  final int createdAt;
  final Uint8List? consent;
  const QueueItemData({
    required this.id,
    required this.kind,
    required this.purpose,
    required this.payload,
    required this.createdAt,
    this.consent,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['kind'] = Variable<String>(kind);
    map['purpose'] = Variable<String>(purpose);
    map['payload'] = Variable<Uint8List>(payload);
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || consent != null) {
      map['consent'] = Variable<Uint8List>(consent);
    }
    return map;
  }

  QueueItemCompanion toCompanion(bool nullToAbsent) {
    return QueueItemCompanion(
      id: Value(id),
      kind: Value(kind),
      purpose: Value(purpose),
      payload: Value(payload),
      createdAt: Value(createdAt),
      consent: consent == null && nullToAbsent
          ? const Value.absent()
          : Value(consent),
    );
  }

  factory QueueItemData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QueueItemData(
      id: serializer.fromJson<String>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      purpose: serializer.fromJson<String>(json['purpose']),
      payload: serializer.fromJson<Uint8List>(json['payload']),
      createdAt: serializer.fromJson<int>(json['created_at']),
      consent: serializer.fromJson<Uint8List?>(json['consent']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'kind': serializer.toJson<String>(kind),
      'purpose': serializer.toJson<String>(purpose),
      'payload': serializer.toJson<Uint8List>(payload),
      'created_at': serializer.toJson<int>(createdAt),
      'consent': serializer.toJson<Uint8List?>(consent),
    };
  }

  QueueItemData copyWith({
    String? id,
    String? kind,
    String? purpose,
    Uint8List? payload,
    int? createdAt,
    Value<Uint8List?> consent = const Value.absent(),
  }) => QueueItemData(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    purpose: purpose ?? this.purpose,
    payload: payload ?? this.payload,
    createdAt: createdAt ?? this.createdAt,
    consent: consent.present ? consent.value : this.consent,
  );
  QueueItemData copyWithCompanion(QueueItemCompanion data) {
    return QueueItemData(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      purpose: data.purpose.present ? data.purpose.value : this.purpose,
      payload: data.payload.present ? data.payload.value : this.payload,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      consent: data.consent.present ? data.consent.value : this.consent,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QueueItemData(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('purpose: $purpose, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('consent: $consent')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    kind,
    purpose,
    $driftBlobEquality.hash(payload),
    createdAt,
    $driftBlobEquality.hash(consent),
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QueueItemData &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.purpose == this.purpose &&
          $driftBlobEquality.equals(other.payload, this.payload) &&
          other.createdAt == this.createdAt &&
          $driftBlobEquality.equals(other.consent, this.consent));
}

class QueueItemCompanion extends UpdateCompanion<QueueItemData> {
  final Value<String> id;
  final Value<String> kind;
  final Value<String> purpose;
  final Value<Uint8List> payload;
  final Value<int> createdAt;
  final Value<Uint8List?> consent;
  final Value<int> rowid;
  const QueueItemCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.purpose = const Value.absent(),
    this.payload = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.consent = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QueueItemCompanion.insert({
    required String id,
    required String kind,
    required String purpose,
    required Uint8List payload,
    required int createdAt,
    this.consent = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       kind = Value(kind),
       purpose = Value(purpose),
       payload = Value(payload),
       createdAt = Value(createdAt);
  static Insertable<QueueItemData> custom({
    Expression<String>? id,
    Expression<String>? kind,
    Expression<String>? purpose,
    Expression<Uint8List>? payload,
    Expression<int>? createdAt,
    Expression<Uint8List>? consent,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (purpose != null) 'purpose': purpose,
      if (payload != null) 'payload': payload,
      if (createdAt != null) 'created_at': createdAt,
      if (consent != null) 'consent': consent,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QueueItemCompanion copyWith({
    Value<String>? id,
    Value<String>? kind,
    Value<String>? purpose,
    Value<Uint8List>? payload,
    Value<int>? createdAt,
    Value<Uint8List?>? consent,
    Value<int>? rowid,
  }) {
    return QueueItemCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      purpose: purpose ?? this.purpose,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      consent: consent ?? this.consent,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (purpose.present) {
      map['purpose'] = Variable<String>(purpose.value);
    }
    if (payload.present) {
      map['payload'] = Variable<Uint8List>(payload.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (consent.present) {
      map['consent'] = Variable<Uint8List>(consent.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QueueItemCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('purpose: $purpose, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('consent: $consent, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class StateEntry extends Table with TableInfo<StateEntry, StateEntryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  StateEntry(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [name, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'state_entry';
  @override
  VerificationContext validateIntegrity(
    Insertable<StateEntryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {name};
  @override
  StateEntryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StateEntryData(
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  StateEntry createAlias(String alias) {
    return StateEntry(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class StateEntryData extends DataClass implements Insertable<StateEntryData> {
  final String name;
  final String value;
  const StateEntryData({required this.name, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['name'] = Variable<String>(name);
    map['value'] = Variable<String>(value);
    return map;
  }

  StateEntryCompanion toCompanion(bool nullToAbsent) {
    return StateEntryCompanion(name: Value(name), value: Value(value));
  }

  factory StateEntryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StateEntryData(
      name: serializer.fromJson<String>(json['name']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'name': serializer.toJson<String>(name),
      'value': serializer.toJson<String>(value),
    };
  }

  StateEntryData copyWith({String? name, String? value}) =>
      StateEntryData(name: name ?? this.name, value: value ?? this.value);
  StateEntryData copyWithCompanion(StateEntryCompanion data) {
    return StateEntryData(
      name: data.name.present ? data.name.value : this.name,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StateEntryData(')
          ..write('name: $name, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(name, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StateEntryData &&
          other.name == this.name &&
          other.value == this.value);
}

class StateEntryCompanion extends UpdateCompanion<StateEntryData> {
  final Value<String> name;
  final Value<String> value;
  final Value<int> rowid;
  const StateEntryCompanion({
    this.name = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StateEntryCompanion.insert({
    required String name,
    required String value,
    this.rowid = const Value.absent(),
  }) : name = Value(name),
       value = Value(value);
  static Insertable<StateEntryData> custom({
    Expression<String>? name,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (name != null) 'name': name,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StateEntryCompanion copyWith({
    Value<String>? name,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return StateEntryCompanion(
      name: name ?? this.name,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StateEntryCompanion(')
          ..write('name: $name, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$QueueDatabase extends GeneratedDatabase {
  _$QueueDatabase(QueryExecutor e) : super(e);
  $QueueDatabaseManager get managers => $QueueDatabaseManager(this);
  late final QueueItem queueItem = QueueItem(this);
  late final Index queueItemOrder = Index(
    'queue_item_order',
    'CREATE INDEX queue_item_order ON queue_item (created_at)',
  );
  late final StateEntry stateEntry = StateEntry(this);
  Selectable<QueueItemData> peekRows(int limit) {
    return customSelect(
      'SELECT * FROM queue_item ORDER BY created_at, "rowid" LIMIT ?1',
      variables: [Variable<int>(limit)],
      readsFrom: {queueItem},
    ).asyncMap(queueItem.mapFromRow);
  }

  Future<int> removeRows(List<String> var1) {
    var $arrayStartIndex = 1;
    final expandedvar1 = $expandVar($arrayStartIndex, var1.length);
    $arrayStartIndex += var1.length;
    return customUpdate(
      'DELETE FROM queue_item WHERE id IN ($expandedvar1)',
      variables: [for (var $ in var1) Variable<String>($)],
      updates: {queueItem},
      updateKind: UpdateKind.delete,
    );
  }

  Future<int> removePurposeRows(String purpose) {
    return customUpdate(
      'DELETE FROM queue_item WHERE purpose = ?1',
      variables: [Variable<String>(purpose)],
      updates: {queueItem},
      updateKind: UpdateKind.delete,
    );
  }

  Future<int> clearRows() {
    return customUpdate(
      'DELETE FROM queue_item',
      variables: [],
      updates: {queueItem},
      updateKind: UpdateKind.delete,
    );
  }

  Selectable<String> readEntry(String key) {
    return customSelect(
      'SELECT value FROM state_entry WHERE name = ?1',
      variables: [Variable<String>(key)],
      readsFrom: {stateEntry},
    ).map((QueryRow row) => row.read<String>('value'));
  }

  Future<int> writeEntry(String key, String value) {
    return customInsert(
      'INSERT INTO state_entry (name, value) VALUES (?1, ?2) ON CONFLICT (name) DO UPDATE SET value = excluded.value',
      variables: [Variable<String>(key), Variable<String>(value)],
      updates: {stateEntry},
    );
  }

  Future<int> deleteEntry(String key) {
    return customUpdate(
      'DELETE FROM state_entry WHERE name = ?1',
      variables: [Variable<String>(key)],
      updates: {stateEntry},
      updateKind: UpdateKind.delete,
    );
  }

  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    queueItem,
    queueItemOrder,
    stateEntry,
  ];
}

typedef $QueueItemCreateCompanionBuilder =
    QueueItemCompanion Function({
      required String id,
      required String kind,
      required String purpose,
      required Uint8List payload,
      required int createdAt,
      Value<Uint8List?> consent,
      Value<int> rowid,
    });
typedef $QueueItemUpdateCompanionBuilder =
    QueueItemCompanion Function({
      Value<String> id,
      Value<String> kind,
      Value<String> purpose,
      Value<Uint8List> payload,
      Value<int> createdAt,
      Value<Uint8List?> consent,
      Value<int> rowid,
    });

class $QueueItemFilterComposer extends Composer<_$QueueDatabase, QueueItem> {
  $QueueItemFilterComposer({
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

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get purpose => $composableBuilder(
    column: $table.purpose,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get consent => $composableBuilder(
    column: $table.consent,
    builder: (column) => ColumnFilters(column),
  );
}

class $QueueItemOrderingComposer extends Composer<_$QueueDatabase, QueueItem> {
  $QueueItemOrderingComposer({
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

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get purpose => $composableBuilder(
    column: $table.purpose,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get consent => $composableBuilder(
    column: $table.consent,
    builder: (column) => ColumnOrderings(column),
  );
}

class $QueueItemAnnotationComposer
    extends Composer<_$QueueDatabase, QueueItem> {
  $QueueItemAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get purpose =>
      $composableBuilder(column: $table.purpose, builder: (column) => column);

  GeneratedColumn<Uint8List> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<Uint8List> get consent =>
      $composableBuilder(column: $table.consent, builder: (column) => column);
}

class $QueueItemTableManager
    extends
        RootTableManager<
          _$QueueDatabase,
          QueueItem,
          QueueItemData,
          $QueueItemFilterComposer,
          $QueueItemOrderingComposer,
          $QueueItemAnnotationComposer,
          $QueueItemCreateCompanionBuilder,
          $QueueItemUpdateCompanionBuilder,
          (
            QueueItemData,
            BaseReferences<_$QueueDatabase, QueueItem, QueueItemData>,
          ),
          QueueItemData,
          PrefetchHooks Function()
        > {
  $QueueItemTableManager(_$QueueDatabase db, QueueItem table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $QueueItemFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $QueueItemOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $QueueItemAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> purpose = const Value.absent(),
                Value<Uint8List> payload = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<Uint8List?> consent = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QueueItemCompanion(
                id: id,
                kind: kind,
                purpose: purpose,
                payload: payload,
                createdAt: createdAt,
                consent: consent,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String kind,
                required String purpose,
                required Uint8List payload,
                required int createdAt,
                Value<Uint8List?> consent = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QueueItemCompanion.insert(
                id: id,
                kind: kind,
                purpose: purpose,
                payload: payload,
                createdAt: createdAt,
                consent: consent,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $QueueItemProcessedTableManager =
    ProcessedTableManager<
      _$QueueDatabase,
      QueueItem,
      QueueItemData,
      $QueueItemFilterComposer,
      $QueueItemOrderingComposer,
      $QueueItemAnnotationComposer,
      $QueueItemCreateCompanionBuilder,
      $QueueItemUpdateCompanionBuilder,
      (
        QueueItemData,
        BaseReferences<_$QueueDatabase, QueueItem, QueueItemData>,
      ),
      QueueItemData,
      PrefetchHooks Function()
    >;
typedef $StateEntryCreateCompanionBuilder =
    StateEntryCompanion Function({
      required String name,
      required String value,
      Value<int> rowid,
    });
typedef $StateEntryUpdateCompanionBuilder =
    StateEntryCompanion Function({
      Value<String> name,
      Value<String> value,
      Value<int> rowid,
    });

class $StateEntryFilterComposer extends Composer<_$QueueDatabase, StateEntry> {
  $StateEntryFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $StateEntryOrderingComposer
    extends Composer<_$QueueDatabase, StateEntry> {
  $StateEntryOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $StateEntryAnnotationComposer
    extends Composer<_$QueueDatabase, StateEntry> {
  $StateEntryAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $StateEntryTableManager
    extends
        RootTableManager<
          _$QueueDatabase,
          StateEntry,
          StateEntryData,
          $StateEntryFilterComposer,
          $StateEntryOrderingComposer,
          $StateEntryAnnotationComposer,
          $StateEntryCreateCompanionBuilder,
          $StateEntryUpdateCompanionBuilder,
          (
            StateEntryData,
            BaseReferences<_$QueueDatabase, StateEntry, StateEntryData>,
          ),
          StateEntryData,
          PrefetchHooks Function()
        > {
  $StateEntryTableManager(_$QueueDatabase db, StateEntry table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $StateEntryFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $StateEntryOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $StateEntryAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> name = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StateEntryCompanion(name: name, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String name,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => StateEntryCompanion.insert(
                name: name,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $StateEntryProcessedTableManager =
    ProcessedTableManager<
      _$QueueDatabase,
      StateEntry,
      StateEntryData,
      $StateEntryFilterComposer,
      $StateEntryOrderingComposer,
      $StateEntryAnnotationComposer,
      $StateEntryCreateCompanionBuilder,
      $StateEntryUpdateCompanionBuilder,
      (
        StateEntryData,
        BaseReferences<_$QueueDatabase, StateEntry, StateEntryData>,
      ),
      StateEntryData,
      PrefetchHooks Function()
    >;

class $QueueDatabaseManager {
  final _$QueueDatabase _db;
  $QueueDatabaseManager(this._db);
  $QueueItemTableManager get queueItem =>
      $QueueItemTableManager(_db, _db.queueItem);
  $StateEntryTableManager get stateEntry =>
      $StateEntryTableManager(_db, _db.stateEntry);
}
