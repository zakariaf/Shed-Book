# N00-T02 — Rule the two dependency-shaped open questions

| | |
|---|---|
| **Epic** | [N00 — Decisions, rulings and the calendar](epic.md) · `00-README` §9 step 0 |
| **Task** | 2 of 9 |
| **Depends on** | N00-T01 |
| **Commit** | one commit · `docs: rule in-app printing and the voice-note cap before the pubspec closes` |

## 1. Why this task exists

Two open questions expire the moment `pubspec.yaml` closes in T03: **in-app PDF printing**
(the `printing` package pulls `http`, which the offline contract has to answer for in prose even
though `http` already sits on four load-bearing regular edges) and the **voice-note cap**
(`kVoiceNoteMaxSeconds`, which decides whether `record`'s configuration is a constant or a setting).
Rule both in the decision record with their reasons, and strike the open rows per the amendment
rule.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/research/00-tech-decisions.md` | §7.1 items 16 and 18, §2 H #83, §3.1, §3.4 #1, §5.3 | the two questions, the `pdf`-not-`printing` decision, the three-tier offline claim, and the two regular `http` edges that already exist |
| `docs/engineering/09-export-formats.md` | §4.1, §8.2, §10 row 10 | *"there is no in-app print dialog"*, the share-sheet delivery, and the exact price of re-admitting `printing` |
| `docs/engineering/04-migrations-media-backup-restore.md` | §4.4 | `kVoiceNoteMaxSeconds` as one constant in `lib/data/media_limits.dart`, and the storage budget at both values |
| `docs/engineering/00-README.md` | §5.2 items 16 and 18, §10 | the open list this task shortens, and the amendment rule that says how |
| `docs/engineering/13-build-ci-release.md` | §2.4, Definition of done | G2 scans `dependencies` and `dev_dependencies` separately, and *"no gate anywhere asserts no `http` in `pubspec.lock`"* |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-dependencies-and-toolchain` | any proposed package and any `pubspec.yaml` change is its front door |
| `shed-export-and-restore` | the printing ruling changes what §7.9's *printable* means for the PDF path |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/policy/dependency_rulings_test.dart`
- **Test** — `'no decision-record row marked dependency-shaped is still open'`
- **Why it is red today** — both rows in decision-record §7.1 still read OPEN, and the test parses the decision record for that word.

```bash
fvm flutter test test/policy/dependency_rulings_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — rule each row, strike the open row with its reason and date, and record the consequence for
`09-export-formats.md` in the same commit, per the amendment rule.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

Nothing under `lib/`. This task reaches the **decision** layer and the **test** layer only, and the
decision layer is a document — which is exactly why the amendment rule exists: a ruling that is not in
the record and in every document that applies it is not a ruling, it is an opinion somebody will
overturn in November.

| # | File | What changes, and why |
|---|---|---|
| 1 | `docs/research/00-tech-decisions.md` §7.1 | Items 16 (in-app printing) and 18 (voice-note cap) are **struck with their reason and date**, never quietly deleted — §6 of that file exists so corrections are not re-litigated. Each surviving item gains an explicit shape tag: `dependency-shaped`, `schema-shaped` or `calendar-shaped`. That tag is what the anchor test parses, and T04 parses the same one |
| 2 | `docs/research/00-tech-decisions.md` §7.0 | Two new rows in the SETTLED table: the question, the ruling, the date, and *what it binds* |
| 3 | `docs/research/00-tech-decisions.md` §2 H #83 | The `pdf`-only row gains the ruling's consequence in its Decision cell, so a reader who never opens §7 still sees it |
| 4 | `docs/engineering/00-README.md` §5.2 | Items 16 and 18 struck from the open list and the trailing count corrected — it currently reads *"Thirteen remain"* |
| 5 | `docs/engineering/09-export-formats.md` §8.2, §10 row 10 | The printing ruling written into the section that owns the honest wording, and row 10 of the open table closed |
| 6 | `docs/engineering/04-migrations-media-backup-restore.md` §4.4 and its Definition of done | The voice-note cap answered; the blockquote that says *"owner-blocked"* replaced by the ruling and its date; the storage-budget table narrowed to the ruled value |
| 7 | `docs/engineering/CONVENTIONS.md` §7 item 3 | The list of *"open questions carried by every document"* loses the voice-note cap and the printing question |
| 8 | `test/policy/dependency_rulings_test.dart` | The anchor, written first |

### The two rulings, and what each one actually decides

**In-app PDF printing — the recommendation on record is *no*.** `09 §8.2` already states the position
and the price: `printing` 5.15.0 declares `http >=0.13.0 <2.0.0` and hands every future contributor a
one-line footgun (`PdfGoogleFonts.robotoRegular()`, `networkImage(...)`) that turns the app into a
networked app on iOS, where there is no permission gate to stop it. Delivery stays share sheet → the OS
Print action, and the Export screen says so rather than printing the word "printable" and leaving the
shepherd hunting for a button.

If the ruling goes the other way, these move together in this commit: `printing 5.15.0` enters
decision-record §5.1 with its audited transitive graph; `tool/policy_allowlist.txt`'s `[dependencies]`
section gains a row (N03-T04); G3's grep list keeps `PdfGoogleFonts` and `networkImage` as **blocking**
rows rather than advisory ones; and decision-record §3.1's tier-2 claim — *"no dependency attempts a
network call from our process"* — has to be re-argued in writing, because `printing` is a package whose
whole job is to talk to a print service.

**The voice-note cap — 60 s or 120 s.** `04 §4.4` gives the shape and the interim: one constant
`kVoiceNoteMaxSeconds` in `lib/data/media_limits.dart`, referenced everywhere including the
storage-budget test, and *"until the owner answers, ship 60 s: it is the lower storage figure and the
recoverable mistake — raising a cap orphans nothing, lowering one makes existing recordings
unreproducible."* The numbers behind it are AAC-LC mono at 32 kbps: **~240 KB** at 60 s, **~480 KB** at
120 s, against a typical-season figure of ~300 MB of media in `04 §4.4`'s table.

The signature the ruling fixes, for the task fifteen epics away that writes it:

```dart
// lib/data/media_limits.dart — written in N15, not here
const int kVoiceNoteMaxSeconds = 60;
```

## 6. Constraints that bind this task

- **Offline** — no network path may be added. G2 (the dependency allowlist) and G3 (the import scan) stay green, and the permission set never changes without G0's recorded evidence.
- **The amendment rule** (`00-README` §10) — the decision record and *every document that applies the decision* change in the same commit. A doc set where 09 still calls printing open and the record calls it closed is worse than no doc set, because both look authoritative.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

### The details that are easy to get wrong

- **Do not create `lib/data/media_limits.dart` in this task.** `CONVENTIONS §1`'s tree is `mkdir`-ed in
  N01-T01 and the file is written in N15 with the rest of the media seam. Creating it here puts a file
  in a tree that does not exist yet and gives N01-T01 something to prune that it should not have to
  think about. This task rules the value; it does not write the constant.
- **The printing question is not "is `http` in the lockfile".** It already is, on four regular edges —
  `flutter_local_notifications → timezone → http ^1.6.0` and `wakelock_plus → package_info_plus → http
  ^1.6.0` (decision-record §3.4 #1). `13`'s Definition of done is explicit: *"No gate anywhere asserts
  'no `http` in `pubspec.lock`' — that gate is unsatisfiable and must not exist."* The question is
  whether a **call site in `lib/` can reach a network API**, which is G3's job, not G2's.
- **§7.1 is a numbered prose list, not a table, and a test cannot parse "OPEN" out of prose reliably.**
  Introducing the shape tag is part of this task, not a tidy-up: each surviving item gets one of
  `dependency-shaped` / `schema-shaped` / `calendar-shaped`, and each ruled item gets a struck line
  carrying `RULED <YYYY-MM-DD> — <one sentence>`. T04 parses the identical markers for the four
  schema-shaped rows, so getting the shape wrong here costs two tasks, not one.
- **Keep the parser private until it has a second consumer.** Write `_ruledRows(String section)` as a
  top-level private function inside `dependency_rulings_test.dart`. When T04 becomes the second reader,
  lift it to `test/support/decision_record.dart` in T04's Refactor step — and add that file to
  `CONVENTIONS §1`'s tree in the same commit, because §1 is the authority on which files exist and R57
  owns the test tree.
- **Striking is not deleting.** Decision-record §6 exists precisely so that a re-read of a raw research
  note cannot reinstate an overturned claim. A ruled row keeps its text, struck, with the ruling beneath
  it. Deleting it means the next person re-opens it from the research notes in three months.
- **Ruling item 18 does not close the field night.** Decision-record §7.1 item 1 says the shed
  observation *"also closes questions 2, 12 and 18"*. If N00-T07's field night later contradicts the
  60 s ruling — a shepherd talking for ninety seconds about a malpresentation is not an unlikely
  observation — the amendment rule applies again, and the cost is one constant and one row. That is why
  60 s is the recoverable direction.
- **Nothing in this task is time-shaped** except the ruling dates themselves, which are civil dates
  written by a human into a document. There is no instant, no arithmetic and no ambiguous-hour case.

## 7. Definition of Done

- [ ] `'no decision-record row marked dependency-shaped is still open'` passes, and was seen to fail first for the stated reason
- [ ] both rows carry a ruling, a reason and a date
- [ ] `printing` is either in the dependency table with its network edge described in the offline prose, or rejected with the alternative named
- [ ] `kVoiceNoteMaxSeconds` has a value and a reason
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
fvm flutter test test/policy/dependency_rulings_test.dart
grep -rn "printing" docs/engineering/09-export-formats.md | grep -i "open\|unresolved"
grep -rn "owner-blocked\|60 s or 120 s" docs/engineering/04-migrations-media-backup-restore.md
```

The last two must return nothing. If either still prints a line, the amendment rule has not been
applied and the record disagrees with the document that applies it.

The test set this task ends with, one file and five cases:

| Case | Asserts |
|---|---|
| `'no decision-record row marked dependency-shaped is still open'` | the anchor: §7.1 has zero items tagged `dependency-shaped` without a `RULED` line |
| `'every ruled row carries a reason and an ISO date'` | the `RULED` line matches `RULED \d{4}-\d{2}-\d{2} — .+` and the reason is at least one sentence |
| `'a ruled row is struck, not deleted'` | the original question text still appears in §7.1 |
| `'§7.0 and §7.1 agree'` | every row struck in §7.1 has a matching row in the §7.0 SETTLED table |
| `'no document still calls either question open'` | `09-export-formats.md` and `04-migrations-media-backup-restore.md` contain no *open* / *owner-blocked* marker for these two |

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `docs: rule in-app printing and the voice-note cap before the pubspec closes`
