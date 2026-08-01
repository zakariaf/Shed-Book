# N09-T02 — `tokens.dart` — one flat `ThemeExtension`

| | |
|---|---|
| **Epic** | [N09 — The design system foundation](epic.md) · `00-README` §9 step 4 (1 of 3) |
| **Task** | 2 of 9 |
| **Depends on** | N09-T01 |
| **Commit** | one commit · `feat(ui): tokens.dart, one flat ThemeExtension with a snapping lerp` |

## 1. Why this task exists

`ShedTokens` as a single flat `ThemeExtension`, `ShedPalette`, `ShedPaletteId`,
`context.tokens`, and a `lerp` that **snaps** rather than interpolating — because a half-way colour
during a palette change is a colour nobody measured for contrast.

This is also the tier where Indelible's eleven tokens become `ShedTokens`' fields. T01 authored values
with no meaning; this task gives each one its job, under `06 §3.4`'s naming scheme, and it is the last
point at which the mapping is cheap to change. Everything from N10 onward reads these field names.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/06-design-system.md` | §3.3 (the full `ShedTokens` / `ShedPalette` / `ShedPaletteId` body, `copyWith`, `lerp`, `ShedTokensX`) · §3.4 (the naming scheme and the two hard rules) · §2.5 (which accessibility flag feeds `motion`) · §4.7 (`photoTint` and its one consumer) | the type shapes, the field names, the accessor |
| `docs/engineering/CONVENTIONS.md` | §2.11 (the design-system type catalogue) · §4.2 (`Shed*` for a design token set) · R35 (palette ids and stored keys) | **BINDING** on every name and signature in this file |
| `docs/design/indelible.md` | §2.2–§2.3 (five surfaces, three inks, one hue) · §2.7 (**there is no status palette** — every state carries at least two non-colour channels) · §5.1–§5.3 (what `motion` is for) | which Indelible token becomes which `ShedTokens` field |
| `docs/engineering/03-data-model-and-schema.md` | §5.13 | `app_settings.palette`'s CHECK is `IN ('night','amber','red')` — the enum keys must be those strings |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `indelible-design-system` | it owns which value carries which job, and the rule that a status is never colour alone |
| `shed-conventions` | `CONVENTIONS §2.11` names the types and `§3` the provider that will read them |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/design/tokens_test.dart`
- **Test** — `'context.tokens resolves every token and lerp snaps rather than interpolating a colour'`
- **Why it is red today** — nothing exposes a token, so every widget would reach for `Theme.of(context).colorScheme`.

```bash
fvm flutter test test/design/tokens_test.dart   # expect: failing, for the reason above
```

Sharpen the assertion: pump a `MaterialApp` whose `ThemeData.extensions` carries one `ShedTokens`,
read **every** field through `context.tokens` inside a builder, then call
`a.lerp(b, t)` for `t` in `{0.0, 0.25, 0.49, 0.50, 0.75, 1.0}` over a pair of different palettes and
assert that **every** field of the result is identical to the corresponding field of `a` or of `b` —
never a third value. That is the executable form of *"a colour nobody measured for contrast"*.

**Green.** The minimum code that passes, and nothing beyond it — the flat extension, the accessor, and a `lerp` that returns `b` for `t >= 0.5` and `a`
below it.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**UI and tests only.** No schema, no domain, no data, no wiring, no controller, no ARB string. Say so
in the commit message.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `lib/core/ui/tokens.dart` | **New.** `ShedPaletteId`, `ShedPalette`, `ShedTokens` and the `ShedTokensX` extension. Imports `package:flutter/material.dart` (it extends `ThemeExtension`) and **not** `primitives.dart` — this file holds no value at all, only fields |
| 2 | `test/design/tokens_test.dart` | **New.** The anchor, plus the field-coverage and `lerp` cases in §5.4 |

That is the whole diff. `palettes.dart` is T03 and it is the only file that imports `primitives.dart`.

### 5.2 The signatures

`06 §3.3` and `CONVENTIONS §2.11` fix these exactly. Type them as printed; a rename here is a rename
in twenty-one components.

