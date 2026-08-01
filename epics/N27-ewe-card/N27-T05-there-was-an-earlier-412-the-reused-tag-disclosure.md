# N27-T05 — *"There was an earlier 412"* — the reused-tag disclosure

| | |
|---|---|
| **Epic** | [N27 — Ewe Card](epic.md) · `00-README` §9 step 10 (2 of 4) |
| **Task** | 5 of 7 |
| **Depends on** | N27-T04 |
| **Commit** | one commit · `feat(ewe_card): disclose an earlier animal with the same tag` |

## 1. Why this task exists

The active-only uniqueness ruling has a consequence a shepherd must be told about: a
reused tag means two animals share a number, and the card says so plainly with a route to the earlier
one. Without this, the ruling silently merges two ewes' histories in the reader's head.

`00-README` §5.1 says it in one line when it records the ruling: *"A culled 412 releases the tag; a new
412 is a new row with its own history. Create-on-the-fly matches active animals only, **and the ewe
card must be able to show 'there was an earlier 412'**."* This task is that sentence.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/07-screens.md` | **§4.2 (the **Reused tag** state, in full: *"An earlier 412 was culled on 12 Aug 2025. Separate record."* plus a 60 pt tap to open it, and the note that this is a normal expected state, not an error)** · §4.3 (*Change status (sold / died / culled)* — `setStatus`, correct-forward, **no undo verb**) · §3.3 (*"A tag held only by a culled or sold animal raises nothing at all: that tag is free"*) · §1.2 (a single-row lookup is permitted alongside the content statement) | the state, the copy and the route |
| `docs/research/00-tech-decisions.md` | **§7.0 ruling 7 (tags are unique among ACTIVE animals only — a partial unique index, not a global one)** · §5 for versions | the ruling this disclosure exists to make honest |
| `docs/engineering/03-data-model-and-schema.md` | **§5.2 (`Ewes` — `tag`, `tag_digits`, `status` with `CHECK (status IN ('active','sold','dead','culled'))`, and `idx_ewe_tag_active … WHERE status = 'active'`)** · §6 (tag uniqueness, settled, with the culled-tag reuse case) · §2.1 (`mixin Identified` — `created_at`, `updated_at`, and P1's `struck` pair) | what the database can and cannot tell you about an earlier animal |
| `docs/engineering/CONVENTIONS.md` | **R41 (`ewes.status` stays a mutable column; there is **no** status-history table; `setStatus` has no undo verb; and the escalation clause — *"Escalate to the owner if the retention story turns out to need 'she was culled in March 2025 and un-culled in April' — that is a schema addition, and it must land before the first snapshot"*)** · §7 item 1 (the same question, listed as deliberately unsettled) · §2.1 (`EweId`), §4.5 (widget keys), §5.4 (`d MMM y`, never all-numeric), R60 | why the *"culled on"* date in 07 §4.2's copy has no column behind it |
| `docs/engineering/05-domain-correctness.md` | §4.2–§4.3 (an event time carries provenance; a row-lifecycle timestamp is not an event time), §7.5 (§12.4 — the app never chooses which of two values is right) | why `updated_at` may not be rendered as a status-change date |
| `docs/engineering/02-state-di-navigation.md` | §8.1–§8.2 (`Routes.eweCard(context, EweId)`; the stack is three deep and this adds a fourth edge — card → card) | the route to the earlier animal |
| `docs/engineering/10-accessibility-and-i18n.md` | §3.2 (the label rules), §3.3 (`spellOutTag` on the tag range only — *"four one two"*, not *"four hundred and twelve"*), §8.5 (the terminology placeholder), §5 (wrap, never truncate) | the disclosure's label and its ARB message |
| `docs/design/indelible.md` | §8 screen 2 (beneath the header, a current-status row printed in the same clothes the fact wears elsewhere), §7.13 (the word button), §6.2 (`†` always accompanied by a word) | where the disclosure sits and what the tap target looks like |
| `docs/engineering/06-design-system.md` | §6.1 (`tapMin` 60 — 07 §4.2 says a 60 pt tap; Indelible builds to 64), §12 (`ShedStatusBadge` — icon and word, never colour alone) | the target size and the badge |
| `docs/engineering/12-testing.md` | §5.2 (targeted seed helpers), §6.1 (`ewe_card` is variant 2 — the reused-tag state is a *state* of that variant, not a fifteenth variant) | how it is asserted, and what it must not become |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-safety-rules` | the disclosure is what keeps the ruling honest |
| `shed-screens-and-routing` | the route to the earlier animal |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/ewe_card_test.dart`
- **Test** — `'a reused tag discloses the earlier animal and links to it'`
- **Why it is red today** — nothing discloses it, and the uniqueness ruling becomes invisible ambiguity.

```bash
fvm flutter test test/features/ewe_card_test.dart   # expect: failing, for the reason above
```

Sharpen the assertion so it is a real reuse and not two rows that happen to share a string. Seed
412 **through the real path**: create her, record a lambing against her, `setStatus(culled)`, then
`createEwe(tag: '412')` again — which the partial unique index now permits and would have refused a
moment earlier. Open the *new* 412's card and assert three things: the disclosure renders; it names
the earlier animal by a **date drawn from one of her own records**, not from `updated_at`; and tapping
it pushes `EweCardScreen` for the *earlier* `EweId`, whose timeline contains the lambing and whose own
disclosure does **not** point back (see §5.3 item 4).

**Green.** The minimum code that passes, and nothing beyond it — the disclosure, the route, and the read that finds the earlier animal.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**Step 3 (one read method), step 6 (the widget), step 6 item 22 (the ARB) and step 7 (tests).** No
schema — and this task is where somebody will want one; see item 2. Say the skipped layers in the
commit message.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `lib/data/flock_repository.dart` | **Edit.** `watchEarlierAnimalsWithTag(String tag, {required EweId excluding})` → `Stream<List<EarlierAnimal>>`. A **single-row-shaped lookup** (07 §1.2), not a second content statement: it reads `ewes` for non-active rows with the same `tag`, and reaches each one's newest event date through a correlated subselect over the same tables the timeline already indexes |
| 2 | `lib/features/flock/ewe_card_controller.dart` | **Edit.** `final class EarlierAnimal` and `earlierAnimalsProvider` — `StreamProvider.autoDispose.family<List<EarlierAnimal>, EweId>` |
| 3 | `lib/features/flock/widgets/earlier_animal_note.dart` | **New.** The disclosure row plus its 64 × 64 tap target. Key `ewe_card.earlier_animal` (and `ewe_card.earlier_animal.<eweId>` when there is more than one) |
| 4 | `lib/features/flock/ewe_card_screen.dart` | **Edit.** The disclosure sits **under the header and above the summary line**, per 07 §4.2's *"Under the header"* — it qualifies who this card is about, so it cannot come after the history it qualifies |
| 5 | `lib/l10n/app_en.arb` | **Edit.** Two messages: the disclosure and its tap label. Terminology placeholders; the date pre-formatted `d MMM y` |
| 6 | `docs/engineering/07-screens.md` | **Amend, §4.2.** The *"was culled on 12 Aug 2025"* copy is struck with its reason and replaced. The amendment lands in this commit, per `00-README` §10 |
| 7 | `test/support/seeds.dart` | **Edit.** `seedCulledEweWithTag(db, tag: '412', lastEventAt: …)` |
| 8 | `test/features/ewe_card_test.dart` | **Edit.** The anchor plus §5.4's cases |

### 5.2 The signatures

```dart
// lib/features/flock/ewe_card_controller.dart

/// A non-active animal that held this tag before. Everything on it is a fact
/// the database can honestly produce — see §5.3 item 2 for the one field that
/// is deliberately absent.
@immutable
final class EarlierAnimal {
  const EarlierAnimal({
    required this.eweId,
    required this.tag,
    required this.status,          // 'sold' | 'dead' | 'culled' — never 'active'
    required this.recordCount,
    this.lastRecordedAt,           // the newest EVENT time on her record, or null
  });

  final EweId eweId;
  final String tag;
  final EweStatus status;
  final int recordCount;
  final Instant? lastRecordedAt;
}

final earlierAnimalsProvider =
    StreamProvider.autoDispose.family<List<EarlierAnimal>, EweId>((ref, eweId) async* {
  final repo = await ref.watch(flockRepositoryProvider.future);
  yield* repo.watchEarlierAnimalsWithTag(/* this ewe's tag */, excluding: eweId);
});
```

```json
// lib/l10n/app_en.arb
"eweCardEarlierAnimal": "An earlier {tag} is on record, last recorded {date}. Separate record.",
"@eweCardEarlierAnimal": {
  "description": "Shown on a ewe card when a NON-ACTIVE animal holds the same tag. Tags are unique among active animals only (decision-record §7.0 ruling 7), so this is a normal expected state and must not read as an error. {date} is the date of the most recent EVENT on the earlier animal's record, pre-formatted 'd MMM y' — NOT the date her status changed, which this app does not store (CONVENTIONS R41).",
  "placeholders": {
    "tag":  { "type": "String", "example": "412" },
    "date": { "type": "String", "example": "12 Aug 2025" }
  }
},
"eweCardEarlierAnimalOpen": "Open the earlier {tag}",
"@eweCardEarlierAnimalOpen": {
  "description": "The 60 pt action beside the disclosure. Pushes that animal's own card.",
  "placeholders": { "tag": { "type": "String", "example": "412" } }
}
```

### 5.3 The details that are easy to get wrong

1. **The disclosure is unconditional, not an affordance.** 07 §4.2 lists it as a **state** of the
   loaded card. It renders whenever the tag was reused — not behind a "show history" toggle, not on a
   long-press (banned), not only when the user asks. A disclosure the user has to find is not a
   disclosure.
2. **07 §4.2's copy names a date the schema cannot produce, and this is the highest-value finding in
   the task.** *"An earlier 412 was culled on 12 Aug 2025"* needs the date her status changed.
   **R41 rules there is no status-history table**: `ewes.status` is a mutable column with `updated_at`
   moving. `updated_at` is a **row-lifecycle** fact — it moves when anyone edits her breed, her EID or
   her date of birth — so rendering it as *"culled on"* presents a maintenance timestamp as an event
   time, which is precisely the laundering §12.5 exists to prevent (05 §4.3: an event time carries its
   provenance; `updated_at` has none). The honest resolution, and what this task ships:
   - the disclosure states the **last recorded event** on the earlier animal — a real event time with
     its own provenance quad, reached through the same tables the timeline reads;
   - it states her **status word** (*sold* / *died* / *culled*) without a date, because that word is
     the current value of a mutable column and is true now;
   - 07 §4.2's copy is amended in this commit, struck with its reason, per `00-README` §10.
   - **R41's escalation is recorded in the PR body and routed to the owner.** *"She was culled in
     March 2025 and un-culled in April"* needs a schema addition, the schema was frozen at N07-T08,
     and this task is where the retention story discovers it. Do not add the table.
3. **`ewes.tag` is stored exactly as typed and is never normalised** (03 §5.2: *"Exactly as typed.
   Never normalised on write — spec §12.4"*). Match on `tag`, not on `tag_digits` — `tag_digits` is a
   projection that is *never shown* (`CONVENTIONS §5.1`) and matching on it would disclose `412` and
   `412A` as the same animal, which is a claim the shepherd did not make. If a fuzzy match ever seems
   right here, it is `rankTagMatches`'s job on a search box, not a disclosure's.
4. **The relationship is directional and it is not symmetric.** The **new** card discloses the earlier
   animal. The **earlier** card does not disclose the new one — she is finished, and telling a reader
   looking at a closed record that a different animal has her number later is noise at the moment they
   are trying to read one history. The anchor asserts both directions, because implementing this with
   one symmetric query is the obvious shortcut and it is wrong.
5. **There can be more than one earlier animal.** Nothing stops a tag being reused twice over ten
   seasons; the partial unique index only constrains the *active* set. Return a list, order it newest
   first, render one row each — and let the ARB message be per-animal rather than a joined sentence,
   because *"An earlier 412 and another earlier 412"* is not a sentence anybody wants to read at 9am.
6. **`status` is `EweStatus`, not a string, and it has exactly four values** (03 §5.2's `CHECK`).
   `'barren'` is not one of them — R42 puts barren on `ewe_seasons.status`, and a disclosure that says
   *"an earlier 412 was barren"* is confusing two different columns and two different facts.
7. **This is a single-row-shaped lookup, and it is legal.** 07 §1.2 permits *"(a) a single-row
   lookup"* alongside the content statement. What it does **not** permit is a second *content*
   statement or a `combineLatest` of this with the timeline — render them as two independent widgets
   watching two independent providers, which §1.2 explicitly allows: *"Two independent widgets
   watching two independent streams is fine."*
8. **The route is card → card and the stack must not grow without bound.** 02 §8.2 draws the deepest
   stack as three pushes. Tapping the disclosure pushes the earlier card; the earlier card's
   disclosure does not point back (item 4), so there is no loop to build. Do not `pushReplacement` —
   the shepherd wants to come back to the animal they were reading.
9. **`spellOutTag` applies to the tag range only** (10 §3.3). The spoken disclosure is *"An earlier
   four one two is on record"*, not *"An earlier four hundred and twelve"* — and the surrounding
   sentence is spoken normally. Applying the attribute to the whole label spells out the entire
   sentence letter by letter, which is the failure mode people ship.
10. **The date is `d MMM y` and never all-numeric** (R60, `CONVENTIONS §5.4`). `12 Aug 2025`, not
    `12/08/2025`. It arrives at the ARB message pre-formatted from `lib/core/ui/formatters.dart`
    (10 §8.4 rule 4).
11. **This is a state of the `ewe_card` variant, not a fifteenth variant.** The matrix is 252 cells
    over **14** variants and R58 fixes the arithmetic against the variant list. T07 pumps the
    reused-tag state as a seeded case inside `ewe_card`; it does not add a row to
    `kPumpableVariants`.
12. **The disclosure carries no colour-only signal and no alarm.** 07 §4.2: *"this line is a normal,
    expected state — not an error."* No red, no exclamation mark, no badge. Indelible §2.7: status is
    never encoded by hue.

### 5.4 The full test set this task ends with

| File | Case | Edge it covers |
|---|---|---|
| `test/features/ewe_card_test.dart` | `'a reused tag discloses the earlier animal and links to it'` | **The anchor.** Seeded through `createEwe` → `setStatus(culled)` → `createEwe`, so the partial index is exercised; the tap pushes the earlier `EweId` |
| | `'the earlier animal card does not disclose the newer one'` | The asymmetry in item 4 — the case a symmetric query passes wrongly |
| | `'the disclosure names a date from the earlier animal own records, not her updated_at'` | Item 2. Touch her `breed` after culling so `updated_at` moves, and assert the rendered date did **not** |
| | `'an earlier animal with no records at all renders the disclosure without a date'` | `lastRecordedAt == null`. A ewe created and culled the same afternoon is real, and the sentence must still be a sentence |
| | `'a tag reused twice renders two disclosures, newest first'` | Item 5 |
| | `'412 and 412A are different tags and neither discloses the other'` | Item 3 — matching on `tag_digits` fails here |
| | `'a tag held only by an active animal renders no disclosure'` | The negative. Two active 412s are unstorable (the partial index), so this is the ordinary case |
| | `'a sold animal and a dead animal both count as earlier animals'` | All three non-active values, not just `culled` |
| | `'the disclosure renders whenever the tag was reused, with no toggle and no gesture'` | Item 1, plus the gesture ban: assert no `Dismissible`, no long-press handler in the subtree |
| | `'the disclosure tap target measures at least 64 by 64'` | 07 §4.2 says 60 pt; Indelible builds to 64. The geometric assertion, at `Device.small` |
| | `'the spoken disclosure spells out the tag and speaks the rest normally'` | 10 §3.3. Assert the `SpellOutStringAttribute` range, not just its presence |
| | `'the disclosure carries no colour-only signal'` | Item 12; grayscale-equivalent assertion |
| | `'the disclosure renders above the summary line'` | Widget order — it qualifies who the card is about |
| | `'the disclosure wraps at textScale 2.0 with boldText and does not truncate'` | 10 §5. Two tag numbers and a date is the longest line on the card |

## 6. Constraints that bind this task

- **§12.4, held at *caught by a test*.** Active-only tag uniqueness means a reused 412 is a new animal with its own history; saying nothing would silently merge two ewes' histories in the reader's head, which is a correction the app made without telling anybody. The disclosure and its route to the earlier animal are the mechanism, and `00-README` §5.1 is the ruling that requires them. The earlier animal's rows are never rewritten, re-tagged or hidden.
- **Accessibility and the ARB, authored here** — every string in `app_en.arb` with a `description`, every element a `semanticLabel` and a `<screen>.<element>` key, every heading a `headingLevel:`. There is no later sweep that adds them; N33 only verifies.
- **No schema.** R41 is the temptation and the answer is a PR-body escalation, not a table.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'a reused tag discloses the earlier animal and links to it'` passes, and was seen to fail first for the stated reason
- [ ] the disclosure names the earlier animal's dates
- [ ] it links to that animal's card
- [ ] it renders whenever the tag was reused, not only when the user asks
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] every date it renders is an **event** time from the earlier animal's own records; `ewes.updated_at` appears nowhere in this feature
- [ ] `07-screens.md` §4.2's *"was culled on"* copy is amended in this commit, struck with its reason
- [ ] R41's escalation is recorded in the PR body and routed to the owner; no table was added
- [ ] the match is on `tag`, never on `tag_digits`
- [ ] the relationship is one-directional, proved by a test
- [ ] the tap target measures ≥ 64 × 64 at `Device.small` and carries a `semanticLabel`
- [ ] `kPumpableVariants` still has 14 entries

## 8. Verification

```bash
# 1. Red first, for the stated reason.
fvm flutter test test/features/ewe_card_test.dart

# 2. Green, plus the flock tier — the partial index is N07's and N26 reads it.
fvm flutter test test/features/ewe_card_test.dart test/features/flock_test.dart

# 3. Nothing moved in the schema.
make gen && git diff --exit-code -- lib/ drift_schemas/ test/drift/generated/

# 4. Both gates.
make check
make test
```

```bash
grep -rn "updated_at\|updatedAt" lib/features/flock/   # expect: nothing
grep -rn "tag_digits\|tagDigits" lib/features/flock/ewe_card_controller.dart  # expect: nothing
grep -n "culled on" docs/engineering/07-screens.md     # expect: struck, with its reason
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(ewe_card): disclose an earlier animal with the same tag`
