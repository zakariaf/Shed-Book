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
