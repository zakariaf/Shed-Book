// lib/data/lambing_repository.dart
//
// beginLambing and nothing else. addLamb, setEase, addCare, removeCare and
// correctOccurredAt are N16's and N17's.
//
// `setBirthType` IS IN CONVENTIONS §2.13 AND IS NOT BUILT HERE. P8 abolished the
// birth-type chooser: birth type is DERIVED from the tally strokes and labelled
// (COUNTED). The column still has a writer — the deferred CHANGE TYPE path in
// N16 — but nothing on the five-tap path ever declares one.
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/core/db/uid.dart';
import 'package:shed_book/core/time/app_clock.dart';
import 'package:shed_book/core/write_outcome.dart';
import 'package:shed_book/data/failure_mapping.dart';
import 'package:shed_book/data/recorded_time_columns.dart';
import 'package:shed_book/domain/birth_type.dart';
import 'package:shed_book/domain/care_kind.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/domain/lambing_ease.dart';
import 'package:shed_book/domain/sex.dart';
import 'package:shed_book/domain/stats/season_counts.dart';
import 'package:shed_book/domain/units/grams.dart';
import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/domain/time/local_date.dart';
import 'package:shed_book/domain/time/recorded_time.dart';

final class LambingRepository {
  /// `db:` is the name `CONVENTIONS §2.13` prints. The initializing-formal lint
  /// is suppressed rather than obeyed for the same reason as in
  /// `FlockRepository`: `this._db` would make the PUBLIC parameter name `_db`,
  /// so every caller would be writing a private name.
  // ignore_for_file: prefer_initializing_formals
  LambingRepository({required AppDatabase db}) : _db = db;

  final AppDatabase _db;

  /// Called by the Quick Entry "Lambing" tap, **before Lambing Entry is
  /// pushed**. The row exists from this moment; there is no draft and nothing to
  /// lose if the phone dies.
  ///
  /// **Returns the id and THROWS** (R32 — this and `addLamb` are the only two
  /// verbs in the app that do). There is no id to hand back on failure and the
  /// screen cannot open, so the global error net (`01 §5.5`) is the right
  /// handler. Never gated by the free tier, at any entitlement state.
  Future<LambingId> beginLambing(EweId ewe) {
    final Instant now = appNow(); // ONE instant per mutation
    final RecordedTime when = RecordedTime.capture(now); // spec §12.5 provenance

    return _db.transaction(() async {
      final SeasonId season = await _currentSeason();

      final int id = await _db
          .into(_db.lambings)
          .insert(
            LambingsCompanion.insert(
              uid: newUid(), // export identity — #32, R15
              createdAt: now,
              updatedAt: now,
              ewe: ewe.value,
              season: season.value,
              // THREE TIME COLUMNS, THREE MEANINGS, ONE `now`. occurred_at is
              // when the thing happened; captured_at is when we wrote it down;
              // local_date is the shepherd's civil day, derived in DART because
              // SQLite cannot bucket by a local civil day without a tz database.
              // A local_date read from a second clock is how the lambing-spread
              // histogram acquires a one-row-off bug nobody sees until the
              // season summary.
              occurredAt: when.effective,
              capturedAt: when.capturedAt,
              // The FROZEN WIRE KEY, never the enum's `name` and never
              // localised: the CHECK is time_source IN ('auto','entered','edited').
              timeSource: Value<String>(when.source.key),
              localDate: LocalDate.of(when.effective),
              // `absent`, NOT `Value(null)`, and the difference is the whole
              // reason R6 exists: absent omits the column so SQLite applies its
              // own rules, while Value(null) writes an explicit NULL. Both land
              // on NULL here — but with Value(null) the next reviewer cannot
              // tell whether the column is nullable by design or by accident.
              declaredBirthType: const Value<int?>.absent(),
            ),
          );

      // ewe_touches is keyed on `ewe`, one row per ewe: upsert, never insert.
      await _db
          .into(_db.eweTouches)
          .insertOnConflictUpdate(
            EweTouchesCompanion.insert(ewe: Value<int>(ewe.value), touchedAt: now),
          );

      // N24-T04 writes the colostrum and navel reminder ROWS here, inside this
      // same transaction (decision #63). The OS projection is reconciled AFTER
      // the transaction returns, never inside it — a platform channel round
      // trips through another isolate while holding the write lock.

      return LambingId(id);
    });
  }

  /// Adds one lamb to [lambing].
  ///
  /// **Returns an id and THROWS** — one of only two verbs that do (R32), the
  /// other being `beginLambing`. There is no id to hand back on failure and the
  /// caller has nowhere to put a `WriteOutcome`.
  ///
  /// **`{Sex? sex}`, not `{required Sex sex}`.** A stroke is one press: the
  /// shepherd counts the lamb now and sexes it later, or never. Making sex
  /// required would put a decision between the thumb and the record, which is
  /// exactly what the five-tap budget exists to prevent — and NULL is not
  /// `Sex.unknown` (R45), so the column keeps "not recorded" distinguishable
  /// from "recorded as unknown".
  ///
  /// `birth_dam` is denormalised from `lambings.ewe` in the same transaction. It
  /// is not redundancy: a lamb's birth dam never changes, while a FOSTER moves
  /// the rearing dam — and reading the birth dam through the lambing would make
  /// a foster look like a rewrite of history.
  /// Scores the assistance the shepherd gave, 1–5.
  ///
  /// **NON-NULLABLE, AND THERE IS NO CLEAR AFFORDANCE.** A mis-tap is corrected
  /// FORWARD by tapping the right value — `07 §15.1` gives this verb no undo,
  /// and the two values are never both present because one `UPDATE` replaces the
  /// other. A sixth "not scored" button would put a chooser on the screen for
  /// the ABSENCE of a value, when `NULL` is already how absence is stored. If
  /// clearing turns out to be needed it is a screens decision, not a local one.
  ///
  /// **A blank ease is NOT `1`** (decision #59). `lambings.ease` is nullable
  /// with no default; `05 §6.7`'s assisted rate excludes an unscored lambing
  /// from BOTH the numerator and the denominator, so inferring "1 —
  /// unassisted" would inflate the unassisted count and deflate the rate,
  /// invisibly, for years.
  ///
  /// **`updated_at` MOVES AND NOTHING ELSE DOES.** The companion names two
  /// columns on purpose: a `copyWith` that rewrote the provenance quad on an
  /// unrelated edit is the kind of defect that only surfaces in an export months
  /// later, and §12.5 is what it would break.
  Future<WriteOutcome> setEase(LambingId id, LambingEase ease) async {
    try {
      final Instant now = appNow(); // ONE instant per mutation
      final int rows =
          await (_db.update(
            _db.lambings,
          )..where(($LambingsTable t) => t.id.equals(id.value))).write(
            LambingsCompanion(ease: Value<int?>(ease.code), updatedAt: Value<Instant>(now)),
          );
      // R53 — the default empty `warnings`. There is nothing to warn about: the
      // ordinal was validated into existence by `LambingEase` and the row either
      // exists or it does not.
      return WriteCommitted(insertedId: rows > 0 ? id.value : null);
    } on Object catch (e) {
      return WriteFailed(shedFailureFrom(e));
    }
  }

