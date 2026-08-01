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
          PrefetchHooks Function({bool lambingsRefs, bool eweSeasonsRefs, bool eweObservationsRefs})
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
              ({lambingsRefs = false, eweSeasonsRefs = false, eweObservationsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (lambingsRefs) db.lambings,
                    if (eweSeasonsRefs) db.eweSeasons,
                    if (eweObservationsRefs) db.eweObservations,
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
      PrefetchHooks Function({bool lambingsRefs, bool eweSeasonsRefs, bool eweObservationsRefs})
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
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (lambingsRefs) db.lambings,
                    if (eweSeasonsRefs) db.eweSeasons,
                    if (eweTouchesRefs) db.eweTouches,
                    if (eweObservationsRefs) db.eweObservations,
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
          PrefetchHooks Function({bool lambing, bool birthDam, bool becameEwe})
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
          prefetchHooksCallback: ({lambing = false, birthDam = false, becameEwe = false}) {
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
                return [];
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
      PrefetchHooks Function({bool lambing, bool birthDam, bool becameEwe})
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
}
