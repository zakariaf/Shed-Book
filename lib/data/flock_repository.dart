// lib/data/flock_repository.dart — the tag index, the Quick Entry deck, and the
// one create verb the free-tier cap can refuse.
//
// `createEwe` CARRIES `EntryContext` FROM ITS FIRST COMMIT (critique S5). The
// old plan added the cap parameter sixteen epics later, which would have
// re-opened the product's most-reviewed repository to change a signature.
// R19: the repository set is twelve and closed; there is no
// QuickEntryRepository.
//
// The class gained a `FreeTierPolicy` collaborator here, so its constructor
// moved from positional to named — N13-T02 built it read-only and N14-T01's own
// text calls this file "New". It is not; it is an edit, and the constructor
// change is the one visible consequence.
//
// The deck lives here rather than on PenRepository for three reasons: both
// buckets are EWES, `ewe_touches` exists only for this read and is already this
// repository's table (CONVENTIONS §2.13), and the Foster screen reuses the same
// query (07 §1.1 row 6) and is not a pen screen. WRITES to `pens` and
// `pen_occupancies` remain PenRepository's — this is a read across a boundary,
// which is normal, not a second writer.
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/core/db/uid.dart';
import 'package:shed_book/core/time/app_clock.dart';
import 'package:shed_book/core/write_outcome.dart';
import 'package:shed_book/domain/free_tier.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/domain/tag_match.dart';
import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/domain/time/local_date.dart';

/// One row of either bucket of the deck.
///
/// **Value equality is REQUIRED, not tidy.** `.distinct()` in the repository
/// compares deck to deck, and a class with identity `==` makes both the
/// de-duplication and the per-bucket list reuse below expensive ways of always
/// returning false (drift#3295 open, `01 §4.4`). `build.yaml` sets
/// `override_hash_and_equals_in_result_sets: true` for the same reason on the
/// generated side.
@immutable
final class DeckEntry {
  const DeckEntry({
    required this.eweId,
    required this.tag,
    required this.digits,
    required this.sortAt,
    this.penLabel,
  });

  /// R33: an extension-type id, never a bare `int`.
  final EweId eweId;

  /// Exactly as typed; never normalised.
  final String tag;

  /// The `tag_digits` projection. Ranks, and is never shown.
  final String digits;

  /// Penned: `entered_at`. Recents: `touched_at`.
  final Instant sortAt;

  /// Penned only; `null` in the recents bucket.
  final String? penLabel;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeckEntry &&
          other.eweId == eweId &&
          other.tag == tag &&
          other.digits == digits &&
          other.sortAt == sortAt &&
          other.penLabel == penLabel;

  @override
  int get hashCode => Object.hash(eweId, tag, digits, sortAt, penLabel);
}

/// **A record, not a class** — that is what makes `.select((d) => d.penned)`
/// legal and readable (R28).
typedef QuickEntryDeck = ({List<DeckEntry> penned, List<DeckEntry> recents});

final class FlockRepository {
  /// `db:` and `policy:` are the names `CONVENTIONS §2.13` prints, and the
  /// initializing-formal lint is suppressed rather than obeyed: `this._db` would
  /// make the PUBLIC parameter name `_db`, so every caller would be writing a
  /// private name.
  // ignore_for_file: prefer_initializing_formals
  FlockRepository({required AppDatabase db, required FreeTierPolicy policy})
    : _db = db,
      _policy = policy;

  final AppDatabase _db;
  final FreeTierPolicy _policy;