  /// Who else was there. Free text, **never a picker and never a list of
  /// names** — the app has no people table and inventing one would be asking a
  /// shepherd to maintain a contacts list at 03:20.
  Future<WriteOutcome> setAssistedBy(LambingId id, String? value) => _setOneColumn(
    id,
    (Instant now) => LambingsCompanion(
      assistedBy: Value<String?>(_blankToNull(value)),
      updatedAt: Value<Instant>(now),
    ),
  );

  /// The malpresentation, as a `vocab_terms.key`.
  ///
  /// **An FK with `ON DELETE RESTRICT`**, so a term in use cannot be deleted —
  /// removal sets `hidden_at` instead. Two consequences the picker honours: a
  /// hidden term is not OFFERED, and a lambing that already references one still
  /// RENDERS ITS LABEL. Filtering hidden terms out of the label lookup as well
  /// as out of the list is how an existing record starts printing a raw key.
  Future<WriteOutcome> setPresentation(LambingId id, String? vocabKey) => _setOneColumn(
    id,
    (Instant now) => LambingsCompanion(
      presentation: Value<String?>(_blankToNull(vocabKey)),
      updatedAt: Value<Instant>(now),
    ),
  );

  /// Free text beside the presentation.
  ///
  /// **THIS IS WHERE `lubricant / ropes / vet` LIVES**, and it is free text
  /// because the frozen schema has no column for it. Spec §7.2 lists it under
  /// assistance detail; `03 §5.4` ships four columns and the schema froze at
  /// N07-T08. A structured version is a v2 migration, not a widget — the ARB
  /// description and the field label both say so, so the next reader does not go
  /// looking for a column or propose one.
  Future<WriteOutcome> setPresentationNote(LambingId id, String? value) => _setOneColumn(
    id,
    (Instant now) => LambingsCompanion(
      presentationNote: Value<String?>(_blankToNull(value)),
      updatedAt: Value<Instant>(now),
    ),
  );

  /// The lambing's own note. Distinct from a `notes` row, which is the
  /// attachment-bearing kind `NoteRepository` owns.
  Future<WriteOutcome> setNote(LambingId id, String? value) => _setOneColumn(
    id,
    (Instant now) => LambingsCompanion(
      note: Value<String?>(_blankToNull(value)),
      updatedAt: Value<Instant>(now),
    ),
  );

  /// **FOUR NARROW VERBS SHARE THIS, AND THERE IS NO `updateDetail(...)`.**
  ///
  /// Each caller builds a companion naming ONE column plus `updated_at`, so drift
  /// writes exactly those two. A wide write — one verb taking four nullable
  /// parameters — is how a second edit clobbers the first: two fields edited in
  /// the same second and the later write carries the earlier field's stale
  /// value back over the top of it.
  ///
  /// The shared helper is the transaction and the instant, which is the part
  /// that must not vary. What each verb writes is the part that must.
  Future<WriteOutcome> _setOneColumn(
    LambingId id,
    LambingsCompanion Function(Instant now) build,
  ) async {
    try {
      final Instant now = appNow(); // ONE instant per mutation
      final int rows = await (_db.update(
        _db.lambings,
      )..where(($LambingsTable t) => t.id.equals(id.value))).write(build(now));
      return WriteCommitted(insertedId: rows > 0 ? id.value : null);
    } on Object catch (e) {
      return WriteFailed(shedFailureFrom(e));
    }
  }

