// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $SeasonsTable extends Seasons with TableInfo<$SeasonsTable, Season> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SeasonsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<String> uid = GeneratedColumn<String>(
    'uid',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 36, maxTextLength: 36),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Instant, int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  ).withConverter<Instant>($SeasonsTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<Instant, int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  ).withConverter<Instant>($SeasonsTable.$converterupdatedAt);
  static const VerificationMeta _struckMeta = const VerificationMeta('struck');
  @override
  late final GeneratedColumn<bool> struck = GeneratedColumn<bool>(
    'struck',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("struck" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Instant?, int> struckAt = GeneratedColumn<int>(
    'struck_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  ).withConverter<Instant?>($SeasonsTable.$converterstruckAtn);
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 60),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<LocalDate, String> startDate =
      GeneratedColumn<String>(
        'start_date',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<LocalDate>($SeasonsTable.$converterstartDate);
  @override
  late final GeneratedColumnWithTypeConverter<LocalDate?, String> endDate = GeneratedColumn<String>(
    'end_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<LocalDate?>($SeasonsTable.$converterendDaten);
  static const VerificationMeta _ewesToRamMeta = const VerificationMeta('ewesToRam');
  @override
  late final GeneratedColumn<int> ewesToRam = GeneratedColumn<int>(
    'ewes_to_ram',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _scanningResultMeta = const VerificationMeta('scanningResult');
  @override
  late final GeneratedColumn<int> scanningResult = GeneratedColumn<int>(
    'scanning_result',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _overFreeCapMeta = const VerificationMeta('overFreeCap');
  @override
  late final GeneratedColumn<bool> overFreeCap = GeneratedColumn<bool>(
    'over_free_cap',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("over_free_cap" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uid,
    createdAt,
    updatedAt,
    struck,
    struckAt,
    year,
    label,
    startDate,
    endDate,
    ewesToRam,
    scanningResult,
    notes,
    overFreeCap,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'seasons';
  @override
  VerificationContext validateIntegrity(Insertable<Season> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uid')) {
      context.handle(_uidMeta, uid.isAcceptableOrUnknown(data['uid']!, _uidMeta));
    } else if (isInserting) {
      context.missing(_uidMeta);
    }
    if (data.containsKey('struck')) {
      context.handle(_struckMeta, struck.isAcceptableOrUnknown(data['struck']!, _struckMeta));
    }
    if (data.containsKey('year')) {
      context.handle(_yearMeta, year.isAcceptableOrUnknown(data['year']!, _yearMeta));
    } else if (isInserting) {
      context.missing(_yearMeta);
    }
    if (data.containsKey('label')) {
      context.handle(_labelMeta, label.isAcceptableOrUnknown(data['label']!, _labelMeta));
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('ewes_to_ram')) {
      context.handle(
        _ewesToRamMeta,
        ewesToRam.isAcceptableOrUnknown(data['ewes_to_ram']!, _ewesToRamMeta),
      );
    }
    if (data.containsKey('scanning_result')) {
      context.handle(
        _scanningResultMeta,
        scanningResult.isAcceptableOrUnknown(data['scanning_result']!, _scanningResultMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(_notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('over_free_cap')) {
      context.handle(
        _overFreeCapMeta,
        overFreeCap.isAcceptableOrUnknown(data['over_free_cap']!, _overFreeCapMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Season map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Season(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      uid: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}uid'])!,
      createdAt: $SeasonsTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      ),
      updatedAt: $SeasonsTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
      ),
      struck: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}struck'],
      )!,
      struckAt: $SeasonsTable.$converterstruckAtn.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}struck_at']),
      ),
      year: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}year'])!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      startDate: $SeasonsTable.$converterstartDate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}start_date'],
        )!,
      ),
      endDate: $SeasonsTable.$converterendDaten.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}end_date']),
      ),
      ewesToRam: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ewes_to_ram'],
      ),
      scanningResult: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}scanning_result'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      overFreeCap: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}over_free_cap'],
      )!,
    );
  }

  @override
  $SeasonsTable createAlias(String alias) {
    return $SeasonsTable(attachedDatabase, alias);
  }

  static TypeConverter<Instant, int> $convertercreatedAt = const InstantConverter();
  static TypeConverter<Instant, int> $converterupdatedAt = const InstantConverter();
  static TypeConverter<Instant, int> $converterstruckAt = const InstantConverter();
  static TypeConverter<Instant?, int?> $converterstruckAtn = NullAwareTypeConverter.wrap(
    $converterstruckAt,
  );
  static TypeConverter<LocalDate, String> $converterstartDate = const LocalDateConverter();
  static TypeConverter<LocalDate, String> $converterendDate = const LocalDateConverter();
  static TypeConverter<LocalDate?, String?> $converterendDaten = NullAwareTypeConverter.wrap(
    $converterendDate,
  );
  @override
  bool get isStrict => true;
}

class Season extends DataClass implements Insertable<Season> {
  /// Joins and foreign keys. Device-local. **NEVER exported** (03 §3): a row id
  /// means nothing on another phone, and exporting one invites a restore that
  /// tries to honour it.
  final int id;

  /// UUID v7. The identity that survives export → re-import.
  final String uid;

  /// Instants: UTC epoch millis (§4).
  final Instant createdAt;
  final Instant updatedAt;

  /// Under `STRICT` there is no `BOOLEAN`, hence the first CHECK above.
  ///
  /// The default is **not** a violation of 03 §2 point 5: that rule bans
  /// defaults on columns that could encode veterinary advice — `days`, `ease`,
  /// `status` — and an unstruck row is the only thing a new row can be.
  final bool struck;

  /// An [Instant], not a civil date: a strike happened at a moment, and that is
  /// what makes one recorded at 01:30 on the clocks-back night unambiguous.
  final Instant? struckAt;
  final int year;
  final String label;
  final LocalDate startDate;
  final LocalDate? endDate;

  /// The lambing-percentage denominator. **NO DEFAULT**: a season with a blank
  /// `ewes_to_ram` is *"I did not record it"*, not zero and not *"same as
  /// lambed"* (decision #59).
  final int? ewesToRam;
  final int? scanningResult;
  final String? notes;

  /// Decision #91 and §7.0 ruling 8: the free tier is **season**-primary, so
  /// this is the column that matters — the second season is the gate, and
  /// `ewes.over_free_cap` is the calm secondary one. Rows over the cap are real
  /// rows, flagged, **never hidden, greyed out or made read-only**. Cleared in
  /// one transaction on unlock.
  final bool overFreeCap;
  const Season({
    required this.id,
    required this.uid,
    required this.createdAt,
    required this.updatedAt,
    required this.struck,
    this.struckAt,
    required this.year,
    required this.label,
    required this.startDate,
    this.endDate,
    this.ewesToRam,
    this.scanningResult,
    this.notes,
    required this.overFreeCap,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uid'] = Variable<String>(uid);
    {
      map['created_at'] = Variable<int>($SeasonsTable.$convertercreatedAt.toSql(createdAt));
    }
    {
      map['updated_at'] = Variable<int>($SeasonsTable.$converterupdatedAt.toSql(updatedAt));
    }
    map['struck'] = Variable<bool>(struck);
    if (!nullToAbsent || struckAt != null) {
      map['struck_at'] = Variable<int>($SeasonsTable.$converterstruckAtn.toSql(struckAt));
    }
    map['year'] = Variable<int>(year);
    map['label'] = Variable<String>(label);
    {
      map['start_date'] = Variable<String>($SeasonsTable.$converterstartDate.toSql(startDate));
    }
    if (!nullToAbsent || endDate != null) {
      map['end_date'] = Variable<String>($SeasonsTable.$converterendDaten.toSql(endDate));
    }
    if (!nullToAbsent || ewesToRam != null) {
      map['ewes_to_ram'] = Variable<int>(ewesToRam);
    }
    if (!nullToAbsent || scanningResult != null) {
      map['scanning_result'] = Variable<int>(scanningResult);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['over_free_cap'] = Variable<bool>(overFreeCap);
    return map;
  }

  SeasonsCompanion toCompanion(bool nullToAbsent) {
    return SeasonsCompanion(
      id: Value(id),
      uid: Value(uid),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      struck: Value(struck),
      struckAt: struckAt == null && nullToAbsent ? const Value.absent() : Value(struckAt),
      year: Value(year),
      label: Value(label),
      startDate: Value(startDate),
      endDate: endDate == null && nullToAbsent ? const Value.absent() : Value(endDate),
      ewesToRam: ewesToRam == null && nullToAbsent ? const Value.absent() : Value(ewesToRam),
      scanningResult: scanningResult == null && nullToAbsent
          ? const Value.absent()
          : Value(scanningResult),
      notes: notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      overFreeCap: Value(overFreeCap),
    );
  }

  factory Season.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Season(
      id: serializer.fromJson<int>(json['id']),
      uid: serializer.fromJson<String>(json['uid']),
      createdAt: serializer.fromJson<Instant>(json['createdAt']),
      updatedAt: serializer.fromJson<Instant>(json['updatedAt']),
      struck: serializer.fromJson<bool>(json['struck']),
      struckAt: serializer.fromJson<Instant?>(json['struckAt']),
      year: serializer.fromJson<int>(json['year']),
      label: serializer.fromJson<String>(json['label']),
      startDate: serializer.fromJson<LocalDate>(json['startDate']),
      endDate: serializer.fromJson<LocalDate?>(json['endDate']),
      ewesToRam: serializer.fromJson<int?>(json['ewesToRam']),
      scanningResult: serializer.fromJson<int?>(json['scanningResult']),
      notes: serializer.fromJson<String?>(json['notes']),
      overFreeCap: serializer.fromJson<bool>(json['overFreeCap']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uid': serializer.toJson<String>(uid),
      'createdAt': serializer.toJson<Instant>(createdAt),
      'updatedAt': serializer.toJson<Instant>(updatedAt),
      'struck': serializer.toJson<bool>(struck),
      'struckAt': serializer.toJson<Instant?>(struckAt),
      'year': serializer.toJson<int>(year),
      'label': serializer.toJson<String>(label),
      'startDate': serializer.toJson<LocalDate>(startDate),
      'endDate': serializer.toJson<LocalDate?>(endDate),
      'ewesToRam': serializer.toJson<int?>(ewesToRam),
      'scanningResult': serializer.toJson<int?>(scanningResult),
      'notes': serializer.toJson<String?>(notes),
      'overFreeCap': serializer.toJson<bool>(overFreeCap),
    };
  }

  Season copyWith({
    int? id,
    String? uid,
    Instant? createdAt,
    Instant? updatedAt,
    bool? struck,
    Value<Instant?> struckAt = const Value.absent(),
    int? year,
    String? label,
    LocalDate? startDate,
    Value<LocalDate?> endDate = const Value.absent(),
    Value<int?> ewesToRam = const Value.absent(),
    Value<int?> scanningResult = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    bool? overFreeCap,
  }) => Season(
    id: id ?? this.id,
    uid: uid ?? this.uid,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    struck: struck ?? this.struck,
    struckAt: struckAt.present ? struckAt.value : this.struckAt,
    year: year ?? this.year,
    label: label ?? this.label,
    startDate: startDate ?? this.startDate,
    endDate: endDate.present ? endDate.value : this.endDate,
    ewesToRam: ewesToRam.present ? ewesToRam.value : this.ewesToRam,
    scanningResult: scanningResult.present ? scanningResult.value : this.scanningResult,
    notes: notes.present ? notes.value : this.notes,
    overFreeCap: overFreeCap ?? this.overFreeCap,
  );
  Season copyWithCompanion(SeasonsCompanion data) {
    return Season(
      id: data.id.present ? data.id.value : this.id,
      uid: data.uid.present ? data.uid.value : this.uid,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      struck: data.struck.present ? data.struck.value : this.struck,
      struckAt: data.struckAt.present ? data.struckAt.value : this.struckAt,
      year: data.year.present ? data.year.value : this.year,
      label: data.label.present ? data.label.value : this.label,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      ewesToRam: data.ewesToRam.present ? data.ewesToRam.value : this.ewesToRam,
      scanningResult: data.scanningResult.present ? data.scanningResult.value : this.scanningResult,
      notes: data.notes.present ? data.notes.value : this.notes,
      overFreeCap: data.overFreeCap.present ? data.overFreeCap.value : this.overFreeCap,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Season(')
          ..write('id: $id, ')
          ..write('uid: $uid, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('struck: $struck, ')
          ..write('struckAt: $struckAt, ')
          ..write('year: $year, ')
          ..write('label: $label, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('ewesToRam: $ewesToRam, ')
          ..write('scanningResult: $scanningResult, ')
          ..write('notes: $notes, ')
          ..write('overFreeCap: $overFreeCap')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    uid,
    createdAt,
    updatedAt,
    struck,
    struckAt,
    year,
    label,
    startDate,
    endDate,
    ewesToRam,
    scanningResult,
    notes,
    overFreeCap,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Season &&
          other.id == this.id &&
          other.uid == this.uid &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.struck == this.struck &&
          other.struckAt == this.struckAt &&
          other.year == this.year &&
          other.label == this.label &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.ewesToRam == this.ewesToRam &&
          other.scanningResult == this.scanningResult &&
          other.notes == this.notes &&
          other.overFreeCap == this.overFreeCap);
}

class SeasonsCompanion extends UpdateCompanion<Season> {
  final Value<int> id;
  final Value<String> uid;
  final Value<Instant> createdAt;
  final Value<Instant> updatedAt;
  final Value<bool> struck;
  final Value<Instant?> struckAt;
  final Value<int> year;
  final Value<String> label;
  final Value<LocalDate> startDate;
  final Value<LocalDate?> endDate;
  final Value<int?> ewesToRam;
  final Value<int?> scanningResult;
  final Value<String?> notes;
  final Value<bool> overFreeCap;
  const SeasonsCompanion({
    this.id = const Value.absent(),
    this.uid = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.struck = const Value.absent(),
    this.struckAt = const Value.absent(),
    this.year = const Value.absent(),
    this.label = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.ewesToRam = const Value.absent(),
    this.scanningResult = const Value.absent(),
    this.notes = const Value.absent(),
    this.overFreeCap = const Value.absent(),
  });
  SeasonsCompanion.insert({
    this.id = const Value.absent(),
    required String uid,
    required Instant createdAt,
    required Instant updatedAt,
    this.struck = const Value.absent(),
    this.struckAt = const Value.absent(),
    required int year,
    required String label,
    required LocalDate startDate,
    this.endDate = const Value.absent(),
    this.ewesToRam = const Value.absent(),
    this.scanningResult = const Value.absent(),
    this.notes = const Value.absent(),
    this.overFreeCap = const Value.absent(),
  }) : uid = Value(uid),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       year = Value(year),
       label = Value(label),
       startDate = Value(startDate);
  static Insertable<Season> custom({
    Expression<int>? id,
    Expression<String>? uid,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<bool>? struck,
    Expression<int>? struckAt,
    Expression<int>? year,
    Expression<String>? label,
    Expression<String>? startDate,
    Expression<String>? endDate,
    Expression<int>? ewesToRam,
    Expression<int>? scanningResult,
    Expression<String>? notes,
    Expression<bool>? overFreeCap,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uid != null) 'uid': uid,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (struck != null) 'struck': struck,
      if (struckAt != null) 'struck_at': struckAt,
      if (year != null) 'year': year,
      if (label != null) 'label': label,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (ewesToRam != null) 'ewes_to_ram': ewesToRam,
      if (scanningResult != null) 'scanning_result': scanningResult,
      if (notes != null) 'notes': notes,
      if (overFreeCap != null) 'over_free_cap': overFreeCap,
    });
  }

  SeasonsCompanion copyWith({
    Value<int>? id,
    Value<String>? uid,
    Value<Instant>? createdAt,
    Value<Instant>? updatedAt,
    Value<bool>? struck,
    Value<Instant?>? struckAt,
    Value<int>? year,
    Value<String>? label,
    Value<LocalDate>? startDate,
    Value<LocalDate?>? endDate,
    Value<int?>? ewesToRam,
    Value<int?>? scanningResult,
    Value<String?>? notes,
    Value<bool>? overFreeCap,
  }) {
    return SeasonsCompanion(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      struck: struck ?? this.struck,
      struckAt: struckAt ?? this.struckAt,
      year: year ?? this.year,
      label: label ?? this.label,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      ewesToRam: ewesToRam ?? this.ewesToRam,
      scanningResult: scanningResult ?? this.scanningResult,
      notes: notes ?? this.notes,
      overFreeCap: overFreeCap ?? this.overFreeCap,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uid.present) {
      map['uid'] = Variable<String>(uid.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>($SeasonsTable.$convertercreatedAt.toSql(createdAt.value));
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>($SeasonsTable.$converterupdatedAt.toSql(updatedAt.value));
    }
    if (struck.present) {
      map['struck'] = Variable<bool>(struck.value);
    }
    if (struckAt.present) {
      map['struck_at'] = Variable<int>($SeasonsTable.$converterstruckAtn.toSql(struckAt.value));
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<String>(
        $SeasonsTable.$converterstartDate.toSql(startDate.value),
      );
    }
    if (endDate.present) {
      map['end_date'] = Variable<String>($SeasonsTable.$converterendDaten.toSql(endDate.value));
    }
    if (ewesToRam.present) {
      map['ewes_to_ram'] = Variable<int>(ewesToRam.value);
    }
    if (scanningResult.present) {
      map['scanning_result'] = Variable<int>(scanningResult.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (overFreeCap.present) {
      map['over_free_cap'] = Variable<bool>(overFreeCap.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SeasonsCompanion(')
          ..write('id: $id, ')
          ..write('uid: $uid, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('struck: $struck, ')
          ..write('struckAt: $struckAt, ')
          ..write('year: $year, ')
          ..write('label: $label, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('ewesToRam: $ewesToRam, ')
          ..write('scanningResult: $scanningResult, ')
          ..write('notes: $notes, ')
          ..write('overFreeCap: $overFreeCap')
          ..write(')'))
        .toString();
  }
}

class $EwesTable extends Ewes with TableInfo<$EwesTable, Ewe> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EwesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<String> uid = GeneratedColumn<String>(
    'uid',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 36, maxTextLength: 36),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Instant, int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  ).withConverter<Instant>($EwesTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<Instant, int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  ).withConverter<Instant>($EwesTable.$converterupdatedAt);
  static const VerificationMeta _struckMeta = const VerificationMeta('struck');
  @override
  late final GeneratedColumn<bool> struck = GeneratedColumn<bool>(
    'struck',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("struck" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Instant?, int> struckAt = GeneratedColumn<int>(
    'struck_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  ).withConverter<Instant?>($EwesTable.$converterstruckAtn);
  static const VerificationMeta _tagMeta = const VerificationMeta('tag');
  @override
  late final GeneratedColumn<String> tag = GeneratedColumn<String>(
    'tag',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 32),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tagDigitsMeta = const VerificationMeta('tagDigits');
  @override
  late final GeneratedColumn<String> tagDigits = GeneratedColumn<String>(
    'tag_digits',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 0, maxTextLength: 32),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eidMeta = const VerificationMeta('eid');
  @override
  late final GeneratedColumn<String> eid = GeneratedColumn<String>(
    'eid',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 0, maxTextLength: 32),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _breedMeta = const VerificationMeta('breed');
  @override
  late final GeneratedColumn<String> breed = GeneratedColumn<String>(
    'breed',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<PartialDate?, String> dateOfBirth =
      GeneratedColumn<String>(
        'date_of_birth',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<PartialDate?>($EwesTable.$converterdateOfBirthn);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('active'),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _overFreeCapMeta = const VerificationMeta('overFreeCap');
  @override
  late final GeneratedColumn<bool> overFreeCap = GeneratedColumn<bool>(
    'over_free_cap',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("over_free_cap" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uid,
    createdAt,
    updatedAt,
    struck,
    struckAt,
    tag,
    tagDigits,
    eid,
    breed,
    dateOfBirth,
    source,
    status,
    notes,
    overFreeCap,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ewes';
  @override
  VerificationContext validateIntegrity(Insertable<Ewe> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uid')) {
      context.handle(_uidMeta, uid.isAcceptableOrUnknown(data['uid']!, _uidMeta));
    } else if (isInserting) {
      context.missing(_uidMeta);
    }
    if (data.containsKey('struck')) {
      context.handle(_struckMeta, struck.isAcceptableOrUnknown(data['struck']!, _struckMeta));
    }
    if (data.containsKey('tag')) {
      context.handle(_tagMeta, tag.isAcceptableOrUnknown(data['tag']!, _tagMeta));
    } else if (isInserting) {
      context.missing(_tagMeta);
    }
    if (data.containsKey('tag_digits')) {
      context.handle(
        _tagDigitsMeta,
        tagDigits.isAcceptableOrUnknown(data['tag_digits']!, _tagDigitsMeta),
      );
    } else if (isInserting) {
      context.missing(_tagDigitsMeta);
    }
    if (data.containsKey('eid')) {
      context.handle(_eidMeta, eid.isAcceptableOrUnknown(data['eid']!, _eidMeta));
    }
    if (data.containsKey('breed')) {
      context.handle(_breedMeta, breed.isAcceptableOrUnknown(data['breed']!, _breedMeta));
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta, source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta, status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(_notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('over_free_cap')) {
      context.handle(
        _overFreeCapMeta,
        overFreeCap.isAcceptableOrUnknown(data['over_free_cap']!, _overFreeCapMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Ewe map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Ewe(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      uid: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}uid'])!,
      createdAt: $EwesTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      ),
      updatedAt: $EwesTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
      ),
      struck: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}struck'],
      )!,
      struckAt: $EwesTable.$converterstruckAtn.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}struck_at']),
      ),
      tag: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}tag'])!,
      tagDigits: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tag_digits'],
      )!,
      eid: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}eid']),
      breed: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}breed'],
      ),
      dateOfBirth: $EwesTable.$converterdateOfBirthn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}date_of_birth'],
        ),
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      overFreeCap: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}over_free_cap'],
      )!,
    );
  }

  @override
  $EwesTable createAlias(String alias) {
    return $EwesTable(attachedDatabase, alias);
  }

  static TypeConverter<Instant, int> $convertercreatedAt = const InstantConverter();
  static TypeConverter<Instant, int> $converterupdatedAt = const InstantConverter();
  static TypeConverter<Instant, int> $converterstruckAt = const InstantConverter();
  static TypeConverter<Instant?, int?> $converterstruckAtn = NullAwareTypeConverter.wrap(
    $converterstruckAt,
  );
  static TypeConverter<PartialDate, String> $converterdateOfBirth = const PartialDateConverter();
  static TypeConverter<PartialDate?, String?> $converterdateOfBirthn = NullAwareTypeConverter.wrap(
    $converterdateOfBirth,
  );
  @override
  bool get isStrict => true;
}

class Ewe extends DataClass implements Insertable<Ewe> {
  /// Joins and foreign keys. Device-local. **NEVER exported** (03 §3): a row id
  /// means nothing on another phone, and exporting one invites a restore that
  /// tries to honour it.
  final int id;

  /// UUID v7. The identity that survives export → re-import.
  final String uid;

  /// Instants: UTC epoch millis (§4).
  final Instant createdAt;
  final Instant updatedAt;

  /// Under `STRICT` there is no `BOOLEAN`, hence the first CHECK above.
  ///
  /// The default is **not** a violation of 03 §2 point 5: that rule bans
  /// defaults on columns that could encode veterinary advice — `days`, `ease`,
  /// `status` — and an unstruck row is the only thing a new row can be.
  final bool struck;

  /// An [Instant], not a civil date: a strike happened at a moment, and that is
  /// what makes one recorded at 01:30 on the clocks-back night unambiguous.
  final Instant? struckAt;

  /// Exactly as typed. **Never normalised on write** (spec §12.4).
  final String tag;

  /// A digits-only **projection** of [tag], written in the same statement.
  ///
  /// A projection, not a correction: the typed value is preserved verbatim
  /// beside it, so the `normalize*` ban does not apply (decision #55).
  /// `min: 0`, because a tag can be all letters.
  ///
  /// **Uniqueness is on [tag], never on this.** Making the projection unique
  /// would refuse `0412` because `412` exists — the app deciding two tags are
  /// the same animal. It ranks matches; it never decides identity.
  final String tagDigits;
  final String? eid;
  final String? breed;

  /// Partial precision is a real state. **Do not pad a year to 1 January.**
  final PartialDate? dateOfBirth;
  final String? source;

  /// A default here is fine: it encodes nothing veterinary.
  final String status;
  final String? notes;
  final bool overFreeCap;
  const Ewe({
    required this.id,
    required this.uid,
    required this.createdAt,
    required this.updatedAt,
    required this.struck,
    this.struckAt,
    required this.tag,
    required this.tagDigits,
    this.eid,
    this.breed,
    this.dateOfBirth,
    this.source,
    required this.status,
    this.notes,
    required this.overFreeCap,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uid'] = Variable<String>(uid);
    {
      map['created_at'] = Variable<int>($EwesTable.$convertercreatedAt.toSql(createdAt));
    }
    {
      map['updated_at'] = Variable<int>($EwesTable.$converterupdatedAt.toSql(updatedAt));
    }
    map['struck'] = Variable<bool>(struck);
    if (!nullToAbsent || struckAt != null) {
      map['struck_at'] = Variable<int>($EwesTable.$converterstruckAtn.toSql(struckAt));
    }
    map['tag'] = Variable<String>(tag);
    map['tag_digits'] = Variable<String>(tagDigits);
    if (!nullToAbsent || eid != null) {
      map['eid'] = Variable<String>(eid);
    }
    if (!nullToAbsent || breed != null) {
      map['breed'] = Variable<String>(breed);
    }
    if (!nullToAbsent || dateOfBirth != null) {
      map['date_of_birth'] = Variable<String>($EwesTable.$converterdateOfBirthn.toSql(dateOfBirth));
    }
    if (!nullToAbsent || source != null) {
      map['source'] = Variable<String>(source);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['over_free_cap'] = Variable<bool>(overFreeCap);
    return map;
  }

  EwesCompanion toCompanion(bool nullToAbsent) {
    return EwesCompanion(
      id: Value(id),
      uid: Value(uid),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      struck: Value(struck),
      struckAt: struckAt == null && nullToAbsent ? const Value.absent() : Value(struckAt),
      tag: Value(tag),
      tagDigits: Value(tagDigits),
      eid: eid == null && nullToAbsent ? const Value.absent() : Value(eid),
      breed: breed == null && nullToAbsent ? const Value.absent() : Value(breed),
      dateOfBirth: dateOfBirth == null && nullToAbsent ? const Value.absent() : Value(dateOfBirth),
      source: source == null && nullToAbsent ? const Value.absent() : Value(source),
      status: Value(status),
      notes: notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      overFreeCap: Value(overFreeCap),
    );
  }

  factory Ewe.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Ewe(
      id: serializer.fromJson<int>(json['id']),
      uid: serializer.fromJson<String>(json['uid']),
      createdAt: serializer.fromJson<Instant>(json['createdAt']),
      updatedAt: serializer.fromJson<Instant>(json['updatedAt']),
      struck: serializer.fromJson<bool>(json['struck']),
      struckAt: serializer.fromJson<Instant?>(json['struckAt']),
      tag: serializer.fromJson<String>(json['tag']),
      tagDigits: serializer.fromJson<String>(json['tagDigits']),
      eid: serializer.fromJson<String?>(json['eid']),
      breed: serializer.fromJson<String?>(json['breed']),
      dateOfBirth: serializer.fromJson<PartialDate?>(json['dateOfBirth']),
      source: serializer.fromJson<String?>(json['source']),
      status: serializer.fromJson<String>(json['status']),
      notes: serializer.fromJson<String?>(json['notes']),
      overFreeCap: serializer.fromJson<bool>(json['overFreeCap']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uid': serializer.toJson<String>(uid),
      'createdAt': serializer.toJson<Instant>(createdAt),
      'updatedAt': serializer.toJson<Instant>(updatedAt),
      'struck': serializer.toJson<bool>(struck),
      'struckAt': serializer.toJson<Instant?>(struckAt),
      'tag': serializer.toJson<String>(tag),
      'tagDigits': serializer.toJson<String>(tagDigits),
      'eid': serializer.toJson<String?>(eid),
      'breed': serializer.toJson<String?>(breed),
      'dateOfBirth': serializer.toJson<PartialDate?>(dateOfBirth),
      'source': serializer.toJson<String?>(source),
      'status': serializer.toJson<String>(status),
      'notes': serializer.toJson<String?>(notes),
      'overFreeCap': serializer.toJson<bool>(overFreeCap),
    };
  }

  Ewe copyWith({
    int? id,
    String? uid,
    Instant? createdAt,
    Instant? updatedAt,
    bool? struck,
    Value<Instant?> struckAt = const Value.absent(),
    String? tag,
    String? tagDigits,
    Value<String?> eid = const Value.absent(),
    Value<String?> breed = const Value.absent(),
    Value<PartialDate?> dateOfBirth = const Value.absent(),
    Value<String?> source = const Value.absent(),
    String? status,
    Value<String?> notes = const Value.absent(),
    bool? overFreeCap,
  }) => Ewe(
    id: id ?? this.id,
    uid: uid ?? this.uid,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    struck: struck ?? this.struck,
    struckAt: struckAt.present ? struckAt.value : this.struckAt,
    tag: tag ?? this.tag,
    tagDigits: tagDigits ?? this.tagDigits,
    eid: eid.present ? eid.value : this.eid,
    breed: breed.present ? breed.value : this.breed,
    dateOfBirth: dateOfBirth.present ? dateOfBirth.value : this.dateOfBirth,
    source: source.present ? source.value : this.source,
    status: status ?? this.status,
    notes: notes.present ? notes.value : this.notes,
    overFreeCap: overFreeCap ?? this.overFreeCap,
  );
  Ewe copyWithCompanion(EwesCompanion data) {
    return Ewe(
      id: data.id.present ? data.id.value : this.id,
      uid: data.uid.present ? data.uid.value : this.uid,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      struck: data.struck.present ? data.struck.value : this.struck,
      struckAt: data.struckAt.present ? data.struckAt.value : this.struckAt,
      tag: data.tag.present ? data.tag.value : this.tag,
      tagDigits: data.tagDigits.present ? data.tagDigits.value : this.tagDigits,
      eid: data.eid.present ? data.eid.value : this.eid,
      breed: data.breed.present ? data.breed.value : this.breed,
      dateOfBirth: data.dateOfBirth.present ? data.dateOfBirth.value : this.dateOfBirth,
      source: data.source.present ? data.source.value : this.source,
      status: data.status.present ? data.status.value : this.status,
      notes: data.notes.present ? data.notes.value : this.notes,
      overFreeCap: data.overFreeCap.present ? data.overFreeCap.value : this.overFreeCap,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Ewe(')
          ..write('id: $id, ')
          ..write('uid: $uid, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('struck: $struck, ')
          ..write('struckAt: $struckAt, ')
          ..write('tag: $tag, ')
          ..write('tagDigits: $tagDigits, ')
          ..write('eid: $eid, ')
          ..write('breed: $breed, ')
          ..write('dateOfBirth: $dateOfBirth, ')
          ..write('source: $source, ')
          ..write('status: $status, ')
          ..write('notes: $notes, ')
          ..write('overFreeCap: $overFreeCap')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    uid,
    createdAt,
    updatedAt,
    struck,
    struckAt,
    tag,
    tagDigits,
    eid,
    breed,
    dateOfBirth,
    source,
    status,
    notes,
    overFreeCap,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Ewe &&
          other.id == this.id &&
          other.uid == this.uid &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.struck == this.struck &&
          other.struckAt == this.struckAt &&
          other.tag == this.tag &&
          other.tagDigits == this.tagDigits &&
          other.eid == this.eid &&
          other.breed == this.breed &&
          other.dateOfBirth == this.dateOfBirth &&
          other.source == this.source &&
          other.status == this.status &&
          other.notes == this.notes &&
          other.overFreeCap == this.overFreeCap);
}

class EwesCompanion extends UpdateCompanion<Ewe> {
  final Value<int> id;
  final Value<String> uid;
  final Value<Instant> createdAt;
  final Value<Instant> updatedAt;
  final Value<bool> struck;
  final Value<Instant?> struckAt;
  final Value<String> tag;
  final Value<String> tagDigits;
  final Value<String?> eid;
  final Value<String?> breed;
  final Value<PartialDate?> dateOfBirth;
  final Value<String?> source;
  final Value<String> status;
  final Value<String?> notes;
  final Value<bool> overFreeCap;
  const EwesCompanion({
    this.id = const Value.absent(),
    this.uid = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.struck = const Value.absent(),
    this.struckAt = const Value.absent(),
    this.tag = const Value.absent(),
    this.tagDigits = const Value.absent(),
    this.eid = const Value.absent(),
    this.breed = const Value.absent(),
    this.dateOfBirth = const Value.absent(),
    this.source = const Value.absent(),
    this.status = const Value.absent(),
    this.notes = const Value.absent(),
    this.overFreeCap = const Value.absent(),
  });
  EwesCompanion.insert({
    this.id = const Value.absent(),
    required String uid,
    required Instant createdAt,
    required Instant updatedAt,
    this.struck = const Value.absent(),
    this.struckAt = const Value.absent(),
    required String tag,
    required String tagDigits,
    this.eid = const Value.absent(),
    this.breed = const Value.absent(),
    this.dateOfBirth = const Value.absent(),
    this.source = const Value.absent(),
    this.status = const Value.absent(),
    this.notes = const Value.absent(),
    this.overFreeCap = const Value.absent(),
  }) : uid = Value(uid),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       tag = Value(tag),
       tagDigits = Value(tagDigits);
  static Insertable<Ewe> custom({
    Expression<int>? id,
    Expression<String>? uid,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<bool>? struck,
    Expression<int>? struckAt,
    Expression<String>? tag,
    Expression<String>? tagDigits,
    Expression<String>? eid,
    Expression<String>? breed,
    Expression<String>? dateOfBirth,
    Expression<String>? source,
    Expression<String>? status,
    Expression<String>? notes,
    Expression<bool>? overFreeCap,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uid != null) 'uid': uid,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (struck != null) 'struck': struck,
      if (struckAt != null) 'struck_at': struckAt,
      if (tag != null) 'tag': tag,
      if (tagDigits != null) 'tag_digits': tagDigits,
      if (eid != null) 'eid': eid,
      if (breed != null) 'breed': breed,
      if (dateOfBirth != null) 'date_of_birth': dateOfBirth,
      if (source != null) 'source': source,
      if (status != null) 'status': status,
      if (notes != null) 'notes': notes,
      if (overFreeCap != null) 'over_free_cap': overFreeCap,
    });
  }

  EwesCompanion copyWith({
    Value<int>? id,
    Value<String>? uid,
    Value<Instant>? createdAt,
    Value<Instant>? updatedAt,
    Value<bool>? struck,
    Value<Instant?>? struckAt,
    Value<String>? tag,
    Value<String>? tagDigits,
    Value<String?>? eid,
    Value<String?>? breed,
    Value<PartialDate?>? dateOfBirth,
    Value<String?>? source,
    Value<String>? status,
    Value<String?>? notes,
    Value<bool>? overFreeCap,
  }) {
    return EwesCompanion(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      struck: struck ?? this.struck,
      struckAt: struckAt ?? this.struckAt,
      tag: tag ?? this.tag,
      tagDigits: tagDigits ?? this.tagDigits,
      eid: eid ?? this.eid,
      breed: breed ?? this.breed,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      source: source ?? this.source,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      overFreeCap: overFreeCap ?? this.overFreeCap,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uid.present) {
      map['uid'] = Variable<String>(uid.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>($EwesTable.$convertercreatedAt.toSql(createdAt.value));
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>($EwesTable.$converterupdatedAt.toSql(updatedAt.value));
    }
    if (struck.present) {
      map['struck'] = Variable<bool>(struck.value);
    }
    if (struckAt.present) {
      map['struck_at'] = Variable<int>($EwesTable.$converterstruckAtn.toSql(struckAt.value));
    }
    if (tag.present) {
      map['tag'] = Variable<String>(tag.value);
    }
    if (tagDigits.present) {
      map['tag_digits'] = Variable<String>(tagDigits.value);
    }
    if (eid.present) {
      map['eid'] = Variable<String>(eid.value);
    }
    if (breed.present) {
      map['breed'] = Variable<String>(breed.value);
    }
    if (dateOfBirth.present) {
      map['date_of_birth'] = Variable<String>(
        $EwesTable.$converterdateOfBirthn.toSql(dateOfBirth.value),
      );
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (overFreeCap.present) {
      map['over_free_cap'] = Variable<bool>(overFreeCap.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EwesCompanion(')
          ..write('id: $id, ')
          ..write('uid: $uid, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('struck: $struck, ')
          ..write('struckAt: $struckAt, ')
          ..write('tag: $tag, ')
          ..write('tagDigits: $tagDigits, ')
          ..write('eid: $eid, ')
          ..write('breed: $breed, ')
          ..write('dateOfBirth: $dateOfBirth, ')
          ..write('source: $source, ')
          ..write('status: $status, ')
          ..write('notes: $notes, ')
          ..write('overFreeCap: $overFreeCap')
          ..write(')'))
        .toString();
  }
}

class $LambingsTable extends Lambings with TableInfo<$LambingsTable, Lambing> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LambingsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<String> uid = GeneratedColumn<String>(
    'uid',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 36, maxTextLength: 36),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Instant, int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  ).withConverter<Instant>($LambingsTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<Instant, int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  ).withConverter<Instant>($LambingsTable.$converterupdatedAt);
  static const VerificationMeta _struckMeta = const VerificationMeta('struck');
  @override
  late final GeneratedColumn<bool> struck = GeneratedColumn<bool>(
    'struck',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("struck" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Instant?, int> struckAt = GeneratedColumn<int>(
    'struck_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  ).withConverter<Instant?>($LambingsTable.$converterstruckAtn);
  static const VerificationMeta _seasonMeta = const VerificationMeta('season');
  @override
  late final GeneratedColumn<int> season = GeneratedColumn<int>(
    'season',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES seasons (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _eweMeta = const VerificationMeta('ewe');
  @override
  late final GeneratedColumn<int> ewe = GeneratedColumn<int>(
    'ewe',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES ewes (id) ON DELETE RESTRICT',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Instant, int> occurredAt = GeneratedColumn<int>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  ).withConverter<Instant>($LambingsTable.$converteroccurredAt);
  @override
  late final GeneratedColumnWithTypeConverter<Instant, int> capturedAt = GeneratedColumn<int>(
    'captured_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  ).withConverter<Instant>($LambingsTable.$convertercapturedAt);
  @override
  late final GeneratedColumnWithTypeConverter<Instant?, int> originalEffective =
      GeneratedColumn<int>(
        'original_effective',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<Instant?>($LambingsTable.$converteroriginalEffectiven);
  static const VerificationMeta _timeSourceMeta = const VerificationMeta('timeSource');
  @override
  late final GeneratedColumn<String> timeSource = GeneratedColumn<String>(
    'time_source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('auto'),
  );
  @override
  late final GeneratedColumnWithTypeConverter<LocalDate, String> localDate =
      GeneratedColumn<String>(
        'local_date',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<LocalDate>($LambingsTable.$converterlocalDate);
  static const VerificationMeta _declaredBirthTypeMeta = const VerificationMeta(
    'declaredBirthType',
  );
  @override
  late final GeneratedColumn<int> declaredBirthType = GeneratedColumn<int>(
    'declared_birth_type',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _easeMeta = const VerificationMeta('ease');
  @override
  late final GeneratedColumn<int> ease = GeneratedColumn<int>(
    'ease',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _assistedByMeta = const VerificationMeta('assistedBy');
  @override
  late final GeneratedColumn<String> assistedBy = GeneratedColumn<String>(
    'assisted_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _presentationMeta = const VerificationMeta('presentation');
  @override
  late final GeneratedColumn<String> presentation = GeneratedColumn<String>(
    'presentation',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _presentationNoteMeta = const VerificationMeta('presentationNote');
  @override
  late final GeneratedColumn<String> presentationNote = GeneratedColumn<String>(
    'presentation_note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uid,
    createdAt,
    updatedAt,
    struck,
    struckAt,
    season,
    ewe,
    occurredAt,
    capturedAt,
    originalEffective,
    timeSource,
    localDate,
    declaredBirthType,
    ease,
    assistedBy,
    presentation,
    presentationNote,
    note,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lambings';
  @override
  VerificationContext validateIntegrity(Insertable<Lambing> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uid')) {
      context.handle(_uidMeta, uid.isAcceptableOrUnknown(data['uid']!, _uidMeta));
    } else if (isInserting) {
      context.missing(_uidMeta);
    }
    if (data.containsKey('struck')) {
      context.handle(_struckMeta, struck.isAcceptableOrUnknown(data['struck']!, _struckMeta));
    }
    if (data.containsKey('season')) {
      context.handle(_seasonMeta, season.isAcceptableOrUnknown(data['season']!, _seasonMeta));
    } else if (isInserting) {
      context.missing(_seasonMeta);
    }
    if (data.containsKey('ewe')) {
      context.handle(_eweMeta, ewe.isAcceptableOrUnknown(data['ewe']!, _eweMeta));
    } else if (isInserting) {
      context.missing(_eweMeta);
    }
    if (data.containsKey('time_source')) {
      context.handle(
        _timeSourceMeta,
        timeSource.isAcceptableOrUnknown(data['time_source']!, _timeSourceMeta),
      );
    }
    if (data.containsKey('declared_birth_type')) {
      context.handle(
        _declaredBirthTypeMeta,
        declaredBirthType.isAcceptableOrUnknown(
          data['declared_birth_type']!,
          _declaredBirthTypeMeta,
        ),
      );
    }
    if (data.containsKey('ease')) {
      context.handle(_easeMeta, ease.isAcceptableOrUnknown(data['ease']!, _easeMeta));
    }
    if (data.containsKey('assisted_by')) {
      context.handle(
        _assistedByMeta,
        assistedBy.isAcceptableOrUnknown(data['assisted_by']!, _assistedByMeta),
      );
    }
    if (data.containsKey('presentation')) {
      context.handle(
        _presentationMeta,
        presentation.isAcceptableOrUnknown(data['presentation']!, _presentationMeta),
      );
    }
    if (data.containsKey('presentation_note')) {
      context.handle(
        _presentationNoteMeta,
        presentationNote.isAcceptableOrUnknown(data['presentation_note']!, _presentationNoteMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(_noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Lambing map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Lambing(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      uid: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}uid'])!,
      createdAt: $LambingsTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      ),
      updatedAt: $LambingsTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
      ),
      struck: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}struck'],
      )!,
      struckAt: $LambingsTable.$converterstruckAtn.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}struck_at']),
      ),
      season: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}season'],
      )!,
      ewe: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}ewe'])!,
      occurredAt: $LambingsTable.$converteroccurredAt.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}occurred_at'])!,
      ),
      capturedAt: $LambingsTable.$convertercapturedAt.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}captured_at'])!,
      ),
      originalEffective: $LambingsTable.$converteroriginalEffectiven.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}original_effective'],
        ),
      ),
      timeSource: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}time_source'],
      )!,
      localDate: $LambingsTable.$converterlocalDate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}local_date'],
        )!,
      ),
      declaredBirthType: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}declared_birth_type'],
      ),
      ease: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}ease']),
      assistedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}assisted_by'],
      ),
      presentation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}presentation'],
      ),
      presentationNote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}presentation_note'],
      ),
      note: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}note']),
    );
  }

  @override
  $LambingsTable createAlias(String alias) {
    return $LambingsTable(attachedDatabase, alias);
  }

  static TypeConverter<Instant, int> $convertercreatedAt = const InstantConverter();
  static TypeConverter<Instant, int> $converterupdatedAt = const InstantConverter();
  static TypeConverter<Instant, int> $converterstruckAt = const InstantConverter();
  static TypeConverter<Instant?, int?> $converterstruckAtn = NullAwareTypeConverter.wrap(
    $converterstruckAt,
  );
  static TypeConverter<Instant, int> $converteroccurredAt = const InstantConverter();
  static TypeConverter<Instant, int> $convertercapturedAt = const InstantConverter();
  static TypeConverter<Instant, int> $converteroriginalEffective = const InstantConverter();
  static TypeConverter<Instant?, int?> $converteroriginalEffectiven = NullAwareTypeConverter.wrap(
    $converteroriginalEffective,
  );
  static TypeConverter<LocalDate, String> $converterlocalDate = const LocalDateConverter();
  @override
  bool get isStrict => true;
}

class Lambing extends DataClass implements Insertable<Lambing> {
  /// Joins and foreign keys. Device-local. **NEVER exported** (03 §3): a row id
  /// means nothing on another phone, and exporting one invites a restore that
  /// tries to honour it.
  final int id;

  /// UUID v7. The identity that survives export → re-import.
  final String uid;

  /// Instants: UTC epoch millis (§4).
  final Instant createdAt;
  final Instant updatedAt;

  /// Under `STRICT` there is no `BOOLEAN`, hence the first CHECK above.
  ///
  /// The default is **not** a violation of 03 §2 point 5: that rule bans
  /// defaults on columns that could encode veterinary advice — `days`, `ease`,
  /// `status` — and an unstruck row is the only thing a new row can be.
  final bool struck;

  /// An [Instant], not a civil date: a strike happened at a moment, and that is
  /// what makes one recorded at 01:30 on the clocks-back night unambiguous.
  final Instant? struckAt;
  final int season;

  /// `restrict`: a ewe with lambings is a record someone may show a vet, so she
  /// cannot be deleted out from under it — and she never needs to be, because a
  /// ewe leaves the flock by `status = 'culled'`, not by DELETE.
  final int ewe;
  final Instant occurredAt;
  final Instant capturedAt;
  final Instant? originalEffective;
  final String timeSource;

  /// Denormalised local civil date of [occurredAt], written in the **same
  /// statement**.
  ///
  /// The grouping key for the lambing-spread histogram: SQLite cannot bucket by
  /// the shepherd's civil day without a timezone database, and Dart can. An edit
  /// to the time that leaves this stale moves a lambing to the wrong bar for
  /// ever — which is what `WarningCode.localDateDisagrees` surfaces and nothing
  /// repairs.
  final LocalDate localDate;

  /// EXACTLY what the shepherd tapped. 1 = single … 4 = quad, 5 = *"more"*.
  /// **The number of Lamb rows is NOT forced to agree** (spec §12.4).
  ///
  /// **NULLABLE, and this is load-bearing (R6):** the lambing row is written on
  /// the FIRST tap, before any birth type exists, and the record must survive
  /// being interrupted at any point. NULL means *"not yet tapped"*, which is a
  /// different fact from any of 1..5 and is **never defaulted to `single`**.
  final int? declaredBirthType;

  /// 1..5. **NO DEFAULT and nullable**: a blank score means *"not scored"*,
  /// which is a different fact from *"unassisted"* (decision #59).
  final int? ease;
  final String? assistedBy;

  /// **Forward reference, deferred to N07-T06** — a user-editable vocabulary is
  /// a foreign key, never a `CHECK` (convention 6):
  /// `.references(VocabTerms, #key, onDelete: KeyAction.restrict)`.
  final String? presentation;
  final String? presentationNote;
  final String? note;
  const Lambing({
    required this.id,
    required this.uid,
    required this.createdAt,
    required this.updatedAt,
    required this.struck,
    this.struckAt,
    required this.season,
    required this.ewe,
    required this.occurredAt,
    required this.capturedAt,
    this.originalEffective,
    required this.timeSource,
    required this.localDate,
    this.declaredBirthType,
    this.ease,
    this.assistedBy,
    this.presentation,
    this.presentationNote,
    this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uid'] = Variable<String>(uid);
    {
      map['created_at'] = Variable<int>($LambingsTable.$convertercreatedAt.toSql(createdAt));
    }
    {
      map['updated_at'] = Variable<int>($LambingsTable.$converterupdatedAt.toSql(updatedAt));
    }
    map['struck'] = Variable<bool>(struck);
    if (!nullToAbsent || struckAt != null) {
      map['struck_at'] = Variable<int>($LambingsTable.$converterstruckAtn.toSql(struckAt));
    }
    map['season'] = Variable<int>(season);
    map['ewe'] = Variable<int>(ewe);
    {
      map['occurred_at'] = Variable<int>($LambingsTable.$converteroccurredAt.toSql(occurredAt));
    }
    {
      map['captured_at'] = Variable<int>($LambingsTable.$convertercapturedAt.toSql(capturedAt));
    }
    if (!nullToAbsent || originalEffective != null) {
      map['original_effective'] = Variable<int>(
        $LambingsTable.$converteroriginalEffectiven.toSql(originalEffective),
      );
    }
    map['time_source'] = Variable<String>(timeSource);
    {
      map['local_date'] = Variable<String>($LambingsTable.$converterlocalDate.toSql(localDate));
    }
    if (!nullToAbsent || declaredBirthType != null) {
      map['declared_birth_type'] = Variable<int>(declaredBirthType);
    }
    if (!nullToAbsent || ease != null) {
      map['ease'] = Variable<int>(ease);
    }
    if (!nullToAbsent || assistedBy != null) {
      map['assisted_by'] = Variable<String>(assistedBy);
    }
    if (!nullToAbsent || presentation != null) {
      map['presentation'] = Variable<String>(presentation);
    }
    if (!nullToAbsent || presentationNote != null) {
      map['presentation_note'] = Variable<String>(presentationNote);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  LambingsCompanion toCompanion(bool nullToAbsent) {
    return LambingsCompanion(
      id: Value(id),
      uid: Value(uid),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      struck: Value(struck),
      struckAt: struckAt == null && nullToAbsent ? const Value.absent() : Value(struckAt),
      season: Value(season),
      ewe: Value(ewe),
      occurredAt: Value(occurredAt),
      capturedAt: Value(capturedAt),
      originalEffective: originalEffective == null && nullToAbsent
          ? const Value.absent()
          : Value(originalEffective),
      timeSource: Value(timeSource),
      localDate: Value(localDate),
      declaredBirthType: declaredBirthType == null && nullToAbsent
          ? const Value.absent()
          : Value(declaredBirthType),
      ease: ease == null && nullToAbsent ? const Value.absent() : Value(ease),
      assistedBy: assistedBy == null && nullToAbsent ? const Value.absent() : Value(assistedBy),
      presentation: presentation == null && nullToAbsent
          ? const Value.absent()
          : Value(presentation),
      presentationNote: presentationNote == null && nullToAbsent
          ? const Value.absent()
          : Value(presentationNote),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory Lambing.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Lambing(
      id: serializer.fromJson<int>(json['id']),
      uid: serializer.fromJson<String>(json['uid']),
      createdAt: serializer.fromJson<Instant>(json['createdAt']),
      updatedAt: serializer.fromJson<Instant>(json['updatedAt']),
      struck: serializer.fromJson<bool>(json['struck']),
      struckAt: serializer.fromJson<Instant?>(json['struckAt']),
      season: serializer.fromJson<int>(json['season']),
      ewe: serializer.fromJson<int>(json['ewe']),
      occurredAt: serializer.fromJson<Instant>(json['occurredAt']),
      capturedAt: serializer.fromJson<Instant>(json['capturedAt']),
      originalEffective: serializer.fromJson<Instant?>(json['originalEffective']),
      timeSource: serializer.fromJson<String>(json['timeSource']),
      localDate: serializer.fromJson<LocalDate>(json['localDate']),
      declaredBirthType: serializer.fromJson<int?>(json['declaredBirthType']),
      ease: serializer.fromJson<int?>(json['ease']),
      assistedBy: serializer.fromJson<String?>(json['assistedBy']),
      presentation: serializer.fromJson<String?>(json['presentation']),
      presentationNote: serializer.fromJson<String?>(json['presentationNote']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uid': serializer.toJson<String>(uid),
      'createdAt': serializer.toJson<Instant>(createdAt),
      'updatedAt': serializer.toJson<Instant>(updatedAt),
      'struck': serializer.toJson<bool>(struck),
      'struckAt': serializer.toJson<Instant?>(struckAt),
      'season': serializer.toJson<int>(season),
      'ewe': serializer.toJson<int>(ewe),
      'occurredAt': serializer.toJson<Instant>(occurredAt),
      'capturedAt': serializer.toJson<Instant>(capturedAt),
      'originalEffective': serializer.toJson<Instant?>(originalEffective),
      'timeSource': serializer.toJson<String>(timeSource),
      'localDate': serializer.toJson<LocalDate>(localDate),
      'declaredBirthType': serializer.toJson<int?>(declaredBirthType),
      'ease': serializer.toJson<int?>(ease),
      'assistedBy': serializer.toJson<String?>(assistedBy),
      'presentation': serializer.toJson<String?>(presentation),
      'presentationNote': serializer.toJson<String?>(presentationNote),
      'note': serializer.toJson<String?>(note),
    };
  }

  Lambing copyWith({
    int? id,
    String? uid,
    Instant? createdAt,
    Instant? updatedAt,
    bool? struck,
    Value<Instant?> struckAt = const Value.absent(),
    int? season,
    int? ewe,
    Instant? occurredAt,
    Instant? capturedAt,
    Value<Instant?> originalEffective = const Value.absent(),
    String? timeSource,
    LocalDate? localDate,
    Value<int?> declaredBirthType = const Value.absent(),
    Value<int?> ease = const Value.absent(),
    Value<String?> assistedBy = const Value.absent(),
    Value<String?> presentation = const Value.absent(),
    Value<String?> presentationNote = const Value.absent(),
    Value<String?> note = const Value.absent(),
  }) => Lambing(
    id: id ?? this.id,
    uid: uid ?? this.uid,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    struck: struck ?? this.struck,
    struckAt: struckAt.present ? struckAt.value : this.struckAt,
    season: season ?? this.season,
    ewe: ewe ?? this.ewe,
    occurredAt: occurredAt ?? this.occurredAt,
    capturedAt: capturedAt ?? this.capturedAt,
    originalEffective: originalEffective.present ? originalEffective.value : this.originalEffective,
    timeSource: timeSource ?? this.timeSource,
    localDate: localDate ?? this.localDate,
    declaredBirthType: declaredBirthType.present ? declaredBirthType.value : this.declaredBirthType,
    ease: ease.present ? ease.value : this.ease,
    assistedBy: assistedBy.present ? assistedBy.value : this.assistedBy,
    presentation: presentation.present ? presentation.value : this.presentation,
    presentationNote: presentationNote.present ? presentationNote.value : this.presentationNote,
    note: note.present ? note.value : this.note,
  );
  Lambing copyWithCompanion(LambingsCompanion data) {
    return Lambing(
      id: data.id.present ? data.id.value : this.id,
      uid: data.uid.present ? data.uid.value : this.uid,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      struck: data.struck.present ? data.struck.value : this.struck,
      struckAt: data.struckAt.present ? data.struckAt.value : this.struckAt,
      season: data.season.present ? data.season.value : this.season,
      ewe: data.ewe.present ? data.ewe.value : this.ewe,
      occurredAt: data.occurredAt.present ? data.occurredAt.value : this.occurredAt,
      capturedAt: data.capturedAt.present ? data.capturedAt.value : this.capturedAt,
      originalEffective: data.originalEffective.present
          ? data.originalEffective.value
          : this.originalEffective,
      timeSource: data.timeSource.present ? data.timeSource.value : this.timeSource,
      localDate: data.localDate.present ? data.localDate.value : this.localDate,
      declaredBirthType: data.declaredBirthType.present
          ? data.declaredBirthType.value
          : this.declaredBirthType,
      ease: data.ease.present ? data.ease.value : this.ease,
      assistedBy: data.assistedBy.present ? data.assistedBy.value : this.assistedBy,
      presentation: data.presentation.present ? data.presentation.value : this.presentation,
      presentationNote: data.presentationNote.present
          ? data.presentationNote.value
          : this.presentationNote,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Lambing(')
          ..write('id: $id, ')
          ..write('uid: $uid, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('struck: $struck, ')
          ..write('struckAt: $struckAt, ')
          ..write('season: $season, ')
          ..write('ewe: $ewe, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('originalEffective: $originalEffective, ')
          ..write('timeSource: $timeSource, ')
          ..write('localDate: $localDate, ')
          ..write('declaredBirthType: $declaredBirthType, ')
          ..write('ease: $ease, ')
          ..write('assistedBy: $assistedBy, ')
          ..write('presentation: $presentation, ')
          ..write('presentationNote: $presentationNote, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    uid,
    createdAt,
    updatedAt,
    struck,
    struckAt,
    season,
    ewe,
    occurredAt,
    capturedAt,
    originalEffective,
    timeSource,
    localDate,
    declaredBirthType,
    ease,
    assistedBy,
    presentation,
    presentationNote,
    note,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Lambing &&
          other.id == this.id &&
          other.uid == this.uid &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.struck == this.struck &&
          other.struckAt == this.struckAt &&
          other.season == this.season &&
          other.ewe == this.ewe &&
          other.occurredAt == this.occurredAt &&
          other.capturedAt == this.capturedAt &&
          other.originalEffective == this.originalEffective &&
          other.timeSource == this.timeSource &&
          other.localDate == this.localDate &&
          other.declaredBirthType == this.declaredBirthType &&
          other.ease == this.ease &&
          other.assistedBy == this.assistedBy &&
          other.presentation == this.presentation &&
          other.presentationNote == this.presentationNote &&
          other.note == this.note);
}

class LambingsCompanion extends UpdateCompanion<Lambing> {
  final Value<int> id;
  final Value<String> uid;
  final Value<Instant> createdAt;
  final Value<Instant> updatedAt;
  final Value<bool> struck;
  final Value<Instant?> struckAt;
  final Value<int> season;
  final Value<int> ewe;
  final Value<Instant> occurredAt;
  final Value<Instant> capturedAt;
  final Value<Instant?> originalEffective;
  final Value<String> timeSource;
  final Value<LocalDate> localDate;
  final Value<int?> declaredBirthType;
  final Value<int?> ease;
  final Value<String?> assistedBy;
  final Value<String?> presentation;
  final Value<String?> presentationNote;
  final Value<String?> note;
  const LambingsCompanion({
    this.id = const Value.absent(),
    this.uid = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.struck = const Value.absent(),
    this.struckAt = const Value.absent(),
    this.season = const Value.absent(),
    this.ewe = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.capturedAt = const Value.absent(),
    this.originalEffective = const Value.absent(),
    this.timeSource = const Value.absent(),
    this.localDate = const Value.absent(),
    this.declaredBirthType = const Value.absent(),
    this.ease = const Value.absent(),
    this.assistedBy = const Value.absent(),
    this.presentation = const Value.absent(),
    this.presentationNote = const Value.absent(),
    this.note = const Value.absent(),
  });
  LambingsCompanion.insert({
    this.id = const Value.absent(),
    required String uid,
    required Instant createdAt,
    required Instant updatedAt,
    this.struck = const Value.absent(),
    this.struckAt = const Value.absent(),
    required int season,
    required int ewe,
    required Instant occurredAt,
    required Instant capturedAt,
    this.originalEffective = const Value.absent(),
    this.timeSource = const Value.absent(),
    required LocalDate localDate,
    this.declaredBirthType = const Value.absent(),
    this.ease = const Value.absent(),
    this.assistedBy = const Value.absent(),
    this.presentation = const Value.absent(),
    this.presentationNote = const Value.absent(),
    this.note = const Value.absent(),
  }) : uid = Value(uid),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       season = Value(season),
       ewe = Value(ewe),
       occurredAt = Value(occurredAt),
       capturedAt = Value(capturedAt),
       localDate = Value(localDate);
  static Insertable<Lambing> custom({
    Expression<int>? id,
    Expression<String>? uid,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<bool>? struck,
    Expression<int>? struckAt,
    Expression<int>? season,
    Expression<int>? ewe,
    Expression<int>? occurredAt,
    Expression<int>? capturedAt,
    Expression<int>? originalEffective,
    Expression<String>? timeSource,
    Expression<String>? localDate,
    Expression<int>? declaredBirthType,
    Expression<int>? ease,
    Expression<String>? assistedBy,
    Expression<String>? presentation,
    Expression<String>? presentationNote,
    Expression<String>? note,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uid != null) 'uid': uid,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (struck != null) 'struck': struck,
      if (struckAt != null) 'struck_at': struckAt,
      if (season != null) 'season': season,
      if (ewe != null) 'ewe': ewe,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (capturedAt != null) 'captured_at': capturedAt,
      if (originalEffective != null) 'original_effective': originalEffective,
      if (timeSource != null) 'time_source': timeSource,
      if (localDate != null) 'local_date': localDate,
      if (declaredBirthType != null) 'declared_birth_type': declaredBirthType,
      if (ease != null) 'ease': ease,
      if (assistedBy != null) 'assisted_by': assistedBy,
      if (presentation != null) 'presentation': presentation,
      if (presentationNote != null) 'presentation_note': presentationNote,
      if (note != null) 'note': note,
    });
  }

  LambingsCompanion copyWith({
    Value<int>? id,
    Value<String>? uid,
    Value<Instant>? createdAt,
    Value<Instant>? updatedAt,
    Value<bool>? struck,
    Value<Instant?>? struckAt,
    Value<int>? season,
    Value<int>? ewe,
    Value<Instant>? occurredAt,
    Value<Instant>? capturedAt,
    Value<Instant?>? originalEffective,
    Value<String>? timeSource,
    Value<LocalDate>? localDate,
    Value<int?>? declaredBirthType,
    Value<int?>? ease,
    Value<String?>? assistedBy,
    Value<String?>? presentation,
    Value<String?>? presentationNote,
    Value<String?>? note,
  }) {
    return LambingsCompanion(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      struck: struck ?? this.struck,
      struckAt: struckAt ?? this.struckAt,
      season: season ?? this.season,
      ewe: ewe ?? this.ewe,
      occurredAt: occurredAt ?? this.occurredAt,
      capturedAt: capturedAt ?? this.capturedAt,
      originalEffective: originalEffective ?? this.originalEffective,
      timeSource: timeSource ?? this.timeSource,
      localDate: localDate ?? this.localDate,
      declaredBirthType: declaredBirthType ?? this.declaredBirthType,
      ease: ease ?? this.ease,
      assistedBy: assistedBy ?? this.assistedBy,
      presentation: presentation ?? this.presentation,
      presentationNote: presentationNote ?? this.presentationNote,
      note: note ?? this.note,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uid.present) {
      map['uid'] = Variable<String>(uid.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>($LambingsTable.$convertercreatedAt.toSql(createdAt.value));
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>($LambingsTable.$converterupdatedAt.toSql(updatedAt.value));
    }
    if (struck.present) {
      map['struck'] = Variable<bool>(struck.value);
    }
    if (struckAt.present) {
      map['struck_at'] = Variable<int>($LambingsTable.$converterstruckAtn.toSql(struckAt.value));
    }
    if (season.present) {
      map['season'] = Variable<int>(season.value);
    }
    if (ewe.present) {
      map['ewe'] = Variable<int>(ewe.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<int>(
        $LambingsTable.$converteroccurredAt.toSql(occurredAt.value),
      );
    }
    if (capturedAt.present) {
      map['captured_at'] = Variable<int>(
        $LambingsTable.$convertercapturedAt.toSql(capturedAt.value),
      );
    }
    if (originalEffective.present) {
      map['original_effective'] = Variable<int>(
        $LambingsTable.$converteroriginalEffectiven.toSql(originalEffective.value),
      );
    }
    if (timeSource.present) {
      map['time_source'] = Variable<String>(timeSource.value);
    }
    if (localDate.present) {
      map['local_date'] = Variable<String>(
        $LambingsTable.$converterlocalDate.toSql(localDate.value),
      );
    }
    if (declaredBirthType.present) {
      map['declared_birth_type'] = Variable<int>(declaredBirthType.value);
    }
    if (ease.present) {
      map['ease'] = Variable<int>(ease.value);
    }
    if (assistedBy.present) {
      map['assisted_by'] = Variable<String>(assistedBy.value);
    }
    if (presentation.present) {
      map['presentation'] = Variable<String>(presentation.value);
    }
    if (presentationNote.present) {
      map['presentation_note'] = Variable<String>(presentationNote.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LambingsCompanion(')
          ..write('id: $id, ')
          ..write('uid: $uid, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('struck: $struck, ')
          ..write('struckAt: $struckAt, ')
          ..write('season: $season, ')
          ..write('ewe: $ewe, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('originalEffective: $originalEffective, ')
          ..write('timeSource: $timeSource, ')
          ..write('localDate: $localDate, ')
          ..write('declaredBirthType: $declaredBirthType, ')
          ..write('ease: $ease, ')
          ..write('assistedBy: $assistedBy, ')
          ..write('presentation: $presentation, ')
          ..write('presentationNote: $presentationNote, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }
}

class $LambsTable extends Lambs with TableInfo<$LambsTable, Lamb> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LambsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<String> uid = GeneratedColumn<String>(
    'uid',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 36, maxTextLength: 36),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Instant, int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  ).withConverter<Instant>($LambsTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<Instant, int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  ).withConverter<Instant>($LambsTable.$converterupdatedAt);
  static const VerificationMeta _struckMeta = const VerificationMeta('struck');
  @override
  late final GeneratedColumn<bool> struck = GeneratedColumn<bool>(
    'struck',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("struck" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Instant?, int> struckAt = GeneratedColumn<int>(
    'struck_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  ).withConverter<Instant?>($LambsTable.$converterstruckAtn);
  static const VerificationMeta _lambingMeta = const VerificationMeta('lambing');
  @override
  late final GeneratedColumn<int> lambing = GeneratedColumn<int>(
    'lambing',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES lambings (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _birthDamMeta = const VerificationMeta('birthDam');
  @override
  late final GeneratedColumn<int> birthDam = GeneratedColumn<int>(
    'birth_dam',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES ewes (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _tagMeta = const VerificationMeta('tag');
  @override
  late final GeneratedColumn<String> tag = GeneratedColumn<String>(
    'tag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tagDigitsMeta = const VerificationMeta('tagDigits');
  @override
  late final GeneratedColumn<String> tagDigits = GeneratedColumn<String>(
    'tag_digits',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sexMeta = const VerificationMeta('sex');
  @override
  late final GeneratedColumn<String> sex = GeneratedColumn<String>(
    'sex',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _birthWeightGMeta = const VerificationMeta('birthWeightG');
  @override
  late final GeneratedColumn<int> birthWeightG = GeneratedColumn<int>(
    'birth_weight_g',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('alive'),
  );
  @override
  late final GeneratedColumnWithTypeConverter<LocalDate?, String> deathDate =
      GeneratedColumn<String>(
        'death_date',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<LocalDate?>($LambsTable.$converterdeathDaten);
  static const VerificationMeta _deathCauseMeta = const VerificationMeta('deathCause');
  @override
  late final GeneratedColumn<String> deathCause = GeneratedColumn<String>(
    'death_cause',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _petLambMeta = const VerificationMeta('petLamb');
  @override
  late final GeneratedColumn<bool> petLamb = GeneratedColumn<bool>(
    'pet_lamb',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("pet_lamb" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _bottleFeedsMeta = const VerificationMeta('bottleFeeds');
  @override
  late final GeneratedColumn<int> bottleFeeds = GeneratedColumn<int>(
    'bottle_feeds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _becameEweMeta = const VerificationMeta('becameEwe');
  @override
  late final GeneratedColumn<int> becameEwe = GeneratedColumn<int>(
    'became_ewe',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES ewes (id) ON DELETE SET NULL',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uid,
    createdAt,
    updatedAt,
    struck,
    struckAt,
    lambing,
    birthDam,
    tag,
    tagDigits,
    sex,
    birthWeightG,
    status,
    deathDate,
    deathCause,
    petLamb,
    bottleFeeds,
    notes,
    becameEwe,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lambs';
  @override
  VerificationContext validateIntegrity(Insertable<Lamb> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uid')) {
      context.handle(_uidMeta, uid.isAcceptableOrUnknown(data['uid']!, _uidMeta));
    } else if (isInserting) {
      context.missing(_uidMeta);
    }
    if (data.containsKey('struck')) {
      context.handle(_struckMeta, struck.isAcceptableOrUnknown(data['struck']!, _struckMeta));
    }
    if (data.containsKey('lambing')) {
      context.handle(_lambingMeta, lambing.isAcceptableOrUnknown(data['lambing']!, _lambingMeta));
    } else if (isInserting) {
      context.missing(_lambingMeta);
    }
    if (data.containsKey('birth_dam')) {
      context.handle(
        _birthDamMeta,
        birthDam.isAcceptableOrUnknown(data['birth_dam']!, _birthDamMeta),
      );
    } else if (isInserting) {
      context.missing(_birthDamMeta);
    }
    if (data.containsKey('tag')) {
      context.handle(_tagMeta, tag.isAcceptableOrUnknown(data['tag']!, _tagMeta));
    }
    if (data.containsKey('tag_digits')) {
      context.handle(
        _tagDigitsMeta,
        tagDigits.isAcceptableOrUnknown(data['tag_digits']!, _tagDigitsMeta),
      );
    }
    if (data.containsKey('sex')) {
      context.handle(_sexMeta, sex.isAcceptableOrUnknown(data['sex']!, _sexMeta));
    }
    if (data.containsKey('birth_weight_g')) {
      context.handle(
        _birthWeightGMeta,
        birthWeightG.isAcceptableOrUnknown(data['birth_weight_g']!, _birthWeightGMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta, status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('death_cause')) {
      context.handle(
        _deathCauseMeta,
        deathCause.isAcceptableOrUnknown(data['death_cause']!, _deathCauseMeta),
      );
    }
    if (data.containsKey('pet_lamb')) {
      context.handle(_petLambMeta, petLamb.isAcceptableOrUnknown(data['pet_lamb']!, _petLambMeta));
    }
    if (data.containsKey('bottle_feeds')) {
      context.handle(
        _bottleFeedsMeta,
        bottleFeeds.isAcceptableOrUnknown(data['bottle_feeds']!, _bottleFeedsMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(_notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('became_ewe')) {
      context.handle(
        _becameEweMeta,
        becameEwe.isAcceptableOrUnknown(data['became_ewe']!, _becameEweMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Lamb map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Lamb(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      uid: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}uid'])!,
      createdAt: $LambsTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      ),
      updatedAt: $LambsTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
      ),
      struck: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}struck'],
      )!,
      struckAt: $LambsTable.$converterstruckAtn.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}struck_at']),
      ),
      lambing: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lambing'],
      )!,
      birthDam: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}birth_dam'],
      )!,
      tag: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}tag']),
      tagDigits: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tag_digits'],
      ),
      sex: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}sex']),
      birthWeightG: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}birth_weight_g'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      deathDate: $LambsTable.$converterdeathDaten.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}death_date'],
        ),
      ),
      deathCause: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}death_cause'],
      ),
      petLamb: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pet_lamb'],
      )!,
      bottleFeeds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bottle_feeds'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      becameEwe: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}became_ewe'],
      ),
    );
  }

  @override
  $LambsTable createAlias(String alias) {
    return $LambsTable(attachedDatabase, alias);
  }

  static TypeConverter<Instant, int> $convertercreatedAt = const InstantConverter();
  static TypeConverter<Instant, int> $converterupdatedAt = const InstantConverter();
  static TypeConverter<Instant, int> $converterstruckAt = const InstantConverter();
  static TypeConverter<Instant?, int?> $converterstruckAtn = NullAwareTypeConverter.wrap(
    $converterstruckAt,
  );
  static TypeConverter<LocalDate, String> $converterdeathDate = const LocalDateConverter();
  static TypeConverter<LocalDate?, String?> $converterdeathDaten = NullAwareTypeConverter.wrap(
    $converterdeathDate,
  );
  @override
  bool get isStrict => true;
}

class Lamb extends DataClass implements Insertable<Lamb> {
  /// Joins and foreign keys. Device-local. **NEVER exported** (03 §3): a row id
  /// means nothing on another phone, and exporting one invites a restore that
  /// tries to honour it.
  final int id;

  /// UUID v7. The identity that survives export → re-import.
  final String uid;

  /// Instants: UTC epoch millis (§4).
  final Instant createdAt;
  final Instant updatedAt;

  /// Under `STRICT` there is no `BOOLEAN`, hence the first CHECK above.
  ///
  /// The default is **not** a violation of 03 §2 point 5: that rule bans
  /// defaults on columns that could encode veterinary advice — `days`, `ease`,
  /// `status` — and an unstruck row is the only thing a new row can be.
  final bool struck;

  /// An [Instant], not a civil date: a strike happened at a moment, and that is
  /// what makes one recorded at 01:30 on the clocks-back night unambiguous.
  final Instant? struckAt;
  final int lambing;

  /// Immutable, denormalised from `lambings.ewe` at insert. **Enforced by a
  /// BEFORE UPDATE trigger, not by Dart** (03 §7) — a Dart guard is one
  /// repository method away from being bypassed, and a fostered lamb whose birth
  /// dam moved has lost the fact the two-dam model exists to keep.
  final int birthDam;
  final String? tag;
  final String? tagDigits;

  /// NULL = not recorded. `'unknown'` = the shepherd looked and could not tell.
  /// The Dart side models NULL as `Sex?`, **never as `Sex.unknown`** (R45).
  final String? sex;
  final int? birthWeightG;
  final String status;

  /// Civil date: the shepherd knows the day, not the minute. Forcing a time
  /// would invent precision the mortality buckets then over-claim.
  final LocalDate? deathDate;

  /// **Forward reference, deferred to N07-T06** (`VocabTerms`, `RESTRICT`).
  final String? deathCause;
  final bool petLamb;
  final int bottleFeeds;
  final String? notes;

  /// The retained lamb, promoted to the breeding flock (§7.0 row 13). NULL for
  /// every lamb that was not kept, which is nearly all of them.
  ///
  /// `setNull` and not `cascade`: deleting the ewe row must not delete the lamb
  /// she was, because the lamb is a record of a birth that happened.
  final int? becameEwe;
  const Lamb({
    required this.id,
    required this.uid,
    required this.createdAt,
    required this.updatedAt,
    required this.struck,
    this.struckAt,
    required this.lambing,
    required this.birthDam,
    this.tag,
    this.tagDigits,
    this.sex,
    this.birthWeightG,
    required this.status,
    this.deathDate,
    this.deathCause,
    required this.petLamb,
    required this.bottleFeeds,
    this.notes,
    this.becameEwe,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uid'] = Variable<String>(uid);
    {
      map['created_at'] = Variable<int>($LambsTable.$convertercreatedAt.toSql(createdAt));
    }
    {
      map['updated_at'] = Variable<int>($LambsTable.$converterupdatedAt.toSql(updatedAt));
    }
    map['struck'] = Variable<bool>(struck);
    if (!nullToAbsent || struckAt != null) {
      map['struck_at'] = Variable<int>($LambsTable.$converterstruckAtn.toSql(struckAt));
    }
    map['lambing'] = Variable<int>(lambing);
    map['birth_dam'] = Variable<int>(birthDam);
    if (!nullToAbsent || tag != null) {
      map['tag'] = Variable<String>(tag);
    }
    if (!nullToAbsent || tagDigits != null) {
      map['tag_digits'] = Variable<String>(tagDigits);
    }
    if (!nullToAbsent || sex != null) {
      map['sex'] = Variable<String>(sex);
    }
    if (!nullToAbsent || birthWeightG != null) {
      map['birth_weight_g'] = Variable<int>(birthWeightG);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || deathDate != null) {
      map['death_date'] = Variable<String>($LambsTable.$converterdeathDaten.toSql(deathDate));
    }
    if (!nullToAbsent || deathCause != null) {
      map['death_cause'] = Variable<String>(deathCause);
    }
    map['pet_lamb'] = Variable<bool>(petLamb);
    map['bottle_feeds'] = Variable<int>(bottleFeeds);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || becameEwe != null) {
      map['became_ewe'] = Variable<int>(becameEwe);
    }
    return map;
  }

  LambsCompanion toCompanion(bool nullToAbsent) {
    return LambsCompanion(
      id: Value(id),
      uid: Value(uid),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      struck: Value(struck),
      struckAt: struckAt == null && nullToAbsent ? const Value.absent() : Value(struckAt),
      lambing: Value(lambing),
      birthDam: Value(birthDam),
      tag: tag == null && nullToAbsent ? const Value.absent() : Value(tag),
      tagDigits: tagDigits == null && nullToAbsent ? const Value.absent() : Value(tagDigits),
      sex: sex == null && nullToAbsent ? const Value.absent() : Value(sex),
      birthWeightG: birthWeightG == null && nullToAbsent
          ? const Value.absent()
          : Value(birthWeightG),
      status: Value(status),
      deathDate: deathDate == null && nullToAbsent ? const Value.absent() : Value(deathDate),
      deathCause: deathCause == null && nullToAbsent ? const Value.absent() : Value(deathCause),
      petLamb: Value(petLamb),
      bottleFeeds: Value(bottleFeeds),
      notes: notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      becameEwe: becameEwe == null && nullToAbsent ? const Value.absent() : Value(becameEwe),
    );
  }

  factory Lamb.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Lamb(
      id: serializer.fromJson<int>(json['id']),
      uid: serializer.fromJson<String>(json['uid']),
      createdAt: serializer.fromJson<Instant>(json['createdAt']),
      updatedAt: serializer.fromJson<Instant>(json['updatedAt']),
      struck: serializer.fromJson<bool>(json['struck']),
      struckAt: serializer.fromJson<Instant?>(json['struckAt']),
      lambing: serializer.fromJson<int>(json['lambing']),
      birthDam: serializer.fromJson<int>(json['birthDam']),
      tag: serializer.fromJson<String?>(json['tag']),
      tagDigits: serializer.fromJson<String?>(json['tagDigits']),
      sex: serializer.fromJson<String?>(json['sex']),
      birthWeightG: serializer.fromJson<int?>(json['birthWeightG']),
      status: serializer.fromJson<String>(json['status']),
      deathDate: serializer.fromJson<LocalDate?>(json['deathDate']),
      deathCause: serializer.fromJson<String?>(json['deathCause']),
      petLamb: serializer.fromJson<bool>(json['petLamb']),
      bottleFeeds: serializer.fromJson<int>(json['bottleFeeds']),
      notes: serializer.fromJson<String?>(json['notes']),
      becameEwe: serializer.fromJson<int?>(json['becameEwe']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uid': serializer.toJson<String>(uid),
      'createdAt': serializer.toJson<Instant>(createdAt),
      'updatedAt': serializer.toJson<Instant>(updatedAt),
      'struck': serializer.toJson<bool>(struck),
      'struckAt': serializer.toJson<Instant?>(struckAt),
      'lambing': serializer.toJson<int>(lambing),
      'birthDam': serializer.toJson<int>(birthDam),
      'tag': serializer.toJson<String?>(tag),
      'tagDigits': serializer.toJson<String?>(tagDigits),
      'sex': serializer.toJson<String?>(sex),
      'birthWeightG': serializer.toJson<int?>(birthWeightG),
      'status': serializer.toJson<String>(status),
      'deathDate': serializer.toJson<LocalDate?>(deathDate),
      'deathCause': serializer.toJson<String?>(deathCause),
      'petLamb': serializer.toJson<bool>(petLamb),
      'bottleFeeds': serializer.toJson<int>(bottleFeeds),
      'notes': serializer.toJson<String?>(notes),
      'becameEwe': serializer.toJson<int?>(becameEwe),
    };
  }

  Lamb copyWith({
    int? id,
    String? uid,
    Instant? createdAt,
    Instant? updatedAt,
    bool? struck,
    Value<Instant?> struckAt = const Value.absent(),
    int? lambing,
    int? birthDam,
    Value<String?> tag = const Value.absent(),
    Value<String?> tagDigits = const Value.absent(),
    Value<String?> sex = const Value.absent(),
    Value<int?> birthWeightG = const Value.absent(),
    String? status,
    Value<LocalDate?> deathDate = const Value.absent(),
    Value<String?> deathCause = const Value.absent(),
    bool? petLamb,
    int? bottleFeeds,
    Value<String?> notes = const Value.absent(),
    Value<int?> becameEwe = const Value.absent(),
  }) => Lamb(
    id: id ?? this.id,
    uid: uid ?? this.uid,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    struck: struck ?? this.struck,
    struckAt: struckAt.present ? struckAt.value : this.struckAt,
    lambing: lambing ?? this.lambing,
    birthDam: birthDam ?? this.birthDam,
    tag: tag.present ? tag.value : this.tag,
    tagDigits: tagDigits.present ? tagDigits.value : this.tagDigits,
    sex: sex.present ? sex.value : this.sex,
    birthWeightG: birthWeightG.present ? birthWeightG.value : this.birthWeightG,
    status: status ?? this.status,
    deathDate: deathDate.present ? deathDate.value : this.deathDate,
    deathCause: deathCause.present ? deathCause.value : this.deathCause,
    petLamb: petLamb ?? this.petLamb,
    bottleFeeds: bottleFeeds ?? this.bottleFeeds,
    notes: notes.present ? notes.value : this.notes,
    becameEwe: becameEwe.present ? becameEwe.value : this.becameEwe,
  );
  Lamb copyWithCompanion(LambsCompanion data) {
    return Lamb(
      id: data.id.present ? data.id.value : this.id,
      uid: data.uid.present ? data.uid.value : this.uid,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      struck: data.struck.present ? data.struck.value : this.struck,
      struckAt: data.struckAt.present ? data.struckAt.value : this.struckAt,
      lambing: data.lambing.present ? data.lambing.value : this.lambing,
      birthDam: data.birthDam.present ? data.birthDam.value : this.birthDam,
      tag: data.tag.present ? data.tag.value : this.tag,
      tagDigits: data.tagDigits.present ? data.tagDigits.value : this.tagDigits,
      sex: data.sex.present ? data.sex.value : this.sex,
      birthWeightG: data.birthWeightG.present ? data.birthWeightG.value : this.birthWeightG,
      status: data.status.present ? data.status.value : this.status,
      deathDate: data.deathDate.present ? data.deathDate.value : this.deathDate,
      deathCause: data.deathCause.present ? data.deathCause.value : this.deathCause,
      petLamb: data.petLamb.present ? data.petLamb.value : this.petLamb,
      bottleFeeds: data.bottleFeeds.present ? data.bottleFeeds.value : this.bottleFeeds,
      notes: data.notes.present ? data.notes.value : this.notes,
      becameEwe: data.becameEwe.present ? data.becameEwe.value : this.becameEwe,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Lamb(')
          ..write('id: $id, ')
          ..write('uid: $uid, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('struck: $struck, ')
          ..write('struckAt: $struckAt, ')
          ..write('lambing: $lambing, ')
          ..write('birthDam: $birthDam, ')
          ..write('tag: $tag, ')
          ..write('tagDigits: $tagDigits, ')
          ..write('sex: $sex, ')
          ..write('birthWeightG: $birthWeightG, ')
          ..write('status: $status, ')
          ..write('deathDate: $deathDate, ')
          ..write('deathCause: $deathCause, ')
          ..write('petLamb: $petLamb, ')
          ..write('bottleFeeds: $bottleFeeds, ')
          ..write('notes: $notes, ')
          ..write('becameEwe: $becameEwe')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    uid,
    createdAt,
    updatedAt,
    struck,
    struckAt,
    lambing,
    birthDam,
    tag,
    tagDigits,
    sex,
    birthWeightG,
    status,
    deathDate,
    deathCause,
    petLamb,
    bottleFeeds,
    notes,
    becameEwe,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Lamb &&
          other.id == this.id &&
          other.uid == this.uid &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.struck == this.struck &&
          other.struckAt == this.struckAt &&
          other.lambing == this.lambing &&
          other.birthDam == this.birthDam &&
          other.tag == this.tag &&
          other.tagDigits == this.tagDigits &&
          other.sex == this.sex &&
          other.birthWeightG == this.birthWeightG &&
          other.status == this.status &&
          other.deathDate == this.deathDate &&
          other.deathCause == this.deathCause &&
          other.petLamb == this.petLamb &&
          other.bottleFeeds == this.bottleFeeds &&
          other.notes == this.notes &&
          other.becameEwe == this.becameEwe);
}

class LambsCompanion extends UpdateCompanion<Lamb> {
  final Value<int> id;
  final Value<String> uid;
  final Value<Instant> createdAt;
  final Value<Instant> updatedAt;
  final Value<bool> struck;
  final Value<Instant?> struckAt;
  final Value<int> lambing;
  final Value<int> birthDam;
  final Value<String?> tag;
  final Value<String?> tagDigits;
  final Value<String?> sex;
  final Value<int?> birthWeightG;
  final Value<String> status;
  final Value<LocalDate?> deathDate;
  final Value<String?> deathCause;
  final Value<bool> petLamb;
  final Value<int> bottleFeeds;
  final Value<String?> notes;
  final Value<int?> becameEwe;
  const LambsCompanion({
    this.id = const Value.absent(),
    this.uid = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.struck = const Value.absent(),
    this.struckAt = const Value.absent(),
    this.lambing = const Value.absent(),
    this.birthDam = const Value.absent(),
    this.tag = const Value.absent(),
    this.tagDigits = const Value.absent(),
    this.sex = const Value.absent(),
    this.birthWeightG = const Value.absent(),
    this.status = const Value.absent(),
    this.deathDate = const Value.absent(),
    this.deathCause = const Value.absent(),
    this.petLamb = const Value.absent(),
    this.bottleFeeds = const Value.absent(),
    this.notes = const Value.absent(),
    this.becameEwe = const Value.absent(),
  });
  LambsCompanion.insert({
    this.id = const Value.absent(),
    required String uid,
    required Instant createdAt,
    required Instant updatedAt,
    this.struck = const Value.absent(),
    this.struckAt = const Value.absent(),
    required int lambing,
    required int birthDam,
    this.tag = const Value.absent(),
    this.tagDigits = const Value.absent(),
    this.sex = const Value.absent(),
    this.birthWeightG = const Value.absent(),
    this.status = const Value.absent(),
    this.deathDate = const Value.absent(),
    this.deathCause = const Value.absent(),
    this.petLamb = const Value.absent(),
    this.bottleFeeds = const Value.absent(),
    this.notes = const Value.absent(),
    this.becameEwe = const Value.absent(),
  }) : uid = Value(uid),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       lambing = Value(lambing),
       birthDam = Value(birthDam);
  static Insertable<Lamb> custom({
    Expression<int>? id,
    Expression<String>? uid,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<bool>? struck,
    Expression<int>? struckAt,
    Expression<int>? lambing,
    Expression<int>? birthDam,
    Expression<String>? tag,
    Expression<String>? tagDigits,
    Expression<String>? sex,
    Expression<int>? birthWeightG,
    Expression<String>? status,
    Expression<String>? deathDate,
    Expression<String>? deathCause,
    Expression<bool>? petLamb,
    Expression<int>? bottleFeeds,
    Expression<String>? notes,
    Expression<int>? becameEwe,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uid != null) 'uid': uid,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (struck != null) 'struck': struck,
      if (struckAt != null) 'struck_at': struckAt,
      if (lambing != null) 'lambing': lambing,
      if (birthDam != null) 'birth_dam': birthDam,
      if (tag != null) 'tag': tag,
      if (tagDigits != null) 'tag_digits': tagDigits,
      if (sex != null) 'sex': sex,
      if (birthWeightG != null) 'birth_weight_g': birthWeightG,
      if (status != null) 'status': status,
      if (deathDate != null) 'death_date': deathDate,
      if (deathCause != null) 'death_cause': deathCause,
      if (petLamb != null) 'pet_lamb': petLamb,
      if (bottleFeeds != null) 'bottle_feeds': bottleFeeds,
      if (notes != null) 'notes': notes,
      if (becameEwe != null) 'became_ewe': becameEwe,
    });
  }

  LambsCompanion copyWith({
    Value<int>? id,
    Value<String>? uid,
    Value<Instant>? createdAt,
    Value<Instant>? updatedAt,
    Value<bool>? struck,
    Value<Instant?>? struckAt,
    Value<int>? lambing,
    Value<int>? birthDam,
    Value<String?>? tag,
    Value<String?>? tagDigits,
    Value<String?>? sex,
    Value<int?>? birthWeightG,
    Value<String>? status,
    Value<LocalDate?>? deathDate,
    Value<String?>? deathCause,
    Value<bool>? petLamb,
    Value<int>? bottleFeeds,
    Value<String?>? notes,
    Value<int?>? becameEwe,
  }) {
    return LambsCompanion(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      struck: struck ?? this.struck,
      struckAt: struckAt ?? this.struckAt,
      lambing: lambing ?? this.lambing,
      birthDam: birthDam ?? this.birthDam,
      tag: tag ?? this.tag,
      tagDigits: tagDigits ?? this.tagDigits,
      sex: sex ?? this.sex,
      birthWeightG: birthWeightG ?? this.birthWeightG,
      status: status ?? this.status,
      deathDate: deathDate ?? this.deathDate,
      deathCause: deathCause ?? this.deathCause,
      petLamb: petLamb ?? this.petLamb,
      bottleFeeds: bottleFeeds ?? this.bottleFeeds,
      notes: notes ?? this.notes,
      becameEwe: becameEwe ?? this.becameEwe,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uid.present) {
      map['uid'] = Variable<String>(uid.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>($LambsTable.$convertercreatedAt.toSql(createdAt.value));
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>($LambsTable.$converterupdatedAt.toSql(updatedAt.value));
    }
    if (struck.present) {
      map['struck'] = Variable<bool>(struck.value);
    }
    if (struckAt.present) {
      map['struck_at'] = Variable<int>($LambsTable.$converterstruckAtn.toSql(struckAt.value));
    }
    if (lambing.present) {
      map['lambing'] = Variable<int>(lambing.value);
    }
    if (birthDam.present) {
      map['birth_dam'] = Variable<int>(birthDam.value);
    }
    if (tag.present) {
      map['tag'] = Variable<String>(tag.value);
    }
    if (tagDigits.present) {
      map['tag_digits'] = Variable<String>(tagDigits.value);
    }
    if (sex.present) {
      map['sex'] = Variable<String>(sex.value);
    }
    if (birthWeightG.present) {
      map['birth_weight_g'] = Variable<int>(birthWeightG.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (deathDate.present) {
      map['death_date'] = Variable<String>($LambsTable.$converterdeathDaten.toSql(deathDate.value));
    }
    if (deathCause.present) {
      map['death_cause'] = Variable<String>(deathCause.value);
    }
    if (petLamb.present) {
      map['pet_lamb'] = Variable<bool>(petLamb.value);
    }
    if (bottleFeeds.present) {
      map['bottle_feeds'] = Variable<int>(bottleFeeds.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (becameEwe.present) {
      map['became_ewe'] = Variable<int>(becameEwe.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LambsCompanion(')
          ..write('id: $id, ')
          ..write('uid: $uid, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('struck: $struck, ')
          ..write('struckAt: $struckAt, ')
          ..write('lambing: $lambing, ')
          ..write('birthDam: $birthDam, ')
          ..write('tag: $tag, ')
          ..write('tagDigits: $tagDigits, ')
          ..write('sex: $sex, ')
          ..write('birthWeightG: $birthWeightG, ')
          ..write('status: $status, ')
          ..write('deathDate: $deathDate, ')
          ..write('deathCause: $deathCause, ')
          ..write('petLamb: $petLamb, ')
          ..write('bottleFeeds: $bottleFeeds, ')
          ..write('notes: $notes, ')
          ..write('becameEwe: $becameEwe')
          ..write(')'))
        .toString();
  }
}

class $EweSeasonsTable extends EweSeasons with TableInfo<$EweSeasonsTable, EweSeason> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EweSeasonsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<String> uid = GeneratedColumn<String>(
    'uid',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 36, maxTextLength: 36),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Instant, int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  ).withConverter<Instant>($EweSeasonsTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<Instant, int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  ).withConverter<Instant>($EweSeasonsTable.$converterupdatedAt);
  static const VerificationMeta _struckMeta = const VerificationMeta('struck');
  @override
  late final GeneratedColumn<bool> struck = GeneratedColumn<bool>(
    'struck',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("struck" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Instant?, int> struckAt = GeneratedColumn<int>(
    'struck_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  ).withConverter<Instant?>($EweSeasonsTable.$converterstruckAtn);
  static const VerificationMeta _seasonMeta = const VerificationMeta('season');
  @override
  late final GeneratedColumn<int> season = GeneratedColumn<int>(
    'season',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES seasons (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _eweMeta = const VerificationMeta('ewe');
  @override
  late final GeneratedColumn<int> ewe = GeneratedColumn<int>(
    'ewe',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES ewes (id) ON DELETE CASCADE',
    ),
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
  static const VerificationMeta _scannedCountMeta = const VerificationMeta('scannedCount');
  @override
  late final GeneratedColumn<int> scannedCount = GeneratedColumn<int>(
    'scanned_count',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uid,
    createdAt,
    updatedAt,
    struck,
    struckAt,
    season,
    ewe,
    status,
    scannedCount,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ewe_seasons';
  @override
  VerificationContext validateIntegrity(
    Insertable<EweSeason> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uid')) {
      context.handle(_uidMeta, uid.isAcceptableOrUnknown(data['uid']!, _uidMeta));
    } else if (isInserting) {
      context.missing(_uidMeta);
    }
    if (data.containsKey('struck')) {
      context.handle(_struckMeta, struck.isAcceptableOrUnknown(data['struck']!, _struckMeta));
    }
    if (data.containsKey('season')) {
      context.handle(_seasonMeta, season.isAcceptableOrUnknown(data['season']!, _seasonMeta));
    } else if (isInserting) {
      context.missing(_seasonMeta);
    }
    if (data.containsKey('ewe')) {
      context.handle(_eweMeta, ewe.isAcceptableOrUnknown(data['ewe']!, _eweMeta));
    } else if (isInserting) {
      context.missing(_eweMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta, status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('scanned_count')) {
      context.handle(
        _scannedCountMeta,
        scannedCount.isAcceptableOrUnknown(data['scanned_count']!, _scannedCountMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(_notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {season, ewe},
  ];
  @override
  EweSeason map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EweSeason(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      uid: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}uid'])!,
      createdAt: $EweSeasonsTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      ),
      updatedAt: $EweSeasonsTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
      ),
      struck: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}struck'],
      )!,
      struckAt: $EweSeasonsTable.$converterstruckAtn.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}struck_at']),
      ),
      season: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}season'],
      )!,
      ewe: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}ewe'])!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      scannedCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}scanned_count'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
    );
  }

  @override
  $EweSeasonsTable createAlias(String alias) {
    return $EweSeasonsTable(attachedDatabase, alias);
  }

  static TypeConverter<Instant, int> $convertercreatedAt = const InstantConverter();
  static TypeConverter<Instant, int> $converterupdatedAt = const InstantConverter();
  static TypeConverter<Instant, int> $converterstruckAt = const InstantConverter();
  static TypeConverter<Instant?, int?> $converterstruckAtn = NullAwareTypeConverter.wrap(
    $converterstruckAt,
  );
  @override
  bool get isStrict => true;
}

class EweSeason extends DataClass implements Insertable<EweSeason> {
  /// Joins and foreign keys. Device-local. **NEVER exported** (03 §3): a row id
  /// means nothing on another phone, and exporting one invites a restore that
  /// tries to honour it.
  final int id;

  /// UUID v7. The identity that survives export → re-import.
  final String uid;

  /// Instants: UTC epoch millis (§4).
  final Instant createdAt;
  final Instant updatedAt;

  /// Under `STRICT` there is no `BOOLEAN`, hence the first CHECK above.
  ///
  /// The default is **not** a violation of 03 §2 point 5: that rule bans
  /// defaults on columns that could encode veterinary advice — `days`, `ease`,
  /// `status` — and an unstruck row is the only thing a new row can be.
  final bool struck;

  /// An [Instant], not a civil date: a strike happened at a moment, and that is
  /// what makes one recorded at 01:30 on the clocks-back night unambiguous.
  final Instant? struckAt;
  final int season;
  final int ewe;

  /// **NO DEFAULT.** Defaulting to `'to_ram'` would silently assert a ewe was
  /// put to the ram, which is the denominator of a commercially sensitive
  /// number (decision #59). Every writer knows which status it is asserting.
  final String status;
  final int? scannedCount;
  final String? notes;
  const EweSeason({
    required this.id,
    required this.uid,
    required this.createdAt,
    required this.updatedAt,
    required this.struck,
    this.struckAt,
    required this.season,
    required this.ewe,
    required this.status,
    this.scannedCount,
    this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uid'] = Variable<String>(uid);
    {
      map['created_at'] = Variable<int>($EweSeasonsTable.$convertercreatedAt.toSql(createdAt));
    }
    {
      map['updated_at'] = Variable<int>($EweSeasonsTable.$converterupdatedAt.toSql(updatedAt));
    }
    map['struck'] = Variable<bool>(struck);
    if (!nullToAbsent || struckAt != null) {
      map['struck_at'] = Variable<int>($EweSeasonsTable.$converterstruckAtn.toSql(struckAt));
    }
    map['season'] = Variable<int>(season);
    map['ewe'] = Variable<int>(ewe);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || scannedCount != null) {
      map['scanned_count'] = Variable<int>(scannedCount);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  EweSeasonsCompanion toCompanion(bool nullToAbsent) {
    return EweSeasonsCompanion(
      id: Value(id),
      uid: Value(uid),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      struck: Value(struck),
      struckAt: struckAt == null && nullToAbsent ? const Value.absent() : Value(struckAt),
      season: Value(season),
      ewe: Value(ewe),
      status: Value(status),
      scannedCount: scannedCount == null && nullToAbsent
          ? const Value.absent()
          : Value(scannedCount),
      notes: notes == null && nullToAbsent ? const Value.absent() : Value(notes),
    );
  }

  factory EweSeason.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EweSeason(
      id: serializer.fromJson<int>(json['id']),
      uid: serializer.fromJson<String>(json['uid']),
      createdAt: serializer.fromJson<Instant>(json['createdAt']),
      updatedAt: serializer.fromJson<Instant>(json['updatedAt']),
      struck: serializer.fromJson<bool>(json['struck']),
      struckAt: serializer.fromJson<Instant?>(json['struckAt']),
      season: serializer.fromJson<int>(json['season']),
      ewe: serializer.fromJson<int>(json['ewe']),
      status: serializer.fromJson<String>(json['status']),
      scannedCount: serializer.fromJson<int?>(json['scannedCount']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uid': serializer.toJson<String>(uid),
      'createdAt': serializer.toJson<Instant>(createdAt),
      'updatedAt': serializer.toJson<Instant>(updatedAt),
      'struck': serializer.toJson<bool>(struck),
      'struckAt': serializer.toJson<Instant?>(struckAt),
      'season': serializer.toJson<int>(season),
      'ewe': serializer.toJson<int>(ewe),
      'status': serializer.toJson<String>(status),
      'scannedCount': serializer.toJson<int?>(scannedCount),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  EweSeason copyWith({
    int? id,
    String? uid,
    Instant? createdAt,
    Instant? updatedAt,
    bool? struck,
    Value<Instant?> struckAt = const Value.absent(),
    int? season,
    int? ewe,
    String? status,
    Value<int?> scannedCount = const Value.absent(),
    Value<String?> notes = const Value.absent(),
  }) => EweSeason(
    id: id ?? this.id,
    uid: uid ?? this.uid,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    struck: struck ?? this.struck,
    struckAt: struckAt.present ? struckAt.value : this.struckAt,
    season: season ?? this.season,
    ewe: ewe ?? this.ewe,
    status: status ?? this.status,
    scannedCount: scannedCount.present ? scannedCount.value : this.scannedCount,
    notes: notes.present ? notes.value : this.notes,
  );
  EweSeason copyWithCompanion(EweSeasonsCompanion data) {
    return EweSeason(
      id: data.id.present ? data.id.value : this.id,
      uid: data.uid.present ? data.uid.value : this.uid,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      struck: data.struck.present ? data.struck.value : this.struck,
      struckAt: data.struckAt.present ? data.struckAt.value : this.struckAt,
      season: data.season.present ? data.season.value : this.season,
      ewe: data.ewe.present ? data.ewe.value : this.ewe,
      status: data.status.present ? data.status.value : this.status,
      scannedCount: data.scannedCount.present ? data.scannedCount.value : this.scannedCount,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EweSeason(')
          ..write('id: $id, ')
          ..write('uid: $uid, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('struck: $struck, ')
          ..write('struckAt: $struckAt, ')
          ..write('season: $season, ')
          ..write('ewe: $ewe, ')
          ..write('status: $status, ')
          ..write('scannedCount: $scannedCount, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    uid,
    createdAt,
    updatedAt,
    struck,
    struckAt,
    season,
    ewe,
    status,
    scannedCount,
    notes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EweSeason &&
          other.id == this.id &&
          other.uid == this.uid &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.struck == this.struck &&
          other.struckAt == this.struckAt &&
          other.season == this.season &&
          other.ewe == this.ewe &&
          other.status == this.status &&
          other.scannedCount == this.scannedCount &&
          other.notes == this.notes);
}

class EweSeasonsCompanion extends UpdateCompanion<EweSeason> {
  final Value<int> id;
  final Value<String> uid;
  final Value<Instant> createdAt;
  final Value<Instant> updatedAt;
  final Value<bool> struck;
  final Value<Instant?> struckAt;
  final Value<int> season;
  final Value<int> ewe;
  final Value<String> status;
  final Value<int?> scannedCount;
  final Value<String?> notes;
  const EweSeasonsCompanion({
    this.id = const Value.absent(),
    this.uid = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.struck = const Value.absent(),
    this.struckAt = const Value.absent(),
    this.season = const Value.absent(),
    this.ewe = const Value.absent(),
    this.status = const Value.absent(),
    this.scannedCount = const Value.absent(),
    this.notes = const Value.absent(),
  });
  EweSeasonsCompanion.insert({
    this.id = const Value.absent(),
    required String uid,
    required Instant createdAt,
    required Instant updatedAt,
    this.struck = const Value.absent(),
    this.struckAt = const Value.absent(),
    required int season,
    required int ewe,
    required String status,
    this.scannedCount = const Value.absent(),
    this.notes = const Value.absent(),
  }) : uid = Value(uid),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       season = Value(season),
       ewe = Value(ewe),
       status = Value(status);
  static Insertable<EweSeason> custom({
    Expression<int>? id,
    Expression<String>? uid,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<bool>? struck,
    Expression<int>? struckAt,
    Expression<int>? season,
    Expression<int>? ewe,
    Expression<String>? status,
    Expression<int>? scannedCount,
    Expression<String>? notes,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uid != null) 'uid': uid,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (struck != null) 'struck': struck,
      if (struckAt != null) 'struck_at': struckAt,
      if (season != null) 'season': season,
      if (ewe != null) 'ewe': ewe,
      if (status != null) 'status': status,
      if (scannedCount != null) 'scanned_count': scannedCount,
      if (notes != null) 'notes': notes,
    });
  }

  EweSeasonsCompanion copyWith({
    Value<int>? id,
    Value<String>? uid,
    Value<Instant>? createdAt,
    Value<Instant>? updatedAt,
    Value<bool>? struck,
    Value<Instant?>? struckAt,
    Value<int>? season,
    Value<int>? ewe,
    Value<String>? status,
    Value<int?>? scannedCount,
    Value<String?>? notes,
  }) {
    return EweSeasonsCompanion(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      struck: struck ?? this.struck,
      struckAt: struckAt ?? this.struckAt,
      season: season ?? this.season,
      ewe: ewe ?? this.ewe,
      status: status ?? this.status,
      scannedCount: scannedCount ?? this.scannedCount,
      notes: notes ?? this.notes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uid.present) {
      map['uid'] = Variable<String>(uid.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
        $EweSeasonsTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(
        $EweSeasonsTable.$converterupdatedAt.toSql(updatedAt.value),
      );
    }
    if (struck.present) {
      map['struck'] = Variable<bool>(struck.value);
    }
    if (struckAt.present) {
      map['struck_at'] = Variable<int>($EweSeasonsTable.$converterstruckAtn.toSql(struckAt.value));
    }
    if (season.present) {
      map['season'] = Variable<int>(season.value);
    }
    if (ewe.present) {
      map['ewe'] = Variable<int>(ewe.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (scannedCount.present) {
      map['scanned_count'] = Variable<int>(scannedCount.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EweSeasonsCompanion(')
          ..write('id: $id, ')
          ..write('uid: $uid, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('struck: $struck, ')
          ..write('struckAt: $struckAt, ')
          ..write('season: $season, ')
          ..write('ewe: $ewe, ')
          ..write('status: $status, ')
          ..write('scannedCount: $scannedCount, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }
}

class $EweTouchesTable extends EweTouches with TableInfo<$EweTouchesTable, EweTouch> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EweTouchesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _eweMeta = const VerificationMeta('ewe');
  @override
  late final GeneratedColumn<int> ewe = GeneratedColumn<int>(
    'ewe',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES ewes (id) ON DELETE CASCADE',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Instant, int> touchedAt = GeneratedColumn<int>(
    'touched_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  ).withConverter<Instant>($EweTouchesTable.$convertertouchedAt);
  @override
  List<GeneratedColumn> get $columns => [ewe, touchedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ewe_touches';
  @override
  VerificationContext validateIntegrity(Insertable<EweTouch> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('ewe')) {
      context.handle(_eweMeta, ewe.isAcceptableOrUnknown(data['ewe']!, _eweMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {ewe};
  @override
  EweTouch map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EweTouch(
      ewe: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}ewe'])!,
      touchedAt: $EweTouchesTable.$convertertouchedAt.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}touched_at'])!,
      ),
    );
  }

  @override
  $EweTouchesTable createAlias(String alias) {
    return $EweTouchesTable(attachedDatabase, alias);
  }

  static TypeConverter<Instant, int> $convertertouchedAt = const InstantConverter();
  @override
  bool get isStrict => true;
}

class EweTouch extends DataClass implements Insertable<EweTouch> {
  final int ewe;
  final Instant touchedAt;
  const EweTouch({required this.ewe, required this.touchedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['ewe'] = Variable<int>(ewe);
    {
      map['touched_at'] = Variable<int>($EweTouchesTable.$convertertouchedAt.toSql(touchedAt));
    }
    return map;
  }

  EweTouchesCompanion toCompanion(bool nullToAbsent) {
    return EweTouchesCompanion(ewe: Value(ewe), touchedAt: Value(touchedAt));
  }

  factory EweTouch.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EweTouch(
      ewe: serializer.fromJson<int>(json['ewe']),
      touchedAt: serializer.fromJson<Instant>(json['touchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'ewe': serializer.toJson<int>(ewe),
      'touchedAt': serializer.toJson<Instant>(touchedAt),
    };
  }

  EweTouch copyWith({int? ewe, Instant? touchedAt}) =>
      EweTouch(ewe: ewe ?? this.ewe, touchedAt: touchedAt ?? this.touchedAt);
  EweTouch copyWithCompanion(EweTouchesCompanion data) {
    return EweTouch(
      ewe: data.ewe.present ? data.ewe.value : this.ewe,
      touchedAt: data.touchedAt.present ? data.touchedAt.value : this.touchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EweTouch(')
          ..write('ewe: $ewe, ')
          ..write('touchedAt: $touchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(ewe, touchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EweTouch && other.ewe == this.ewe && other.touchedAt == this.touchedAt);
}

class EweTouchesCompanion extends UpdateCompanion<EweTouch> {
  final Value<int> ewe;
  final Value<Instant> touchedAt;
  const EweTouchesCompanion({
    this.ewe = const Value.absent(),
    this.touchedAt = const Value.absent(),
  });
  EweTouchesCompanion.insert({this.ewe = const Value.absent(), required Instant touchedAt})
    : touchedAt = Value(touchedAt);
  static Insertable<EweTouch> custom({Expression<int>? ewe, Expression<int>? touchedAt}) {
    return RawValuesInsertable({
      if (ewe != null) 'ewe': ewe,
      if (touchedAt != null) 'touched_at': touchedAt,
    });
  }

  EweTouchesCompanion copyWith({Value<int>? ewe, Value<Instant>? touchedAt}) {
    return EweTouchesCompanion(ewe: ewe ?? this.ewe, touchedAt: touchedAt ?? this.touchedAt);
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (ewe.present) {
      map['ewe'] = Variable<int>(ewe.value);
    }
    if (touchedAt.present) {
      map['touched_at'] = Variable<int>(
        $EweTouchesTable.$convertertouchedAt.toSql(touchedAt.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EweTouchesCompanion(')
          ..write('ewe: $ewe, ')
          ..write('touchedAt: $touchedAt')
          ..write(')'))
        .toString();
  }
}

class $EweObservationsTable extends EweObservations
    with TableInfo<$EweObservationsTable, EweObservation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EweObservationsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<String> uid = GeneratedColumn<String>(
    'uid',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 36, maxTextLength: 36),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Instant, int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  ).withConverter<Instant>($EweObservationsTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<Instant, int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  ).withConverter<Instant>($EweObservationsTable.$converterupdatedAt);
  static const VerificationMeta _struckMeta = const VerificationMeta('struck');
  @override
  late final GeneratedColumn<bool> struck = GeneratedColumn<bool>(
    'struck',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("struck" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Instant?, int> struckAt = GeneratedColumn<int>(
    'struck_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  ).withConverter<Instant?>($EweObservationsTable.$converterstruckAtn);
  static const VerificationMeta _eweMeta = const VerificationMeta('ewe');
  @override
  late final GeneratedColumn<int> ewe = GeneratedColumn<int>(
    'ewe',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES ewes (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _seasonMeta = const VerificationMeta('season');
  @override
  late final GeneratedColumn<int> season = GeneratedColumn<int>(
    'season',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES seasons (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _lambingMeta = const VerificationMeta('lambing');
  @override
  late final GeneratedColumn<int> lambing = GeneratedColumn<int>(
    'lambing',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES lambings (id) ON DELETE SET NULL',
    ),
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
  @override
  late final GeneratedColumnWithTypeConverter<Instant, int> occurredAt = GeneratedColumn<int>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  ).withConverter<Instant>($EweObservationsTable.$converteroccurredAt);
  @override
  late final GeneratedColumnWithTypeConverter<Instant, int> capturedAt = GeneratedColumn<int>(
    'captured_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  ).withConverter<Instant>($EweObservationsTable.$convertercapturedAt);
  @override
  late final GeneratedColumnWithTypeConverter<Instant?, int> originalEffective =
      GeneratedColumn<int>(
        'original_effective',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<Instant?>($EweObservationsTable.$converteroriginalEffectiven);
  static const VerificationMeta _timeSourceMeta = const VerificationMeta('timeSource');
  @override
  late final GeneratedColumn<String> timeSource = GeneratedColumn<String>(
    'time_source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('auto'),
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uid,
    createdAt,
    updatedAt,
    struck,
    struckAt,
    ewe,
    season,
    lambing,
    kind,
    occurredAt,
    capturedAt,
    originalEffective,
    timeSource,
    note,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ewe_observations';
  @override
  VerificationContext validateIntegrity(
    Insertable<EweObservation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uid')) {
      context.handle(_uidMeta, uid.isAcceptableOrUnknown(data['uid']!, _uidMeta));
    } else if (isInserting) {
      context.missing(_uidMeta);
    }
    if (data.containsKey('struck')) {
      context.handle(_struckMeta, struck.isAcceptableOrUnknown(data['struck']!, _struckMeta));
    }
    if (data.containsKey('ewe')) {
      context.handle(_eweMeta, ewe.isAcceptableOrUnknown(data['ewe']!, _eweMeta));
    } else if (isInserting) {
      context.missing(_eweMeta);
    }
    if (data.containsKey('season')) {
      context.handle(_seasonMeta, season.isAcceptableOrUnknown(data['season']!, _seasonMeta));
    } else if (isInserting) {
      context.missing(_seasonMeta);
    }
    if (data.containsKey('lambing')) {
      context.handle(_lambingMeta, lambing.isAcceptableOrUnknown(data['lambing']!, _lambingMeta));
    }
    if (data.containsKey('kind')) {
      context.handle(_kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('time_source')) {
      context.handle(
        _timeSourceMeta,
        timeSource.isAcceptableOrUnknown(data['time_source']!, _timeSourceMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(_noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EweObservation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EweObservation(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      uid: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}uid'])!,
      createdAt: $EweObservationsTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      ),
      updatedAt: $EweObservationsTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
      ),
      struck: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}struck'],
      )!,
      struckAt: $EweObservationsTable.$converterstruckAtn.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}struck_at']),
      ),
      ewe: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}ewe'])!,
      season: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}season'],
      )!,
      lambing: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lambing'],
      ),
      kind: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      occurredAt: $EweObservationsTable.$converteroccurredAt.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}occurred_at'])!,
      ),
      capturedAt: $EweObservationsTable.$convertercapturedAt.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}captured_at'])!,
      ),
      originalEffective: $EweObservationsTable.$converteroriginalEffectiven.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}original_effective'],
        ),
      ),
      timeSource: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}time_source'],
      )!,
      note: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}note']),
    );
  }

  @override
  $EweObservationsTable createAlias(String alias) {
    return $EweObservationsTable(attachedDatabase, alias);
  }

  static TypeConverter<Instant, int> $convertercreatedAt = const InstantConverter();
  static TypeConverter<Instant, int> $converterupdatedAt = const InstantConverter();
  static TypeConverter<Instant, int> $converterstruckAt = const InstantConverter();
  static TypeConverter<Instant?, int?> $converterstruckAtn = NullAwareTypeConverter.wrap(
    $converterstruckAt,
  );
  static TypeConverter<Instant, int> $converteroccurredAt = const InstantConverter();
  static TypeConverter<Instant, int> $convertercapturedAt = const InstantConverter();
  static TypeConverter<Instant, int> $converteroriginalEffective = const InstantConverter();
  static TypeConverter<Instant?, int?> $converteroriginalEffectiven = NullAwareTypeConverter.wrap(
    $converteroriginalEffective,
  );
  @override
  bool get isStrict => true;
}

class EweObservation extends DataClass implements Insertable<EweObservation> {
  /// Joins and foreign keys. Device-local. **NEVER exported** (03 §3): a row id
  /// means nothing on another phone, and exporting one invites a restore that
  /// tries to honour it.
  final int id;

  /// UUID v7. The identity that survives export → re-import.
  final String uid;

  /// Instants: UTC epoch millis (§4).
  final Instant createdAt;
  final Instant updatedAt;

  /// Under `STRICT` there is no `BOOLEAN`, hence the first CHECK above.
  ///
  /// The default is **not** a violation of 03 §2 point 5: that rule bans
  /// defaults on columns that could encode veterinary advice — `days`, `ease`,
  /// `status` — and an unstruck row is the only thing a new row can be.
  final bool struck;

  /// An [Instant], not a civil date: a strike happened at a moment, and that is
  /// what makes one recorded at 01:30 on the clocks-back night unambiguous.
  final Instant? struckAt;
  final int ewe;
  final int season;

  /// `setNull`: an observation outlives the lambing it was noticed at.
  final int? lambing;

  /// **Forward reference, deferred to N07-T06.** A user-editable vocabulary is a
  /// foreign key, never a `CHECK` (convention 6), and `VocabTerms` lands in T06:
  /// `.references(VocabTerms, #key, onDelete: KeyAction.restrict)`.
  final String kind;
  final Instant occurredAt;
  final Instant capturedAt;
  final Instant? originalEffective;
  final String timeSource;
  final String? note;
  const EweObservation({
    required this.id,
    required this.uid,
    required this.createdAt,
    required this.updatedAt,
    required this.struck,
    this.struckAt,
    required this.ewe,
    required this.season,
    this.lambing,
    required this.kind,
    required this.occurredAt,
    required this.capturedAt,
    this.originalEffective,
    required this.timeSource,
    this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uid'] = Variable<String>(uid);
    {
      map['created_at'] = Variable<int>($EweObservationsTable.$convertercreatedAt.toSql(createdAt));
    }
    {
      map['updated_at'] = Variable<int>($EweObservationsTable.$converterupdatedAt.toSql(updatedAt));
    }
    map['struck'] = Variable<bool>(struck);
    if (!nullToAbsent || struckAt != null) {
      map['struck_at'] = Variable<int>($EweObservationsTable.$converterstruckAtn.toSql(struckAt));
    }
    map['ewe'] = Variable<int>(ewe);
    map['season'] = Variable<int>(season);
    if (!nullToAbsent || lambing != null) {
      map['lambing'] = Variable<int>(lambing);
    }
    map['kind'] = Variable<String>(kind);
    {
      map['occurred_at'] = Variable<int>(
        $EweObservationsTable.$converteroccurredAt.toSql(occurredAt),
      );
    }
    {
      map['captured_at'] = Variable<int>(
        $EweObservationsTable.$convertercapturedAt.toSql(capturedAt),
      );
    }
    if (!nullToAbsent || originalEffective != null) {
      map['original_effective'] = Variable<int>(
        $EweObservationsTable.$converteroriginalEffectiven.toSql(originalEffective),
      );
    }
    map['time_source'] = Variable<String>(timeSource);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  EweObservationsCompanion toCompanion(bool nullToAbsent) {
    return EweObservationsCompanion(
      id: Value(id),
      uid: Value(uid),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      struck: Value(struck),
      struckAt: struckAt == null && nullToAbsent ? const Value.absent() : Value(struckAt),
      ewe: Value(ewe),
      season: Value(season),
      lambing: lambing == null && nullToAbsent ? const Value.absent() : Value(lambing),
      kind: Value(kind),
      occurredAt: Value(occurredAt),
      capturedAt: Value(capturedAt),
      originalEffective: originalEffective == null && nullToAbsent
          ? const Value.absent()
          : Value(originalEffective),
      timeSource: Value(timeSource),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory EweObservation.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EweObservation(
      id: serializer.fromJson<int>(json['id']),
      uid: serializer.fromJson<String>(json['uid']),
      createdAt: serializer.fromJson<Instant>(json['createdAt']),
      updatedAt: serializer.fromJson<Instant>(json['updatedAt']),
      struck: serializer.fromJson<bool>(json['struck']),
      struckAt: serializer.fromJson<Instant?>(json['struckAt']),
      ewe: serializer.fromJson<int>(json['ewe']),
      season: serializer.fromJson<int>(json['season']),
      lambing: serializer.fromJson<int?>(json['lambing']),
      kind: serializer.fromJson<String>(json['kind']),
      occurredAt: serializer.fromJson<Instant>(json['occurredAt']),
      capturedAt: serializer.fromJson<Instant>(json['capturedAt']),
      originalEffective: serializer.fromJson<Instant?>(json['originalEffective']),
      timeSource: serializer.fromJson<String>(json['timeSource']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uid': serializer.toJson<String>(uid),
      'createdAt': serializer.toJson<Instant>(createdAt),
      'updatedAt': serializer.toJson<Instant>(updatedAt),
      'struck': serializer.toJson<bool>(struck),
      'struckAt': serializer.toJson<Instant?>(struckAt),
      'ewe': serializer.toJson<int>(ewe),
      'season': serializer.toJson<int>(season),
      'lambing': serializer.toJson<int?>(lambing),
      'kind': serializer.toJson<String>(kind),
      'occurredAt': serializer.toJson<Instant>(occurredAt),
      'capturedAt': serializer.toJson<Instant>(capturedAt),
      'originalEffective': serializer.toJson<Instant?>(originalEffective),
      'timeSource': serializer.toJson<String>(timeSource),
      'note': serializer.toJson<String?>(note),
    };
  }

  EweObservation copyWith({
    int? id,
    String? uid,
    Instant? createdAt,
    Instant? updatedAt,
    bool? struck,
    Value<Instant?> struckAt = const Value.absent(),
    int? ewe,
    int? season,
    Value<int?> lambing = const Value.absent(),
    String? kind,
    Instant? occurredAt,
    Instant? capturedAt,
    Value<Instant?> originalEffective = const Value.absent(),
    String? timeSource,
    Value<String?> note = const Value.absent(),
  }) => EweObservation(
    id: id ?? this.id,
    uid: uid ?? this.uid,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    struck: struck ?? this.struck,
    struckAt: struckAt.present ? struckAt.value : this.struckAt,
    ewe: ewe ?? this.ewe,
    season: season ?? this.season,
    lambing: lambing.present ? lambing.value : this.lambing,
    kind: kind ?? this.kind,
    occurredAt: occurredAt ?? this.occurredAt,
    capturedAt: capturedAt ?? this.capturedAt,
    originalEffective: originalEffective.present ? originalEffective.value : this.originalEffective,
    timeSource: timeSource ?? this.timeSource,
    note: note.present ? note.value : this.note,
  );
  EweObservation copyWithCompanion(EweObservationsCompanion data) {
    return EweObservation(
      id: data.id.present ? data.id.value : this.id,
      uid: data.uid.present ? data.uid.value : this.uid,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      struck: data.struck.present ? data.struck.value : this.struck,
      struckAt: data.struckAt.present ? data.struckAt.value : this.struckAt,
      ewe: data.ewe.present ? data.ewe.value : this.ewe,
      season: data.season.present ? data.season.value : this.season,
      lambing: data.lambing.present ? data.lambing.value : this.lambing,
      kind: data.kind.present ? data.kind.value : this.kind,
      occurredAt: data.occurredAt.present ? data.occurredAt.value : this.occurredAt,
      capturedAt: data.capturedAt.present ? data.capturedAt.value : this.capturedAt,
      originalEffective: data.originalEffective.present
          ? data.originalEffective.value
          : this.originalEffective,
      timeSource: data.timeSource.present ? data.timeSource.value : this.timeSource,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EweObservation(')
          ..write('id: $id, ')
          ..write('uid: $uid, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('struck: $struck, ')
          ..write('struckAt: $struckAt, ')
          ..write('ewe: $ewe, ')
          ..write('season: $season, ')
          ..write('lambing: $lambing, ')
          ..write('kind: $kind, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('originalEffective: $originalEffective, ')
          ..write('timeSource: $timeSource, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    uid,
    createdAt,
    updatedAt,
    struck,
    struckAt,
    ewe,
    season,
    lambing,
    kind,
    occurredAt,
    capturedAt,
    originalEffective,
    timeSource,
    note,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EweObservation &&
          other.id == this.id &&
          other.uid == this.uid &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.struck == this.struck &&
          other.struckAt == this.struckAt &&
          other.ewe == this.ewe &&
          other.season == this.season &&
          other.lambing == this.lambing &&
          other.kind == this.kind &&
          other.occurredAt == this.occurredAt &&
          other.capturedAt == this.capturedAt &&
          other.originalEffective == this.originalEffective &&
          other.timeSource == this.timeSource &&
          other.note == this.note);
}

class EweObservationsCompanion extends UpdateCompanion<EweObservation> {
  final Value<int> id;
  final Value<String> uid;
  final Value<Instant> createdAt;
  final Value<Instant> updatedAt;
  final Value<bool> struck;
  final Value<Instant?> struckAt;
  final Value<int> ewe;
  final Value<int> season;
  final Value<int?> lambing;
  final Value<String> kind;
  final Value<Instant> occurredAt;
  final Value<Instant> capturedAt;
  final Value<Instant?> originalEffective;
  final Value<String> timeSource;
  final Value<String?> note;
  const EweObservationsCompanion({
    this.id = const Value.absent(),
    this.uid = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.struck = const Value.absent(),
    this.struckAt = const Value.absent(),
    this.ewe = const Value.absent(),
    this.season = const Value.absent(),
    this.lambing = const Value.absent(),
    this.kind = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.capturedAt = const Value.absent(),
    this.originalEffective = const Value.absent(),
    this.timeSource = const Value.absent(),
    this.note = const Value.absent(),
  });
  EweObservationsCompanion.insert({
    this.id = const Value.absent(),
    required String uid,
    required Instant createdAt,
    required Instant updatedAt,
    this.struck = const Value.absent(),
    this.struckAt = const Value.absent(),
    required int ewe,
    required int season,
    this.lambing = const Value.absent(),
    required String kind,
    required Instant occurredAt,
    required Instant capturedAt,
    this.originalEffective = const Value.absent(),
    this.timeSource = const Value.absent(),
    this.note = const Value.absent(),
  }) : uid = Value(uid),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       ewe = Value(ewe),
       season = Value(season),
       kind = Value(kind),
       occurredAt = Value(occurredAt),
       capturedAt = Value(capturedAt);
  static Insertable<EweObservation> custom({
    Expression<int>? id,
    Expression<String>? uid,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<bool>? struck,
    Expression<int>? struckAt,
    Expression<int>? ewe,
    Expression<int>? season,
    Expression<int>? lambing,
    Expression<String>? kind,
    Expression<int>? occurredAt,
    Expression<int>? capturedAt,
    Expression<int>? originalEffective,
    Expression<String>? timeSource,
    Expression<String>? note,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uid != null) 'uid': uid,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (struck != null) 'struck': struck,
      if (struckAt != null) 'struck_at': struckAt,
      if (ewe != null) 'ewe': ewe,
      if (season != null) 'season': season,
      if (lambing != null) 'lambing': lambing,
      if (kind != null) 'kind': kind,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (capturedAt != null) 'captured_at': capturedAt,
      if (originalEffective != null) 'original_effective': originalEffective,
      if (timeSource != null) 'time_source': timeSource,
      if (note != null) 'note': note,
    });
  }

  EweObservationsCompanion copyWith({
    Value<int>? id,
    Value<String>? uid,
    Value<Instant>? createdAt,
    Value<Instant>? updatedAt,
    Value<bool>? struck,
    Value<Instant?>? struckAt,
    Value<int>? ewe,
    Value<int>? season,
    Value<int?>? lambing,
    Value<String>? kind,
    Value<Instant>? occurredAt,
    Value<Instant>? capturedAt,
    Value<Instant?>? originalEffective,
    Value<String>? timeSource,
    Value<String?>? note,
  }) {
    return EweObservationsCompanion(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      struck: struck ?? this.struck,
      struckAt: struckAt ?? this.struckAt,
      ewe: ewe ?? this.ewe,
      season: season ?? this.season,
      lambing: lambing ?? this.lambing,
      kind: kind ?? this.kind,
      occurredAt: occurredAt ?? this.occurredAt,
      capturedAt: capturedAt ?? this.capturedAt,
      originalEffective: originalEffective ?? this.originalEffective,
      timeSource: timeSource ?? this.timeSource,
      note: note ?? this.note,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uid.present) {
      map['uid'] = Variable<String>(uid.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
        $EweObservationsTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(
        $EweObservationsTable.$converterupdatedAt.toSql(updatedAt.value),
      );
    }
    if (struck.present) {
      map['struck'] = Variable<bool>(struck.value);
    }
    if (struckAt.present) {
      map['struck_at'] = Variable<int>(
        $EweObservationsTable.$converterstruckAtn.toSql(struckAt.value),
      );
    }
    if (ewe.present) {
      map['ewe'] = Variable<int>(ewe.value);
    }
    if (season.present) {
      map['season'] = Variable<int>(season.value);
    }
    if (lambing.present) {
      map['lambing'] = Variable<int>(lambing.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<int>(
        $EweObservationsTable.$converteroccurredAt.toSql(occurredAt.value),
      );
    }
    if (capturedAt.present) {
      map['captured_at'] = Variable<int>(
        $EweObservationsTable.$convertercapturedAt.toSql(capturedAt.value),
      );
    }
    if (originalEffective.present) {
      map['original_effective'] = Variable<int>(
        $EweObservationsTable.$converteroriginalEffectiven.toSql(originalEffective.value),
      );
    }
    if (timeSource.present) {
      map['time_source'] = Variable<String>(timeSource.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EweObservationsCompanion(')
          ..write('id: $id, ')
          ..write('uid: $uid, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('struck: $struck, ')
          ..write('struckAt: $struckAt, ')
          ..write('ewe: $ewe, ')
          ..write('season: $season, ')
          ..write('lambing: $lambing, ')
          ..write('kind: $kind, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('originalEffective: $originalEffective, ')
          ..write('timeSource: $timeSource, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }
}

class $TreatmentsTable extends Treatments with TableInfo<$TreatmentsTable, Treatment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TreatmentsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<String> uid = GeneratedColumn<String>(
    'uid',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 36, maxTextLength: 36),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Instant, int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  ).withConverter<Instant>($TreatmentsTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<Instant, int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  ).withConverter<Instant>($TreatmentsTable.$converterupdatedAt);
  static const VerificationMeta _seasonMeta = const VerificationMeta('season');
  @override
  late final GeneratedColumn<int> season = GeneratedColumn<int>(
    'season',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES seasons (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _eweMeta = const VerificationMeta('ewe');
  @override
  late final GeneratedColumn<int> ewe = GeneratedColumn<int>(
    'ewe',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES ewes (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _lambMeta = const VerificationMeta('lamb');
  @override
  late final GeneratedColumn<int> lamb = GeneratedColumn<int>(
    'lamb',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES lambs (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _productNameMeta = const VerificationMeta('productName');
  @override
  late final GeneratedColumn<String> productName = GeneratedColumn<String>(
    'product_name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 120),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _doseTextMeta = const VerificationMeta('doseText');
  @override
  late final GeneratedColumn<String> doseText = GeneratedColumn<String>(
    'dose_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _routeMeta = const VerificationMeta('route');
  @override
  late final GeneratedColumn<String> route = GeneratedColumn<String>(
    'route',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _batchNoMeta = const VerificationMeta('batchNo');
  @override
  late final GeneratedColumn<String> batchNo = GeneratedColumn<String>(
    'batch_no',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Instant, int> administeredAt = GeneratedColumn<int>(
    'administered_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  ).withConverter<Instant>($TreatmentsTable.$converteradministeredAt);
  @override
  late final GeneratedColumnWithTypeConverter<Instant, int> capturedAt = GeneratedColumn<int>(
    'captured_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  ).withConverter<Instant>($TreatmentsTable.$convertercapturedAt);
  @override
  late final GeneratedColumnWithTypeConverter<Instant?, int> originalEffective =
      GeneratedColumn<int>(
        'original_effective',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<Instant?>($TreatmentsTable.$converteroriginalEffectiven);
  static const VerificationMeta _timeSourceMeta = const VerificationMeta('timeSource');
  @override
  late final GeneratedColumn<String> timeSource = GeneratedColumn<String>(
    'time_source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('auto'),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Instant?, int> voidedAt = GeneratedColumn<int>(
    'voided_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  ).withConverter<Instant?>($TreatmentsTable.$convertervoidedAtn);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uid,
    createdAt,
    updatedAt,
    season,
    ewe,
    lamb,
    productName,
    doseText,
    route,
    batchNo,
    administeredAt,
    capturedAt,
    originalEffective,
    timeSource,
    voidedAt,
    note,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'treatments';
  @override
  VerificationContext validateIntegrity(
    Insertable<Treatment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uid')) {
      context.handle(_uidMeta, uid.isAcceptableOrUnknown(data['uid']!, _uidMeta));
    } else if (isInserting) {
      context.missing(_uidMeta);
    }
    if (data.containsKey('season')) {
      context.handle(_seasonMeta, season.isAcceptableOrUnknown(data['season']!, _seasonMeta));
    } else if (isInserting) {
      context.missing(_seasonMeta);
    }
    if (data.containsKey('ewe')) {
      context.handle(_eweMeta, ewe.isAcceptableOrUnknown(data['ewe']!, _eweMeta));
    }
    if (data.containsKey('lamb')) {
      context.handle(_lambMeta, lamb.isAcceptableOrUnknown(data['lamb']!, _lambMeta));
    }
    if (data.containsKey('product_name')) {
      context.handle(
        _productNameMeta,
        productName.isAcceptableOrUnknown(data['product_name']!, _productNameMeta),
      );
    } else if (isInserting) {
      context.missing(_productNameMeta);
    }
    if (data.containsKey('dose_text')) {
      context.handle(
        _doseTextMeta,
        doseText.isAcceptableOrUnknown(data['dose_text']!, _doseTextMeta),
      );
    }
    if (data.containsKey('route')) {
      context.handle(_routeMeta, route.isAcceptableOrUnknown(data['route']!, _routeMeta));
    }
    if (data.containsKey('batch_no')) {
      context.handle(_batchNoMeta, batchNo.isAcceptableOrUnknown(data['batch_no']!, _batchNoMeta));
    }
    if (data.containsKey('time_source')) {
      context.handle(
        _timeSourceMeta,
        timeSource.isAcceptableOrUnknown(data['time_source']!, _timeSourceMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(_noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Treatment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Treatment(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      uid: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}uid'])!,
      createdAt: $TreatmentsTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      ),
      updatedAt: $TreatmentsTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
      ),
      season: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}season'],
      )!,
      ewe: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}ewe']),
      lamb: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}lamb']),
      productName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_name'],
      )!,
      doseText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dose_text'],
      ),
      route: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}route'],
      ),
      batchNo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}batch_no'],
      ),
      administeredAt: $TreatmentsTable.$converteradministeredAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}administered_at'],
        )!,
      ),
      capturedAt: $TreatmentsTable.$convertercapturedAt.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}captured_at'])!,
      ),
      originalEffective: $TreatmentsTable.$converteroriginalEffectiven.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}original_effective'],
        ),
      ),
      timeSource: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}time_source'],
      )!,
      voidedAt: $TreatmentsTable.$convertervoidedAtn.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}voided_at']),
      ),
      note: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}note']),
    );
  }

  @override
  $TreatmentsTable createAlias(String alias) {
    return $TreatmentsTable(attachedDatabase, alias);
  }

  static TypeConverter<Instant, int> $convertercreatedAt = const InstantConverter();
  static TypeConverter<Instant, int> $converterupdatedAt = const InstantConverter();
  static TypeConverter<Instant, int> $converteradministeredAt = const InstantConverter();
  static TypeConverter<Instant, int> $convertercapturedAt = const InstantConverter();
  static TypeConverter<Instant, int> $converteroriginalEffective = const InstantConverter();
  static TypeConverter<Instant?, int?> $converteroriginalEffectiven = NullAwareTypeConverter.wrap(
    $converteroriginalEffective,
  );
  static TypeConverter<Instant, int> $convertervoidedAt = const InstantConverter();
  static TypeConverter<Instant?, int?> $convertervoidedAtn = NullAwareTypeConverter.wrap(
    $convertervoidedAt,
  );
  @override
  bool get isStrict => true;
}

class Treatment extends DataClass implements Insertable<Treatment> {
  /// Joins and foreign keys. Device-local. **NEVER exported** (03 §3): a row id
  /// means nothing on another phone, and exporting one invites a restore that
  /// tries to honour it.
  final int id;

  /// UUID v7. The identity that survives export → re-import.
  final String uid;

  /// Instants: UTC epoch millis (§4).
  final Instant createdAt;
  final Instant updatedAt;
  final int season;
  final int? ewe;
  final int? lamb;
  final String productName;
  final String? doseText;

  /// **Forward reference, deferred to N07-T06** (`VocabTerms`, `RESTRICT`).
  final String? route;
  final String? batchNo;

  /// One of the three documented exceptions to the `occurred_at` column-name
  /// rule, alongside `pen_occupancies.entered_at` and
  /// `foster_events.effective_at` (R37).
  final Instant administeredAt;
  final Instant capturedAt;
  final Instant? originalEffective;
  final String timeSource;

  /// Decision #69: undo for a treatment is a **soft void**.
  final Instant? voidedAt;
  final String? note;
  const Treatment({
    required this.id,
    required this.uid,
    required this.createdAt,
    required this.updatedAt,
    required this.season,
    this.ewe,
    this.lamb,
    required this.productName,
    this.doseText,
    this.route,
    this.batchNo,
    required this.administeredAt,
    required this.capturedAt,
    this.originalEffective,
    required this.timeSource,
    this.voidedAt,
    this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uid'] = Variable<String>(uid);
    {
      map['created_at'] = Variable<int>($TreatmentsTable.$convertercreatedAt.toSql(createdAt));
    }
    {
      map['updated_at'] = Variable<int>($TreatmentsTable.$converterupdatedAt.toSql(updatedAt));
    }
    map['season'] = Variable<int>(season);
    if (!nullToAbsent || ewe != null) {
      map['ewe'] = Variable<int>(ewe);
    }
    if (!nullToAbsent || lamb != null) {
      map['lamb'] = Variable<int>(lamb);
    }
    map['product_name'] = Variable<String>(productName);
    if (!nullToAbsent || doseText != null) {
      map['dose_text'] = Variable<String>(doseText);
    }
    if (!nullToAbsent || route != null) {
      map['route'] = Variable<String>(route);
    }
    if (!nullToAbsent || batchNo != null) {
      map['batch_no'] = Variable<String>(batchNo);
    }
    {
      map['administered_at'] = Variable<int>(
        $TreatmentsTable.$converteradministeredAt.toSql(administeredAt),
      );
    }
    {
      map['captured_at'] = Variable<int>($TreatmentsTable.$convertercapturedAt.toSql(capturedAt));
    }
    if (!nullToAbsent || originalEffective != null) {
      map['original_effective'] = Variable<int>(
        $TreatmentsTable.$converteroriginalEffectiven.toSql(originalEffective),
      );
    }
    map['time_source'] = Variable<String>(timeSource);
    if (!nullToAbsent || voidedAt != null) {
      map['voided_at'] = Variable<int>($TreatmentsTable.$convertervoidedAtn.toSql(voidedAt));
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  TreatmentsCompanion toCompanion(bool nullToAbsent) {
    return TreatmentsCompanion(
      id: Value(id),
      uid: Value(uid),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      season: Value(season),
      ewe: ewe == null && nullToAbsent ? const Value.absent() : Value(ewe),
      lamb: lamb == null && nullToAbsent ? const Value.absent() : Value(lamb),
      productName: Value(productName),
      doseText: doseText == null && nullToAbsent ? const Value.absent() : Value(doseText),
      route: route == null && nullToAbsent ? const Value.absent() : Value(route),
      batchNo: batchNo == null && nullToAbsent ? const Value.absent() : Value(batchNo),
      administeredAt: Value(administeredAt),
      capturedAt: Value(capturedAt),
      originalEffective: originalEffective == null && nullToAbsent
          ? const Value.absent()
          : Value(originalEffective),
      timeSource: Value(timeSource),
      voidedAt: voidedAt == null && nullToAbsent ? const Value.absent() : Value(voidedAt),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory Treatment.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Treatment(
      id: serializer.fromJson<int>(json['id']),
      uid: serializer.fromJson<String>(json['uid']),
      createdAt: serializer.fromJson<Instant>(json['createdAt']),
      updatedAt: serializer.fromJson<Instant>(json['updatedAt']),
      season: serializer.fromJson<int>(json['season']),
      ewe: serializer.fromJson<int?>(json['ewe']),
      lamb: serializer.fromJson<int?>(json['lamb']),
      productName: serializer.fromJson<String>(json['productName']),
      doseText: serializer.fromJson<String?>(json['doseText']),
      route: serializer.fromJson<String?>(json['route']),
      batchNo: serializer.fromJson<String?>(json['batchNo']),
      administeredAt: serializer.fromJson<Instant>(json['administeredAt']),
      capturedAt: serializer.fromJson<Instant>(json['capturedAt']),
      originalEffective: serializer.fromJson<Instant?>(json['originalEffective']),
      timeSource: serializer.fromJson<String>(json['timeSource']),
      voidedAt: serializer.fromJson<Instant?>(json['voidedAt']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uid': serializer.toJson<String>(uid),
      'createdAt': serializer.toJson<Instant>(createdAt),
      'updatedAt': serializer.toJson<Instant>(updatedAt),
      'season': serializer.toJson<int>(season),
      'ewe': serializer.toJson<int?>(ewe),
      'lamb': serializer.toJson<int?>(lamb),
      'productName': serializer.toJson<String>(productName),
      'doseText': serializer.toJson<String?>(doseText),
      'route': serializer.toJson<String?>(route),
      'batchNo': serializer.toJson<String?>(batchNo),
      'administeredAt': serializer.toJson<Instant>(administeredAt),
      'capturedAt': serializer.toJson<Instant>(capturedAt),
      'originalEffective': serializer.toJson<Instant?>(originalEffective),
      'timeSource': serializer.toJson<String>(timeSource),
      'voidedAt': serializer.toJson<Instant?>(voidedAt),
      'note': serializer.toJson<String?>(note),
    };
  }

  Treatment copyWith({
    int? id,
    String? uid,
    Instant? createdAt,
    Instant? updatedAt,
    int? season,
    Value<int?> ewe = const Value.absent(),
    Value<int?> lamb = const Value.absent(),
    String? productName,
    Value<String?> doseText = const Value.absent(),
    Value<String?> route = const Value.absent(),
    Value<String?> batchNo = const Value.absent(),
    Instant? administeredAt,
    Instant? capturedAt,
    Value<Instant?> originalEffective = const Value.absent(),
    String? timeSource,
    Value<Instant?> voidedAt = const Value.absent(),
    Value<String?> note = const Value.absent(),
  }) => Treatment(
    id: id ?? this.id,
    uid: uid ?? this.uid,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    season: season ?? this.season,
    ewe: ewe.present ? ewe.value : this.ewe,
    lamb: lamb.present ? lamb.value : this.lamb,
    productName: productName ?? this.productName,
    doseText: doseText.present ? doseText.value : this.doseText,
    route: route.present ? route.value : this.route,
    batchNo: batchNo.present ? batchNo.value : this.batchNo,
    administeredAt: administeredAt ?? this.administeredAt,
    capturedAt: capturedAt ?? this.capturedAt,
    originalEffective: originalEffective.present ? originalEffective.value : this.originalEffective,
    timeSource: timeSource ?? this.timeSource,
    voidedAt: voidedAt.present ? voidedAt.value : this.voidedAt,
    note: note.present ? note.value : this.note,
  );
  Treatment copyWithCompanion(TreatmentsCompanion data) {
    return Treatment(
      id: data.id.present ? data.id.value : this.id,
      uid: data.uid.present ? data.uid.value : this.uid,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      season: data.season.present ? data.season.value : this.season,
      ewe: data.ewe.present ? data.ewe.value : this.ewe,
      lamb: data.lamb.present ? data.lamb.value : this.lamb,
      productName: data.productName.present ? data.productName.value : this.productName,
      doseText: data.doseText.present ? data.doseText.value : this.doseText,
      route: data.route.present ? data.route.value : this.route,
      batchNo: data.batchNo.present ? data.batchNo.value : this.batchNo,
      administeredAt: data.administeredAt.present ? data.administeredAt.value : this.administeredAt,
      capturedAt: data.capturedAt.present ? data.capturedAt.value : this.capturedAt,
      originalEffective: data.originalEffective.present
          ? data.originalEffective.value
          : this.originalEffective,
      timeSource: data.timeSource.present ? data.timeSource.value : this.timeSource,
      voidedAt: data.voidedAt.present ? data.voidedAt.value : this.voidedAt,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Treatment(')
          ..write('id: $id, ')
          ..write('uid: $uid, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('season: $season, ')
          ..write('ewe: $ewe, ')
          ..write('lamb: $lamb, ')
          ..write('productName: $productName, ')
          ..write('doseText: $doseText, ')
          ..write('route: $route, ')
          ..write('batchNo: $batchNo, ')
          ..write('administeredAt: $administeredAt, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('originalEffective: $originalEffective, ')
          ..write('timeSource: $timeSource, ')
          ..write('voidedAt: $voidedAt, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    uid,
    createdAt,
    updatedAt,
    season,
    ewe,
    lamb,
    productName,
    doseText,
    route,
    batchNo,
    administeredAt,
    capturedAt,
    originalEffective,
    timeSource,
    voidedAt,
    note,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Treatment &&
          other.id == this.id &&
          other.uid == this.uid &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.season == this.season &&
          other.ewe == this.ewe &&
          other.lamb == this.lamb &&
          other.productName == this.productName &&
          other.doseText == this.doseText &&
          other.route == this.route &&
          other.batchNo == this.batchNo &&
          other.administeredAt == this.administeredAt &&
          other.capturedAt == this.capturedAt &&
          other.originalEffective == this.originalEffective &&
          other.timeSource == this.timeSource &&
          other.voidedAt == this.voidedAt &&
          other.note == this.note);
}

class TreatmentsCompanion extends UpdateCompanion<Treatment> {
  final Value<int> id;
  final Value<String> uid;
  final Value<Instant> createdAt;
  final Value<Instant> updatedAt;
  final Value<int> season;
  final Value<int?> ewe;
  final Value<int?> lamb;
  final Value<String> productName;
  final Value<String?> doseText;
  final Value<String?> route;
  final Value<String?> batchNo;
  final Value<Instant> administeredAt;
  final Value<Instant> capturedAt;
  final Value<Instant?> originalEffective;
  final Value<String> timeSource;
  final Value<Instant?> voidedAt;
  final Value<String?> note;
  const TreatmentsCompanion({
    this.id = const Value.absent(),
    this.uid = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.season = const Value.absent(),
    this.ewe = const Value.absent(),
    this.lamb = const Value.absent(),
    this.productName = const Value.absent(),
    this.doseText = const Value.absent(),
    this.route = const Value.absent(),
    this.batchNo = const Value.absent(),
    this.administeredAt = const Value.absent(),
    this.capturedAt = const Value.absent(),
    this.originalEffective = const Value.absent(),
    this.timeSource = const Value.absent(),
    this.voidedAt = const Value.absent(),
    this.note = const Value.absent(),
  });
  TreatmentsCompanion.insert({
    this.id = const Value.absent(),
    required String uid,
    required Instant createdAt,
    required Instant updatedAt,
    required int season,
    this.ewe = const Value.absent(),
    this.lamb = const Value.absent(),
    required String productName,
    this.doseText = const Value.absent(),
    this.route = const Value.absent(),
    this.batchNo = const Value.absent(),
    required Instant administeredAt,
    required Instant capturedAt,
    this.originalEffective = const Value.absent(),
    this.timeSource = const Value.absent(),
    this.voidedAt = const Value.absent(),
    this.note = const Value.absent(),
  }) : uid = Value(uid),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       season = Value(season),
       productName = Value(productName),
       administeredAt = Value(administeredAt),
       capturedAt = Value(capturedAt);
  static Insertable<Treatment> custom({
    Expression<int>? id,
    Expression<String>? uid,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? season,
    Expression<int>? ewe,
    Expression<int>? lamb,
    Expression<String>? productName,
    Expression<String>? doseText,
    Expression<String>? route,
    Expression<String>? batchNo,
    Expression<int>? administeredAt,
    Expression<int>? capturedAt,
    Expression<int>? originalEffective,
    Expression<String>? timeSource,
    Expression<int>? voidedAt,
    Expression<String>? note,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uid != null) 'uid': uid,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (season != null) 'season': season,
      if (ewe != null) 'ewe': ewe,
      if (lamb != null) 'lamb': lamb,
      if (productName != null) 'product_name': productName,
      if (doseText != null) 'dose_text': doseText,
      if (route != null) 'route': route,
      if (batchNo != null) 'batch_no': batchNo,
      if (administeredAt != null) 'administered_at': administeredAt,
      if (capturedAt != null) 'captured_at': capturedAt,
      if (originalEffective != null) 'original_effective': originalEffective,
      if (timeSource != null) 'time_source': timeSource,
      if (voidedAt != null) 'voided_at': voidedAt,
      if (note != null) 'note': note,
    });
  }

  TreatmentsCompanion copyWith({
    Value<int>? id,
    Value<String>? uid,
    Value<Instant>? createdAt,
    Value<Instant>? updatedAt,
    Value<int>? season,
    Value<int?>? ewe,
    Value<int?>? lamb,
    Value<String>? productName,
    Value<String?>? doseText,
    Value<String?>? route,
    Value<String?>? batchNo,
    Value<Instant>? administeredAt,
    Value<Instant>? capturedAt,
    Value<Instant?>? originalEffective,
    Value<String>? timeSource,
    Value<Instant?>? voidedAt,
    Value<String?>? note,
  }) {
    return TreatmentsCompanion(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      season: season ?? this.season,
      ewe: ewe ?? this.ewe,
      lamb: lamb ?? this.lamb,
      productName: productName ?? this.productName,
      doseText: doseText ?? this.doseText,
      route: route ?? this.route,
      batchNo: batchNo ?? this.batchNo,
      administeredAt: administeredAt ?? this.administeredAt,
      capturedAt: capturedAt ?? this.capturedAt,
      originalEffective: originalEffective ?? this.originalEffective,
      timeSource: timeSource ?? this.timeSource,
      voidedAt: voidedAt ?? this.voidedAt,
      note: note ?? this.note,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uid.present) {
      map['uid'] = Variable<String>(uid.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
        $TreatmentsTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(
        $TreatmentsTable.$converterupdatedAt.toSql(updatedAt.value),
      );
    }
    if (season.present) {
      map['season'] = Variable<int>(season.value);
    }
    if (ewe.present) {
      map['ewe'] = Variable<int>(ewe.value);
    }
    if (lamb.present) {
      map['lamb'] = Variable<int>(lamb.value);
    }
    if (productName.present) {
      map['product_name'] = Variable<String>(productName.value);
    }
    if (doseText.present) {
      map['dose_text'] = Variable<String>(doseText.value);
    }
    if (route.present) {
      map['route'] = Variable<String>(route.value);
    }
    if (batchNo.present) {
      map['batch_no'] = Variable<String>(batchNo.value);
    }
    if (administeredAt.present) {
      map['administered_at'] = Variable<int>(
        $TreatmentsTable.$converteradministeredAt.toSql(administeredAt.value),
      );
    }
    if (capturedAt.present) {
      map['captured_at'] = Variable<int>(
        $TreatmentsTable.$convertercapturedAt.toSql(capturedAt.value),
      );
    }
    if (originalEffective.present) {
      map['original_effective'] = Variable<int>(
        $TreatmentsTable.$converteroriginalEffectiven.toSql(originalEffective.value),
      );
    }
    if (timeSource.present) {
      map['time_source'] = Variable<String>(timeSource.value);
    }
    if (voidedAt.present) {
      map['voided_at'] = Variable<int>($TreatmentsTable.$convertervoidedAtn.toSql(voidedAt.value));
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TreatmentsCompanion(')
          ..write('id: $id, ')
          ..write('uid: $uid, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('season: $season, ')
          ..write('ewe: $ewe, ')
          ..write('lamb: $lamb, ')
          ..write('productName: $productName, ')
          ..write('doseText: $doseText, ')
          ..write('route: $route, ')
          ..write('batchNo: $batchNo, ')
          ..write('administeredAt: $administeredAt, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('originalEffective: $originalEffective, ')
          ..write('timeSource: $timeSource, ')
          ..write('voidedAt: $voidedAt, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }
}

class $TreatmentWithdrawalsTable extends TreatmentWithdrawals
    with TableInfo<$TreatmentWithdrawalsTable, TreatmentWithdrawal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TreatmentWithdrawalsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<String> uid = GeneratedColumn<String>(
    'uid',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 36, maxTextLength: 36),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Instant, int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  ).withConverter<Instant>($TreatmentWithdrawalsTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<Instant, int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  ).withConverter<Instant>($TreatmentWithdrawalsTable.$converterupdatedAt);
  static const VerificationMeta _treatmentMeta = const VerificationMeta('treatment');
  @override
  late final GeneratedColumn<int> treatment = GeneratedColumn<int>(
    'treatment',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES treatments (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _targetMeta = const VerificationMeta('target');
  @override
  late final GeneratedColumn<String> target = GeneratedColumn<String>(
    'target',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _daysMeta = const VerificationMeta('days');
  @override
  late final GeneratedColumn<int> days = GeneratedColumn<int>(
    'days',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<LocalDate?, String> clearDate =
      GeneratedColumn<String>(
        'clear_date',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<LocalDate?>($TreatmentWithdrawalsTable.$converterclearDaten);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uid,
    createdAt,
    updatedAt,
    treatment,
    target,
    kind,
    days,
    clearDate,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'treatment_withdrawals';
  @override
  VerificationContext validateIntegrity(
    Insertable<TreatmentWithdrawal> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uid')) {
      context.handle(_uidMeta, uid.isAcceptableOrUnknown(data['uid']!, _uidMeta));
    } else if (isInserting) {
      context.missing(_uidMeta);
    }
    if (data.containsKey('treatment')) {
      context.handle(
        _treatmentMeta,
        treatment.isAcceptableOrUnknown(data['treatment']!, _treatmentMeta),
      );
    } else if (isInserting) {
      context.missing(_treatmentMeta);
    }
    if (data.containsKey('target')) {
      context.handle(_targetMeta, target.isAcceptableOrUnknown(data['target']!, _targetMeta));
    } else if (isInserting) {
      context.missing(_targetMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(_kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('days')) {
      context.handle(_daysMeta, days.isAcceptableOrUnknown(data['days']!, _daysMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {treatment, target},
  ];
  @override
  TreatmentWithdrawal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TreatmentWithdrawal(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      uid: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}uid'])!,
      createdAt: $TreatmentWithdrawalsTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      ),
      updatedAt: $TreatmentWithdrawalsTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
      ),
      treatment: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}treatment'],
      )!,
      target: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target'],
      )!,
      kind: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      days: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}days']),
      clearDate: $TreatmentWithdrawalsTable.$converterclearDaten.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}clear_date'],
        ),
      ),
    );
  }

  @override
  $TreatmentWithdrawalsTable createAlias(String alias) {
    return $TreatmentWithdrawalsTable(attachedDatabase, alias);
  }

  static TypeConverter<Instant, int> $convertercreatedAt = const InstantConverter();
  static TypeConverter<Instant, int> $converterupdatedAt = const InstantConverter();
  static TypeConverter<LocalDate, String> $converterclearDate = const LocalDateConverter();
  static TypeConverter<LocalDate?, String?> $converterclearDaten = NullAwareTypeConverter.wrap(
    $converterclearDate,
  );
  @override
  bool get isStrict => true;
}

class TreatmentWithdrawal extends DataClass implements Insertable<TreatmentWithdrawal> {
  /// Joins and foreign keys. Device-local. **NEVER exported** (03 §3): a row id
  /// means nothing on another phone, and exporting one invites a restore that
  /// tries to honour it.
  final int id;

  /// UUID v7. The identity that survives export → re-import.
  final String uid;

  /// Instants: UTC epoch millis (§4).
  final Instant createdAt;
  final Instant updatedAt;
  final int treatment;

  /// `'meat'` | `'milk'`. One product routinely prints different figures.
  final String target;

  /// `'days'` | `'not_applicable'`.
  final String kind;

  /// **NO DEFAULT. NO clientDefault.** The app physically cannot write this row
  /// without the user having typed a number off the bottle. Spec §12.1 enforced
  /// by the schema, not by a code review — and N07-T08's snapshot assertion is
  /// what keeps it that way.
  final int? days;

  /// The **one** stored derived value (decision #50). Computed exactly once at
  /// write time by `clearDateFor()`; its inputs live alongside it for ever.
  ///
  /// A record of what the app TOLD the user and printed into the medicine-book
  /// PDF — **not a cache**. When it disagrees with a fresh computation, that is
  /// `clearDateDisagrees`: shown, never applied.
  final LocalDate? clearDate;
  const TreatmentWithdrawal({
    required this.id,
    required this.uid,
    required this.createdAt,
    required this.updatedAt,
    required this.treatment,
    required this.target,
    required this.kind,
    this.days,
    this.clearDate,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uid'] = Variable<String>(uid);
    {
      map['created_at'] = Variable<int>(
        $TreatmentWithdrawalsTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    {
      map['updated_at'] = Variable<int>(
        $TreatmentWithdrawalsTable.$converterupdatedAt.toSql(updatedAt),
      );
    }
    map['treatment'] = Variable<int>(treatment);
    map['target'] = Variable<String>(target);
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || days != null) {
      map['days'] = Variable<int>(days);
    }
    if (!nullToAbsent || clearDate != null) {
      map['clear_date'] = Variable<String>(
        $TreatmentWithdrawalsTable.$converterclearDaten.toSql(clearDate),
      );
    }
    return map;
  }

  TreatmentWithdrawalsCompanion toCompanion(bool nullToAbsent) {
    return TreatmentWithdrawalsCompanion(
      id: Value(id),
      uid: Value(uid),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      treatment: Value(treatment),
      target: Value(target),
      kind: Value(kind),
      days: days == null && nullToAbsent ? const Value.absent() : Value(days),
      clearDate: clearDate == null && nullToAbsent ? const Value.absent() : Value(clearDate),
    );
  }

  factory TreatmentWithdrawal.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TreatmentWithdrawal(
      id: serializer.fromJson<int>(json['id']),
      uid: serializer.fromJson<String>(json['uid']),
      createdAt: serializer.fromJson<Instant>(json['createdAt']),
      updatedAt: serializer.fromJson<Instant>(json['updatedAt']),
      treatment: serializer.fromJson<int>(json['treatment']),
      target: serializer.fromJson<String>(json['target']),
      kind: serializer.fromJson<String>(json['kind']),
      days: serializer.fromJson<int?>(json['days']),
      clearDate: serializer.fromJson<LocalDate?>(json['clearDate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uid': serializer.toJson<String>(uid),
      'createdAt': serializer.toJson<Instant>(createdAt),
      'updatedAt': serializer.toJson<Instant>(updatedAt),
      'treatment': serializer.toJson<int>(treatment),
      'target': serializer.toJson<String>(target),
      'kind': serializer.toJson<String>(kind),
      'days': serializer.toJson<int?>(days),
      'clearDate': serializer.toJson<LocalDate?>(clearDate),
    };
  }

  TreatmentWithdrawal copyWith({
    int? id,
    String? uid,
    Instant? createdAt,
    Instant? updatedAt,
    int? treatment,
    String? target,
    String? kind,
    Value<int?> days = const Value.absent(),
    Value<LocalDate?> clearDate = const Value.absent(),
  }) => TreatmentWithdrawal(
    id: id ?? this.id,
    uid: uid ?? this.uid,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    treatment: treatment ?? this.treatment,
    target: target ?? this.target,
    kind: kind ?? this.kind,
    days: days.present ? days.value : this.days,
    clearDate: clearDate.present ? clearDate.value : this.clearDate,
  );
  TreatmentWithdrawal copyWithCompanion(TreatmentWithdrawalsCompanion data) {
    return TreatmentWithdrawal(
      id: data.id.present ? data.id.value : this.id,
      uid: data.uid.present ? data.uid.value : this.uid,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      treatment: data.treatment.present ? data.treatment.value : this.treatment,
      target: data.target.present ? data.target.value : this.target,
      kind: data.kind.present ? data.kind.value : this.kind,
      days: data.days.present ? data.days.value : this.days,
      clearDate: data.clearDate.present ? data.clearDate.value : this.clearDate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TreatmentWithdrawal(')
          ..write('id: $id, ')
          ..write('uid: $uid, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('treatment: $treatment, ')
          ..write('target: $target, ')
          ..write('kind: $kind, ')
          ..write('days: $days, ')
          ..write('clearDate: $clearDate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, uid, createdAt, updatedAt, treatment, target, kind, days, clearDate);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TreatmentWithdrawal &&
          other.id == this.id &&
          other.uid == this.uid &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.treatment == this.treatment &&
          other.target == this.target &&
          other.kind == this.kind &&
          other.days == this.days &&
          other.clearDate == this.clearDate);
}

class TreatmentWithdrawalsCompanion extends UpdateCompanion<TreatmentWithdrawal> {
  final Value<int> id;
  final Value<String> uid;
  final Value<Instant> createdAt;
  final Value<Instant> updatedAt;
  final Value<int> treatment;
  final Value<String> target;
  final Value<String> kind;
  final Value<int?> days;
  final Value<LocalDate?> clearDate;
  const TreatmentWithdrawalsCompanion({
    this.id = const Value.absent(),
    this.uid = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.treatment = const Value.absent(),
    this.target = const Value.absent(),
    this.kind = const Value.absent(),
    this.days = const Value.absent(),
    this.clearDate = const Value.absent(),
  });
  TreatmentWithdrawalsCompanion.insert({
    this.id = const Value.absent(),
    required String uid,
    required Instant createdAt,
    required Instant updatedAt,
    required int treatment,
    required String target,
    required String kind,
    this.days = const Value.absent(),
    this.clearDate = const Value.absent(),
  }) : uid = Value(uid),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       treatment = Value(treatment),
       target = Value(target),
       kind = Value(kind);
  static Insertable<TreatmentWithdrawal> custom({
    Expression<int>? id,
    Expression<String>? uid,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? treatment,
    Expression<String>? target,
    Expression<String>? kind,
    Expression<int>? days,
    Expression<String>? clearDate,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uid != null) 'uid': uid,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (treatment != null) 'treatment': treatment,
      if (target != null) 'target': target,
      if (kind != null) 'kind': kind,
      if (days != null) 'days': days,
      if (clearDate != null) 'clear_date': clearDate,
    });
  }

  TreatmentWithdrawalsCompanion copyWith({
    Value<int>? id,
    Value<String>? uid,
    Value<Instant>? createdAt,
    Value<Instant>? updatedAt,
    Value<int>? treatment,
    Value<String>? target,
    Value<String>? kind,
    Value<int?>? days,
    Value<LocalDate?>? clearDate,
  }) {
    return TreatmentWithdrawalsCompanion(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      treatment: treatment ?? this.treatment,
      target: target ?? this.target,
      kind: kind ?? this.kind,
      days: days ?? this.days,
      clearDate: clearDate ?? this.clearDate,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uid.present) {
      map['uid'] = Variable<String>(uid.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
        $TreatmentWithdrawalsTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(
        $TreatmentWithdrawalsTable.$converterupdatedAt.toSql(updatedAt.value),
      );
    }
    if (treatment.present) {
      map['treatment'] = Variable<int>(treatment.value);
    }
    if (target.present) {
      map['target'] = Variable<String>(target.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (days.present) {
      map['days'] = Variable<int>(days.value);
    }
    if (clearDate.present) {
      map['clear_date'] = Variable<String>(
        $TreatmentWithdrawalsTable.$converterclearDaten.toSql(clearDate.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TreatmentWithdrawalsCompanion(')
          ..write('id: $id, ')
          ..write('uid: $uid, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('treatment: $treatment, ')
          ..write('target: $target, ')
          ..write('kind: $kind, ')
          ..write('days: $days, ')
          ..write('clearDate: $clearDate')
          ..write(')'))
        .toString();
  }
}

class $PensTable extends Pens with TableInfo<$PensTable, Pen> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PensTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<String> uid = GeneratedColumn<String>(
    'uid',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 36, maxTextLength: 36),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Instant, int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  ).withConverter<Instant>($PensTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<Instant, int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  ).withConverter<Instant>($PensTable.$converterupdatedAt);
  static const VerificationMeta _struckMeta = const VerificationMeta('struck');
  @override
  late final GeneratedColumn<bool> struck = GeneratedColumn<bool>(
    'struck',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("struck" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Instant?, int> struckAt = GeneratedColumn<int>(
    'struck_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  ).withConverter<Instant?>($PensTable.$converterstruckAtn);
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 24),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uid,
    createdAt,
    updatedAt,
    struck,
    struckAt,
    label,
    sortOrder,
    isActive,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pens';
  @override
  VerificationContext validateIntegrity(Insertable<Pen> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uid')) {
      context.handle(_uidMeta, uid.isAcceptableOrUnknown(data['uid']!, _uidMeta));
    } else if (isInserting) {
      context.missing(_uidMeta);
    }
    if (data.containsKey('struck')) {
      context.handle(_struckMeta, struck.isAcceptableOrUnknown(data['struck']!, _struckMeta));
    }
    if (data.containsKey('label')) {
      context.handle(_labelMeta, label.isAcceptableOrUnknown(data['label']!, _labelMeta));
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {label},
  ];
  @override
  Pen map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Pen(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      uid: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}uid'])!,
      createdAt: $PensTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      ),
      updatedAt: $PensTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
      ),
      struck: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}struck'],
      )!,
      struckAt: $PensTable.$converterstruckAtn.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}struck_at']),
      ),
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
    );
  }

  @override
  $PensTable createAlias(String alias) {
    return $PensTable(attachedDatabase, alias);
  }

  static TypeConverter<Instant, int> $convertercreatedAt = const InstantConverter();
  static TypeConverter<Instant, int> $converterupdatedAt = const InstantConverter();
  static TypeConverter<Instant, int> $converterstruckAt = const InstantConverter();
  static TypeConverter<Instant?, int?> $converterstruckAtn = NullAwareTypeConverter.wrap(
    $converterstruckAt,
  );
  @override
  bool get isStrict => true;
}

class Pen extends DataClass implements Insertable<Pen> {
  /// Joins and foreign keys. Device-local. **NEVER exported** (03 §3): a row id
  /// means nothing on another phone, and exporting one invites a restore that
  /// tries to honour it.
  final int id;

  /// UUID v7. The identity that survives export → re-import.
  final String uid;

  /// Instants: UTC epoch millis (§4).
  final Instant createdAt;
  final Instant updatedAt;

  /// Under `STRICT` there is no `BOOLEAN`, hence the first CHECK above.
  ///
  /// The default is **not** a violation of 03 §2 point 5: that rule bans
  /// defaults on columns that could encode veterinary advice — `days`, `ease`,
  /// `status` — and an unstruck row is the only thing a new row can be.
  final bool struck;

  /// An [Instant], not a civil date: a strike happened at a moment, and that is
  /// what makes one recorded at 01:30 on the clocks-back night unambiguous.
  final Instant? struckAt;
  final String label;
  final int sortOrder;
  final bool isActive;
  const Pen({
    required this.id,
    required this.uid,
    required this.createdAt,
    required this.updatedAt,
    required this.struck,
    this.struckAt,
    required this.label,
    required this.sortOrder,
    required this.isActive,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uid'] = Variable<String>(uid);
    {
      map['created_at'] = Variable<int>($PensTable.$convertercreatedAt.toSql(createdAt));
    }
    {
      map['updated_at'] = Variable<int>($PensTable.$converterupdatedAt.toSql(updatedAt));
    }
    map['struck'] = Variable<bool>(struck);
    if (!nullToAbsent || struckAt != null) {
      map['struck_at'] = Variable<int>($PensTable.$converterstruckAtn.toSql(struckAt));
    }
    map['label'] = Variable<String>(label);
    map['sort_order'] = Variable<int>(sortOrder);
    map['is_active'] = Variable<bool>(isActive);
    return map;
  }

  PensCompanion toCompanion(bool nullToAbsent) {
    return PensCompanion(
      id: Value(id),
      uid: Value(uid),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      struck: Value(struck),
      struckAt: struckAt == null && nullToAbsent ? const Value.absent() : Value(struckAt),
      label: Value(label),
      sortOrder: Value(sortOrder),
      isActive: Value(isActive),
    );
  }

  factory Pen.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Pen(
      id: serializer.fromJson<int>(json['id']),
      uid: serializer.fromJson<String>(json['uid']),
      createdAt: serializer.fromJson<Instant>(json['createdAt']),
      updatedAt: serializer.fromJson<Instant>(json['updatedAt']),
      struck: serializer.fromJson<bool>(json['struck']),
      struckAt: serializer.fromJson<Instant?>(json['struckAt']),
      label: serializer.fromJson<String>(json['label']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      isActive: serializer.fromJson<bool>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uid': serializer.toJson<String>(uid),
      'createdAt': serializer.toJson<Instant>(createdAt),
      'updatedAt': serializer.toJson<Instant>(updatedAt),
      'struck': serializer.toJson<bool>(struck),
      'struckAt': serializer.toJson<Instant?>(struckAt),
      'label': serializer.toJson<String>(label),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'isActive': serializer.toJson<bool>(isActive),
    };
  }

  Pen copyWith({
    int? id,
    String? uid,
    Instant? createdAt,
    Instant? updatedAt,
    bool? struck,
    Value<Instant?> struckAt = const Value.absent(),
    String? label,
    int? sortOrder,
    bool? isActive,
  }) => Pen(
    id: id ?? this.id,
    uid: uid ?? this.uid,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    struck: struck ?? this.struck,
    struckAt: struckAt.present ? struckAt.value : this.struckAt,
    label: label ?? this.label,
    sortOrder: sortOrder ?? this.sortOrder,
    isActive: isActive ?? this.isActive,
  );
  Pen copyWithCompanion(PensCompanion data) {
    return Pen(
      id: data.id.present ? data.id.value : this.id,
      uid: data.uid.present ? data.uid.value : this.uid,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      struck: data.struck.present ? data.struck.value : this.struck,
      struckAt: data.struckAt.present ? data.struckAt.value : this.struckAt,
      label: data.label.present ? data.label.value : this.label,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Pen(')
          ..write('id: $id, ')
          ..write('uid: $uid, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('struck: $struck, ')
          ..write('struckAt: $struckAt, ')
          ..write('label: $label, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, uid, createdAt, updatedAt, struck, struckAt, label, sortOrder, isActive);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Pen &&
          other.id == this.id &&
          other.uid == this.uid &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.struck == this.struck &&
          other.struckAt == this.struckAt &&
          other.label == this.label &&
          other.sortOrder == this.sortOrder &&
          other.isActive == this.isActive);
}

class PensCompanion extends UpdateCompanion<Pen> {
  final Value<int> id;
  final Value<String> uid;
  final Value<Instant> createdAt;
  final Value<Instant> updatedAt;
  final Value<bool> struck;
  final Value<Instant?> struckAt;
  final Value<String> label;
  final Value<int> sortOrder;
  final Value<bool> isActive;
  const PensCompanion({
    this.id = const Value.absent(),
    this.uid = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.struck = const Value.absent(),
    this.struckAt = const Value.absent(),
    this.label = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.isActive = const Value.absent(),
  });
  PensCompanion.insert({
    this.id = const Value.absent(),
    required String uid,
    required Instant createdAt,
    required Instant updatedAt,
    this.struck = const Value.absent(),
    this.struckAt = const Value.absent(),
    required String label,
    this.sortOrder = const Value.absent(),
    this.isActive = const Value.absent(),
  }) : uid = Value(uid),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       label = Value(label);
  static Insertable<Pen> custom({
    Expression<int>? id,
    Expression<String>? uid,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<bool>? struck,
    Expression<int>? struckAt,
    Expression<String>? label,
    Expression<int>? sortOrder,
    Expression<bool>? isActive,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uid != null) 'uid': uid,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (struck != null) 'struck': struck,
      if (struckAt != null) 'struck_at': struckAt,
      if (label != null) 'label': label,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (isActive != null) 'is_active': isActive,
    });
  }

  PensCompanion copyWith({
    Value<int>? id,
    Value<String>? uid,
    Value<Instant>? createdAt,
    Value<Instant>? updatedAt,
    Value<bool>? struck,
    Value<Instant?>? struckAt,
    Value<String>? label,
    Value<int>? sortOrder,
    Value<bool>? isActive,
  }) {
    return PensCompanion(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      struck: struck ?? this.struck,
      struckAt: struckAt ?? this.struckAt,
      label: label ?? this.label,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uid.present) {
      map['uid'] = Variable<String>(uid.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>($PensTable.$convertercreatedAt.toSql(createdAt.value));
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>($PensTable.$converterupdatedAt.toSql(updatedAt.value));
    }
    if (struck.present) {
      map['struck'] = Variable<bool>(struck.value);
    }
    if (struckAt.present) {
      map['struck_at'] = Variable<int>($PensTable.$converterstruckAtn.toSql(struckAt.value));
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PensCompanion(')
          ..write('id: $id, ')
          ..write('uid: $uid, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('struck: $struck, ')
          ..write('struckAt: $struckAt, ')
          ..write('label: $label, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }
}

class $PenOccupanciesTable extends PenOccupancies
    with TableInfo<$PenOccupanciesTable, PenOccupancy> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PenOccupanciesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<String> uid = GeneratedColumn<String>(
    'uid',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 36, maxTextLength: 36),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Instant, int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  ).withConverter<Instant>($PenOccupanciesTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<Instant, int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  ).withConverter<Instant>($PenOccupanciesTable.$converterupdatedAt);
  static const VerificationMeta _struckMeta = const VerificationMeta('struck');
  @override
  late final GeneratedColumn<bool> struck = GeneratedColumn<bool>(
    'struck',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("struck" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Instant?, int> struckAt = GeneratedColumn<int>(
    'struck_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  ).withConverter<Instant?>($PenOccupanciesTable.$converterstruckAtn);
  static const VerificationMeta _penMeta = const VerificationMeta('pen');
  @override
  late final GeneratedColumn<int> pen = GeneratedColumn<int>(
    'pen',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES pens (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _seasonMeta = const VerificationMeta('season');
  @override
  late final GeneratedColumn<int> season = GeneratedColumn<int>(
    'season',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES seasons (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _eweMeta = const VerificationMeta('ewe');
  @override
  late final GeneratedColumn<int> ewe = GeneratedColumn<int>(
    'ewe',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES ewes (id) ON DELETE RESTRICT',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Instant, int> enteredAt = GeneratedColumn<int>(
    'entered_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  ).withConverter<Instant>($PenOccupanciesTable.$converterenteredAt);
  @override
  late final GeneratedColumnWithTypeConverter<Instant, int> capturedAt = GeneratedColumn<int>(
    'captured_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  ).withConverter<Instant>($PenOccupanciesTable.$convertercapturedAt);
  @override
  late final GeneratedColumnWithTypeConverter<Instant?, int> originalEffective =
      GeneratedColumn<int>(
        'original_effective',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<Instant?>($PenOccupanciesTable.$converteroriginalEffectiven);
  static const VerificationMeta _timeSourceMeta = const VerificationMeta('timeSource');
  @override
  late final GeneratedColumn<String> timeSource = GeneratedColumn<String>(
    'time_source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('auto'),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Instant?, int> exitedAt = GeneratedColumn<int>(
    'exited_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  ).withConverter<Instant?>($PenOccupanciesTable.$converterexitedAtn);
  static const VerificationMeta _exitReasonMeta = const VerificationMeta('exitReason');
  @override
  late final GeneratedColumn<String> exitReason = GeneratedColumn<String>(
    'exit_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uid,
    createdAt,
    updatedAt,
    struck,
    struckAt,
    pen,
    season,
    ewe,
    enteredAt,
    capturedAt,
    originalEffective,
    timeSource,
    exitedAt,
    exitReason,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pen_occupancies';
  @override
  VerificationContext validateIntegrity(
    Insertable<PenOccupancy> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uid')) {
      context.handle(_uidMeta, uid.isAcceptableOrUnknown(data['uid']!, _uidMeta));
    } else if (isInserting) {
      context.missing(_uidMeta);
    }
    if (data.containsKey('struck')) {
      context.handle(_struckMeta, struck.isAcceptableOrUnknown(data['struck']!, _struckMeta));
    }
    if (data.containsKey('pen')) {
      context.handle(_penMeta, pen.isAcceptableOrUnknown(data['pen']!, _penMeta));
    } else if (isInserting) {
      context.missing(_penMeta);
    }
    if (data.containsKey('season')) {
      context.handle(_seasonMeta, season.isAcceptableOrUnknown(data['season']!, _seasonMeta));
    } else if (isInserting) {
      context.missing(_seasonMeta);
    }
    if (data.containsKey('ewe')) {
      context.handle(_eweMeta, ewe.isAcceptableOrUnknown(data['ewe']!, _eweMeta));
    }
    if (data.containsKey('time_source')) {
      context.handle(
        _timeSourceMeta,
        timeSource.isAcceptableOrUnknown(data['time_source']!, _timeSourceMeta),
      );
    }
    if (data.containsKey('exit_reason')) {
      context.handle(
        _exitReasonMeta,
        exitReason.isAcceptableOrUnknown(data['exit_reason']!, _exitReasonMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PenOccupancy map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PenOccupancy(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      uid: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}uid'])!,
      createdAt: $PenOccupanciesTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      ),
      updatedAt: $PenOccupanciesTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
      ),
      struck: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}struck'],
      )!,
      struckAt: $PenOccupanciesTable.$converterstruckAtn.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}struck_at']),
      ),
      pen: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}pen'])!,
      season: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}season'],
      )!,
      ewe: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}ewe']),
      enteredAt: $PenOccupanciesTable.$converterenteredAt.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}entered_at'])!,
      ),
      capturedAt: $PenOccupanciesTable.$convertercapturedAt.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}captured_at'])!,
      ),
      originalEffective: $PenOccupanciesTable.$converteroriginalEffectiven.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}original_effective'],
        ),
      ),
      timeSource: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}time_source'],
      )!,
      exitedAt: $PenOccupanciesTable.$converterexitedAtn.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}exited_at']),
      ),
      exitReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exit_reason'],
      ),
    );
  }

  @override
  $PenOccupanciesTable createAlias(String alias) {
    return $PenOccupanciesTable(attachedDatabase, alias);
  }

  static TypeConverter<Instant, int> $convertercreatedAt = const InstantConverter();
  static TypeConverter<Instant, int> $converterupdatedAt = const InstantConverter();
  static TypeConverter<Instant, int> $converterstruckAt = const InstantConverter();
  static TypeConverter<Instant?, int?> $converterstruckAtn = NullAwareTypeConverter.wrap(
    $converterstruckAt,
  );
  static TypeConverter<Instant, int> $converterenteredAt = const InstantConverter();
  static TypeConverter<Instant, int> $convertercapturedAt = const InstantConverter();
  static TypeConverter<Instant, int> $converteroriginalEffective = const InstantConverter();
  static TypeConverter<Instant?, int?> $converteroriginalEffectiven = NullAwareTypeConverter.wrap(
    $converteroriginalEffective,
  );
  static TypeConverter<Instant, int> $converterexitedAt = const InstantConverter();
  static TypeConverter<Instant?, int?> $converterexitedAtn = NullAwareTypeConverter.wrap(
    $converterexitedAt,
  );
  @override
  bool get isStrict => true;
}

class PenOccupancy extends DataClass implements Insertable<PenOccupancy> {
  /// Joins and foreign keys. Device-local. **NEVER exported** (03 §3): a row id
  /// means nothing on another phone, and exporting one invites a restore that
  /// tries to honour it.
  final int id;

  /// UUID v7. The identity that survives export → re-import.
  final String uid;

  /// Instants: UTC epoch millis (§4).
  final Instant createdAt;
  final Instant updatedAt;

  /// Under `STRICT` there is no `BOOLEAN`, hence the first CHECK above.
  ///
  /// The default is **not** a violation of 03 §2 point 5: that rule bans
  /// defaults on columns that could encode veterinary advice — `days`, `ease`,
  /// `status` — and an unstruck row is the only thing a new row can be.
  final bool struck;

  /// An [Instant], not a civil date: a strike happened at a moment, and that is
  /// what makes one recorded at 01:30 on the clocks-back night unambiguous.
  final Instant? struckAt;
  final int pen;
  final int season;
  final int? ewe;

  /// The event time. One of the three documented exceptions to the
  /// `occurred_at` column-name rule (R37).
  final Instant enteredAt;
  final Instant capturedAt;
  final Instant? originalEffective;
  final String timeSource;
  final Instant? exitedAt;

  /// The stored keys of `PenExitReason`. **Not optional when `exited_at` is
  /// set** — the paired CHECK below is what makes `exitPen`'s `required reason`
  /// storable rather than merely conventional.
  final String? exitReason;
  const PenOccupancy({
    required this.id,
    required this.uid,
    required this.createdAt,
    required this.updatedAt,
    required this.struck,
    this.struckAt,
    required this.pen,
    required this.season,
    this.ewe,
    required this.enteredAt,
    required this.capturedAt,
    this.originalEffective,
    required this.timeSource,
    this.exitedAt,
    this.exitReason,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uid'] = Variable<String>(uid);
    {
      map['created_at'] = Variable<int>($PenOccupanciesTable.$convertercreatedAt.toSql(createdAt));
    }
    {
      map['updated_at'] = Variable<int>($PenOccupanciesTable.$converterupdatedAt.toSql(updatedAt));
    }
    map['struck'] = Variable<bool>(struck);
    if (!nullToAbsent || struckAt != null) {
      map['struck_at'] = Variable<int>($PenOccupanciesTable.$converterstruckAtn.toSql(struckAt));
    }
    map['pen'] = Variable<int>(pen);
    map['season'] = Variable<int>(season);
    if (!nullToAbsent || ewe != null) {
      map['ewe'] = Variable<int>(ewe);
    }
    {
      map['entered_at'] = Variable<int>($PenOccupanciesTable.$converterenteredAt.toSql(enteredAt));
    }
    {
      map['captured_at'] = Variable<int>(
        $PenOccupanciesTable.$convertercapturedAt.toSql(capturedAt),
      );
    }
    if (!nullToAbsent || originalEffective != null) {
      map['original_effective'] = Variable<int>(
        $PenOccupanciesTable.$converteroriginalEffectiven.toSql(originalEffective),
      );
    }
    map['time_source'] = Variable<String>(timeSource);
    if (!nullToAbsent || exitedAt != null) {
      map['exited_at'] = Variable<int>($PenOccupanciesTable.$converterexitedAtn.toSql(exitedAt));
    }
    if (!nullToAbsent || exitReason != null) {
      map['exit_reason'] = Variable<String>(exitReason);
    }
    return map;
  }

  PenOccupanciesCompanion toCompanion(bool nullToAbsent) {
    return PenOccupanciesCompanion(
      id: Value(id),
      uid: Value(uid),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      struck: Value(struck),
      struckAt: struckAt == null && nullToAbsent ? const Value.absent() : Value(struckAt),
      pen: Value(pen),
      season: Value(season),
      ewe: ewe == null && nullToAbsent ? const Value.absent() : Value(ewe),
      enteredAt: Value(enteredAt),
      capturedAt: Value(capturedAt),
      originalEffective: originalEffective == null && nullToAbsent
          ? const Value.absent()
          : Value(originalEffective),
      timeSource: Value(timeSource),
      exitedAt: exitedAt == null && nullToAbsent ? const Value.absent() : Value(exitedAt),
      exitReason: exitReason == null && nullToAbsent ? const Value.absent() : Value(exitReason),
    );
  }

  factory PenOccupancy.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PenOccupancy(
      id: serializer.fromJson<int>(json['id']),
      uid: serializer.fromJson<String>(json['uid']),
      createdAt: serializer.fromJson<Instant>(json['createdAt']),
      updatedAt: serializer.fromJson<Instant>(json['updatedAt']),
      struck: serializer.fromJson<bool>(json['struck']),
      struckAt: serializer.fromJson<Instant?>(json['struckAt']),
      pen: serializer.fromJson<int>(json['pen']),
      season: serializer.fromJson<int>(json['season']),
      ewe: serializer.fromJson<int?>(json['ewe']),
      enteredAt: serializer.fromJson<Instant>(json['enteredAt']),
      capturedAt: serializer.fromJson<Instant>(json['capturedAt']),
      originalEffective: serializer.fromJson<Instant?>(json['originalEffective']),
      timeSource: serializer.fromJson<String>(json['timeSource']),
      exitedAt: serializer.fromJson<Instant?>(json['exitedAt']),
      exitReason: serializer.fromJson<String?>(json['exitReason']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uid': serializer.toJson<String>(uid),
      'createdAt': serializer.toJson<Instant>(createdAt),
      'updatedAt': serializer.toJson<Instant>(updatedAt),
      'struck': serializer.toJson<bool>(struck),
      'struckAt': serializer.toJson<Instant?>(struckAt),
      'pen': serializer.toJson<int>(pen),
      'season': serializer.toJson<int>(season),
      'ewe': serializer.toJson<int?>(ewe),
      'enteredAt': serializer.toJson<Instant>(enteredAt),
      'capturedAt': serializer.toJson<Instant>(capturedAt),
      'originalEffective': serializer.toJson<Instant?>(originalEffective),
      'timeSource': serializer.toJson<String>(timeSource),
      'exitedAt': serializer.toJson<Instant?>(exitedAt),
      'exitReason': serializer.toJson<String?>(exitReason),
    };
  }

  PenOccupancy copyWith({
    int? id,
    String? uid,
    Instant? createdAt,
    Instant? updatedAt,
    bool? struck,
    Value<Instant?> struckAt = const Value.absent(),
    int? pen,
    int? season,
    Value<int?> ewe = const Value.absent(),
    Instant? enteredAt,
    Instant? capturedAt,
    Value<Instant?> originalEffective = const Value.absent(),
    String? timeSource,
    Value<Instant?> exitedAt = const Value.absent(),
    Value<String?> exitReason = const Value.absent(),
  }) => PenOccupancy(
    id: id ?? this.id,
    uid: uid ?? this.uid,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    struck: struck ?? this.struck,
    struckAt: struckAt.present ? struckAt.value : this.struckAt,
    pen: pen ?? this.pen,
    season: season ?? this.season,
    ewe: ewe.present ? ewe.value : this.ewe,
    enteredAt: enteredAt ?? this.enteredAt,
    capturedAt: capturedAt ?? this.capturedAt,
    originalEffective: originalEffective.present ? originalEffective.value : this.originalEffective,
    timeSource: timeSource ?? this.timeSource,
    exitedAt: exitedAt.present ? exitedAt.value : this.exitedAt,
    exitReason: exitReason.present ? exitReason.value : this.exitReason,
  );
  PenOccupancy copyWithCompanion(PenOccupanciesCompanion data) {
    return PenOccupancy(
      id: data.id.present ? data.id.value : this.id,
      uid: data.uid.present ? data.uid.value : this.uid,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      struck: data.struck.present ? data.struck.value : this.struck,
      struckAt: data.struckAt.present ? data.struckAt.value : this.struckAt,
      pen: data.pen.present ? data.pen.value : this.pen,
      season: data.season.present ? data.season.value : this.season,
      ewe: data.ewe.present ? data.ewe.value : this.ewe,
      enteredAt: data.enteredAt.present ? data.enteredAt.value : this.enteredAt,
      capturedAt: data.capturedAt.present ? data.capturedAt.value : this.capturedAt,
      originalEffective: data.originalEffective.present
          ? data.originalEffective.value
          : this.originalEffective,
      timeSource: data.timeSource.present ? data.timeSource.value : this.timeSource,
      exitedAt: data.exitedAt.present ? data.exitedAt.value : this.exitedAt,
      exitReason: data.exitReason.present ? data.exitReason.value : this.exitReason,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PenOccupancy(')
          ..write('id: $id, ')
          ..write('uid: $uid, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('struck: $struck, ')
          ..write('struckAt: $struckAt, ')
          ..write('pen: $pen, ')
          ..write('season: $season, ')
          ..write('ewe: $ewe, ')
          ..write('enteredAt: $enteredAt, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('originalEffective: $originalEffective, ')
          ..write('timeSource: $timeSource, ')
          ..write('exitedAt: $exitedAt, ')
          ..write('exitReason: $exitReason')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    uid,
    createdAt,
    updatedAt,
    struck,
    struckAt,
    pen,
    season,
    ewe,
    enteredAt,
    capturedAt,
    originalEffective,
    timeSource,
    exitedAt,
    exitReason,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PenOccupancy &&
          other.id == this.id &&
          other.uid == this.uid &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.struck == this.struck &&
          other.struckAt == this.struckAt &&
          other.pen == this.pen &&
          other.season == this.season &&
          other.ewe == this.ewe &&
          other.enteredAt == this.enteredAt &&
          other.capturedAt == this.capturedAt &&
          other.originalEffective == this.originalEffective &&
          other.timeSource == this.timeSource &&
          other.exitedAt == this.exitedAt &&
          other.exitReason == this.exitReason);
}

class PenOccupanciesCompanion extends UpdateCompanion<PenOccupancy> {
  final Value<int> id;
  final Value<String> uid;
  final Value<Instant> createdAt;
  final Value<Instant> updatedAt;
  final Value<bool> struck;
  final Value<Instant?> struckAt;
  final Value<int> pen;
  final Value<int> season;
  final Value<int?> ewe;
  final Value<Instant> enteredAt;
  final Value<Instant> capturedAt;
  final Value<Instant?> originalEffective;
  final Value<String> timeSource;
  final Value<Instant?> exitedAt;
  final Value<String?> exitReason;
  const PenOccupanciesCompanion({
    this.id = const Value.absent(),
    this.uid = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.struck = const Value.absent(),
    this.struckAt = const Value.absent(),
    this.pen = const Value.absent(),
    this.season = const Value.absent(),
    this.ewe = const Value.absent(),
    this.enteredAt = const Value.absent(),
    this.capturedAt = const Value.absent(),
    this.originalEffective = const Value.absent(),
    this.timeSource = const Value.absent(),
    this.exitedAt = const Value.absent(),
    this.exitReason = const Value.absent(),
  });
  PenOccupanciesCompanion.insert({
    this.id = const Value.absent(),
    required String uid,
    required Instant createdAt,
    required Instant updatedAt,
    this.struck = const Value.absent(),
    this.struckAt = const Value.absent(),
    required int pen,
    required int season,
    this.ewe = const Value.absent(),
    required Instant enteredAt,
    required Instant capturedAt,
    this.originalEffective = const Value.absent(),
    this.timeSource = const Value.absent(),
    this.exitedAt = const Value.absent(),
    this.exitReason = const Value.absent(),
  }) : uid = Value(uid),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       pen = Value(pen),
       season = Value(season),
       enteredAt = Value(enteredAt),
       capturedAt = Value(capturedAt);
  static Insertable<PenOccupancy> custom({
    Expression<int>? id,
    Expression<String>? uid,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<bool>? struck,
    Expression<int>? struckAt,
    Expression<int>? pen,
    Expression<int>? season,
    Expression<int>? ewe,
    Expression<int>? enteredAt,
    Expression<int>? capturedAt,
    Expression<int>? originalEffective,
    Expression<String>? timeSource,
    Expression<int>? exitedAt,
    Expression<String>? exitReason,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uid != null) 'uid': uid,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (struck != null) 'struck': struck,
      if (struckAt != null) 'struck_at': struckAt,
      if (pen != null) 'pen': pen,
      if (season != null) 'season': season,
      if (ewe != null) 'ewe': ewe,
      if (enteredAt != null) 'entered_at': enteredAt,
      if (capturedAt != null) 'captured_at': capturedAt,
      if (originalEffective != null) 'original_effective': originalEffective,
      if (timeSource != null) 'time_source': timeSource,
      if (exitedAt != null) 'exited_at': exitedAt,
      if (exitReason != null) 'exit_reason': exitReason,
    });
  }

  PenOccupanciesCompanion copyWith({
    Value<int>? id,
    Value<String>? uid,
    Value<Instant>? createdAt,
    Value<Instant>? updatedAt,
    Value<bool>? struck,
    Value<Instant?>? struckAt,
    Value<int>? pen,
    Value<int>? season,
    Value<int?>? ewe,
    Value<Instant>? enteredAt,
    Value<Instant>? capturedAt,
    Value<Instant?>? originalEffective,
    Value<String>? timeSource,
    Value<Instant?>? exitedAt,
    Value<String?>? exitReason,
  }) {
    return PenOccupanciesCompanion(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      struck: struck ?? this.struck,
      struckAt: struckAt ?? this.struckAt,
      pen: pen ?? this.pen,
      season: season ?? this.season,
      ewe: ewe ?? this.ewe,
      enteredAt: enteredAt ?? this.enteredAt,
      capturedAt: capturedAt ?? this.capturedAt,
      originalEffective: originalEffective ?? this.originalEffective,
      timeSource: timeSource ?? this.timeSource,
      exitedAt: exitedAt ?? this.exitedAt,
      exitReason: exitReason ?? this.exitReason,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uid.present) {
      map['uid'] = Variable<String>(uid.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
        $PenOccupanciesTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(
        $PenOccupanciesTable.$converterupdatedAt.toSql(updatedAt.value),
      );
    }
    if (struck.present) {
      map['struck'] = Variable<bool>(struck.value);
    }
    if (struckAt.present) {
      map['struck_at'] = Variable<int>(
        $PenOccupanciesTable.$converterstruckAtn.toSql(struckAt.value),
      );
    }
    if (pen.present) {
      map['pen'] = Variable<int>(pen.value);
    }
    if (season.present) {
      map['season'] = Variable<int>(season.value);
    }
    if (ewe.present) {
      map['ewe'] = Variable<int>(ewe.value);
    }
    if (enteredAt.present) {
      map['entered_at'] = Variable<int>(
        $PenOccupanciesTable.$converterenteredAt.toSql(enteredAt.value),
      );
    }
    if (capturedAt.present) {
      map['captured_at'] = Variable<int>(
        $PenOccupanciesTable.$convertercapturedAt.toSql(capturedAt.value),
      );
    }
    if (originalEffective.present) {
      map['original_effective'] = Variable<int>(
        $PenOccupanciesTable.$converteroriginalEffectiven.toSql(originalEffective.value),
      );
    }
    if (timeSource.present) {
      map['time_source'] = Variable<String>(timeSource.value);
    }
    if (exitedAt.present) {
      map['exited_at'] = Variable<int>(
        $PenOccupanciesTable.$converterexitedAtn.toSql(exitedAt.value),
      );
    }
    if (exitReason.present) {
      map['exit_reason'] = Variable<String>(exitReason.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PenOccupanciesCompanion(')
          ..write('id: $id, ')
          ..write('uid: $uid, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('struck: $struck, ')
          ..write('struckAt: $struckAt, ')
          ..write('pen: $pen, ')
          ..write('season: $season, ')
          ..write('ewe: $ewe, ')
          ..write('enteredAt: $enteredAt, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('originalEffective: $originalEffective, ')
          ..write('timeSource: $timeSource, ')
          ..write('exitedAt: $exitedAt, ')
          ..write('exitReason: $exitReason')
          ..write(')'))
        .toString();
  }
}

class $PenOccupancyLambsTable extends PenOccupancyLambs
    with TableInfo<$PenOccupancyLambsTable, PenOccupancyLamb> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PenOccupancyLambsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _occupancyMeta = const VerificationMeta('occupancy');
  @override
  late final GeneratedColumn<int> occupancy = GeneratedColumn<int>(
    'occupancy',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES pen_occupancies (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _lambMeta = const VerificationMeta('lamb');
  @override
  late final GeneratedColumn<int> lamb = GeneratedColumn<int>(
    'lamb',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES lambs (id) ON DELETE CASCADE',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [occupancy, lamb];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pen_occupancy_lambs';
  @override
  VerificationContext validateIntegrity(
    Insertable<PenOccupancyLamb> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('occupancy')) {
      context.handle(
        _occupancyMeta,
        occupancy.isAcceptableOrUnknown(data['occupancy']!, _occupancyMeta),
      );
    } else if (isInserting) {
      context.missing(_occupancyMeta);
    }
    if (data.containsKey('lamb')) {
      context.handle(_lambMeta, lamb.isAcceptableOrUnknown(data['lamb']!, _lambMeta));
    } else if (isInserting) {
      context.missing(_lambMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {occupancy, lamb};
  @override
  PenOccupancyLamb map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PenOccupancyLamb(
      occupancy: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}occupancy'],
      )!,
      lamb: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}lamb'])!,
    );
  }

  @override
  $PenOccupancyLambsTable createAlias(String alias) {
    return $PenOccupancyLambsTable(attachedDatabase, alias);
  }

  @override
  bool get isStrict => true;
}

class PenOccupancyLamb extends DataClass implements Insertable<PenOccupancyLamb> {
  final int occupancy;
  final int lamb;
  const PenOccupancyLamb({required this.occupancy, required this.lamb});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['occupancy'] = Variable<int>(occupancy);
    map['lamb'] = Variable<int>(lamb);
    return map;
  }

  PenOccupancyLambsCompanion toCompanion(bool nullToAbsent) {
    return PenOccupancyLambsCompanion(occupancy: Value(occupancy), lamb: Value(lamb));
  }

  factory PenOccupancyLamb.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PenOccupancyLamb(
      occupancy: serializer.fromJson<int>(json['occupancy']),
      lamb: serializer.fromJson<int>(json['lamb']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'occupancy': serializer.toJson<int>(occupancy),
      'lamb': serializer.toJson<int>(lamb),
    };
  }

  PenOccupancyLamb copyWith({int? occupancy, int? lamb}) =>
      PenOccupancyLamb(occupancy: occupancy ?? this.occupancy, lamb: lamb ?? this.lamb);
  PenOccupancyLamb copyWithCompanion(PenOccupancyLambsCompanion data) {
    return PenOccupancyLamb(
      occupancy: data.occupancy.present ? data.occupancy.value : this.occupancy,
      lamb: data.lamb.present ? data.lamb.value : this.lamb,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PenOccupancyLamb(')
          ..write('occupancy: $occupancy, ')
          ..write('lamb: $lamb')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(occupancy, lamb);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PenOccupancyLamb && other.occupancy == this.occupancy && other.lamb == this.lamb);
}

class PenOccupancyLambsCompanion extends UpdateCompanion<PenOccupancyLamb> {
  final Value<int> occupancy;
  final Value<int> lamb;
  final Value<int> rowid;
  const PenOccupancyLambsCompanion({
    this.occupancy = const Value.absent(),
    this.lamb = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PenOccupancyLambsCompanion.insert({
    required int occupancy,
    required int lamb,
    this.rowid = const Value.absent(),
  }) : occupancy = Value(occupancy),
       lamb = Value(lamb);
  static Insertable<PenOccupancyLamb> custom({
    Expression<int>? occupancy,
    Expression<int>? lamb,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (occupancy != null) 'occupancy': occupancy,
      if (lamb != null) 'lamb': lamb,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PenOccupancyLambsCompanion copyWith({
    Value<int>? occupancy,
    Value<int>? lamb,
    Value<int>? rowid,
  }) {
    return PenOccupancyLambsCompanion(
      occupancy: occupancy ?? this.occupancy,
      lamb: lamb ?? this.lamb,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (occupancy.present) {
      map['occupancy'] = Variable<int>(occupancy.value);
    }
    if (lamb.present) {
      map['lamb'] = Variable<int>(lamb.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PenOccupancyLambsCompanion(')
          ..write('occupancy: $occupancy, ')
          ..write('lamb: $lamb, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SeasonsTable seasons = $SeasonsTable(this);
  late final $EwesTable ewes = $EwesTable(this);
  late final $LambingsTable lambings = $LambingsTable(this);
  late final $LambsTable lambs = $LambsTable(this);
  late final Trigger lambBirthDamIsImmutable = Trigger(
    'CREATE TRIGGER lamb_birth_dam_is_immutable BEFORE UPDATE OF birth_dam ON lambs WHEN old.birth_dam IS NOT new.birth_dam BEGIN SELECT RAISE (ABORT, \'birth_dam is immutable; record a foster instead\');END',
    'lamb_birth_dam_is_immutable',
  );
  late final Index idxLambingSeasonTime = Index(
    'idx_lambing_season_time',
    'CREATE INDEX idx_lambing_season_time ON lambings (season, occurred_at)',
  );
  late final Index idxLambingEweTime = Index(
    'idx_lambing_ewe_time',
    'CREATE INDEX idx_lambing_ewe_time ON lambings (ewe, occurred_at)',
  );
  late final Index idxLambingLocaldate = Index(
    'idx_lambing_localdate',
    'CREATE INDEX idx_lambing_localdate ON lambings (season, local_date)',
  );
  late final Index idxLambingPresentation = Index(
    'idx_lambing_presentation',
    'CREATE INDEX idx_lambing_presentation ON lambings (presentation)',
  );
  late final Index idxLambLambing = Index(
    'idx_lamb_lambing',
    'CREATE INDEX idx_lamb_lambing ON lambs (lambing)',
  );
  late final Index idxLambBirthdam = Index(
    'idx_lamb_birthdam',
    'CREATE INDEX idx_lamb_birthdam ON lambs (birth_dam)',
  );
  late final Index idxLambTagdigits = Index(
    'idx_lamb_tagdigits',
    'CREATE INDEX idx_lamb_tagdigits ON lambs (tag_digits)',
  );
  late final Index idxLambDeathcause = Index(
    'idx_lamb_deathcause',
    'CREATE INDEX idx_lamb_deathcause ON lambs (death_cause)',
  );
  late final Index idxLambBecameEwe = Index(
    'idx_lamb_became_ewe',
    'CREATE INDEX idx_lamb_became_ewe ON lambs (became_ewe)',
  );
  late final Index idxLambTagAlive = Index(
    'idx_lamb_tag_alive',
    'CREATE UNIQUE INDEX idx_lamb_tag_alive ON lambs (tag) WHERE tag IS NOT NULL AND status = \'alive\' AND struck = 0',
  );
  late final Index idxSeasonStart = Index(
    'idx_season_start',
    'CREATE INDEX idx_season_start ON seasons (start_date)',
  );
  late final $EweSeasonsTable eweSeasons = $EweSeasonsTable(this);
  late final $EweTouchesTable eweTouches = $EweTouchesTable(this);
  late final $EweObservationsTable eweObservations = $EweObservationsTable(this);
  late final Index idxEweStatus = Index(
    'idx_ewe_status',
    'CREATE INDEX idx_ewe_status ON ewes (status)',
  );
  late final Index idxEweTagdigits = Index(
    'idx_ewe_tagdigits',
    'CREATE INDEX idx_ewe_tagdigits ON ewes (tag_digits)',
  );
  late final Index idxEweTagActive = Index(
    'idx_ewe_tag_active',
    'CREATE UNIQUE INDEX idx_ewe_tag_active ON ewes (tag) WHERE status = \'active\' AND struck = 0',
  );
  late final Index idxEweseasonSeason = Index(
    'idx_eweseason_season',
    'CREATE INDEX idx_eweseason_season ON ewe_seasons (season)',
  );
  late final Index idxEweseasonEwe = Index(
    'idx_eweseason_ewe',
    'CREATE INDEX idx_eweseason_ewe ON ewe_seasons (ewe)',
  );
  late final Index idxEweobsEweTime = Index(
    'idx_eweobs_ewe_time',
    'CREATE INDEX idx_eweobs_ewe_time ON ewe_observations (ewe, occurred_at)',
  );
  late final Index idxEweobsSeasonKind = Index(
    'idx_eweobs_season_kind',
    'CREATE INDEX idx_eweobs_season_kind ON ewe_observations (season, kind)',
  );
  late final Index idxEweobsKind = Index(
    'idx_eweobs_kind',
    'CREATE INDEX idx_eweobs_kind ON ewe_observations (kind)',
  );
  late final Index idxEweobsLambing = Index(
    'idx_eweobs_lambing',
    'CREATE INDEX idx_eweobs_lambing ON ewe_observations (lambing)',
  );
  late final $TreatmentsTable treatments = $TreatmentsTable(this);
  late final $TreatmentWithdrawalsTable treatmentWithdrawals = $TreatmentWithdrawalsTable(this);
  late final $PensTable pens = $PensTable(this);
  late final $PenOccupanciesTable penOccupancies = $PenOccupanciesTable(this);
  late final $PenOccupancyLambsTable penOccupancyLambs = $PenOccupancyLambsTable(this);
  late final Index idxTreatmentEweTime = Index(
    'idx_treatment_ewe_time',
    'CREATE INDEX idx_treatment_ewe_time ON treatments (ewe, administered_at)',
  );
  late final Index idxTreatmentLambTime = Index(
    'idx_treatment_lamb_time',
    'CREATE INDEX idx_treatment_lamb_time ON treatments (lamb, administered_at)',
  );
  late final Index idxTreatmentSeasonTime = Index(
    'idx_treatment_season_time',
    'CREATE INDEX idx_treatment_season_time ON treatments (season, administered_at)',
  );
  late final Index idxTreatmentRoute = Index(
    'idx_treatment_route',
    'CREATE INDEX idx_treatment_route ON treatments (route)',
  );
  late final Index idxWithdrawalClear = Index(
    'idx_withdrawal_clear',
    'CREATE INDEX idx_withdrawal_clear ON treatment_withdrawals (clear_date)',
  );
  late final Index idxPenoccPenTime = Index(
    'idx_penocc_pen_time',
    'CREATE INDEX idx_penocc_pen_time ON pen_occupancies (pen, entered_at)',
  );
  late final Index idxPenoccEwe = Index(
    'idx_penocc_ewe',
    'CREATE INDEX idx_penocc_ewe ON pen_occupancies (ewe)',
  );
  late final Index idxPenoccSeason = Index(
    'idx_penocc_season',
    'CREATE INDEX idx_penocc_season ON pen_occupancies (season)',
  );
  late final Index idxPenoccOneOpen = Index(
    'idx_penocc_one_open',
    'CREATE UNIQUE INDEX idx_penocc_one_open ON pen_occupancies (pen) WHERE exited_at IS NULL',
  );
  late final Index idxPenocclambLamb = Index(
    'idx_penocclamb_lamb',
    'CREATE INDEX idx_penocclamb_lamb ON pen_occupancy_lambs (lamb)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    seasons,
    ewes,
    lambings,
    lambs,
    lambBirthDamIsImmutable,
    idxLambingSeasonTime,
    idxLambingEweTime,
    idxLambingLocaldate,
    idxLambingPresentation,
    idxLambLambing,
    idxLambBirthdam,
    idxLambTagdigits,
    idxLambDeathcause,
    idxLambBecameEwe,
    idxLambTagAlive,
    idxSeasonStart,
    eweSeasons,
    eweTouches,
    eweObservations,
    idxEweStatus,
    idxEweTagdigits,
    idxEweTagActive,
    idxEweseasonSeason,
    idxEweseasonEwe,
    idxEweobsEweTime,
    idxEweobsSeasonKind,
    idxEweobsKind,
    idxEweobsLambing,
    treatments,
    treatmentWithdrawals,
    pens,
    penOccupancies,
    penOccupancyLambs,
    idxTreatmentEweTime,
    idxTreatmentLambTime,
    idxTreatmentSeasonTime,
    idxTreatmentRoute,
    idxWithdrawalClear,
    idxPenoccPenTime,
    idxPenoccEwe,
    idxPenoccSeason,
    idxPenoccOneOpen,
    idxPenocclambLamb,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName('seasons', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('lambings', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('lambings', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('lambs', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('ewes', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('lambs', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('lambs', limitUpdateKind: UpdateKind.update),
      result: [],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('seasons', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('ewe_seasons', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('ewes', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('ewe_seasons', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('ewes', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('ewe_touches', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('ewes', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('ewe_observations', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('seasons', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('ewe_observations', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('lambings', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('ewe_observations', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('seasons', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('treatments', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('lambs', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('treatments', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('treatments', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('treatment_withdrawals', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('seasons', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('pen_occupancies', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('pen_occupancies', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('pen_occupancy_lambs', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('lambs', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('pen_occupancy_lambs', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$SeasonsTableCreateCompanionBuilder =
    SeasonsCompanion Function({
      Value<int> id,
      required String uid,
      required Instant createdAt,
      required Instant updatedAt,
      Value<bool> struck,
      Value<Instant?> struckAt,
      required int year,
      required String label,
      required LocalDate startDate,
      Value<LocalDate?> endDate,
      Value<int?> ewesToRam,
      Value<int?> scanningResult,
      Value<String?> notes,
      Value<bool> overFreeCap,
    });
typedef $$SeasonsTableUpdateCompanionBuilder =
    SeasonsCompanion Function({
      Value<int> id,
      Value<String> uid,
      Value<Instant> createdAt,
      Value<Instant> updatedAt,
      Value<bool> struck,
      Value<Instant?> struckAt,
      Value<int> year,
      Value<String> label,
      Value<LocalDate> startDate,
      Value<LocalDate?> endDate,
      Value<int?> ewesToRam,
      Value<int?> scanningResult,
      Value<String?> notes,
      Value<bool> overFreeCap,
    });

final class $$SeasonsTableReferences extends BaseReferences<_$AppDatabase, $SeasonsTable, Season> {
  $$SeasonsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$LambingsTable, List<Lambing>> _lambingsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.lambings, aliasName: 'seasons__id__lambings__season');

  $$LambingsTableProcessedTableManager get lambingsRefs {
    final manager = $$LambingsTableTableManager(
      $_db,
      $_db.lambings,
    ).filter((f) => f.season.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_lambingsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$EweSeasonsTable, List<EweSeason>> _eweSeasonsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(db.eweSeasons, aliasName: 'seasons__id__ewe_seasons__season');

  $$EweSeasonsTableProcessedTableManager get eweSeasonsRefs {
    final manager = $$EweSeasonsTableTableManager(
      $_db,
      $_db.eweSeasons,
    ).filter((f) => f.season.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_eweSeasonsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$EweObservationsTable, List<EweObservation>> _eweObservationsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.eweObservations,
    aliasName: 'seasons__id__ewe_observations__season',
  );

  $$EweObservationsTableProcessedTableManager get eweObservationsRefs {
    final manager = $$EweObservationsTableTableManager(
      $_db,
      $_db.eweObservations,
    ).filter((f) => f.season.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_eweObservationsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$TreatmentsTable, List<Treatment>> _treatmentsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(db.treatments, aliasName: 'seasons__id__treatments__season');

  $$TreatmentsTableProcessedTableManager get treatmentsRefs {
    final manager = $$TreatmentsTableTableManager(
      $_db,
      $_db.treatments,
    ).filter((f) => f.season.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_treatmentsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$PenOccupanciesTable, List<PenOccupancy>> _penOccupanciesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.penOccupancies,
    aliasName: 'seasons__id__pen_occupancies__season',
  );

  $$PenOccupanciesTableProcessedTableManager get penOccupanciesRefs {
    final manager = $$PenOccupanciesTableTableManager(
      $_db,
      $_db.penOccupancies,
    ).filter((f) => f.season.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_penOccupanciesRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$SeasonsTableFilterComposer extends Composer<_$AppDatabase, $SeasonsTable> {
  $$SeasonsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<Instant, Instant, int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<Instant, Instant, int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<bool> get struck =>
      $composableBuilder(column: $table.struck, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<Instant?, Instant, int> get struckAt => $composableBuilder(
    column: $table.struckAt,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<LocalDate, LocalDate, String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<LocalDate?, LocalDate, String> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get ewesToRam =>
      $composableBuilder(column: $table.ewesToRam, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get scanningResult =>
      $composableBuilder(column: $table.scanningResult, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get overFreeCap =>
      $composableBuilder(column: $table.overFreeCap, builder: (column) => ColumnFilters(column));

  Expression<bool> lambingsRefs(Expression<bool> Function($$LambingsTableFilterComposer f) f) {
    final $$LambingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lambings,
      getReferencedColumn: (t) => t.season,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$LambingsTableFilterComposer(
            $db: $db,
            $table: $db.lambings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> eweSeasonsRefs(Expression<bool> Function($$EweSeasonsTableFilterComposer f) f) {
    final $$EweSeasonsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.eweSeasons,
      getReferencedColumn: (t) => t.season,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$EweSeasonsTableFilterComposer(
            $db: $db,
            $table: $db.eweSeasons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> eweObservationsRefs(
    Expression<bool> Function($$EweObservationsTableFilterComposer f) f,
  ) {
    final $$EweObservationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.eweObservations,
      getReferencedColumn: (t) => t.season,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$EweObservationsTableFilterComposer(
            $db: $db,
            $table: $db.eweObservations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> treatmentsRefs(Expression<bool> Function($$TreatmentsTableFilterComposer f) f) {
    final $$TreatmentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.treatments,
      getReferencedColumn: (t) => t.season,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$TreatmentsTableFilterComposer(
            $db: $db,
            $table: $db.treatments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> penOccupanciesRefs(
    Expression<bool> Function($$PenOccupanciesTableFilterComposer f) f,
  ) {
    final $$PenOccupanciesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.penOccupancies,
      getReferencedColumn: (t) => t.season,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$PenOccupanciesTableFilterComposer(
            $db: $db,
            $table: $db.penOccupancies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SeasonsTableOrderingComposer extends Composer<_$AppDatabase, $SeasonsTable> {
  $$SeasonsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get struck =>
      $composableBuilder(column: $table.struck, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get struckAt =>
      $composableBuilder(column: $table.struckAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get ewesToRam =>
      $composableBuilder(column: $table.ewesToRam, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get scanningResult => $composableBuilder(
    column: $table.scanningResult,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get overFreeCap =>
      $composableBuilder(column: $table.overFreeCap, builder: (column) => ColumnOrderings(column));
}

class $$SeasonsTableAnnotationComposer extends Composer<_$AppDatabase, $SeasonsTable> {
  $$SeasonsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Instant, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Instant, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get struck =>
      $composableBuilder(column: $table.struck, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Instant?, int> get struckAt =>
      $composableBuilder(column: $table.struckAt, builder: (column) => column);

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumnWithTypeConverter<LocalDate, String> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumnWithTypeConverter<LocalDate?, String> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<int> get ewesToRam =>
      $composableBuilder(column: $table.ewesToRam, builder: (column) => column);

  GeneratedColumn<int> get scanningResult =>
      $composableBuilder(column: $table.scanningResult, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get overFreeCap =>
      $composableBuilder(column: $table.overFreeCap, builder: (column) => column);

  Expression<T> lambingsRefs<T extends Object>(
    Expression<T> Function($$LambingsTableAnnotationComposer a) f,
  ) {
    final $$LambingsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lambings,
      getReferencedColumn: (t) => t.season,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$LambingsTableAnnotationComposer(
            $db: $db,
            $table: $db.lambings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> eweSeasonsRefs<T extends Object>(
    Expression<T> Function($$EweSeasonsTableAnnotationComposer a) f,
  ) {
    final $$EweSeasonsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.eweSeasons,
      getReferencedColumn: (t) => t.season,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$EweSeasonsTableAnnotationComposer(
            $db: $db,
            $table: $db.eweSeasons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> eweObservationsRefs<T extends Object>(
    Expression<T> Function($$EweObservationsTableAnnotationComposer a) f,
  ) {
    final $$EweObservationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.eweObservations,
      getReferencedColumn: (t) => t.season,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$EweObservationsTableAnnotationComposer(
            $db: $db,
            $table: $db.eweObservations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> treatmentsRefs<T extends Object>(
    Expression<T> Function($$TreatmentsTableAnnotationComposer a) f,
  ) {
    final $$TreatmentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.treatments,
      getReferencedColumn: (t) => t.season,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$TreatmentsTableAnnotationComposer(
            $db: $db,
            $table: $db.treatments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> penOccupanciesRefs<T extends Object>(
    Expression<T> Function($$PenOccupanciesTableAnnotationComposer a) f,
  ) {
    final $$PenOccupanciesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.penOccupancies,
      getReferencedColumn: (t) => t.season,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$PenOccupanciesTableAnnotationComposer(
            $db: $db,
            $table: $db.penOccupancies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SeasonsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SeasonsTable,
          Season,
          $$SeasonsTableFilterComposer,
          $$SeasonsTableOrderingComposer,
          $$SeasonsTableAnnotationComposer,
          $$SeasonsTableCreateCompanionBuilder,
          $$SeasonsTableUpdateCompanionBuilder,
          (Season, $$SeasonsTableReferences),
          Season,
          PrefetchHooks Function({
            bool lambingsRefs,
            bool eweSeasonsRefs,
            bool eweObservationsRefs,
            bool treatmentsRefs,
            bool penOccupanciesRefs,
          })
        > {
  $$SeasonsTableTableManager(_$AppDatabase db, $SeasonsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$SeasonsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$SeasonsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SeasonsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uid = const Value.absent(),
                Value<Instant> createdAt = const Value.absent(),
                Value<Instant> updatedAt = const Value.absent(),
                Value<bool> struck = const Value.absent(),
                Value<Instant?> struckAt = const Value.absent(),
                Value<int> year = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<LocalDate> startDate = const Value.absent(),
                Value<LocalDate?> endDate = const Value.absent(),
                Value<int?> ewesToRam = const Value.absent(),
                Value<int?> scanningResult = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> overFreeCap = const Value.absent(),
              }) => SeasonsCompanion(
                id: id,
                uid: uid,
                createdAt: createdAt,
                updatedAt: updatedAt,
                struck: struck,
                struckAt: struckAt,
                year: year,
                label: label,
                startDate: startDate,
                endDate: endDate,
                ewesToRam: ewesToRam,
                scanningResult: scanningResult,
                notes: notes,
                overFreeCap: overFreeCap,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String uid,
                required Instant createdAt,
                required Instant updatedAt,
                Value<bool> struck = const Value.absent(),
                Value<Instant?> struckAt = const Value.absent(),
                required int year,
                required String label,
                required LocalDate startDate,
                Value<LocalDate?> endDate = const Value.absent(),
                Value<int?> ewesToRam = const Value.absent(),
                Value<int?> scanningResult = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> overFreeCap = const Value.absent(),
              }) => SeasonsCompanion.insert(
                id: id,
                uid: uid,
                createdAt: createdAt,
                updatedAt: updatedAt,
                struck: struck,
                struckAt: struckAt,
                year: year,
                label: label,
                startDate: startDate,
                endDate: endDate,
                ewesToRam: ewesToRam,
                scanningResult: scanningResult,
                notes: notes,
                overFreeCap: overFreeCap,
              ),
          withReferenceMapper: (p0) =>
              p0.map((e) => (e.readTable(table), $$SeasonsTableReferences(db, table, e))).toList(),
          prefetchHooksCallback:
              ({
                lambingsRefs = false,
                eweSeasonsRefs = false,
                eweObservationsRefs = false,
                treatmentsRefs = false,
                penOccupanciesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (lambingsRefs) db.lambings,
                    if (eweSeasonsRefs) db.eweSeasons,
                    if (eweObservationsRefs) db.eweObservations,
                    if (treatmentsRefs) db.treatments,
                    if (penOccupanciesRefs) db.penOccupancies,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (lambingsRefs)
                        await $_getPrefetchedData<Season, $SeasonsTable, Lambing>(
                          currentTable: table,
                          referencedTable: $$SeasonsTableReferences._lambingsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SeasonsTableReferences(db, table, p0).lambingsRefs,
                          referencedItemsForCurrentItem: (item, referencedItems) =>
                              referencedItems.where((e) => e.season == item.id),
                          typedResults: items,
                        ),
                      if (eweSeasonsRefs)
                        await $_getPrefetchedData<Season, $SeasonsTable, EweSeason>(
                          currentTable: table,
                          referencedTable: $$SeasonsTableReferences._eweSeasonsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SeasonsTableReferences(db, table, p0).eweSeasonsRefs,
                          referencedItemsForCurrentItem: (item, referencedItems) =>
                              referencedItems.where((e) => e.season == item.id),
                          typedResults: items,
                        ),
                      if (eweObservationsRefs)
                        await $_getPrefetchedData<Season, $SeasonsTable, EweObservation>(
                          currentTable: table,
                          referencedTable: $$SeasonsTableReferences._eweObservationsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SeasonsTableReferences(db, table, p0).eweObservationsRefs,
                          referencedItemsForCurrentItem: (item, referencedItems) =>
                              referencedItems.where((e) => e.season == item.id),
                          typedResults: items,
                        ),
                      if (treatmentsRefs)
                        await $_getPrefetchedData<Season, $SeasonsTable, Treatment>(
                          currentTable: table,
                          referencedTable: $$SeasonsTableReferences._treatmentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SeasonsTableReferences(db, table, p0).treatmentsRefs,
                          referencedItemsForCurrentItem: (item, referencedItems) =>
                              referencedItems.where((e) => e.season == item.id),
                          typedResults: items,
                        ),
                      if (penOccupanciesRefs)
                        await $_getPrefetchedData<Season, $SeasonsTable, PenOccupancy>(
                          currentTable: table,
                          referencedTable: $$SeasonsTableReferences._penOccupanciesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SeasonsTableReferences(db, table, p0).penOccupanciesRefs,
                          referencedItemsForCurrentItem: (item, referencedItems) =>
                              referencedItems.where((e) => e.season == item.id),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$SeasonsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SeasonsTable,
      Season,
      $$SeasonsTableFilterComposer,
      $$SeasonsTableOrderingComposer,
      $$SeasonsTableAnnotationComposer,
      $$SeasonsTableCreateCompanionBuilder,
      $$SeasonsTableUpdateCompanionBuilder,
      (Season, $$SeasonsTableReferences),
      Season,
      PrefetchHooks Function({
        bool lambingsRefs,
        bool eweSeasonsRefs,
        bool eweObservationsRefs,
        bool treatmentsRefs,
        bool penOccupanciesRefs,
      })
    >;
typedef $$EwesTableCreateCompanionBuilder =
    EwesCompanion Function({
      Value<int> id,
      required String uid,
      required Instant createdAt,
      required Instant updatedAt,
      Value<bool> struck,
      Value<Instant?> struckAt,
      required String tag,
      required String tagDigits,
      Value<String?> eid,
      Value<String?> breed,
      Value<PartialDate?> dateOfBirth,
      Value<String?> source,
      Value<String> status,
      Value<String?> notes,
      Value<bool> overFreeCap,
    });
typedef $$EwesTableUpdateCompanionBuilder =
    EwesCompanion Function({
      Value<int> id,
      Value<String> uid,
      Value<Instant> createdAt,
      Value<Instant> updatedAt,
      Value<bool> struck,
      Value<Instant?> struckAt,
      Value<String> tag,
      Value<String> tagDigits,
      Value<String?> eid,
      Value<String?> breed,
      Value<PartialDate?> dateOfBirth,
      Value<String?> source,
      Value<String> status,
      Value<String?> notes,
      Value<bool> overFreeCap,
    });

final class $$EwesTableReferences extends BaseReferences<_$AppDatabase, $EwesTable, Ewe> {
  $$EwesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$LambingsTable, List<Lambing>> _lambingsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.lambings, aliasName: 'ewes__id__lambings__ewe');

  $$LambingsTableProcessedTableManager get lambingsRefs {
    final manager = $$LambingsTableTableManager(
      $_db,
      $_db.lambings,
    ).filter((f) => f.ewe.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_lambingsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$EweSeasonsTable, List<EweSeason>> _eweSeasonsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(db.eweSeasons, aliasName: 'ewes__id__ewe_seasons__ewe');

  $$EweSeasonsTableProcessedTableManager get eweSeasonsRefs {
    final manager = $$EweSeasonsTableTableManager(
      $_db,
      $_db.eweSeasons,
    ).filter((f) => f.ewe.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_eweSeasonsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$EweTouchesTable, List<EweTouch>> _eweTouchesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(db.eweTouches, aliasName: 'ewes__id__ewe_touches__ewe');

  $$EweTouchesTableProcessedTableManager get eweTouchesRefs {
    final manager = $$EweTouchesTableTableManager(
      $_db,
      $_db.eweTouches,
    ).filter((f) => f.ewe.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_eweTouchesRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$EweObservationsTable, List<EweObservation>> _eweObservationsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.eweObservations,
    aliasName: 'ewes__id__ewe_observations__ewe',
  );

  $$EweObservationsTableProcessedTableManager get eweObservationsRefs {
    final manager = $$EweObservationsTableTableManager(
      $_db,
      $_db.eweObservations,
    ).filter((f) => f.ewe.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_eweObservationsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$TreatmentsTable, List<Treatment>> _treatmentsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(db.treatments, aliasName: 'ewes__id__treatments__ewe');

  $$TreatmentsTableProcessedTableManager get treatmentsRefs {
    final manager = $$TreatmentsTableTableManager(
      $_db,
      $_db.treatments,
    ).filter((f) => f.ewe.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_treatmentsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$PenOccupanciesTable, List<PenOccupancy>> _penOccupanciesRefsTable(
    _$AppDatabase db,
  ) =>
      MultiTypedResultKey.fromTable(db.penOccupancies, aliasName: 'ewes__id__pen_occupancies__ewe');

  $$PenOccupanciesTableProcessedTableManager get penOccupanciesRefs {
    final manager = $$PenOccupanciesTableTableManager(
      $_db,
      $_db.penOccupancies,
    ).filter((f) => f.ewe.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_penOccupanciesRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$EwesTableFilterComposer extends Composer<_$AppDatabase, $EwesTable> {
  $$EwesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<Instant, Instant, int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<Instant, Instant, int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<bool> get struck =>
      $composableBuilder(column: $table.struck, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<Instant?, Instant, int> get struckAt => $composableBuilder(
    column: $table.struckAt,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get tag =>
      $composableBuilder(column: $table.tag, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tagDigits =>
      $composableBuilder(column: $table.tagDigits, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get eid =>
      $composableBuilder(column: $table.eid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get breed =>
      $composableBuilder(column: $table.breed, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<PartialDate?, PartialDate, String> get dateOfBirth =>
      $composableBuilder(
        column: $table.dateOfBirth,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get overFreeCap =>
      $composableBuilder(column: $table.overFreeCap, builder: (column) => ColumnFilters(column));

  Expression<bool> lambingsRefs(Expression<bool> Function($$LambingsTableFilterComposer f) f) {
    final $$LambingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lambings,
      getReferencedColumn: (t) => t.ewe,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$LambingsTableFilterComposer(
            $db: $db,
            $table: $db.lambings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> eweSeasonsRefs(Expression<bool> Function($$EweSeasonsTableFilterComposer f) f) {
    final $$EweSeasonsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.eweSeasons,
      getReferencedColumn: (t) => t.ewe,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$EweSeasonsTableFilterComposer(
            $db: $db,
            $table: $db.eweSeasons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> eweTouchesRefs(Expression<bool> Function($$EweTouchesTableFilterComposer f) f) {
    final $$EweTouchesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.eweTouches,
      getReferencedColumn: (t) => t.ewe,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$EweTouchesTableFilterComposer(
            $db: $db,
            $table: $db.eweTouches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> eweObservationsRefs(
    Expression<bool> Function($$EweObservationsTableFilterComposer f) f,
  ) {
    final $$EweObservationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.eweObservations,
      getReferencedColumn: (t) => t.ewe,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$EweObservationsTableFilterComposer(
            $db: $db,
            $table: $db.eweObservations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> treatmentsRefs(Expression<bool> Function($$TreatmentsTableFilterComposer f) f) {
    final $$TreatmentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.treatments,
      getReferencedColumn: (t) => t.ewe,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$TreatmentsTableFilterComposer(
            $db: $db,
            $table: $db.treatments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> penOccupanciesRefs(
    Expression<bool> Function($$PenOccupanciesTableFilterComposer f) f,
  ) {
    final $$PenOccupanciesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.penOccupancies,
      getReferencedColumn: (t) => t.ewe,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$PenOccupanciesTableFilterComposer(
            $db: $db,
            $table: $db.penOccupancies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$EwesTableOrderingComposer extends Composer<_$AppDatabase, $EwesTable> {
  $$EwesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get struck =>
      $composableBuilder(column: $table.struck, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get struckAt =>
      $composableBuilder(column: $table.struckAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tag =>
      $composableBuilder(column: $table.tag, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tagDigits =>
      $composableBuilder(column: $table.tagDigits, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get eid =>
      $composableBuilder(column: $table.eid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get breed =>
      $composableBuilder(column: $table.breed, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dateOfBirth =>
      $composableBuilder(column: $table.dateOfBirth, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get overFreeCap =>
      $composableBuilder(column: $table.overFreeCap, builder: (column) => ColumnOrderings(column));
}

class $$EwesTableAnnotationComposer extends Composer<_$AppDatabase, $EwesTable> {
  $$EwesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Instant, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Instant, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get struck =>
      $composableBuilder(column: $table.struck, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Instant?, int> get struckAt =>
      $composableBuilder(column: $table.struckAt, builder: (column) => column);

  GeneratedColumn<String> get tag =>
      $composableBuilder(column: $table.tag, builder: (column) => column);

  GeneratedColumn<String> get tagDigits =>
      $composableBuilder(column: $table.tagDigits, builder: (column) => column);

  GeneratedColumn<String> get eid =>
      $composableBuilder(column: $table.eid, builder: (column) => column);

  GeneratedColumn<String> get breed =>
      $composableBuilder(column: $table.breed, builder: (column) => column);

  GeneratedColumnWithTypeConverter<PartialDate?, String> get dateOfBirth =>
      $composableBuilder(column: $table.dateOfBirth, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get overFreeCap =>
      $composableBuilder(column: $table.overFreeCap, builder: (column) => column);

  Expression<T> lambingsRefs<T extends Object>(
    Expression<T> Function($$LambingsTableAnnotationComposer a) f,
  ) {
    final $$LambingsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lambings,
      getReferencedColumn: (t) => t.ewe,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$LambingsTableAnnotationComposer(
            $db: $db,
            $table: $db.lambings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> eweSeasonsRefs<T extends Object>(
    Expression<T> Function($$EweSeasonsTableAnnotationComposer a) f,
  ) {
    final $$EweSeasonsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.eweSeasons,
      getReferencedColumn: (t) => t.ewe,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$EweSeasonsTableAnnotationComposer(
            $db: $db,
            $table: $db.eweSeasons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> eweTouchesRefs<T extends Object>(
    Expression<T> Function($$EweTouchesTableAnnotationComposer a) f,
  ) {
    final $$EweTouchesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.eweTouches,
      getReferencedColumn: (t) => t.ewe,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$EweTouchesTableAnnotationComposer(
            $db: $db,
            $table: $db.eweTouches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> eweObservationsRefs<T extends Object>(
    Expression<T> Function($$EweObservationsTableAnnotationComposer a) f,
  ) {
    final $$EweObservationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.eweObservations,
      getReferencedColumn: (t) => t.ewe,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$EweObservationsTableAnnotationComposer(
            $db: $db,
            $table: $db.eweObservations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> treatmentsRefs<T extends Object>(
    Expression<T> Function($$TreatmentsTableAnnotationComposer a) f,
  ) {
    final $$TreatmentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.treatments,
      getReferencedColumn: (t) => t.ewe,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$TreatmentsTableAnnotationComposer(
            $db: $db,
            $table: $db.treatments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> penOccupanciesRefs<T extends Object>(
    Expression<T> Function($$PenOccupanciesTableAnnotationComposer a) f,
  ) {
    final $$PenOccupanciesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.penOccupancies,
      getReferencedColumn: (t) => t.ewe,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$PenOccupanciesTableAnnotationComposer(
            $db: $db,
            $table: $db.penOccupancies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$EwesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EwesTable,
          Ewe,
          $$EwesTableFilterComposer,
          $$EwesTableOrderingComposer,
          $$EwesTableAnnotationComposer,
          $$EwesTableCreateCompanionBuilder,
          $$EwesTableUpdateCompanionBuilder,
          (Ewe, $$EwesTableReferences),
          Ewe,
          PrefetchHooks Function({
            bool lambingsRefs,
            bool eweSeasonsRefs,
            bool eweTouchesRefs,
            bool eweObservationsRefs,
            bool treatmentsRefs,
            bool penOccupanciesRefs,
          })
        > {
  $$EwesTableTableManager(_$AppDatabase db, $EwesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$EwesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$EwesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$EwesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uid = const Value.absent(),
                Value<Instant> createdAt = const Value.absent(),
                Value<Instant> updatedAt = const Value.absent(),
                Value<bool> struck = const Value.absent(),
                Value<Instant?> struckAt = const Value.absent(),
                Value<String> tag = const Value.absent(),
                Value<String> tagDigits = const Value.absent(),
                Value<String?> eid = const Value.absent(),
                Value<String?> breed = const Value.absent(),
                Value<PartialDate?> dateOfBirth = const Value.absent(),
                Value<String?> source = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> overFreeCap = const Value.absent(),
              }) => EwesCompanion(
                id: id,
                uid: uid,
                createdAt: createdAt,
                updatedAt: updatedAt,
                struck: struck,
                struckAt: struckAt,
                tag: tag,
                tagDigits: tagDigits,
                eid: eid,
                breed: breed,
                dateOfBirth: dateOfBirth,
                source: source,
                status: status,
                notes: notes,
                overFreeCap: overFreeCap,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String uid,
                required Instant createdAt,
                required Instant updatedAt,
                Value<bool> struck = const Value.absent(),
                Value<Instant?> struckAt = const Value.absent(),
                required String tag,
                required String tagDigits,
                Value<String?> eid = const Value.absent(),
                Value<String?> breed = const Value.absent(),
                Value<PartialDate?> dateOfBirth = const Value.absent(),
                Value<String?> source = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> overFreeCap = const Value.absent(),
              }) => EwesCompanion.insert(
                id: id,
                uid: uid,
                createdAt: createdAt,
                updatedAt: updatedAt,
                struck: struck,
                struckAt: struckAt,
                tag: tag,
                tagDigits: tagDigits,
                eid: eid,
                breed: breed,
                dateOfBirth: dateOfBirth,
                source: source,
                status: status,
                notes: notes,
                overFreeCap: overFreeCap,
              ),
          withReferenceMapper: (p0) =>
              p0.map((e) => (e.readTable(table), $$EwesTableReferences(db, table, e))).toList(),
          prefetchHooksCallback:
              ({
                lambingsRefs = false,
                eweSeasonsRefs = false,
                eweTouchesRefs = false,
                eweObservationsRefs = false,
                treatmentsRefs = false,
                penOccupanciesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (lambingsRefs) db.lambings,
                    if (eweSeasonsRefs) db.eweSeasons,
                    if (eweTouchesRefs) db.eweTouches,
                    if (eweObservationsRefs) db.eweObservations,
                    if (treatmentsRefs) db.treatments,
                    if (penOccupanciesRefs) db.penOccupancies,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (lambingsRefs)
                        await $_getPrefetchedData<Ewe, $EwesTable, Lambing>(
                          currentTable: table,
                          referencedTable: $$EwesTableReferences._lambingsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EwesTableReferences(db, table, p0).lambingsRefs,
                          referencedItemsForCurrentItem: (item, referencedItems) =>
                              referencedItems.where((e) => e.ewe == item.id),
                          typedResults: items,
                        ),
                      if (eweSeasonsRefs)
                        await $_getPrefetchedData<Ewe, $EwesTable, EweSeason>(
                          currentTable: table,
                          referencedTable: $$EwesTableReferences._eweSeasonsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EwesTableReferences(db, table, p0).eweSeasonsRefs,
                          referencedItemsForCurrentItem: (item, referencedItems) =>
                              referencedItems.where((e) => e.ewe == item.id),
                          typedResults: items,
                        ),
                      if (eweTouchesRefs)
                        await $_getPrefetchedData<Ewe, $EwesTable, EweTouch>(
                          currentTable: table,
                          referencedTable: $$EwesTableReferences._eweTouchesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EwesTableReferences(db, table, p0).eweTouchesRefs,
                          referencedItemsForCurrentItem: (item, referencedItems) =>
                              referencedItems.where((e) => e.ewe == item.id),
                          typedResults: items,
                        ),
                      if (eweObservationsRefs)
                        await $_getPrefetchedData<Ewe, $EwesTable, EweObservation>(
                          currentTable: table,
                          referencedTable: $$EwesTableReferences._eweObservationsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EwesTableReferences(db, table, p0).eweObservationsRefs,
                          referencedItemsForCurrentItem: (item, referencedItems) =>
                              referencedItems.where((e) => e.ewe == item.id),
                          typedResults: items,
                        ),
                      if (treatmentsRefs)
                        await $_getPrefetchedData<Ewe, $EwesTable, Treatment>(
                          currentTable: table,
                          referencedTable: $$EwesTableReferences._treatmentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EwesTableReferences(db, table, p0).treatmentsRefs,
                          referencedItemsForCurrentItem: (item, referencedItems) =>
                              referencedItems.where((e) => e.ewe == item.id),
                          typedResults: items,
                        ),
                      if (penOccupanciesRefs)
                        await $_getPrefetchedData<Ewe, $EwesTable, PenOccupancy>(
                          currentTable: table,
                          referencedTable: $$EwesTableReferences._penOccupanciesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EwesTableReferences(db, table, p0).penOccupanciesRefs,
                          referencedItemsForCurrentItem: (item, referencedItems) =>
                              referencedItems.where((e) => e.ewe == item.id),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$EwesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EwesTable,
      Ewe,
      $$EwesTableFilterComposer,
      $$EwesTableOrderingComposer,
      $$EwesTableAnnotationComposer,
      $$EwesTableCreateCompanionBuilder,
      $$EwesTableUpdateCompanionBuilder,
      (Ewe, $$EwesTableReferences),
      Ewe,
      PrefetchHooks Function({
        bool lambingsRefs,
        bool eweSeasonsRefs,
        bool eweTouchesRefs,
        bool eweObservationsRefs,
        bool treatmentsRefs,
        bool penOccupanciesRefs,
      })
    >;
typedef $$LambingsTableCreateCompanionBuilder =
    LambingsCompanion Function({
      Value<int> id,
      required String uid,
      required Instant createdAt,
      required Instant updatedAt,
      Value<bool> struck,
      Value<Instant?> struckAt,
      required int season,
      required int ewe,
      required Instant occurredAt,
      required Instant capturedAt,
      Value<Instant?> originalEffective,
      Value<String> timeSource,
      required LocalDate localDate,
      Value<int?> declaredBirthType,
      Value<int?> ease,
      Value<String?> assistedBy,
      Value<String?> presentation,
      Value<String?> presentationNote,
      Value<String?> note,
    });
typedef $$LambingsTableUpdateCompanionBuilder =
    LambingsCompanion Function({
      Value<int> id,
      Value<String> uid,
      Value<Instant> createdAt,
      Value<Instant> updatedAt,
      Value<bool> struck,
      Value<Instant?> struckAt,
      Value<int> season,
      Value<int> ewe,
      Value<Instant> occurredAt,
      Value<Instant> capturedAt,
      Value<Instant?> originalEffective,
      Value<String> timeSource,
      Value<LocalDate> localDate,
      Value<int?> declaredBirthType,
      Value<int?> ease,
      Value<String?> assistedBy,
      Value<String?> presentation,
      Value<String?> presentationNote,
      Value<String?> note,
    });

final class $$LambingsTableReferences
    extends BaseReferences<_$AppDatabase, $LambingsTable, Lambing> {
  $$LambingsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SeasonsTable _seasonTable(_$AppDatabase db) =>
      db.seasons.createAlias('lambings__season__seasons__id');

  $$SeasonsTableProcessedTableManager get season {
    final $_column = $_itemColumn<int>('season')!;

    final manager = $$SeasonsTableTableManager(
      $_db,
      $_db.seasons,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_seasonTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static $EwesTable _eweTable(_$AppDatabase db) => db.ewes.createAlias('lambings__ewe__ewes__id');

  $$EwesTableProcessedTableManager get ewe {
    final $_column = $_itemColumn<int>('ewe')!;

    final manager = $$EwesTableTableManager(
      $_db,
      $_db.ewes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_eweTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$LambsTable, List<Lamb>> _lambsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.lambs, aliasName: 'lambings__id__lambs__lambing');

  $$LambsTableProcessedTableManager get lambsRefs {
    final manager = $$LambsTableTableManager(
      $_db,
      $_db.lambs,
    ).filter((f) => f.lambing.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_lambsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$EweObservationsTable, List<EweObservation>> _eweObservationsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.eweObservations,
    aliasName: 'lambings__id__ewe_observations__lambing',
  );

  $$EweObservationsTableProcessedTableManager get eweObservationsRefs {
    final manager = $$EweObservationsTableTableManager(
      $_db,
      $_db.eweObservations,
    ).filter((f) => f.lambing.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_eweObservationsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$LambingsTableFilterComposer extends Composer<_$AppDatabase, $LambingsTable> {
  $$LambingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<Instant, Instant, int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<Instant, Instant, int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<bool> get struck =>
      $composableBuilder(column: $table.struck, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<Instant?, Instant, int> get struckAt => $composableBuilder(
    column: $table.struckAt,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<Instant, Instant, int> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<Instant, Instant, int> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<Instant?, Instant, int> get originalEffective =>
      $composableBuilder(
        column: $table.originalEffective,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get timeSource =>
      $composableBuilder(column: $table.timeSource, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<LocalDate, LocalDate, String> get localDate => $composableBuilder(
    column: $table.localDate,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get declaredBirthType => $composableBuilder(
    column: $table.declaredBirthType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ease =>
      $composableBuilder(column: $table.ease, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get assistedBy =>
      $composableBuilder(column: $table.assistedBy, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get presentation =>
      $composableBuilder(column: $table.presentation, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get presentationNote => $composableBuilder(
    column: $table.presentationNote,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => ColumnFilters(column));

  $$SeasonsTableFilterComposer get season {
    final $$SeasonsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.season,
      referencedTable: $db.seasons,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$SeasonsTableFilterComposer(
            $db: $db,
            $table: $db.seasons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EwesTableFilterComposer get ewe {
    final $$EwesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ewe,
      referencedTable: $db.ewes,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$EwesTableFilterComposer(
            $db: $db,
            $table: $db.ewes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> lambsRefs(Expression<bool> Function($$LambsTableFilterComposer f) f) {
    final $$LambsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lambs,
      getReferencedColumn: (t) => t.lambing,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$LambsTableFilterComposer(
            $db: $db,
            $table: $db.lambs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> eweObservationsRefs(
    Expression<bool> Function($$EweObservationsTableFilterComposer f) f,
  ) {
    final $$EweObservationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.eweObservations,
      getReferencedColumn: (t) => t.lambing,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$EweObservationsTableFilterComposer(
            $db: $db,
            $table: $db.eweObservations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LambingsTableOrderingComposer extends Composer<_$AppDatabase, $LambingsTable> {
  $$LambingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get struck =>
      $composableBuilder(column: $table.struck, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get struckAt =>
      $composableBuilder(column: $table.struckAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get occurredAt =>
      $composableBuilder(column: $table.occurredAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get capturedAt =>
      $composableBuilder(column: $table.capturedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get originalEffective => $composableBuilder(
    column: $table.originalEffective,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timeSource =>
      $composableBuilder(column: $table.timeSource, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get localDate =>
      $composableBuilder(column: $table.localDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get declaredBirthType => $composableBuilder(
    column: $table.declaredBirthType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ease =>
      $composableBuilder(column: $table.ease, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get assistedBy =>
      $composableBuilder(column: $table.assistedBy, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get presentation =>
      $composableBuilder(column: $table.presentation, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get presentationNote => $composableBuilder(
    column: $table.presentationNote,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => ColumnOrderings(column));

  $$SeasonsTableOrderingComposer get season {
    final $$SeasonsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.season,
      referencedTable: $db.seasons,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$SeasonsTableOrderingComposer(
            $db: $db,
            $table: $db.seasons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EwesTableOrderingComposer get ewe {
    final $$EwesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ewe,
      referencedTable: $db.ewes,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$EwesTableOrderingComposer(
            $db: $db,
            $table: $db.ewes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LambingsTableAnnotationComposer extends Composer<_$AppDatabase, $LambingsTable> {
  $$LambingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Instant, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Instant, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get struck =>
      $composableBuilder(column: $table.struck, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Instant?, int> get struckAt =>
      $composableBuilder(column: $table.struckAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Instant, int> get occurredAt =>
      $composableBuilder(column: $table.occurredAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Instant, int> get capturedAt =>
      $composableBuilder(column: $table.capturedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Instant?, int> get originalEffective =>
      $composableBuilder(column: $table.originalEffective, builder: (column) => column);

  GeneratedColumn<String> get timeSource =>
      $composableBuilder(column: $table.timeSource, builder: (column) => column);

  GeneratedColumnWithTypeConverter<LocalDate, String> get localDate =>
      $composableBuilder(column: $table.localDate, builder: (column) => column);

  GeneratedColumn<int> get declaredBirthType =>
      $composableBuilder(column: $table.declaredBirthType, builder: (column) => column);

  GeneratedColumn<int> get ease =>
      $composableBuilder(column: $table.ease, builder: (column) => column);

  GeneratedColumn<String> get assistedBy =>
      $composableBuilder(column: $table.assistedBy, builder: (column) => column);

  GeneratedColumn<String> get presentation =>
      $composableBuilder(column: $table.presentation, builder: (column) => column);

  GeneratedColumn<String> get presentationNote =>
      $composableBuilder(column: $table.presentationNote, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  $$SeasonsTableAnnotationComposer get season {
    final $$SeasonsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.season,
      referencedTable: $db.seasons,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$SeasonsTableAnnotationComposer(
            $db: $db,
            $table: $db.seasons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EwesTableAnnotationComposer get ewe {
    final $$EwesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ewe,
      referencedTable: $db.ewes,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$EwesTableAnnotationComposer(
            $db: $db,
            $table: $db.ewes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> lambsRefs<T extends Object>(
    Expression<T> Function($$LambsTableAnnotationComposer a) f,
  ) {
    final $$LambsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lambs,
      getReferencedColumn: (t) => t.lambing,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$LambsTableAnnotationComposer(
            $db: $db,
            $table: $db.lambs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> eweObservationsRefs<T extends Object>(
    Expression<T> Function($$EweObservationsTableAnnotationComposer a) f,
  ) {
    final $$EweObservationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.eweObservations,
      getReferencedColumn: (t) => t.lambing,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$EweObservationsTableAnnotationComposer(
            $db: $db,
            $table: $db.eweObservations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LambingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LambingsTable,
          Lambing,
          $$LambingsTableFilterComposer,
          $$LambingsTableOrderingComposer,
          $$LambingsTableAnnotationComposer,
          $$LambingsTableCreateCompanionBuilder,
          $$LambingsTableUpdateCompanionBuilder,
          (Lambing, $$LambingsTableReferences),
          Lambing,
          PrefetchHooks Function({bool season, bool ewe, bool lambsRefs, bool eweObservationsRefs})
        > {
  $$LambingsTableTableManager(_$AppDatabase db, $LambingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$LambingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$LambingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LambingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uid = const Value.absent(),
                Value<Instant> createdAt = const Value.absent(),
                Value<Instant> updatedAt = const Value.absent(),
                Value<bool> struck = const Value.absent(),
                Value<Instant?> struckAt = const Value.absent(),
                Value<int> season = const Value.absent(),
                Value<int> ewe = const Value.absent(),
                Value<Instant> occurredAt = const Value.absent(),
                Value<Instant> capturedAt = const Value.absent(),
                Value<Instant?> originalEffective = const Value.absent(),
                Value<String> timeSource = const Value.absent(),
                Value<LocalDate> localDate = const Value.absent(),
                Value<int?> declaredBirthType = const Value.absent(),
                Value<int?> ease = const Value.absent(),
                Value<String?> assistedBy = const Value.absent(),
                Value<String?> presentation = const Value.absent(),
                Value<String?> presentationNote = const Value.absent(),
                Value<String?> note = const Value.absent(),
              }) => LambingsCompanion(
                id: id,
                uid: uid,
                createdAt: createdAt,
                updatedAt: updatedAt,
                struck: struck,
                struckAt: struckAt,
                season: season,
                ewe: ewe,
                occurredAt: occurredAt,
                capturedAt: capturedAt,
                originalEffective: originalEffective,
                timeSource: timeSource,
                localDate: localDate,
                declaredBirthType: declaredBirthType,
                ease: ease,
                assistedBy: assistedBy,
                presentation: presentation,
                presentationNote: presentationNote,
                note: note,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String uid,
                required Instant createdAt,
                required Instant updatedAt,
                Value<bool> struck = const Value.absent(),
                Value<Instant?> struckAt = const Value.absent(),
                required int season,
                required int ewe,
                required Instant occurredAt,
                required Instant capturedAt,
                Value<Instant?> originalEffective = const Value.absent(),
                Value<String> timeSource = const Value.absent(),
                required LocalDate localDate,
                Value<int?> declaredBirthType = const Value.absent(),
                Value<int?> ease = const Value.absent(),
                Value<String?> assistedBy = const Value.absent(),
                Value<String?> presentation = const Value.absent(),
                Value<String?> presentationNote = const Value.absent(),
                Value<String?> note = const Value.absent(),
              }) => LambingsCompanion.insert(
                id: id,
                uid: uid,
                createdAt: createdAt,
                updatedAt: updatedAt,
                struck: struck,
                struckAt: struckAt,
                season: season,
                ewe: ewe,
                occurredAt: occurredAt,
                capturedAt: capturedAt,
                originalEffective: originalEffective,
                timeSource: timeSource,
                localDate: localDate,
                declaredBirthType: declaredBirthType,
                ease: ease,
                assistedBy: assistedBy,
                presentation: presentation,
                presentationNote: presentationNote,
                note: note,
              ),
          withReferenceMapper: (p0) =>
              p0.map((e) => (e.readTable(table), $$LambingsTableReferences(db, table, e))).toList(),
          prefetchHooksCallback:
              ({season = false, ewe = false, lambsRefs = false, eweObservationsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (lambsRefs) db.lambs,
                    if (eweObservationsRefs) db.eweObservations,
                  ],
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
                        if (season) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.season,
                                    referencedTable: $$LambingsTableReferences._seasonTable(db),
                                    referencedColumn: $$LambingsTableReferences._seasonTable(db).id,
                                  )
                                  as T;
                        }
                        if (ewe) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.ewe,
                                    referencedTable: $$LambingsTableReferences._eweTable(db),
                                    referencedColumn: $$LambingsTableReferences._eweTable(db).id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (lambsRefs)
                        await $_getPrefetchedData<Lambing, $LambingsTable, Lamb>(
                          currentTable: table,
                          referencedTable: $$LambingsTableReferences._lambsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LambingsTableReferences(db, table, p0).lambsRefs,
                          referencedItemsForCurrentItem: (item, referencedItems) =>
                              referencedItems.where((e) => e.lambing == item.id),
                          typedResults: items,
                        ),
                      if (eweObservationsRefs)
                        await $_getPrefetchedData<Lambing, $LambingsTable, EweObservation>(
                          currentTable: table,
                          referencedTable: $$LambingsTableReferences._eweObservationsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LambingsTableReferences(db, table, p0).eweObservationsRefs,
                          referencedItemsForCurrentItem: (item, referencedItems) =>
                              referencedItems.where((e) => e.lambing == item.id),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$LambingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LambingsTable,
      Lambing,
      $$LambingsTableFilterComposer,
      $$LambingsTableOrderingComposer,
      $$LambingsTableAnnotationComposer,
      $$LambingsTableCreateCompanionBuilder,
      $$LambingsTableUpdateCompanionBuilder,
      (Lambing, $$LambingsTableReferences),
      Lambing,
      PrefetchHooks Function({bool season, bool ewe, bool lambsRefs, bool eweObservationsRefs})
    >;
typedef $$LambsTableCreateCompanionBuilder =
    LambsCompanion Function({
      Value<int> id,
      required String uid,
      required Instant createdAt,
      required Instant updatedAt,
      Value<bool> struck,
      Value<Instant?> struckAt,
      required int lambing,
      required int birthDam,
      Value<String?> tag,
      Value<String?> tagDigits,
      Value<String?> sex,
      Value<int?> birthWeightG,
      Value<String> status,
      Value<LocalDate?> deathDate,
      Value<String?> deathCause,
      Value<bool> petLamb,
      Value<int> bottleFeeds,
      Value<String?> notes,
      Value<int?> becameEwe,
    });
typedef $$LambsTableUpdateCompanionBuilder =
    LambsCompanion Function({
      Value<int> id,
      Value<String> uid,
      Value<Instant> createdAt,
      Value<Instant> updatedAt,
      Value<bool> struck,
      Value<Instant?> struckAt,
      Value<int> lambing,
      Value<int> birthDam,
      Value<String?> tag,
      Value<String?> tagDigits,
      Value<String?> sex,
      Value<int?> birthWeightG,
      Value<String> status,
      Value<LocalDate?> deathDate,
      Value<String?> deathCause,
      Value<bool> petLamb,
      Value<int> bottleFeeds,
      Value<String?> notes,
      Value<int?> becameEwe,
    });

final class $$LambsTableReferences extends BaseReferences<_$AppDatabase, $LambsTable, Lamb> {
  $$LambsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LambingsTable _lambingTable(_$AppDatabase db) =>
      db.lambings.createAlias('lambs__lambing__lambings__id');

  $$LambingsTableProcessedTableManager get lambing {
    final $_column = $_itemColumn<int>('lambing')!;

    final manager = $$LambingsTableTableManager(
      $_db,
      $_db.lambings,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_lambingTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static $EwesTable _birthDamTable(_$AppDatabase db) =>
      db.ewes.createAlias('lambs__birth_dam__ewes__id');

  $$EwesTableProcessedTableManager get birthDam {
    final $_column = $_itemColumn<int>('birth_dam')!;

    final manager = $$EwesTableTableManager(
      $_db,
      $_db.ewes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_birthDamTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static $EwesTable _becameEweTable(_$AppDatabase db) =>
      db.ewes.createAlias('lambs__became_ewe__ewes__id');

  $$EwesTableProcessedTableManager? get becameEwe {
    final $_column = $_itemColumn<int>('became_ewe');
    if ($_column == null) return null;
    final manager = $$EwesTableTableManager(
      $_db,
      $_db.ewes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_becameEweTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$TreatmentsTable, List<Treatment>> _treatmentsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(db.treatments, aliasName: 'lambs__id__treatments__lamb');

  $$TreatmentsTableProcessedTableManager get treatmentsRefs {
    final manager = $$TreatmentsTableTableManager(
      $_db,
      $_db.treatments,
    ).filter((f) => f.lamb.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_treatmentsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$PenOccupancyLambsTable, List<PenOccupancyLamb>>
  _penOccupancyLambsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.penOccupancyLambs,
    aliasName: 'lambs__id__pen_occupancy_lambs__lamb',
  );

  $$PenOccupancyLambsTableProcessedTableManager get penOccupancyLambsRefs {
    final manager = $$PenOccupancyLambsTableTableManager(
      $_db,
      $_db.penOccupancyLambs,
    ).filter((f) => f.lamb.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_penOccupancyLambsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$LambsTableFilterComposer extends Composer<_$AppDatabase, $LambsTable> {
  $$LambsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<Instant, Instant, int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<Instant, Instant, int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<bool> get struck =>
      $composableBuilder(column: $table.struck, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<Instant?, Instant, int> get struckAt => $composableBuilder(
    column: $table.struckAt,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get tag =>
      $composableBuilder(column: $table.tag, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tagDigits =>
      $composableBuilder(column: $table.tagDigits, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sex =>
      $composableBuilder(column: $table.sex, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get birthWeightG =>
      $composableBuilder(column: $table.birthWeightG, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<LocalDate?, LocalDate, String> get deathDate => $composableBuilder(
    column: $table.deathDate,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get deathCause =>
      $composableBuilder(column: $table.deathCause, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get petLamb =>
      $composableBuilder(column: $table.petLamb, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get bottleFeeds =>
      $composableBuilder(column: $table.bottleFeeds, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => ColumnFilters(column));

  $$LambingsTableFilterComposer get lambing {
    final $$LambingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lambing,
      referencedTable: $db.lambings,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$LambingsTableFilterComposer(
            $db: $db,
            $table: $db.lambings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EwesTableFilterComposer get birthDam {
    final $$EwesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.birthDam,
      referencedTable: $db.ewes,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$EwesTableFilterComposer(
            $db: $db,
            $table: $db.ewes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EwesTableFilterComposer get becameEwe {
    final $$EwesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.becameEwe,
      referencedTable: $db.ewes,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$EwesTableFilterComposer(
            $db: $db,
            $table: $db.ewes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> treatmentsRefs(Expression<bool> Function($$TreatmentsTableFilterComposer f) f) {
    final $$TreatmentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.treatments,
      getReferencedColumn: (t) => t.lamb,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$TreatmentsTableFilterComposer(
            $db: $db,
            $table: $db.treatments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> penOccupancyLambsRefs(
    Expression<bool> Function($$PenOccupancyLambsTableFilterComposer f) f,
  ) {
    final $$PenOccupancyLambsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.penOccupancyLambs,
      getReferencedColumn: (t) => t.lamb,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$PenOccupancyLambsTableFilterComposer(
            $db: $db,
            $table: $db.penOccupancyLambs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LambsTableOrderingComposer extends Composer<_$AppDatabase, $LambsTable> {
  $$LambsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get struck =>
      $composableBuilder(column: $table.struck, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get struckAt =>
      $composableBuilder(column: $table.struckAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tag =>
      $composableBuilder(column: $table.tag, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tagDigits =>
      $composableBuilder(column: $table.tagDigits, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sex =>
      $composableBuilder(column: $table.sex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get birthWeightG =>
      $composableBuilder(column: $table.birthWeightG, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deathDate =>
      $composableBuilder(column: $table.deathDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deathCause =>
      $composableBuilder(column: $table.deathCause, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get petLamb =>
      $composableBuilder(column: $table.petLamb, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get bottleFeeds =>
      $composableBuilder(column: $table.bottleFeeds, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => ColumnOrderings(column));

  $$LambingsTableOrderingComposer get lambing {
    final $$LambingsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lambing,
      referencedTable: $db.lambings,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$LambingsTableOrderingComposer(
            $db: $db,
            $table: $db.lambings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EwesTableOrderingComposer get birthDam {
    final $$EwesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.birthDam,
      referencedTable: $db.ewes,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$EwesTableOrderingComposer(
            $db: $db,
            $table: $db.ewes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EwesTableOrderingComposer get becameEwe {
    final $$EwesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.becameEwe,
      referencedTable: $db.ewes,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$EwesTableOrderingComposer(
            $db: $db,
            $table: $db.ewes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LambsTableAnnotationComposer extends Composer<_$AppDatabase, $LambsTable> {
  $$LambsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Instant, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Instant, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get struck =>
      $composableBuilder(column: $table.struck, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Instant?, int> get struckAt =>
      $composableBuilder(column: $table.struckAt, builder: (column) => column);

  GeneratedColumn<String> get tag =>
      $composableBuilder(column: $table.tag, builder: (column) => column);

  GeneratedColumn<String> get tagDigits =>
      $composableBuilder(column: $table.tagDigits, builder: (column) => column);

  GeneratedColumn<String> get sex =>
      $composableBuilder(column: $table.sex, builder: (column) => column);

  GeneratedColumn<int> get birthWeightG =>
      $composableBuilder(column: $table.birthWeightG, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumnWithTypeConverter<LocalDate?, String> get deathDate =>
      $composableBuilder(column: $table.deathDate, builder: (column) => column);

  GeneratedColumn<String> get deathCause =>
      $composableBuilder(column: $table.deathCause, builder: (column) => column);

  GeneratedColumn<bool> get petLamb =>
      $composableBuilder(column: $table.petLamb, builder: (column) => column);

  GeneratedColumn<int> get bottleFeeds =>
      $composableBuilder(column: $table.bottleFeeds, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  $$LambingsTableAnnotationComposer get lambing {
    final $$LambingsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lambing,
      referencedTable: $db.lambings,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$LambingsTableAnnotationComposer(
            $db: $db,
            $table: $db.lambings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EwesTableAnnotationComposer get birthDam {
    final $$EwesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.birthDam,
      referencedTable: $db.ewes,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$EwesTableAnnotationComposer(
            $db: $db,
            $table: $db.ewes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EwesTableAnnotationComposer get becameEwe {
    final $$EwesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.becameEwe,
      referencedTable: $db.ewes,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$EwesTableAnnotationComposer(
            $db: $db,
            $table: $db.ewes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> treatmentsRefs<T extends Object>(
    Expression<T> Function($$TreatmentsTableAnnotationComposer a) f,
  ) {
    final $$TreatmentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.treatments,
      getReferencedColumn: (t) => t.lamb,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$TreatmentsTableAnnotationComposer(
            $db: $db,
            $table: $db.treatments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> penOccupancyLambsRefs<T extends Object>(
    Expression<T> Function($$PenOccupancyLambsTableAnnotationComposer a) f,
  ) {
    final $$PenOccupancyLambsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.penOccupancyLambs,
      getReferencedColumn: (t) => t.lamb,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$PenOccupancyLambsTableAnnotationComposer(
            $db: $db,
            $table: $db.penOccupancyLambs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LambsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LambsTable,
          Lamb,
          $$LambsTableFilterComposer,
          $$LambsTableOrderingComposer,
          $$LambsTableAnnotationComposer,
          $$LambsTableCreateCompanionBuilder,
          $$LambsTableUpdateCompanionBuilder,
          (Lamb, $$LambsTableReferences),
          Lamb,
          PrefetchHooks Function({
            bool lambing,
            bool birthDam,
            bool becameEwe,
            bool treatmentsRefs,
            bool penOccupancyLambsRefs,
          })
        > {
  $$LambsTableTableManager(_$AppDatabase db, $LambsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$LambsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$LambsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$LambsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uid = const Value.absent(),
                Value<Instant> createdAt = const Value.absent(),
                Value<Instant> updatedAt = const Value.absent(),
                Value<bool> struck = const Value.absent(),
                Value<Instant?> struckAt = const Value.absent(),
                Value<int> lambing = const Value.absent(),
                Value<int> birthDam = const Value.absent(),
                Value<String?> tag = const Value.absent(),
                Value<String?> tagDigits = const Value.absent(),
                Value<String?> sex = const Value.absent(),
                Value<int?> birthWeightG = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<LocalDate?> deathDate = const Value.absent(),
                Value<String?> deathCause = const Value.absent(),
                Value<bool> petLamb = const Value.absent(),
                Value<int> bottleFeeds = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int?> becameEwe = const Value.absent(),
              }) => LambsCompanion(
                id: id,
                uid: uid,
                createdAt: createdAt,
                updatedAt: updatedAt,
                struck: struck,
                struckAt: struckAt,
                lambing: lambing,
                birthDam: birthDam,
                tag: tag,
                tagDigits: tagDigits,
                sex: sex,
                birthWeightG: birthWeightG,
                status: status,
                deathDate: deathDate,
                deathCause: deathCause,
                petLamb: petLamb,
                bottleFeeds: bottleFeeds,
                notes: notes,
                becameEwe: becameEwe,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String uid,
                required Instant createdAt,
                required Instant updatedAt,
                Value<bool> struck = const Value.absent(),
                Value<Instant?> struckAt = const Value.absent(),
                required int lambing,
                required int birthDam,
                Value<String?> tag = const Value.absent(),
                Value<String?> tagDigits = const Value.absent(),
                Value<String?> sex = const Value.absent(),
                Value<int?> birthWeightG = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<LocalDate?> deathDate = const Value.absent(),
                Value<String?> deathCause = const Value.absent(),
                Value<bool> petLamb = const Value.absent(),
                Value<int> bottleFeeds = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int?> becameEwe = const Value.absent(),
              }) => LambsCompanion.insert(
                id: id,
                uid: uid,
                createdAt: createdAt,
                updatedAt: updatedAt,
                struck: struck,
                struckAt: struckAt,
                lambing: lambing,
                birthDam: birthDam,
                tag: tag,
                tagDigits: tagDigits,
                sex: sex,
                birthWeightG: birthWeightG,
                status: status,
                deathDate: deathDate,
                deathCause: deathCause,
                petLamb: petLamb,
                bottleFeeds: bottleFeeds,
                notes: notes,
                becameEwe: becameEwe,
              ),
          withReferenceMapper: (p0) =>
              p0.map((e) => (e.readTable(table), $$LambsTableReferences(db, table, e))).toList(),
          prefetchHooksCallback:
              ({
                lambing = false,
                birthDam = false,
                becameEwe = false,
                treatmentsRefs = false,
                penOccupancyLambsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (treatmentsRefs) db.treatments,
                    if (penOccupancyLambsRefs) db.penOccupancyLambs,
                  ],
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
                        if (lambing) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.lambing,
                                    referencedTable: $$LambsTableReferences._lambingTable(db),
                                    referencedColumn: $$LambsTableReferences._lambingTable(db).id,
                                  )
                                  as T;
                        }
                        if (birthDam) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.birthDam,
                                    referencedTable: $$LambsTableReferences._birthDamTable(db),
                                    referencedColumn: $$LambsTableReferences._birthDamTable(db).id,
                                  )
                                  as T;
                        }
                        if (becameEwe) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.becameEwe,
                                    referencedTable: $$LambsTableReferences._becameEweTable(db),
                                    referencedColumn: $$LambsTableReferences._becameEweTable(db).id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (treatmentsRefs)
                        await $_getPrefetchedData<Lamb, $LambsTable, Treatment>(
                          currentTable: table,
                          referencedTable: $$LambsTableReferences._treatmentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LambsTableReferences(db, table, p0).treatmentsRefs,
                          referencedItemsForCurrentItem: (item, referencedItems) =>
                              referencedItems.where((e) => e.lamb == item.id),
                          typedResults: items,
                        ),
                      if (penOccupancyLambsRefs)
                        await $_getPrefetchedData<Lamb, $LambsTable, PenOccupancyLamb>(
                          currentTable: table,
                          referencedTable: $$LambsTableReferences._penOccupancyLambsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LambsTableReferences(db, table, p0).penOccupancyLambsRefs,
                          referencedItemsForCurrentItem: (item, referencedItems) =>
                              referencedItems.where((e) => e.lamb == item.id),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$LambsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LambsTable,
      Lamb,
      $$LambsTableFilterComposer,
      $$LambsTableOrderingComposer,
      $$LambsTableAnnotationComposer,
      $$LambsTableCreateCompanionBuilder,
      $$LambsTableUpdateCompanionBuilder,
      (Lamb, $$LambsTableReferences),
      Lamb,
      PrefetchHooks Function({
        bool lambing,
        bool birthDam,
        bool becameEwe,
        bool treatmentsRefs,
        bool penOccupancyLambsRefs,
      })
    >;
typedef $$EweSeasonsTableCreateCompanionBuilder =
    EweSeasonsCompanion Function({
      Value<int> id,
      required String uid,
      required Instant createdAt,
      required Instant updatedAt,
      Value<bool> struck,
      Value<Instant?> struckAt,
      required int season,
      required int ewe,
      required String status,
      Value<int?> scannedCount,
      Value<String?> notes,
    });
typedef $$EweSeasonsTableUpdateCompanionBuilder =
    EweSeasonsCompanion Function({
      Value<int> id,
      Value<String> uid,
      Value<Instant> createdAt,
      Value<Instant> updatedAt,
      Value<bool> struck,
      Value<Instant?> struckAt,
      Value<int> season,
      Value<int> ewe,
      Value<String> status,
      Value<int?> scannedCount,
      Value<String?> notes,
    });

final class $$EweSeasonsTableReferences
    extends BaseReferences<_$AppDatabase, $EweSeasonsTable, EweSeason> {
  $$EweSeasonsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SeasonsTable _seasonTable(_$AppDatabase db) =>
      db.seasons.createAlias('ewe_seasons__season__seasons__id');

  $$SeasonsTableProcessedTableManager get season {
    final $_column = $_itemColumn<int>('season')!;

    final manager = $$SeasonsTableTableManager(
      $_db,
      $_db.seasons,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_seasonTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static $EwesTable _eweTable(_$AppDatabase db) =>
      db.ewes.createAlias('ewe_seasons__ewe__ewes__id');

  $$EwesTableProcessedTableManager get ewe {
    final $_column = $_itemColumn<int>('ewe')!;

    final manager = $$EwesTableTableManager(
      $_db,
      $_db.ewes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_eweTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$EweSeasonsTableFilterComposer extends Composer<_$AppDatabase, $EweSeasonsTable> {
  $$EweSeasonsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<Instant, Instant, int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<Instant, Instant, int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<bool> get struck =>
      $composableBuilder(column: $table.struck, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<Instant?, Instant, int> get struckAt => $composableBuilder(
    column: $table.struckAt,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get scannedCount =>
      $composableBuilder(column: $table.scannedCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => ColumnFilters(column));

  $$SeasonsTableFilterComposer get season {
    final $$SeasonsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.season,
      referencedTable: $db.seasons,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$SeasonsTableFilterComposer(
            $db: $db,
            $table: $db.seasons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EwesTableFilterComposer get ewe {
    final $$EwesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ewe,
      referencedTable: $db.ewes,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$EwesTableFilterComposer(
            $db: $db,
            $table: $db.ewes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EweSeasonsTableOrderingComposer extends Composer<_$AppDatabase, $EweSeasonsTable> {
  $$EweSeasonsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get struck =>
      $composableBuilder(column: $table.struck, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get struckAt =>
      $composableBuilder(column: $table.struckAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get scannedCount =>
      $composableBuilder(column: $table.scannedCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => ColumnOrderings(column));

  $$SeasonsTableOrderingComposer get season {
    final $$SeasonsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.season,
      referencedTable: $db.seasons,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$SeasonsTableOrderingComposer(
            $db: $db,
            $table: $db.seasons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EwesTableOrderingComposer get ewe {
    final $$EwesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ewe,
      referencedTable: $db.ewes,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$EwesTableOrderingComposer(
            $db: $db,
            $table: $db.ewes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EweSeasonsTableAnnotationComposer extends Composer<_$AppDatabase, $EweSeasonsTable> {
  $$EweSeasonsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Instant, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Instant, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get struck =>
      $composableBuilder(column: $table.struck, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Instant?, int> get struckAt =>
      $composableBuilder(column: $table.struckAt, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get scannedCount =>
      $composableBuilder(column: $table.scannedCount, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  $$SeasonsTableAnnotationComposer get season {
    final $$SeasonsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.season,
      referencedTable: $db.seasons,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$SeasonsTableAnnotationComposer(
            $db: $db,
            $table: $db.seasons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EwesTableAnnotationComposer get ewe {
    final $$EwesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ewe,
      referencedTable: $db.ewes,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$EwesTableAnnotationComposer(
            $db: $db,
            $table: $db.ewes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EweSeasonsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EweSeasonsTable,
          EweSeason,
          $$EweSeasonsTableFilterComposer,
          $$EweSeasonsTableOrderingComposer,
          $$EweSeasonsTableAnnotationComposer,
          $$EweSeasonsTableCreateCompanionBuilder,
          $$EweSeasonsTableUpdateCompanionBuilder,
          (EweSeason, $$EweSeasonsTableReferences),
          EweSeason,
          PrefetchHooks Function({bool season, bool ewe})
        > {
  $$EweSeasonsTableTableManager(_$AppDatabase db, $EweSeasonsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$EweSeasonsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$EweSeasonsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EweSeasonsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uid = const Value.absent(),
                Value<Instant> createdAt = const Value.absent(),
                Value<Instant> updatedAt = const Value.absent(),
                Value<bool> struck = const Value.absent(),
                Value<Instant?> struckAt = const Value.absent(),
                Value<int> season = const Value.absent(),
                Value<int> ewe = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int?> scannedCount = const Value.absent(),
                Value<String?> notes = const Value.absent(),
              }) => EweSeasonsCompanion(
                id: id,
                uid: uid,
                createdAt: createdAt,
                updatedAt: updatedAt,
                struck: struck,
                struckAt: struckAt,
                season: season,
                ewe: ewe,
                status: status,
                scannedCount: scannedCount,
                notes: notes,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String uid,
                required Instant createdAt,
                required Instant updatedAt,
                Value<bool> struck = const Value.absent(),
                Value<Instant?> struckAt = const Value.absent(),
                required int season,
                required int ewe,
                required String status,
                Value<int?> scannedCount = const Value.absent(),
                Value<String?> notes = const Value.absent(),
              }) => EweSeasonsCompanion.insert(
                id: id,
                uid: uid,
                createdAt: createdAt,
                updatedAt: updatedAt,
                struck: struck,
                struckAt: struckAt,
                season: season,
                ewe: ewe,
                status: status,
                scannedCount: scannedCount,
                notes: notes,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), $$EweSeasonsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({season = false, ewe = false}) {
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
                    if (season) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.season,
                                referencedTable: $$EweSeasonsTableReferences._seasonTable(db),
                                referencedColumn: $$EweSeasonsTableReferences._seasonTable(db).id,
                              )
                              as T;
                    }
                    if (ewe) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.ewe,
                                referencedTable: $$EweSeasonsTableReferences._eweTable(db),
                                referencedColumn: $$EweSeasonsTableReferences._eweTable(db).id,
                              )
                              as T;
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

typedef $$EweSeasonsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EweSeasonsTable,
      EweSeason,
      $$EweSeasonsTableFilterComposer,
      $$EweSeasonsTableOrderingComposer,
      $$EweSeasonsTableAnnotationComposer,
      $$EweSeasonsTableCreateCompanionBuilder,
      $$EweSeasonsTableUpdateCompanionBuilder,
      (EweSeason, $$EweSeasonsTableReferences),
      EweSeason,
      PrefetchHooks Function({bool season, bool ewe})
    >;
typedef $$EweTouchesTableCreateCompanionBuilder =
    EweTouchesCompanion Function({Value<int> ewe, required Instant touchedAt});
typedef $$EweTouchesTableUpdateCompanionBuilder =
    EweTouchesCompanion Function({Value<int> ewe, Value<Instant> touchedAt});

final class $$EweTouchesTableReferences
    extends BaseReferences<_$AppDatabase, $EweTouchesTable, EweTouch> {
  $$EweTouchesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $EwesTable _eweTable(_$AppDatabase db) =>
      db.ewes.createAlias('ewe_touches__ewe__ewes__id');

  $$EwesTableProcessedTableManager get ewe {
    final $_column = $_itemColumn<int>('ewe')!;

    final manager = $$EwesTableTableManager(
      $_db,
      $_db.ewes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_eweTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$EweTouchesTableFilterComposer extends Composer<_$AppDatabase, $EweTouchesTable> {
  $$EweTouchesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnWithTypeConverterFilters<Instant, Instant, int> get touchedAt => $composableBuilder(
    column: $table.touchedAt,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  $$EwesTableFilterComposer get ewe {
    final $$EwesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ewe,
      referencedTable: $db.ewes,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$EwesTableFilterComposer(
            $db: $db,
            $table: $db.ewes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EweTouchesTableOrderingComposer extends Composer<_$AppDatabase, $EweTouchesTable> {
  $$EweTouchesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get touchedAt =>
      $composableBuilder(column: $table.touchedAt, builder: (column) => ColumnOrderings(column));

  $$EwesTableOrderingComposer get ewe {
    final $$EwesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ewe,
      referencedTable: $db.ewes,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$EwesTableOrderingComposer(
            $db: $db,
            $table: $db.ewes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EweTouchesTableAnnotationComposer extends Composer<_$AppDatabase, $EweTouchesTable> {
  $$EweTouchesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumnWithTypeConverter<Instant, int> get touchedAt =>
      $composableBuilder(column: $table.touchedAt, builder: (column) => column);

  $$EwesTableAnnotationComposer get ewe {
    final $$EwesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ewe,
      referencedTable: $db.ewes,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$EwesTableAnnotationComposer(
            $db: $db,
            $table: $db.ewes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EweTouchesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EweTouchesTable,
          EweTouch,
          $$EweTouchesTableFilterComposer,
          $$EweTouchesTableOrderingComposer,
          $$EweTouchesTableAnnotationComposer,
          $$EweTouchesTableCreateCompanionBuilder,
          $$EweTouchesTableUpdateCompanionBuilder,
          (EweTouch, $$EweTouchesTableReferences),
          EweTouch,
          PrefetchHooks Function({bool ewe})
        > {
  $$EweTouchesTableTableManager(_$AppDatabase db, $EweTouchesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$EweTouchesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$EweTouchesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EweTouchesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> ewe = const Value.absent(),
                Value<Instant> touchedAt = const Value.absent(),
              }) => EweTouchesCompanion(ewe: ewe, touchedAt: touchedAt),
          createCompanionCallback:
              ({Value<int> ewe = const Value.absent(), required Instant touchedAt}) =>
                  EweTouchesCompanion.insert(ewe: ewe, touchedAt: touchedAt),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), $$EweTouchesTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({ewe = false}) {
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
                    if (ewe) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.ewe,
                                referencedTable: $$EweTouchesTableReferences._eweTable(db),
                                referencedColumn: $$EweTouchesTableReferences._eweTable(db).id,
                              )
                              as T;
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

typedef $$EweTouchesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EweTouchesTable,
      EweTouch,
      $$EweTouchesTableFilterComposer,
      $$EweTouchesTableOrderingComposer,
      $$EweTouchesTableAnnotationComposer,
      $$EweTouchesTableCreateCompanionBuilder,
      $$EweTouchesTableUpdateCompanionBuilder,
      (EweTouch, $$EweTouchesTableReferences),
      EweTouch,
      PrefetchHooks Function({bool ewe})
    >;
typedef $$EweObservationsTableCreateCompanionBuilder =
    EweObservationsCompanion Function({
      Value<int> id,
      required String uid,
      required Instant createdAt,
      required Instant updatedAt,
      Value<bool> struck,
      Value<Instant?> struckAt,
      required int ewe,
      required int season,
      Value<int?> lambing,
      required String kind,
      required Instant occurredAt,
      required Instant capturedAt,
      Value<Instant?> originalEffective,
      Value<String> timeSource,
      Value<String?> note,
    });
typedef $$EweObservationsTableUpdateCompanionBuilder =
    EweObservationsCompanion Function({
      Value<int> id,
      Value<String> uid,
      Value<Instant> createdAt,
      Value<Instant> updatedAt,
      Value<bool> struck,
      Value<Instant?> struckAt,
      Value<int> ewe,
      Value<int> season,
      Value<int?> lambing,
      Value<String> kind,
      Value<Instant> occurredAt,
      Value<Instant> capturedAt,
      Value<Instant?> originalEffective,
      Value<String> timeSource,
      Value<String?> note,
    });

final class $$EweObservationsTableReferences
    extends BaseReferences<_$AppDatabase, $EweObservationsTable, EweObservation> {
  $$EweObservationsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $EwesTable _eweTable(_$AppDatabase db) =>
      db.ewes.createAlias('ewe_observations__ewe__ewes__id');

  $$EwesTableProcessedTableManager get ewe {
    final $_column = $_itemColumn<int>('ewe')!;

    final manager = $$EwesTableTableManager(
      $_db,
      $_db.ewes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_eweTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static $SeasonsTable _seasonTable(_$AppDatabase db) =>
      db.seasons.createAlias('ewe_observations__season__seasons__id');

  $$SeasonsTableProcessedTableManager get season {
    final $_column = $_itemColumn<int>('season')!;

    final manager = $$SeasonsTableTableManager(
      $_db,
      $_db.seasons,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_seasonTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static $LambingsTable _lambingTable(_$AppDatabase db) =>
      db.lambings.createAlias('ewe_observations__lambing__lambings__id');

  $$LambingsTableProcessedTableManager? get lambing {
    final $_column = $_itemColumn<int>('lambing');
    if ($_column == null) return null;
    final manager = $$LambingsTableTableManager(
      $_db,
      $_db.lambings,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_lambingTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$EweObservationsTableFilterComposer extends Composer<_$AppDatabase, $EweObservationsTable> {
  $$EweObservationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<Instant, Instant, int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<Instant, Instant, int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<bool> get struck =>
      $composableBuilder(column: $table.struck, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<Instant?, Instant, int> get struckAt => $composableBuilder(
    column: $table.struckAt,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<Instant, Instant, int> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<Instant, Instant, int> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<Instant?, Instant, int> get originalEffective =>
      $composableBuilder(
        column: $table.originalEffective,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get timeSource =>
      $composableBuilder(column: $table.timeSource, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => ColumnFilters(column));

  $$EwesTableFilterComposer get ewe {
    final $$EwesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ewe,
      referencedTable: $db.ewes,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$EwesTableFilterComposer(
            $db: $db,
            $table: $db.ewes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SeasonsTableFilterComposer get season {
    final $$SeasonsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.season,
      referencedTable: $db.seasons,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$SeasonsTableFilterComposer(
            $db: $db,
            $table: $db.seasons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LambingsTableFilterComposer get lambing {
    final $$LambingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lambing,
      referencedTable: $db.lambings,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$LambingsTableFilterComposer(
            $db: $db,
            $table: $db.lambings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EweObservationsTableOrderingComposer
    extends Composer<_$AppDatabase, $EweObservationsTable> {
  $$EweObservationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get struck =>
      $composableBuilder(column: $table.struck, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get struckAt =>
      $composableBuilder(column: $table.struckAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get occurredAt =>
      $composableBuilder(column: $table.occurredAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get capturedAt =>
      $composableBuilder(column: $table.capturedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get originalEffective => $composableBuilder(
    column: $table.originalEffective,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timeSource =>
      $composableBuilder(column: $table.timeSource, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => ColumnOrderings(column));

  $$EwesTableOrderingComposer get ewe {
    final $$EwesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ewe,
      referencedTable: $db.ewes,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$EwesTableOrderingComposer(
            $db: $db,
            $table: $db.ewes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SeasonsTableOrderingComposer get season {
    final $$SeasonsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.season,
      referencedTable: $db.seasons,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$SeasonsTableOrderingComposer(
            $db: $db,
            $table: $db.seasons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LambingsTableOrderingComposer get lambing {
    final $$LambingsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lambing,
      referencedTable: $db.lambings,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$LambingsTableOrderingComposer(
            $db: $db,
            $table: $db.lambings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EweObservationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EweObservationsTable> {
  $$EweObservationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Instant, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Instant, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get struck =>
      $composableBuilder(column: $table.struck, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Instant?, int> get struckAt =>
      $composableBuilder(column: $table.struckAt, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Instant, int> get occurredAt =>
      $composableBuilder(column: $table.occurredAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Instant, int> get capturedAt =>
      $composableBuilder(column: $table.capturedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Instant?, int> get originalEffective =>
      $composableBuilder(column: $table.originalEffective, builder: (column) => column);

  GeneratedColumn<String> get timeSource =>
      $composableBuilder(column: $table.timeSource, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  $$EwesTableAnnotationComposer get ewe {
    final $$EwesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ewe,
      referencedTable: $db.ewes,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$EwesTableAnnotationComposer(
            $db: $db,
            $table: $db.ewes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SeasonsTableAnnotationComposer get season {
    final $$SeasonsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.season,
      referencedTable: $db.seasons,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$SeasonsTableAnnotationComposer(
            $db: $db,
            $table: $db.seasons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LambingsTableAnnotationComposer get lambing {
    final $$LambingsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lambing,
      referencedTable: $db.lambings,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$LambingsTableAnnotationComposer(
            $db: $db,
            $table: $db.lambings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EweObservationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EweObservationsTable,
          EweObservation,
          $$EweObservationsTableFilterComposer,
          $$EweObservationsTableOrderingComposer,
          $$EweObservationsTableAnnotationComposer,
          $$EweObservationsTableCreateCompanionBuilder,
          $$EweObservationsTableUpdateCompanionBuilder,
          (EweObservation, $$EweObservationsTableReferences),
          EweObservation,
          PrefetchHooks Function({bool ewe, bool season, bool lambing})
        > {
  $$EweObservationsTableTableManager(_$AppDatabase db, $EweObservationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EweObservationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EweObservationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EweObservationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uid = const Value.absent(),
                Value<Instant> createdAt = const Value.absent(),
                Value<Instant> updatedAt = const Value.absent(),
                Value<bool> struck = const Value.absent(),
                Value<Instant?> struckAt = const Value.absent(),
                Value<int> ewe = const Value.absent(),
                Value<int> season = const Value.absent(),
                Value<int?> lambing = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<Instant> occurredAt = const Value.absent(),
                Value<Instant> capturedAt = const Value.absent(),
                Value<Instant?> originalEffective = const Value.absent(),
                Value<String> timeSource = const Value.absent(),
                Value<String?> note = const Value.absent(),
              }) => EweObservationsCompanion(
                id: id,
                uid: uid,
                createdAt: createdAt,
                updatedAt: updatedAt,
                struck: struck,
                struckAt: struckAt,
                ewe: ewe,
                season: season,
                lambing: lambing,
                kind: kind,
                occurredAt: occurredAt,
                capturedAt: capturedAt,
                originalEffective: originalEffective,
                timeSource: timeSource,
                note: note,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String uid,
                required Instant createdAt,
                required Instant updatedAt,
                Value<bool> struck = const Value.absent(),
                Value<Instant?> struckAt = const Value.absent(),
                required int ewe,
                required int season,
                Value<int?> lambing = const Value.absent(),
                required String kind,
                required Instant occurredAt,
                required Instant capturedAt,
                Value<Instant?> originalEffective = const Value.absent(),
                Value<String> timeSource = const Value.absent(),
                Value<String?> note = const Value.absent(),
              }) => EweObservationsCompanion.insert(
                id: id,
                uid: uid,
                createdAt: createdAt,
                updatedAt: updatedAt,
                struck: struck,
                struckAt: struckAt,
                ewe: ewe,
                season: season,
                lambing: lambing,
                kind: kind,
                occurredAt: occurredAt,
                capturedAt: capturedAt,
                originalEffective: originalEffective,
                timeSource: timeSource,
                note: note,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), $$EweObservationsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({ewe = false, season = false, lambing = false}) {
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
                    if (ewe) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.ewe,
                                referencedTable: $$EweObservationsTableReferences._eweTable(db),
                                referencedColumn: $$EweObservationsTableReferences._eweTable(db).id,
                              )
                              as T;
                    }
                    if (season) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.season,
                                referencedTable: $$EweObservationsTableReferences._seasonTable(db),
                                referencedColumn: $$EweObservationsTableReferences
                                    ._seasonTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (lambing) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.lambing,
                                referencedTable: $$EweObservationsTableReferences._lambingTable(db),
                                referencedColumn: $$EweObservationsTableReferences
                                    ._lambingTable(db)
                                    .id,
                              )
                              as T;
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

typedef $$EweObservationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EweObservationsTable,
      EweObservation,
      $$EweObservationsTableFilterComposer,
      $$EweObservationsTableOrderingComposer,
      $$EweObservationsTableAnnotationComposer,
      $$EweObservationsTableCreateCompanionBuilder,
      $$EweObservationsTableUpdateCompanionBuilder,
      (EweObservation, $$EweObservationsTableReferences),
      EweObservation,
      PrefetchHooks Function({bool ewe, bool season, bool lambing})
    >;
typedef $$TreatmentsTableCreateCompanionBuilder =
    TreatmentsCompanion Function({
      Value<int> id,
      required String uid,
      required Instant createdAt,
      required Instant updatedAt,
      required int season,
      Value<int?> ewe,
      Value<int?> lamb,
      required String productName,
      Value<String?> doseText,
      Value<String?> route,
      Value<String?> batchNo,
      required Instant administeredAt,
      required Instant capturedAt,
      Value<Instant?> originalEffective,
      Value<String> timeSource,
      Value<Instant?> voidedAt,
      Value<String?> note,
    });
typedef $$TreatmentsTableUpdateCompanionBuilder =
    TreatmentsCompanion Function({
      Value<int> id,
      Value<String> uid,
      Value<Instant> createdAt,
      Value<Instant> updatedAt,
      Value<int> season,
      Value<int?> ewe,
      Value<int?> lamb,
      Value<String> productName,
      Value<String?> doseText,
      Value<String?> route,
      Value<String?> batchNo,
      Value<Instant> administeredAt,
      Value<Instant> capturedAt,
      Value<Instant?> originalEffective,
      Value<String> timeSource,
      Value<Instant?> voidedAt,
      Value<String?> note,
    });

final class $$TreatmentsTableReferences
    extends BaseReferences<_$AppDatabase, $TreatmentsTable, Treatment> {
  $$TreatmentsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SeasonsTable _seasonTable(_$AppDatabase db) =>
      db.seasons.createAlias('treatments__season__seasons__id');

  $$SeasonsTableProcessedTableManager get season {
    final $_column = $_itemColumn<int>('season')!;

    final manager = $$SeasonsTableTableManager(
      $_db,
      $_db.seasons,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_seasonTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static $EwesTable _eweTable(_$AppDatabase db) => db.ewes.createAlias('treatments__ewe__ewes__id');

  $$EwesTableProcessedTableManager? get ewe {
    final $_column = $_itemColumn<int>('ewe');
    if ($_column == null) return null;
    final manager = $$EwesTableTableManager(
      $_db,
      $_db.ewes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_eweTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static $LambsTable _lambTable(_$AppDatabase db) =>
      db.lambs.createAlias('treatments__lamb__lambs__id');

  $$LambsTableProcessedTableManager? get lamb {
    final $_column = $_itemColumn<int>('lamb');
    if ($_column == null) return null;
    final manager = $$LambsTableTableManager(
      $_db,
      $_db.lambs,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_lambTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$TreatmentWithdrawalsTable, List<TreatmentWithdrawal>>
  _treatmentWithdrawalsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.treatmentWithdrawals,
    aliasName: 'treatments__id__treatment_withdrawals__treatment',
  );

  $$TreatmentWithdrawalsTableProcessedTableManager get treatmentWithdrawalsRefs {
    final manager = $$TreatmentWithdrawalsTableTableManager(
      $_db,
      $_db.treatmentWithdrawals,
    ).filter((f) => f.treatment.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_treatmentWithdrawalsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$TreatmentsTableFilterComposer extends Composer<_$AppDatabase, $TreatmentsTable> {
  $$TreatmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<Instant, Instant, int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<Instant, Instant, int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get productName =>
      $composableBuilder(column: $table.productName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get doseText =>
      $composableBuilder(column: $table.doseText, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get route =>
      $composableBuilder(column: $table.route, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get batchNo =>
      $composableBuilder(column: $table.batchNo, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<Instant, Instant, int> get administeredAt => $composableBuilder(
    column: $table.administeredAt,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<Instant, Instant, int> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<Instant?, Instant, int> get originalEffective =>
      $composableBuilder(
        column: $table.originalEffective,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get timeSource =>
      $composableBuilder(column: $table.timeSource, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<Instant?, Instant, int> get voidedAt => $composableBuilder(
    column: $table.voidedAt,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => ColumnFilters(column));

  $$SeasonsTableFilterComposer get season {
    final $$SeasonsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.season,
      referencedTable: $db.seasons,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$SeasonsTableFilterComposer(
            $db: $db,
            $table: $db.seasons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EwesTableFilterComposer get ewe {
    final $$EwesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ewe,
      referencedTable: $db.ewes,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$EwesTableFilterComposer(
            $db: $db,
            $table: $db.ewes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LambsTableFilterComposer get lamb {
    final $$LambsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lamb,
      referencedTable: $db.lambs,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$LambsTableFilterComposer(
            $db: $db,
            $table: $db.lambs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> treatmentWithdrawalsRefs(
    Expression<bool> Function($$TreatmentWithdrawalsTableFilterComposer f) f,
  ) {
    final $$TreatmentWithdrawalsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.treatmentWithdrawals,
      getReferencedColumn: (t) => t.treatment,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$TreatmentWithdrawalsTableFilterComposer(
            $db: $db,
            $table: $db.treatmentWithdrawals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TreatmentsTableOrderingComposer extends Composer<_$AppDatabase, $TreatmentsTable> {
  $$TreatmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get productName =>
      $composableBuilder(column: $table.productName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get doseText =>
      $composableBuilder(column: $table.doseText, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get route =>
      $composableBuilder(column: $table.route, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get batchNo =>
      $composableBuilder(column: $table.batchNo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get administeredAt => $composableBuilder(
    column: $table.administeredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get capturedAt =>
      $composableBuilder(column: $table.capturedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get originalEffective => $composableBuilder(
    column: $table.originalEffective,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timeSource =>
      $composableBuilder(column: $table.timeSource, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get voidedAt =>
      $composableBuilder(column: $table.voidedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => ColumnOrderings(column));

  $$SeasonsTableOrderingComposer get season {
    final $$SeasonsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.season,
      referencedTable: $db.seasons,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$SeasonsTableOrderingComposer(
            $db: $db,
            $table: $db.seasons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EwesTableOrderingComposer get ewe {
    final $$EwesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ewe,
      referencedTable: $db.ewes,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$EwesTableOrderingComposer(
            $db: $db,
            $table: $db.ewes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LambsTableOrderingComposer get lamb {
    final $$LambsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lamb,
      referencedTable: $db.lambs,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$LambsTableOrderingComposer(
            $db: $db,
            $table: $db.lambs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TreatmentsTableAnnotationComposer extends Composer<_$AppDatabase, $TreatmentsTable> {
  $$TreatmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Instant, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Instant, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get productName =>
      $composableBuilder(column: $table.productName, builder: (column) => column);

  GeneratedColumn<String> get doseText =>
      $composableBuilder(column: $table.doseText, builder: (column) => column);

  GeneratedColumn<String> get route =>
      $composableBuilder(column: $table.route, builder: (column) => column);

  GeneratedColumn<String> get batchNo =>
      $composableBuilder(column: $table.batchNo, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Instant, int> get administeredAt =>
      $composableBuilder(column: $table.administeredAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Instant, int> get capturedAt =>
      $composableBuilder(column: $table.capturedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Instant?, int> get originalEffective =>
      $composableBuilder(column: $table.originalEffective, builder: (column) => column);

  GeneratedColumn<String> get timeSource =>
      $composableBuilder(column: $table.timeSource, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Instant?, int> get voidedAt =>
      $composableBuilder(column: $table.voidedAt, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  $$SeasonsTableAnnotationComposer get season {
    final $$SeasonsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.season,
      referencedTable: $db.seasons,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$SeasonsTableAnnotationComposer(
            $db: $db,
            $table: $db.seasons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EwesTableAnnotationComposer get ewe {
    final $$EwesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ewe,
      referencedTable: $db.ewes,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$EwesTableAnnotationComposer(
            $db: $db,
            $table: $db.ewes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LambsTableAnnotationComposer get lamb {
    final $$LambsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lamb,
      referencedTable: $db.lambs,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$LambsTableAnnotationComposer(
            $db: $db,
            $table: $db.lambs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> treatmentWithdrawalsRefs<T extends Object>(
    Expression<T> Function($$TreatmentWithdrawalsTableAnnotationComposer a) f,
  ) {
    final $$TreatmentWithdrawalsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.treatmentWithdrawals,
      getReferencedColumn: (t) => t.treatment,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$TreatmentWithdrawalsTableAnnotationComposer(
            $db: $db,
            $table: $db.treatmentWithdrawals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TreatmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TreatmentsTable,
          Treatment,
          $$TreatmentsTableFilterComposer,
          $$TreatmentsTableOrderingComposer,
          $$TreatmentsTableAnnotationComposer,
          $$TreatmentsTableCreateCompanionBuilder,
          $$TreatmentsTableUpdateCompanionBuilder,
          (Treatment, $$TreatmentsTableReferences),
          Treatment,
          PrefetchHooks Function({bool season, bool ewe, bool lamb, bool treatmentWithdrawalsRefs})
        > {
  $$TreatmentsTableTableManager(_$AppDatabase db, $TreatmentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$TreatmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$TreatmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TreatmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uid = const Value.absent(),
                Value<Instant> createdAt = const Value.absent(),
                Value<Instant> updatedAt = const Value.absent(),
                Value<int> season = const Value.absent(),
                Value<int?> ewe = const Value.absent(),
                Value<int?> lamb = const Value.absent(),
                Value<String> productName = const Value.absent(),
                Value<String?> doseText = const Value.absent(),
                Value<String?> route = const Value.absent(),
                Value<String?> batchNo = const Value.absent(),
                Value<Instant> administeredAt = const Value.absent(),
                Value<Instant> capturedAt = const Value.absent(),
                Value<Instant?> originalEffective = const Value.absent(),
                Value<String> timeSource = const Value.absent(),
                Value<Instant?> voidedAt = const Value.absent(),
                Value<String?> note = const Value.absent(),
              }) => TreatmentsCompanion(
                id: id,
                uid: uid,
                createdAt: createdAt,
                updatedAt: updatedAt,
                season: season,
                ewe: ewe,
                lamb: lamb,
                productName: productName,
                doseText: doseText,
                route: route,
                batchNo: batchNo,
                administeredAt: administeredAt,
                capturedAt: capturedAt,
                originalEffective: originalEffective,
                timeSource: timeSource,
                voidedAt: voidedAt,
                note: note,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String uid,
                required Instant createdAt,
                required Instant updatedAt,
                required int season,
                Value<int?> ewe = const Value.absent(),
                Value<int?> lamb = const Value.absent(),
                required String productName,
                Value<String?> doseText = const Value.absent(),
                Value<String?> route = const Value.absent(),
                Value<String?> batchNo = const Value.absent(),
                required Instant administeredAt,
                required Instant capturedAt,
                Value<Instant?> originalEffective = const Value.absent(),
                Value<String> timeSource = const Value.absent(),
                Value<Instant?> voidedAt = const Value.absent(),
                Value<String?> note = const Value.absent(),
              }) => TreatmentsCompanion.insert(
                id: id,
                uid: uid,
                createdAt: createdAt,
                updatedAt: updatedAt,
                season: season,
                ewe: ewe,
                lamb: lamb,
                productName: productName,
                doseText: doseText,
                route: route,
                batchNo: batchNo,
                administeredAt: administeredAt,
                capturedAt: capturedAt,
                originalEffective: originalEffective,
                timeSource: timeSource,
                voidedAt: voidedAt,
                note: note,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), $$TreatmentsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback:
              ({season = false, ewe = false, lamb = false, treatmentWithdrawalsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [if (treatmentWithdrawalsRefs) db.treatmentWithdrawals],
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
                        if (season) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.season,
                                    referencedTable: $$TreatmentsTableReferences._seasonTable(db),
                                    referencedColumn: $$TreatmentsTableReferences
                                        ._seasonTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (ewe) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.ewe,
                                    referencedTable: $$TreatmentsTableReferences._eweTable(db),
                                    referencedColumn: $$TreatmentsTableReferences._eweTable(db).id,
                                  )
                                  as T;
                        }
                        if (lamb) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.lamb,
                                    referencedTable: $$TreatmentsTableReferences._lambTable(db),
                                    referencedColumn: $$TreatmentsTableReferences._lambTable(db).id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (treatmentWithdrawalsRefs)
                        await $_getPrefetchedData<Treatment, $TreatmentsTable, TreatmentWithdrawal>(
                          currentTable: table,
                          referencedTable: $$TreatmentsTableReferences
                              ._treatmentWithdrawalsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TreatmentsTableReferences(db, table, p0).treatmentWithdrawalsRefs,
                          referencedItemsForCurrentItem: (item, referencedItems) =>
                              referencedItems.where((e) => e.treatment == item.id),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$TreatmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TreatmentsTable,
      Treatment,
      $$TreatmentsTableFilterComposer,
      $$TreatmentsTableOrderingComposer,
      $$TreatmentsTableAnnotationComposer,
      $$TreatmentsTableCreateCompanionBuilder,
      $$TreatmentsTableUpdateCompanionBuilder,
      (Treatment, $$TreatmentsTableReferences),
      Treatment,
      PrefetchHooks Function({bool season, bool ewe, bool lamb, bool treatmentWithdrawalsRefs})
    >;
typedef $$TreatmentWithdrawalsTableCreateCompanionBuilder =
    TreatmentWithdrawalsCompanion Function({
      Value<int> id,
      required String uid,
      required Instant createdAt,
      required Instant updatedAt,
      required int treatment,
      required String target,
      required String kind,
      Value<int?> days,
      Value<LocalDate?> clearDate,
    });
typedef $$TreatmentWithdrawalsTableUpdateCompanionBuilder =
    TreatmentWithdrawalsCompanion Function({
      Value<int> id,
      Value<String> uid,
      Value<Instant> createdAt,
      Value<Instant> updatedAt,
      Value<int> treatment,
      Value<String> target,
      Value<String> kind,
      Value<int?> days,
      Value<LocalDate?> clearDate,
    });

final class $$TreatmentWithdrawalsTableReferences
    extends BaseReferences<_$AppDatabase, $TreatmentWithdrawalsTable, TreatmentWithdrawal> {
  $$TreatmentWithdrawalsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TreatmentsTable _treatmentTable(_$AppDatabase db) =>
      db.treatments.createAlias('treatment_withdrawals__treatment__treatments__id');

  $$TreatmentsTableProcessedTableManager get treatment {
    final $_column = $_itemColumn<int>('treatment')!;

    final manager = $$TreatmentsTableTableManager(
      $_db,
      $_db.treatments,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_treatmentTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$TreatmentWithdrawalsTableFilterComposer
    extends Composer<_$AppDatabase, $TreatmentWithdrawalsTable> {
  $$TreatmentWithdrawalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<Instant, Instant, int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<Instant, Instant, int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get target =>
      $composableBuilder(column: $table.target, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get days =>
      $composableBuilder(column: $table.days, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<LocalDate?, LocalDate, String> get clearDate => $composableBuilder(
    column: $table.clearDate,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  $$TreatmentsTableFilterComposer get treatment {
    final $$TreatmentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.treatment,
      referencedTable: $db.treatments,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$TreatmentsTableFilterComposer(
            $db: $db,
            $table: $db.treatments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TreatmentWithdrawalsTableOrderingComposer
    extends Composer<_$AppDatabase, $TreatmentWithdrawalsTable> {
  $$TreatmentWithdrawalsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get target =>
      $composableBuilder(column: $table.target, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get days =>
      $composableBuilder(column: $table.days, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get clearDate =>
      $composableBuilder(column: $table.clearDate, builder: (column) => ColumnOrderings(column));

  $$TreatmentsTableOrderingComposer get treatment {
    final $$TreatmentsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.treatment,
      referencedTable: $db.treatments,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$TreatmentsTableOrderingComposer(
            $db: $db,
            $table: $db.treatments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TreatmentWithdrawalsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TreatmentWithdrawalsTable> {
  $$TreatmentWithdrawalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Instant, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Instant, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get target =>
      $composableBuilder(column: $table.target, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get days =>
      $composableBuilder(column: $table.days, builder: (column) => column);

  GeneratedColumnWithTypeConverter<LocalDate?, String> get clearDate =>
      $composableBuilder(column: $table.clearDate, builder: (column) => column);

  $$TreatmentsTableAnnotationComposer get treatment {
    final $$TreatmentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.treatment,
      referencedTable: $db.treatments,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$TreatmentsTableAnnotationComposer(
            $db: $db,
            $table: $db.treatments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TreatmentWithdrawalsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TreatmentWithdrawalsTable,
          TreatmentWithdrawal,
          $$TreatmentWithdrawalsTableFilterComposer,
          $$TreatmentWithdrawalsTableOrderingComposer,
          $$TreatmentWithdrawalsTableAnnotationComposer,
          $$TreatmentWithdrawalsTableCreateCompanionBuilder,
          $$TreatmentWithdrawalsTableUpdateCompanionBuilder,
          (TreatmentWithdrawal, $$TreatmentWithdrawalsTableReferences),
          TreatmentWithdrawal,
          PrefetchHooks Function({bool treatment})
        > {
  $$TreatmentWithdrawalsTableTableManager(_$AppDatabase db, $TreatmentWithdrawalsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TreatmentWithdrawalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TreatmentWithdrawalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TreatmentWithdrawalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uid = const Value.absent(),
                Value<Instant> createdAt = const Value.absent(),
                Value<Instant> updatedAt = const Value.absent(),
                Value<int> treatment = const Value.absent(),
                Value<String> target = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<int?> days = const Value.absent(),
                Value<LocalDate?> clearDate = const Value.absent(),
              }) => TreatmentWithdrawalsCompanion(
                id: id,
                uid: uid,
                createdAt: createdAt,
                updatedAt: updatedAt,
                treatment: treatment,
                target: target,
                kind: kind,
                days: days,
                clearDate: clearDate,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String uid,
                required Instant createdAt,
                required Instant updatedAt,
                required int treatment,
                required String target,
                required String kind,
                Value<int?> days = const Value.absent(),
                Value<LocalDate?> clearDate = const Value.absent(),
              }) => TreatmentWithdrawalsCompanion.insert(
                id: id,
                uid: uid,
                createdAt: createdAt,
                updatedAt: updatedAt,
                treatment: treatment,
                target: target,
                kind: kind,
                days: days,
                clearDate: clearDate,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), $$TreatmentWithdrawalsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({treatment = false}) {
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
                    if (treatment) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.treatment,
                                referencedTable: $$TreatmentWithdrawalsTableReferences
                                    ._treatmentTable(db),
                                referencedColumn: $$TreatmentWithdrawalsTableReferences
                                    ._treatmentTable(db)
                                    .id,
                              )
                              as T;
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

typedef $$TreatmentWithdrawalsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TreatmentWithdrawalsTable,
      TreatmentWithdrawal,
      $$TreatmentWithdrawalsTableFilterComposer,
      $$TreatmentWithdrawalsTableOrderingComposer,
      $$TreatmentWithdrawalsTableAnnotationComposer,
      $$TreatmentWithdrawalsTableCreateCompanionBuilder,
      $$TreatmentWithdrawalsTableUpdateCompanionBuilder,
      (TreatmentWithdrawal, $$TreatmentWithdrawalsTableReferences),
      TreatmentWithdrawal,
      PrefetchHooks Function({bool treatment})
    >;
typedef $$PensTableCreateCompanionBuilder =
    PensCompanion Function({
      Value<int> id,
      required String uid,
      required Instant createdAt,
      required Instant updatedAt,
      Value<bool> struck,
      Value<Instant?> struckAt,
      required String label,
      Value<int> sortOrder,
      Value<bool> isActive,
    });
typedef $$PensTableUpdateCompanionBuilder =
    PensCompanion Function({
      Value<int> id,
      Value<String> uid,
      Value<Instant> createdAt,
      Value<Instant> updatedAt,
      Value<bool> struck,
      Value<Instant?> struckAt,
      Value<String> label,
      Value<int> sortOrder,
      Value<bool> isActive,
    });

final class $$PensTableReferences extends BaseReferences<_$AppDatabase, $PensTable, Pen> {
  $$PensTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PenOccupanciesTable, List<PenOccupancy>> _penOccupanciesRefsTable(
    _$AppDatabase db,
  ) =>
      MultiTypedResultKey.fromTable(db.penOccupancies, aliasName: 'pens__id__pen_occupancies__pen');

  $$PenOccupanciesTableProcessedTableManager get penOccupanciesRefs {
    final manager = $$PenOccupanciesTableTableManager(
      $_db,
      $_db.penOccupancies,
    ).filter((f) => f.pen.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_penOccupanciesRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$PensTableFilterComposer extends Composer<_$AppDatabase, $PensTable> {
  $$PensTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<Instant, Instant, int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<Instant, Instant, int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<bool> get struck =>
      $composableBuilder(column: $table.struck, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<Instant?, Instant, int> get struckAt => $composableBuilder(
    column: $table.struckAt,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => ColumnFilters(column));

  Expression<bool> penOccupanciesRefs(
    Expression<bool> Function($$PenOccupanciesTableFilterComposer f) f,
  ) {
    final $$PenOccupanciesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.penOccupancies,
      getReferencedColumn: (t) => t.pen,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$PenOccupanciesTableFilterComposer(
            $db: $db,
            $table: $db.penOccupancies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PensTableOrderingComposer extends Composer<_$AppDatabase, $PensTable> {
  $$PensTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get struck =>
      $composableBuilder(column: $table.struck, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get struckAt =>
      $composableBuilder(column: $table.struckAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => ColumnOrderings(column));
}

class $$PensTableAnnotationComposer extends Composer<_$AppDatabase, $PensTable> {
  $$PensTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Instant, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Instant, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get struck =>
      $composableBuilder(column: $table.struck, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Instant?, int> get struckAt =>
      $composableBuilder(column: $table.struckAt, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  Expression<T> penOccupanciesRefs<T extends Object>(
    Expression<T> Function($$PenOccupanciesTableAnnotationComposer a) f,
  ) {
    final $$PenOccupanciesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.penOccupancies,
      getReferencedColumn: (t) => t.pen,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$PenOccupanciesTableAnnotationComposer(
            $db: $db,
            $table: $db.penOccupancies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PensTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PensTable,
          Pen,
          $$PensTableFilterComposer,
          $$PensTableOrderingComposer,
          $$PensTableAnnotationComposer,
          $$PensTableCreateCompanionBuilder,
          $$PensTableUpdateCompanionBuilder,
          (Pen, $$PensTableReferences),
          Pen,
          PrefetchHooks Function({bool penOccupanciesRefs})
        > {
  $$PensTableTableManager(_$AppDatabase db, $PensTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$PensTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$PensTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$PensTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uid = const Value.absent(),
                Value<Instant> createdAt = const Value.absent(),
                Value<Instant> updatedAt = const Value.absent(),
                Value<bool> struck = const Value.absent(),
                Value<Instant?> struckAt = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
              }) => PensCompanion(
                id: id,
                uid: uid,
                createdAt: createdAt,
                updatedAt: updatedAt,
                struck: struck,
                struckAt: struckAt,
                label: label,
                sortOrder: sortOrder,
                isActive: isActive,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String uid,
                required Instant createdAt,
                required Instant updatedAt,
                Value<bool> struck = const Value.absent(),
                Value<Instant?> struckAt = const Value.absent(),
                required String label,
                Value<int> sortOrder = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
              }) => PensCompanion.insert(
                id: id,
                uid: uid,
                createdAt: createdAt,
                updatedAt: updatedAt,
                struck: struck,
                struckAt: struckAt,
                label: label,
                sortOrder: sortOrder,
                isActive: isActive,
              ),
          withReferenceMapper: (p0) =>
              p0.map((e) => (e.readTable(table), $$PensTableReferences(db, table, e))).toList(),
          prefetchHooksCallback: ({penOccupanciesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (penOccupanciesRefs) db.penOccupancies],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (penOccupanciesRefs)
                    await $_getPrefetchedData<Pen, $PensTable, PenOccupancy>(
                      currentTable: table,
                      referencedTable: $$PensTableReferences._penOccupanciesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$PensTableReferences(db, table, p0).penOccupanciesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.pen == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$PensTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PensTable,
      Pen,
      $$PensTableFilterComposer,
      $$PensTableOrderingComposer,
      $$PensTableAnnotationComposer,
      $$PensTableCreateCompanionBuilder,
      $$PensTableUpdateCompanionBuilder,
      (Pen, $$PensTableReferences),
      Pen,
      PrefetchHooks Function({bool penOccupanciesRefs})
    >;
typedef $$PenOccupanciesTableCreateCompanionBuilder =
    PenOccupanciesCompanion Function({
      Value<int> id,
      required String uid,
      required Instant createdAt,
      required Instant updatedAt,
      Value<bool> struck,
      Value<Instant?> struckAt,
      required int pen,
      required int season,
      Value<int?> ewe,
      required Instant enteredAt,
      required Instant capturedAt,
      Value<Instant?> originalEffective,
      Value<String> timeSource,
      Value<Instant?> exitedAt,
      Value<String?> exitReason,
    });
typedef $$PenOccupanciesTableUpdateCompanionBuilder =
    PenOccupanciesCompanion Function({
      Value<int> id,
      Value<String> uid,
      Value<Instant> createdAt,
      Value<Instant> updatedAt,
      Value<bool> struck,
      Value<Instant?> struckAt,
      Value<int> pen,
      Value<int> season,
      Value<int?> ewe,
      Value<Instant> enteredAt,
      Value<Instant> capturedAt,
      Value<Instant?> originalEffective,
      Value<String> timeSource,
      Value<Instant?> exitedAt,
      Value<String?> exitReason,
    });

final class $$PenOccupanciesTableReferences
    extends BaseReferences<_$AppDatabase, $PenOccupanciesTable, PenOccupancy> {
  $$PenOccupanciesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PensTable _penTable(_$AppDatabase db) =>
      db.pens.createAlias('pen_occupancies__pen__pens__id');

  $$PensTableProcessedTableManager get pen {
    final $_column = $_itemColumn<int>('pen')!;

    final manager = $$PensTableTableManager(
      $_db,
      $_db.pens,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_penTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static $SeasonsTable _seasonTable(_$AppDatabase db) =>
      db.seasons.createAlias('pen_occupancies__season__seasons__id');

  $$SeasonsTableProcessedTableManager get season {
    final $_column = $_itemColumn<int>('season')!;

    final manager = $$SeasonsTableTableManager(
      $_db,
      $_db.seasons,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_seasonTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static $EwesTable _eweTable(_$AppDatabase db) =>
      db.ewes.createAlias('pen_occupancies__ewe__ewes__id');

  $$EwesTableProcessedTableManager? get ewe {
    final $_column = $_itemColumn<int>('ewe');
    if ($_column == null) return null;
    final manager = $$EwesTableTableManager(
      $_db,
      $_db.ewes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_eweTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$PenOccupancyLambsTable, List<PenOccupancyLamb>>
  _penOccupancyLambsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.penOccupancyLambs,
    aliasName: 'pen_occupancies__id__pen_occupancy_lambs__occupancy',
  );

  $$PenOccupancyLambsTableProcessedTableManager get penOccupancyLambsRefs {
    final manager = $$PenOccupancyLambsTableTableManager(
      $_db,
      $_db.penOccupancyLambs,
    ).filter((f) => f.occupancy.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_penOccupancyLambsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$PenOccupanciesTableFilterComposer extends Composer<_$AppDatabase, $PenOccupanciesTable> {
  $$PenOccupanciesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<Instant, Instant, int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<Instant, Instant, int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<bool> get struck =>
      $composableBuilder(column: $table.struck, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<Instant?, Instant, int> get struckAt => $composableBuilder(
    column: $table.struckAt,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<Instant, Instant, int> get enteredAt => $composableBuilder(
    column: $table.enteredAt,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<Instant, Instant, int> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<Instant?, Instant, int> get originalEffective =>
      $composableBuilder(
        column: $table.originalEffective,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get timeSource =>
      $composableBuilder(column: $table.timeSource, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<Instant?, Instant, int> get exitedAt => $composableBuilder(
    column: $table.exitedAt,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get exitReason =>
      $composableBuilder(column: $table.exitReason, builder: (column) => ColumnFilters(column));

  $$PensTableFilterComposer get pen {
    final $$PensTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pen,
      referencedTable: $db.pens,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$PensTableFilterComposer(
            $db: $db,
            $table: $db.pens,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SeasonsTableFilterComposer get season {
    final $$SeasonsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.season,
      referencedTable: $db.seasons,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$SeasonsTableFilterComposer(
            $db: $db,
            $table: $db.seasons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EwesTableFilterComposer get ewe {
    final $$EwesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ewe,
      referencedTable: $db.ewes,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$EwesTableFilterComposer(
            $db: $db,
            $table: $db.ewes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> penOccupancyLambsRefs(
    Expression<bool> Function($$PenOccupancyLambsTableFilterComposer f) f,
  ) {
    final $$PenOccupancyLambsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.penOccupancyLambs,
      getReferencedColumn: (t) => t.occupancy,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$PenOccupancyLambsTableFilterComposer(
            $db: $db,
            $table: $db.penOccupancyLambs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PenOccupanciesTableOrderingComposer extends Composer<_$AppDatabase, $PenOccupanciesTable> {
  $$PenOccupanciesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get struck =>
      $composableBuilder(column: $table.struck, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get struckAt =>
      $composableBuilder(column: $table.struckAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get enteredAt =>
      $composableBuilder(column: $table.enteredAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get capturedAt =>
      $composableBuilder(column: $table.capturedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get originalEffective => $composableBuilder(
    column: $table.originalEffective,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timeSource =>
      $composableBuilder(column: $table.timeSource, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get exitedAt =>
      $composableBuilder(column: $table.exitedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get exitReason =>
      $composableBuilder(column: $table.exitReason, builder: (column) => ColumnOrderings(column));

  $$PensTableOrderingComposer get pen {
    final $$PensTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pen,
      referencedTable: $db.pens,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$PensTableOrderingComposer(
            $db: $db,
            $table: $db.pens,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SeasonsTableOrderingComposer get season {
    final $$SeasonsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.season,
      referencedTable: $db.seasons,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$SeasonsTableOrderingComposer(
            $db: $db,
            $table: $db.seasons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EwesTableOrderingComposer get ewe {
    final $$EwesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ewe,
      referencedTable: $db.ewes,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$EwesTableOrderingComposer(
            $db: $db,
            $table: $db.ewes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PenOccupanciesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PenOccupanciesTable> {
  $$PenOccupanciesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Instant, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Instant, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get struck =>
      $composableBuilder(column: $table.struck, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Instant?, int> get struckAt =>
      $composableBuilder(column: $table.struckAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Instant, int> get enteredAt =>
      $composableBuilder(column: $table.enteredAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Instant, int> get capturedAt =>
      $composableBuilder(column: $table.capturedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Instant?, int> get originalEffective =>
      $composableBuilder(column: $table.originalEffective, builder: (column) => column);

  GeneratedColumn<String> get timeSource =>
      $composableBuilder(column: $table.timeSource, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Instant?, int> get exitedAt =>
      $composableBuilder(column: $table.exitedAt, builder: (column) => column);

  GeneratedColumn<String> get exitReason =>
      $composableBuilder(column: $table.exitReason, builder: (column) => column);

  $$PensTableAnnotationComposer get pen {
    final $$PensTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pen,
      referencedTable: $db.pens,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$PensTableAnnotationComposer(
            $db: $db,
            $table: $db.pens,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SeasonsTableAnnotationComposer get season {
    final $$SeasonsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.season,
      referencedTable: $db.seasons,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$SeasonsTableAnnotationComposer(
            $db: $db,
            $table: $db.seasons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EwesTableAnnotationComposer get ewe {
    final $$EwesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ewe,
      referencedTable: $db.ewes,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$EwesTableAnnotationComposer(
            $db: $db,
            $table: $db.ewes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> penOccupancyLambsRefs<T extends Object>(
    Expression<T> Function($$PenOccupancyLambsTableAnnotationComposer a) f,
  ) {
    final $$PenOccupancyLambsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.penOccupancyLambs,
      getReferencedColumn: (t) => t.occupancy,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$PenOccupancyLambsTableAnnotationComposer(
            $db: $db,
            $table: $db.penOccupancyLambs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PenOccupanciesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PenOccupanciesTable,
          PenOccupancy,
          $$PenOccupanciesTableFilterComposer,
          $$PenOccupanciesTableOrderingComposer,
          $$PenOccupanciesTableAnnotationComposer,
          $$PenOccupanciesTableCreateCompanionBuilder,
          $$PenOccupanciesTableUpdateCompanionBuilder,
          (PenOccupancy, $$PenOccupanciesTableReferences),
          PenOccupancy,
          PrefetchHooks Function({bool pen, bool season, bool ewe, bool penOccupancyLambsRefs})
        > {
  $$PenOccupanciesTableTableManager(_$AppDatabase db, $PenOccupanciesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PenOccupanciesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PenOccupanciesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PenOccupanciesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uid = const Value.absent(),
                Value<Instant> createdAt = const Value.absent(),
                Value<Instant> updatedAt = const Value.absent(),
                Value<bool> struck = const Value.absent(),
                Value<Instant?> struckAt = const Value.absent(),
                Value<int> pen = const Value.absent(),
                Value<int> season = const Value.absent(),
                Value<int?> ewe = const Value.absent(),
                Value<Instant> enteredAt = const Value.absent(),
                Value<Instant> capturedAt = const Value.absent(),
                Value<Instant?> originalEffective = const Value.absent(),
                Value<String> timeSource = const Value.absent(),
                Value<Instant?> exitedAt = const Value.absent(),
                Value<String?> exitReason = const Value.absent(),
              }) => PenOccupanciesCompanion(
                id: id,
                uid: uid,
                createdAt: createdAt,
                updatedAt: updatedAt,
                struck: struck,
                struckAt: struckAt,
                pen: pen,
                season: season,
                ewe: ewe,
                enteredAt: enteredAt,
                capturedAt: capturedAt,
                originalEffective: originalEffective,
                timeSource: timeSource,
                exitedAt: exitedAt,
                exitReason: exitReason,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String uid,
                required Instant createdAt,
                required Instant updatedAt,
                Value<bool> struck = const Value.absent(),
                Value<Instant?> struckAt = const Value.absent(),
                required int pen,
                required int season,
                Value<int?> ewe = const Value.absent(),
                required Instant enteredAt,
                required Instant capturedAt,
                Value<Instant?> originalEffective = const Value.absent(),
                Value<String> timeSource = const Value.absent(),
                Value<Instant?> exitedAt = const Value.absent(),
                Value<String?> exitReason = const Value.absent(),
              }) => PenOccupanciesCompanion.insert(
                id: id,
                uid: uid,
                createdAt: createdAt,
                updatedAt: updatedAt,
                struck: struck,
                struckAt: struckAt,
                pen: pen,
                season: season,
                ewe: ewe,
                enteredAt: enteredAt,
                capturedAt: capturedAt,
                originalEffective: originalEffective,
                timeSource: timeSource,
                exitedAt: exitedAt,
                exitReason: exitReason,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), $$PenOccupanciesTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback:
              ({pen = false, season = false, ewe = false, penOccupancyLambsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [if (penOccupancyLambsRefs) db.penOccupancyLambs],
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
                        if (pen) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.pen,
                                    referencedTable: $$PenOccupanciesTableReferences._penTable(db),
                                    referencedColumn: $$PenOccupanciesTableReferences
                                        ._penTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (season) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.season,
                                    referencedTable: $$PenOccupanciesTableReferences._seasonTable(
                                      db,
                                    ),
                                    referencedColumn: $$PenOccupanciesTableReferences
                                        ._seasonTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (ewe) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.ewe,
                                    referencedTable: $$PenOccupanciesTableReferences._eweTable(db),
                                    referencedColumn: $$PenOccupanciesTableReferences
                                        ._eweTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (penOccupancyLambsRefs)
                        await $_getPrefetchedData<
                          PenOccupancy,
                          $PenOccupanciesTable,
                          PenOccupancyLamb
                        >(
                          currentTable: table,
                          referencedTable: $$PenOccupanciesTableReferences
                              ._penOccupancyLambsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PenOccupanciesTableReferences(db, table, p0).penOccupancyLambsRefs,
                          referencedItemsForCurrentItem: (item, referencedItems) =>
                              referencedItems.where((e) => e.occupancy == item.id),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$PenOccupanciesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PenOccupanciesTable,
      PenOccupancy,
      $$PenOccupanciesTableFilterComposer,
      $$PenOccupanciesTableOrderingComposer,
      $$PenOccupanciesTableAnnotationComposer,
      $$PenOccupanciesTableCreateCompanionBuilder,
      $$PenOccupanciesTableUpdateCompanionBuilder,
      (PenOccupancy, $$PenOccupanciesTableReferences),
      PenOccupancy,
      PrefetchHooks Function({bool pen, bool season, bool ewe, bool penOccupancyLambsRefs})
    >;
typedef $$PenOccupancyLambsTableCreateCompanionBuilder =
    PenOccupancyLambsCompanion Function({
      required int occupancy,
      required int lamb,
      Value<int> rowid,
    });
typedef $$PenOccupancyLambsTableUpdateCompanionBuilder =
    PenOccupancyLambsCompanion Function({Value<int> occupancy, Value<int> lamb, Value<int> rowid});

final class $$PenOccupancyLambsTableReferences
    extends BaseReferences<_$AppDatabase, $PenOccupancyLambsTable, PenOccupancyLamb> {
  $$PenOccupancyLambsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PenOccupanciesTable _occupancyTable(_$AppDatabase db) =>
      db.penOccupancies.createAlias('pen_occupancy_lambs__occupancy__pen_occupancies__id');

  $$PenOccupanciesTableProcessedTableManager get occupancy {
    final $_column = $_itemColumn<int>('occupancy')!;

    final manager = $$PenOccupanciesTableTableManager(
      $_db,
      $_db.penOccupancies,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_occupancyTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static $LambsTable _lambTable(_$AppDatabase db) =>
      db.lambs.createAlias('pen_occupancy_lambs__lamb__lambs__id');

  $$LambsTableProcessedTableManager get lamb {
    final $_column = $_itemColumn<int>('lamb')!;

    final manager = $$LambsTableTableManager(
      $_db,
      $_db.lambs,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_lambTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$PenOccupancyLambsTableFilterComposer
    extends Composer<_$AppDatabase, $PenOccupancyLambsTable> {
  $$PenOccupancyLambsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$PenOccupanciesTableFilterComposer get occupancy {
    final $$PenOccupanciesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.occupancy,
      referencedTable: $db.penOccupancies,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$PenOccupanciesTableFilterComposer(
            $db: $db,
            $table: $db.penOccupancies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LambsTableFilterComposer get lamb {
    final $$LambsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lamb,
      referencedTable: $db.lambs,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$LambsTableFilterComposer(
            $db: $db,
            $table: $db.lambs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PenOccupancyLambsTableOrderingComposer
    extends Composer<_$AppDatabase, $PenOccupancyLambsTable> {
  $$PenOccupancyLambsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$PenOccupanciesTableOrderingComposer get occupancy {
    final $$PenOccupanciesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.occupancy,
      referencedTable: $db.penOccupancies,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$PenOccupanciesTableOrderingComposer(
            $db: $db,
            $table: $db.penOccupancies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LambsTableOrderingComposer get lamb {
    final $$LambsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lamb,
      referencedTable: $db.lambs,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$LambsTableOrderingComposer(
            $db: $db,
            $table: $db.lambs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PenOccupancyLambsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PenOccupancyLambsTable> {
  $$PenOccupancyLambsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$PenOccupanciesTableAnnotationComposer get occupancy {
    final $$PenOccupanciesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.occupancy,
      referencedTable: $db.penOccupancies,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$PenOccupanciesTableAnnotationComposer(
            $db: $db,
            $table: $db.penOccupancies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LambsTableAnnotationComposer get lamb {
    final $$LambsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lamb,
      referencedTable: $db.lambs,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$LambsTableAnnotationComposer(
            $db: $db,
            $table: $db.lambs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PenOccupancyLambsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PenOccupancyLambsTable,
          PenOccupancyLamb,
          $$PenOccupancyLambsTableFilterComposer,
          $$PenOccupancyLambsTableOrderingComposer,
          $$PenOccupancyLambsTableAnnotationComposer,
          $$PenOccupancyLambsTableCreateCompanionBuilder,
          $$PenOccupancyLambsTableUpdateCompanionBuilder,
          (PenOccupancyLamb, $$PenOccupancyLambsTableReferences),
          PenOccupancyLamb,
          PrefetchHooks Function({bool occupancy, bool lamb})
        > {
  $$PenOccupancyLambsTableTableManager(_$AppDatabase db, $PenOccupancyLambsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PenOccupancyLambsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PenOccupancyLambsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PenOccupancyLambsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> occupancy = const Value.absent(),
                Value<int> lamb = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PenOccupancyLambsCompanion(occupancy: occupancy, lamb: lamb, rowid: rowid),
          createCompanionCallback:
              ({
                required int occupancy,
                required int lamb,
                Value<int> rowid = const Value.absent(),
              }) =>
                  PenOccupancyLambsCompanion.insert(occupancy: occupancy, lamb: lamb, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), $$PenOccupancyLambsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({occupancy = false, lamb = false}) {
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
                    if (occupancy) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.occupancy,
                                referencedTable: $$PenOccupancyLambsTableReferences._occupancyTable(
                                  db,
                                ),
                                referencedColumn: $$PenOccupancyLambsTableReferences
                                    ._occupancyTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (lamb) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.lamb,
                                referencedTable: $$PenOccupancyLambsTableReferences._lambTable(db),
                                referencedColumn: $$PenOccupancyLambsTableReferences
                                    ._lambTable(db)
                                    .id,
                              )
                              as T;
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

typedef $$PenOccupancyLambsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PenOccupancyLambsTable,
      PenOccupancyLamb,
      $$PenOccupancyLambsTableFilterComposer,
      $$PenOccupancyLambsTableOrderingComposer,
      $$PenOccupancyLambsTableAnnotationComposer,
      $$PenOccupancyLambsTableCreateCompanionBuilder,
      $$PenOccupancyLambsTableUpdateCompanionBuilder,
      (PenOccupancyLamb, $$PenOccupancyLambsTableReferences),
      PenOccupancyLamb,
      PrefetchHooks Function({bool occupancy, bool lamb})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SeasonsTableTableManager get seasons => $$SeasonsTableTableManager(_db, _db.seasons);
  $$EwesTableTableManager get ewes => $$EwesTableTableManager(_db, _db.ewes);
  $$LambingsTableTableManager get lambings => $$LambingsTableTableManager(_db, _db.lambings);
  $$LambsTableTableManager get lambs => $$LambsTableTableManager(_db, _db.lambs);
  $$EweSeasonsTableTableManager get eweSeasons =>
      $$EweSeasonsTableTableManager(_db, _db.eweSeasons);
  $$EweTouchesTableTableManager get eweTouches =>
      $$EweTouchesTableTableManager(_db, _db.eweTouches);
  $$EweObservationsTableTableManager get eweObservations =>
      $$EweObservationsTableTableManager(_db, _db.eweObservations);
  $$TreatmentsTableTableManager get treatments =>
      $$TreatmentsTableTableManager(_db, _db.treatments);
  $$TreatmentWithdrawalsTableTableManager get treatmentWithdrawals =>
      $$TreatmentWithdrawalsTableTableManager(_db, _db.treatmentWithdrawals);
  $$PensTableTableManager get pens => $$PensTableTableManager(_db, _db.pens);
  $$PenOccupanciesTableTableManager get penOccupancies =>
      $$PenOccupanciesTableTableManager(_db, _db.penOccupancies);
  $$PenOccupancyLambsTableTableManager get penOccupancyLambs =>
      $$PenOccupancyLambsTableTableManager(_db, _db.penOccupancyLambs);
}
