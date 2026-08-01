# N03-T03 — The `net.*` rules — G3

| | |
|---|---|
| **Epic** | [N03 — The gate](epic.md) · `00-README` §9 step 1 |
| **Task** | 3 of 7 |
| **Depends on** | N03-T02 |
| **Commit** | one commit · `feat: the net.* rules — G3, the import scan` |

## 1. Why this task exists

The import scan: no `dart:io` `HttpClient`, no `package:http`, no socket, no
`WebSocket`, no `Uri.parse` reaching a scheme we do not ship, anywhere under `lib/`. **And the
recorded reason a *"no `http` in `pubspec.lock`"* rule is unsatisfiable and must never be written** —
`http 1.6.0` sits on two load-bearing regular edges, so such a rule would be permanently red and would
be deleted by the first person who met it.

G3 is one of the three mechanical gates behind the product's central public claim. The permitted
wording is *"the app itself cannot connect to anything"*; G1 proves the Android build ships no
`INTERNET` permission, G2 proves no package entered the graph unreviewed, and **G3 is the only one
that proves our own source cannot reach a network API**. Tiers 1 and 2 of the offline claim are
mechanically held the moment this commit lands; tier 3 is never claimed, because the share sheet and
the system photo picker are other processes.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/research/00-tech-decisions.md` | §3.1 | the three tiers and the only permitted public wording, verbatim |
| `docs/research/00-tech-decisions.md` | §3.2, §3.4 | G3's definition, and the two regular `http` edges that make a lockfile rule unsatisfiable |
| `docs/engineering/13-build-ci-release.md` | §2.5, §2.8 | G3's two halves and why they are not redundant; the gate table |
| `docs/engineering/01-architecture.md` | §3.2 | `_bannedEverywhere`, the five `net.*` rows and the comment above them |
| `CLAUDE.md` | offline purity | the banned phrases, and the standing ban on writing the lockfile rule |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-conventions` | the rule ids and the banned-import list |
| `shed-dependencies-and-toolchain` | why the lockfile cannot be scanned for `http` is a dependency-graph fact |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/policy/gate_rules_test.dart`
- **Test** — `'net.http_import exits 1 on a planted package:http import, and no rule scans pubspec.lock for http'`
- **Why it is red today** — nothing stops a network import under `lib/`.

```bash
fvm flutter test test/policy/gate_rules_test.dart   # expect: failing, for the reason above
```

The assertion has two halves and both must be present from the first red run. **First**: plant
`lib/data/export_repository.dart` importing `package:http/http.dart`, assert exactly one violation
naming the file. **Second**: assert `policyRuleIds.where((id) => id.startsWith('net.'))` is
non-empty **and** that no rule in either table reads `pubspec.lock` — the negative half is what stops
a future contributor writing the unsatisfiable rule, and a test that only checks the positive half
leaves the door open.

**Green.** The minimum code that passes, and nothing beyond it — the import scan plus a second assertion that no rule id starting `net.` reads
`pubspec.lock` — with the reason in the rule table's comment.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in the order you touch them

No schema, no domain, no data, no UI, no ARB — say so in the commit message (`00-README` §8).

| # | File | What changes, and why |
|---|---|---|
| 1 | `tool/check_policy.dart` | `_bannedEverywhere` is filled in (the `package:` half of G3) and six `net.*` rows join `_bannedText` (the half that does not arrive on a `package:` URI). The comment above them is part of the deliverable, not decoration |
| 2 | `test/policy/gate_rules_test.dart` | One planting case per row, the two `_bannedEverywhere` shapes, and the negative assertion about `pubspec.lock` |

### 5.2 The signatures

`_bannedEverywhere` applies to **every scanned file**, in both roots, regardless of layer — copy it
from `01-architecture.md` §3.2:

```dart
/// G3 of the offline contract. Applies to every scanned file.
const _bannedEverywhere = <String>{
  'package:http/', 'package:dio/', 'package:connectivity_plus/', 'package:workmanager/',
  'package:battery_plus/', 'package:web_socket_channel/', 'package:firebase_',
  'package:google_fonts/', 'package:printing/', 'package:speech_to_text/',
  'package:google_mlkit_', 'package:permission_handler/',
};
```

And the text rows, with the comment that is the reason they exist:

```dart
/// The network rows are not redundant with _bannedEverywhere. That set matches
/// `package:` URIs, and the highest-risk socket APIs in this app do not arrive
/// on one: HttpClient, Socket and WebSocket come from dart:io, which every file
/// may legitimately import, and Image.network is in the Flutter SDK. G3 claims
/// our own source cannot reach a network API; without these rows it is not proved.
///
/// There is no rule that reads pubspec.lock for `http`, and there must never be
/// one. http 1.6.0 sits on two REGULAR edges — flutter_local_notifications →
/// timezone → http, and wakelock_plus → package_info_plus → http. Such a rule is
/// permanently red, so it gets deleted by whoever meets it first, and then there
/// is no gate at all. The claim G2 makes is narrower and true: no package enters
/// the graph unreviewed. (00-tech-decisions §3.4 #1, 13 §2.4.)
('net.http_client',   'HttpClient(',     'lib/', 'dart:io socket — G3'),
('net.socket',        'Socket.connect(', 'lib/', 'dart:io socket — G3'),
('net.web_socket',    'WebSocket.',      'lib/', 'dart:io socket — G3'),
('net.image_network', 'Image.network(',  'lib/', 'no remote assets — G3'),
('net.pdf_fonts',     'PdfGoogleFonts',  'lib/', 'fetches fonts over HTTP — G3, #83'),
('net.sync_timer',    'Timer.periodic(', 'lib/',
                      'per-row timers and sync loops are both banned; the one ticker uses '
                      'Future.delayed so this rule needs no exemption — #66, #7'),