  /// An empty field is **not recorded**, which is a different fact from an empty
  /// string and stores as NULL (R45 again, one tier down). A shepherd who clears
  /// a note has unrecorded it; they have not recorded a blank one.
  ///
  /// Trimmed, because trailing whitespace from a keyboard is not content — and
  /// this is the one transformation permitted here. It removes nothing the
  /// shepherd meant.
  static String? _blankToNull(String? v) {
    final String? trimmed = v?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  /// Whether the lamb is on the bottle.
  ///
  /// **CLEARING IT DOES NOT ZERO THE COUNT**, and that is a choice rather than a
  /// constraint — unlike the death columns there is no `CHECK` forcing them to
  /// move together. The instinct is to tidy: if she is no longer a pet lamb the
  /// feeds are meaningless. They are not. *Which lambs cost them six weeks of
  /// bottles* is exactly the April question, and a lamb weaned off the bottle is
  /// still a lamb that was on it.
  Future<WriteOutcome> setPetLamb(LambId lamb, {required bool petLamb}) => _setOneLambColumn(
    lamb,
    (Instant now) => LambsCompanion(petLamb: Value<bool>(petLamb), updatedAt: Value<Instant>(now)),
  );

  /// One more bottle feed.
  ///
  /// **`bottle_feeds = bottle_feeds + 1` IN SQL, NOT READ-MODIFY-WRITE IN
  /// DART.** Two taps a frame apart both reading 3 and both writing 4 loses a
  /// feed silently — and silently is the whole problem, because a lost feed
  /// looks exactly like a feed that was never given.
  ///
  /// `guard()` refuses a CONCURRENT call, which is the double-tap defence, but it
  /// does not serialise two deliberate taps two seconds apart and it is not the
  /// mechanism for this. The increment has to be atomic in the statement.
  ///
  /// **NO PER-FEED ROW IS WRITTEN, AND THE DIVERGENCE IS DELIBERATE.**
  /// `indelible.md §8` screen 5 asks for a timestamped `FEED 4 — 06:40` line in
  /// the stream; there is no table that can hold one. `care_events.kind` is a
  /// CLOSED `CHECK` and a fifth value is a schema migration AND a notification
  /// channel decision (#65) — the schema froze at N07-T08. Printing that line
  /// from a counter would invent a timestamp the record does not have, which is
  /// precision inflation: the same §12.4 failure as claiming an hour for a civil
  /// death date.
  /// **THROUGH `update(...).write(...)`, NOT A RAW STATEMENT**, and the gate
  /// ruled that too. A raw statement bypasses drift's stream tracking, so the
  /// card would keep showing the old count until the shepherd navigated away and
  /// back — the increment would be correct in the database and invisible on
  /// screen, which is the worst of both. `RawValuesInsertable` carries the
  /// EXPRESSION through the typed update, so the table is still tracked.
  Future<WriteOutcome> addBottleFeed(LambId lamb) async {
    try {
      final Instant now = appNow();
      final int rows =
          await (_db.update(_db.lambs)..where(($LambsTable t) => t.id.equals(lamb.value))).write(
            RawValuesInsertable<Lamb>(<String, Expression<Object>>{
              'bottle_feeds': _db.lambs.bottleFeeds + const Constant<int>(1),
              'updated_at': Variable<int>(now.epochMillis),
            }),
          );
      return WriteCommitted(insertedId: rows > 0 ? lamb.value : null);
    } on Object catch (e) {
      return WriteFailed(shedFailureFrom(e));
    }
  }

  /// Records a lamb's death — **status, date and cause in one transaction**.
  ///
  /// One `_db.transaction()` and not three writes, because the schema's `CHECK`s
  /// make the three a single atomic move: a row that is `dead` with no date, or
  /// carries a date while `alive`, is a state the database refuses. Three
  /// separate writes would each have to pass through an invalid intermediate.
  ///
  /// **THE CAUSE MAY BE NULL AND THAT IS *UNATTRIBUTED*** — not `dc_unknown`,
  /// which is a term the shepherd can pick. The vocabulary keeps those two apart
  /// and so does this parameter: a lamb died and nobody wrote down why is a
  /// different fact from a lamb died and the shepherd recorded that the cause was
  /// unknown.
  ///
  /// **NO WARNING IS PRODUCED HERE** (R53). `deathBeforeBirth` is the
  /// controller's to raise; this layer cannot reach a validator at all, and the
  /// `WriteCommitted` it returns carries the default empty list.
  Future<WriteOutcome> recordDeath(
    LambId lamb, {
    required LambStatus status,
    required LocalDate? deathDate,
    String? causeKey,
  }) async {
    try {
      final Instant now = appNow(); // ONE instant per mutation

      return await _db.transaction(() async {
        await (_db.update(_db.lambs)..where(($LambsTable t) => t.id.equals(lamb.value))).write(
          LambsCompanion(
            status: Value<String>(status.key),
            deathDate: Value<LocalDate?>(deathDate),
            deathCause: Value<String?>(causeKey),
            updatedAt: Value<Instant>(now),
          ),
        );
        return WriteCommitted(insertedId: lamb.value);
      });
    } on Object catch (e) {
      return WriteFailed(shedFailureFrom(e));
    }
  }

  /// Back to alive, **and the date and cause go with it**.
  ///
  /// Leaving a death date on a living lamb is the state the `CHECK` refuses, and
  /// it is also the state a shepherd would never mean: undoing a death that was
  /// recorded by mistake means the lamb is alive, not that it is alive and died
  /// on Tuesday.
  Future<WriteOutcome> clearDeath(LambId lamb) async {
    try {
      final Instant now = appNow();

      return await _db.transaction(() async {
        await (_db.update(_db.lambs)..where(($LambsTable t) => t.id.equals(lamb.value))).write(
          LambsCompanion(
            status: Value<String>(LambStatus.alive.key),
            deathDate: const Value<LocalDate?>(null),
            deathCause: const Value<String?>(null),
            updatedAt: Value<Instant>(now),
          ),
        );
        return WriteCommitted(insertedId: lamb.value);
      });
    } on Object catch (e) {
      return WriteFailed(shedFailureFrom(e));
    }
  }

  /// **`null` IS *NOT RECORDED*; `Sex.unknown` IS *THE SHEPHERD LOOKED AND
  /// COULD NOT TELL*.** R45: two different facts, and neither is the other's
  /// default. The parameter is nullable so the second is expressible and the
  /// first is reachable — a non-nullable signature would make un-recording a sex
  /// impossible, which is the app refusing to accept a correction.
  Future<WriteOutcome> setLambSex(LambId lamb, Sex? sex) => _setOneLambColumn(
    lamb,
    (Instant now) => LambsCompanion(sex: Value<String?>(sex?.key), updatedAt: Value<Instant>(now)),
  );

  /// The birthweight, in **canonical grams** (#42).
  ///
  /// `WeightUnit` is a DISPLAY choice from `unitsProvider` (R68) and conversion
  /// happens at the widget boundary; this column never learns which unit was
  /// typed. A shepherd who switches to lb must see the same lambs at the same
  /// weights, and storing the typed unit is how that stops being true.
  ///
  /// **NOT VALIDATED HERE.** `05 §6`'s implausible-birthweight band is a
  /// `Warning`, never a block — a blocked write produces a lost record, which is
  /// worse than a queried one.
  Future<WriteOutcome> setBirthWeight(LambId lamb, Grams? weight) => _setOneLambColumn(
    lamb,
    (Instant now) =>
        LambsCompanion(birthWeightG: Value<int?>(weight?.value), updatedAt: Value<Instant>(now)),
  );

  /// The lamb-row twin of `_setOneColumn`, and it exists for the same reason: a
  /// wide write is how a second edit clobbers the first.
  Future<WriteOutcome> _setOneLambColumn(
    LambId lamb,
    LambsCompanion Function(Instant now) build,
  ) async {
    try {
      final Instant now = appNow(); // ONE instant per mutation
      final int rows = await (_db.update(
        _db.lambs,
      )..where(($LambsTable t) => t.id.equals(lamb.value))).write(build(now));
      return WriteCommitted(insertedId: rows > 0 ? lamb.value : null);
    } on Object catch (e) {
      return WriteFailed(shedFailureFrom(e));
    }
  }

  /// The Lamb Card, from one statement.
  ///
  /// **`readsFrom:` IS EXPLICIT AND IT IS LOAD-BEARING.** A `customSelect`
  /// cannot infer its dependencies, so a stream that omitted a table would go
  /// stale silently — the shepherd fosters a lamb and the card keeps showing the
  /// old dam until they navigate away and back. The five tables here are the
  /// five the statement reads; `lamb_rearing` is a VIEW over `lambs` and
  /// `foster_events`, both of which are named, so drift can see through it.
  Stream<LambCardData> watchLambCard(LambId lamb) => _db
      .customSelect(
        _lambCardSql,
        variables: <Variable<Object>>[Variable<int>(lamb.value)],
        readsFrom: <ResultSetImplementation<dynamic, dynamic>>{
          _db.lambs,
          _db.lambings,
          _db.fosterEvents,
          _db.ewes,
          _db.careEvents,
          _db.treatments,
        },
      )
      .watch()
      .map(_foldLambCard);

  /// Corrects the time the lambing happened.
  ///
  /// **THE FIRST CODE IN THE APP THAT WRITES AN `edited` ROW.** `Lambings` has
  /// carried the provenance quad and both paired `CHECK`s since N07-T04; this is
  /// the verb that finally uses them.
  ///
  /// **`captured_at` NEVER MOVES, AND THE COMPANION SAYS SO WITH ABSENCE.**
  /// `Value.absent()` leaves the column alone; `Value(null)` would write NULL
  /// and trip the `CHECK`. `05 §4.1`'s anti-pattern list names *"a `copyWith` on
  /// `RecordedTime` that accepts `capturedAt`"* for the same reason: that field
  /// is how `entryLag` is measurable at all, and how spec §15's *"within five
  /// minutes of the event"* can ever be checked.
  ///
  /// **`original_effective` IS THE FIRST VALUE, NOT THE PREVIOUS ONE.**
  /// `editedTo` is `originalEffective ?? effective`, so an unbounded chain of
  /// edits keeps what we first thought. Storing the previous value instead
  /// records THAT a time was edited and loses WHAT IT WAS EDITED FROM, which
  /// makes §12.5's label true but useless.
  ///
  /// **`local_date` MOVES WITH THE INSTANT, IN THE SAME STATEMENT** (`12 §2.4`).
  /// A one-day error puts a bar in the wrong column of the lambing-spread
  /// histogram and fires `localDateDisagrees` on every subsequent read.
  ///
  /// This verb produces `userEdited` and never `userEntered`. *A deferred entry
  /// typed at 7am for a 03:20 lambing was never wrong, whereas an edited one
  /// was* — they are different facts, and v1's Quick Entry does not offer the
  /// first: every lambing starts `auto`.
  Future<WriteOutcome> correctOccurredAt(LambingId id, Instant when) async {
    try {
      final Instant now = appNow(); // ONE instant per mutation

      return await _db.transaction(() async {
        final Lambing row = await (_db.select(
          _db.lambings,
        )..where(($LambingsTable t) => t.id.equals(id.value))).getSingle();

        final RecordedTime corrected = recordedTimeFromColumns(
          effective: row.occurredAt,
          capturedAt: row.capturedAt,
          originalEffective: row.originalEffective,
          sourceKey: row.timeSource,
        ).editedTo(when);

        await (_db.update(_db.lambings)..where(($LambingsTable t) => t.id.equals(id.value))).write(
          LambingsCompanion(
            occurredAt: Value<Instant>(corrected.effective),
            originalEffective: Value<Instant?>(corrected.originalEffective),
            timeSource: Value<String>(corrected.source.key),
            // MOVED IN THE SAME STATEMENT — never in a second write, which
            // could be the one that is lost.
            localDate: Value<LocalDate>(LocalDate.of(corrected.effective)),
            // ABSENT, NOT NULL. See the doc comment above.
            updatedAt: Value<Instant>(now),
          ),
        );
        return WriteCommitted(insertedId: id.value);
      });
    } on Object catch (e) {
      return WriteFailed(shedFailureFrom(e));
    }
  }

  /// **THE ONLY WRITER OF `declared_birth_type` IN THE APP**, and it is reached
  /// only from the deliberate declaration path — the type cell or a query mark,
  /// never the five-tap path.
  ///
  /// P8 (`CLAUDE.md`, decision-record §7.0b) abolished the birth-type CHOOSER:
  /// birth type is DERIVED from the tally strokes and printed `(COUNTED)`. That
  /// is what makes §12.4 structural rather than procedural — the shepherd
  /// cannot be asked to declare a number the app is about to contradict.
  /// `setBirthType` is the deliberate exception, and it does exactly one thing:
  /// **it writes the declaration and LEAVES THE LAMBS ALONE.** There is no
  /// reconciliation, no lamb is added, none is struck.
  ///
  /// Returns `WriteCommitted()` with the default **empty** `warnings` (R53). A
  /// repository is structurally incapable of producing one: this whole directory
  /// has no import path to the validators, held both by a gate row and by a
  /// policy test that scans these files for the import.
  ///
  /// **That test scans for the PATH as a literal**, so this comment describes it
  /// rather than spelling it — the first version of this doc comment failed the
  /// suite by naming the thing it was explaining. If a warning ever appears to
  /// come from here, an import was added; check the gate before the logic.
  Future<WriteOutcome> setBirthType(LambingId id, BirthType type) async {
    try {
      final Instant now = appNow();
      final int rows =
          await (_db.update(
            _db.lambings,
          )..where(($LambingsTable t) => t.id.equals(id.value))).write(
            LambingsCompanion(
              declaredBirthType: Value<int?>(type.code),
              updatedAt: Value<Instant>(now),
            ),
          );
      return WriteCommitted(insertedId: rows > 0 ? id.value : null);
    } on Object catch (e) {
      return WriteFailed(shedFailureFrom(e));
    }
  }

  /// Records one care event against exactly one subject.
  ///
  /// **THERE IS NO WAY TO RECORD "NO", AND THAT IS THE DESIGN** (decision #43,
  /// `07 §6.2`). A care line has two states — *not recorded* and *done* — and a
  /// shepherd who did not dip a navel has recorded nothing. The app must not
  /// turn that into a claim. The state is `EXISTS` over rows precisely because
  /// it *"keeps 'colostrum given at 03:22' recoverable"*; a boolean column would
  /// delete both facts at once.
  ///
  /// **NO DEFAULT VOLUME AND NO DEFAULT METHOD.** `05 §7.3` settles it: the app
  /// may arithmetic-transform a number the user supplied; it may never originate
  /// a number that is a clinical decision. No suggested volume, no "typical"
  /// figure, no last-value autofill. `volume_ml BETWEEN 1 AND 2000` is a
  /// UNIT-SLIP GUARD and never a dose (`03 §5.6`) — 3000 trips the `CHECK` and
  /// comes back as a `WriteFailed`. It is not clamped to 2000, not rounded and
  /// not silently dropped: all three are §12.4 with a helpful face on.
  ///
  /// **`season` is copied from the parent INSIDE the transaction.**
  /// `care_events.season` is `NOT NULL`; reading it from the screen's copy is
  /// one frame stale, and getting it wrong scopes the row into the wrong
  /// season's statistics forever.
  ///
  /// N24 writes the colostrum and navel reminder rows INSIDE this transaction,
  /// so that completing a reminder and writing the care event stay the same tap
  /// (`03 §5.6`). The boundary is here rather than in a second transaction the
  /// next epic would have to open.
  Future<WriteOutcome> addCare(
    CareSubject subject, {
    required CareKind kind,
    int? volumeMl,
    ColostrumMethod? method,
  }) async {
    try {
      final Instant now = appNow(); // ONE instant per mutation
      final RecordedTime when = RecordedTime.capture(now); // §12.5 provenance

      return await _db.transaction(() async {
        // The season comes from the SUBJECT's lambing, and the two arms differ
        // only in how far they have to walk to find it.
        final SeasonId season = switch (subject) {
          CareForLambing(:final LambingId lambing) => await _seasonOfLambing(lambing),
          CareForLamb(:final LambId lamb) => await _seasonOfLamb(lamb),
        };

        final int id = await _db
            .into(_db.careEvents)
            .insert(
              CareEventsCompanion.insert(
                uid: newUid(), // export identity — #32, R15
                createdAt: now,
                updatedAt: now,
                season: season.value,
                lambing: Value<int?>(switch (subject) {
                  CareForLambing(:final LambingId lambing) => lambing.value,
                  CareForLamb() => null,
                }),
                lamb: Value<int?>(switch (subject) {
                  CareForLamb(:final LambId lamb) => lamb.value,
                  CareForLambing() => null,
                }),
                kind: kind.key,
                occurredAt: when.effective,
                capturedAt: when.capturedAt,
                originalEffective: Value<Instant?>(when.originalEffective),
                timeSource: Value<String>(when.source.key),
                volumeMl: Value<int?>(volumeMl),
                method: Value<String?>(method?.key),
              ),
            );
        return WriteCommitted(insertedId: id);
      });
    } on Object catch (e) {
      return WriteFailed(shedFailureFrom(e));
    }
  }

  /// **STRIKES, AND DOES NOT DELETE.**
  ///
  /// `07 §15.1` predates P1 and says the undo of this verb is *"re-insert with
  /// the original `RecordedTime`"*, which implies the row was deleted. That is
  /// unrenderable: `indelible.md §7.10`'s **Undone** state prints the struck
  /// stamp beside a new one, and a deleted row has no stamp to strike. P1
  /// (N00-T05) puts `struck` / `struck_at` on `care_events` through
  /// `mixin Struckable`, which is what settles it — Indelible rule 1, *"if a
  /// proposal makes information disappear from the page, it is wrong"*, is
  /// binding rather than advisory. `07 §15.1` is amended in this commit.
  Future<WriteOutcome> removeCare(CareEventId id) async {
    try {
      final Instant now = appNow();
      final int rows =
          await (_db.update(
            _db.careEvents,
          )..where(($CareEventsTable t) => t.id.equals(id.value))).write(
            CareEventsCompanion(
              struck: const Value<bool>(true),
              struckAt: Value<Instant?>(now),
              updatedAt: Value<Instant>(now),
            ),
          );
      return WriteCommitted(insertedId: rows > 0 ? id.value : null);
    } on Object catch (e) {
      return WriteFailed(shedFailureFrom(e));
    }
  }

  Future<SeasonId> _seasonOfLambing(LambingId id) async {
    final Lambing row = await (_db.select(
      _db.lambings,
    )..where(($LambingsTable t) => t.id.equals(id.value))).getSingle();
    return SeasonId(row.season);
  }

  Future<SeasonId> _seasonOfLamb(LambId id) async {
    final Lamb lamb = await (_db.select(
      _db.lambs,
    )..where(($LambsTable t) => t.id.equals(id.value))).getSingle();
    return _seasonOfLambing(LambingId(lamb.lambing));
  }

  Future<LambId> addLamb(LambingId lambing, {Sex? sex}) {
    final Instant now = appNow(); // ONE instant per mutation

    return _db.transaction(() async {
      final Lambing parent = await (_db.select(
        _db.lambings,
      )..where(($LambingsTable t) => t.id.equals(lambing.value))).getSingle();

      final int id = await _db
          .into(_db.lambs)
          .insert(
            LambsCompanion.insert(
              lambing: lambing.value,
              birthDam: parent.ewe,
              sex: Value<String?>(sex?.key),
              uid: newUid(),
              createdAt: now,
              updatedAt: now,
            ),
          );
      return LambId(id);
    });
  }

  /// Strikes a lambing. **The row STAYS.**
  ///
  /// `strike`, never `delete`, never `remove`, never a generic `undo(id)`:
  /// decision #69 refuses a generic undo, and `CONVENTIONS §5.2` makes *strike*
  /// the project word. Indelible Rule 1 is absolute — *"There is no delete. Not
  /// banned — absent. The concept of erasure does not exist in the product."*
  ///
  /// **THE FIRST EDIT VERB ON `lambings`**, which R37 permits only because the
  /// table carries the provenance quad. A table without the quad has no edit
  /// verb.
  ///
  /// `struck_at` is a real instant from `appNow()`, in the same mutation. It is
  /// a MACHINE FACT ABOUT THE STRIKE rather than an event time, so it takes no
  /// provenance quad of its own and never claims one. The paired-nullable CHECK
  /// — `(struck = 1) = (struck_at IS NOT NULL)` — is what makes a struck row
  /// with no time unrepresentable.
  Future<WriteOutcome> strikeLambing(LambingId id) async {
    try {
      final Instant now = appNow();
      final int rows =
          await (_db.update(
            _db.lambings,
          )..where(($LambingsTable t) => t.id.equals(id.value))).write(
            LambingsCompanion(
              struck: const Value<bool>(true),
              struckAt: Value<Instant?>(now),
              updatedAt: Value<Instant>(now),
            ),
          );
      return WriteCommitted(insertedId: rows > 0 ? id.value : null);
    } on Object catch (e) {
      return WriteFailed(shedFailureFrom(e));
    }
  }

  /// **ONE STATEMENT FOR THE WHOLE SCREEN** (decision #12, `07 §6.2`).
  ///
  /// The obvious implementation combines four streams in Dart, and two drift
  /// streams updated inside one transaction can emit at different times — so a
  /// screen built that way renders a lamb whose care event has not arrived yet.
  /// Fan-in happens in SQL.
  ///
  /// `care_events`' CHECK is exactly one of (`lambing`, `lamb`). This screen
  /// writes every care event against a LAMB; the nullable `lambing` FK exists
  /// for a care action taken before any lamb is attached, and the second arm of
  /// the join picks those up on the null-lamb row the outer `LEFT JOIN`
  /// produces. **Deleting that arm is silent** — the rows simply stop
  /// appearing.
  Stream<LambingEntryData> watchLambingEntry(LambingId lambing) => _db
      .customSelect(
        _lambingEntrySql,
        variables: <Variable<Object>>[Variable<int>(lambing.value)],
        readsFrom: <ResultSetImplementation<dynamic, dynamic>>{
          _db.lambings,
          _db.lambs,
          _db.careEvents,
        },
      )
      .watch()
      .map(_foldLambingEntry);

  /// Folds the joined rows into one value.
  ///
  /// The `LEFT JOIN` repeats the header on every row, so the header is read
  /// once and the two lists are accumulated by id — which is also why the
  /// statement orders by `l.id, c.id`: **insertion order is stroke order**, and
  /// a fold over an unordered result would renumber the strokes on every
  /// emission.
  LambingEntryData _foldLambingEntry(List<QueryRow> rows) {
    final QueryRow first = rows.first;

    final Map<int, LambEntryRow> lambs = <int, LambEntryRow>{};
    final Map<int, List<CareEntryRow>> careByLamb = <int, List<CareEntryRow>>{};
    final List<CareEntryRow> lambingCare = <CareEntryRow>[];
    final Set<int> seenCare = <int>{};

    for (final QueryRow r in rows) {
      final int? lambId = r.readNullable<int>('lamb_id');
      final int? careId = r.readNullable<int>('care_id');

      if (lambId != null && !lambs.containsKey(lambId)) {
        lambs[lambId] = LambEntryRow(
          id: LambId(lambId),
          // NULL is not Sex.unknown (R45) — the null check is on the COLUMN.
          sex: r.readNullable<String>('sex') == null ? null : Sex.fromKey(r.read<String>('sex')),
          status: LambStatus.fromKey(r.read<String>('status')),
          birthWeight: r.readNullable<int>('birth_weight_g') == null
              ? null
              : Grams(r.read<int>('birth_weight_g')),
          tag: r.readNullable<String>('tag'),
          struck: r.read<bool>('lamb_struck'),
          care: const <CareEntryRow>[],
        );
      }

      // A care event repeats once per joined row; the set is what stops it
      // being counted twice when a lamb carries more than one.
      if (careId != null && seenCare.add(careId)) {
        final CareEntryRow care = CareEntryRow(
          id: CareEventId(careId),
          kind: r.read<String>('care_kind'),
          volumeMl: r.readNullable<int>('volume_ml'),
          method: r.readNullable<String>('method'),
          time: recordedTimeFromColumns(
            effective: Instant(r.read<int>('care_occurred_at')),
            capturedAt: Instant(r.read<int>('care_occurred_at')),
            originalEffective: null,
            sourceKey: r.read<String>('care_time_source'),
          ),
          struck: r.read<bool>('care_struck'),
        );
        if (lambId == null) {
          lambingCare.add(care);
        } else {
          (careByLamb[lambId] ??= <CareEntryRow>[]).add(care);
        }
      }
    }

    return LambingEntryData(
      lambing: LambingHeaderRow(
        id: LambingId(first.read<int>('lambing_id')),
        ewe: EweId(first.read<int>('ewe')),
        season: SeasonId(first.read<int>('season')),
        seasonStart: LocalDate.parse(first.read<String>('season_start')),
        declaredBirthType: first.readNullable<int>('declared_birth_type') == null
            ? null
            : BirthType.fromCode(first.read<int>('declared_birth_type')),
        ease: first.readNullable<int>('ease') == null ? null : LambingEase(first.read<int>('ease')),
        time: recordedTimeFromColumns(
          effective: Instant(first.read<int>('occurred_at')),
          capturedAt: Instant(first.read<int>('captured_at')),
          originalEffective: first.readNullable<int>('original_effective') == null
              ? null
              : Instant(first.read<int>('original_effective')),
          sourceKey: first.read<String>('time_source'),
        ),
        assistedBy: first.readNullable<String>('assisted_by'),
        presentation: first.readNullable<String>('presentation'),
        presentationNote: first.readNullable<String>('presentation_note'),
        note: first.readNullable<String>('note'),
        struck: first.read<bool>('lambing_struck'),
      ),
      lambs: <LambEntryRow>[
        for (final MapEntry<int, LambEntryRow> e in lambs.entries)
          LambEntryRow(
            id: e.value.id,
            sex: e.value.sex,
            status: e.value.status,
            birthWeight: e.value.birthWeight,
            tag: e.value.tag,
            struck: e.value.struck,
            care: careByLamb[e.key] ?? const <CareEntryRow>[],
          ),
      ],
      lambingCare: lambingCare,
    );
  }

  /// **Never creates a season.** A verb that invented one would give the
  /// shepherd a season they did not start, on the 3am path, silently — and the
  /// season is the unit the whole free tier is priced on.
  Future<SeasonId> _currentSeason() async {
    final AppSetting settings = await _db.select(_db.appSettings).getSingle();
    final int? current = settings.currentSeason;
    if (current == null) {
      throw StateError('no current season — Quick Entry must not offer a lambing without one');
    }
    return SeasonId(current);
  }
}

/// One screen, one value. Assembled from ONE statement; nothing here is
/// computed from a second stream.
///
/// It is declared in `lib/data/` because `lib/features/` may import this layer
/// and may **not** import `lib/core/db/` or `package:drift` at all — so a data
/// class living beside the table would be unreachable from the screen that
/// needs it.
@immutable
final class LambingEntryData {
  const LambingEntryData({required this.lambing, required this.lambs, required this.lambingCare});