  /// The whole active flock's tags, held in memory and ranked in Dart.
  ///
  /// ~400 entries × ~40 bytes ≈ 16 KB (`03 §9.1`). **Active animals only** —
  /// decision-record §7.0 ruling 7 — and that is not a filter for tidiness. The
  /// partial unique index `idx_ewe_tag_active` and this set are the SAME set, so
  /// typing `412` can never surface two live candidates and never needs a
  /// disambiguation dialog at 03:20. A culled `412` is absent, which is correct
  /// and not silent: her record surfaces later, in daylight, on the new 412's
  /// ewe card.
  ///
  /// **No `LIKE`, no FTS5, no trigram tokenizer on this path** (`03 §9.1`).
  /// FTS5's trigram tokenizer documents that substrings under three characters
  /// match no rows, and the spec's own example is the two-character `12`;
  /// `LIKE '%12%'` works and cannot use an index. Ranking is `rankTagMatches`,
  /// in Dart, over the list this stream yields.
  ///
  /// `.distinct()` here rather than in the controller: drift re-runs a watched
  /// query on any write to a tracked table, and without this every unrelated
  /// `ewe_touches` write would rebuild the controller's match list.
  Stream<List<TagIndexEntry>> watchTagIndex() {
    final JoinedSelectStatement<HasResultSet, dynamic> q = _db.select(_db.ewes).join(
      <Join<HasResultSet, dynamic>>[
        leftOuterJoin(_db.eweTouches, _db.eweTouches.ewe.equalsExp(_db.ewes.id)),
      ],
    )..where(_db.ewes.status.equals('active'));

    return q
        .map((TypedResult row) {
          final Ewe e = row.readTable(_db.ewes);
          return (
            eweId: EweId(e.id),
            tag: e.tag,
            // The PROJECTION ranks; `tag` decides identity (03 §6 rule 1). It is
            // never rendered — a unique tag_digits would refuse `0412` while
            // `412` exists, which is the app deciding two tags are one animal.
            digits: e.tagDigits,
            lastTouched: row.readTableOrNull(_db.eweTouches)?.touchedAt,
          );
        })
        .watch()
        .distinct();
  }

  /// The previous deck, so [_toDeck] can hand back the SAME list instance when a
  /// bucket did not change. This field is the mechanism, not a cache — see the
  /// comment on [_toDeck].
  QuickEntryDeck? _last;

  /// One statement, two buckets, one stream (decisions #12, #67, #68).
  ///
  /// **SQLite only accepts `ORDER BY`/`LIMIT` on the FINAL arm of a compound
  /// `SELECT`, so each bucket is a CTE.** Writing the two `SELECT`s with their
  /// own `ORDER BY … LIMIT 6` either fails to parse or — worse — parses as one
  /// ordering over the whole union: six rows TOTAL instead of six per bucket,
  /// and the penned strip silently empties on a busy night.
  ///
  /// **Combining two `watch()` streams in Dart is a build-breaking defect**
  /// (decision #12, gate row `stream.combine` — which scans this file, so the
  /// operator is described here rather than named). Two streams updated inside
  /// one transaction can emit at different times, and the maintainer's position
  /// on drift#3338 (open) is that this "generally is working as intended". A
  /// deck built that way renders a penned ewe who has already been turned out.
  /// Fan-in happens in SQL.
  ///
  /// `o.ewe IS NOT NULL` is load-bearing even though the `JOIN` would drop the
  /// row anyway: `pen_occupancies.ewe` is nullable because a pen can hold lambs
  /// with no ewe, decision #67 says the strip is ewes only, and reaching that
  /// result by accident rather than on purpose is how it stops being true.
  Stream<QuickEntryDeck> watchQuickEntryDeck() => _db
      .customSelect(
        _deckSql,
        readsFrom: <ResultSetImplementation<dynamic, dynamic>>{
          _db.penOccupancies,
          _db.eweTouches,
          _db.ewes,
          _db.pens,
        },
      )
      .watch()
      .map(_toDeck)
      .distinct();

  DeckEntry _entry(QueryRow r) => DeckEntry(
    eweId: EweId(r.read<int>('ewe_id')),
    tag: r.read<String>('tag'),
    digits: r.read<String>('tag_digits'),
    sortAt: Instant(r.read<int>('sort_at')),
    penLabel: r.readNullable<String>('pen_label'),
  );

