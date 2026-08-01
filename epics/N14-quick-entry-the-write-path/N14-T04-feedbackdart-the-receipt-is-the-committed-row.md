# N14-T04 — `feedback.dart` — the receipt is the committed row

| | |
|---|---|
| **Epic** | [N14 — Quick Entry: the write path](epic.md) · `00-README` §9 step 5 (2 of 2) |
| **Task** | 4 of 7 |
| **Depends on** | N14-T03 |
| **Commit** | one commit · `feat(ui): feedback.dart — the receipt is the committed row` |

## 1. Why this task exists

`confirmSaved` / `showFailure` / `showCapRow`, where the confirmation **is the committed
row**, in ink, one line above the one being written. **P2 supersedes `CONVENTIONS §2.11`**: there is no
SnackBar anywhere, including in this file, which was the last place with a legitimate call site.

The failure mode this closes is not slowness. Indelible §9: *"That failure mode was never slowness. It
was doubt."* A toast is a claim about a row; the row is the row. And a floating overlay at 03:20 covers
the thing it is confirming, cannot be re-read after it fades, and needs a gesture to dismiss that the
gesture ban forbids.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/07-screens.md` | §5.4 | the write path and the tap budget |
| `docs/engineering/00-README.md` | §2.4, §8 step 3 | every write commits immediately; the row is created on screen entry |
| `docs/engineering/11-monetization-and-store.md` | §2 | `EntryContext` and decision #91's live-entry rule |
| `docs/skills/02-build-manifest.md` | **§4.1 (P2, the ruling this task implements)** · §4.4 defect 2 (`AUTO-CAPTURED` is not an exempt stamp and must meet the 18 px floor) | what replaces the SnackBar, and the one stamp whose size is a correction |
| `docs/engineering/06-design-system.md` | §10.1 (the four haptics and the two deliberate gaps) · §10.3 (the receipt as proof, `SaveReceipt`, the three functions, the live-region uniqueness rule) · §12 (`ShedReceiptBar`, `ShedBanner`, the three free-tier constraints) | the type, the signatures, the channel rules |
| `docs/design/indelible.md` | §7.3 (the ruled record row: Default, Live, Pressed, Struck, Queried, Unset cell) · §8 Screen 3 (the live row welded above the bottom band, the row above fully legible) · §9 (*no toast, no snackbar, no modal dialog anywhere in the app*) | what the shepherd sees |
| `docs/engineering/CONVENTIONS.md` | §2.11 (`SaveReceipt`, the three functions — **amended by this task**) · §4.5 (widget keys) · §5.4 (copy conventions; every displayed event time carries its provenance label) · R10, R30, R31 | **BINDING**: the three names and their signatures |
| `docs/engineering/10-accessibility-and-i18n.md` | §9.1 (`formatShedTime` renders `at`) · the live-region rules | why `SaveReceipt.at` is a pre-formatted `String` |
| `docs/engineering/12-testing.md` | §7.1–§7.5 (semantics as an executable gate, the canary) | how the announcement is asserted |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `indelible-states-and-feedback` | the receipt, the failure and the cap row are its subject |
| `shed-write-path` | what feedback a write may produce and when |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/policy/no_snackbar_test.dart`
- **Test** — `'showSnackBar( appears nowhere in lib/, including feedback.dart'`
- **Why it is red today** — nothing renders a confirmation, and the framework's obvious answer is a SnackBar.

```bash
fvm flutter test test/policy/no_snackbar_test.dart   # expect: failing, for the reason above
```

Sharpen the assertion so it survives a rename. Scan every non-generated `.dart` file under `lib/` for
`showSnackBar(`, `SnackBar(`, `SnackBarAction(`, `ScaffoldMessenger.of(` and `showMaterialBanner(`,
expect zero hits for each, and assert **in the same test** that `tool/policy_allowlist.txt` contains no
`[exempt]` line naming `gesture.raw_snackbar` — a rule with an escape hatch is a rule that will be
escaped at 23:00 on a Tuesday.