  final LambingHeaderRow lambing;

  /// **Insertion order IS stroke order** — `ORDER BY l.id ASC`. Struck lambs
  /// stay in the list (Indelible Rule 1: nothing disappears from the page); the
  /// widget decides how a struck stroke renders, and the statement never
  /// filters.
  final List<LambEntryRow> lambs;

  /// Care events attached to the LAMBING rather than to a lamb — recorded
  /// before the first stroke. **Never merged into [lambs]**: they are a
  /// different fact, and `care_events`' CHECK keeps them distinguishable.
  final List<CareEntryRow> lambingCare;
}

@immutable
final class LambingHeaderRow {
  const LambingHeaderRow({
    required this.id,
    required this.ewe,
    required this.season,
    required this.seasonStart,
    required this.declaredBirthType,
    required this.ease,
    required this.time,
    required this.assistedBy,
    required this.presentation,
    required this.presentationNote,
    required this.note,
    required this.struck,
  });

  final LambingId id;
  final EweId ewe;
  final SeasonId season;

  /// **CARRIED ON THE HEADER, NOT FETCHED SEPARATELY.** `checkLambing` needs the
  /// season's start date to fire `lambingBeforeSeasonStart`, and reading it with
  /// a second query would be a second content statement — `07 §1.2` allows one.
  /// The join costs one row.
  final LocalDate seasonStart;

