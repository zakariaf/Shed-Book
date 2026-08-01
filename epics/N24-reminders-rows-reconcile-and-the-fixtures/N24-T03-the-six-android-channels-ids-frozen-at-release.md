# N24-T03 — The six Android channels, ids frozen at release

| | |
|---|---|
| **Epic** | [N24 — Reminders: rows, reconcile and the fixtures](epic.md) · `00-README` §9 step 9 (1 of 2) |
| **Task** | 3 of 8 |
| **Depends on** | N24-T02 |
| **Commit** | one commit · `feat(platform): the six Android notification channels` |

## 1. Why this task exists

> 🚩 **Read this before you write a line: there are eight channels, not six.** This task's title, its
> anchor test name and its Definition of Done all say *six*, and all three inherit the count from
> decision **#65**, whose channel list (`colostrum`, `navel`, `turnout`, `tag_by`, `dose`,
> `withdrawal`) is **superseded**. `CONVENTIONS` **R49** ruled it: *"03 owns stored keys. There is one
> set of strings, 03's eight, and the Android channel id is byte-identical to the kind. `turnout`,
> `dose` and `withdrawal` are banned channel ids."* `08 §2.7` and `13`'s preamble both adopt the ruling
> and print the eight. **Build eight.** The stale count in the title and the DoD is a documentation
> defect this task fixes under `00-README` §10's amendment rule — see §5.3.

Eight channels rather than one, because one channel for everything means the shepherd who mutes
tag-by spam loses colostrum alerts with it, and that is the entire purpose of channels. Their ids are
**frozen at release**: an Android channel id cannot be changed afterwards without orphaning every
user's per-channel settings, and Android restores a deleted channel's settings if you recreate it with
the same id. This is the last commit in which the eight strings are cheap.

