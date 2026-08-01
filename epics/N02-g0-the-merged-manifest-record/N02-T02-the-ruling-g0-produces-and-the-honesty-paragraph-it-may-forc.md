# N02-T02 — The ruling G0 produces, and the honesty paragraph it may force

| | |
|---|---|
| **Epic** | [N02 — G0 — the merged-manifest record](epic.md) · `00-README` §9 step 12, run at 2 |
| **Task** | 2 of 3 |
| **Depends on** | N02-T01 |
| **Commit** | one commit · `docs: rule the permission set G0 proved, and draft the store honesty paragraph` |

## 1. Why this task exists

`INTERNET` is removed. `ACCESS_NETWORK_STATE` is **left or removed on the evidence**, not on
faith. If it is left, `13 §2.2`'s second permitted outcome applies: the Play listing will show *"view
network connections"*, and the store-listing honesty paragraph is drafted **now**, before any copy is
authored — because discovering it after the About screen and the Export screen have merged means
re-opening copy in three epics.

T01 produced an observation. This task turns it into a **ruling**: a line somebody else can act on
without re-reading a merger report. The two are separate commits because they fail differently — a
wrong observation is a build you re-run, a wrong ruling is copy on a public store listing.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/13-build-ci-release.md` | §2.2 | *"The ruling G0 produces"* — the two permitted outcomes, and neither is a removal on faith |
| `docs/engineering/13-build-ci-release.md` | §2.1, §2.3, §12 item 9 | the only permitted public wording · what `expected_permissions.txt` will hold · store metadata is a **human** check, forever |
| `docs/research/00-tech-decisions.md` | §3.1, §3.3, §3.4 #6 | the three tiers and which two are claimable · the eight-entry set · the share sheet as another process |
| `CLAUDE.md` | offline purity · vocabulary | the permitted wording verbatim, and the phrases banned from our own prose |
| `docs/engineering/12-testing.md` | §1.4, §10 | why a source-text assertion belongs in the gate — and why the gate does not exist yet |
| `docs/engineering/11-monetization-and-store.md` | §3.1 | iOS merges nothing, so this ruling is Android-only and must say so |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-accessibility-and-copy` | the honesty paragraph is user-facing copy and the offline wording is fixed verbatim |
| `shed-platform-gateways` | the ruling is about a manifest entry and what may be removed from it |
| `shed-release` | typed by name; its description is the only one that carries the exact eight-entry permission set and the store tracks that consume this paragraph |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/policy/offline_wording_test.dart`
- **Test** — `'the only public offline wording in the repository is decision-record §3.1 verbatim, and the phrase your data never leaves your phone appears nowhere'`
- **Why it is red today** — no wording exists yet, and the banned phrasings are only banned in prose.

```bash
fvm flutter test test/policy/offline_wording_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — write the ruling, draft the paragraph if it is needed, and let the test read
`docs/store/offline-honesty.md`, compare its quoted block to decision-record §3.1 **character for
character**, and scan the authored public copy for the banned phrasings. Read §5.5 before choosing
what "the repository" means in the test name: the naive reading is red on day one, twenty-six times,
for twenty-six correct reasons.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step. The
banned-phrase list stays a `const` in this one file: N22-T04 and N32-T02 add cases to the **same
file**, and a list that moves to `test/support/` acquires a second allowlist, which is the failure
`12 §1.4` describes.

## 5. What you build

### 5.1 The ruling, in the shape `13 §2.2` fixes

`INTERNET` — **removed, and the removal is now proven.** Say what proved it (the merged manifest read
at T01, on a dated artefact), not that it is safe.

`ACCESS_NETWORK_STATE` — exactly two outcomes are permitted, and *neither is a removal on faith*:

| If T01's artefact showed | The ruling | What follows |
|---|---|---|
| **Absent from the merged manifest** | nothing to remove | The canonical set stays at decision-record §3.3's **eight entries**; `android/expected_permissions.txt` (N31-T01) will hold **seven** uncommented lines. No honesty paragraph is required, and `docs/store/offline-honesty.md` records *why* none is required |
| **Present, contributed by billing** | **leave it** | It joins `expected_permissions.txt` with its source in a comment — nine entries, eight lines. The Play listing will show *"view network connections"*. That does not contradict §2.1's wording, because `ACCESS_NETWORK_STATE` cannot open a socket — but a shepherd reading the permission list will see it, so it belongs in the store listing's own honesty paragraph |

**The escalation, stated so nobody has to invent it.** If T01 found that `INTERNET` cannot be removed
at all, then decision-record §3.1's permitted wording — *"The Android build ships without the internet
permission"* — is **false**, and this stops being a copy task. It becomes an amendment to §3.1,
`CLAUDE.md`'s offline-purity section, `13 §2.1`, `11 §3` and every screen that quotes them, and it
goes to the owner before a line of it is written.

### 5.2 The files this task touches, in order

