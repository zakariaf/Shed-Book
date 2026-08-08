// lib/features/quick_entry/quick_entry_controller.dart — 02 §10.2.
//
// The read controller for the deck. It ranks in Dart over an in-memory list and
// touches the database never: the whole point of 03 §9.1's index is that a
// keystroke is a filter, not a query.
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shed_book/data/providers.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/domain/tag_match.dart';

@immutable
final class QuickEntryState {
  const QuickEntryState._({
    required this.query,
    required this.index,
    required this.matches,
    required this.selected,
    required this.openLambing,
  });

  factory QuickEntryState({
    String query = '',
    List<TagIndexEntry> index = const <TagIndexEntry>[],
    EweId? selected,
    LambingId? openLambing,
  }) => QuickEntryState._(
    query: query,
    index: index,
    selected: selected,
    openLambing: openLambing,
    // STORED, NEVER A GETTER (`02 §4.4`). A getter that allocates a new List
    // runs the filter once per equality check AND once per build, which is
    // strictly worse than no `.select` at all. Computed once per transition.
    matches: rankTagMatches(index, query),
  );

  final String query;
  final List<TagIndexEntry> index;
  final List<TagIndexEntry> matches;
  final EweId? selected;

  /// The row the slab is writing into, or `null` if the next press must open one.
  ///
  /// **THE ROW STAYS OPEN, AND THAT IS THE PRODUCT** (`indelible.md §8`): *"A
  /// lambing is a forty-minute window, not a form-filling event. You put the
  /// phone in your pocket, deliver the second lamb, take the phone out again, and
  /// press the same slab without reselecting anyone."* Without this field every
  /// press of the slab would begin a new lambing, and a set of triplets would be
  /// filed as three singles.
  ///
  /// **It is an id, never a count and never a copy of the row.** How many strokes
  /// have been pressed is read from `tonightProvider` — the committed rows are the
  /// only honest answer, and a counter held here would be a draft of one.
  final LambingId? openLambing;
}

final class QuickEntryController extends Notifier<QuickEntryState> {
  // NOT IN `state`, AND THAT IS LOAD-BEARING. 2.6.1 preserves the notifier
  // instance across a `build()` re-run; `state` is not preserved. Without these
  // fields, a flock change while the shepherd is mid-tag — a create-on-the-fly
  // two pens over, a cull — wipes the digits they just typed.
  String _query = '';
  EweId? _selected;
  LambingId? _openLambing;

  @override
  QuickEntryState build() {
    final List<TagIndexEntry> index = switch (ref.watch(tagIndexProvider)) {
      AsyncData<List<TagIndexEntry>>(value: final List<TagIndexEntry> v) => v,
      _ => const <TagIndexEntry>[],
    };
    return QuickEntryState(
      query: _query,
      index: index,
      selected: _selected,
      openLambing: _openLambing,
    );
  }

  /// **No debounce, and that is `02 §10.3` rule 8**: debouncing a
  /// sub-millisecond operation is cargo cult, and it puts a visible lag between
  /// the thumb and the digit. The two debounces in this app are on full-text
  /// note search and on free-text fields; a third is a defect.
  void appendDigit(String digit) {
    _query = '$_query$digit';
    state = _rebuilt();
  }

  void backspace() {
    if (_query.isEmpty) {
      return;
    }
    _query = _query.substring(0, _query.length - 1);
    state = _rebuilt();
  }

  /// Clears the selection **and** the digits. The two are one act: "wrong ewe"
  /// at 03:20 means starting the tag again, not editing it.
  void clearSelection() {
    _query = '';
    _selected = null;
    // **THE OPEN ROW CLOSES WITH THE SELECTION**, because "new tag" at 03:20
    // means the animal in front of you is not the one on screen — and a slab
    // press after that must not land another lamb on the previous ewe's row.
    _openLambing = null;
    state = QuickEntryState(index: state.index);
  }

  /// Selecting an animal closes whatever row was open on the previous one.
  void select(EweId ewe) {
    if (_selected != ewe) {
      _openLambing = null;
    }
    _selected = ewe;
    state = _rebuilt();
  }

  /// The row the slab just opened, so the next press adds a lamb to it rather
  /// than starting a second lambing.
  void openedLambing(LambingId lambing) {
    _openLambing = lambing;
    state = _rebuilt();
  }

  QuickEntryState _rebuilt() => QuickEntryState(
    query: _query,
    index: state.index,
    selected: _selected,
    openLambing: _openLambing,
  );
}

/// **keepAlive, not autoDispose**: this is the hub screen, re-entered constantly
/// through a night, and the typed digits must survive a pop back from a screen.
final NotifierProvider<QuickEntryController, QuickEntryState> quickEntryControllerProvider =
    NotifierProvider<QuickEntryController, QuickEntryState>(QuickEntryController.new);

// `quickEntryDeckProvider` MOVED TO `lib/data/providers.dart` AT N18-T02 (R83).
//
// The Foster screen needs the same deck — the pen strip is where a ewe with a
// spare teat is found — and `layer.features` forbids one feature importing
// another. A provider declared in a feature folder is a provider only that
// feature can ever read, which is a constraint on the ARCHITECTURE dressed up as
// a file location.
//
// Quick Entry's two strips are unchanged: they still read it with
// `.select((d) => d.penned)` and `.select((d) => d.recents)`, and R28 is
// untouched. Only the file moved.
