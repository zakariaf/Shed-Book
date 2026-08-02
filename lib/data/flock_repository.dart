// lib/data/flock_repository.dart — the only reader of the tag index.
//
// READS ONLY, TODAY. `createEwe` — the one verb the free-tier cap can refuse —
// is N14-T01 and lands on this same class with `EntryContext` in its signature
// from its first commit (critique S5). R19: the repository set is twelve and
// closed; there is no QuickEntryRepository.
import 'package:drift/drift.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/domain/tag_match.dart';

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
  /// `LIKE '%12%'` works and cannot use an index. Ranking is
  /// `rankTagMatches`, in Dart, over the list this stream yields.
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
}