**Green.** The minimum code that passes, and nothing beyond it — the three functions over `ShedReceiptBar`, and the policy test with **no** exempt line.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**No schema, no domain, no data step.** This is `00-README` §8 step 6 (UI) and step 22 (the ARB), plus
one gate row and two document amendments.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `lib/core/ui/components/shed_receipt.dart` | **New.** `ShedReceiptBar` — under P2 this is the **ruled record row in its receipt state**, not a floating bar: `06 §12` sizes it at ≥ `tapHero` including the strike affordance, and Indelible §7.3 gives it its rendering. Carries `Semantics(liveRegion: true)` with a label that differs every save |
| 2 | `lib/core/ui/feedback.dart` | **New.** `SaveReceipt`, `confirmSaved`, `showFailure`, `showCapRow`, and `ShedReceiptScope` (see §5.2). The file keeps its identity as *the* feedback channel; what it loses is the SnackBar |
| 3 | `lib/features/quick_entry/quick_entry_screen.dart` | **Edit.** Install `ShedReceiptScope` above the ledger, build the `SaveReceipt` for each verb, and pass it to `confirmSaved` from the `ref.listen` T03 landed |
| 4 | `lib/l10n/app_en.arb` | **Edit.** The receipt's own strings and `ShedFailure`'s **are not the same thing**: the six `userMessage` strings live on the failure types and are the only user-facing text outside the ARB in v1 (`CONVENTIONS §1`). Everything this file composes is an ARB message with a `description` |
| 5 | `tool/check_policy.dart` | **Edit.** `gesture.raw_snackbar` stops pointing at `lib/core/ui/feedback.dart` as its one allowed site and becomes an unconditional `lib/`-wide ban. Add `ui.material_banner` for `showMaterialBanner(` if it is not already a row |
| 6 | `docs/engineering/CONVENTIONS.md` §2.11 | **Amend.** Strike *"`feedback.dart` is the one file permitted to call `showSnackBar(`"* with its reason (P2), and add `ShedReceiptScope` to the design-system type catalogue |
| 7 | `docs/engineering/06-design-system.md` §10.3 | **Amend.** Its printed `confirmSaved` body calls `ScaffoldMessenger.of(context).showSnackBar(...)`, and its stated fallback is an `OverlayEntry`. P2 forbids both — *"no floating overlay"* |
| 8 | `test/policy/no_snackbar_test.dart` | **New.** The anchor |
| 9 | `test/features/quick_entry_test.dart` | **Edit.** The rendering, haptic and semantics cases below |

`tool/policy_allowlist.txt` is **not** edited. R56 fixes the `[exempt]` section at four lines on day
one, and adding a fifth to keep this rule quiet is the named anti-pattern.

### 5.2 The signatures

R30 fixes all three, and they do not change — a feedback function holds a `BuildContext` and nothing
else. No `WidgetRef`, no provider read, no navigation.

```dart
// lib/core/ui/feedback.dart
//
// P2: there is no SnackBar in this app, including in this file. The
// confirmation IS the committed row, in ink, one line above the one being
// written (02-build-manifest §4.1). showShedReceipt and showShedFailure are
// banned spellings (R30).

/// What a receipt says. `at` is pre-formatted `HH:mm`, 24-hour, en_GB by
/// lib/core/ui/formatters.dart — never here. `undoLabel` exists because the
/// label is not always "UNDO": it is "Correct this" on a foster and "Void
/// this" on a treatment (07 §15.3).
@immutable
final class SaveReceipt {
  const SaveReceipt({
    required this.term,
    required this.tag,
    required this.summary,
    required this.at,
    this.undo,
    this.undoLabel = 'UNDO',
  });

  final String term, tag, summary, at;
  final VoidCallback? undo;
  final String undoLabel;
}

void confirmSaved(BuildContext context, SaveReceipt receipt, List<Warning> warnings);
void showFailure(BuildContext context, ShedFailure failure);
void showCapRow(BuildContext context, RefusalReason reason);
```

**The one new name this task introduces**, because P2 removed the mechanism `06 §10.3` relied on and
left the three signatures standing. Register it in `CONVENTIONS §2.11` in this commit rather than
letting it appear unannounced in a widget file:

```dart
/// The channel a receipt travels on now that there is no overlay. An
/// InheritedNotifier over a ValueNotifier<SaveReceipt?>, installed once by the
/// screen above its ledger. `confirmSaved` publishes; ShedReceiptBar reads it
/// to know which committed row is the live region and which row currently
/// carries the strike affordance (T05).
///
/// It is an InheritedNotifier and not a provider on purpose: a feedback
/// function has a BuildContext and no WidgetRef (R30), and `of(context)` is
/// the only lookup that signature permits.
final class ShedReceiptScope extends InheritedNotifier<ValueNotifier<SaveReceipt?>> {
  const ShedReceiptScope({super.key, required super.notifier, required super.child});
  static ValueNotifier<SaveReceipt?> of(BuildContext context);
}
```

What each function now does:

| Function | Channel 1 | Channel 2 | Channel 3 |
|---|---|---|---|
| `confirmSaved` | `HapticFeedback.successNotification()`, or `warningNotification()` when `warnings` is non-empty | publishes the `SaveReceipt` to `ShedReceiptScope`, so the just-committed **row** becomes the live region and gains the strike affordance | the row itself, already re-emitted by the drift stream — the only signal still true five seconds later |
| `showFailure` | `HapticFeedback.errorNotification()` | prints `failure.userMessage` as a ruled line in the same column, never a dialog and never a toast | — |
| `showCapRow` | **no haptic, deliberately** (`06 §10.1`) | a static `ShedBanner` row — never a modal, never on a shed screen, never 22:00–06:00 | — |

### 5.3 The details that are easy to get wrong

- **P2 forbids the fallback as well as the mechanism.** `06 §10.3` offers *"replace `SnackBar` with a
  house `ShedReceiptBar` in an `OverlayEntry`"* — and P2 says *"no floating overlay."* Both are out.
  The row in the ledger is the receipt. If you find yourself reaching for `Overlay.of(context)`, you
  have re-invented the toast with a different class name.
- **`ScaffoldMessenger` goes too, in both spellings.** `showSnackBar(` is P2's explicit target;
  `showMaterialBanner(` is the one `06 §10.3` hands `showCapRow`. Neither is a shed-screen surface, and
  the cap row's rendering is N30-T05's anyway. This task lands `showCapRow`'s **signature and its two
  guards** — never on a shed screen, never between 22:00 and 06:00 — and leaves the pixels to N30-T05,
  which owns the two static upgrade rows.
- **Verify the haptic member before you type it, and it takes five minutes.** `06 §10.1` asserts
  `successNotification`, `warningNotification` and `errorNotification` are real members of
  `HapticFeedback` on this SDK; `07 §5.5`, `10 §11` and `12` all carry the same member as
  **unverified**; `00-README` §10 lists it as a known open contradiction and `REFERENCES §22.E` E1
  states the check. Run it. If the member does not exist on 3.44.8, the commit haptic degrades to
  `heavyImpact()`, the design intent is unchanged, and the contradiction is closed in this commit
  rather than carried for another sixteen epics.
- **The success haptic fires on the transaction *returning*, never on the tap** (`06 §10.1`). A false
  receipt is worse than no receipt. That is why `confirmSaved` is called from `ref.listen` on
  `WriteDone`, not from `onPressed`.
- **`HapticFeedback.vibrate()` is banned** — on Android it is a long buzz — and there are exactly four
  patterns in the whole vocabulary. Adding a fifth is a design change, not an implementation detail.
- **The live-region label must differ every time or it does not re-announce.** A live region only
  re-fires on `didChangeLabel()`, and two saves in ten seconds is normal during triplets. The label is
  `'${receipt.term} ${receipt.tag} · ${receipt.summary} · ${receipt.at}'` — tag plus summary plus
  wall-clock time guarantees uniqueness. This is also why `at` is a `String` on the type: it is stable,
  pre-formatted and comparable.
