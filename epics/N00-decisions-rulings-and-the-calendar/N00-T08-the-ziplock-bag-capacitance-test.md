# N00-T08 — The ziplock-bag capacitance test

| | |
|---|---|
| **Epic** | [N00 — Decisions, rulings and the calendar](epic.md) · `00-README` §9 step 0 |
| **Task** | 8 of 9 |
| **Depends on** | N00-T06 |
| **Commit** | one commit · `docs: record the ziplock-bag capacitance result and its consequence` |

## 1. Why this task exists

A phone, a freezer bag and a recorded result per target device. Spec §17 item 4 says it
plainly: if the target hardware does not register taps reliably through a bag, the whole interaction
model is re-cut around volume-button shortcuts — which invalidates N13 onward. The old plan gave this
prose in a parallel-work section and no owner, no epic and no date. It gets all three here, and the
named consequence goes in the ledger next to the result.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `shed-book-spec.md` | §17 item 4, §5 | the question in the owner's words, and the 3am test the answer feeds |
| `docs/research/00-tech-decisions.md` | §2 J #100, #101, #102; §4 (the §17.4 row); §7.1 item 2 | the 60×60 pt floor, the gesture ban, and volume-button shortcuts marked *"Reopened. Not answered"* — the three decisions that change if this fails |
| `docs/engineering/06-design-system.md` | §6, §7 | the tap-target contract and the gesture ban this measurement is testing the premise of |
| `docs/engineering/00-README.md` | §2.2, §5.2 item 2 | the 3am test as a shipping gate, and *"a hardware test, not a desk decision"* |
| `epics/00-PLAN-CRITIQUE.md` | §2 | *"No task at all"* — the defect this task closes |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-accessibility-and-copy` | the outcome is an interaction-model question — targets, hit slop and what a tap has to survive |
| `shed-conventions` | the ledger row and the consequence wording |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/policy/calendar_commitments_test.dart`
- **Test** — `'the ziplock row carries a date, a device and an outcome'`
- **Why it is red today** — the row is empty and decisions #100–#102 rest on an unmeasured assumption.

