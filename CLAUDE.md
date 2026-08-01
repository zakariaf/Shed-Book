# Shed Book

Shed Book is an offline-only Flutter lambing notebook for a shepherd with 20–400 ewes, built around one
fifteen-second interaction — pick the animal, tap what happened — performed at 03:20, one-handed, in a
cold shed with a head torch and no signal. It has no account, no server, no sync and no subscription;
it is bought once with a single non-consumable unlock. Its lasting value is not the entry but the
recall: in year two, *"what did 412 do last year?"* takes one second instead of an evening with a shoebox.

**Authority order.** `docs/research/00-tech-decisions.md` (decisions; §5 the only source of a version
number) → `docs/engineering/CONVENTIONS.md` (every name, path, type, word) → `docs/design/indelible.md`
(the one design system) → the thirteen engineering documents → `.claude/skills/`. A skill never outranks
a document; it distils one and cites it. **Before claiming work is complete, run `/shed-code-review`.**

## The four non-negotiables

Here rather than in a skill because they must be *present*, not *consulted*: a one-line request may
trigger no skill at all and can still break all four.

### 1. Offline purity

**This is the only permitted public wording, verbatim** (decision-record §3.1):

> "Shed Book has no account, no server and no sync. The Android build ships without the internet
> permission, so the app itself cannot connect to anything. Your records only leave the phone when you
> deliberately export and share them."

