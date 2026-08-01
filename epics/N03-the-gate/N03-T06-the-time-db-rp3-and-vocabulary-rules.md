# N03-T06 — The `time`, `db`, `rp3` and vocabulary rules

| | |
|---|---|
| **Epic** | [N03 — The gate](epic.md) · `00-README` §9 step 1 |
| **Task** | 6 of 7 |
| **Depends on** | N03-T05 |
| **Commit** | one commit · `feat: the time, db, rp3 and vocabulary rules` |

## 1. Why this task exists

`time.wall_clock` — `DateTime.now(` may appear in exactly one non-generated file under
`lib/`. `db.custom_statement` — no `customStatement(` outside `lib/core/db/`. `rp3.*` — every
Riverpod-3-only API is a gate failure, because `flutter_riverpod 2.6.1` is pinned exactly and the
compile error it would otherwise produce arrives too late to be cheap. `copy.banned_word` — the
`CLAUDE.md` ban list and the one-word-per-concept vocabulary, applied to source, ARB and commit
messages.

The `rp3.*` family is the one worth arguing for out loud. `13 §2.5`: *"every tutorial published
after 2025 shows the 3.x form, and the analyzer will not save you — several of them **compile**
against 2.6.1 and mean something else."* `ProviderContainer.test`, `valueOrNull`, `ref.mutate(` and
`retry:` are not compile errors that stop you; they are spellings that resolve to something wrong,
or to nothing, at 03:20 in March.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/02-state-di-navigation.md` | §2.4 | the Riverpod-3 CI rules, with the correct 2.6.1 spelling for each |
| `docs/engineering/13-build-ci-release.md` | §2.5 | the count — **thirteen** `rp3.*` rows — and why it is a grep and not a review item |
| `docs/engineering/01-architecture.md` | §3.1 rule 8, §3.2 | the single-writer rule and the `time.*`, `db.*`, `stream.*`, `stat.*` rows already printed |
| `docs/engineering/CONVENTIONS.md` | §4.7 | the canonical ids, and 04's `snake_case` ids renamed — two of which must be **deleted**, not renamed |
| `docs/engineering/CONVENTIONS.md` | §5.1–§5.4 | the vocabulary, the absolutely-banned words and the copy conventions |
| `docs/engineering/10-accessibility-and-i18n.md` | §10 | the ARB reader amendment the driver needs, and the three `copy.*` rows that depend on it |
| `docs/research/00-tech-decisions.md` | §2 #18, #46, #47 | the Riverpod-3 ban, the one clock, and why SQL-side time is banned but `strftime` is not |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-conventions` | §5's vocabulary is the source of the banned-word list |
| `shed-accessibility-and-copy` | the ARB half of the copy rules is its subject |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/policy/gate_rules_test.dart`
- **Test** — `'time.wall_clock exits 1 on a second DateTime.now( call site and copy.banned_word exits 1 on the word draft'`
- **Why it is red today** — `DateTime.now(` may be called anywhere and `draft` may be typed anywhere.

```bash
fvm flutter test test/policy/gate_rules_test.dart   # expect: failing, for the reason above
```

The test title is the backlog's anchor and stays as written. The canonical ids it asserts on are
`CONVENTIONS` §4.7's: **`time.dart_clock`**, not `time.wall_clock` — §4.7 says the row *"already
exists — do not add a duplicate"* — and **`db.raw_statement`**, not `db.custom_statement`. The
assertion, spelled out: plant `lib/core/time/app_clock.dart` (which is exempt) and
`lib/data/lambing_repository.dart` (which is not), both containing `DateTime.now(`, and assert
exactly **one** violation, naming the repository. Then plant a file containing the word `draft` and
assert one `copy.banned_word` violation.

**Green.** The minimum code that passes, and nothing beyond it — four rule families, each planted and watched. The vocabulary rule reads its word list from
one place, so adding a banned word is a one-line change.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in the order you touch them

This task touches no schema, domain, data, controller or UI layer. It is the first task in the epic
that **reaches the ARB** — not to author a string, but because the vocabulary rules have nothing to
run against until the walker can read `lib/l10n/app_en.arb`. Say both things in the commit message
(`00-README` §8).

| # | File | What changes, and why |
|---|---|---|
| 1 | `tool/check_policy.dart` | The `time.*`, `db.*`, `rp3.*`, `stream.*` and `stat.*` rows join `_bannedText`; the vocabulary rows join `_bannedPattern`; **the walker gains a second reader for `lib/l10n/*.arb`** (`10 §10`); `kBannedWords` becomes the one place a banned word is written down |
| 2 | `test/policy/gate_rules_test.dart` | One planting case per row, the exemption case for `app_clock.dart`, the ARB reader's cases, and the four false-positive cases in §5.3 that decide the vocabulary rule's shape |

No allowlist line is added. The `time.dart_clock` exemption for `app_clock.dart` is already there
from N03-T01 — this is the commit where it becomes live, and the first time it can be proved to
work.

### 5.2 The signatures

**`time.*` — six rows.** One clock (decision #46, R23), no SQL-side time (#47):

```dart
('time.dart_clock',  'DateTime.now(',     '', 'use appNow() — #46, R23'),
('time.sql_now_1',   "date('now')",       'lib/', 'no SQL-side time — #47'),
('time.sql_now_2',   "datetime('now')",   'lib/', 'no SQL-side time — #47'),
('time.sql_now_3',   'CURRENT_TIMESTAMP', 'lib/', 'no SQL-side time — #47'),
('time.sql_now_4',   'CURRENT_DATE',      'lib/', 'no SQL-side time — #47'),
('time.sql_now_5',   'CURRENT_TIME',      'lib/', 'no SQL-side time — #47'),
```

**`db.*` — the single-writer text half, plus the stream rows that belong with it:**

```dart
('db.raw_statement', 'customStatement(', 'lib/data/', 'bypasses stream tracking — rule 8'),
('db.save_verb',     RegExp(r'\bsave\w*\('), 'lib/data/',
    'repositories are event verbs; there is no save(aggregate) — CONVENTIONS §4.7'),
('stream.combine',    'combineLatest',   'lib/', 'torn state across drift streams — #12'),
('stream.invalidate', 'ref.invalidate(', 'lib/',
    'drift tracks tables; manual invalidation is a stale read — #12'),
('stat.zero_default', '?? 0', 'lib/features/season/', 'unknown is not zero — #58'),
('stat.zero_default2','?? 0', 'lib/features/flock/',  'unknown is not zero — #58'),
```

**`rp3.*` — thirteen rows** (`13 §2.5` fixes the count and `02 §2.4` fixes the spellings). Scope is
`''` — both roots — except `rp3.overrides`, which is `lib/` only:

`rp3.retry` · `rp3.container_test` · `rp3.tester_container` (`test/` only) · `rp3.is_auto_dispose` ·
`rp3.mutation` · `rp3.value_or_null` · `rp3.ref_mounted` · `rp3.observer_context` ·
`rp3.state_provider` · `rp3.state_notifier` · `rp3.annotation` · `rp3.hooks` · `rp3.overrides`

**The vocabulary rows.** One list, one place — adding a banned word is a one-line change:

```dart
/// CONVENTIONS §5.3 and CLAUDE.md, verbatim. The ONLY place a banned word is
/// written down; both vocabulary rows build their patterns from it.
const kBannedWords = <String>[
  'draft', 'isDirty', 'commit(', 'submit(', 'synchronized', 'offline-first',
  'flags', /* … */
];

('copy.banned_word', /* built from kBannedWords */ 'lib/', 'CONVENTIONS §5.3'),
('copy.tier3_claim', /* the four banned public phrases */ '',
    'only decision-record §3.1 wording is permitted'),
```

**The ARB reader**, which `10 §10` requires and `01 §3.2`'s driver does not have:

```dart
/// 10 §10(a): the walker skips every file that does not end .dart, so the ARB
/// rows and 05 §7.3's ContentPolicy scan have nothing to run against. This is a
/// SEPARATE reader from the Dart one: JSON has no adjacent-string-literal
/// problem, so 05's join-before-matching rule applies to the .dart half only and
/// must not be copied here, where it would concatenate unrelated messages.
Iterable<(String key, String value)> _arbMessages(String path);
```

### 5.3 The details that are easy to get wrong

- **A bare `sync` ban is the mistake this project already documented once.** `CONVENTIONS` §5.3 bans
  the word `sync`; a substring row for it fires on `existsSync(`, `readAsLinesSync()`,
  `writeAsStringSync(`, `listSync(`, `asyncMap`, `Future.sync` and the `sync*` generator keyword —
  which is to say, on the gate's own driver. `01 §3.3` names the pattern exactly: *"Banning bare
  `strftime` or `datetime` — they false-positive on legitimate SQL and get weakened, which is why
  decision #47 excludes them."* Same failure, same remedy: over `.dart` sources, ban the spellings
  that **cannot** false-positive — `isDirty`, `Draft`, `commit(`, `submit(`, `\bflags\b`,
  `synchronized`, `offline-first` — and run the full §5.3 list, `sync` included, over the **ARB and
  prose** files, where `existsSync` cannot appear. Two scopes, one word list.
- **`copy.banned_word` must be case-sensitive and word-anchored, or `draft` eats `Draggable`.** It
  does not — `Draggable` has no `draft` in it — but `pending` eats nothing while `\bpending\b`
  correctly spares `pendingRequests`, and `flags` would eat `flagsFor` without the boundary. Build
  each pattern as `RegExp(r'\b' + word + r'\b')` and hand-write the three that are not bare words
  (`commit(`, `submit(`, `offline-first`).
- **`Error` as a failure-type name is a *class-declaration* rule, not a word ban.** `RegExp(r'class\s+\w*Error\b')`.
  A bare `Error` ban fires on `StateError`, `ArgumentError`, `FlutterError.onError` and
  `ErrorWidget.builder`, all of which are the framework's and all of which the app legitimately
  names — `01 §5.5` installs `FlutterError.onError` in `main()`.
- **`db.save_verb` is `save\w*\(` scoped `lib/data/` and it is not the same rule as the word ban.**
  `CONVENTIONS` §4.7 adds it as its own row. It is what makes *"there is no `save(aggregate)`
  method anywhere, so there is no aggregate parameter in which a draft could be deferred"*
  (`00-README` §2.4) mechanical rather than aspirational. It also fires on `saveAs(`, `savePoint(`
  and `savedAt`, which is why it is scoped to `lib/data/` and no wider.
- **Delete, do not rename, two of 04's ids.** `CONVENTIONS` §4.7 R54: `no_sql_side_time` maps onto
  `time.sql_now_*`, which already exists, and `single_clock` maps onto `time.dart_clock`, which
  already exists. *"A duplicate rule is a rule that gets weakened twice."* The other ten of 04's ids
  are renames and they land with the migration harness in N08, not here.
- **`time.dart_clock` is scoped to both roots, and `''` is how you say that.** The tuple carries one
  path prefix, and `12 §5` says the rule *"scans `test/` too"* — a test that reads the real clock
  depends on the day it runs. `_roots` is `['lib', 'test']` and `tool/` is never walked, so an empty
  prefix means "both roots and nothing else". Writing two rows with the same id instead is the
  duplicate R54 forbids; writing one row scoped `lib/` silently leaves the whole test tier reading
  wall-clock time.
- **The exemption is a file that does not exist yet.** `lib/core/time/app_clock.dart` arrives in
  N04-T05 or thereabouts. The exemption line is inert until then and the rule is live from this
  commit, which means the *first* `DateTime.now(` written anywhere in the project has to be in that
  file. That is the intended order and it is worth saying in the commit message.
- **`Timer.periodic(` is already banned** by `net.sync_timer` from N03-T03, so do not add a `time.*`
  row for it. The one ticker uses `Future.delayed` precisely so the rule needs no exemption (#66).
- **`rp3.overrides` is `lib/` only and every other `rp3.*` row is both roots.** Overrides are a test
  mechanism — `02 §5.2` says production has zero of them — so a row scoped to both roots would fire
  on `test/support/harness.dart`, which is built entirely out of `overrideWith`. Get this one wrong
  and the harness is unwritable in N12.
- **`02 §2.4`'s table has six rows that are not `rp3.*`.** `go_router` / `GoRoute` / `context.go(`,
  the restoration family, `WillPopScope`, `pushNamed(` / `onGenerateRoute`, and the `.select(`
  fresh-collection heuristic are navigation and read-path rules. `13 §2.5` counts thirteen and means
  the Riverpod ones. Landing the other six needs a namespace `CONVENTIONS` §4.7 does not list — that
  is a §6 ruling, not a decision at the keyboard. Leave them, and say in the commit message that the
  count is thirteen and why.
- **The ARB is JSON, and its `@`-prefixed entries are metadata.** `_arbMessages` yields only
  non-`@` keys' values. Scan the metadata and every `description` — which `10 §8` requires on every
  string — becomes a false positive on its own explanatory prose.
- **The commit-message half of the vocabulary rule is not the gate's.** The gate reads files. `01
  §3.3` offers a `.git/hooks/pre-push` one-liner, which is local-only and optional; a `commit-msg`
  hook is the same shape. Neither is a gate, neither runs in CI, and the honest mechanism for the
  message is the Definition of Done plus `/shed-code-review`. Do not claim in the commit message
  that the gate checks commit messages.
- **The two `copy.*` content rules are deliberately absent.** `copy.vet_advice` and
  `copy.disclaimer_retyped` need `ContentPolicy` and `Disclaimers`, which are N06-T09 — and `12 §10`
  is explicit that the allowlist must be *"keyed by `Disclaimers.*` rather than by a literal"*, so
  writing them now against a literal is worse than not writing them. The header comment already says
  the table is not closed (N03-T01); this commit is where a reader would otherwise assume it now is.

### 5.4 The full test set

| Case | Plant | Expect |
|---|---|---|
| the anchor, half one | `lib/core/time/app_clock.dart` and `lib/data/lambing_repository.dart` both containing `DateTime.now(` | **one** violation, id `time.dart_clock`, naming the repository — the exemption is proved by the file that does *not* appear |
| the anchor, half two | a file containing the word `draft` | one violation, id `copy.banned_word` |
| `time.sql_now_*`, five rows | one file per spelling: `date('now')`, `datetime('now')`, `CURRENT_TIMESTAMP`, `CURRENT_DATE`, `CURRENT_TIME` | five violations, five distinct ids |
| `time.dart_clock` under `test/` | `test/data/lambing_repository_test.dart` containing `DateTime.now(` | one violation — the empty scope reaches the test tier |
| `db.raw_statement` | `lib/data/pen_repository.dart` containing `customStatement(` | one violation |
| `db.raw_statement`, the legal site | `lib/core/db/queries.drift.dart` and `lib/core/db/connection.dart` containing `customStatement(` | zero violations — generated, and outside the scope prefix |
| `db.save_verb` | `lib/data/flock_repository.dart` containing `Future<void> saveEwe(` | one violation |
| every `rp3.*` row, table-driven | one snippet per row from `02 §2.4` | one violation per row, each naming its own id and the 2.6.1 spelling to use instead |
| `rp3.overrides` scope | `test/support/harness.dart` full of `overrideWith` | **zero** violations; the same text under `lib/` gives one |
| `stream.combine`, `stream.invalidate` | one file each | one violation each |
| `stat.zero_default` | `lib/features/season/season_controller.dart` containing `?? 0` | one violation |
| `stat.zero_default`, out of scope | `lib/features/pens/pen_board_controller.dart` containing `?? 0` | zero violations — only the two statistic surfaces are scoped |
| **false positive** — `existsSync` | `lib/data/media_store.dart` containing `existsSync(`, `readAsStringSync(`, `listSync(` | **zero** violations. If this case is red the vocabulary rule is substring-matching `sync` and will be deleted by whoever meets it |
| **false positive** — `sync*` | a file containing `Iterable<int> f() sync* { … }` | zero violations |
| **false positive** — framework error types | a file containing `StateError`, `ArgumentError`, `FlutterError.onError` | zero violations; `class LambingError` gives one |
| **false positive** — `pendingRequests` | a file containing `pendingRequests` | zero violations; the bare word `pending` gives one |
| ARB — a banned word in a message value | `lib/l10n/app_en.arb` with a message containing `draft` | one violation, naming the ARB key |
| ARB — the same word in a `description` | the `@`-prefixed metadata for that key | zero violations |
| ARB — the full §5.3 list applies | an ARB message containing `sync` | one violation — the wider list runs where `existsSync` cannot appear |
| `copy.tier3_claim` | a file containing *"your data never leaves your phone"* | one violation. The permitted wording from decision-record §3.1 in the same file gives zero |
| **absent by design** | — | `policyRuleIds` contains no `copy.vet_advice` and no `copy.disclaimer_retyped`; a comment names N06-T09 |

Nothing here reads a clock — the rules are about `DateTime.now(` as *text* — so there is no
`test/domain/uk_zone/` case. The first ambiguous-hour case in the project is N04's, and it exists
because of the row this task lands.

## 6. Constraints that bind this task

- **One clock.** `appNow()` in `lib/core/time/app_clock.dart` is the only wall-clock reader in the app (R23, decision #46), and `package:clock` is banned in `lib/domain/` outright (R24) — a domain function that needs the current instant takes it as a parameter. This row is what makes both true; without it, `withClock` in a test is bypassable and every DST assertion in N04 and N05 rests on discipline.
- **`flutter_riverpod: 2.6.1`, pinned exactly.** Riverpod 3.x cannot resolve alongside `drift_dev`. Every Riverpod-3-only API is banned from the codebase *and* from the docs. Thirteen rows, `13 §2.5`.
- **Accessibility and the ARB, authored here** — every string in `app_en.arb` with a `description`, every element a `semanticLabel` and a `<screen>.<element>` key, every heading a `headingLevel:`. There is no later sweep that adds them; N33 only verifies. This task authors no string; it builds the reader that makes the ARB scannable at all, which is `10 §10`'s named amendment to `01 §3.2`.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name. The gate cannot read a commit message; the Definition of Done and `/shed-code-review` are what hold that half.

## 7. Definition of Done

- [ ] `'time.wall_clock exits 1 on a second DateTime.now( call site and copy.banned_word exits 1 on the word draft'` passes, and was seen to fail first for the stated reason
- [ ] a second `DateTime.now(` call site exits 1
- [ ] every Riverpod-3-only API name in the ban list exits 1
- [ ] `draft`, `isDirty`, `save()`, `commit()`, `submit()`, `sync` and the rest exit 1
- [ ] the two `copy.*` **content** rules are deliberately absent and the comment says they arrive in N06-T09
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
dart tool/check_policy.dart
fvm flutter test test/policy/gate_rules_test.dart
```

Then watch the clock rule and the vocabulary rule fire, and confirm the two false positives that
would kill them do not:

```bash
mkdir -p lib/data
printf "final t = DateTime.now();\nvoid saveEwe() {}\n" > lib/data/_plant.dart
dart tool/check_policy.dart ; echo "exit=$?"   # time.dart_clock + db.save_verb, exit=1
printf "final f = File('x').existsSync();\n"       > lib/data/_plant.dart
dart tool/check_policy.dart ; echo "exit=$?"   # policy ok, exit=0 — the sync trap
rm lib/data/_plant.dart
make check
make test
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat: the time, db, rp3 and vocabulary rules`