```dart
// lib/core/ui/tokens.dart
import 'package:flutter/material.dart';

/// The member and the stored key are the same string, so `app_settings.palette`
/// can be read off the enum and back (CONVENTIONS R35). 03's CHECK is
/// `IN ('night','amber','red')`; `deepRed`'s key is `'red'`.
enum ShedPaletteId {
  night('night'),
  amber('amber'),
  deepRed('red');

  const ShedPaletteId(this.key);
  final String key;
}

@immutable
final class ShedPalette {
  const ShedPalette({
    required this.id,
    required this.highContrast,
    required this.name,
    required this.colorScheme,
    required this.tokens,
  });

  final ShedPaletteId id;
  final bool highContrast;
  final String name;             // 'night', 'night-hc', 'amber', … — test group names
  final ColorScheme colorScheme;
  final ShedTokens tokens;
}
```

`ShedTokens` is **one flat class, never five nested ones** — `Theme.of(context).extension<T>()` is a
map lookup per call, and a flat object is trivially diffable, lerpable and testable. Its constructor
takes every field as `required`, in `06 §3.3`'s order:

```dart
@immutable
final class ShedTokens extends ThemeExtension<ShedTokens> {
  final ShedPaletteId id;
  final bool highContrast;
  final Color surfaceBase, surfaceRaised, surfacePressed, surfaceFill, outline;
  final Color textNumeric, textPrimary, textSecondary, textChrome;
  final Color statusReady, statusAttention, statusLoss, onStatus;
  final double tapMin, tapPrimary, tapHero, gapMin, gapDestructive;
  final double outlineWidth, radiusControl, bodySize, numeralSize;
  final Duration motion;
  final ColorFilter? photoTint;   // non-null only in a night-shift palette (§4.7)
}
```

Three members carry the whole design of the file:

```dart
  /// Only `motion` and `highContrast` are ever overridden at runtime, so the
  /// signature is narrow on purpose: a wide copyWith invites a widget to build
  /// a one-off token set, which is exactly what the two tiers exist to stop.
  @override
  ShedTokens copyWith({Duration? motion, bool? highContrast});

  // Signature per api.flutter.dev:
  //   ThemeExtension<T> lerp(covariant ThemeExtension<T>? other, double t)
  @override
  ShedTokens lerp(covariant ShedTokens? other, double t);
```

```dart
/// The ONLY way a widget gets a colour or a size.
extension ShedTokensX on BuildContext {
  ShedTokens get tokens => Theme.of(this).extension<ShedTokens>()!;
}
```

**The Indelible → `ShedTokens` mapping is this task's decision, and it is not one-to-one.** Record it
in a doc comment at the top of the file, because every reviewer from N10 onward will want it:

| `ShedTokens` field | Indelible token | Note |
|---|---|---|
| `surfaceBase` | `--page` | the first painted frame |
| `surfaceRaised` | `--sheet` | the bottom sheet, the only overlay in the app |
| `surfacePressed` | `--row-pressed` | a row under the thumb, 40 ms |
| `surfaceFill` | `--slab` | button fills — the only filled shapes |
| *(a fifth surface)* | `--slab-pressed` | **`06 §3.3` has four surfaces; Indelible has five.** `06 §1`: *"If a direction needs a token this system does not have, add the token to `ShedTokens`"* — add it, name it with the `surface*` prefix per §3.4, and do not reuse `surfacePressed` for both a row and a slab: they are different hexes with different placement rules |
| `outline` | `--rule` | **non-text only**, 3.52:1 |
| `textNumeric` · `textPrimary` | `--ink-full` | Indelible has no separate numeral ink; the tabular figure comes from the *role*, not a colour |
| `textSecondary` | `--ink-mid` | |
| `textChrome` | `--ink-low` | struck text and gap labels. `06 §4.2`: chrome is *"never a value the shepherd must read"* — and struck text **is** read, forever, so check this mapping against `indelible.md` §7.3's struck row before you commit it |
| `statusReady` · `statusAttention` · `statusLoss` · `onStatus` | *no Indelible equivalent* | see the gotcha below |
| `outlineWidth` | `--rule-w` 2 | never 1 — a hairline shimmers or vanishes on a mid-range Android at low brightness |
| `radiusControl` | `--radius-slab` 2 | `--radius-record` is 0: *"a document has no corners"* |
| `bodySize` · `numeralSize` | §3.4's scale | 18/20 and 40/44 — type metrics a palette may shift, never a `TextStyle` |
| `tapMin` · `tapPrimary` · `tapHero` · `gapMin` · `gapDestructive` | §4.5's audit | 60 is the contract floor; Indelible builds to 64 |

### 5.3 The details that are easy to get wrong