The same commit lands the **copy seam**. `lib/data/` may not import `package:flutter/material.dart`
(layer rule 4) and the generated `AppLocalizations` does, so the gateway cannot localise anything: every
user-visible string it hands to the OS must arrive from above, through `NotificationCopy`.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/08-platform-integration.md` | **§2.7** (the eight channels, their ARB names, their initial importance, and the five rules) · **§2.6** (the copy seam, `buildNotificationCopy`, the boot-kick chain, and why `project()` throws without a copy) · **§2.5** (the id is `reminders.id`; the payload is `reminder:<id>` and the lock-screen table) · §2.14 (an id from `uid.hashCode`) · §9 (the channel-id gate, blocking every push) | the eight ids, the eight names, and the gate that stops them drifting |
| `docs/engineering/03-data-model-and-schema.md` | **§5.10** (the `reminders.kind` CHECK — the eight strings, byte for byte; `title TEXT NOT NULL`; no `os_notification_id`) | the authority the channel ids copy |
| `docs/engineering/CONVENTIONS.md` | **R49** (one set of strings; three banned ids) · §1 (`lib/features/reminders/`, `lib/l10n/app_en.arb`) · §4.6 (stored enum key: `snake_case`, ASCII, **frozen forever**) · §5.1 (*turn out* two words; the stored key is `turn_out`, *"including the Android channel id"*) · §2.12 (the gateway) · R67 (the ARB) | **BINDING** on all eight strings and on the words around them |
| `docs/engineering/10-accessibility-and-i18n.md` | the ARB rules: every message has a `description`; no domain noun is a literal — the term is a placeholder fed by `terminologyProvider` | how the eight names are authored |
| `docs/engineering/07-screens.md` | §11.6 (§12.2 on this screen: *"Colostrum — your 2 h interval"* is a fact; *"Colostrum is needed within 2 hours"* is advice) | the one rule the channel names and bodies can break |
| `docs/engineering/12-testing.md` | §5.3 (`findColumn(schema, table:, column:)` in `reads.dart`, over the committed drift schema JSON) · §11.1 (a policy test is named for the property) | how the gate reads the frozen list |
| `docs/research/00-tech-decisions.md` | **§5 only** for versions · **#65** (superseded on the channel names by R49; its permission clause is narrowed in T06) · #63 · #106 (colour is never the only channel) · #108 (ARB from day one) | what #65 still binds and what it no longer does |
| `shed-book-spec.md` | §7.6 (the reminder kinds, all user-configurable, nothing nags twice) · §4.5 (treatment records and losses are commercially sensitive) | why there are eight kinds and what may not reach a lock screen |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-platform-gateways` | channels, ids and payloads are its subject |
| `shed-conventions` | a frozen id is a name, and names are its authority |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/data/notification_channels_test.dart`
- **Test** — `'the six channel ids match the frozen list exactly'`
- **Why it is red today** — no channels exist, and the first release freezes whatever is there.

```bash
fvm flutter test test/data/notification_channels_test.dart   # expect: failing, for the reason above
```

Sharpen the assertion, and this is the sharpening that matters most in the epic: **the "frozen list"
is not a literal in the test file.** It is read out of the committed `drift_schemas/drift_schema_v<N>.json`
— the `reminders.kind` CHECK's string set, extracted with `findColumn(schema, table: 'reminders',
column: 'kind')` — and compared for **set equality** with the ids in `NotificationCopy.channels`. That
is `08 §9`'s blocking gate: *"the two cannot drift, and the failure message names both sides."* A test
that compares the Dart list against a Dart list copied from the same file asserts nothing.

The set has **eight** members. Keep the test's name (it is this task's anchor and three documents cite
it) and put the count in the failure message instead: *"schema declares 8 kinds, NotificationCopy
declares N"*.

**Green.** The minimum code that passes, and nothing beyond it — the six channels, the frozen id list, and the assertion against it.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8's order

| §8 step | File | What changes in it, and why |
|---|---|---|
| 1 — schema | **skipped, deliberately** | `reminders.kind`'s CHECK already carries the eight strings from N07-T06 and was frozen at N07-T08. This task **reads** it and adds nothing. A `drift_schemas/` diff in this commit means someone edited the CHECK to match their channel list, which is a post-freeze schema change on a table pointing at a shepherd's records |
| 3 — data | `lib/data/notification_scheduler.dart` | **Edit.** `installCopy(NotificationCopy)` gets its body: store `_copy`, then create the eight Android channels idempotently. `titleFor` / `bodyFor` delegate to `_copy`; `project()` throws `StateError` when `_copy` is null |
| 6 — UI | `lib/features/reminders/reminder_copy.dart` | **New.** `NotificationCopy buildNotificationCopy(AppLocalizations l10n, Terminology terms)` — the presentation edge, and the only place that may see `AppLocalizations`. A file addition to `CONVENTIONS §1`'s `lib/features/reminders/`, flagged in `08 §11` and landed here |
| 6 — root | `lib/app.dart` | **Edit.** `_bootNotifications()` — the post-frame chain that awaits `notificationSchedulerProvider.future` and calls `installCopy(...)`. Started with `.ignore()`, **never awaited on the frame**. The `reconcile()` line at the end of the chain is **T05's**; leave the chain one call long here |
| 6 — ARB | `lib/l10n/app_en.arb` | **Edit.** Eight channel names, eight channel descriptions, and the title/body messages `titleFor`/`bodyFor` render. Every one with a `description`; the animal's tag is a placeholder, never concatenated |
| 7 — tests | `test/data/notification_channels_test.dart` | **New.** The anchor plus §5.4's cases |

### 5.2 The signatures and the eight strings

```dart
// lib/data/notification_scheduler.dart — 08 §2.6
final class NotificationCopy {
  const NotificationCopy({
    required this.channels,
    required this.title,
    required this.body,
  });
  final List<NotificationChannelSpec> channels;   // eight
  final String Function(String kind, String? tag) title;
  final String Function(String kind, String? tag) body;
}

typedef NotificationChannelSpec = ({
  String id,               // === reminders.kind (R49)
  String name,
  String description,
  ChannelImportance importance,
});

