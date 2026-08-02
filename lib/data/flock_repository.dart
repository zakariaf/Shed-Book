// lib/data/flock_repository.dart — the tag index and the Quick Entry deck.
//
// READS ONLY, TODAY. `createEwe` — the one verb the free-tier cap can refuse —
// is N14-T01 and lands on this same class with `EntryContext` in its signature
// from its first commit (critique S5). R19: the repository set is twelve and
// closed; there is no QuickEntryRepository.
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
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/domain/tag_match.dart';
import 'package:shed_book/domain/time/instant.dart';

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
  FlockRepository(this._db);

  final AppDatabase _db;

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