```bash
fvm flutter test test/policy/calendar_commitments_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — test each target device through a bag, record pass or fail per device, and write the named
consequence — *decisions #100–#102 change and the interaction model is re-cut around volume-button
shortcuts* — into the outcome cell.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

One ledger row, one test case, and a measurement that needs a phone, a freezer bag and twenty minutes.
The deliverable that matters is the *consequence sentence*, written before the result is known, so that
the result cannot be argued with afterwards.

| # | File | What changes, and why |
|---|---|---|
| 1 | `docs/calendar.md` — `ziplock_capacitance` | Owner, the date measured, and an outcome cell carrying one line per target device: model, OS version, and pass or fail under each of the five conditions below |
| 2 | `test/policy/calendar_commitments_test.dart` | One named-row case beside T06's anchor and T07's two |
| 3 | `docs/research/00-tech-decisions.md` §7.1 item 2 | Struck with the result and the date |
| 4 | `docs/research/00-tech-decisions.md` §2 J #100, #101, #102 | Each row gains the measurement as its evidence — or, if the bag fails, each is **struck and re-decided** in this same commit, per the amendment rule |
| 5 | `docs/engineering/00-README.md` §5.2 item 2, §2.2 | The open list loses item 2; the 3am table's tap-target row cites a measurement rather than an assumption |

### The measurement, so two people get the same answer

A standard 1 L LDPE freezer bag, the kind a shepherd already has, sealed over the phone. Test **every
target device** at the OS version it will ship to, and record each of these separately:

| # | Condition | Why it is on the list |
|---|---|---|
| 1 | A single tap on a 60×60 pt target, dry bag, bare hand | The baseline decision #100 assumes |
| 2 | The same, with the bag **wet** on the outside | This is the shed condition, and it is the one that fails: water on a capacitive surface produces phantom touches, not missed ones |
| 3 | The same, with a wet or gloved hand inside | Spec §5's actual user. Gloves and cold are worse than ideal, and Parhi et al.'s 9.2/9.6 mm optimum is for a *bare* thumb in ideal conditions |
| 4 | Two taps in quick succession on the same target | The double-tap defence (decision #22) exists because cold, wet fingers on capacitive glass double-fire. Confirm the hardware double-fires rather than misses |
| 5 | The same tap with the vendor's "glove mode" / increased touch sensitivity **off** | It is off by default on the Androids that have it. A result that only holds with it on is a fail for a stock device |

**Pass means: every condition registers a tap on the intended 60×60 pt target, and no condition produces
a phantom touch elsewhere.** Anything else is a fail, recorded per device with the condition that
failed.

### The consequence, written down before the result

If it fails, decisions **#100** (60×60 pt floor, 72–88 pt for the five primary 3am actions),
**#101** (the gesture ban — every action reachable by one simple pointer action) and **#102**
(volume-button shortcuts, currently *"Reopened. Not answered"*) all change, and the interaction model is
re-cut around volume-button shortcuts. That invalidates N13 onward, which is why this is an epic-0 task
and not a design note.

## 6. Constraints that bind this task

- **The 3am test** (spec §5) — one thumb, one hand, gloves, wet hands, 60×60 pt minimum. This measurement is the premise of that whole clause; if it fails, the clause is unchanged but the mechanism that satisfies it is not.
- **No swipe, drag, long-press, pinch or force touch** (decision #101) — the measurement uses a single tap only, because that is the only gesture the product has. Do not test a swipe through the bag; there are no swipes to save.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

### The details that are easy to get wrong

- **The bag is not the failure mode; the water on it is.** Capacitive digitisers couple happily through
  a thin dielectric — 50 µm of LDPE is nothing. What breaks them is a conductive film across the
  surface, which is exactly what a shed produces. A test run on a dry bag at a kitchen table passes and
  proves nothing.
- **The bag is a user workaround, never a product feature.** The app cannot detect it, must not detect
  it, and no code path may branch on it. What the measurement changes is a *decision*, not a runtime.
- **Volume-button shortcuts are not a free fallback.** On Android, capturing volume keys outside your
  own foreground activity needs a media session or an accessibility service; on iOS it is bounded by
  App Store Guideline 2.5.9, which is the ground note 05 used to close the question from a desk before
  c3 reopened it. Either route is a new permission or a new entitlement — and a new permission is a
  change to the set **G0 records at N02**. If this fails, N02's answer changes shape too.
- **Record the OS version, not just the model.** Touch rejection and palm/moisture heuristics are
  firmware, and the same handset behaves differently across a major OS release. `13 §12` item 1 already
  makes "read it yourself on the artefact you are about to ship" a habit; this is the same habit applied
  to hardware.
- **Do not test with a screen protector unless the target ships with one**, and if you do, say so in
  the outcome cell. It is another dielectric layer and it changes the answer.
- **A partial pass is a fail with a named condition.** *"Works dry, phantom touches wet"* is the most
  likely result and it is a genuine answer — it points at hit slop and target size rather than at
  volume buttons. Write the condition, not a verdict.
- **This row's consequence sentence is the row's real content.** The critique's complaint about the old
  plan was not that the test was missing; it was that the test had *"no owner, no epic and no date"* and
  its consequence lived in prose. A date with no consequence beside it repeats the defect.
- **Nothing here is time-shaped.** The recorded date is a civil date in a document, and the ledger test
  reads no clock (T06, sixth case).

## 7. Definition of Done

- [ ] `'the ziplock row carries a date, a device and an outcome'` passes, and was seen to fail first for the stated reason
- [ ] a result per target device, with the OS version
- [ ] the consequence if it fails is written, not implied
- [ ] if it fails, decisions #100–#102 are struck in this commit per the amendment rule
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
fvm flutter test test/policy/calendar_commitments_test.dart
```

By path, not `--tags calendar` — the tag is not declared until N01-T04 and an undeclared tag matches
nothing (`12 §11.2`). The failure message must have shrunk to three rows: `developer_accounts`,
`apple_sbp_enrolment`, `price_and_territories`.

Then confirm the amendment rule was applied, because a measurement that contradicts three decisions and
leaves them standing is worse than not measuring:

```bash
grep -n "Reopened. Not answered" docs/research/00-tech-decisions.md   # #102 must now cite the result
grep -rn "ziplock" docs/engineering/00-README.md                       # §5.2 item 2 struck
```

The case this task adds:

| Case | Asserts |
|---|---|
| `'the ziplock row carries a date, a device and an outcome'` | the anchor: the row is complete under T06's `complete` rule |
| `'the ziplock outcome names a device and an OS version'` | the outcome cell contains at least one device string and a version number — *"passed"* alone does not pass |
| `'the ziplock row states its consequence'` | the last column names decisions #100, #101 and #102 by number, so a future reader cannot mistake the scope |

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `docs: record the ziplock-bag capacitance result and its consequence`