```

Five of those six are `01-architecture.md` §3.2's, verbatim. **`net.web_socket` is the one row this
task adds**, because §1 names `WebSocket` and `package:web_socket_channel/` only covers the package
form — `dart:io`'s `WebSocket.connect(` arrives on an import every file may legitimately make.

### 5.3 The details that are easy to get wrong

- **Substring matching is doing more work than it looks.** `'Socket.connect('` also matches
  `RawSocket.connect(` and `SecureSocket.connect(`, because both contain it. That is deliberate and
  it is why the row is spelled with the dot and the open paren rather than as `Socket`. Do not
  "complete" the set with two more rows; do add a case that plants `SecureSocket.connect(` so the
  behaviour is recorded rather than accidental.
- **`'HttpClient('` misses `HttpClient.new` and a torn-off constructor.** Both are legal Dart and
  neither contains the literal. This is the honest limit of a text gate: G3 proves *our source has no
  obvious network call site*, not *our source cannot possibly open a socket*. `13 §2.5` states the
  split — what G3 does not prove is G1's job, and the split is the point. Do not upgrade the row to a
  regex that tries to catch every spelling; upgrade the claim's honesty instead.
- **There is no `Uri.parse(` row, and that is a decision, not an omission.** §1 names it, and a bare
  `Uri.parse(` row would fire on the media store's relative-path handling, on the backup import path
  and on `share_plus`'s file URIs — all legitimate, none of them a network path. `01-architecture.md`
  §3.3 names the anti-pattern precisely: *"Banning bare `strftime` or `datetime` — they
  false-positive on legitimate SQL and get weakened."* A rule that gets weakened is worse than a rule
  that was never written. Record the decision in the comment above the `net.*` block so the next
  reader does not add it. If a scheme check is ever wanted, it belongs where a URI is actually
  constructed, and that is one file.
- **The rows are scoped `lib/`, so the proving cases may plant the literals freely.**
  `test/policy/gate_rules_test.dart` does not start with `lib/`, so `from.startsWith(under)` is false
  and no `net.*` row can fire on the test's own source. `_bannedEverywhere` is the exception: it is
  checked against **import directives in every scanned file**, so the test must never write a real
  `import 'package:http/http.dart';` at the top of itself. Planting it as a string into the temp tree
  is not an import directive and is safe.
- **`net.sync_timer` bans `Timer.periodic(` and there is deliberately no exemption.** R25's one
  ticker is built on `Future.delayed`, precisely so this row needs no waiver (decision #66). When
  N12 builds `minuteTickProvider`, a developer reaching for `Timer.periodic` will hit this row —
  that is the row working, not the row being wrong.
- **`package:firebase_` and `package:google_mlkit_` have no trailing slash** in
  `_bannedEverywhere`, because they are prefixes over a family of packages, not a single package
  root. Adding the slash silently unbans `firebase_core`. Keep the set exactly as printed.
- **`package:printing/` and `package:google_fonts/` are banned here as well as in G2's allowlist.**
  That is not duplication: G2 stops the package entering the graph, G3 stops a source file importing
  it if it ever does — for instance transitively, via a package that vendors it. `13 §2.4` lists the
  same names in both places for the same reason.
- **`net.pdf_fonts` bans an identifier, not an import.** `PdfGoogleFonts` is a class inside
  `package:printing`, and decision #83 keeps `pdf` and rejects `printing` exactly because the class
  is *"a one-line footgun"*. The row fires on the identifier so it catches a copied snippet before
  the import is even added.
- **Never write the phrase this gate is protecting.** The commit message, the test names and the
  comments in this task may say *"the app itself cannot connect to anything"* and may not say
  *"your data never leaves your phone"*, *"offline-first"*, or *"a lost phone is lost data"*. Those
  are `CLAUDE.md` banned strings and N03-T06's `copy.tier3_claim` row will start failing the build on
  them one commit from now.

### 5.4 The full test set

| Case | Plant | Expect |
|---|---|---|
| the anchor, half one | `lib/data/export_repository.dart` imports `package:http/http.dart` | one violation, the file named, `layer.import` for the package half |
| the anchor, half two | — | no rule in either table reads `pubspec.lock`; at least one `net.*` id exists |
| `net.http_client` | `lib/data/share_service.dart` contains `HttpClient(` | one violation, id `net.http_client` |
| `net.socket` | `lib/core/log/local_log.dart` contains `Socket.connect(` | one violation, id `net.socket` |
| `net.socket`, subclass form | the same file contains `SecureSocket.connect(` | one violation — the substring rule covers it |
| `net.web_socket` | `lib/data/notification_scheduler.dart` contains `WebSocket.connect(` | one violation, id `net.web_socket` |
| `net.image_network` | `lib/core/ui/components/shed_photo.dart` contains `Image.network(` | one violation, id `net.image_network` |
| `net.pdf_fonts` | `lib/features/export/pdf_builder.dart` contains `PdfGoogleFonts` | one violation, id `net.pdf_fonts` |
| `net.sync_timer` | `lib/core/time/ticker.dart` contains `Timer.periodic(` | one violation, id `net.sync_timer` |
| every `_bannedEverywhere` entry | one planted import per entry, twelve in all, table-driven | twelve violations, each naming its URI |
| **edge** — `dart:io` itself is legal | `lib/data/media_store.dart` imports `dart:io` and calls `File(...)` | zero violations — the offline claim is about sockets, not the filesystem |
| **edge** — the ticker's real shape | `lib/core/time/ticker.dart` uses `Future.delayed` | zero violations; decision #66's shape needs no exemption |
| **edge** — `test/` is scanned for the package half | `test/support/fake_share_service.dart` imports `package:dio/dio.dart` | one violation — `_bannedEverywhere` applies to every scanned file, and a network dependency in the test tier would still be in the graph |
| **edge** — `test/` is not scanned for the `lib/`-scoped rows | `test/support/harness.dart` contains `Image.network(` | zero violations — the row is scoped `lib/`, and widening it is a `CONVENTIONS` §6 ruling, not a keyboard decision |
| **the negative, restated** | a synthetic table containing a row whose `under` is `pubspec.lock` | the inventory test fails loudly — the guard is a test, so a future contributor's rule cannot land quietly |

No case is time-shaped; the gate reads text and never reads a clock.

## 6. Constraints that bind this task

- **Offline** — no network path may be added. G2 (the dependency allowlist) and G3 (the import scan) stay green, and the permission set never changes without G0's recorded evidence. This commit **is** G3; from here on, tiers 1 and 2 of the offline claim are held by a mechanism rather than by intention.
- **The only permitted public wording is decision-record §3.1's, verbatim.** Three tiers exist and only the first two are claimable. Never write "your data never leaves your phone" — it does, the moment they AirDrop a CSV, which is the backup story this product depends on.
- **The lockfile rule must never be written.** It is unsatisfiable, four research notes proposed it, and this commit is where the reason enters the source rather than staying in a document.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'net.http_import exits 1 on a planted package:http import, and no rule scans pubspec.lock for http'` passes, and was seen to fail first for the stated reason
- [ ] every network import shape exits 1, each watched once
- [ ] the unsatisfiable-rule reason is written in the source, not only in a document
- [ ] tiers 1 and 2 of the offline claim are now mechanically held
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
dart tool/check_policy.dart
fvm flutter test test/policy/gate_rules_test.dart
```

Then watch the two halves of G3 fire against the real tree:

```bash
mkdir -p lib/data lib/features/export
printf "import 'package:http/http.dart';\n" > lib/data/_plant.dart
printf "void f() { Image.network('x'); }\n"  > lib/features/export/_plant.dart
dart tool/check_policy.dart ; echo "exit=$?"   # two POLICY lines, exit=1
rm lib/data/_plant.dart lib/features/export/_plant.dart
grep -c 'pubspec.lock' tool/check_policy.dart      # 1 — the lockfile reader, not a net rule
make check
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat: the net.* rules — G3, the import scan`
