# N03-T05 — The design rules

| | |
|---|---|
| **Epic** | [N03 — The gate](epic.md) · `00-README` §9 step 1 |
| **Task** | 5 of 7 |
| **Depends on** | N03-T04 |
| **Commit** | one commit · `feat: the design rules — raw hex, magic size, the gesture ban, no snackbar` |

## 1. Why this task exists

`design.raw_hex` (a `Color(0x…)` outside `lib/core/ui/primitives.dart`), `design.magic_size`
(a numeric literal in a padding, gap, width or height), the **whole gesture ban** — `Dismissible`,
`Draggable`, drag handles, `onLongPress`, `GestureDetector.onScaleUpdate`, `Slider`, `Tooltip` —
plus `showSnackBar(`, `CircularProgressIndicator` and `showDialog(`. The last three are P2 and the
one-overlay rule made mechanical.

These are the 3am test with teeth. A banned gesture is not a style preference: a swipe-to-delete on a
lambing row, performed with a wet glove through a freezer bag at 03:20, deletes a record the shepherd
cannot get back. `00-README` §2.2 holds that clause with *"the gesture ban as `check_policy` rows"* —
this task is that sentence becoming a file.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/06-design-system.md` | §3.5 | the whole `_bannedPattern` table, verbatim — tokens, themes, typography, gestures, the one `a11y` row |
| `docs/engineering/CONVENTIONS.md` | §4.7 | the canonical ids: `token.*`, `gesture.*`, `ui.spinner`, `ui.show_dialog` — there is no `design` namespace |
| `docs/engineering/CONVENTIONS.md` | §6 R55, R56 | `token.raw_color` and `token.material_color` are scoped `lib/`, and the `[exempt]` list is exactly four lines |
| `docs/skills/02-build-manifest.md` | §4.1 | **P2** — there is no SnackBar, including in `feedback.dart`; the receipt is the committed row |
| `docs/design/indelible.md` | §9 | *"no toast, no snackbar, no modal dialog anywhere in the app"* |
| `docs/engineering/CODE-REVIEW-CHECKLIST.md` | §1.13 | the gesture list as a reviewer reads it, with each row's trigger spelled out |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `indelible-design-system` | the design front door owns every token, size, gesture and motion rule |
| `shed-conventions` | the rule ids and the exempt-line format |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/policy/gate_rules_test.dart`
- **Test** — `'design.raw_hex, design.magic_size, design.banned_gesture, design.snackbar, design.spinner and design.dialog each exit 1 on their planted violation'`
- **Why it is red today** — a raw hex, a magic size and a `Dismissible` all pass today.

```bash
fvm flutter test test/policy/gate_rules_test.dart   # expect: failing, for the reason above
```

The test title is the backlog's anchor and stays exactly as written. **The six names in it are the
plan's shorthand; the ids the assertions match on are `CONVENTIONS` §4.7's**, because §4.7 lists the
seventeen namespaces this project has and `design` is not one of them:

| The title says | The row is |
|---|---|
| `design.raw_hex` | `token.raw_color` (`Color(0x`) and `token.raw_color_ctor` (`Color.fromARGB(` / `Color.fromRGBO(`) |
| `design.magic_size` | `token.magic_size` |
| `design.banned_gesture` | the **fourteen** `gesture.*` rows — eleven in `06 §3.5` plus `gesture.dismissible`, `gesture.draggable` and `gesture.tooltip`, which are literal rows in `01 §3.2`. `CODE-REVIEW-CHECKLIST` §1.8: *"Count the table, never the sentence"* — `10 §10` says eleven and is counting only one document's half |
| `design.snackbar` | `gesture.raw_snackbar` |
| `design.spinner` | `ui.spinner` |
| `design.dialog` | `ui.show_dialog` |

**Green.** The minimum code that passes, and nothing beyond it — six rules, each planted and watched; `showSnackBar(` has **no** exempt line, including for
`feedback.dart` — P2 removed the last legitimate call site.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in the order you touch them