/// OURS, not the plugin's. `Importance` lives in flutter_local_notifications and
/// lib/features/ may not import it. The gateway maps high -> Importance.high,
/// normal -> Importance.defaultImportance.
enum ChannelImportance { high, normal }
```

```dart
// lib/features/reminders/reminder_copy.dart — may see AppLocalizations and Terminology
NotificationCopy buildNotificationCopy(AppLocalizations l10n, Terminology terms);
```

The eight, from `08 §2.7`, which is `03 §5.10`'s CHECK byte for byte:

| Channel id = `reminders.kind` | Name (ARB) | Initial importance |
|---|---|---|
| `colostrum` | Colostrum | `high` |
| `navel` | Navel dip | `normal` |
| `turn_out` | Turn out | `high` |
| `tag_by` | Tag-by date | `normal` |
| `ring_dock_castrate` | Ring, dock, castrate | `normal` |
| `second_dose` | Second dose | `high` |
| `withdrawal_end` | Withdrawal period ends | `high` |
| `custom` | Other reminders | `normal` |

Banned channel ids, permanently: **`turnout`** (one word), **`dose`**, **`withdrawal`**.

The boot chain, from `08 §2.6` — the ordering guarantee is structural, not hopeful:

```dart
// lib/app.dart — started from the existing post-frame callback (01 §6.3) and
// deliberately NOT awaited on the frame. The chain INSIDE it is awaited, which
// is where the ordering comes from.
Future<void> _bootNotifications() async {
  final scheduler = await ref.read(notificationSchedulerProvider.future);
  await scheduler.installCopy(
    buildNotificationCopy(AppLocalizations.of(context)!, ref.read(terminologyProvider)),
  );
  // T05 appends the first reconcile() here, and nowhere else.
}