Irreversibility order again: the ranking authority first, the public copy next, the test last.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `docs/research/00-tech-decisions.md` §3.3 | the `ACCESS_NETWORK_STATE` line stops reading *"removal PENDING G0"* and carries the ruling plus its one-line reason. Superseded text is **struck with its reason** — §6 of that document exists so corrections are not re-litigated by somebody re-reading a raw note |
| 2 | `docs/engineering/13-build-ci-release.md` §2.2 | the *"The ruling G0 produces"* block records which of the two outcomes applies and the resulting line count for `android/expected_permissions.txt`. The sentence *"Until this table is filled in, `expected_permissions.txt` does not exist and G1 cannot be written"* is now discharged — say so, do not delete it |
| 3 | `docs/store/offline-honesty.md` | **new.** The single authored source of every public sentence about the offline claim. No authority names this path; this task creates it, on `docs/perf/measurements.md`'s precedent (`13 §6.3`) for recorded evidence under `docs/`, and in the folder N32-T02 already expects the listing draft to live in |
| 4 | `docs/engineering/REFERENCES.md` §22 A2 | A2's *"Removing `INTERNET` is proven; removing `ACCESS_NETWORK_STATE` is not"* is struck with the ruling and the date |
| 5 | `test/policy/offline_wording_test.dart` | **written first** (§4). New file. N22-T04 adds the backup-checksum wording case to it; N32-T02 adds the listing case |

No `lib/`, no `assets/`, no ARB. The About screen's message is authored at **N29-T07** and the export
screen's at **N21**; both *quote* this file rather than re-type it — the same discipline the gate rule
`copy.disclaimer_retyped` holds over `Disclaimers`, which `CLAUDE.md` §12.3 requires be *"referenced
and never re-typed."*

### 5.3 `docs/store/offline-honesty.md`, in outline

Four blocks, in this order, because the order is what stops the paragraph being paraphrased.

```markdown
# The offline paragraph

## 1. Permitted wording — decision-record §3.1, verbatim. Quoted, never edited.
> "Shed Book has no account, no server and no sync. The Android build ships without the internet
> permission, so the app itself cannot connect to anything. Your records only leave the phone when
> you deliberately export and share them."

## 2. The permission-list paragraph        <- present only under §5.1's second outcome
<one short paragraph naming what the store's permission list will show and what it cannot do>

## 3. Never written, anywhere public
"your data never leaves your phone" · "offline-first" · "a lost phone is lost data" unqualified ·
"verified" or "secure" about the backup checksum

## 4. Who quotes this file
N21 (export screen) · N29-T07 (About) · N32-T02 (the Play listing draft)
```

Block 1 is a **quotation**, so it is copied out of decision-record §3.1 by machine, not by hand, and
the test compares it character for character. Block 2 is the only authored sentence in the file, and
it is the one the whole product is judged on.

### 5.4 The anchor test, in outline

```dart
// test/policy/offline_wording_test.dart — decision-record §3.1; 13 §2.1.
// Scope: the authored PUBLIC copy this repository holds. Not the doc set — see §5.5.
const _publicCopy = <String>['docs/store/', 'README.md'];

const _bannedEverywhereInPublicCopy = <String>[
  'your data never leaves your phone',
  'offline-first',
];

/// Decision-record §3.1's blockquote, read from the document, never inlined here.
String _permittedWording() { /* ... */ }

void main() {
  test('the only public offline wording in the repository is decision-record §3.1 verbatim, and '
      'the phrase your data never leaves your phone appears nowhere', () {
    final honesty = File('docs/store/offline-honesty.md').readAsStringSync();
    expect(honesty, contains(_permittedWording()),
        reason: 'block 1 is a quotation; a paraphrase is a different claim');
    for (final file in _filesUnder(_publicCopy)) {
      final text = File(file).readAsStringSync().toLowerCase();
      for (final phrase in _bannedEverywhereInPublicCopy) {
        expect(text, isNot(contains(phrase)), reason: file);
      }
    }
  });
}
```

### 5.5 The details that are easy to get wrong

- **A repository-wide substring scan is red on day one, dozens of times, and every hit is correct.**
  Run `grep -rn "never leaves your phone" --include="*.md" . | wc -l` before you write a line of the
  test. Today it counts `CLAUDE.md` twice, decision-record §3.1, ten lines across
  `docs/engineering/`, five skills, three research notes — and both of the task files in this very
  epic. Every one is a document **banning** the phrase. A test that cannot tell a prohibition from a
  claim gets one allowlist, then two, then deleted. **Scope the scan to authored public copy**
  (`docs/store/**`, `README.md`) and say so in the file's first line. That is what "in the
  repository" has to mean to be worth writing.
- **The gate does not exist yet, and this test must not grow into it.** `tool/check_policy.dart` is
  built at **N03** and wired into the `gate` job at N03-T07; its `copy.*` rules take `lib/` and
  `assets/` at N03 and N06. `12 §1.4` is explicit: *"if the assertion can be made by reading source
  text, it belongs in `tool/check_policy.dart`, not in `test/policy/`."* This file never claims
  `lib/` or `assets/`, so when those rules land there is no second scanner and no second allowlist.