No schema, no domain, no data, no UI, no ARB — say so in the commit message (`00-README` §8). This is
the largest single table in the epic and it is still two files.

| # | File | What changes, and why |
|---|---|---|
| 1 | `tool/check_policy.dart` | `_bannedPattern` is filled in from `06 §3.5` — it is `final`, not `const`, because `RegExp` has no const constructor. Two rows widen scope per R55. Two rows change from `06 §3.5` as printed, per P2. `_bannedText` gains `token.raw_color` and `token.material_color` |
| 2 | `test/policy/gate_rules_test.dart` | One planting case per row, table-driven off a `Map<String, String>` of id → the smallest source that must trip it. That map is what N03-T07's inventory assertion iterates, so build it as data, not as thirty hand-written `test()` calls |

**No allowlist line is added.** R56's four are already there from N03-T01, and two of them
(`primitives.dart`, `night_error_panel.dart`) are for rows this task lands — so those two exemptions
become live here for the first time, against files that do not exist until N09 and N11.

### 5.2 The signatures

The second table, with the same tuple shape, the same allowlist keys and the same exit code as
`_bannedText`. The driver gains one extra `for` loop beside the existing one:

```dart
/// (id, pattern, path prefix it applies under, why)
/// Same driver, same allowlist keys ('<path> :: <id>'), same exit code.
final _bannedPattern = <(String, RegExp, String, String)>[ … ];
```

The rows, grouped as `06 §3.5` groups them. Copy the patterns exactly — several are load-bearing in
ways a re-derivation loses:

- **tokens** — `token.raw_color_ctor`, `token.seeded_scheme`, `token.literal_font_size`,
  `token.color_scheme_read` (scoped `lib/features/`), `token.color_scheme_read_ui` (scoped
  `lib/core/ui/components/`), `token.primitives_import`, `token.magic_size`.
- **themes** — `theme.mode`, `theme.brightness`, `theme.platform_brightness`, `theme.light_factory`,
  `theme.deprecated_scheme_role`.
- **typography** — `type.google_fonts`, `type.clamp`, `type.weight_cap`, `type.fitted_box`.
- **gestures** — `gesture.long_press_draggable`, `gesture.interactive_viewer`, `gesture.refresh`,
  `gesture.long_press`, `gesture.scale`, `gesture.drag`, `gesture.drag_handle`,
  `gesture.sheet_drag`, `gesture.slider`, `gesture.horizontal_swipe`, `gesture.raw_snackbar`,
  plus the three literal rows already in `_bannedText`: `gesture.dismissible`, `gesture.draggable`,
  `gesture.tooltip`.
- **semantics** — `a11y.announce`, plus `10 §10`'s three: `a11y.sort_key` (`OrdinalSortKey`,
  `sortKey:`), `a11y.merge_semantics` (`MergeSemantics`) and `a11y.material_picker`
  (`showDatePicker(`, `showTimePicker(` — the dial is a drag, the keyboard mode is the system IME
  and the cells are under 60 pt, which is why `CODE-REVIEW-CHECKLIST` §1.8 groups it with the
  gesture ban rather than with accessibility).
- **added by `CONVENTIONS` §4.7, which no document had as a row** — `ui.spinner`
  (`CircularProgressIndicator` under `lib/features/`) and `ui.show_dialog` (`showDialog(` outside the
  two allowlisted destructive files).

Three rows differ from `06 §3.5` as printed, and all three differences are rulings, not taste:

```dart
// R55: scoped lib/, not lib/features/ — lib/core/ui/components/ is exactly where
// a shared widget would hide a raw hex. The two [exempt] lines are the only escape.
('token.raw_color',     'Color(0x', 'lib/', 'read ShedTokens — #97'),
('token.material_color','Colors.',  'lib/', 'read ShedTokens — #97'),

// P2 (02-build-manifest §4.1) supersedes CONVENTIONS §2.11 and 06 §3.5's scope.
// Indelible §9 bans toasts, snackbars and modal dialogs outright, which made
// undo-until-the-snackbar-is-dismissed unimplementable — so Indelible won. The
// confirmation IS the committed row, in ink, one line above the one being
// written; undo is a time-boxed strike in that row's margin, its window stated
// in seconds. feedback.dart is no longer a legitimate call site, so this row is
// scoped lib/ and has NO allowlist entry, ever.
('gesture.raw_snackbar', RegExp(r'showSnackBar\('), 'lib/',
    'the receipt is the committed row — P2, indelible §9'),

// 10 §10 records this as a live defect: as 06 §3.5 prints it the pattern is
// SemanticsService\.announce, which does NOT match sendAnnouncement — while
// 10 §3.8 bans both spellings and 10 §11 row 2 claims the gate catches both.
// As printed, the claim is false and the Android no-op ships. Widen it here.
('a11y.announce', RegExp(r'SemanticsService\.(announce|sendAnnouncement)\b'), 'lib/',
    'no-op on Android — use a liveRegion — #103'),
```

The `token.magic_size` pattern, which is the one nobody should retype:

```dart
// 0 and 1 are not magic; everything else is a token you failed to name.
('token.magic_size', RegExp(
    r'(EdgeInsets\.\w+\(|SizedBox\(|BoxConstraints\(|Size\(|'
    r'(?:Border)?Radius\.circular\(|'
    r'(?:width|height|minWidth|minHeight|maxWidth|maxHeight|spacing|'
    r'strokeWidth|elevation|letterSpacing):)'
    r'\s*(?![01](?:\.0+)?\s*[,)])[0-9]'), 'lib/',
    'magic size — use the spacing or tap scale — §3.2'),
```

### 5.3 The details that are easy to get wrong

- **There is no `design` namespace.** `CONVENTIONS` §4.7 lists seventeen and `design` is not among
  them. Spelling a row `design.raw_hex` means the id in `[exempt]` lines, in commit messages and in
  N03-T07's inventory never matches the one in the table — and R54 exists because *"a duplicate rule
  is a rule that gets weakened twice."* Use §4.7's ids; the anchor test's title keeps the plan's
  wording because it is the backlog's anchor, and the mapping table in §4 above is the bridge.
- **`showSnackBar(` has no exemption — and the document that says otherwise is still on disk.**
  `CONVENTIONS` §2.11 calls `feedback.dart` *"the one file permitted to call `showSnackBar(`"*, R30
  repeats it, and `06 §3.5` scopes the row to `lib/features/` for exactly that reason. **P2
  supersedes all three.** A developer reading `CONVENTIONS` will add the exemption in good faith;
  the comment above the row is what stops them. N14-T04 is the commit where `feedback.dart` is
  written without one, and its anchor test is
  `'showSnackBar( appears nowhere in lib/, including feedback.dart'`.
- **`token.magic_size`'s negative lookahead is the whole rule.** `(?![01](?:\.0+)?\s*[,)])` is what
  lets `EdgeInsets.all(0)` and `SizedBox(height: 1)` through while catching `SizedBox(height: 12)`.
  Simplify it — "surely `[0-9]` is enough" — and every hairline divider and every zero inset in the
  codebase becomes a violation, the rule gets an exemption per file, and within a month it is dead.
  It also only fires on the **literal** form: `SizedBox(height: kGap)` passes, which is the point —
  `CODE-REVIEW-CHECKLIST` §1.7 shows the idiom, `const _gap = 12.0;` at the top of the file, *"named,
  so `token.magic_size` never fires"* — and then shows what it therefore misses (`_gap * 2.5`,
  `Opacity(opacity: 0.6, …)`, an alpha literal inside `withValues`), which is a reviewer's job and
  not a row.