- **`covariant` is not optional on `lerp`.** The framework signature is
  `ThemeExtension<T> lerp(covariant ThemeExtension<T>? other, double t)`. Writing
  `ShedTokens lerp(ShedTokens? other, double t)` without `covariant` is an invalid override and the
  analyzer says so — but the error message points at the parameter type, not at the missing keyword,
  and it is the single easiest compile error to make in this file. Handle `other == null` by returning
  `this`.
- **Full snapping is a deliberate narrowing of `06 §3.3`, and it must be recorded.** `06 §3.3`'s
  printed body interpolates the `Color` fields with `Color.lerp` and snaps only the non-`Color` ones;
  `CONVENTIONS §2.11` says *"`lerp` snaps every non-`Color` field at `t < 0.5`"*. This task's anchor
  test and Definition of Done ask for **no intermediate colour at all**, which is Indelible rule 4
  applied one level harder: a colour produced by interpolation is a colour nobody measured, and
  `00-README` §2.3's hierarchy prefers *unrepresentable* over *documented*. The cost is zero, because
  `06 §2.1` and §4.8 already pin `themeAnimationDuration: Duration.zero` — *"a 200 ms lerp between
  night and deep red drags every colour through a desaturated, low-contrast midpoint"* — so no
  intermediate `t` is ever produced in the app anyway. **Take the narrowing, and amend `06 §3.3` in
  this commit** per `00-README` §10's amendment rule, or state it in the PR body. Do not implement one
  thing and leave the document saying another.
- **`copyWith` takes exactly two named parameters and no more.** `{Duration? motion, bool? highContrast}`.
  Everything else is passed through verbatim. Widening it — even "just for a test" — is how a widget
  ends up building a one-off token set that no contrast test ever sees. The narrowness *is* the
  feature.
- **Because every field is `required` with no default, dropping one inside `copyWith` or `lerp` is a
  compile error rather than a silent zero.** Keep it that way: never give a field a default value, and
  never make one nullable except `photoTint`.
- **Indelible has no status palette, and `statusLoss` is the trap.** `indelible.md` §2.7 is explicit:
  a lamb that died prints the word `DEAD`, in full ink, with *"colour: **none, ever**"*. The three
  status fields still exist — `06 §12`'s `ShedStatusBadge` and `contrast_test.dart`'s
  `contrastRatio(onStatus, statusX)` assertion both need them — so give them Indelible ink values and
  record in the doc comment that **the field existing does not license a component to use it as the
  only channel**. `06 §11`'s own rule agrees: colour + shape + text + position, always. If in doubt,
  map `statusLoss` to full ink and let the word carry the meaning; that is the direction's answer and
  it is not negotiable in a component in N10.
- **The two hard naming rules (`06 §3.4`).** No token is named after a colour — `amberWarning` is
  banned, it is `statusAttention`. No token is named after a screen — `penTileBorder` is banned, the
  pen tile uses `outline`. Both survive a palette change; a colour name does not.
- **`ShedTokens` holds no `TextStyle` and no `TextTheme`.** It holds `bodySize` and `numeralSize` as
  `double`s, and `buildShedTextTheme(t)` in `theme.dart` (T04/T05) turns them into roles. A
  `TextStyle` on the extension would be a second place a font size could come from, and
  `token.literal_font_size` exists precisely because there must be one.
- **`context.tokens` ends in `!` and that is intentional.** A `MaterialApp` built without the
  extension must fail loudly on the first build, not paint a fallback colour nobody measured. The
  consequence lands on tests: **every** widget test in this project pumps through `pumpApp`
  (N12-T05), which installs the extension. A bare `tester.pumpWidget(MaterialApp(home: …))` in a test
  written before then will throw a null check on a widget deep in the tree, and the message will not
  mention tokens. Say so in a doc comment beside the accessor.
- **`deepRed`'s key is `'red'`, not `'deepRed'` or `'deep_red'`** (R35). It is the one member whose
  key does not match its name, and `03 §5.13`'s CHECK constraint is what makes a mismatch a runtime
  write failure rather than a compile error. The Settings labels are also frozen and typed exactly:
  `Night`, `Amber (recommended)`, `Deep red (best for night vision, hardest to read)`, plus a separate
  `High contrast` switch.
- **`photoTint` is a `ColorFilter?` and Indelible does not use a filter for the palette.**
  `indelible.md` §2.6 rejects a filter as the *mechanism* for red-shift — peak luminance is halved
  through the platform brightness API, *"not a CSS `filter`, because a filter would also dim the press
  feedback and would be a lie about what the display is doing."* The field survives for `ShedPhoto`
  alone (`06 §4.7`), which is N10's. A global `ColorFiltered` over the app is banned outright.
