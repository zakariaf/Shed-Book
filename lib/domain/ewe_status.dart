/// The **animal's** state, as stored in `ewes.status` (`03 §5.2`).
///
/// **NOT `struck`, AND THE TWO ARE NEVER MERGED.** `indelible.md §6` draws the
/// line the schema already draws: a boxed stamp talks about the sheep, an
/// unboxed one talks about the writing. `CULLED` is a sheep that left the flock;
/// `STRUCK` is an entry ruled through. Ruling N2 shipped a single field derived
/// from `status != 'active'` and quietly renamed one fact after another.
///
/// **R41: `ewes.status` is a MUTABLE COLUMN.** There is no `ewe_status_events`
/// table and `setStatus` has no undo verb — not because history is unwanted, but
/// because the previous value is recoverable from the record's own context. A
/// table without the provenance quad has no edit verb; this one is not edited,
/// it is *set*, and the four values are the whole domain.
enum EweStatus {
  active('active'),
  sold('sold'),
  dead('dead'),
  culled('culled');

  const EweStatus(this.key);

  /// **Byte-identical to `03 §5.2`'s `CHECK (status IN (…))`.** A stored enum key
  /// is *"snake_case, ASCII, frozen forever"* (`CONVENTIONS §4.6`) — it is in the
  /// schema, in every CSV column and in every JSON backup, so it outlives any
  /// rename of the Dart member beside it.
  final String key;

  /// Throws rather than falling back. An `orElse` returning [EweStatus.active]
  /// would turn a corrupt value into a plausible one — and *plausible* here means
  /// a culled ewe reappearing in the flock.
  static EweStatus fromKey(String k) => EweStatus.values.firstWhere(
    (EweStatus s) => s.key == k,
    orElse: () => throw FormatException('Unknown ewe status', k),
  );
}