- **`token.material_color` bans the literal `Colors.`, which also matches `Colors.transparent`.**
  That is intended: `context.tokens` owns every colour including the absent one. Do not add an
  exemption; add a token.
- **`gesture.tooltip` bans `Tooltip(` and it will surprise somebody.** A tooltip is a long-press
  affordance on touch, and long-press is banned, so the widget is banned — `00-README` §2.2 lists it
  beside `Dismissible` and `Draggable` for that reason. `CLAUDE.md` names the same three.
- **`gesture.sheet_drag` bans `enableDrag: true`, not the default.** `showModalBottomSheet` defaults
  `enableDrag` to **true**, so the rule catches only the explicit spelling and misses the default.
  That gap is closed by `ui.show_dialog` and by `ShedBottomSheet` being the only overlay in the app
  (`00-PLAN-CRITIQUE` §8 G1) — the sheet is constructed in one place, and that place sets
  `enableDrag: false`. Say so in the row's comment so the gap is recorded rather than discovered.
- **`ui.show_dialog` allowlists two files and they do not exist yet.** The two destructive flows —
  delete-season and restore-from-backup — arrive in N23 and N29. Until then the rule has no
  exemption at all, and that is correct; the exemptions arrive with the files, in the commits that
  need them, each with its reason.
- **`token.color_scheme_read` and `token.color_scheme_read_ui` are two rows for one idea** because
  the tuple carries a single path prefix and the idea spans two prefixes. Do not merge them into one
  row with a widened scope: `lib/core/ui/theme.dart` and `lib/core/ui/palettes.dart` legitimately
  build a `ColorScheme` and would fire.
- **The gate walks `test/` and every row here is scoped under `lib/`**, so the proving cases may
  plant `Dismissible(` and `Color(0x` as strings in the temp tree without tripping the gate on the
  test file itself. That is a property of the scopes, not luck — if a later ruling widens one of
  these rows to both roots, the proving case has to change with it.
- **One case per row, and the cases are data.** Write a `Map<String, String>` from id to the smallest
  snippet that must trip it and iterate it; do not hand-write thirty-odd `test()` bodies. That is
  where a row lands with no case and N03-T07's inventory assertion goes red two tasks later for a
  reason nobody can find. It is also why the count is never written down as a number: derive it from
  the table, because `CODE-REVIEW-CHECKLIST` §1.8's standing instruction is *"count the table, never
  the sentence"* and three documents already disagree about how many `gesture.*` rows there are.

### 5.4 The full test set

| Case | Plant | Expect |
|---|---|---|
| the anchor, six named rules | one file per row: `Color(0xFF0B0D0E)`, `SizedBox(height: 12)`, `Dismissible(`, `showSnackBar(`, `CircularProgressIndicator(`, `showDialog(` | six violations, ids `token.raw_color`, `token.magic_size`, `gesture.dismissible`, `gesture.raw_snackbar`, `ui.spinner`, `ui.show_dialog` |
| every remaining row, table-driven | the id → snippet map | one violation per row, each naming its own id |
| **edge** — `EdgeInsets.all(0)` | `lib/features/pens/pen_board_screen.dart` | zero violations — 0 is not magic |
| **edge** — `SizedBox(height: 1)` and `SizedBox(height: 1.0)` | same | zero violations — 1 is not magic |
| **edge** — `SizedBox(height: kGap)` | same | zero violations — a named constant is the remedy the rule is asking for |
| **edge** — `SizedBox(height: 1.5)` | same | **one** violation — 1.5 is not 1, and a hairline that is not a token is still a magic size |
| **edge** — `Colors.transparent` | same | one violation — `context.tokens` owns the absent colour too |
| **edge** — `primitives.dart` is exempt | `lib/core/ui/primitives.dart` containing `Color(0x…)` | zero violations, via the R56 line — and the exemption is keyed to that path and that id only |
| **edge** — `palettes.dart` importing primitives is exempt | the `token.primitives_import` line | zero violations |
| **edge** — a third file importing primitives | `lib/core/ui/components/shed_pen_tile.dart` | one violation, id `token.primitives_import` — the exemption does not generalise |
| **edge** — `feedback.dart` has no exemption | `lib/core/ui/feedback.dart` containing `showSnackBar(` | **one** violation. This is P2, and it is the case a future contributor will try to delete |
| **edge** — `enableDrag: false` | `lib/core/ui/components/shed_bottom_sheet.dart` | zero violations |
| **edge** — a raw hex in a generated file | `lib/core/db/database.g.dart` containing `Color(0x…)` | zero violations — generated files are never scanned |
| **edge** — both announce spellings | one file with `SemanticsService.announce`, one with `SemanticsService.sendAnnouncement` | **two** violations, both `a11y.announce`. The second is the case that would have passed against `06 §3.5`'s printed pattern |
| **edge** — `showDatePicker(` | `lib/features/treatments/treatments_screen.dart` | one violation, id `a11y.material_picker` — the shepherd enters a date on the keypad, never on a dial |

