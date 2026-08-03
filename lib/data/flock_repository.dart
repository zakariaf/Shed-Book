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
    required this.seasonsRecorded,
    required this.lambingsRecorded,
    required this.lambsBorn,
    required this.lambsBornAlive,
    required this.assistedLambings,
    required this.isPenned,
    required this.underWithdrawal,
    required this.hasWarning,
  });

  final EweId id;
  final String tag;
  final String tagDigits;

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
  final bool underWithdrawal;

  /// Read from the `lambing_consistency` VIEW, which recomputes on read.
  ///
  /// **There is no `warning_count` column and there never will be** (decision
  /// #54): a warning cannot be persisted because there is nowhere to persist it
  /// that survives the record changing underneath it.
  final bool hasWarning;
}

/// `07 §3.1`, printed there in full and copied here once.
///
/// **THE FILTERS ARE BOUND, NOT INTERPOLATED.** Each of the five is a `?` that
/// is either 0 (the filter is off, so the clause is satisfied by every row) or 1
/// (the clause narrows). One statement whatever the shepherd ticks — string
/// concatenation would make it five statements' worth of shapes and a query plan
/// SQLite has to re-prepare each time.
const String _flockListSql = '''
SELECT e.id, e.tag, e.tag_digits, e.status,
       s.seasons_recorded, s.lambings_recorded, s.lambs_born, s.lambs_born_alive,
       s.assisted_lambings,
       EXISTS (SELECT 1 FROM pen_occupancies o
                WHERE o.ewe = e.id AND o.exited_at IS NULL)          AS is_penned,
       EXISTS (SELECT 1 FROM treatments t
                 JOIN treatment_withdrawals w ON w.treatment = t.id
                WHERE t.ewe = e.id AND t.voided_at IS NULL
                  AND w.kind = 'days' AND w.clear_date >= ?)         AS under_withdrawal,
       EXISTS (SELECT 1 FROM lambing_consistency lc
                 JOIN lambings lg ON lg.id = lc.lambing_id
                WHERE lg.ewe = e.id AND lc.is_mismatched = 1)        AS has_warning
  FROM ewes e
  LEFT JOIN ewe_summaries s ON s.ewe = e.id
 WHERE e.status = 'active'
   AND (? = 0 OR COALESCE(s.lambings_recorded, 0) = 0)
   AND (? = 0 OR NOT EXISTS (SELECT 1 FROM lambings lg WHERE lg.ewe = e.id))
   AND (? = 0 OR EXISTS (SELECT 1 FROM lambings lg
                           JOIN lambs lb ON lb.lambing = lg.id
                          WHERE lg.ewe = e.id
                          GROUP BY lg.id HAVING COUNT(lb.id) >= 3))
   AND (? = 0 OR EXISTS (SELECT 1 FROM pen_occupancies o
                          WHERE o.ewe = e.id AND o.exited_at IS NULL))
   AND (? = 0 OR EXISTS (SELECT 1 FROM treatments t
                           JOIN treatment_withdrawals w ON w.treatment = t.id
                          WHERE t.ewe = e.id AND t.voided_at IS NULL
                            AND w.kind = 'days' AND w.clear_date >= ?))
 ORDER BY e.tag_digits, e.tag;
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
  // COUNTED OFF THE STATEMENT, not remembered: one `?` for the withdrawal date
  // in the SELECT list, then the five filter flags, then the withdrawal date
  // again inside the fifth filter's subquery. Seven.
  final String today = LocalDate.of(appNow()).iso;
  return <Variable<Object>>[
    Variable<String>(today),
    Variable<int>(f.barren ? 1 : 0),
    Variable<int>(f.notYetLambed ? 1 : 0),
    Variable<int>(f.tripletBearing ? 1 : 0),
    Variable<int>(f.currentlyPenned ? 1 : 0),
    Variable<int>(f.underTreatment ? 1 : 0),
    Variable<String>(today),
  ];
}

Set<ResultSetImplementation<dynamic, dynamic>> _flockReads(AppDatabase db) =>
    <ResultSetImplementation<dynamic, dynamic>>{
      db.ewes,
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
  seasonsRecorded: r.readNullable<int>('seasons_recorded'),
  lambingsRecorded: r.readNullable<int>('lambings_recorded'),
  lambsBorn: r.readNullable<int>('lambs_born'),
  lambsBornAlive: r.readNullable<int>('lambs_born_alive'),
  assistedLambings: r.readNullable<int>('assisted_lambings'),
  isPenned: r.read<int>('is_penned') == 1,
  underWithdrawal: r.read<int>('under_withdrawal') == 1,
  hasWarning: r.read<int>('has_warning') == 1,
);