// …inside addPostFrameCallback, beside `ref.read(databaseProvider.future).ignore()`:
_bootNotifications().ignore();          // dart:async — 01 §6.3's spelling
```

### 5.3 The count, ruled in writing

Decision #65 named six channels; three of its six ids match no `reminders.kind` value. R49 replaced the
list with `03 §5.10`'s **eight** and banned the three orphans. `08 §2.7` and `13`'s preamble both adopt
it. Nothing in the doc set still says six.

This task therefore builds eight and, in the same commit, applies `00-README` §10's amendment rule to
the three places in *this epic* that still say six: this file's title and DoD line, the epic's task
table, and the anchor test's failure message. **The anchor test's name is not changed** — it is cited
by `00-PLAN-CRITIQUE` §11.3 and by the epic, and renaming an anchor mid-epic costs more than the
inconsistency it fixes. The count lives in the failure message, where a red build shows it.

If you find yourself writing six channels because the title says six, stop: you are one commit away
from freezing a channel list that does not cover `ring_dock_castrate`, `second_dose` or `custom`, and
every reminder of those kinds would arrive on a channel the shepherd cannot mute separately — or not
arrive at all.

### 5.4 The details that are easy to get wrong

- **The frozen list is the schema JSON, not the Dart.** The gate reads
  `drift_schemas/drift_schema_v<N>.json`, extracts the `reminders.kind` CHECK's strings, and asserts
  set equality with `NotificationCopy.channels`. Comparing the Dart channel list against a Dart
  constant in the test file is a test that agrees with itself.
- **`turn_out`, with the underscore.** `CONVENTIONS §5.1`: *turn out* is two words as a verb,
  *turn-out* hyphenated as an adjective, and the **stored key is `turn_out` everywhere, including the
  Android channel id**. `turnout` is banned in prose, in code and in the id.
- **Channel names are nouns and never clinical claims.** "Colostrum", not "Colostrum window". A channel
  name is user-facing copy and §12.2 applies to it as hard as to anything on a screen — harder,
  because nobody reviews a string that only appears in Android's own settings list.
- **Importance is an initial value only.** After creation the user owns it. `createNotificationChannel`
  can *lower* importance but never raise it, and Android restores a deleted channel's settings if you
  recreate it with the same id. Never rely on importance for correctness, and **never delete and
  recreate a channel to "fix" it** — that is the one operation that looks like a repair and is a
  permanent loss of the user's choices.
- **No custom sound.** An unfamiliar sound at 3am is worse than the familiar one.
- **No badge count.** A badge implies unread state the app does not model, and Indelible has no badge
  anywhere.
- **No full-screen intents.** `USE_FULL_SCREEN_INTENT` is restricted on Android 14+ by the same policy
  pattern as `USE_EXACT_ALARM` — Play auto-grants it to calling and alarm apps only. Do not declare it.
  A heads-up notification on a high-importance channel is what the 3am user expects anyway.
- **Channels are created by `installCopy()`, idempotently, because their names are localised.** They
  cannot be created in `initialize()`: the gateway has no `AppLocalizations` and layer rule 4 says it
  never will.
- **The notification id is `reminders.id`** — `INTEGER PRIMARY KEY AUTOINCREMENT`, stable, and
  comfortably inside int32 for any real flock. Assert that. Deriving an id from `uid.hashCode`
  collides and overflows int32, and the collision presents as *"a reminder that didn't fire"*, which
  nobody debugs.
- **The payload is `reminder:<id>` and carries nothing else.** A notification body sits on a lock
  screen and is readable without unlocking the phone. Spec §4.5 calls treatment records and losses
  commercially sensitive, so: the tag and the kind's label may appear; the medicine's product name,
  its batch number, the withdrawal period in days, and any free text may **never**. For
  `withdrawal_end`, the **clear date** as `d MMM y` with its "as you entered it" framing is the
  permitted form.
- **`project()` throws `StateError` if no copy is installed, and that is deliberate.** The alternative
  — projecting with an empty title — is a blank notification at 3am. The boot chain's ordering is what
  makes the throw unreachable in production.
- **`reminders.title` is stored, by the repository, in T04**, using `titleFor(kind, tag: tag)` from
  this task. It is a **record of what the app said**, in the same spirit as the stored `clear_date`: a
  later terminology edit does not rewrite a reminder a shepherd has already read.
- **No domain noun is a literal in the ARB.** *Ewe* may become *gimmer* (N29). The term is a
  placeholder fed by `terminologyProvider`, which is why `buildNotificationCopy` takes `Terminology`
  as well as `AppLocalizations`.
- **`_bootNotifications()` is started with `.ignore()` and never awaited on the frame.** `main()`
  awaits nothing (pre-commit decision #4) and the post-frame callback returns synchronously
  (decision #21). A failure inside the chain surfaces through `notificationSchedulerProvider`'s
  `AsyncError`, exactly as a failed database open surfaces through `databaseProvider`'s.
- **Nothing in this task is time-shaped**, so there is no `uk-zone` case here. The eight ids are
  strings and the copy is text. Say so in the commit message.

### 5.5 The full test set

`test/data/notification_channels_test.dart`

| Case | What it asserts |
|---|---|
| `'the six channel ids match the frozen list exactly'` | **The anchor.** Set equality between the `reminders.kind` CHECK read out of `drift_schemas/drift_schema_v<N>.json` and `NotificationCopy.channels.map((c) => c.id)`. The failure message names both sides and both counts |
| `'the channel id list has eight members and each is lower_snake ASCII'` | The count and `CONVENTIONS §4.6`'s stored-key rule, in one place |
| `'turnout, dose and withdrawal appear nowhere under lib/ or in the ARB'` | R49's three banned ids, as a source scan. This is the case that catches a developer following decision #65 |
| `'turn_out is spelled with the underscore in the id, the ARB key and the kind'` | The single most likely typo, and it is unfixable after release |
| `'every channel has a non-empty localised name and description'` | Through `buildNotificationCopy` with the real `AppLocalizations` — an empty channel name renders as the package id in Android settings |
| `'four channels are high importance and four are normal'` | `08 §2.7`'s table, held as data rather than as prose |
| `'no channel name contains a clinical claim'` | `ContentPolicy.bannedInUserFacingText` over the eight names and the eight descriptions. §12.2 |
| `'the notification body for withdrawal_end carries a clear date and never a day count'` | §12.1 + spec §4.5: `d MMM y`, its provenance framing, and no integer of days |
| `'no notification body contains a product name, a batch number or note text'` | The lock-screen table in `08 §2.5`, as an assertion over the rendered bodies |
| `'project() throws StateError before installCopy is called'` | The ordering guard, matched on message |
| `'installCopy is idempotent — calling it twice creates no second channel set'` | The fake records one `installCopy` per call and the channel ids do not duplicate |
| `'the notification id equals reminders.id and fits in int32'` | `08 §2.5`. Seed a reminder, project it, assert `pendingIds().single == row.id` and `row.id < 1 << 31` |
| `'uid.hashCode appears nowhere near a notification id'` | Source scan — note 06's silent pitfall #2 |
| `'every ARB message this task adds has a description and no domain noun literal'` | `10`'s rule, asserted over the ARB rather than reviewed |
| `'app.dart starts _bootNotifications with .ignore() and does not await it on the frame'` | Source text over `lib/app.dart`; the property decision #21 exists for |

## 6. Constraints that bind this task

- **Offline** — no network path may be added. G2 (the dependency allowlist) and G3 (the import scan) stay green, and the permission set never changes without G0's recorded evidence.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.
- **Accessibility and the ARB, authored here** — every string in `app_en.arb` carries a `description`,
  and no domain noun appears as a literal. There is no later sweep that adds them; N33 only verifies.
  These strings never render *in* the app, so no `semanticLabel` and no `headingLevel:` applies —
  Android's own settings list and the lock screen are their surfaces.
- **§12.2 binds hardest here**, because a notification body and a channel name are the two strings
  least likely ever to be re-read: *"Colostrum — your 2 h interval"* is a fact about a setting the
  shepherd chose; *"Colostrum is needed within 2 hours"* is veterinary advice and is banned.
- **No schema change.** `drift_schemas/` must not appear in this diff.

## 7. Definition of Done

- [ ] `'the six channel ids match the frozen list exactly'` passes, and was seen to fail first for the stated reason
- [ ] six channels, ids recorded in `CONVENTIONS` and frozen
- [ ] the payload carries enough to route to the record and nothing sensitive
- [ ] the ids are asserted against the recorded list, not against themselves
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] **the built list has eight entries** — R49's, byte-identical to `03 §5.10`'s `reminders.kind` CHECK — and the stale count in this file's title and in the line above is corrected in this commit under `00-README` §10
- [ ] `turnout`, `dose` and `withdrawal` appear nowhere in `lib/`, in the ARB or in a commit message
- [ ] the frozen list the anchor compares against is read from `drift_schemas/`, never from a Dart literal
- [ ] `installCopy()` creates the channels, is idempotent, and runs before the first `project()`
- [ ] `project()` throws with a message when no copy is installed
- [ ] `drift_schemas/` does not appear in this diff

## 8. Verification

```bash
fvm flutter test test/data/notification_channels_test.dart
make check
make test
```

```bash
# The eight, and the three that must never exist.
grep -o "'[a-z_]*'" drift_schemas/drift_schema_v*.json | sort -u | grep -E 'colostrum|navel|turn_out|tag_by|ring_dock_castrate|second_dose|withdrawal_end|custom'
grep -rn "'turnout'\|'dose'\|'withdrawal'" lib/ assets/ lib/l10n/    # expect nothing

# The copy seam stays on the right side of layer rule 4.
grep -rn 'AppLocalizations' lib/data/                                # expect nothing
grep -rn 'package:flutter/material.dart' lib/data/                   # expect nothing

# Nothing schema-shaped moved.
git diff --stat -- drift_schemas/ lib/core/db/                        # expect nothing
fvm flutter test test/policy/                                         # the ARB and content-policy rows
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(platform): the six Android notification channels`
