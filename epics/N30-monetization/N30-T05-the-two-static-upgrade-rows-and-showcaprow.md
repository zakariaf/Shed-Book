# N30-T05 — The two static upgrade rows and `showCapRow`

| | |
|---|---|
| **Epic** | [N30 — Monetization](epic.md) · `00-README` §9 step 11 |
| **Task** | 5 of 8 |
| **Depends on** | N30-T04 |
| **Commit** | one commit · `feat(monetization): the two upgrade rows and their four constraints` |

## 1. Why this task exists

Two rows, four hard constraints: never on a shed screen, never mid-entry, never between
22:00 and 06:00, never modal. The cap speaks in daylight, in a row, once — or it does not speak.

A permanent static row converts worse than a well-timed modal. That is the **deliberate trade**
(`11 §8`), taken because spec §5's *"zero interruptions"* is written as a shipping gate and because this
audience is described as vocally hostile to farm-software nagging and will punish an app that does it.
The conversion mechanism is the **season wall**, not the prompt: it lands exactly where spec §7.7 says
the value is — opening last year's history in season two — so the app asks for money at the moment it
has proved itself.

This task also has to make a ruling nobody upstream made. `11 §2` requires
`app_settings.last_unlock_prompted_at` and says it *"must land before the first schema snapshot"*. It
did not, and N07-T08 froze v1 without it. Read §5.5 before you write the once-a-day rule.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/11-monetization-and-store.md` | **§8** (the four hard constraints, each with the failure it prevents; the soliciting-versus-selling distinction; the once-per-civil-day rule and `app_settings.last_unlock_prompted_at`) · **§8.1** (what happens to over-cap data when a user later pays — *"nothing destructive. Ever."*) · §8.2 (what the cap never does) · **§6.1** (the surface: upgrade row 1 pinned to Flock, row 2 in Settings ▸ Unlock, `ShedBanner`, no dismiss action, Restore above Unlock, both ≥ 60 pt) · §7.3 (the two `RefusalReason` ARB messages, with the cap as a placeholder) · §7.2 (`isQuietHours`, and why the ambiguous DST hour cannot change the answer) · §12.1 (`ui.monetization_surface`) · §12.2 (`quiet_window_never_solicits_test.dart`) | the rows, their constraints and their copy |
| `docs/engineering/06-design-system.md` | **§12** (`ShedBanner` ≥ `tapHero` with two `tapMin` actions; and **the three free-tier constraints, which are 06's to enforce**: `ShedBanner` is the only monetization component, it never renders on the five shed screens, and it never renders 22:00–06:00 *"on any screen, at any ewe count"*) · §10.1 (`showCapRow` is the one feedback channel with **no haptic**) · §10.3 (`showCapRow`'s printed body and what P2 removed) · §6 (`tapMin` / `tapPrimary` / `tapHero`) · §4 (the palettes; `textSecondary` on `surfaceRaised`, **no accent**) | the component and the wider quiet-window rule |
| `docs/engineering/07-screens.md` | **§19.2** (the two surfaces and their exact copy: `Free version · covers this season · 22 of 15 ewes · Unlock once for <store price>`) · §19.3 (the two hard rules) · §19.4 (what the cap never does) · §14.3 row 9 (Settings ▸ Unlock, section **9 of 12**) · §14.2 (Settings' over-cap state: *"every other section is unaffected"*) · §20 (list-row geometry, bottom-third primaries) | where the rows sit and what they say |
| `docs/engineering/CONVENTIONS.md` | §1 (`lib/features/flock/`, `lib/features/settings/`, `lib/core/ui/feedback.dart`) · §1.1 layer rules **5, 6, 7** (a sibling feature import is a layer violation) · §2.11 (`ShedBanner`, `showCapRow`, `context.tokens`) · §2.10 (`RefusalReason`) · §3.1 (`entitlementProvider`, `freeTierPolicyProvider`) · §3.3 (**`minuteTickProvider` is the only ticker in the app**, R25) · §4.5 + **R59** (widget keys, `lower_snake`, `<screen>.<element>`) · §4.7 (`ui.monetization_surface`) · §5.1 (*unlock*, and the one *purchase* exception) · §5.4 (the price is never a literal) · **R30** (the three feedback signatures) · **R40** (the `app_settings` precedent §5.5 leans on) · R58 | the paths, the keys and the component |
| `docs/research/00-tech-decisions.md` | §2 **#92** (no modal ever; two static rows, *"always present, in the same pixels, at 3 ewes or at 15"*) · #90 · #91 · #100/#101 (the 60 pt floor and the gesture ban) · #106 (colour is never the only channel) · #99 (never clamp text scale) · #108 (never an all-numeric date) · §7.0 ruling 8 · §7.1 open question 4 | the affordance's shape |
| `docs/engineering/03-data-model-and-schema.md` | **§5.13** (`AppSettings` — the **fourteen** columns that exist, and the absence §5.5 is about) · §5.1 / §5.2 (the two `over_free_cap` columns) | the column that is missing |
| `docs/engineering/04-migrations-media-backup-restore.md` | §2.3–§2.5 (the migration ritual, `make gen`, the snapshot) · §3 (the from→to matrix) · §1 (the four things you cannot undo) | **only if §5.5 option 1 is taken** |
| `docs/engineering/10-accessibility-and-i18n.md` | §3.2 (label rules; rule 8 — the label uses the **user's** noun) · §3.4 (`headingLevel:` only) · §4 (200% text; never clamp; `FittedBox` is banned) · §8.4–§8.5 (ARB house rules and the terminology-placeholder rule) | the row's semantics and its ARB messages |
| `docs/engineering/12-testing.md` | §6 (the overflow matrix; **R58**'s note that the at-cap and over-cap widget states are part of the 252 cells, because *"22 of 15 ewes · Unlock once for €12.99 at textScaler 2.0 with bold text is exactly the kind of row that overflows"*) · §5.1 (`pumpApp`) · §5.3 (`setEntitlement`, `setEwesInCurrentSeason`) · §2.1 (installing time with `withClock`) · §10.7 | the matrix rows and the clock |
| `docs/design/indelible.md` | §7 (the controls, the word button, *"never a filled red button"*) · §8 (the screens laid out) · §9 (the 3am compliance table) | how a row is drawn in this system |
| `epics/00-PLAN-CRITIQUE.md` | §11.4 (N30's skills) · G4 | the skills |
| `shed-book-spec.md` | **§5** (the 3am test and zero interruptions as a shipping gate) · §7.1 · §7.7 (the retention thesis the season wall aims at) · §14 | why the row is static |
| `CLAUDE.md` | **P2** (there is no SnackBar — and `showMaterialBanner(` went with it in N14-T04) · the 3am floor (64 × 64, 18 px, dark only, the gesture ban) · the banned words | the rendering, and what it may not be |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-monetization` | what the cap may say and where |
| `indelible-states-and-feedback` | the row's shape and the never-modal rule |
| `/shed-migrations` | **by name, and only if §5.5 option 1 is taken** — this is the project's first migration |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/free_tier_test.dart`
- **Test** — `'the upgrade row refuses to build on a shed screen, mid-entry, or during quiet hours'`
- **Why it is red today** — nothing renders the offer, and the obvious implementation is a dialog.

```bash
fvm flutter test test/features/free_tier_test.dart   # expect: failing, for the reason above
```

Sharpen the third clause so it cannot pass by accident: **set the clock, not the entitlement**
(`06 §12` constraint 3, and `11 §12.2`). Pump the **Flock** screen and the **Settings** screen at
`unlocked: false, ewesInCurrentSeason: 99` — the state where a paywall is most tempting — first at
14:00 and assert both rows are found by key, then at 23:30 and assert both are `findsNothing`. The
entitlement is identical in both halves; only `withClock` moves. A test that reaches the same result by
flipping `unlocked` proves the wrong property.

**Green.** The minimum code that passes, and nothing beyond it — the two rows, the four constraints enforced in the widget, not in each caller.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

| # | File | What changes in it, and why |
|---|---|---|
| 0 | `lib/core/db/tables/settings.dart`, `lib/core/db/database.dart`, `lib/core/db/migrations.dart`, `drift_schemas/drift_schema_v2.json`, `lib/core/db/schema_versions.dart`, `test/drift/generated/**`, `test/drift/` | 🚩 **Only if §5.5 option 1 is taken.** `last_unlock_prompted_at` as a nullable `INTEGER` instant, `kSchemaVersion` → 2, the hand-written `from1To2`, `make gen`, and the from→to matrix going from zero pairs to one. **One commit, unsplit** (`00-README §7.4`) |
| 1 | `lib/data/settings_repository.dart` | **Edit**, with the same condition. One event verb — `markUnlockPrompted()` — writing `last_unlock_prompted_at = appNow()`. `CONVENTIONS §2.13` already gives this repository `app_settings` |
| 2 | `lib/core/ui/feedback.dart` | **Edit.** `showCapRow`'s **body**. N14-T04 landed the signature and the two guards; this commit renders the row. The signature is R30's and does not move |
| 3 | `lib/features/flock/widgets/upgrade_row.dart` | **New.** Upgrade row 1's composition over `ShedBanner`, keyed `flock.upgrade_row`. It lives under the feature's `widgets/`, not in `lib/core/ui/components/` — `ShedBanner` is the shared component and this is its one composition |
| 4 | `lib/features/flock/flock_screen.dart` | **Edit.** Pin the row to the **top** of the Flock screen (`07 §19.2`), above the list, inside the same scroll container the list uses only if it does not scroll away |
| 5 | `lib/features/settings/settings_screen.dart` | **Edit.** Section **9 of 12**, keyed `settings.upgrade_row`. N29-T01 rendered eleven sections and left a ledger comment naming this task as the twelfth's home — fill it and delete the comment |
| 6 | `lib/features/settings/unlock_controller.dart` | **Edit.** Call `openSection()` when the section becomes visible, and honour `SettingsState.focusUnlock` (N29-T01 put the field there for this) |
| 7 | `lib/l10n/app_en.arb` | **Edit.** The row's sentence, both `RefusalReason` messages with `{count}` as a placeholder, and the two action labels. Every message carries a `description`; no domain noun is a literal |
| 8 | `tool/check_policy.dart` | **Edit.** `ui.monetization_surface`, both clauses |
| 9 | `test/policy/gate_rules_test.dart` | **Edit.** Two planted-violation cases, one per clause |
| 10 | `test/features/free_tier_test.dart` | **Edit.** The anchor and the widget cases |
| 11 | `test/policy/quiet_window_never_solicits_test.dart` | **New.** `11 §12.2`'s file |
| 12 | `test/features/overflow_matrix_test.dart` | **Edit.** R58: the at-cap and over-cap states join the matrix |

**Not touched:** `lib/routing/routes.dart` (`Routes.settings(context, focusUnlock: true)` landed in
N29-T01 and there is no fourteenth `RouteNames` entry), `lib/core/ui/components/shed_banner.dart`
(N10-T08 built it; if this task wants to change it, that is a 06 conversation and an N10 amendment),
`lib/domain/free_tier.dart`.

### 5.2 The signatures

`showCapRow` is R30's and does not move — a feedback function holds a `BuildContext` and nothing else:

```dart
// lib/core/ui/feedback.dart
void showCapRow(BuildContext context, RefusalReason reason);
```

`ShedBanner` is N10-T08's and this task **uses** it. Note that it takes `now` and self-suppresses:

```dart
// lib/core/ui/components/shed_banner.dart  — existing, not edited here
final class ShedBanner extends StatelessWidget {
  const ShedBanner({
    super.key,
    required this.now,
    required this.message,
    required this.primary,        // ('Unlock', onTap)
    this.secondary,               // the upgrade row has none
  });

  final Instant now;
  final String message;
  final ({String label, String semanticLabel, VoidCallback onTap}) primary;
  final ({String label, String semanticLabel, VoidCallback onTap})? secondary;

  @override
  Widget build(BuildContext context) {
    // THE one definition of the window. Re-typing `h >= 22 || h < 6` here is how
    // the policy and the row end up disagreeing about when the app goes quiet.
    if (isQuietHours(now)) return const SizedBox.shrink();
    // …
  }
}
```

The two widget keys, which have been contracts since **N14-T07** asserted their absence at step 5:

```
flock.upgrade_row
settings.upgrade_row
```

The gate row, both clauses:

| Rule id | Fails on | Scope |
|---|---|---|
| `ui.monetization_surface` | `showCapRow(` called outside `lib/features/flock/` and `lib/features/settings/`; **and** `ShedBanner` constructed outside those two plus `lib/features/quick_entry/` | `lib/features/` |

`quick_entry/` is allowed **on purpose**: the same component carries the end-of-day **export prompt**
(`07 §16.2`), which is not a monetization surface and predates `11`. Scoping the component ban to two
folders would fail the build on a banner the spec calls a safety feature. `showCapRow(` is the half
that actually guards monetization, and it is exact — the cap can only be refused from those two
folders, because `liveEntry` is structurally incapable of returning `BlockedByCap`.

The ARB messages, from `11 §7.3`:

| Reason | Message |
|---|---|
| `secondSeason` | "The free version covers one season. Unlock to start another." |
| `eweCap` | "The free version covers {count} ewes in a season. Unlock to add more." |

And the row's own sentence, from `07 §19.2`:

> `Free version · covers this season · 22 of 15 ewes · Unlock once for <store price>`

### 5.3 The details that are easy to get wrong

- 🚩 **`showCapRow` is not a `MaterialBanner`, and the document that says it is has been superseded.**
  `11 §8` constraint 3 says the row goes *"through `ScaffoldMessenger.showMaterialBanner`"*. **P2
  removed that**: N14-T04 banned `showMaterialBanner(` in the same commit as `showSnackBar(`, and
  `06 §10.3`'s `OverlayEntry` fallback with it. The cap row is a **ruled row in the document**, in the
  same column as everything else, exactly as the receipt is the committed row. If you are reaching for
  `Overlay.of(context)` or `ScaffoldMessenger.of(context)`, you have re-invented the toast with a
  different class name.
- 🚩 **Feed `ShedBanner` a `now` that moves.** It takes `now` and self-suppresses in the quiet window.
  A single `appNow()` read at build time means a Flock screen left open at 21:58 is **still soliciting
  at 22:05** — and the widget test would not catch it, because the test sets the clock *before* it
  pumps. `minuteTickProvider` is the only ticker in the app (R25), is boundary-aligned to the wall-clock
  minute, yields `Instant`, and exists for exactly this class of problem. Decide, implement, and put the
  reason in a comment; a row that reads a frozen clock is the quietest bug in this epic.
- **The quiet window suppresses *soliciting*, not *selling*.** `11 §8` constraint 2 writes this down
  because it is easy to over-apply: Settings ▸ Unlock is a settings section like any other, it exists at
  23:00, its Restore and Unlock buttons **work** at 23:00, and a shepherd who deliberately walks there
  at midnight to pay is not interrupted by being allowed to. What does not happen at 23:00 is a **row
  appearing**, a **refusal firing**, or the **app navigating anywhere on its own**.
- **06's rule is wider than 07's, and 06's is the one that ships.** `07 §19.3` rule 2 suppresses only
  the Flock row; `06 §12` constraint 3 suppresses `ShedBanner` *"on any screen, at any ewe count"*.
  `11 §8` constraint 2 rules for 06. Suppress **both** rows.
- **The four constraints are enforced by the component, not by each caller.** A caller-side
  `if (!isQuietHours(now))` is one new call site away from being forgotten, and there will be a new call
  site. `ShedBanner` already returns `SizedBox.shrink()`; `showCapRow` must be a no-op in the same
  conditions.
- **The two upgrade rows have no dismiss action, and that is why `secondary` is null.** `11 §6.1`: *"the
  upgrade row uses one of `ShedBanner`'s two action slots and has no dismiss action, because a permanent
  row cannot meaningfully be dismissed."* `07 §19.2`: the rows are *"always present, in the same pixels,
  at 3 ewes and at 22."* The `secondary` slot exists for the **export banner**'s *"Not this season"*,
  which is a different use of the same component.
- **Restore sits above Unlock in the row too**, not only in the section (`11 §6.4`). Both rows, and the
  section. It removes the double-charge fear before it forms, and App Review 3.1.1 is a routine
  rejection cause when it is missing.
- **"Restore purchases" is the one permitted use of the word *purchase*** in user-facing copy
  (`CONVENTIONS §5.1`). Every other sentence on both rows says **unlock**.
- **`{count}` is a placeholder, never a typed 15.** `11 §7.3`: *"the cap as a placeholder so the number
  is never typed twice."* Feed it `kFreeEweCap`. The same applies to the row's `22 of 15 ewes` — both
  numbers are read, neither is written.
- **The noun in the row is the user's noun.** `10 §3.2` rule 8 and `10 §8.5`: no ARB message carries a
  domain noun as a literal; the term is a placeholder fed by `terminologyProvider`. A shepherd who
  renamed *ewe* to *gimmer* must see *gimmers* here too, and the failure mode is invisible until they
  rename.
- **No accent, no badge, no colour change, no red.** `06 §12` constraint 1: the row renders in
  `textSecondary` on `surfaceRaised` like any other row, and *"if a visual direction proposes an accent
  for the upgrade row, it is refused."* Indelible §7 adds: never a filled red button.
- **No haptic.** `06 §10.1` makes `showCapRow` the one feedback channel with none, because both gated
  actions are calm-UI and `liveEntry` cannot be refused. A haptic here is the app tapping a shepherd on
  the shoulder to ask for money.
- **No dialog.** `ui.show_dialog` allowlists exactly two files (delete-season, restore-from-backup) and
  neither is here — so a modal paywall is caught by a rule that already exists rather than a new one.
- **Nothing on this screen is greyed, blurred, teased or made read-only.** `11 §8.1`: on not paying,
  *"nothing is deleted, hidden, greyed out, blurred, teased or made read-only. Ever."* A shepherd who
  tried it for one season and walked away opens the app in year two and exports their CSV. Anything else
  is data ransom in a product whose selling point is that no company can take their five seasons away in
  2029.
- **The Flock row is pinned to the top and must not scroll away or push the list.** `07 §19.2` says
  *"pinned top"*. It is also the row most likely to overflow: R58 puts the at-cap and over-cap states in
  the 252-cell matrix by name, because `Free version · covers this season · 22 of 15 ewes · Unlock once
  for €12.99` at textScaler 2.0 with bold text is a four-clause sentence in a fixed-height row.
  **Reflow, never clip; never `FittedBox`; never clamp the scale.**
- **64 × 64 targets, 18 px floor, dark only, no banned gesture.** The row has two interactive elements
  and both are `ShedTapTarget`s with required `semanticLabel`s. `ShedBanner` is ≥ `tapHero` tall with
  two `tapMin` actions (`06 §12`), and Indelible builds to 64 — 4 pt of headroom over the 60 pt floor.
- **`headingLevel:` on the Settings section heading, never `header: true`** — the latter is a no-op on
  3.44 (`10 §3.4`).

### 5.4 The full test set

| File | Case | What it holds |
|---|---|---|
| `test/features/free_tier_test.dart` | **anchor** — `'the upgrade row refuses to build on a shed screen, mid-entry, or during quiet hours'` | The three clauses of §4, with the clock moving and the entitlement fixed |
| | `'both rows render at 14:00 and neither renders at 23:30, with the entitlement unchanged'` | The wider 06 rule, stated as its own case |
| | `'the boundary is 22:00 inclusive and 06:00 exclusive'` | 21:59 renders, 22:00 does not, 05:59 does not, 06:00 does — all four, both directions |
| | `'neither row has a dismiss action'` | `ShedBanner.secondary` is null on both |
| | `'Restore purchases is above Unlock in both rows and in the section'` | Geometry, not a comment |
| | `'showCapRow constructs no dialog, no overlay and no MaterialBanner'` | P2 and `ui.show_dialog`, at the widget tier |
| | `'a refusal renders the eweCap message with the cap read from kFreeEweCap'` | The placeholder, not a typed 15 |
| | `'the row uses the user's noun after a terminology override'` | `10 §8.5`'s invisible failure |
| | `'the row renders identically at 3 ewes and at 22'` | Decision #92's *"same pixels"* |
| | `'nothing on the Flock screen is greyed, blurred or disabled at 99 ewes, locked'` | `11 §8.1`'s no-ransom rule |
| `test/policy/quiet_window_never_solicits_test.dart` | `'at every local hour in 22:00–05:59, decide returns Allow for both calm gates'` | Eight hours × both gates |
| | `'at every local hour in 22:00–05:59, no ShedBanner renders on Flock or on Settings'` | **The test sets the clock, not the entitlement** |
| | `'no self-navigation to Settings ▸ Unlock occurs inside the window'` | It cannot, because nothing is refused inside it — asserted so a future refactor cannot make it possible |
| **`@Tags(['uk-zone'])`**, same file | `'both instants of the repeated 01:00–01:59 hour are inside the quiet window'` | `11 §7.2`'s comment says the one place a local hour is genuinely ambiguous is a place where the ambiguity cannot change the answer. Build both candidate `Instant`s for `2026-10-25T01:30` and assert `isQuietHours` is true for each. Carry the `setUpAll` offset guard |
| | `'the clocks-forward night has no 01:30 and the predicate does not throw'` | The other DST direction, through `checkLocalWallTimeExists()` |
| `test/features/overflow_matrix_test.dart` | the at-cap and over-cap variants | R58: 3 sizes × 3 text scales × 2 bold states, no `RenderFlex` overflow and no exception. **Fix the layout, never the matrix** |
| `test/policy/gate_rules_test.dart` | `'ui.monetization_surface exits 1 on a planted showCapRow( in lib/features/pens/'` | Clause one |
| | `'ui.monetization_surface exits 1 on a planted ShedBanner in lib/features/season/, and zero on one in lib/features/quick_entry/'` | Clause two **and** its deliberate exception, in one case so nobody deletes the exception |

**If §5.5 option 1 is taken, add:** `test/drift/` gains its first real from→to pair, and
`test/data/settings_repository_test.dart` gains `'markUnlockPrompted writes an instant and the
same-civil-day comparison uses LocalDate rather than a 24-hour subtraction'` — tagged `uk-zone`,
because a prompt at 23:30 and a refusal at 00:30 are one hour apart in absolute time and two different
civil days, and the repeated hour puts two different instants on the same civil day. `11 §8`
constraint 4 spells the comparison: `LocalDate.of(appNow()) != LocalDate.of(lastPrompted)`.

### 5.5 🚩 The column that does not exist, and the ruling this task must make

`11 §2` flags `app_settings.last_unlock_prompted_at` on R40's precedent — a nullable `INTEGER` instant
a screen needs and 03 did not declare — and says in bold that it **must land before the first schema
snapshot**. `11`'s own Definition of Done repeats it. **It did not land.** `03 §5.13` declares fourteen
`AppSettings` columns and this is not one of them; no task in N00–N29 adds it; `kSchemaVersion` is `1`
and `from1To2` is still the commented-out stub N08-T01 shipped.

It exists for one rule and one rule only — `11 §8` constraint 4, *"never more than once a day"*:

> When a calm-UI action returns `WriteRefused`, the **user initiated that tap**, so navigating to
> Settings ▸ Unlock is a response rather than an interruption — and it is the only navigation to Unlock
> the app ever performs on its own. But a user who taps "+" ten times must not be sent there ten times.

Two honest options. **Pick one, in writing, in the commit message.**

1. **Land it as v2.** Forward-only, additive, nullable — the safest possible migration and a reasonable
   first one. `00-README §7.4`: `kSchemaVersion`, the new `from1To2` body, the regenerated snapshot and
   the regenerated test helpers, **together or not at all**; CI enforces it by regenerating and failing
   on any diff. Run **`/shed-migrations`** first. Amend `03 §5.13` in the same commit per the amendment
   rule. Remember that the first committed snapshot froze v1 forever and this one joins it — every later
   version is diffed against both by `SchemaVerifier`, on phones that have never been online.
2. **Ship without the self-navigation.** `showCapRow` renders the refusal in place and the app never
   navigates on its own. Everything else in constraint 4 still holds, because a **user-initiated** tap
   on an upgrade row was never rate-limited — *"the row is always tappable"* — and the rule cannot fire
   in the quiet window anyway, because nothing is refused there. Record it as an open item against
   `11`'s Definition of Done and route the column to the owner.

**Do not fake it with a third store.** `shared_preferences` is forbidden by entitlement rule 3, is not
in decision-record §5.1, and adding it re-introduces the `NSPrivacyAccessedAPICategoryUserDefaults`
(`CA92.1`) obligation T07 is about to declare away. **Do not fake it with an in-memory field** either:
a rate limit that resets on every cold launch is not a rate limit, and it will read as one to whoever
maintains it.

## 6. Constraints that bind this task

- **3am** — every interactive element ≥ 64 × 64 with ≥ the ruled separation, 18 px text floor, dark only, and none of the banned gestures: no swipe, no drag, no long-press, no pinch, no slider.
- **Accessibility and the ARB, authored here** — every string in `app_en.arb` with a `description`, every element a `semanticLabel` and a `<screen>.<element>` key, every heading a `headingLevel:`. There is no later sweep that adds them; N33 only verifies.
- **Offline** — no network path may be added. G2 (the dependency allowlist) and G3 (the import scan) stay green, and the permission set never changes without G0's recorded evidence.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'the upgrade row refuses to build on a shed screen, mid-entry, or during quiet hours'` passes, and was seen to fail first for the stated reason
- [ ] all four constraints enforced by the component itself
- [ ] no dialog, no overlay, no interstitial
- [ ] the row is dismissible and stays dismissed
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

> **Reading line four, which is about two different rows.** The **two upgrade rows** are permanent:
> `ShedBanner.secondary` is null, they have no dismiss action, and `07 §19.2` requires them *"always
> present, in the same pixels"* — `11 §6.1` says why (*"a permanent row cannot meaningfully be
> dismissed"*). What is dismissible is the **cap row** `showCapRow` raises after a refusal: `06 §10.3`
> says it *"leaves the screen only when one of the row's own actions is tapped"* — no scrim, no
> auto-dismiss, no swipe (a banned gesture) — and it **stays dismissed** for the rest of the local civil
> day, which is `11 §8` constraint 4 and §5.5's ruling. Both halves of this line are about that row.

## 8. Verification

```bash
fvm flutter test test/features/free_tier_test.dart
fvm flutter test test/policy/quiet_window_never_solicits_test.dart
fvm flutter test test/policy/gate_rules_test.dart
fvm flutter test test/features/overflow_matrix_test.dart
TZ=Europe/London fvm flutter test --tags uk-zone
dart run tool/check_policy.dart
grep -rn "showMaterialBanner(\|showSnackBar(\|Overlay.of(\|showDialog(" lib/features/ lib/core/ui/   # nothing
grep -rn "isQuietHours" lib/ | grep -v "lib/domain/free_tier.dart"    # call sites only, no re-derivation
grep -rnE "h >= 22|hour >= 22|< 6\b" lib/ | grep -v free_tier.dart    # nothing
grep -rn "upgrade_row" lib/features/                                   # exactly two keys
# only if §5.5 option 1 was taken:
make gen && git status --porcelain drift_schemas/ lib/core/db/ test/drift/generated/   # must be committed, not dirty
fvm flutter test test/drift/
make check
make test
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(monetization): the two upgrade rows and their four constraints`
