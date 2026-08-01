// test/domain/tag_match_test.dart — spec §7.1's partial tag matching.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/domain/tag_match.dart';
import 'package:shed_book/domain/time/instant.dart';

int _next = 1;

TagIndexEntry entry(String tag, {Instant? lastTouched}) => (
  eweId: EweId(_next++),
  tag: tag,
  digits: tag.replaceAll(RegExp(r'\D'), ''),
  lastTouched: lastTouched,
);

void main() {
  test("rankTagMatches('12') returns 12, 128, 412 in that order", () {
    // Spec §7.1's own worked example. exact(0) then prefix(1) then suffix(2);
    // '99' scores 99 and is dropped before the sort.
    final List<TagIndexEntry> all = <TagIndexEntry>[
      entry('412'),
      entry('128'),
      entry('12'),
      entry('99'),
    ];

    expect(rankTagMatches(all, '12').map((TagIndexEntry e) => e.tag).toList(), <String>[
      '12',
      '128',
      '412',
    ]);
  });

  test('an infix match ranks below a suffix match', () {
    final List<TagIndexEntry> all = <TagIndexEntry>[entry('4125'), entry('412')];

    expect(rankTagMatches(all, '12').map((TagIndexEntry e) => e.tag).toList(), <String>[
      '412',
      '4125',
    ]);
  });

  test('a non-matching tag is dropped, not sorted last', () {
    final List<TagIndexEntry> all = <TagIndexEntry>[entry('99'), entry('12')];

    // Dropped matters more than ordered: at 03:20 the strip shows a handful of
    // tiles, and a non-match sorted last still occupies one.
    expect(rankTagMatches(all, '12'), hasLength(1));
  });

  test('within a band the most-recently-touched comes first', () {
    final Instant older = Instant.fromDateTime(DateTime.utc(2026, 3, 1));
    final Instant newer = Instant.fromDateTime(DateTime.utc(2026, 3, 4));
    final List<TagIndexEntry> all = <TagIndexEntry>[
      entry('120', lastTouched: older),
      entry('129', lastTouched: newer),
    ];

    expect(rankTagMatches(all, '12').map((TagIndexEntry e) => e.tag).toList(), <String>[
      '129',
      '120',
    ]);
  });

  test('a null lastTouched sorts after a non-null one', () {
    final List<TagIndexEntry> all = <TagIndexEntry>[
      entry('120'),
      entry('129', lastTouched: Instant.fromDateTime(DateTime.utc(2026, 3, 1))),
    ];

    expect(rankTagMatches(all, '12').map((TagIndexEntry e) => e.tag).toList(), <String>[
      '129',
      '120',
    ]);
  });

  test('within a band with no lastTouched, the shorter digit string comes first', () {
    final List<TagIndexEntry> all = <TagIndexEntry>[entry('12345'), entry('123')];

    expect(rankTagMatches(all, '12').map((TagIndexEntry e) => e.tag).toList(), <String>[
      '123',
      '12345',
    ]);
  });

  test('a query with no digits returns an empty list', () {
    // Not everything. An empty query must not dump the whole flock into a strip
    // at 03:20.
    final List<TagIndexEntry> all = <TagIndexEntry>[entry('12'), entry('412')];

    expect(rankTagMatches(all, 'abc'), isEmpty);
    expect(rankTagMatches(all, ''), isEmpty);
    expect(rankTagMatches(all, '  '), isEmpty);
  });

  test('a query of "0412" does not match "412"', () {
    // The projection RANKS; it never decides identity. Uniqueness is on `tag` as
    // typed, not on tag_digits — making the projection unique would refuse
    // '0412' because '412' exists, which is the app deciding two tags are the
    // same animal.
    final List<TagIndexEntry> all = <TagIndexEntry>[entry('412')];

    expect(rankTagMatches(all, '0412'), isEmpty);
    expect(rankTagMatches(all, '412'), hasLength(1));
  });

  test('ranking is synchronous', () {
    // The call site is not async and nothing here awaits. Every keypad tap
    // re-filters inside the same frame — a SQL round trip through drift's
    // background isolate lands one or two frames late, and a debounced keypad is
    // a keypad that feels broken.
    final List<TagIndexEntry> all = <TagIndexEntry>[entry('12')];
    final List<TagIndexEntry> result = rankTagMatches(all, '12');

    expect(result, isA<List<TagIndexEntry>>());
    expect(result, isNot(isA<Future<dynamic>>()));
  });

  test('the input list is not reordered in place', () {
    // rankTagMatches is called on every tap against the SAME cached list from
    // tagIndexProvider. Sorting that list in place would leave the cache in a
    // query-dependent order and make the next tap's tie-breaks depend on the
    // last one.
    final List<TagIndexEntry> all = <TagIndexEntry>[entry('412'), entry('12')];
    final List<String> before = all.map((TagIndexEntry e) => e.tag).toList();

    rankTagMatches(all, '12');

    expect(all.map((TagIndexEntry e) => e.tag).toList(), before);
  });
}