  /// **THE SHARPEST TRAP IN THIS TASK, AND IT IS NOT THE SQL.**
  ///
  /// `02 §4.4`: *"a stored `List` field still has identity `==`, so `.select`
  /// deduplicates nothing — every new state instance carries a new list."* So a
  /// naive mapping fails the one-strip-rebuilds property EVEN WITH PERFECT SQL:
  /// penning a ewe writes `pen_occupancies`, drift re-runs the whole statement,
  /// this method allocates TWO fresh lists, `.distinct()` sees a deck that
  /// genuinely changed and emits, and the recents strip's `.select` compares two
  /// equal-but-not-identical `List`s with identity `==` and rebuilds.
  ///
  /// The fix is **not** a deep-equality helper in the selector — `02 §4.4` bans
  /// that explicitly, because it would run once per rebuild. It is here: hand
  /// back the SAME list when the bucket did not change, so the comparison runs
  /// once per emission instead. Same trade `01 §4.4` already makes for the pen
  /// board — *de-duplicate in the repository, never in the widget* — pushed one
  /// level finer so it works per bucket. It is also what makes the outer
  /// `.distinct()` meaningful, because an unchanged deck is now identical field
  /// for field.
  QuickEntryDeck _toDeck(List<QueryRow> rows) {
    final List<DeckEntry> penned = <DeckEntry>[
      for (final QueryRow r in rows)
        if (r.read<String>('bucket') == 'penned') _entry(r),
    ];
    final List<DeckEntry> recents = <DeckEntry>[
      for (final QueryRow r in rows)
        if (r.read<String>('bucket') == 'recent') _entry(r),
    ];

    final QuickEntryDeck? prev = _last;
    final QuickEntryDeck deck = (
      penned: _sameList(prev?.penned, penned) ? prev!.penned : penned,
      recents: _sameList(prev?.recents, recents) ? prev!.recents : recents,
    );
    return _last = deck;
  }

  /// **The one create verb the cap can refuse** (`11 §7.3`).
  ///
  /// On the live-entry path it is structurally incapable of refusing:
  /// `FreeTierPolicy.decide` cannot reach a `BlockedByCap` on that arm
  /// (decision #91). A shepherd mid-lambing is never told to pay.
  ///
  /// **The decision and the insert are in ONE transaction**, so the count
  /// cannot move between them — reading a count outside and inserting inside is
  /// a race with the restore path and with a second create.
  ///
  /// Reading `entitlements` here does not violate *"nothing on the 3am path
  /// reads it"*: `11 §4.4` bans a SCREEN from watching the entitlement, and the
  /// failure it prevents is a paywall flash at 03:20. Quick Entry watches
  /// nothing; it calls a verb that decides.
  Future<WriteOutcome> createEwe({required String tag, required EntryContext context}) =>
      _db.transaction(() async {
        final Instant now = appNow(); // ONE instant per mutation

        // THE COUNTS ARE POST-WRITE, and getting that wrong is an off-by-one
        // that ships. 11 §7.2: "the counts AS THEY WOULD BE AFTER THE WRITE".
        // Backwards, you either refuse ewe #15 or let #16 through — and the free
        // tier's boundary is the one number a paying user notices.
        final CapDecision decision = _policy.decide(
          context: context,
          now: now,
          unlocked: await _readUnlocked(),
          ewesInCurrentSeason: await _countEwesInCurrentSeason() + 1,
          seasonCount: await _countSeasons(), // this verb creates no season
        );

        // NO `default:`. CapDecision is sealed with two variants, and the day a
        // third appears every switch must fail to compile rather than swallow it.
        return switch (decision) {
          BlockedByCap(:final RefusalReason reason) => WriteRefused(reason),
          Allow(:final bool overFreeCap) => WriteCommitted(
            insertedId: await _insertEwe(tag: tag, now: now, overFreeCap: overFreeCap),
          ),
        };
      });

  /// `getSingle()`, not `getSingleOrNull()`: the table has `CHECK (id = 1)` and
  /// `seedFirstRun` seeds the row in `onCreate`, so it can never find nothing.
  /// A null branch here would have to guess an entitlement.
  Future<bool> _readUnlocked() async => (await _db.select(_db.entitlements).getSingle()).unlocked;

  Future<int> _countEwesInCurrentSeason() async {
    final AppSetting settings = await _db.select(_db.appSettings).getSingle();
    final int? season = settings.currentSeason;
    if (season == null) {
      return 0;
    }
    final List<EweSeason> rows = await (_db.select(
      _db.eweSeasons,
    )..where(($EweSeasonsTable t) => t.season.equals(season) & t.struck.equals(false))).get();
    return rows.length;
  }

  Future<int> _countSeasons() async => (await _db.select(_db.seasons).get()).length;