  /// **NULL means NOT DECLARED (R6), never `single`.** P8 abolished the chooser,
  /// so on the five-tap path this is always null and the birth type is derived
  /// from the strokes and labelled `(COUNTED)`.
  final BirthType? declaredBirthType;

  /// **NULL means NOT SCORED, never "1 — unassisted".** A blank ease excludes
  /// the lambing from both sides of the assisted rate rather than counting as
  /// an easy one.
  final LambingEase? ease;

  /// The whole §12.5 quad, assembled here through the write path's own
  /// factories — see `recorded_time_columns.dart` for why that matters.
  final RecordedTime time;

  final String? assistedBy;

  /// A `vocab_terms.key`, resolved at the edge. The repository never renders a
  /// label, because the shepherd may have renamed it.
  final String? presentation;

  final String? presentationNote;
  final String? note;
  final bool struck;
}

@immutable
final class LambEntryRow {
  const LambEntryRow({
    required this.id,
    required this.sex,
    required this.status,
    required this.birthWeight,
    required this.tag,
    required this.struck,
    required this.care,
  });

  final LambId id;

  /// **NULL is not `Sex.unknown`** (R45). Not recorded and recorded-as-unknown
  /// are different facts, and merging them would be the app answering a
  /// question the shepherd did not.
  final Sex? sex;