Nothing here is time-shaped, so no `uk-zone` case. The one thing this task cannot assert is contrast:
a regex cannot express a luminance ratio, and its companion is `test/design/contrast_test.dart`,
which is N09's.

## 6. Constraints that bind this task

- **3am** — every interactive element ≥ 64 × 64 with ≥ the ruled separation, 18 px text floor, dark only, and none of the banned gestures: no swipe, no drag, no long-press, no pinch, no slider. This task is where "none of the banned gestures" stops being a sentence: thirteen `gesture.*` rows, each watched to fire.
- **The gesture list matches `CLAUDE.md`'s ban exactly** — nothing added and nothing missing. `CODE-REVIEW-CHECKLIST` §1.13 prints the same list with each row's trigger; if the two disagree, one of them is wrong and it is a `CONVENTIONS` §6 ruling, not a keyboard decision.
- **P2 is settled and outranks a BINDING document.** `showSnackBar(` is banned everywhere including `feedback.dart`; the confirmation is the committed row; undo is a time-boxed strike whose window is stated in seconds, never in terms of a widget's lifetime.
- **Accessibility and the ARB, authored here** — every string in `app_en.arb` with a `description`, every element a `semanticLabel` and a `<screen>.<element>` key, every heading a `headingLevel:`. There is no later sweep that adds them; N33 only verifies. This task authors no string, but it lands `a11y.announce` and `a11y.header_bool`, which are the two rows that make a later sweep unnecessary.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'design.raw_hex, design.magic_size, design.banned_gesture, design.snackbar, design.spinner and design.dialog each exit 1 on their planted violation'` passes, and was seen to fail first for the stated reason
- [ ] all six rules fire on their planted violations
- [ ] `showSnackBar(` is banned with no exemption anywhere
- [ ] the gesture list matches `CLAUDE.md`'s ban exactly, with nothing added and nothing missing
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
dart run tool/check_policy.dart
fvm flutter test test/policy/gate_rules_test.dart
```

Then watch the two that matter most fire against the real tree — the one that protects a record, and
the one P2 rules on:

```bash
mkdir -p lib/features/lambing lib/core/ui
printf "Widget b() => Dismissible(key: k, child: c);\n" > lib/features/lambing/_plant.dart
printf "void f() { m.showSnackBar(s); }\n"              > lib/core/ui/_plant.dart
dart run tool/check_policy.dart ; echo "exit=$?"   # gesture.dismissible + gesture.raw_snackbar, exit=1
rm lib/features/lambing/_plant.dart lib/core/ui/_plant.dart
grep -c '::' tool/policy_allowlist.txt             # 4 — R56, unchanged by this commit
make check
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat: the design rules — raw hex, magic size, the gesture ban, no snackbar`