**Never write "your data never leaves your phone."** It does, the moment they AirDrop a CSV — which is
the backup story this product depends on. Only tiers 1 and 2 are claimable (no network code and no
`INTERNET` permission; **no dependency *can* reach** a network from our process — amended 2026-08-01
by G0, which found a Google telemetry library transitively inside Play Billing: what is provable is
that it cannot succeed, not that it does not try). Tier 3 — *no data leaves the
device by any route* — is **false**: the share sheet and the system photo picker are other processes.
Also never in our own prose: **"offline-first"** (Shed Book is offline-**only**; the Flutter
offline-first pattern is cache-over-network and is banned outright), *"a lost phone is lost data"*
unqualified, *"verified"*/*"secure"* about the backup checksum. A *"no `http` in `pubspec.lock`"* gate is
**unsatisfiable** and must never be written — `http 1.6.0` sits on four load-bearing regular edges. The
gates are G1 (permission set on the shipped `.aab`), G2 (dependency allowlist), G3 (import scan).

### 2. The 3am test floor

*"Every screen must pass this. If a feature cannot be operated under these conditions, it does not ship."*

- **60 × 60 pt minimum target**, asserted by `MinimumTapTargetGuideline(size: Size(60, 60), link: …)`
  plus a geometric gate in `test/design/`. Indelible builds to **64 × 64** — 4 pt is all the headroom.
- **18 pt body floor.** Record body 20 px, control floor 19 px, absolute floor 18 px. Every text pair
  ≥ 4.5:1, every rule and mark ≥ 3:1. Raw hexes and magic sizes are build-breaking defects.
- **Dark only.** No light theme, no system-follow. The first painted frame is the page colour — no
  splash, no logo, no white flash, on either platform.
- **Banned gestures, absolutely**: swipe-to-delete and every swipe action, drag and drag handles,
  long-press bindings, hold-to-repeat, pinch, force touch, sliders. Held as `check_policy` rows — no
  `Dismissible`, `Draggable` or `Tooltip` anywhere in `lib/`.
- **Under fifteen seconds from unlock to a saved lambing**, and **zero interruptions**: nothing
  monetization-related renders on the five shed screens at any entitlement state.

The one question to ask of any change to Quick Entry: **does the shepherd have to do anything new
before the record exists?** A tap, a wait, a decision, or a thing on screen that was not there before.
If yes, it lands somewhere calmer, in daylight.

### 3. The five safety rules (spec §12)

Each is pushed as far up this hierarchy as it will go — *unrepresentable → unconstructible →
unpersistable → caught by a test on the source text → documented*. **A rule that has dropped to merely
documented has been deleted, whatever the prose says.**

| Rule | Mechanism | Level |
|---|---|---|
| **§12.1** never default a medicine withdrawal period | `sealed WithdrawalPeriod`, private generative constructor, one entry point; a child table where **no row implies `NotRecorded`** — `0` is a real label value, so a nullable int cannot carry it | unconstructible + unpersistable |
| **§12.2** never give veterinary advice | The origination line — *the app may arithmetic-transform a number the user supplied; it may never originate a number that is a clinical decision* — plus `ContentPolicy`'s scan of string literals and ARB messages | test on source text |
| **§12.3** never present the app as a compliance record | `Disclaimers` is an `abstract final class` of `const` strings in one file, **referenced and never re-typed**; `ExportEnvelope` has no disclaimer parameter | unconstructible |
| **§12.4** never silently correct a user's entry | `Warning` / `Reviewed<T>` have no writer and no `fix()`; there is **no `warnings` column**; `lib/data/` may not import `lib/domain/validation/` at all | unrepresentable + unpersistable |
| **§12.5** timestamps are honest | The provenance quad with paired SQL `CHECK`s; `provenanceLabel` is an exhaustive switch and can never be empty | unrepresentable |

Corollary: **a table without the provenance quad has no edit verb.**

### 4. Every write commits immediately

*"Assume the phone dies. Every write is committed immediately. There is no draft state to lose."*

Repository methods are **event verbs** — there is no `save(aggregate)` anywhere, so there is no aggregate
in which a draft could be deferred. **The row is created on screen entry, not on exit**: Quick Entry's
"Lambing" tap calls `beginLambing(ewe)` *before* Lambing Entry is pushed, and every field after that is
its own committed write. No `Save` button, no `isDirty`, no `commit()`, no `submit()`, no draft object,
no optimistic UI. `synchronous = FULL` on every connection.

### Two owner rulings that supersede a written document

- **P2 — there is no SnackBar.** `showSnackBar(` is banned everywhere, including in `feedback.dart`
  (`CONVENTIONS §2.11` superseded). The confirmation **is the committed row**, in ink, one line above the
  one being written; undo is a time-boxed strike in that row's margin, its window **stated in seconds**.
- **P8 — there is no birth-type chooser in the product.** Birth type is **derived from the tally strokes
  and labelled `(COUNTED)`** (`06 §12`'s `ShedChoiceRow` survives only for lambing ease 1–5). That is
  what makes §12.4 structural instead of procedural.

## Vocabulary — one word per concept

Everywhere: prose, class names, ARB keys, column names, commit messages. Reasons in `CONVENTIONS.md`
§5.1–§5.3; it is also a gate row, so it is enforced twice and remembered once.

| Use | Never |
|---|---|
| **record** (the stored fact) · **entry** (the act, and its screens) | entry as a noun, item, object, document · input, capture |
| **event** (an append-only row; the verb form of a write) · **warning** (`List<Warning>`) | action, transaction for a domain fact · **flag**, issue, problem, validation error |
| **withdrawal period**, then **withdrawal** · **clear date** | withholding, WHP, "the days" · safe date, withdrawal end date, "clears on" as a noun |
| **tag** · **season** | ear tag, number, ID · year, campaign |
| **birth dam** / **rearing dam** · **birth type** / **rearing type** | mother, dam unqualified, foster mum · litter size |
| **turn out** (verb) / **turn-out** (adj) · **penned** / **pen occupancy** | turnout · housed, in the pen as a state |
| **barren** · **stillborn** | empty, not in lamb · died at birth, dead-born, "died at age 0" |
| **unattributed** (a blank cause) · **provenance** / **provenance label** | unknown — a cause the user can pick; never merge the two · audit, source unqualified, metadata |
| **the free tier** / **the cap** · **unlock** · **shed screen** | trial, freemium, paywall · purchase, buy, subscribe · 3am screen in code |
| **gateway** (the seven seams) · **repository** (the only writer) · **controller** / **write controller** | platform service, adapter, wrapper, client · DAO, store (except `MediaStore`), service · view model, presenter, bloc, command, mutation |
| **the gate** (`tool/check_policy.dart`) · **the diagnostics log** (`LocalLog`) | linter, plugin, checker · crash log, telemetry, analytics — there is none |
| **the backup** (JSON) / **the snapshot** (`VACUUM INTO`, drift schema JSON) | dump; and never swap the two |
| **reconcile** (the OS notification projection) · **the deck** (Quick Entry's two strips) | schedule, sync, refresh · picker, chooser |
| **restore** (replace everything) · **export** (records off the phone) | import, merge — **there is no merge** · backup, when it means the action |

**Banned absolutely:** `draft`, `isDirty`, `save()`, `commit()`, `submit()`, `pending` (as a model
state), `sync`, `synchronized`, `offline-first`, `flags`, `Error` as a failure-type name, "your data
never leaves your phone", "a lost phone is lost data" unqualified, "verified"/"secure" about the backup
checksum, "compliance record", "official record", "recommended dose", "should".

## The pinned stack

**Decision-record §5 is the only source of a version number in this project** — not a README, not
`pub add`, not memory, not this table. The rows exist so a wrong one is noticed, not so one is copied.

| | |
|---|---|
| Toolchain | Flutter **3.44.8** stable / Dart **3.12.2**, pinned via FVM (`.fvmrc`). Never unpinned `stable` |
| State + DI | `flutter_riverpod` **2.6.1 — exact pin, no caret.** Every Riverpod 3 API is a compile error here |
| Persistence | `drift` **2.34.2** / `drift_dev` **2.34.5** / `sqlite3` **3.5.0**. **drift is the only generator** |
| Codegen range | `build_runner` `">=2.15.0 <2.15.2"` — it does **not** resolve at `^2.15.2` |
| Architecture | Two-layer MVVM (UI + Data), pure-Dart domain of top-level functions; feature-first, single package |
| Enforcement | **One** gate: `tool/check_policy.dart`, one rule table, one allowlist, one exit code |
| Commands | `make gen` · `make check` · `make test` · `dart tool/check_policy.dart` · `python3 tool/validate_skills.py` |

Never edit `tool/check_policy.dart`, its rule table or its exit code to make a build pass; never add a
line to `tool/policy_allowlist.txt` or `android/expected_permissions.txt` to silence a gate. If a gate is
genuinely wrong, say so and stop.

## Which skill owns this

At most **two** auto-firing skills per intent; where a task spans more, the owning skill names the next
one to load. Full index and routing rationale in `docs/skills/README.md`.

| Intent | Skill |
|---|---|
| **Any pixel, colour, token, size, weight, spacing, gesture, motion or haptic** — the design front door | `indelible-design-system` |
| **Any file, class, provider, key or column name; whether one folder may import another** — the code front door | `shed-conventions` |
| Add or change a screen | `shed-screens-and-routing` → then `indelible-page-and-screens` |
| Compose a page; any padding, gap, width, height or target size | `indelible-page-and-screens` |
| Any button, field, form, keypad, stepper, sheet or toggle | `indelible-controls` |
| A status, warning, tally, chart, strike, delete, hide, mute or edit | `indelible-marks-and-strikes` |
| Empty state, first frame, error, confirmation, receipt, banner, prompt | `indelible-states-and-feedback` |
| Record a lambing, lamb, weight, treatment or note; any Save button or draft | `shed-write-path` |
| Undo or delete a record | `shed-screens-and-routing` |
| A table, column, index, view or named query; `make gen`, `build_runner`, codegen | `shed-drift-schema` |
| Any calculation, statistic or date arithmetic; a DST or clocks-change bug | `shed-domain` |
| Medicines, doses, batch numbers, withdrawal days, clear dates | `shed-withdrawal` |
| Any default, pre-fill, suggestion, placeholder, validation or auto-correction | `shed-safety-rules` |
| Any provider, notifier, `ref.watch`, `AsyncValue`, rebuild scope or jank | `shed-riverpod-providers` |
| `main.dart`, `app.dart`, exception mapping, lifecycle, resume, slow start | `shed-bootstrap-and-errors` |
| Any label, string, heading, date or number format; semantics; text scaling | `shed-accessibility-and-copy` |
| Any test, flaky test, or failing tap-target / semantics / contrast gate | `shed-testing` |
| `pub add`, any proposed package, `pubspec.yaml`, `analysis_options.yaml`, a red gate | `shed-dependencies-and-toolchain` |
| Wrapping an approved plugin, `AndroidManifest.xml`, `Info.plist`, reminders, permissions | `shed-platform-gateways` |
| CSV, PDF, JSON backup, import, restoring a backup file | `shed-export-and-restore` |
| Price, purchase, restoring a purchase, entitlement, unlock, the cap | `shed-monetization` |
| **Runbooks — never auto-fire, invoke by name:** a schema migration · cutting a release · re-baselining goldens · reviewing a change | `/shed-migrations` · `/shed-release` · `/shed-goldens-rebaseline` · `/shed-code-review` |

## The amendment rule

> **A change to a decision requires updating the decision record and every document *and skill* that
> applies it, in the same change.**

1. Edit the row in `docs/research/00-tech-decisions.md`. A superseded decision is **struck with its
   reason**, never quietly rewritten.
2. Grep the doc set for the decision number — every document opens with a `> **Decisions applied:**`
   line — and grep `.claude/skills/` for the same. All of them change in that commit.
3. A **name** change is `CONVENTIONS.md`'s: a numbered ruling in §6, §1–§5 updated, the files listed.
4. A **schema** change is irreversible after the first snapshot: say so, and route it to the owner.
5. A **§12 safety rule** change moves a mechanism, not prose: state its new level and which test holds it.
6. A **skill scope or description** change also updates `docs/skills/02-build-manifest.md` §3 and re-runs
   `python3 tool/validate_skills.py`. A skill whose description no longer matches its row there is worse
   than a missing skill.

You may never implement around a decision you disagree with. Every rule here has a failure behind it,
and most of those failures happen at 03:20 on somebody else's phone in March.