  final LambStatus status;

  /// Canonical grams, never a double.
  final Grams? birthWeight;

  final String? tag;
  final bool struck;
  final List<CareEntryRow> care;
}

@immutable
final class CareEntryRow {
  const CareEntryRow({
    required this.id,
    required this.kind,
    required this.volumeMl,
    required this.method,
    required this.time,
    required this.struck,
  });

  final CareEventId id;

  /// One of the four closed CHECK values.
  final String kind;

  final int? volumeMl;
  final String? method;
  final RecordedTime time;
  final bool struck;
}

/// `07 §6.2`'s statement, verbatim. Do not re-derive it and do not "tidy" the
/// column list.
const String _lambingEntrySql = '''
SELECT lg.id AS lambing_id, lg.ewe, lg.season, lg.declared_birth_type, lg.ease,
       s.start_date AS season_start,
       lg.occurred_at, lg.captured_at, lg.original_effective, lg.time_source,
       lg.assisted_by, lg.presentation, lg.presentation_note, lg.note,
       lg.struck AS lambing_struck,
       l.id AS lamb_id, l.sex, l.status, l.birth_weight_g, l.tag,
       l.struck AS lamb_struck,
       c.id AS care_id, c.kind AS care_kind, c.volume_ml, c.method,
       c.occurred_at AS care_occurred_at, c.time_source AS care_time_source,
       c.struck AS care_struck
  FROM lambings lg
  JOIN seasons s          ON s.id = lg.season
  LEFT JOIN lambs l       ON l.lambing = lg.id
  LEFT JOIN care_events c ON c.lamb = l.id
                          OR (l.id IS NULL AND c.lambing = lg.id)
 WHERE lg.id = ?
 ORDER BY l.id ASC, c.id ASC
''';

/// `07 §7.1`'s statement, fanned in **in SQL**.
///
/// The `WITH` carries the header onto every history row, so there is ONE
/// statement and ONE dependency list. Two statements would be two lists that can
/// disagree about when the card is stale — and the card is the screen a shepherd
/// opens in year two to answer *"what did 412 do last year?"*, which is the
/// product's whole reason for existing.
const String _lambCardSql = '''
WITH card AS (
  SELECT lb.id  AS lamb_id,  lb.tag        AS tag,        lb.sex           AS sex,
         lb.birth_weight_g   AS birth_weight_g,           lb.status        AS status,
         lb.death_date       AS death_date,               lb.death_cause   AS death_cause,
         lb.pet_lamb         AS pet_lamb,                 lb.bottle_feeds  AS bottle_feeds,
         lb.struck           AS struck,
         lb.lambing          AS lambing_id,
         lg.occurred_at      AS born_at,                  lg.local_date    AS born_local_date,
         lg.captured_at      AS born_captured_at,
         lg.original_effective AS born_original_effective,
         lg.time_source      AS born_time_source,
         lr.birth_dam        AS birth_dam,    bd.tag      AS birth_dam_tag,
         lr.rearing_dam      AS rearing_dam,  rd.tag      AS rearing_dam_tag,
         lr.was_fostered     AS was_fostered,
         (SELECT fe.outcome FROM foster_events fe
           WHERE fe.lamb = lb.id
           ORDER BY fe.effective_at DESC, fe.id DESC LIMIT 1) AS latest_outcome
    FROM lambs lb
    JOIN lambings     lg ON lg.id      = lb.lambing
    JOIN lamb_rearing lr ON lr.lamb_id = lb.id
    JOIN ewes         bd ON bd.id      = lb.birth_dam
    LEFT JOIN ewes    rd ON rd.id      = lr.rearing_dam
   WHERE lb.id = ?
)
SELECT c.*, 'born' AS kind, c.lambing_id AS ref, c.born_at AS at,
       c.born_captured_at AS captured_at,
       c.born_original_effective AS original_effective,
       c.born_time_source AS time_source
  FROM card c
UNION ALL
SELECT c.*, 'foster', f.id, f.effective_at, f.captured_at, f.original_effective, f.time_source
  FROM card c JOIN foster_events f ON f.lamb = c.lamb_id
UNION ALL
SELECT c.*, 'care', ce.id, ce.occurred_at, ce.captured_at, ce.original_effective, ce.time_source
  FROM card c JOIN care_events ce ON ce.lamb = c.lamb_id
UNION ALL
SELECT c.*, 'treatment', t.id, t.administered_at, t.captured_at, t.original_effective, t.time_source
  FROM card c JOIN treatments t ON t.lamb = c.lamb_id
 ORDER BY at DESC
''';

/// One history row on the Lamb Card.
///
/// **THE §12.5 TRIPLE TRAVELS WITH EVERY ROW**, on every arm of the union, so no
/// arm can be rendered without its provenance. A history list that showed four
/// kinds of event and a bare time for each would be the one screen where the
/// provenance claim quietly stops being true.
final class LambHistoryRow {
  const LambHistoryRow({
    required this.kind,
    required this.ref,
    required this.at,
    required this.capturedAt,
    required this.timeSource,
    this.originalEffective,
  });