- **Never `SemanticsService.announce`.** It is a silent no-op on Android, where `NO_ANNOUNCE` is set
  unconditionally, and Android 16 deprecates announcements outright in favour of live regions
  (decision #103).
- **Every displayed event time carries its provenance label.** `CONVENTIONS §5.4`: *"a bare `03:21` is
  a review failure."* The receipt reads `412 · triplets · 03:24 · recorded automatically`, with the
  label from `RecordedTime.provenanceLabel` — an exhaustive switch that can never be empty. `at` alone
  is not a receipt.
- **`AUTO-CAPTURED` is not an exempt stamp.** `02-build-manifest §4.4` defect 2: Indelible's
  `--t-stamp` is 14 px and the §3.4 exemption test fails on the three stamps that are the sole carrier
  of their meaning — `DEAD`, `AUTO-CAPTURED` and `DERIVED FROM N STROKES`. `AUTO-CAPTURED` is this
  file's, and it must meet the **18 px** floor. Every other stamp keeps the exemption.
- **`ShedFailure.userMessage` is not an ARB string and must not be re-typed here.** The six strings
  live on the six failure variants (`01 §5.1`) and are the only user-facing text outside the ARB in v1.
  `showFailure` renders `failure.userMessage` and never composes its own copy, never shows a code and
  never assigns blame.
- **`undoLabel` defaults to `'UNDO'` and is a field, not a constant** (R31). On a foster it is
  "Correct this"; on a treatment it is "Void this" — because a compensating event and a soft-void both
  leave visible history, and calling that "Undo" would be the app claiming to have erased something it
  did not. Quick Entry's lambing strike is the one case where the word is honest.
- **No swipe, no drag, no dismiss gesture on the receipt.** The row has exactly three ways to stop
  being the receipt (`06 §10.3`): the strike is tapped, the next save replaces it, or the route pops.
  `Dismissible` is banned outright and `dismissDirection` has nothing to attach to now that there is no
  `SnackBar`.
- **`showCapRow` fires no haptic and this is deliberate** (`06 §10.1`): both gated actions are calm-UI,
  and a buzz would turn a calm gate into a rebuke.
- **The receipt says nothing about money.** `over_free_cap` is monetization bookkeeping, not a warning
  (`11 §8.1`) — no badge, no colour, no line in the receipt. T07 is the test that holds it.
- **`lib/core/ui/` may not import `lib/data/`** (layer rule 7). `feedback.dart` takes values —
  `SaveReceipt`, `ShedFailure`, `List<Warning>`, `RefusalReason` — and never a repository, a row class
  or a provider.

### 5.4 The full test set

| File | Case | What it asserts |
|---|---|---|
| `test/policy/no_snackbar_test.dart` | `'showSnackBar( appears nowhere in lib/, including feedback.dart'` | **The anchor.** Source text over every non-generated file under `lib/` |
| | `'SnackBar, SnackBarAction, ScaffoldMessenger and showMaterialBanner appear nowhere in lib/'` | The four spellings that would bring the toast back under another name |
| | `'gesture.raw_snackbar has no allowlist entry'` | Parses `tool/policy_allowlist.txt`. A rule with an escape hatch is a rule that will be escaped |
| | `'the [exempt] section still has exactly four lines'` | R56, re-asserted here because this is the task most tempted to add a fifth |
| | `'Overlay.of and OverlayEntry appear nowhere under lib/features/ or lib/core/ui/feedback.dart'` | P2's *"no floating overlay"*, made mechanical |
| `test/features/quick_entry_test.dart` | `'the committed row renders as the receipt, one line above the live row'` | Indelible §7.3 and §8. The row is present, legible, and above — not over |
| | `'the receipt carries the time and its provenance label'` | `03:24` **and** `recorded automatically`. A bare time fails |
| | `'the receipt text is unique across two saves in the same minute'` | The live-region rule, asserted by comparing two labels rather than by reading the code |
| | `'the receipt is a liveRegion and no SemanticsService.announce is used'` | Through `ensureSemantics` (`12 §7.2`) |
| | `'the success haptic fires when the transaction returns, not when the key is pressed'` | Record haptic channel calls; assert none between the tap and the transaction completing |
| | `'a non-empty warnings list fires the warning haptic instead of the success haptic'` | `06 §10.1`. Empty means success; non-empty means warning; there is no third |
| | `'showFailure renders failure.userMessage and never a code'` | Force a `WriteFailed` and assert the exact string from the variant |
| | `'showFailure is not a dialog'` | `find.byType(Dialog)` and `find.byType(AlertDialog)` find nothing |
| | `'showCapRow renders nothing on Quick Entry'` | The shed-screen guard. T07 widens this across the entitlement and hour axes |
| | `'the receipt has no dismiss gesture'` | No `Dismissible`, no `GestureDetector` with a drag callback anywhere in its subtree |
| | `'the receipt row and its strike affordance are at least 64 by 64 with a semanticLabel'` | `06 §12`'s size contract for `ShedReceiptBar` |
| | `'every stamp that is the sole carrier of its meaning is at least 18 px'` | Defect 2: `AUTO-CAPTURED` measured, not assumed |

No `uk-zone` group here: this file formats nothing and reads no clock. `at` arrives pre-formatted from
`formatShedTime` (N09-T06), whose DST cases already cover the ambiguous hour.

## 6. Constraints that bind this task

- **Write path** — the row is created on screen entry, not on exit. No draft, no Save button, no `commit()`, no optimistic UI; every write commits immediately and goes through `guard()`.
- **3am** — every interactive element ≥ 64 × 64 with ≥ the ruled separation, 18 px text floor, dark only, and none of the banned gestures: no swipe, no drag, no long-press, no pinch, no slider.
- **Accessibility and the ARB, authored here** — every string in `app_en.arb` with a `description`, every element a `semanticLabel` and a `<screen>.<element>` key, every heading a `headingLevel:`. There is no later sweep that adds them; N33 only verifies.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.
- **Safety rule §12.5** — every time this file renders carries its provenance label, from
  `RecordedTime.provenanceLabel` and never re-typed.
- **Safety rule §12.2** — no copy added here contains a "should", a recommendation or a clinical claim.

## 7. Definition of Done

- [ ] `'showSnackBar( appears nowhere in lib/, including feedback.dart'` passes, and was seen to fail first for the stated reason
- [ ] `showSnackBar(` appears nowhere and has no allowlist entry
- [ ] the receipt renders the committed row, not a message about it
- [ ] `showCapRow` never renders on a shed screen
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] `SnackBar`, `SnackBarAction`, `ScaffoldMessenger`, `showMaterialBanner(`, `Overlay.of` and `OverlayEntry` appear nowhere in the receipt path
- [ ] `tool/policy_allowlist.txt`'s `[exempt]` section still has **exactly four** lines (R56)
- [ ] the three function names and signatures match R30 exactly; `showShedReceipt` and `showShedFailure` appear nowhere
- [ ] `ShedReceiptScope` is registered in `CONVENTIONS §2.11` in this commit, not introduced silently in a widget file
- [ ] `CONVENTIONS §2.11` and `06 §10.3` are amended in this commit, each struck with its reason (P2)
- [ ] the haptic member was **verified against the SDK** before it was typed, and the result is recorded — `00-README` §10's open contradiction is closed or the degrade to `heavyImpact()` is in the diff
- [ ] the receipt is a live region whose label differs on every save, and `SemanticsService.announce` appears nowhere
- [ ] the receipt carries its provenance label; no bare `03:24`
- [ ] `AUTO-CAPTURED` meets the 18 px floor

## 8. Verification

```bash
fvm flutter test test/policy/no_snackbar_test.dart
fvm flutter test test/features/quick_entry_test.dart
make check
make test
```

```bash
grep -rn "showSnackBar(\|SnackBar(\|SnackBarAction(\|ScaffoldMessenger" lib/ --include='*.dart'
grep -rn "showMaterialBanner(\|OverlayEntry\|Overlay.of" lib/ --include='*.dart'
grep -rn "SemanticsService.announce\|HapticFeedback.vibrate" lib/ --include='*.dart'
grep -n "raw_snackbar" tool/policy_allowlist.txt        # expect zero lines
# expect zero hits for all of the above
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(ui): feedback.dart — the receipt is the committed row`
