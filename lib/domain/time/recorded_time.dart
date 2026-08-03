import 'package:shed_book/domain/time/instant.dart';

/// How an event time came to be what it is.
///
/// The third member is `userEdited`, key `'edited'` — **not "corrected"**. The
/// word *correct* is reserved for the thing safety rule §12.4 bans: the app
/// silently correcting a user's entry. An edit is the user's own act and is
/// labelled as theirs.
enum TimeSource {
  autoCaptured('auto'),
  userEntered('entered'),
  userEdited('edited');

  const TimeSource(this.key);

  /// **Frozen.** Written to SQLite, to every CSV `time_source` column and to
  /// every JSON backup — and a v1.0 backup is restored by v1.9.
  final String key;

  static TimeSource fromKey(String k) => TimeSource.values.firstWhere(
    (TimeSource s) => s.key == k,
    orElse: () => throw FormatException('Unknown time source', k),
  );

  /// `07 §1.5`'s three strings, verbatim.
  ///
  /// **ON THE ENUM RATHER THAN ON [RecordedTime]**, and that is the whole reason
  /// it moved: the CSV's §12.5 trailer line is built from `TimeSource.values`
  /// and a writer has no instance to ask (`09 §1.3`). A hand-typed list of three
  /// labels in the writer is a list that goes stale the day a fourth source is
  /// added — silently, in the one file nobody re-reads.
  ///
  /// The exhaustive switch does not weaken by moving: a fourth member is still a
  /// compile error here, which is the property `05 §4.1` asks for.
  ///
  /// **Not the export value.** CSV carries the stable [key]; this is for screens
  /// and for the trailer's own prose. Exporting the label in a data column
  /// instead of the key is a named anti-pattern (`05 §4.3`).
  String get label => switch (this) {
    TimeSource.autoCaptured => 'recorded automatically',
    TimeSource.userEntered => 'time entered by you',
    TimeSource.userEdited => 'time edited by you',
  };
}

/// An event time with its provenance attached — safety rule §12.5, held at the
/// **unrepresentable** level rather than by discipline.
///
/// The paired `CHECK` this is designed for lands on eight tables in N07:
/// `CHECK ((time_source = 'edited') = (original_effective IS NOT NULL))`, which
/// makes *"edited, but we lost what it was edited from"* unstorable. This type
/// must never be able to produce that pair, which is why the generative
/// constructor is **private**, there are exactly two factories, there is no
/// `copyWith`, and there is no way to clear [originalEffective].
///
/// It has no clock. [RecordedTime.capture] takes `now`; it does not read it. The
/// single call site that reads is a repository calling `appNow()` **once per
/// mutation**.
///
/// The English in [provenanceLabel] is deliberate and bounded: D4 bans
/// `package:intl` and `AppLocalizations` from `lib/domain/`, and this is one of
/// exactly two documented exceptions (the other is `Disclaimers`). It is correct
/// today because v1 ships `en` only (#108). If a second locale ever ships, the
/// label moves to ARB and the exhaustive-switch test moves with it — not before.
final class RecordedTime {
  const RecordedTime._(this.effective, this.capturedAt, this.originalEffective, this.source);

  /// Auto-captured: `effective` is the moment of the write.
  factory RecordedTime.capture(Instant now) =>
      RecordedTime._(now, now, null, TimeSource.autoCaptured);

  /// The user typed a time at creation — a deferred entry. **It was never
  /// wrong**, which is why this is a different fact from an edit and the two
  /// must not be merged into one "user-supplied" state.
  factory RecordedTime.entered({required Instant effective, required Instant now}) =>
      RecordedTime._(effective, now, null, TimeSource.userEntered);

  /// The value that counts: when the event happened.
  final Instant effective;

  /// When the row was first written. Never changes, never editable — not even
  /// on an edit. It is *when we found out*.
  final Instant capturedAt;

  /// Present only when [source] is [TimeSource.userEdited]: the **first**
  /// effective value ever held, preserved across an unbounded chain of edits.
  final Instant? originalEffective;

  final TimeSource source;

  /// The `??` is the whole feature.
  ///
  /// On the *first* edit [originalEffective] is null and [effective] is the
  /// value being replaced, so the pre-edit value is captured. On every later
  /// edit [originalEffective] is already set and passes through unchanged.
  /// Write `originalEffective = effective` instead and the chain keeps only the
  /// *previous* value: the type then records **that** a time was edited and
  /// loses **what it was edited from**, which makes the §12.5 label true and
  /// uninformative (05 §4.3).
  RecordedTime editedTo(Instant newEffective) => RecordedTime._(
    newEffective,
    capturedAt,
    originalEffective ?? effective,
    TimeSource.userEdited,
  );

  bool get isEdited => source == TimeSource.userEdited;

  /// Never empty: the label is part of the value, by exhaustive switch.
  ///
  /// **No `default:` arm, ever.** Exhaustive over a closed enum, a fourth
  /// `TimeSource` is a compile error here *and* at every call site. Add a
  /// `default:` and the compiler stops helping, silently, and a fourth source
  /// ships with an empty label.
  ///
  /// Screens only. CSV carries the stable [TimeSource.key]; the PDF carries a
  /// dagger and a footer legend; the JSON backup carries all four fields.
  /// Exporting this label instead of the key is a named anti-pattern (05 §4.3).
  /// Delegates to [TimeSource.label] — **one switch, on the enum**. Two copies
  /// of these three strings is two things to keep in step, and the second one
  /// stops being read the moment it stops being wrong.
  String get provenanceLabel => source.label;

  /// The time it takes an entry to reach the app — `capturedAt − effective`, so
  /// a deferred entry has a **positive** lag.
  ///
  /// Only meaningful because [capturedAt] is immutable; it is how spec §15's
  /// *"within five minutes of the event"* is measurable at all. A diagnostics
  /// measure only: never displayed to the user as a judgement (05 §4.3).
  Duration get entryLag => capturedAt.difference(effective);
}