  /// `born` · `foster` · `care` · `treatment` — the union arm.
  final String kind;

  /// The source row's id, **raw and never leaving this layer**: a typed id per
  /// arm would need a sealed hierarchy for a value nothing above here reads.
  final int ref;

  final Instant at;
  final Instant capturedAt;
  final Instant? originalEffective;
  final TimeSource timeSource;

  /// Rebuilt rather than stored, so the card renders the same label the lambing
  /// header does.
  RecordedTime get time => recordedTimeFromColumns(
    effective: at,
    capturedAt: capturedAt,
    originalEffective: originalEffective,
    sourceKey: timeSource.key,
  );
}

/// Both dams, and **the two different reasons the rearing dam can be absent**.
///
/// `rearingDam == null` is NEVER rendered with one string (`07 §7.2`): a lamb on
/// the bottle and a lamb whose rearing dam was not recorded are different facts,
/// and `latestOutcome` is what tells them apart.
final class LambRearing {
  const LambRearing({
    required this.birthDam,
    required this.birthDamTag,
    required this.wasFostered,
    this.rearingDam,
    this.rearingDamTag,
    this.latestOutcome,
  });

  /// **A lamb has one birth dam, forever.** It is on the lamb row and no verb
  /// in the app moves it — a foster moves the REARING dam, and making a foster
  /// look like a rewrite of history is the failure `lamb_rearing` exists to
  /// prevent.
  final EweId birthDam;
  final String birthDamTag;