- **Store metadata is outside every scanner, forever.** `13 §2.1`: the store listing and the release
  notes *"are outside its reach and are a human checklist item (§12)."* `13 §12` item 9 says it
  plainly — *"you are the gate."* That is precisely why the paragraph is authored **here**, in a file
  a test can read, rather than typed into Play Console at N32.
- **"A lost phone is lost data" is banned *unqualified*, not banned.** The qualified form — the one
  that names the export as the backup — is the honest sentence this product needs. A test that bans
  the string outright deletes a true statement; assert the unqualified form only.
- **`ACCESS_NETWORK_STATE` staying is not a softening of the claim.** It cannot open a socket. The
  claim in §3.1 is about `INTERNET` and about our own source, and it survives intact. The honesty
  paragraph exists because a shepherd reads a *permission list*, not a doc set — write it for that
  reader, not to hedge.
- **iOS merges nothing.** `11 §3.1`: iOS has no manifest permission model, so this ruling is
  Android-only and the paragraph must not imply parity. `13 §2.7` — G5 — makes the same point about
  saying so honestly rather than implying it.
- **Tier 3 is not claimable and never becomes claimable.** The share sheet and the system photo
  picker are *other processes* with their own network access (decision-record §3.1, §3.4 #6). Any
  sentence that would be false the moment a shepherd AirDrops a CSV is the sentence this task exists
  to prevent.
- **The vocabulary rules apply to this file too.** No `sync` as a verb, no *offline-first*, no
  "compliance record", no "should". `CLAUDE.md`'s banned list is not scoped to Dart.

### 5.6 The full test set

| File | Case | What it catches |
|---|---|---|
| `test/policy/offline_wording_test.dart` | `'the only public offline wording in the repository is decision-record §3.1 verbatim, and the phrase your data never leaves your phone appears nowhere'` | a paraphrased permitted paragraph; the banned phrase reaching authored public copy |
| `test/policy/offline_wording_test.dart` | *edge* — the quotation is read from decision-record §3.1 at run time, never inlined | a copy in the test drifts from the copy in the document and the test then defends the wrong sentence |
| `test/policy/offline_wording_test.dart` | *edge* — the unqualified *a lost phone is lost data* fails; the qualified form passes | a blanket ban that would delete the one honest sentence about the backup story |
| `test/policy/offline_wording_test.dart` | *edge* — an absent `docs/store/offline-honesty.md` fails, never skips | the file being deleted or renamed leaves N21, N29-T07 and N32-T02 quoting nothing |
| `test/policy/offline_wording_test.dart` | *edge* — the scan is case-insensitive and normalises straight and curly apostrophes | *"your data never leaves your phone"* typed with a typographic apostrophe slipping through |

Nothing here is time-shaped — no instant is computed, stored or formatted — so there is no
`test/domain/uk_zone/` case to add; the ambiguous **01:00–01:59** hour first appears in N04. The one
date in this task is the ISO date on the ruling, and it is written, never derived.

## 6. Constraints that bind this task

- **The permitted wording is fixed verbatim** (`CLAUDE.md`, decision-record §3.1). It is quoted, never edited, never improved, never shortened for a store field. If it does not fit a field, the field gets a shorter sentence that is *also* true, not a trimmed version of this one.
- **Offline** — no network path may be added. G2 (the dependency allowlist) and G3 (the import scan) stay green, and the permission set never changes without G0's recorded evidence.
- **Safety rule §12.3 — never present the app as a regulatory record.** This is public copy about what the app is and is not; it is the one place in this epic where a §12 rule is genuinely reached, and it is the answer to that question in the PR body.
- **No ARB here.** This epic writes no `lib/`. `app_en.arb`'s rules — a `description` on every message, a `<screen>.<element>` key, no domain noun as a literal — bind **N29-T07**, which authors the About message that quotes this file.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'the only public offline wording in the repository is decision-record §3.1 verbatim, and the phrase your data never leaves your phone appears nowhere'` passes, and was seen to fail first for the stated reason
- [ ] the ruling names the evidence it rests on
- [ ] `INTERNET` is ruled removed; `ACCESS_NETWORK_STATE` is ruled with a reason either way
- [ ] if it stays, the honesty paragraph exists and is referenced by N21, N29 and N32 rather than re-typed
- [ ] *offline-first*, *your data never leaves your phone* and unqualified *a lost phone is lost data* appear nowhere
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
fvm flutter test test/policy/offline_wording_test.dart
grep -rn "never leaves your phone" docs/store README.md
grep -rn "offline-first" docs/store README.md
make check
make test
```

Both greps must return nothing. Then read `docs/store/offline-honesty.md` aloud once — it is the text
a shepherd reads on a store page, and it is the only paragraph in this project that is judged by
somebody who will never open the app.

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `docs: rule the permission set G0 proved, and draft the store honesty paragraph`