- **This file must not import `primitives.dart`.** It declares fields, not values. If you find
  yourself needing a hex here, the field you are adding belongs in T03's palette literals.

### 5.4 The full test set

`test/design/tokens_test.dart` — widget tests for the accessor, pure unit tests for `lerp`.

| Case | What it asserts |
|---|---|
| `'context.tokens resolves every token and lerp snaps rather than interpolating a colour'` | **The anchor.** Every field readable through the accessor inside a pumped builder; `lerp` at six values of `t` produces only endpoint values |
| `'lerp returns this when other is null'` | The framework calls it that way during theme teardown |
| `'lerp switches at exactly t = 0.5'` | `t = 0.49` is `a` field-for-field, `t = 0.50` is `b` field-for-field. The boundary, named, so nobody "fixes" it to `>` later |
| `'no lerp result contains a value present in neither operand'` | Iterate all six palettes pairwise. This is the case that would catch a stray `Color.lerp` left behind in one field |
| `'the metric fields never take an intermediate value'` | `tapMin` is 60.0 or 64.0 and never 63.4 — *"a tap target that is 63.4 pt for 150 ms breaks the 60 pt contract for 150 ms"* (`06 §3.3`) |
| `'copyWith declares exactly two named parameters'` | A source-text assertion over `tokens.dart`. The narrowness is the design; a widened `copyWith` is the regression |
| `'copyWith(motion:) leaves every other field identical'` | Field-by-field equality against the original — catches a dropped pass-through if a future edit makes a field nullable |
| `'ShedPaletteId keys are night, amber and red'` | And the set equals `03 §5.13`'s CHECK vocabulary, read from the schema document's own list rather than retyped |
| `'no ShedTokens field is named after a colour or a screen'` | Source text: no field name contains `amber`, `red`, `green`, `salmon`, `pen`, `keypad`, `ewe` or `lamb` (`06 §3.4`) |
| `'ShedTokens holds no TextStyle and no TextTheme'` | Source text. The one place a font size comes from is `buildShedTextTheme` |
| `'every Indelible token in §2.2 and §2.3 maps to exactly one ShedTokens field'` | The mapping table in the file's doc comment is complete and has no field mapped twice |

**Nothing here is time-shaped** — `motion` is a `Duration` but no wall clock is read, so there is no
`uk-zone` case. T06 is the first task in this epic with one.

## 6. Constraints that bind this task

- **3am** — `tapMin`, `bodySize` and the surfaces are fields on this type, so the whole floor is
  expressible here. A field that can hold a value below 60 or below 18 is a field the contrast and
  tap-target gates have to catch later; the `required`-everywhere constructor is what keeps a
  half-built token set from existing at all.
- **Two tiers, and the boundary is this file.** No hex, no import of `primitives.dart`, no `TextStyle`.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.
- **Colour is never the only channel** (decision #106, WCAG 1.4.1 Level A). The status fields exist;
  the licence to use one alone does not.

## 7. Definition of Done

- [ ] `'context.tokens resolves every token and lerp snaps rather than interpolating a colour'` passes, and was seen to fail first for the stated reason
- [ ] one flat extension, no nesting
- [ ] `lerp` snaps and the test proves no intermediate colour is produced
- [ ] every token has a name from `indelible.md`, not an invented one
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] `lerp` is declared `covariant` and returns `this` for a null `other`
- [ ] `copyWith` takes exactly `{Duration? motion, bool? highContrast}` and every other field is passed through verbatim
- [ ] `ShedPaletteId` keys are `night` / `amber` / `red` and match `app_settings.palette`'s CHECK
- [ ] the Indelible → `ShedTokens` mapping is written as a doc comment in the file, including the fifth surface and the status-field caveat
- [ ] `tokens.dart` imports neither `primitives.dart` nor anything under `lib/data/` (layer rule 7)
- [ ] **if full snapping was taken, `06 §3.3` is amended in this commit or the narrowing is stated in the PR body**

## 8. Verification

```bash
fvm flutter test test/design/tokens_test.dart
fvm flutter test test/design/                 # nothing else in the folder regressed
make check
make test
```

```bash
grep -n "Color.lerp" lib/core/ui/tokens.dart      # expect no hits if full snapping was taken
grep -n "copyWith(" lib/core/ui/tokens.dart       # expect one, with two named parameters
grep -rn "primitives.dart" lib/core/ui/tokens.dart # expect zero
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(ui): tokens.dart, one flat ThemeExtension with a snapping lerp`
