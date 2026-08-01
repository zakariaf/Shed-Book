import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/domain/time/instant.dart';

/// One row of the in-memory tag index.
///
/// A **record typedef, not a class** (CONVENTIONS §2.14). Records have
/// structural equality for free, which is what lets `tagIndexProvider` use
/// `.distinct()`; a hand-written class would need `==` and would silently defeat
/// it the day somebody forgot.
///
/// [digits] is `tag_digits`, a **projection**. Rank with it; **never display it,
/// and never compare identity with it**.
typedef TagIndexEntry = ({EweId eweId, String tag, String digits, Instant? lastTouched});

/// Spec §7.1's partial tag matching: typing `12` surfaces 12, then 128, then 412.
///
/// **Pure and synchronous.** Called on every keypad tap, it must return inside
/// the same frame — no `await`, no debounce, and no SQL round trip through
/// drift's background isolate, which lands one or two frames late and shows an
/// empty list in between.
///
/// **No FTS5, no trigram tokenizer, no `LIKE`.** The spec's own example is a
/// two-character infix query, which is FTS5's documented counter-example:
/// *"substrings consisting of fewer than 3 unicode characters do not match any
/// rows"*. `LIKE '%12%'` works and cannot use an index. At 400 ewes — about
/// 16 KB — none of it matters. The 200 ms debounce belongs to note search and
/// nowhere else; a debounced keypad is a keypad that feels broken.
///
/// It also gives ranking for free, and ranking is the actual problem: a raw
/// `LIKE` returns `128` before `12` in rowid order.
///
/// **Scope, so a test does not aim at the wrong layer.** [all] is fed by
/// `tagIndexProvider`, a drift `watch()` over the ewes table **filtered to
/// ACTIVE animals** (R26, and the owner's tag ruling — a culled 412 releases the
/// tag). That filtering is the provider's, not this function's.
List<TagIndexEntry> rankTagMatches(List<TagIndexEntry> all, String query) {
  final String q = query.replaceAll(RegExp(r'\D'), '');
  // `const []`, never everything. `'abc'` projects to the empty string, and an
  // empty query must not dump the whole flock into a strip at 03:20.
  if (q.isEmpty) {
    return const <TagIndexEntry>[];
  }

  int score(TagIndexEntry e) {
    final String d = e.digits;
    if (d == q) {
      return 0; // exact
    }
    if (d.startsWith(q)) {
      return 1; // prefix
    }
    if (d.endsWith(q)) {
      return 2; // suffix
    }
    if (d.contains(q)) {
      return 3; // infix
    }
    return 99; // dropped before the sort, never sorted last
  }

  // A new list, so the caller's cached index is never reordered in place: the
  // same list is ranked on every tap, and sorting it would make each tap's
  // tie-breaks depend on the last one.
  return <TagIndexEntry>[
    for (final TagIndexEntry e in all)
      if (score(e) < 99) e,
  ]..sort((TagIndexEntry a, TagIndexEntry b) {
    final int s = score(a).compareTo(score(b));
    if (s != 0) {
      return s;
    }
    final Instant? ra = a.lastTouched;
    final Instant? rb = b.lastTouched;
    if (ra != null && rb != null) {
      return rb.compareTo(ra); // most-recently-touched first
    }
    if (ra != null) {
      return -1;
    }
    if (rb != null) {
      return 1;
    }
    return a.digits.length.compareTo(b.digits.length); // then shorter first
  });
}
