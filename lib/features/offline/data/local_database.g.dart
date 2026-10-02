// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_database.dart';

// ignore_for_file: type=lint
class $CachedContractsTable extends CachedContracts
    with TableInfo<$CachedContractsTable, CachedContract> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedContractsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<String> startDate = GeneratedColumn<String>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  @override
  late final GeneratedColumn<String> endDate = GeneratedColumn<String>(
    'end_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modeMeta = const VerificationMeta('mode');
  @override
  late final GeneratedColumn<String> mode = GeneratedColumn<String>(
    'mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindRecoveriesUsedMeta =
      const VerificationMeta('kindRecoveriesUsed');
  @override
  late final GeneratedColumn<int> kindRecoveriesUsed = GeneratedColumn<int>(
    'kind_recoveries_used',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    startDate,
    endDate,
    mode,
    status,
    kindRecoveriesUsed,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_contracts';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedContract> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('end_date')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta),
      );
    } else if (isInserting) {
      context.missing(_endDateMeta);
    }
    if (data.containsKey('mode')) {
      context.handle(
        _modeMeta,
        mode.isAcceptableOrUnknown(data['mode']!, _modeMeta),
      );
    } else if (isInserting) {
      context.missing(_modeMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('kind_recoveries_used')) {
      context.handle(
        _kindRecoveriesUsedMeta,
        kindRecoveriesUsed.isAcceptableOrUnknown(
          data['kind_recoveries_used']!,
          _kindRecoveriesUsedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_kindRecoveriesUsedMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedContract map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedContract(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_date'],
      )!,
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_date'],
      )!,
      mode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mode'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      kindRecoveriesUsed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}kind_recoveries_used'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CachedContractsTable createAlias(String alias) {
    return $CachedContractsTable(attachedDatabase, alias);
  }
}

class CachedContract extends DataClass implements Insertable<CachedContract> {
  final String id;
  final String userId;
  final String startDate;
  final String endDate;
  final String mode;
  final String status;
  final int kindRecoveriesUsed;
  final String updatedAt;
  const CachedContract({
    required this.id,
    required this.userId,
    required this.startDate,
    required this.endDate,
    required this.mode,
    required this.status,
    required this.kindRecoveriesUsed,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['start_date'] = Variable<String>(startDate);
    map['end_date'] = Variable<String>(endDate);
    map['mode'] = Variable<String>(mode);
    map['status'] = Variable<String>(status);
    map['kind_recoveries_used'] = Variable<int>(kindRecoveriesUsed);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  CachedContractsCompanion toCompanion(bool nullToAbsent) {
    return CachedContractsCompanion(
      id: Value(id),
      userId: Value(userId),
      startDate: Value(startDate),
      endDate: Value(endDate),
      mode: Value(mode),
      status: Value(status),
      kindRecoveriesUsed: Value(kindRecoveriesUsed),
      updatedAt: Value(updatedAt),
    );
  }

  factory CachedContract.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedContract(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      startDate: serializer.fromJson<String>(json['startDate']),
      endDate: serializer.fromJson<String>(json['endDate']),
      mode: serializer.fromJson<String>(json['mode']),
      status: serializer.fromJson<String>(json['status']),
      kindRecoveriesUsed: serializer.fromJson<int>(json['kindRecoveriesUsed']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'startDate': serializer.toJson<String>(startDate),
      'endDate': serializer.toJson<String>(endDate),
      'mode': serializer.toJson<String>(mode),
      'status': serializer.toJson<String>(status),
      'kindRecoveriesUsed': serializer.toJson<int>(kindRecoveriesUsed),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  CachedContract copyWith({
    String? id,
    String? userId,
    String? startDate,
    String? endDate,
    String? mode,
    String? status,
    int? kindRecoveriesUsed,
    String? updatedAt,
  }) => CachedContract(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    mode: mode ?? this.mode,
    status: status ?? this.status,
    kindRecoveriesUsed: kindRecoveriesUsed ?? this.kindRecoveriesUsed,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CachedContract copyWithCompanion(CachedContractsCompanion data) {
    return CachedContract(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      mode: data.mode.present ? data.mode.value : this.mode,
      status: data.status.present ? data.status.value : this.status,
      kindRecoveriesUsed: data.kindRecoveriesUsed.present
          ? data.kindRecoveriesUsed.value
          : this.kindRecoveriesUsed,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedContract(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('mode: $mode, ')
          ..write('status: $status, ')
          ..write('kindRecoveriesUsed: $kindRecoveriesUsed, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    startDate,
    endDate,
    mode,
    status,
    kindRecoveriesUsed,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedContract &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.mode == this.mode &&
          other.status == this.status &&
          other.kindRecoveriesUsed == this.kindRecoveriesUsed &&
          other.updatedAt == this.updatedAt);
}

class CachedContractsCompanion extends UpdateCompanion<CachedContract> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> startDate;
  final Value<String> endDate;
  final Value<String> mode;
  final Value<String> status;
  final Value<int> kindRecoveriesUsed;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const CachedContractsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.mode = const Value.absent(),
    this.status = const Value.absent(),
    this.kindRecoveriesUsed = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedContractsCompanion.insert({
    required String id,
    required String userId,
    required String startDate,
    required String endDate,
    required String mode,
    required String status,
    required int kindRecoveriesUsed,
    required String updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       startDate = Value(startDate),
       endDate = Value(endDate),
       mode = Value(mode),
       status = Value(status),
       kindRecoveriesUsed = Value(kindRecoveriesUsed),
       updatedAt = Value(updatedAt);
  static Insertable<CachedContract> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? startDate,
    Expression<String>? endDate,
    Expression<String>? mode,
    Expression<String>? status,
    Expression<int>? kindRecoveriesUsed,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (mode != null) 'mode': mode,
      if (status != null) 'status': status,
      if (kindRecoveriesUsed != null)
        'kind_recoveries_used': kindRecoveriesUsed,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedContractsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? startDate,
    Value<String>? endDate,
    Value<String>? mode,
    Value<String>? status,
    Value<int>? kindRecoveriesUsed,
    Value<String>? updatedAt,
    Value<int>? rowid,
  }) {
    return CachedContractsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      mode: mode ?? this.mode,
      status: status ?? this.status,
      kindRecoveriesUsed: kindRecoveriesUsed ?? this.kindRecoveriesUsed,
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
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<String>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<String>(endDate.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(mode.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (kindRecoveriesUsed.present) {
      map['kind_recoveries_used'] = Variable<int>(kindRecoveriesUsed.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedContractsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('mode: $mode, ')
          ..write('status: $status, ')
          ..write('kindRecoveriesUsed: $kindRecoveriesUsed, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedCommitmentsTable extends CachedCommitments
    with TableInfo<$CachedCommitmentsTable, CachedCommitment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedCommitmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contractIdMeta = const VerificationMeta(
    'contractId',
  );
  @override
  late final GeneratedColumn<String> contractId = GeneratedColumn<String>(
    'contract_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetTimeMeta = const VerificationMeta(
    'targetTime',
  );
  @override
  late final GeneratedColumn<String> targetTime = GeneratedColumn<String>(
    'target_time',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _retiredAtMeta = const VerificationMeta(
    'retiredAt',
  );
  @override
  late final GeneratedColumn<String> retiredAt = GeneratedColumn<String>(
    'retired_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    contractId,
    userId,
    title,
    targetTime,
    sortOrder,
    retiredAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_commitments';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedCommitment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('contract_id')) {
      context.handle(
        _contractIdMeta,
        contractId.isAcceptableOrUnknown(data['contract_id']!, _contractIdMeta),
      );
    } else if (isInserting) {
      context.missing(_contractIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('target_time')) {
      context.handle(
        _targetTimeMeta,
        targetTime.isAcceptableOrUnknown(data['target_time']!, _targetTimeMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('retired_at')) {
      context.handle(
        _retiredAtMeta,
        retiredAt.isAcceptableOrUnknown(data['retired_at']!, _retiredAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedCommitment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedCommitment(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      contractId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contract_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      targetTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_time'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      retiredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}retired_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CachedCommitmentsTable createAlias(String alias) {
    return $CachedCommitmentsTable(attachedDatabase, alias);
  }
}

class CachedCommitment extends DataClass
    implements Insertable<CachedCommitment> {
  final String id;
  final String contractId;
  final String userId;
  final String title;
  final String? targetTime;
  final int sortOrder;
  final String? retiredAt;
  final String updatedAt;
  const CachedCommitment({
    required this.id,
    required this.contractId,
    required this.userId,
    required this.title,
    this.targetTime,
    required this.sortOrder,
    this.retiredAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['contract_id'] = Variable<String>(contractId);
    map['user_id'] = Variable<String>(userId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || targetTime != null) {
      map['target_time'] = Variable<String>(targetTime);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    if (!nullToAbsent || retiredAt != null) {
      map['retired_at'] = Variable<String>(retiredAt);
    }
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  CachedCommitmentsCompanion toCompanion(bool nullToAbsent) {
    return CachedCommitmentsCompanion(
      id: Value(id),
      contractId: Value(contractId),
      userId: Value(userId),
      title: Value(title),
      targetTime: targetTime == null && nullToAbsent
          ? const Value.absent()
          : Value(targetTime),
      sortOrder: Value(sortOrder),
      retiredAt: retiredAt == null && nullToAbsent
          ? const Value.absent()
          : Value(retiredAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CachedCommitment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedCommitment(
      id: serializer.fromJson<String>(json['id']),
      contractId: serializer.fromJson<String>(json['contractId']),
      userId: serializer.fromJson<String>(json['userId']),
      title: serializer.fromJson<String>(json['title']),
      targetTime: serializer.fromJson<String?>(json['targetTime']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      retiredAt: serializer.fromJson<String?>(json['retiredAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'contractId': serializer.toJson<String>(contractId),
      'userId': serializer.toJson<String>(userId),
      'title': serializer.toJson<String>(title),
      'targetTime': serializer.toJson<String?>(targetTime),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'retiredAt': serializer.toJson<String?>(retiredAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  CachedCommitment copyWith({
    String? id,
    String? contractId,
    String? userId,
    String? title,
    Value<String?> targetTime = const Value.absent(),
    int? sortOrder,
    Value<String?> retiredAt = const Value.absent(),
    String? updatedAt,
  }) => CachedCommitment(
    id: id ?? this.id,
    contractId: contractId ?? this.contractId,
    userId: userId ?? this.userId,
    title: title ?? this.title,
    targetTime: targetTime.present ? targetTime.value : this.targetTime,
    sortOrder: sortOrder ?? this.sortOrder,
    retiredAt: retiredAt.present ? retiredAt.value : this.retiredAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CachedCommitment copyWithCompanion(CachedCommitmentsCompanion data) {
    return CachedCommitment(
      id: data.id.present ? data.id.value : this.id,
      contractId: data.contractId.present
          ? data.contractId.value
          : this.contractId,
      userId: data.userId.present ? data.userId.value : this.userId,
      title: data.title.present ? data.title.value : this.title,
      targetTime: data.targetTime.present
          ? data.targetTime.value
          : this.targetTime,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      retiredAt: data.retiredAt.present ? data.retiredAt.value : this.retiredAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedCommitment(')
          ..write('id: $id, ')
          ..write('contractId: $contractId, ')
          ..write('userId: $userId, ')
          ..write('title: $title, ')
          ..write('targetTime: $targetTime, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('retiredAt: $retiredAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    contractId,
    userId,
    title,
    targetTime,
    sortOrder,
    retiredAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedCommitment &&
          other.id == this.id &&
          other.contractId == this.contractId &&
          other.userId == this.userId &&
          other.title == this.title &&
          other.targetTime == this.targetTime &&
          other.sortOrder == this.sortOrder &&
          other.retiredAt == this.retiredAt &&
          other.updatedAt == this.updatedAt);
}

class CachedCommitmentsCompanion extends UpdateCompanion<CachedCommitment> {
  final Value<String> id;
  final Value<String> contractId;
  final Value<String> userId;
  final Value<String> title;
  final Value<String?> targetTime;
  final Value<int> sortOrder;
  final Value<String?> retiredAt;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const CachedCommitmentsCompanion({
    this.id = const Value.absent(),
    this.contractId = const Value.absent(),
    this.userId = const Value.absent(),
    this.title = const Value.absent(),
    this.targetTime = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.retiredAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedCommitmentsCompanion.insert({
    required String id,
    required String contractId,
    required String userId,
    required String title,
    this.targetTime = const Value.absent(),
    required int sortOrder,
    this.retiredAt = const Value.absent(),
    required String updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       contractId = Value(contractId),
       userId = Value(userId),
       title = Value(title),
       sortOrder = Value(sortOrder),
       updatedAt = Value(updatedAt);
  static Insertable<CachedCommitment> custom({
    Expression<String>? id,
    Expression<String>? contractId,
    Expression<String>? userId,
    Expression<String>? title,
    Expression<String>? targetTime,
    Expression<int>? sortOrder,
    Expression<String>? retiredAt,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (contractId != null) 'contract_id': contractId,
      if (userId != null) 'user_id': userId,
      if (title != null) 'title': title,
      if (targetTime != null) 'target_time': targetTime,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (retiredAt != null) 'retired_at': retiredAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedCommitmentsCompanion copyWith({
    Value<String>? id,
    Value<String>? contractId,
    Value<String>? userId,
    Value<String>? title,
    Value<String?>? targetTime,
    Value<int>? sortOrder,
    Value<String?>? retiredAt,
    Value<String>? updatedAt,
    Value<int>? rowid,
  }) {
    return CachedCommitmentsCompanion(
      id: id ?? this.id,
      contractId: contractId ?? this.contractId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      targetTime: targetTime ?? this.targetTime,
      sortOrder: sortOrder ?? this.sortOrder,
      retiredAt: retiredAt ?? this.retiredAt,
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
    if (contractId.present) {
      map['contract_id'] = Variable<String>(contractId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (targetTime.present) {
      map['target_time'] = Variable<String>(targetTime.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (retiredAt.present) {
      map['retired_at'] = Variable<String>(retiredAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedCommitmentsCompanion(')
          ..write('id: $id, ')
          ..write('contractId: $contractId, ')
          ..write('userId: $userId, ')
          ..write('title: $title, ')
          ..write('targetTime: $targetTime, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('retiredAt: $retiredAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedLedgerEntriesTable extends CachedLedgerEntries
    with TableInfo<$CachedLedgerEntriesTable, CachedLedgerEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedLedgerEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contractIdMeta = const VerificationMeta(
    'contractId',
  );
  @override
  late final GeneratedColumn<String> contractId = GeneratedColumn<String>(
    'contract_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _commitmentIdMeta = const VerificationMeta(
    'commitmentId',
  );
  @override
  late final GeneratedColumn<String> commitmentId = GeneratedColumn<String>(
    'commitment_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<String> day = GeneratedColumn<String>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _doneMeta = const VerificationMeta('done');
  @override
  late final GeneratedColumn<bool> done = GeneratedColumn<bool>(
    'done',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("done" IN (0, 1))',
    ),
  );
  static const VerificationMeta _isPausedMeta = const VerificationMeta(
    'isPaused',
  );
  @override
  late final GeneratedColumn<bool> isPaused = GeneratedColumn<bool>(
    'is_paused',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_paused" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    key,
    userId,
    contractId,
    commitmentId,
    title,
    day,
    status,
    done,
    isPaused,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_ledger_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedLedgerEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('contract_id')) {
      context.handle(
        _contractIdMeta,
        contractId.isAcceptableOrUnknown(data['contract_id']!, _contractIdMeta),
      );
    } else if (isInserting) {
      context.missing(_contractIdMeta);
    }
    if (data.containsKey('commitment_id')) {
      context.handle(
        _commitmentIdMeta,
        commitmentId.isAcceptableOrUnknown(
          data['commitment_id']!,
          _commitmentIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_commitmentIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('done')) {
      context.handle(
        _doneMeta,
        done.isAcceptableOrUnknown(data['done']!, _doneMeta),
      );
    }
    if (data.containsKey('is_paused')) {
      context.handle(
        _isPausedMeta,
        isPaused.isAcceptableOrUnknown(data['is_paused']!, _isPausedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  CachedLedgerEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedLedgerEntry(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      contractId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contract_id'],
      )!,
      commitmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}commitment_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      done: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}done'],
      ),
      isPaused: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_paused'],
      )!,
    );
  }

  @override
  $CachedLedgerEntriesTable createAlias(String alias) {
    return $CachedLedgerEntriesTable(attachedDatabase, alias);
  }
}

class CachedLedgerEntry extends DataClass
    implements Insertable<CachedLedgerEntry> {
  final String key;
  final String userId;
  final String contractId;
  final String commitmentId;
  final String title;
  final String day;
  final String status;
  final bool? done;
  final bool isPaused;
  const CachedLedgerEntry({
    required this.key,
    required this.userId,
    required this.contractId,
    required this.commitmentId,
    required this.title,
    required this.day,
    required this.status,
    this.done,
    required this.isPaused,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['user_id'] = Variable<String>(userId);
    map['contract_id'] = Variable<String>(contractId);
    map['commitment_id'] = Variable<String>(commitmentId);
    map['title'] = Variable<String>(title);
    map['day'] = Variable<String>(day);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || done != null) {
      map['done'] = Variable<bool>(done);
    }
    map['is_paused'] = Variable<bool>(isPaused);
    return map;
  }

  CachedLedgerEntriesCompanion toCompanion(bool nullToAbsent) {
    return CachedLedgerEntriesCompanion(
      key: Value(key),
      userId: Value(userId),
      contractId: Value(contractId),
      commitmentId: Value(commitmentId),
      title: Value(title),
      day: Value(day),
      status: Value(status),
      done: done == null && nullToAbsent ? const Value.absent() : Value(done),
      isPaused: Value(isPaused),
    );
  }

  factory CachedLedgerEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedLedgerEntry(
      key: serializer.fromJson<String>(json['key']),
      userId: serializer.fromJson<String>(json['userId']),
      contractId: serializer.fromJson<String>(json['contractId']),
      commitmentId: serializer.fromJson<String>(json['commitmentId']),
      title: serializer.fromJson<String>(json['title']),
      day: serializer.fromJson<String>(json['day']),
      status: serializer.fromJson<String>(json['status']),
      done: serializer.fromJson<bool?>(json['done']),
      isPaused: serializer.fromJson<bool>(json['isPaused']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'userId': serializer.toJson<String>(userId),
      'contractId': serializer.toJson<String>(contractId),
      'commitmentId': serializer.toJson<String>(commitmentId),
      'title': serializer.toJson<String>(title),
      'day': serializer.toJson<String>(day),
      'status': serializer.toJson<String>(status),
      'done': serializer.toJson<bool?>(done),
      'isPaused': serializer.toJson<bool>(isPaused),
    };
  }

  CachedLedgerEntry copyWith({
    String? key,
    String? userId,
    String? contractId,
    String? commitmentId,
    String? title,
    String? day,
    String? status,
    Value<bool?> done = const Value.absent(),
    bool? isPaused,
  }) => CachedLedgerEntry(
    key: key ?? this.key,
    userId: userId ?? this.userId,
    contractId: contractId ?? this.contractId,
    commitmentId: commitmentId ?? this.commitmentId,
    title: title ?? this.title,
    day: day ?? this.day,
    status: status ?? this.status,
    done: done.present ? done.value : this.done,
    isPaused: isPaused ?? this.isPaused,
  );
  CachedLedgerEntry copyWithCompanion(CachedLedgerEntriesCompanion data) {
    return CachedLedgerEntry(
      key: data.key.present ? data.key.value : this.key,
      userId: data.userId.present ? data.userId.value : this.userId,
      contractId: data.contractId.present
          ? data.contractId.value
          : this.contractId,
      commitmentId: data.commitmentId.present
          ? data.commitmentId.value
          : this.commitmentId,
      title: data.title.present ? data.title.value : this.title,
      day: data.day.present ? data.day.value : this.day,
      status: data.status.present ? data.status.value : this.status,
      done: data.done.present ? data.done.value : this.done,
      isPaused: data.isPaused.present ? data.isPaused.value : this.isPaused,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedLedgerEntry(')
          ..write('key: $key, ')
          ..write('userId: $userId, ')
          ..write('contractId: $contractId, ')
          ..write('commitmentId: $commitmentId, ')
          ..write('title: $title, ')
          ..write('day: $day, ')
          ..write('status: $status, ')
          ..write('done: $done, ')
          ..write('isPaused: $isPaused')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    key,
    userId,
    contractId,
    commitmentId,
    title,
    day,
    status,
    done,
    isPaused,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedLedgerEntry &&
          other.key == this.key &&
          other.userId == this.userId &&
          other.contractId == this.contractId &&
          other.commitmentId == this.commitmentId &&
          other.title == this.title &&
          other.day == this.day &&
          other.status == this.status &&
          other.done == this.done &&
          other.isPaused == this.isPaused);
}

class CachedLedgerEntriesCompanion extends UpdateCompanion<CachedLedgerEntry> {
  final Value<String> key;
  final Value<String> userId;
  final Value<String> contractId;
  final Value<String> commitmentId;
  final Value<String> title;
  final Value<String> day;
  final Value<String> status;
  final Value<bool?> done;
  final Value<bool> isPaused;
  final Value<int> rowid;
  const CachedLedgerEntriesCompanion({
    this.key = const Value.absent(),
    this.userId = const Value.absent(),
    this.contractId = const Value.absent(),
    this.commitmentId = const Value.absent(),
    this.title = const Value.absent(),
    this.day = const Value.absent(),
    this.status = const Value.absent(),
    this.done = const Value.absent(),
    this.isPaused = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedLedgerEntriesCompanion.insert({
    required String key,
    required String userId,
    required String contractId,
    required String commitmentId,
    required String title,
    required String day,
    required String status,
    this.done = const Value.absent(),
    this.isPaused = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       userId = Value(userId),
       contractId = Value(contractId),
       commitmentId = Value(commitmentId),
       title = Value(title),
       day = Value(day),
       status = Value(status);
  static Insertable<CachedLedgerEntry> custom({
    Expression<String>? key,
    Expression<String>? userId,
    Expression<String>? contractId,
    Expression<String>? commitmentId,
    Expression<String>? title,
    Expression<String>? day,
    Expression<String>? status,
    Expression<bool>? done,
    Expression<bool>? isPaused,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (userId != null) 'user_id': userId,
      if (contractId != null) 'contract_id': contractId,
      if (commitmentId != null) 'commitment_id': commitmentId,
      if (title != null) 'title': title,
      if (day != null) 'day': day,
      if (status != null) 'status': status,
      if (done != null) 'done': done,
      if (isPaused != null) 'is_paused': isPaused,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedLedgerEntriesCompanion copyWith({
    Value<String>? key,
    Value<String>? userId,
    Value<String>? contractId,
    Value<String>? commitmentId,
    Value<String>? title,
    Value<String>? day,
    Value<String>? status,
    Value<bool?>? done,
    Value<bool>? isPaused,
    Value<int>? rowid,
  }) {
    return CachedLedgerEntriesCompanion(
      key: key ?? this.key,
      userId: userId ?? this.userId,
      contractId: contractId ?? this.contractId,
      commitmentId: commitmentId ?? this.commitmentId,
      title: title ?? this.title,
      day: day ?? this.day,
      status: status ?? this.status,
      done: done ?? this.done,
      isPaused: isPaused ?? this.isPaused,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (contractId.present) {
      map['contract_id'] = Variable<String>(contractId.value);
    }
    if (commitmentId.present) {
      map['commitment_id'] = Variable<String>(commitmentId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (day.present) {
      map['day'] = Variable<String>(day.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (done.present) {
      map['done'] = Variable<bool>(done.value);
    }
    if (isPaused.present) {
      map['is_paused'] = Variable<bool>(isPaused.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedLedgerEntriesCompanion(')
          ..write('key: $key, ')
          ..write('userId: $userId, ')
          ..write('contractId: $contractId, ')
          ..write('commitmentId: $commitmentId, ')
          ..write('title: $title, ')
          ..write('day: $day, ')
          ..write('status: $status, ')
          ..write('done: $done, ')
          ..write('isPaused: $isPaused, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedStreaksTable extends CachedStreaks
    with TableInfo<$CachedStreaksTable, CachedStreak> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedStreaksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _contractIdMeta = const VerificationMeta(
    'contractId',
  );
  @override
  late final GeneratedColumn<String> contractId = GeneratedColumn<String>(
    'contract_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currentStreakMeta = const VerificationMeta(
    'currentStreak',
  );
  @override
  late final GeneratedColumn<int> currentStreak = GeneratedColumn<int>(
    'current_streak',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recoveriesUsedMeta = const VerificationMeta(
    'recoveriesUsed',
  );
  @override
  late final GeneratedColumn<int> recoveriesUsed = GeneratedColumn<int>(
    'recoveries_used',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modeMeta = const VerificationMeta('mode');
  @override
  late final GeneratedColumn<String> mode = GeneratedColumn<String>(
    'mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _todayMeta = const VerificationMeta('today');
  @override
  late final GeneratedColumn<String> today = GeneratedColumn<String>(
    'today',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _asOfMeta = const VerificationMeta('asOf');
  @override
  late final GeneratedColumn<String> asOf = GeneratedColumn<String>(
    'as_of',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    contractId,
    userId,
    currentStreak,
    recoveriesUsed,
    mode,
    today,
    asOf,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_streaks';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedStreak> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('contract_id')) {
      context.handle(
        _contractIdMeta,
        contractId.isAcceptableOrUnknown(data['contract_id']!, _contractIdMeta),
      );
    } else if (isInserting) {
      context.missing(_contractIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('current_streak')) {
      context.handle(
        _currentStreakMeta,
        currentStreak.isAcceptableOrUnknown(
          data['current_streak']!,
          _currentStreakMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currentStreakMeta);
    }
    if (data.containsKey('recoveries_used')) {
      context.handle(
        _recoveriesUsedMeta,
        recoveriesUsed.isAcceptableOrUnknown(
          data['recoveries_used']!,
          _recoveriesUsedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_recoveriesUsedMeta);
    }
    if (data.containsKey('mode')) {
      context.handle(
        _modeMeta,
        mode.isAcceptableOrUnknown(data['mode']!, _modeMeta),
      );
    } else if (isInserting) {
      context.missing(_modeMeta);
    }
    if (data.containsKey('today')) {
      context.handle(
        _todayMeta,
        today.isAcceptableOrUnknown(data['today']!, _todayMeta),
      );
    } else if (isInserting) {
      context.missing(_todayMeta);
    }
    if (data.containsKey('as_of')) {
      context.handle(
        _asOfMeta,
        asOf.isAcceptableOrUnknown(data['as_of']!, _asOfMeta),
      );
    } else if (isInserting) {
      context.missing(_asOfMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {contractId, userId};
  @override
  CachedStreak map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedStreak(
      contractId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contract_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      currentStreak: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_streak'],
      )!,
      recoveriesUsed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recoveries_used'],
      )!,
      mode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mode'],
      )!,
      today: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}today'],
      )!,
      asOf: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}as_of'],
      )!,
    );
  }

  @override
  $CachedStreaksTable createAlias(String alias) {
    return $CachedStreaksTable(attachedDatabase, alias);
  }
}

class CachedStreak extends DataClass implements Insertable<CachedStreak> {
  final String contractId;
  final String userId;
  final int currentStreak;
  final int recoveriesUsed;
  final String mode;
  final String today;
  final String asOf;
  const CachedStreak({
    required this.contractId,
    required this.userId,
    required this.currentStreak,
    required this.recoveriesUsed,
    required this.mode,
    required this.today,
    required this.asOf,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['contract_id'] = Variable<String>(contractId);
    map['user_id'] = Variable<String>(userId);
    map['current_streak'] = Variable<int>(currentStreak);
    map['recoveries_used'] = Variable<int>(recoveriesUsed);
    map['mode'] = Variable<String>(mode);
    map['today'] = Variable<String>(today);
    map['as_of'] = Variable<String>(asOf);
    return map;
  }

  CachedStreaksCompanion toCompanion(bool nullToAbsent) {
    return CachedStreaksCompanion(
      contractId: Value(contractId),
      userId: Value(userId),
      currentStreak: Value(currentStreak),
      recoveriesUsed: Value(recoveriesUsed),
      mode: Value(mode),
      today: Value(today),
      asOf: Value(asOf),
    );
  }

  factory CachedStreak.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedStreak(
      contractId: serializer.fromJson<String>(json['contractId']),
      userId: serializer.fromJson<String>(json['userId']),
      currentStreak: serializer.fromJson<int>(json['currentStreak']),
      recoveriesUsed: serializer.fromJson<int>(json['recoveriesUsed']),
      mode: serializer.fromJson<String>(json['mode']),
      today: serializer.fromJson<String>(json['today']),
      asOf: serializer.fromJson<String>(json['asOf']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'contractId': serializer.toJson<String>(contractId),
      'userId': serializer.toJson<String>(userId),
      'currentStreak': serializer.toJson<int>(currentStreak),
      'recoveriesUsed': serializer.toJson<int>(recoveriesUsed),
      'mode': serializer.toJson<String>(mode),
      'today': serializer.toJson<String>(today),
      'asOf': serializer.toJson<String>(asOf),
    };
  }

  CachedStreak copyWith({
    String? contractId,
    String? userId,
    int? currentStreak,
    int? recoveriesUsed,
    String? mode,
    String? today,
    String? asOf,
  }) => CachedStreak(
    contractId: contractId ?? this.contractId,
    userId: userId ?? this.userId,
    currentStreak: currentStreak ?? this.currentStreak,
    recoveriesUsed: recoveriesUsed ?? this.recoveriesUsed,
    mode: mode ?? this.mode,
    today: today ?? this.today,
    asOf: asOf ?? this.asOf,
  );
  CachedStreak copyWithCompanion(CachedStreaksCompanion data) {
    return CachedStreak(
      contractId: data.contractId.present
          ? data.contractId.value
          : this.contractId,
      userId: data.userId.present ? data.userId.value : this.userId,
      currentStreak: data.currentStreak.present
          ? data.currentStreak.value
          : this.currentStreak,
      recoveriesUsed: data.recoveriesUsed.present
          ? data.recoveriesUsed.value
          : this.recoveriesUsed,
      mode: data.mode.present ? data.mode.value : this.mode,
      today: data.today.present ? data.today.value : this.today,
      asOf: data.asOf.present ? data.asOf.value : this.asOf,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedStreak(')
          ..write('contractId: $contractId, ')
          ..write('userId: $userId, ')
          ..write('currentStreak: $currentStreak, ')
          ..write('recoveriesUsed: $recoveriesUsed, ')
          ..write('mode: $mode, ')
          ..write('today: $today, ')
          ..write('asOf: $asOf')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    contractId,
    userId,
    currentStreak,
    recoveriesUsed,
    mode,
    today,
    asOf,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedStreak &&
          other.contractId == this.contractId &&
          other.userId == this.userId &&
          other.currentStreak == this.currentStreak &&
          other.recoveriesUsed == this.recoveriesUsed &&
          other.mode == this.mode &&
          other.today == this.today &&
          other.asOf == this.asOf);
}

class CachedStreaksCompanion extends UpdateCompanion<CachedStreak> {
  final Value<String> contractId;
  final Value<String> userId;
  final Value<int> currentStreak;
  final Value<int> recoveriesUsed;
  final Value<String> mode;
  final Value<String> today;
  final Value<String> asOf;
  final Value<int> rowid;
  const CachedStreaksCompanion({
    this.contractId = const Value.absent(),
    this.userId = const Value.absent(),
    this.currentStreak = const Value.absent(),
    this.recoveriesUsed = const Value.absent(),
    this.mode = const Value.absent(),
    this.today = const Value.absent(),
    this.asOf = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedStreaksCompanion.insert({
    required String contractId,
    required String userId,
    required int currentStreak,
    required int recoveriesUsed,
    required String mode,
    required String today,
    required String asOf,
    this.rowid = const Value.absent(),
  }) : contractId = Value(contractId),
       userId = Value(userId),
       currentStreak = Value(currentStreak),
       recoveriesUsed = Value(recoveriesUsed),
       mode = Value(mode),
       today = Value(today),
       asOf = Value(asOf);
  static Insertable<CachedStreak> custom({
    Expression<String>? contractId,
    Expression<String>? userId,
    Expression<int>? currentStreak,
    Expression<int>? recoveriesUsed,
    Expression<String>? mode,
    Expression<String>? today,
    Expression<String>? asOf,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (contractId != null) 'contract_id': contractId,
      if (userId != null) 'user_id': userId,
      if (currentStreak != null) 'current_streak': currentStreak,
      if (recoveriesUsed != null) 'recoveries_used': recoveriesUsed,
      if (mode != null) 'mode': mode,
      if (today != null) 'today': today,
      if (asOf != null) 'as_of': asOf,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedStreaksCompanion copyWith({
    Value<String>? contractId,
    Value<String>? userId,
    Value<int>? currentStreak,
    Value<int>? recoveriesUsed,
    Value<String>? mode,
    Value<String>? today,
    Value<String>? asOf,
    Value<int>? rowid,
  }) {
    return CachedStreaksCompanion(
      contractId: contractId ?? this.contractId,
      userId: userId ?? this.userId,
      currentStreak: currentStreak ?? this.currentStreak,
      recoveriesUsed: recoveriesUsed ?? this.recoveriesUsed,
      mode: mode ?? this.mode,
      today: today ?? this.today,
      asOf: asOf ?? this.asOf,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (contractId.present) {
      map['contract_id'] = Variable<String>(contractId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (currentStreak.present) {
      map['current_streak'] = Variable<int>(currentStreak.value);
    }
    if (recoveriesUsed.present) {
      map['recoveries_used'] = Variable<int>(recoveriesUsed.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(mode.value);
    }
    if (today.present) {
      map['today'] = Variable<String>(today.value);
    }
    if (asOf.present) {
      map['as_of'] = Variable<String>(asOf.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedStreaksCompanion(')
          ..write('contractId: $contractId, ')
          ..write('userId: $userId, ')
          ..write('currentStreak: $currentStreak, ')
          ..write('recoveriesUsed: $recoveriesUsed, ')
          ..write('mode: $mode, ')
          ..write('today: $today, ')
          ..write('asOf: $asOf, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OutboxCheckinsTable extends OutboxCheckins
    with TableInfo<$OutboxCheckinsTable, OutboxCheckin> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxCheckinsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta = const VerificationMeta(
    'localId',
  );
  @override
  late final GeneratedColumn<int> localId = GeneratedColumn<int>(
    'local_id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contractIdMeta = const VerificationMeta(
    'contractId',
  );
  @override
  late final GeneratedColumn<String> contractId = GeneratedColumn<String>(
    'contract_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _commitmentIdMeta = const VerificationMeta(
    'commitmentId',
  );
  @override
  late final GeneratedColumn<String> commitmentId = GeneratedColumn<String>(
    'commitment_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _commitmentTitleMeta = const VerificationMeta(
    'commitmentTitle',
  );
  @override
  late final GeneratedColumn<String> commitmentTitle = GeneratedColumn<String>(
    'commitment_title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<String> day = GeneratedColumn<String>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _errorMessageMeta = const VerificationMeta(
    'errorMessage',
  );
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
    'error_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    localId,
    userId,
    contractId,
    commitmentId,
    commitmentTitle,
    day,
    createdAt,
    status,
    errorMessage,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox_checkins';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutboxCheckin> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(
        _localIdMeta,
        localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta),
      );
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('contract_id')) {
      context.handle(
        _contractIdMeta,
        contractId.isAcceptableOrUnknown(data['contract_id']!, _contractIdMeta),
      );
    } else if (isInserting) {
      context.missing(_contractIdMeta);
    }
    if (data.containsKey('commitment_id')) {
      context.handle(
        _commitmentIdMeta,
        commitmentId.isAcceptableOrUnknown(
          data['commitment_id']!,
          _commitmentIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_commitmentIdMeta);
    }
    if (data.containsKey('commitment_title')) {
      context.handle(
        _commitmentTitleMeta,
        commitmentTitle.isAcceptableOrUnknown(
          data['commitment_title']!,
          _commitmentTitleMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_commitmentTitleMeta);
    }
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('error_message')) {
      context.handle(
        _errorMessageMeta,
        errorMessage.isAcceptableOrUnknown(
          data['error_message']!,
          _errorMessageMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  OutboxCheckin map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxCheckin(
      localId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}local_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      contractId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contract_id'],
      )!,
      commitmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}commitment_id'],
      )!,
      commitmentTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}commitment_title'],
      )!,
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      errorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_message'],
      ),
    );
  }

  @override
  $OutboxCheckinsTable createAlias(String alias) {
    return $OutboxCheckinsTable(attachedDatabase, alias);
  }
}

class OutboxCheckin extends DataClass implements Insertable<OutboxCheckin> {
  final int localId;
  final String userId;
  final String contractId;
  final String commitmentId;
  final String commitmentTitle;
  final String day;
  final String createdAt;
  final String status;
  final String? errorMessage;
  const OutboxCheckin({
    required this.localId,
    required this.userId,
    required this.contractId,
    required this.commitmentId,
    required this.commitmentTitle,
    required this.day,
    required this.createdAt,
    required this.status,
    this.errorMessage,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<int>(localId);
    map['user_id'] = Variable<String>(userId);
    map['contract_id'] = Variable<String>(contractId);
    map['commitment_id'] = Variable<String>(commitmentId);
    map['commitment_title'] = Variable<String>(commitmentTitle);
    map['day'] = Variable<String>(day);
    map['created_at'] = Variable<String>(createdAt);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    return map;
  }

  OutboxCheckinsCompanion toCompanion(bool nullToAbsent) {
    return OutboxCheckinsCompanion(
      localId: Value(localId),
      userId: Value(userId),
      contractId: Value(contractId),
      commitmentId: Value(commitmentId),
      commitmentTitle: Value(commitmentTitle),
      day: Value(day),
      createdAt: Value(createdAt),
      status: Value(status),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
    );
  }

  factory OutboxCheckin.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxCheckin(
      localId: serializer.fromJson<int>(json['localId']),
      userId: serializer.fromJson<String>(json['userId']),
      contractId: serializer.fromJson<String>(json['contractId']),
      commitmentId: serializer.fromJson<String>(json['commitmentId']),
      commitmentTitle: serializer.fromJson<String>(json['commitmentTitle']),
      day: serializer.fromJson<String>(json['day']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      status: serializer.fromJson<String>(json['status']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<int>(localId),
      'userId': serializer.toJson<String>(userId),
      'contractId': serializer.toJson<String>(contractId),
      'commitmentId': serializer.toJson<String>(commitmentId),
      'commitmentTitle': serializer.toJson<String>(commitmentTitle),
      'day': serializer.toJson<String>(day),
      'createdAt': serializer.toJson<String>(createdAt),
      'status': serializer.toJson<String>(status),
      'errorMessage': serializer.toJson<String?>(errorMessage),
    };
  }

  OutboxCheckin copyWith({
    int? localId,
    String? userId,
    String? contractId,
    String? commitmentId,
    String? commitmentTitle,
    String? day,
    String? createdAt,
    String? status,
    Value<String?> errorMessage = const Value.absent(),
  }) => OutboxCheckin(
    localId: localId ?? this.localId,
    userId: userId ?? this.userId,
    contractId: contractId ?? this.contractId,
    commitmentId: commitmentId ?? this.commitmentId,
    commitmentTitle: commitmentTitle ?? this.commitmentTitle,
    day: day ?? this.day,
    createdAt: createdAt ?? this.createdAt,
    status: status ?? this.status,
    errorMessage: errorMessage.present ? errorMessage.value : this.errorMessage,
  );
  OutboxCheckin copyWithCompanion(OutboxCheckinsCompanion data) {
    return OutboxCheckin(
      localId: data.localId.present ? data.localId.value : this.localId,
      userId: data.userId.present ? data.userId.value : this.userId,
      contractId: data.contractId.present
          ? data.contractId.value
          : this.contractId,
      commitmentId: data.commitmentId.present
          ? data.commitmentId.value
          : this.commitmentId,
      commitmentTitle: data.commitmentTitle.present
          ? data.commitmentTitle.value
          : this.commitmentTitle,
      day: data.day.present ? data.day.value : this.day,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      status: data.status.present ? data.status.value : this.status,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxCheckin(')
          ..write('localId: $localId, ')
          ..write('userId: $userId, ')
          ..write('contractId: $contractId, ')
          ..write('commitmentId: $commitmentId, ')
          ..write('commitmentTitle: $commitmentTitle, ')
          ..write('day: $day, ')
          ..write('createdAt: $createdAt, ')
          ..write('status: $status, ')
          ..write('errorMessage: $errorMessage')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    localId,
    userId,
    contractId,
    commitmentId,
    commitmentTitle,
    day,
    createdAt,
    status,
    errorMessage,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxCheckin &&
          other.localId == this.localId &&
          other.userId == this.userId &&
          other.contractId == this.contractId &&
          other.commitmentId == this.commitmentId &&
          other.commitmentTitle == this.commitmentTitle &&
          other.day == this.day &&
          other.createdAt == this.createdAt &&
          other.status == this.status &&
          other.errorMessage == this.errorMessage);
}

class OutboxCheckinsCompanion extends UpdateCompanion<OutboxCheckin> {
  final Value<int> localId;
  final Value<String> userId;
  final Value<String> contractId;
  final Value<String> commitmentId;
  final Value<String> commitmentTitle;
  final Value<String> day;
  final Value<String> createdAt;
  final Value<String> status;
  final Value<String?> errorMessage;
  const OutboxCheckinsCompanion({
    this.localId = const Value.absent(),
    this.userId = const Value.absent(),
    this.contractId = const Value.absent(),
    this.commitmentId = const Value.absent(),
    this.commitmentTitle = const Value.absent(),
    this.day = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.status = const Value.absent(),
    this.errorMessage = const Value.absent(),
  });
  OutboxCheckinsCompanion.insert({
    this.localId = const Value.absent(),
    required String userId,
    required String contractId,
    required String commitmentId,
    required String commitmentTitle,
    required String day,
    required String createdAt,
    required String status,
    this.errorMessage = const Value.absent(),
  }) : userId = Value(userId),
       contractId = Value(contractId),
       commitmentId = Value(commitmentId),
       commitmentTitle = Value(commitmentTitle),
       day = Value(day),
       createdAt = Value(createdAt),
       status = Value(status);
  static Insertable<OutboxCheckin> custom({
    Expression<int>? localId,
    Expression<String>? userId,
    Expression<String>? contractId,
    Expression<String>? commitmentId,
    Expression<String>? commitmentTitle,
    Expression<String>? day,
    Expression<String>? createdAt,
    Expression<String>? status,
    Expression<String>? errorMessage,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (userId != null) 'user_id': userId,
      if (contractId != null) 'contract_id': contractId,
      if (commitmentId != null) 'commitment_id': commitmentId,
      if (commitmentTitle != null) 'commitment_title': commitmentTitle,
      if (day != null) 'day': day,
      if (createdAt != null) 'created_at': createdAt,
      if (status != null) 'status': status,
      if (errorMessage != null) 'error_message': errorMessage,
    });
  }

  OutboxCheckinsCompanion copyWith({
    Value<int>? localId,
    Value<String>? userId,
    Value<String>? contractId,
    Value<String>? commitmentId,
    Value<String>? commitmentTitle,
    Value<String>? day,
    Value<String>? createdAt,
    Value<String>? status,
    Value<String?>? errorMessage,
  }) {
    return OutboxCheckinsCompanion(
      localId: localId ?? this.localId,
      userId: userId ?? this.userId,
      contractId: contractId ?? this.contractId,
      commitmentId: commitmentId ?? this.commitmentId,
      commitmentTitle: commitmentTitle ?? this.commitmentTitle,
      day: day ?? this.day,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<int>(localId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (contractId.present) {
      map['contract_id'] = Variable<String>(contractId.value);
    }
    if (commitmentId.present) {
      map['commitment_id'] = Variable<String>(commitmentId.value);
    }
    if (commitmentTitle.present) {
      map['commitment_title'] = Variable<String>(commitmentTitle.value);
    }
    if (day.present) {
      map['day'] = Variable<String>(day.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxCheckinsCompanion(')
          ..write('localId: $localId, ')
          ..write('userId: $userId, ')
          ..write('contractId: $contractId, ')
          ..write('commitmentId: $commitmentId, ')
          ..write('commitmentTitle: $commitmentTitle, ')
          ..write('day: $day, ')
          ..write('createdAt: $createdAt, ')
          ..write('status: $status, ')
          ..write('errorMessage: $errorMessage')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CachedContractsTable cachedContracts = $CachedContractsTable(
    this,
  );
  late final $CachedCommitmentsTable cachedCommitments =
      $CachedCommitmentsTable(this);
  late final $CachedLedgerEntriesTable cachedLedgerEntries =
      $CachedLedgerEntriesTable(this);
  late final $CachedStreaksTable cachedStreaks = $CachedStreaksTable(this);
  late final $OutboxCheckinsTable outboxCheckins = $OutboxCheckinsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    cachedContracts,
    cachedCommitments,
    cachedLedgerEntries,
    cachedStreaks,
    outboxCheckins,
  ];
}

typedef $$CachedContractsTableCreateCompanionBuilder =
    CachedContractsCompanion Function({
      required String id,
      required String userId,
      required String startDate,
      required String endDate,
      required String mode,
      required String status,
      required int kindRecoveriesUsed,
      required String updatedAt,
      Value<int> rowid,
    });
typedef $$CachedContractsTableUpdateCompanionBuilder =
    CachedContractsCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> startDate,
      Value<String> endDate,
      Value<String> mode,
      Value<String> status,
      Value<int> kindRecoveriesUsed,
      Value<String> updatedAt,
      Value<int> rowid,
    });

class $$CachedContractsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedContractsTable> {
  $$CachedContractsTableFilterComposer({
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

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get kindRecoveriesUsed => $composableBuilder(
    column: $table.kindRecoveriesUsed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedContractsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedContractsTable> {
  $$CachedContractsTableOrderingComposer({
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

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get kindRecoveriesUsed => $composableBuilder(
    column: $table.kindRecoveriesUsed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedContractsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedContractsTable> {
  $$CachedContractsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<String> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get kindRecoveriesUsed => $composableBuilder(
    column: $table.kindRecoveriesUsed,
    builder: (column) => column,
  );

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CachedContractsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedContractsTable,
          CachedContract,
          $$CachedContractsTableFilterComposer,
          $$CachedContractsTableOrderingComposer,
          $$CachedContractsTableAnnotationComposer,
          $$CachedContractsTableCreateCompanionBuilder,
          $$CachedContractsTableUpdateCompanionBuilder,
          (
            CachedContract,
            BaseReferences<
              _$AppDatabase,
              $CachedContractsTable,
              CachedContract
            >,
          ),
          CachedContract,
          PrefetchHooks Function()
        > {
  $$CachedContractsTableTableManager(
    _$AppDatabase db,
    $CachedContractsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedContractsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedContractsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedContractsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> startDate = const Value.absent(),
                Value<String> endDate = const Value.absent(),
                Value<String> mode = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> kindRecoveriesUsed = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedContractsCompanion(
                id: id,
                userId: userId,
                startDate: startDate,
                endDate: endDate,
                mode: mode,
                status: status,
                kindRecoveriesUsed: kindRecoveriesUsed,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String startDate,
                required String endDate,
                required String mode,
                required String status,
                required int kindRecoveriesUsed,
                required String updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedContractsCompanion.insert(
                id: id,
                userId: userId,
                startDate: startDate,
                endDate: endDate,
                mode: mode,
                status: status,
                kindRecoveriesUsed: kindRecoveriesUsed,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CachedContractsTable, CachedContract>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CachedContractsTable,
                    CachedContract
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedContractsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedContractsTable,
      CachedContract,
      $$CachedContractsTableFilterComposer,
      $$CachedContractsTableOrderingComposer,
      $$CachedContractsTableAnnotationComposer,
      $$CachedContractsTableCreateCompanionBuilder,
      $$CachedContractsTableUpdateCompanionBuilder,
      (
        CachedContract,
        BaseReferences<_$AppDatabase, $CachedContractsTable, CachedContract>,
      ),
      CachedContract,
      PrefetchHooks Function()
    >;
typedef $$CachedCommitmentsTableCreateCompanionBuilder =
    CachedCommitmentsCompanion Function({
      required String id,
      required String contractId,
      required String userId,
      required String title,
      Value<String?> targetTime,
      required int sortOrder,
      Value<String?> retiredAt,
      required String updatedAt,
      Value<int> rowid,
    });
typedef $$CachedCommitmentsTableUpdateCompanionBuilder =
    CachedCommitmentsCompanion Function({
      Value<String> id,
      Value<String> contractId,
      Value<String> userId,
      Value<String> title,
      Value<String?> targetTime,
      Value<int> sortOrder,
      Value<String?> retiredAt,
      Value<String> updatedAt,
      Value<int> rowid,
    });

class $$CachedCommitmentsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedCommitmentsTable> {
  $$CachedCommitmentsTableFilterComposer({
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

  ColumnFilters<String> get contractId => $composableBuilder(
    column: $table.contractId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetTime => $composableBuilder(
    column: $table.targetTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get retiredAt => $composableBuilder(
    column: $table.retiredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedCommitmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedCommitmentsTable> {
  $$CachedCommitmentsTableOrderingComposer({
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

  ColumnOrderings<String> get contractId => $composableBuilder(
    column: $table.contractId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetTime => $composableBuilder(
    column: $table.targetTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get retiredAt => $composableBuilder(
    column: $table.retiredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedCommitmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedCommitmentsTable> {
  $$CachedCommitmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get contractId => $composableBuilder(
    column: $table.contractId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get targetTime => $composableBuilder(
    column: $table.targetTime,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get retiredAt =>
      $composableBuilder(column: $table.retiredAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CachedCommitmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedCommitmentsTable,
          CachedCommitment,
          $$CachedCommitmentsTableFilterComposer,
          $$CachedCommitmentsTableOrderingComposer,
          $$CachedCommitmentsTableAnnotationComposer,
          $$CachedCommitmentsTableCreateCompanionBuilder,
          $$CachedCommitmentsTableUpdateCompanionBuilder,
          (
            CachedCommitment,
            BaseReferences<
              _$AppDatabase,
              $CachedCommitmentsTable,
              CachedCommitment
            >,
          ),
          CachedCommitment,
          PrefetchHooks Function()
        > {
  $$CachedCommitmentsTableTableManager(
    _$AppDatabase db,
    $CachedCommitmentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedCommitmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedCommitmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedCommitmentsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> contractId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> targetTime = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String?> retiredAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedCommitmentsCompanion(
                id: id,
                contractId: contractId,
                userId: userId,
                title: title,
                targetTime: targetTime,
                sortOrder: sortOrder,
                retiredAt: retiredAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String contractId,
                required String userId,
                required String title,
                Value<String?> targetTime = const Value.absent(),
                required int sortOrder,
                Value<String?> retiredAt = const Value.absent(),
                required String updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedCommitmentsCompanion.insert(
                id: id,
                contractId: contractId,
                userId: userId,
                title: title,
                targetTime: targetTime,
                sortOrder: sortOrder,
                retiredAt: retiredAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CachedCommitmentsTable, CachedCommitment>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CachedCommitmentsTable,
                    CachedCommitment
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedCommitmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedCommitmentsTable,
      CachedCommitment,
      $$CachedCommitmentsTableFilterComposer,
      $$CachedCommitmentsTableOrderingComposer,
      $$CachedCommitmentsTableAnnotationComposer,
      $$CachedCommitmentsTableCreateCompanionBuilder,
      $$CachedCommitmentsTableUpdateCompanionBuilder,
      (
        CachedCommitment,
        BaseReferences<
          _$AppDatabase,
          $CachedCommitmentsTable,
          CachedCommitment
        >,
      ),
      CachedCommitment,
      PrefetchHooks Function()
    >;
typedef $$CachedLedgerEntriesTableCreateCompanionBuilder =
    CachedLedgerEntriesCompanion Function({
      required String key,
      required String userId,
      required String contractId,
      required String commitmentId,
      required String title,
      required String day,
      required String status,
      Value<bool?> done,
      Value<bool> isPaused,
      Value<int> rowid,
    });
typedef $$CachedLedgerEntriesTableUpdateCompanionBuilder =
    CachedLedgerEntriesCompanion Function({
      Value<String> key,
      Value<String> userId,
      Value<String> contractId,
      Value<String> commitmentId,
      Value<String> title,
      Value<String> day,
      Value<String> status,
      Value<bool?> done,
      Value<bool> isPaused,
      Value<int> rowid,
    });

class $$CachedLedgerEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $CachedLedgerEntriesTable> {
  $$CachedLedgerEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contractId => $composableBuilder(
    column: $table.contractId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get commitmentId => $composableBuilder(
    column: $table.commitmentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get done => $composableBuilder(
    column: $table.done,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPaused => $composableBuilder(
    column: $table.isPaused,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedLedgerEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedLedgerEntriesTable> {
  $$CachedLedgerEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contractId => $composableBuilder(
    column: $table.contractId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get commitmentId => $composableBuilder(
    column: $table.commitmentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get done => $composableBuilder(
    column: $table.done,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPaused => $composableBuilder(
    column: $table.isPaused,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedLedgerEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedLedgerEntriesTable> {
  $$CachedLedgerEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get contractId => $composableBuilder(
    column: $table.contractId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get commitmentId => $composableBuilder(
    column: $table.commitmentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<bool> get done =>
      $composableBuilder(column: $table.done, builder: (column) => column);

  GeneratedColumn<bool> get isPaused =>
      $composableBuilder(column: $table.isPaused, builder: (column) => column);
}

class $$CachedLedgerEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedLedgerEntriesTable,
          CachedLedgerEntry,
          $$CachedLedgerEntriesTableFilterComposer,
          $$CachedLedgerEntriesTableOrderingComposer,
          $$CachedLedgerEntriesTableAnnotationComposer,
          $$CachedLedgerEntriesTableCreateCompanionBuilder,
          $$CachedLedgerEntriesTableUpdateCompanionBuilder,
          (
            CachedLedgerEntry,
            BaseReferences<
              _$AppDatabase,
              $CachedLedgerEntriesTable,
              CachedLedgerEntry
            >,
          ),
          CachedLedgerEntry,
          PrefetchHooks Function()
        > {
  $$CachedLedgerEntriesTableTableManager(
    _$AppDatabase db,
    $CachedLedgerEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedLedgerEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedLedgerEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CachedLedgerEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> contractId = const Value.absent(),
                Value<String> commitmentId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> day = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<bool?> done = const Value.absent(),
                Value<bool> isPaused = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedLedgerEntriesCompanion(
                key: key,
                userId: userId,
                contractId: contractId,
                commitmentId: commitmentId,
                title: title,
                day: day,
                status: status,
                done: done,
                isPaused: isPaused,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String userId,
                required String contractId,
                required String commitmentId,
                required String title,
                required String day,
                required String status,
                Value<bool?> done = const Value.absent(),
                Value<bool> isPaused = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedLedgerEntriesCompanion.insert(
                key: key,
                userId: userId,
                contractId: contractId,
                commitmentId: commitmentId,
                title: title,
                day: day,
                status: status,
                done: done,
                isPaused: isPaused,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CachedLedgerEntriesTable, CachedLedgerEntry>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $CachedLedgerEntriesTable,
                    CachedLedgerEntry
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedLedgerEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedLedgerEntriesTable,
      CachedLedgerEntry,
      $$CachedLedgerEntriesTableFilterComposer,
      $$CachedLedgerEntriesTableOrderingComposer,
      $$CachedLedgerEntriesTableAnnotationComposer,
      $$CachedLedgerEntriesTableCreateCompanionBuilder,
      $$CachedLedgerEntriesTableUpdateCompanionBuilder,
      (
        CachedLedgerEntry,
        BaseReferences<
          _$AppDatabase,
          $CachedLedgerEntriesTable,
          CachedLedgerEntry
        >,
      ),
      CachedLedgerEntry,
      PrefetchHooks Function()
    >;
typedef $$CachedStreaksTableCreateCompanionBuilder =
    CachedStreaksCompanion Function({
      required String contractId,
      required String userId,
      required int currentStreak,
      required int recoveriesUsed,
      required String mode,
      required String today,
      required String asOf,
      Value<int> rowid,
    });
typedef $$CachedStreaksTableUpdateCompanionBuilder =
    CachedStreaksCompanion Function({
      Value<String> contractId,
      Value<String> userId,
      Value<int> currentStreak,
      Value<int> recoveriesUsed,
      Value<String> mode,
      Value<String> today,
      Value<String> asOf,
      Value<int> rowid,
    });

class $$CachedStreaksTableFilterComposer
    extends Composer<_$AppDatabase, $CachedStreaksTable> {
  $$CachedStreaksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get contractId => $composableBuilder(
    column: $table.contractId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentStreak => $composableBuilder(
    column: $table.currentStreak,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get recoveriesUsed => $composableBuilder(
    column: $table.recoveriesUsed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get today => $composableBuilder(
    column: $table.today,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get asOf => $composableBuilder(
    column: $table.asOf,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedStreaksTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedStreaksTable> {
  $$CachedStreaksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get contractId => $composableBuilder(
    column: $table.contractId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentStreak => $composableBuilder(
    column: $table.currentStreak,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recoveriesUsed => $composableBuilder(
    column: $table.recoveriesUsed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get today => $composableBuilder(
    column: $table.today,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get asOf => $composableBuilder(
    column: $table.asOf,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedStreaksTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedStreaksTable> {
  $$CachedStreaksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get contractId => $composableBuilder(
    column: $table.contractId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<int> get currentStreak => $composableBuilder(
    column: $table.currentStreak,
    builder: (column) => column,
  );

  GeneratedColumn<int> get recoveriesUsed => $composableBuilder(
    column: $table.recoveriesUsed,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<String> get today =>
      $composableBuilder(column: $table.today, builder: (column) => column);

  GeneratedColumn<String> get asOf =>
      $composableBuilder(column: $table.asOf, builder: (column) => column);
}

class $$CachedStreaksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedStreaksTable,
          CachedStreak,
          $$CachedStreaksTableFilterComposer,
          $$CachedStreaksTableOrderingComposer,
          $$CachedStreaksTableAnnotationComposer,
          $$CachedStreaksTableCreateCompanionBuilder,
          $$CachedStreaksTableUpdateCompanionBuilder,
          (
            CachedStreak,
            BaseReferences<_$AppDatabase, $CachedStreaksTable, CachedStreak>,
          ),
          CachedStreak,
          PrefetchHooks Function()
        > {
  $$CachedStreaksTableTableManager(_$AppDatabase db, $CachedStreaksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedStreaksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedStreaksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedStreaksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> contractId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<int> currentStreak = const Value.absent(),
                Value<int> recoveriesUsed = const Value.absent(),
                Value<String> mode = const Value.absent(),
                Value<String> today = const Value.absent(),
                Value<String> asOf = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedStreaksCompanion(
                contractId: contractId,
                userId: userId,
                currentStreak: currentStreak,
                recoveriesUsed: recoveriesUsed,
                mode: mode,
                today: today,
                asOf: asOf,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String contractId,
                required String userId,
                required int currentStreak,
                required int recoveriesUsed,
                required String mode,
                required String today,
                required String asOf,
                Value<int> rowid = const Value.absent(),
              }) => CachedStreaksCompanion.insert(
                contractId: contractId,
                userId: userId,
                currentStreak: currentStreak,
                recoveriesUsed: recoveriesUsed,
                mode: mode,
                today: today,
                asOf: asOf,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CachedStreaksTable, CachedStreak>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CachedStreaksTable,
                    CachedStreak
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedStreaksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedStreaksTable,
      CachedStreak,
      $$CachedStreaksTableFilterComposer,
      $$CachedStreaksTableOrderingComposer,
      $$CachedStreaksTableAnnotationComposer,
      $$CachedStreaksTableCreateCompanionBuilder,
      $$CachedStreaksTableUpdateCompanionBuilder,
      (
        CachedStreak,
        BaseReferences<_$AppDatabase, $CachedStreaksTable, CachedStreak>,
      ),
      CachedStreak,
      PrefetchHooks Function()
    >;
typedef $$OutboxCheckinsTableCreateCompanionBuilder =
    OutboxCheckinsCompanion Function({
      Value<int> localId,
      required String userId,
      required String contractId,
      required String commitmentId,
      required String commitmentTitle,
      required String day,
      required String createdAt,
      required String status,
      Value<String?> errorMessage,
    });
typedef $$OutboxCheckinsTableUpdateCompanionBuilder =
    OutboxCheckinsCompanion Function({
      Value<int> localId,
      Value<String> userId,
      Value<String> contractId,
      Value<String> commitmentId,
      Value<String> commitmentTitle,
      Value<String> day,
      Value<String> createdAt,
      Value<String> status,
      Value<String?> errorMessage,
    });

class $$OutboxCheckinsTableFilterComposer
    extends Composer<_$AppDatabase, $OutboxCheckinsTable> {
  $$OutboxCheckinsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contractId => $composableBuilder(
    column: $table.contractId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get commitmentId => $composableBuilder(
    column: $table.commitmentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get commitmentTitle => $composableBuilder(
    column: $table.commitmentTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OutboxCheckinsTableOrderingComposer
    extends Composer<_$AppDatabase, $OutboxCheckinsTable> {
  $$OutboxCheckinsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contractId => $composableBuilder(
    column: $table.contractId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get commitmentId => $composableBuilder(
    column: $table.commitmentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get commitmentTitle => $composableBuilder(
    column: $table.commitmentTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OutboxCheckinsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OutboxCheckinsTable> {
  $$OutboxCheckinsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get contractId => $composableBuilder(
    column: $table.contractId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get commitmentId => $composableBuilder(
    column: $table.commitmentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get commitmentTitle => $composableBuilder(
    column: $table.commitmentTitle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => column,
  );
}

class $$OutboxCheckinsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OutboxCheckinsTable,
          OutboxCheckin,
          $$OutboxCheckinsTableFilterComposer,
          $$OutboxCheckinsTableOrderingComposer,
          $$OutboxCheckinsTableAnnotationComposer,
          $$OutboxCheckinsTableCreateCompanionBuilder,
          $$OutboxCheckinsTableUpdateCompanionBuilder,
          (
            OutboxCheckin,
            BaseReferences<_$AppDatabase, $OutboxCheckinsTable, OutboxCheckin>,
          ),
          OutboxCheckin,
          PrefetchHooks Function()
        > {
  $$OutboxCheckinsTableTableManager(
    _$AppDatabase db,
    $OutboxCheckinsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutboxCheckinsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutboxCheckinsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutboxCheckinsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> localId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> contractId = const Value.absent(),
                Value<String> commitmentId = const Value.absent(),
                Value<String> commitmentTitle = const Value.absent(),
                Value<String> day = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
              }) => OutboxCheckinsCompanion(
                localId: localId,
                userId: userId,
                contractId: contractId,
                commitmentId: commitmentId,
                commitmentTitle: commitmentTitle,
                day: day,
                createdAt: createdAt,
                status: status,
                errorMessage: errorMessage,
              ),
          createCompanionCallback:
              ({
                Value<int> localId = const Value.absent(),
                required String userId,
                required String contractId,
                required String commitmentId,
                required String commitmentTitle,
                required String day,
                required String createdAt,
                required String status,
                Value<String?> errorMessage = const Value.absent(),
              }) => OutboxCheckinsCompanion.insert(
                localId: localId,
                userId: userId,
                contractId: contractId,
                commitmentId: commitmentId,
                commitmentTitle: commitmentTitle,
                day: day,
                createdAt: createdAt,
                status: status,
                errorMessage: errorMessage,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OutboxCheckinsTable, OutboxCheckin>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $OutboxCheckinsTable,
                    OutboxCheckin
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OutboxCheckinsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OutboxCheckinsTable,
      OutboxCheckin,
      $$OutboxCheckinsTableFilterComposer,
      $$OutboxCheckinsTableOrderingComposer,
      $$OutboxCheckinsTableAnnotationComposer,
      $$OutboxCheckinsTableCreateCompanionBuilder,
      $$OutboxCheckinsTableUpdateCompanionBuilder,
      (
        OutboxCheckin,
        BaseReferences<_$AppDatabase, $OutboxCheckinsTable, OutboxCheckin>,
      ),
      OutboxCheckin,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CachedContractsTableTableManager get cachedContracts =>
      $$CachedContractsTableTableManager(_db, _db.cachedContracts);
  $$CachedCommitmentsTableTableManager get cachedCommitments =>
      $$CachedCommitmentsTableTableManager(_db, _db.cachedCommitments);
  $$CachedLedgerEntriesTableTableManager get cachedLedgerEntries =>
      $$CachedLedgerEntriesTableTableManager(_db, _db.cachedLedgerEntries);
  $$CachedStreaksTableTableManager get cachedStreaks =>
      $$CachedStreaksTableTableManager(_db, _db.cachedStreaks);
  $$OutboxCheckinsTableTableManager get outboxCheckins =>
      $$OutboxCheckinsTableTableManager(_db, _db.outboxCheckins);
}
