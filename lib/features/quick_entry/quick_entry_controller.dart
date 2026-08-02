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
  });

  factory QuickEntryState({
    String query = '',
    List<TagIndexEntry> index = const <TagIndexEntry>[],
    EweId? selected,
  }) => QuickEntryState._(
    query: query,
    index: index,
    selected: selected,
    // STORED, NEVER A GETTER (`02 §4.4`). A getter that allocates a new List
    // runs the filter once per equality check AND once per build, which is
    // strictly worse than no `.select` at all. Computed once per transition.
    matches: rankTagMatches(index, query),
  );

  final String query;
  final List<TagIndexEntry> index;
  final List<TagIndexEntry> matches;
  final EweId? selected;
}

final class QuickEntryController extends Notifier<QuickEntryState> {
  // NOT IN `state`, AND THAT IS LOAD-BEARING. 2.6.1 preserves the notifier
  // instance across a `build()` re-run; `state` is not preserved. Without these
  // fields, a flock change while the shepherd is mid-tag — a create-on-the-fly
  // two pens over, a cull — wipes the digits they just typed.
  String _query = '';
  EweId? _selected;

  @override
  QuickEntryState build() {
    final List<TagIndexEntry> index = switch (ref.watch(tagIndexProvider)) {
      AsyncData<List<TagIndexEntry>>(value: final List<TagIndexEntry> v) => v,
      _ => const <TagIndexEntry>[],
    };
    return QuickEntryState(query: _query, index: index, selected: _selected);
  }

  /// **No debounce, and that is `02 §10.3` rule 8**: debouncing a
  /// sub-millisecond operation is cargo cult, and it puts a visible lag between
  /// the thumb and the digit. The two debounces in this app are on full-text
  /// note search and on free-text fields; a third is a defect.
  void appendDigit(String digit) {
    _query = '$_query$digit';
    state = QuickEntryState(query: _query, index: state.index, selected: _selected);
  }

  void backspace() {
    if (_query.isEmpty) {
      return;
    }
    _query = _query.substring(0, _query.length - 1);
    state = QuickEntryState(query: _query, index: state.index, selected: _selected);
  }

  /// Clears the selection **and** the digits. The two are one act: "wrong ewe"
  /// at 03:20 means starting the tag again, not editing it.
  void clearSelection() {
    _query = '';
    _selected = null;
    state = QuickEntryState(index: state.index);
  }

  void select(EweId ewe) {
    _selected = ewe;
    state = QuickEntryState(query: _query, index: state.index, selected: _selected);
  }
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