  /// Returns a raw `int` — one of only two places R33 permits one, because
  /// `WriteCommitted.insertedId` is an `int?` and the single reading call site
  /// wraps it in an `EweId`.
  Future<int> _insertEwe({
    required String tag,
    required Instant now,
    required bool overFreeCap,
  }) async {
    final int id = await _db
        .into(_db.ewes)
        .insert(
          EwesCompanion.insert(
            uid: newUid(), // R15 — core/db/uid.dart
            createdAt: now,
            updatedAt: now,
            // EXACTLY AS TYPED, never normalised (spec §12.4, decision #55).
            tag: tag,
            // A PROJECTION written in the same statement, not a correction:
            // '0412' stores '0412' and projects '0412'.
            tagDigits: tag.replaceAll(RegExp(r'\D'), ''),
            overFreeCap: Value<bool>(overFreeCap),
          ),
        );

    // ewe_touches is keyed on `ewe`, one row per ewe: upsert, never insert.
    await _db
        .into(_db.eweTouches)
        .insertOnConflictUpdate(EweTouchesCompanion.insert(ewe: Value<int>(id), touchedAt: now));
    return id;
  }
}

/// Element-wise comparison, written out rather than taken from
/// `package:collection`.
///
/// `ListEquality` would be the idiomatic call, but `collection` is transitive
/// here and making it direct is a `pubspec.yaml` and allowlist change — a
/// dependency decision, for four lines. [DeckEntry] has real `==`, so this is
/// exactly what `ListEquality` would do.
bool _sameList(List<DeckEntry>? a, List<DeckEntry> b) {
  if (a == null || a.length != b.length) {
    return false;
  }
  for (int i = 0; i < b.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

/// `07 §5.2`'s statement, verbatim.
const String _deckSql = '''
WITH penned AS (
  SELECT 'penned' AS bucket, e.id AS ewe_id, e.tag AS tag, e.tag_digits AS tag_digits,
         o.entered_at AS sort_at, p.label AS pen_label
    FROM pen_occupancies o
    JOIN ewes e ON e.id = o.ewe
    JOIN pens p ON p.id = o.pen
   WHERE o.exited_at IS NULL AND o.ewe IS NOT NULL
   ORDER BY o.entered_at ASC           -- longest-penned first: the one you are standing next to
   LIMIT 6
), recents AS (
  SELECT 'recent', e.id, e.tag, e.tag_digits, t.touched_at, NULL
    FROM ewe_touches t
    JOIN ewes e ON e.id = t.ewe
   WHERE e.status = 'active'
   ORDER BY t.touched_at DESC
   LIMIT 6
)
SELECT * FROM penned UNION ALL SELECT * FROM recents;
''';

/// The flock filter set — `spec §7.7`'s five, as a value.
///
/// **A RECORD OF BOOLEANS, NOT AN ENUM.** The five are not mutually exclusive:
/// *barren* and *not yet lambed* are different questions and a shepherd may want
/// both at once. An enum would make the screen build a second statement the day
/// somebody ticks two boxes, and `07 §1.2` allows one.
/// Spec §7.7's five, in the order `indelible.md §8` prints them on the filter
/// line. **The stored keys are the ARB keys and the widget keys; spell them
/// once** — three spellings of one filter is two of them going stale.
enum FlockFilter {
  notYetLambed('not_yet_lambed'),
  currentlyPenned('currently_penned'),
  underTreatment('under_treatment'),
  tripletBearing('triplet_bearing'),
  barren('barren');

  const FlockFilter(this.key);

  final String key;
}

final class FlockFilters {
  const FlockFilters({
    this.barren = false,
    this.notYetLambed = false,
    this.tripletBearing = false,
    this.currentlyPenned = false,
    this.underTreatment = false,
  });

  final bool barren;
  final bool notYetLambed;
  final bool tripletBearing;
  final bool currentlyPenned;
  final bool underTreatment;

  bool get isEmpty =>
      !barren && !notYetLambed && !tripletBearing && !currentlyPenned && !underTreatment;

  bool has(FlockFilter f) => switch (f) {
    FlockFilter.barren => barren,
    FlockFilter.notYetLambed => notYetLambed,
    FlockFilter.tripletBearing => tripletBearing,
    FlockFilter.currentlyPenned => currentlyPenned,
    FlockFilter.underTreatment => underTreatment,
  };

  FlockFilters toggle(FlockFilter f) => FlockFilters(
    barren: f == FlockFilter.barren ? !barren : barren,
    notYetLambed: f == FlockFilter.notYetLambed ? !notYetLambed : notYetLambed,
    tripletBearing: f == FlockFilter.tripletBearing ? !tripletBearing : tripletBearing,
    currentlyPenned: f == FlockFilter.currentlyPenned ? !currentlyPenned : currentlyPenned,
    underTreatment: f == FlockFilter.underTreatment ? !underTreatment : underTreatment,
  );

  /// **VALUE EQUALITY, AND IT IS LOAD-BEARING RATHER THAN TIDY.** This type is a
  /// Riverpod `.family` argument, and a family keys its providers by `==`. Two
  /// equal-but-distinct filter sets would be two providers, two subscriptions and
  /// two statements over four hundred rows — and the first one would never be
  /// disposed. T01 shipped without it and got away with it only because the
  /// notifier hands back the same instance until the state changes, which is
  /// identity holding by luck rather than equality holding by construction.
  ///
  /// This is also why the type is not `Set<FlockFilter>`, which N26-T02 §5.2
  /// prints: a Dart `Set` has no value equality either, so it would carry the
  /// same defect with none of the compile-time help.
  @override
  bool operator ==(Object other) =>
      other is FlockFilters &&
      other.barren == barren &&
      other.notYetLambed == notYetLambed &&
      other.tripletBearing == tripletBearing &&
      other.currentlyPenned == currentlyPenned &&
      other.underTreatment == underTreatment;

  @override
  int get hashCode =>
      Object.hash(barren, notYetLambed, tripletBearing, currentlyPenned, underTreatment);
}

/// One row of the flock list, as the statement returns it.
///
/// **COUNTS, NEVER A FORMATTED STRING** (`03 §5.13`). *"3 seasons · avg 2.0 ·
/// assisted twice"* is assembled in Dart from these numbers with the terminology
/// overlay and the locale applied; a formatted string in the database freezes
/// both, and the shepherd who renames *ewe* to *yow* in Settings would find the
/// old word still printed on every row.
final class FlockRow {
  const FlockRow({
    required this.id,
    required this.tag,
    required this.tagDigits,
    required this.status,
    required this.struck,
    required this.seasonsRecorded,
    required this.lambingsRecorded,
    required this.lambsBorn,
    required this.lambsBornAlive,
    required this.assistedLambings,
    required this.isPenned,
    required this.barren,
    required this.notYetLambed,
    required this.tripletBearing,
    required this.latestClearDate,
    required this.unrecordedWithdrawal,
    required this.hasWarning,
  });

  final EweId id;
  final String tag;
  final String tagDigits;

  /// The ANIMAL's state: `active`, `culled`, `sold` or `dead` (`03 §5.2`).
  ///
  /// **A STATE OF THE SHEEP, WHICH IS NOT THE SAME THING AS A STRUCK RECORD** —
  /// `indelible.md §6` draws exactly this line: a **boxed** stamp talks about the
  /// animal, an **unboxed** one talks about the writing, and *"you must be able to
  /// tell from ten feet"* which. `CULLED` is the sheep; `STRUCK` is the entry.
  final String status;

  /// **THE RECORD WAS STRUCK** — `ewes.struck`, the real column, not a synonym
  /// for culled.
  ///
  /// N26-T02's ruling N2 shipped a single `struck` field derived from
  /// `status != 'active'`, which quietly renamed one fact after another. The
  /// schema keeps them apart and so does the design; `idx_ewe_tagdigits` is
  /// partial on **both** (`status = 'active' AND struck = 0`), which is the
  /// clearest statement that they are two conditions rather than one.
  final bool struck;

  /// §7.4's **Struck** row state — *"ewe removed from the flock"*, by either
  /// route. This is what the row renders on; the two fields above are what it
  /// renders *about*.
  ///
  /// It is also what makes §7.0 ruling 7 legible: tags are unique among active,
  /// unstruck animals only, so `2003` is in this list twice and the removed one
  /// is the reason that is legal rather than a bug.
  bool get removedFromFlock => struck || status != 'active';

  /// **NULLABLE, AND NEVER `?? 0`** (decision #58). `ewe_summaries` is a
  /// `LEFT JOIN`, so a ewe with no summary row yet returns NULL — which means
  /// *not computed*, not *zero*. Printing `0 seasons` for an animal whose
  /// history simply has not been rolled up yet is the app inventing a fact.
  final int? seasonsRecorded;
  final int? lambingsRecorded;
  final int? lambsBorn;
  final int? lambsBornAlive;
  final int? assistedLambings;

  final bool isPenned;

  /// `ewe_seasons.status = 'barren'` (R42) — a stored ANSWER, not the absence of
  /// a lambing. `CONVENTIONS §5.1` keeps this word away from *empty* and *not in
  /// lamb* precisely because it is a different fact from [notYetLambed].
  final bool barren;

  /// In lamb and still waiting: in the season, and no lambing written in it.
  final bool notYetLambed;

  final bool tripletBearing;

  /// The stored TEXT civil date of the furthest-out live `days` withdrawal, or
  /// null if she carries none. **Read, never derived** — it is the date the
  /// shepherd was told on the day the medicine went in.
  final String? latestClearDate;

  /// **A live treatment with no withdrawal row: UNKNOWN, never clear** (§12.1,
  /// `03 §5.8`). Its own field rather than folded into a single boolean, because
  /// *still running* and *nobody typed it* are different facts and the screen
  /// says different things about them (`indelible.md §2.7`: `— NOT RECORDED`
  /// over a dotted rule, never a blank that could read as zero).
  final bool unrecordedWithdrawal;

  /// Read from the `lambing_consistency` VIEW, which recomputes on read.
  ///
  /// **There is no `warning_count` column and there never will be** (decision
  /// #54): a warning cannot be persisted because there is nowhere to persist it
  /// that survives the record changing underneath it.
  final bool hasWarning;

  /// **RULING N1 — THE COMPARISON HAPPENS HERE, NOT IN SQL.**
  ///
  /// `now` is a parameter (R24), so the answer advances with the clock: a phone
  /// left on the flock page across midnight re-answers correctly on the next
  /// rebuild, which a date bound into a long-lived `watch()` statement cannot do.
  ///
  /// **Unknown counts as under treatment.** A ewe whose withdrawal nobody typed
  /// is not clear — the app does not know, and hiding her from this list is the
  /// app deciding on the shepherd's behalf (spec §12.1). *Not applicable* is a
  /// recorded ANSWER and is therefore clear; the difference between an answer and
  /// an absence is the whole of `03 §5.8`.
  bool isUnderTreatment(Instant now) {
    if (unrecordedWithdrawal) {
      return true;
    }
    final String? clear = latestClearDate;
    if (clear == null) {
      return false;
    }
    // A LEXICOGRAPHIC COMPARISON, correct only because the format sorts —
    // `YYYY-MM-DD`, decision #2. Written out rather than parsed back into a date,
    // because parsing and re-formatting is two chances to shift a day.
    return clear.compareTo(LocalDate.of(now).iso) >= 0;
  }
}

/// `07 §3.1`, printed there in full and copied here once.
///
/// **THE FILTERS ARE BOUND, NOT INTERPOLATED.** Each of the five is a `?` that
/// is either 0 (the filter is off, so the clause is satisfied by every row) or 1
/// (the clause narrows). One statement whatever the shepherd ticks — string
/// concatenation would make it five statements' worth of shapes and a query plan
/// SQLite has to re-prepare each time.
const String _flockListSql = '''
SELECT e.id, e.tag, e.tag_digits, e.status, e.struck,
       s.seasons_recorded, s.lambings_recorded, s.lambs_born, s.lambs_born_alive,
       s.assisted_lambings,
       EXISTS (SELECT 1 FROM pen_occupancies o
                WHERE o.ewe = e.id AND o.exited_at IS NULL)          AS is_penned,
       -- RULING N1, HALF ONE: clock-free. The latest clear date this ewe carries,
       -- returned as the stored TEXT civil date and compared in Dart, because a
       -- date bound into a `watch()` statement is bound ONCE and never advances.
       (SELECT MAX(w.clear_date) FROM treatments t
          JOIN treatment_withdrawals w ON w.treatment = t.id
         WHERE t.ewe = e.id AND t.voided_at IS NULL
           AND w.kind = 'days')                                      AS latest_clear_date,
       -- RULING N1, HALF TWO: a live treatment with NO withdrawal row for any
       -- target. `03 §5.8`: no row means NotRecorded — which is UNKNOWN, and
       -- never clear. The predicate this replaced was an INNER JOIN, so this ewe
       -- had nothing to join to and silently vanished from *under treatment*.
       EXISTS (SELECT 1 FROM treatments t
                WHERE t.ewe = e.id AND t.voided_at IS NULL
                  AND NOT EXISTS (SELECT 1 FROM treatment_withdrawals w
                                   WHERE w.treatment = t.id))        AS unrecorded_withdrawal,
       -- **THE FILTER PREDICATES AS COLUMNS.** The counts Indelible prints after
       -- each word are then derived in Dart from ONE result set, instead of six
       -- more statements — and every one of them is clock-free, so the same row
       -- answers correctly tomorrow.
       EXISTS (SELECT 1 FROM ewe_seasons es
                WHERE es.ewe = e.id
                  AND es.season = (SELECT current_season FROM app_settings WHERE id = 1)
                  AND es.status = 'barren')                          AS barren,
       (EXISTS (SELECT 1 FROM ewe_seasons es
                 WHERE es.ewe = e.id
                   AND es.season = (SELECT current_season FROM app_settings WHERE id = 1)
                   AND es.status IN ('to_ram','scanned'))
        AND NOT EXISTS (SELECT 1 FROM lambings lg
                         WHERE lg.ewe = e.id
                           AND lg.season = (SELECT current_season FROM app_settings
                                             WHERE id = 1)))         AS not_yet_lambed,
       EXISTS (SELECT 1 FROM lambings lg
                 JOIN lambs lb ON lb.lambing = lg.id
                WHERE lg.ewe = e.id
                GROUP BY lg.id HAVING COUNT(lb.id) >= 3)             AS triplet_bearing,
       EXISTS (SELECT 1 FROM lambing_consistency lc
                 JOIN lambings lg ON lg.id = lc.lambing_id
                WHERE lg.ewe = e.id AND lc.is_mismatched = 1)        AS has_warning
  FROM ewes e
  LEFT JOIN ewe_summaries s ON s.ewe = e.id
 WHERE 1 = 1
   -- **BARREN IS A STORED STATUS, NOT AN ABSENCE OF LAMBINGS** (R42,
   -- `03 §5.3`). It is `ewe_seasons.status = 'barren'` — the shepherd scanned
   -- her and she is not in lamb. T01 wrote this as `lambings_recorded = 0`,
   -- which is a different question with the same answer shape, and made *barren*
   -- and *not yet lambed* the same filter wearing two words. `CONVENTIONS §5.1`
   -- keeps those words apart for exactly this reason.
   AND (? = 0 OR EXISTS (SELECT 1 FROM ewe_seasons es
                          WHERE es.ewe = e.id
                            AND es.season = (SELECT current_season FROM app_settings WHERE id = 1)
                            AND es.status = 'barren'))
   -- **NOT YET LAMBED IS *IN LAMB AND STILL WAITING*.** She is in this season —
   -- there is an `ewe_seasons` row — and no lambing has been written for her in
   -- it. A ewe with no `ewe_seasons` row at all is not in the season and is not
   -- waiting for anything; a barren one has an answer already.
   AND (? = 0 OR (EXISTS (SELECT 1 FROM ewe_seasons es
                           WHERE es.ewe = e.id
                             AND es.season = (SELECT current_season FROM app_settings WHERE id = 1)
                             AND es.status IN ('to_ram','scanned'))
                  AND NOT EXISTS (SELECT 1 FROM lambings lg
                                   WHERE lg.ewe = e.id
                                     AND lg.season = (SELECT current_season FROM app_settings
                                                       WHERE id = 1))))
   AND (? = 0 OR EXISTS (SELECT 1 FROM lambings lg
                           JOIN lambs lb ON lb.lambing = lg.id
                          WHERE lg.ewe = e.id
                          GROUP BY lg.id HAVING COUNT(lb.id) >= 3))
   AND (? = 0 OR EXISTS (SELECT 1 FROM pen_occupancies o
                          WHERE o.ewe = e.id AND o.exited_at IS NULL))
 -- **RULING N2: IN THE FLOCK FIRST, THEN THE ONES WHO LEFT IT.** They are all in
 -- the list — `indelible.md`'s first rule is *nothing is ever removed, only
 -- struck* — and §7.4 puts the removed ones at the bottom under a printed
 -- `STRUCK` line.
 --
 -- **BOTH MECHANISMS, AND THE INDEX SAYS SO.** `idx_ewe_tagdigits` is partial on
 -- `WHERE status = 'active' AND struck = 0`, so a tag is released when the ewe
 -- LEAVES THE FLOCK (culled, sold, dead) *or* when her record is STRUCK. Those
 -- are two different facts about two different things — the animal and the
 -- writing — and §7.4's *"ewe removed from the flock"* is satisfied by either.
 ORDER BY (e.status <> 'active' OR e.struck = 1), e.tag_digits, e.tag;
''';

/// The flock, filtered — **one statement**, streamed.
///
/// `:today` is a `TEXT 'YYYY-MM-DD'` civil date computed in Dart from `appNow()`
/// — SQL-side time is banned (decision #47) and `clear_date` is a TEXT civil date
/// (decision #2), so the comparison is lexicographic and correct only because the
/// format sorts.
Stream<List<FlockRow>> watchFlockList(AppDatabase db, FlockFilters filters) => db
    .customSelect(_flockListSql, variables: _flockVariables(filters), readsFrom: _flockReads(db))
    .watch()
    .map((List<QueryRow> rows) => rows.map(_toFlockRow).toList());

/// The same statement, once. Used by the tests that count statements, and by
/// anything that needs the list without a subscription.
Future<List<FlockRow>> flockList(AppDatabase db, FlockFilters filters) async =>
    (await db
            .customSelect(
              _flockListSql,
              variables: _flockVariables(filters),
              readsFrom: _flockReads(db),
            )
            .get())
        .map(_toFlockRow)
        .toList();

List<Variable<Object>> _flockVariables(FlockFilters f) {
  // COUNTED OFF THE STATEMENT, not remembered: four `?`, one per SQL filter.
  //
  // **NO DATE IS BOUND, AND THAT IS RULING N1.** `underTreatment` is the one
  // filter whose answer depends on today, and `watch()` binds its variables once
  // when the stream is built — so a bound date never advances and a phone left on
  // this screen overnight filters against yesterday. It is applied in Dart
  // instead, against the two clock-free columns.
  return <Variable<Object>>[
    Variable<int>(f.barren ? 1 : 0),
    Variable<int>(f.notYetLambed ? 1 : 0),
    Variable<int>(f.tripletBearing ? 1 : 0),
    Variable<int>(f.currentlyPenned ? 1 : 0),
  ];
}

/// The statement, for the property that asserts no date is in it.
///
/// Exposed rather than duplicated: a test that keeps its own copy of the SQL
/// asserts against the copy.
const String flockListSqlForTest = _flockListSql;

Set<ResultSetImplementation<dynamic, dynamic>> _flockReads(AppDatabase db) =>
    <ResultSetImplementation<dynamic, dynamic>>{
      db.ewes,
      db.eweSeasons,
      db.appSettings,
      db.eweSummaries,
      db.penOccupancies,
      db.treatments,
      db.treatmentWithdrawals,
      db.lambings,
      db.lambs,
    };

FlockRow _toFlockRow(QueryRow r) => FlockRow(
  id: EweId(r.read<int>('id')),
  tag: r.read<String>('tag'),
  tagDigits: r.read<String>('tag_digits'),
  status: r.read<String>('status'),
  struck: r.read<bool>('struck'),
  seasonsRecorded: r.readNullable<int>('seasons_recorded'),
  lambingsRecorded: r.readNullable<int>('lambings_recorded'),
  lambsBorn: r.readNullable<int>('lambs_born'),
  lambsBornAlive: r.readNullable<int>('lambs_born_alive'),
  assistedLambings: r.readNullable<int>('assisted_lambings'),
  isPenned: r.read<int>('is_penned') == 1,
  barren: r.read<int>('barren') == 1,
  notYetLambed: r.read<int>('not_yet_lambed') == 1,
  tripletBearing: r.read<int>('triplet_bearing') == 1,
  latestClearDate: r.readNullable<String>('latest_clear_date'),
  unrecordedWithdrawal: r.read<int>('unrecorded_withdrawal') == 1,
  hasWarning: r.read<int>('has_warning') == 1,
);
