import 'package:drift/drift.dart';
import 'package:shed_book/core/db/converters.dart';

/// Carried by every table whose rows cross the export boundary.
///
/// **NOT** carried by caches (`ewe_touches`, `ewe_summaries`, `search_docs`), by
/// singletons (`app_settings`, `entitlements`), or by pure join tables — a cache
/// has no identity to survive a round trip, and a singleton has nothing to
/// distinguish.
mixin Identified on Table {
  /// Joins and foreign keys. Device-local. **NEVER exported** (03 §3): a row id
  /// means nothing on another phone, and exporting one invites a restore that
  /// tries to honour it.
  late final id = integer().autoIncrement()();

  /// UUID v7. The identity that survives export → re-import.
  late final uid = text().withLength(min: 36, max: 36).unique()();

  /// Instants: UTC epoch millis (§4).
  late final createdAt = integer().map(const InstantConverter())();

  late final updatedAt = integer().map(const InstantConverter())();
}

/// Indelible Rule 1 — *nothing is ever removed, only struck*.
///
/// **A SECOND mixin, applied beside [Identified] and never instead of it**
/// (R79), over the **twelve** tables where a strike is a thing a shepherd would
/// say out loud: `Seasons`, `Ewes`, `EweSeasons`, `Lambings`, `Lambs`,
/// `FosterEvents`, `CareEvents`, `EweObservations`, `Pens`, `PenOccupancies`,
/// `Reminders`, `Notes`.
///
/// Deliberately **not** carried by four `Identified` tables, because the act
/// already has a home: `Treatments` has `voided_at` (#69 — a treatment is
/// *voided*, not struck, because it may already have been printed into a
/// medicine book handed to a vet); `TreatmentWithdrawals` is voided by voiding
/// its treatment; `VocabTerms` labels are edited, not struck; `MediaAssets`
/// removal is 04 §4.8's `.trash/` path.
///
/// **The default every reader follows: struck rows are excluded from every count
/// and included in every history and every export.** A `WHERE struck = 0` in an
/// export query is a defect — Indelible screen 11 requires every CSV to carry
/// both columns and to include every struck row, marked.
///
/// Every table carrying this adds both constraints, the same paired-nullable
/// idiom `treatment_withdrawals` uses:
///
/// ```
/// CHECK (struck IN (0,1))
/// CHECK ((struck = 1) = (struck_at IS NOT NULL))
/// ```
mixin Struckable on Table {
  /// Under `STRICT` there is no `BOOLEAN`, hence the first CHECK above.
  ///
  /// The default is **not** a violation of 03 §2 point 5: that rule bans
  /// defaults on columns that could encode veterinary advice — `days`, `ease`,
  /// `status` — and an unstruck row is the only thing a new row can be.
  late final struck = boolean().withDefault(const Constant(false))();

  /// An [Instant], not a civil date: a strike happened at a moment, and that is
  /// what makes one recorded at 01:30 on the clocks-back night unambiguous.
  late final struckAt = integer().map(const InstantConverter()).nullable()();
}
