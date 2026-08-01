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

  /// **Forward reference, deferred to N07-T04.** `Lambings` does not exist yet.
  /// The column and its index land now — an index needs no parent table — and
  /// `.references(Lambings, #id, onDelete: KeyAction.setNull)` is added when the
  /// parent exists. Nothing is frozen until T08, so editing this in T04 is free.
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
  late final $EweSeasonsTable eweSeasons = $EweSeasonsTable(this);
  late final $EweTouchesTable eweTouches = $EweTouchesTable(this);
  late final $EweObservationsTable eweObservations = $EweObservationsTable(this);
  late final Index idxSeasonStart = Index(
    'idx_season_start',
    'CREATE INDEX idx_season_start ON seasons (start_date)',
  );
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
    eweSeasons,
    eweTouches,
    eweObservations,
    idxSeasonStart,
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
          PrefetchHooks Function({bool eweSeasonsRefs, bool eweObservationsRefs})
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
          prefetchHooksCallback: ({eweSeasonsRefs = false, eweObservationsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (eweSeasonsRefs) db.eweSeasons,
                if (eweObservationsRefs) db.eweObservations,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
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
      PrefetchHooks Function({bool eweSeasonsRefs, bool eweObservationsRefs})
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
              ({eweSeasonsRefs = false, eweTouchesRefs = false, eweObservationsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (eweSeasonsRefs) db.eweSeasons,
                    if (eweTouchesRefs) db.eweTouches,
                    if (eweObservationsRefs) db.eweObservations,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
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
      PrefetchHooks Function({bool eweSeasonsRefs, bool eweTouchesRefs, bool eweObservationsRefs})
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

  ColumnFilters<int> get lambing =>
      $composableBuilder(column: $table.lambing, builder: (column) => ColumnFilters(column));

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

  ColumnOrderings<int> get lambing =>
      $composableBuilder(column: $table.lambing, builder: (column) => ColumnOrderings(column));

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

  GeneratedColumn<int> get lambing =>
      $composableBuilder(column: $table.lambing, builder: (column) => column);

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
          PrefetchHooks Function({bool ewe, bool season})
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
          prefetchHooksCallback: ({ewe = false, season = false}) {
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
      PrefetchHooks Function({bool ewe, bool season})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SeasonsTableTableManager get seasons => $$SeasonsTableTableManager(_db, _db.seasons);
  $$EwesTableTableManager get ewes => $$EwesTableTableManager(_db, _db.ewes);
  $$EweSeasonsTableTableManager get eweSeasons =>
      $$EweSeasonsTableTableManager(_db, _db.eweSeasons);
  $$EweTouchesTableTableManager get eweTouches =>
      $$EweTouchesTableTableManager(_db, _db.eweTouches);
  $$EweObservationsTableTableManager get eweObservations =>
      $$EweObservationsTableTableManager(_db, _db.eweObservations);
}