  /// True when any foster event exists, including one that removed the lamb from
  /// a ewe. It is not `rearingDam != birthDam`: a lamb fostered back is still a
  /// lamb that was fostered.
  final bool wasFostered;

  final EweId? rearingDam;
  final String? rearingDamTag;

  /// `to_ewe` · `to_bottle` · `removed_unknown` · null.
  final String? latestOutcome;
}

/// Everything the Lamb Card renders, from one statement.
final class LambCardData {
  const LambCardData({
    required this.lambId,
    required this.lambingId,
    required this.bornTime,
    required this.bornLocalDate,
    required this.rearing,
    required this.status,
    required this.petLamb,
    required this.bottleFeeds,
    required this.history,
    required this.struck,
    this.tag,
    this.sex,
    this.birthWeight,
    this.deathDate,
    this.deathCauseKey,
  });

  final LambId lambId;
  final LambingId lambingId;

  /// The LAMBING's provenance, because that is when the lamb was born — a lamb
  /// has no time of its own.
  final RecordedTime bornTime;
  final LocalDate bornLocalDate;

  final LambRearing rearing;
  final LambStatus status;
  final bool petLamb;
  final int bottleFeeds;

  /// **Never empty**: the `born` arm always yields one row.
  final List<LambHistoryRow> history;

  final bool struck;

  /// `null` is UNTAGGED, which is the state a lamb is in for most of its first
  /// week.
  final String? tag;

  /// **NULL is not `Sex.unknown`** (R45).
  final Sex? sex;

  final Grams? birthWeight;
  final LocalDate? deathDate;

  /// A `vocab_terms` key, or **null = unattributed** — which is not the same as
  /// the `dc_unknown` term the shepherd can pick. The vocabulary keeps those two
  /// apart and so does this field.
  final String? deathCauseKey;
}

/// Folds the union back into one card.
///
/// The header repeats on every row — that is what the `WITH` is for — so the
/// first row carries it and the rest contribute only their history entry.
LambCardData _foldLambCard(List<QueryRow> rows) {
  if (rows.isEmpty) {
    // A lamb that does not exist, or one whose lambing was hard-deleted — which
    // cannot happen, because nothing in this app hard-deletes. Throwing is
    // right: the route was pushed with an id, and an empty card would be a blank
    // screen with no explanation.
    throw StateError('no lamb card rows — the lamb id does not exist');
  }

  final QueryRow first = rows.first;

  return LambCardData(
    lambId: LambId(first.read<int>('lamb_id')),
    lambingId: LambingId(first.read<int>('lambing_id')),
    bornTime: recordedTimeFromColumns(
      effective: Instant(first.read<int>('born_at')),
      capturedAt: Instant(first.read<int>('born_captured_at')),
      originalEffective: first.readNullable<int>('born_original_effective') == null
          ? null
          : Instant(first.read<int>('born_original_effective')),
      sourceKey: first.read<String>('born_time_source'),
    ),
    bornLocalDate: LocalDate.parse(first.read<String>('born_local_date')),
    rearing: LambRearing(
      birthDam: EweId(first.read<int>('birth_dam')),
      birthDamTag: first.read<String>('birth_dam_tag'),
      wasFostered: first.read<int>('was_fostered') != 0,
      rearingDam: first.readNullable<int>('rearing_dam') == null
          ? null
          : EweId(first.read<int>('rearing_dam')),
      rearingDamTag: first.readNullable<String>('rearing_dam_tag'),
      latestOutcome: first.readNullable<String>('latest_outcome'),
    ),
    status: LambStatus.fromKey(first.read<String>('status')),
    petLamb: first.read<int>('pet_lamb') != 0,
    bottleFeeds: first.read<int>('bottle_feeds'),
    struck: first.read<int>('struck') != 0,
    tag: first.readNullable<String>('tag'),
    // NULL IS NOT `Sex.unknown` (R45), and the ternary is where that would be
    // lost by anybody reaching for a default.
    sex: first.readNullable<String>('sex') == null
        ? null
        : Sex.values.firstWhere((Sex s) => s.key == first.read<String>('sex')),
    birthWeight: first.readNullable<int>('birth_weight_g') == null
        ? null
        : Grams(first.read<int>('birth_weight_g')),
    deathDate: first.readNullable<String>('death_date') == null
        ? null
        : LocalDate.parse(first.read<String>('death_date')),
    deathCauseKey: first.readNullable<String>('death_cause'),
    history: <LambHistoryRow>[
      for (final QueryRow r in rows)
        LambHistoryRow(
          kind: r.read<String>('kind'),
          ref: r.read<int>('ref'),
          at: Instant(r.read<int>('at')),
          capturedAt: Instant(r.read<int>('captured_at')),
          originalEffective: r.readNullable<int>('original_effective') == null
              ? null
              : Instant(r.read<int>('original_effective')),
          timeSource: TimeSource.fromKey(r.read<String>('time_source')),
        ),
    ],
  );
}
