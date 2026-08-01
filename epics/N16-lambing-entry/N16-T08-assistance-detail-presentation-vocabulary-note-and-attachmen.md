# N16-T08 — Assistance detail, presentation vocabulary, note and attachments

| | |
|---|---|
| **Epic** | [N16 — Lambing Entry and the P8 ruling](epic.md) · `00-README` §9 step 6 (2 of 5) |
| **Task** | 9 of 10 |
| **Depends on** | N16-T07 |
| **Commit** | one commit · `feat(lambing_entry): assistance detail, note and attachments` |

## 1. Why this task exists

Who assisted, the malpresentation vocabulary from `assets/content/`, the free-text note,
and the photo and voice-note attachments over N15's gateways. Every one of them skippable — spec §7.2:
a valid record can be one tap.

**Correction to the line above:** the malpresentation labels are not in `assets/content/` either. R66
puts the eight `mp_*` **keys** in `lib/core/db/seed/first_run.dart` and their **labels** in
`lib/l10n/app_en.arb`; `assets/content/` carries one provenance line per list and nothing else. And
after P8 the one-tap promise reads *a valid record is one tally stroke* — the mechanism changed, the
promise did not.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/03-data-model-and-schema.md` | **§5.4 (`assisted_by`, `presentation` FK `ON DELETE RESTRICT`, `presentation_note`, `note` — all nullable)** · §5.12 (`VocabTerms`: `key` unique, `label` nullable, `hidden_at`, `origin`) · **§5.11 (`MediaAssets`: the three `relative_path` `CHECK`s and the exactly-one subject `CHECK`)** · §10.1 (the eight `mp_*` keys) | every column this task writes |
| `docs/engineering/04-migrations-media-backup-restore.md` | §4.3–§4.4 (the media root, `newRelativePath`, `writeAtomically`, the compress settings) | how a file reaches the disk |
| `docs/engineering/CONVENTIONS.md` | §2.12 (`MediaStore`, `CameraService`, `VoiceRecorder` — the three seams) · §2.8 (`MediaAssetId`) · §4.6 · **R47** (capture belongs to the gateways, not to `MediaStore`) · **R66** · §4.4 rule 4 (what the user typed lives in a private field) | the gateways and the split |
| `docs/engineering/02-state-di-navigation.md` | **§7.1 rule 3 (the 400 ms debounce ceiling: free-text only, plus focus loss, route pop and `AppLifecycleState.inactive`)** · §8.3 (`PopScope`, `canPop` always true, no discard dialog) | the one debounce in the app |
| `docs/design/indelible.md` | **§7.12 (the text field: label above, rule below, no placeholder ever, unset = a dotted rule)** · §7.13 (the word button) · §9 screen 1 (*"the filters are not chips — chips are containers with a radius, and this system has neither"*) · §9 screen 4 (*"every unset cell prints its gap and its `NOT RECORDED · SKIPPABLE` label"*) | every control's shape |
| `docs/engineering/07-screens.md` | §6.4 (assistance detail, note, voice note, photo — the tap costs) · §6.3 (the states) | what the screen offers |
| `shed-book-spec.md` | **§7.2 (*"assistance detail: who assisted, malpresentation note, lubricant/ropes/vet"*, *"free-text note and optional voice note"*, *"photo attachment"*, *"every field except birth type is skippable"*)** | the fields, and the promise |
| `docs/research/00-tech-decisions.md` | §5 (`image_picker` **1.2.3**, `flutter_image_compress` **2.5.1**, `record` **7.1.1**) · #40 (2048 px, JPEG q80, `keepExif` false) · #76 (AAC-LC `.m4a`, **never opus**) · #77 (`image_picker` merges zero Android permissions) · §7.0 (**OCR and voice tag entry are cut from v1; the voice note ships**) | the versions and the media rules |
| `docs/engineering/10-accessibility-and-i18n.md` | §3.2 (the eight label rules) · §8 (every message has a `description`; no domain noun as a literal) | the copy |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-write-path` | each field is its own committed write |
| `indelible-controls` | the field rows, the vocabulary picker and the attachment controls |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/lambing_entry_test.dart`
- **Test** — `'every field after the first tap is skippable and each one commits on its own'`
- **Why it is red today** — the screen records a lambing and its lambs but none of §7.2's detail.

```bash
fvm flutter test test/features/lambing_entry_test.dart   # expect: failing, for the reason above
```

Sharpen both halves. **Skippable** — pop the route with only a tally stroke recorded, reopen the
lambing, and assert the record is complete and valid with every detail column `NULL`. **Each one
commits on its own** — set one field, read the row back, and assert the other columns are byte-
identical; a screen that writes the whole row on every edit passes a naive version of this test and
loses a field the moment two edits race.

**Green.** The minimum code that passes, and nothing beyond it — the fields, each committing independently, none of them required.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**No schema step, and say so in the commit message.** Every column and every `CHECK` this task writes
into froze at N07.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `lib/data/lambing_repository.dart` | **Extended.** `setAssistedBy`, `setPresentation`, `setPresentationNote`, `setNote` — four narrow verbs, each writing **one column** plus `updated_at`, each returning `WriteOutcome`. Not one `updateDetail(...)`: a wide write is how a second edit clobbers the first |
| 2 | `lib/data/note_repository.dart` | **Unchanged, and that is the check.** `NoteRepository` owns `notes` and `media_assets` (N15-T04); the attachment path goes through it, not through a second inserter here |
| 3 | `lib/features/lambing/lambing_entry_controller.dart` | **Extended.** `LambingEntryController` gains the private in-flight text fields and the 400 ms debounce, plus the three flush points. `LambingWriteController` gains the four verbs through `guard()` |
| 4 | `lib/features/lambing/widgets/detail_rows.dart` | **New.** `ShedFieldRow` for `assisted_by`, the presentation picker, `presentation_note` and `note` — label above, rule below, **no placeholder ever** |
| 5 | `lib/features/lambing/widgets/attachment_row.dart` | **New.** The photo and voice-note controls, over `CameraService`, `VoiceRecorder` and `MediaStore`; `ShedPhoto` (N15-T06) renders the result as a ruled cell |
| 6 | `lib/features/lambing/lambing_entry_screen.dart` | **Extended.** Mounts the detail section and the `PopScope` that flushes on the way out |
| 7 | `lib/l10n/app_en.arb` | **Extended.** The eight `mp_*` labels if N07-T07 did not already land them, the four field labels, the `NOT RECORDED · SKIPPABLE` label, the attachment labels and every `semanticLabel` — each with a `description` |
| 8 | `assets/content/` | **Extended.** One provenance line for the `malpresentation` list. Not the labels — R66 |
| 9 | `test/features/lambing_entry_test.dart` | **The anchor**, plus the skippability, debounce, vocabulary and attachment cases |
| 10 | `test/data/lambing_repository_test.dart` | **Extended.** The four narrow verbs and the one-column property |
| 11 | `test/data/media_assets_test.dart` | **Extended** (created at N15-T01). The lambing subject and the three path `CHECK`s |
| 12 | `test/data/lambing_ambiguous_hour_test.dart` | **Extended.** A debounced note flush inside the repeated hour |

### 5.2 The signatures

Four narrow verbs, and the reason they are four:

```dart
// lib/data/lambing_repository.dart
/// One column each, plus `updated_at`. A single wide `updateDetail(...)` would
/// read the row, build a companion from a screen copy that is one frame old,
/// and write every column back — so two edits in the same second lose one of
/// them, silently, with no failure anywhere.
Future<WriteOutcome> setAssistedBy(LambingId id, String? who);
Future<WriteOutcome> setPresentation(LambingId id, String? vocabKey);   // vocab_terms.key
Future<WriteOutcome> setPresentationNote(LambingId id, String? note);
Future<WriteOutcome> setNote(LambingId id, String? note);
```

The one debounce in the codebase, and its three flush points:

```dart
// lib/features/lambing/lambing_entry_controller.dart
/// 02 §7.1 rule 3. The debounce ceiling in this codebase is 400 ms and it
/// applies ONLY to free-text fields — a note cannot round-trip to SQLite per
/// keystroke without churning every watching stream. Taps are NEVER debounced.
///
/// What the user typed lives in a PRIVATE FIELD on this notifier, not only in
/// `state` (CONVENTIONS §4.4 rule 4). That is not a draft: worst-case loss is
/// 400 ms of typing, and the field is flushed on focus loss, on route pop
/// (PopScope) and on AppLifecycleState.inactive.
static const _textDebounce = Duration(milliseconds: 400);
```

The capture flow, in R47's order and no other:

```dart
// CameraService.pick()  ->  MediaStore compresses and writes  ->
// NoteRepository inserts the media_assets row.
//
// `MediaStore` owns the media root, `newRelativePath`, `resolve` and
// `writeAtomically`; `CameraService` owns image_picker; `VoiceRecorder` owns
// record. 04 §4.4 put pickImage and AudioRecorder ON MediaStore — R47 ruled
// against it, because a seam that wraps two plugins cannot be faked as one.
```

### 5.3 The details that are easy to get wrong

- **`lubricant / ropes / vet` has no column in the frozen schema.** Spec §7.2 lists it under assistance
  detail; `03 §5.4` ships `assisted_by`, `presentation`, `presentation_note` and `note`, and the
  schema froze at N07-T08. It therefore lands in **`presentation_note`** as free text — say so in the
  ARB `description` and in the field's label, so the next reader does not go looking for a column or,
  worse, propose one. A structured version is a v2 migration, not a widget.
- **There are no chips on this screen, and `07 §6.4` uses the word anyway.** `indelible.md` is explicit:
  *"the filters are not chips — chips are containers with a radius, and this system has neither."*
  The malpresentation picker is a ruled line of **word buttons** (§7.13), each ≥ 64 × 64, in a sheet
  or on a 64 px line. If a `Chip`, `FilterChip`, `ActionChip` or `InputChip` appears in the diff, the
  design system was not read.
- **The vocabulary comes from `vocabProvider` and is user-editable** (T04, R76). `presentation` is an
  FK onto `vocab_terms.key` with `ON DELETE RESTRICT`, so a term in use **cannot be deleted** —
  removal sets `hidden_at`. Two consequences the picker must honour: a hidden term is not **offered**,
  and a lambing that already references one still **renders its label**. Filtering hidden terms out of
  the label lookup as well as out of the list is how an existing record starts rendering a raw key.
- **The labels are ARB messages, the keys are seeded, and `assets/content/` holds neither.** R66, and
  `test/policy/vocab_labels_are_complete_test.dart` (N07-T07) asserts the two sets are equal. The
  eight keys are `mp_head_back`, `mp_one_leg_back`, `mp_both_legs_back`, `mp_breech`, `mp_backwards`,
  `mp_twins_together`, `mp_ringwomb`, `mp_other`. Write the labels in the app's own words; the
  no-verbatim-third-party-copy check scans `assets/content/` **and** `lib/l10n/`.
- **Never a placeholder inside a field** (`indelible.md` §7.12). *"In the dark, a grey placeholder is
  indistinguishable from an entered value."* The label goes above the line; unset is a 2 px **dotted**
  rule and the `NOT RECORDED · SKIPPABLE` label; there is no `hintText` anywhere in the feature.
- **The private text field is not a draft, and the distinction is in the flush points.** `CONVENTIONS
  §4.4` rule 4 requires it; `CLAUDE.md` bans drafts. Both hold because the field is flushed on focus
  loss, on route pop and on `AppLifecycleState.inactive`, and it never survives process death. Worst
  case is 400 ms of typing, and that number is in `CODE-REVIEW-CHECKLIST.md` precisely so it cannot
  silently grow.
- **`canPop` stays `true` and there is no discard dialog anywhere in this app** (`02 §8.3`). Because
  every write commits immediately, backing out is always safe, always instant, and never asks a
  question. `PopScope` exists on this screen **only** to flush the debounce, not to block the pop.
- **Taps are never debounced.** Rule 3 again: the 400 ms ceiling applies to free text only. Debouncing
  a slab press or a care line would drop a legitimate second lamb.
- **A media asset carries exactly one subject.** `CHECK ((ewe IS NOT NULL) + (lamb IS NOT NULL) +
  (lambing IS NOT NULL) + (note IS NOT NULL) = 1)`. The free-text note on this screen is
  **`lambings.note`, a column** — so a photo taken here hangs off `lambing`, never off `note`. Setting
  both is unstorable, and picking the wrong one orphans the photo from the record a shepherd will look
  for it under.
- **`relative_path` carries three `CHECK`s and all three bite** (R62): `NOT LIKE '/%'`,
  `GLOB '[0-9][0-9][0-9][0-9]/[0-9][0-9]/*.*'`, `NOT GLOB '*/*/*/*'`. An absolute path is refused
  because the iOS container UUID is not stable across launches — *"an absolute path 404s after every
  restore, update and re-install, and never reproduces on the developer's Android phone."* Let
  `MediaStore.newRelativePath` produce it; never build one by hand.
- **The capture order is `CameraService` → `MediaStore` → `NoteRepository`** (R47). `04 §4.4` put
  `ImagePicker().pickImage` and `AudioRecorder()` on `MediaStore`; the ruling moved them, because a
  seam that wraps two plugins cannot be replaced by one hand-written fake, and `test/support/` holds
  seven fakes for exactly seven seams.
- **The voice note is AAC-LC `.m4a` and never opus** (decision #76, R54's `media.opus` gate row), and
  it is capped by `kVoiceNoteMaxSeconds` in `lib/data/media_limits.dart`. Voice **tag entry** and OCR
  are **cut from v1** by the owner's §7.0 ruling; the voice **note** ships. Do not let a "while we are
  here" transcription idea in — there is no network path.
- **The photo goes through the system picker, which is another process.** Only tiers 1 and 2 of the
  offline contract are claimable; *"your records only leave the phone when you deliberately export and
  share them"* is the permitted wording, and **"your data never leaves your phone" is banned**.
  `image_picker` merges zero Android permissions (decision #77), so `android/` must not move in this
  diff.
- **A full disk is a `MediaWriteFailed`, not a crash and not a silent skip.** N15-T05 built the path;
  this screen surfaces `failure.userMessage` and leaves the record intact. The lambing is already
  committed — an attachment that fails costs a photo, never the night's record.
- **Every field is skippable and none of them blocks.** Spec §7.2 and `07 §6.3`: the record is valid
  with a single stroke. There is no required-field mark, no validation gate, no "complete this record"
  prompt, and no disabled Done.

### 5.4 The full test set

| File · case | What it asserts |
|---|---|
| `test/features/lambing_entry_test.dart` · `'every field after the first tap is skippable and each one commits on its own'` | **The anchor.** Pop with one stroke and reopen: valid, every detail column `NULL`. Then one field set and the rest byte-identical |
| `test/features/lambing_entry_test.dart` · `'setting one detail leaves the other three and the provenance quad untouched'` | The four narrow verbs. The wide-write bug, caught |
| `test/features/lambing_entry_test.dart` · `'the presentation picker lists the eight seeded terms plus any the user added'` | `vocabProvider`, `origin = 'user'` included |
| `test/features/lambing_entry_test.dart` · `'a hidden term is not offered but an existing record still renders its label'` | `hidden_at` filters the list, never the lookup |
| `test/features/lambing_entry_test.dart` · `'the note commits on focus loss, on route pop and on lifecycle inactive'` | The three flush points, one case each |
| `test/features/lambing_entry_test.dart` · `'typing does not write per keystroke and the ceiling is 400 ms'` | One write after the debounce, not eight |
| `test/features/lambing_entry_test.dart` · `'canPop is true and no discard dialog exists anywhere in the feature'` | `02 §8.3` |
| `test/features/lambing_entry_test.dart` · `'no field renders a placeholder inside the field'` | Source text: `hintText` and `placeholder` appear zero times |
| `test/features/lambing_entry_test.dart` · `'no chip widget is mounted and every detail target is at least 64 by 64'` | `Chip`, `FilterChip`, `ActionChip`, `InputChip` appear nowhere |
| `test/features/lambing_entry_test.dart` · `'an unset detail prints its gap and NOT RECORDED · SKIPPABLE'` | `indelible.md` §9 screen 4 |
| `test/features/lambing_entry_test.dart` · `'a photo attaches to the lambing and renders through ShedPhoto'` | The fake `CameraService`, the fake `MediaStore`, and one `media_assets` row |
| `test/features/lambing_entry_test.dart` · `'a full disk surfaces MediaWriteFailed and leaves the lambing intact'` | N15-T05's path, from this screen |
| `test/data/media_assets_test.dart` · `'a lambing attachment sets lambing and no other subject'` | The exactly-one `CHECK` |
| `test/data/media_assets_test.dart` · `'an absolute path and a three-deep path are both refused'` | Two of R62's three `CHECK`s, against SQLite |
| `test/data/media_assets_test.dart` · `'a voice note is m4a, is capped by kVoiceNoteMaxSeconds, and is never opus'` | Decision #76 and the `media.opus` gate row |
| `test/data/lambing_repository_test.dart` · `'each detail verb writes one column and updated_at'` | Read the whole row back and diff it |
| `test/data/lambing_ambiguous_hour_test.dart` · `'a note flushed at 01:30 in the repeated hour moves updated_at and leaves the provenance quad untouched'` | **`uk-zone`.** A detail edit is not an event-time edit |

## 6. Constraints that bind this task

- **Write path** — the row is created on screen entry, not on exit. No draft, no Save button, no `commit()`, no optimistic UI; every write commits immediately and goes through `guard()`. The 400 ms free-text debounce is the one documented exception and it carries three flush points.
- **3am** — every interactive element ≥ 64 × 64 with ≥ the ruled separation, 18 px text floor, dark only, and none of the banned gestures: no swipe, no drag, no long-press, no pinch, no slider. No chips, and no placeholder inside a field.
- **Offline purity** — the system photo picker is another process. The permitted wording is the verbatim one; *"your data never leaves your phone"* is banned. `android/` and `ios/` must not appear in this diff.
- **Accessibility and the ARB, authored here** — every string in `app_en.arb` with a `description`, every element a `semanticLabel` and a `<screen>.<element>` key. There is no later sweep; N33 only verifies.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'every field after the first tap is skippable and each one commits on its own'` passes, and was seen to fail first for the stated reason
- [ ] no field blocks the record
- [ ] the presentation vocabulary comes from `vocab_terms` and is user-editable
- [ ] attachments route through N15's gateways and store relative paths
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] four narrow verbs, each writing one column; there is no wide `updateDetail`
- [ ] a hidden vocabulary term is not offered and an existing record still renders its label
- [ ] the 400 ms debounce applies to free text only, with all three flush points, and taps are never debounced
- [ ] `canPop` is `true`, `PopScope` only flushes, and no discard dialog exists
- [ ] no placeholder inside any field, and no chip widget anywhere
- [ ] a lambing attachment sets exactly one subject and its path matches `YYYY/MM/`
- [ ] the voice note is `.m4a`, capped by `kVoiceNoteMaxSeconds`, and never opus
- [ ] `lubricant / ropes / vet` is written down as living in `presentation_note`, in the ARB `description`
- [ ] `android/` and `ios/` do not appear in the diff
- [ ] the ambiguous-hour case exists and is tagged `uk-zone`

## 8. Verification

```bash
fvm flutter test test/features/lambing_entry_test.dart
fvm flutter test test/data/lambing_repository_test.dart
fvm flutter test test/data/media_assets_test.dart
TZ=Europe/London fvm flutter test --tags uk-zone
make check
make test
```

```bash
grep -rn "Chip(\|FilterChip\|ActionChip\|InputChip" lib/features/lambing/   # expect zero
grep -rn "hintText\|placeholder" lib/features/lambing/                      # expect zero
grep -rn "opus" lib/                                                        # expect zero
git diff --name-only main -- android/ ios/                                  # expect empty
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(lambing_entry): assistance detail, note and attachments`
