# N06-T05 — Lambing percentage, average litter size and barren rate

| | |
|---|---|
| **Epic** | [N06 — Domain: statistics, warnings and policy](epic.md) · `00-README` §9 step 2 (3 of 3) |
| **Task** | 5 of 11 |
| **Depends on** | N06-T04 |
| **Commit** | one commit · `feat(domain): lambing percentage, litter size and barren rate` |

## 1. Why this task exists

Three statistics, each carrying its **verbatim definition**, its numerator, its
denominator and its caveats — because *lambing percentage* means at least four different things and
the number is worthless without which one it is.

`05` §6's epigraph measures the cost: one toy season — 5 ewes to the ram, 3 lambed, 6 lambs of which
1 stillborn and 1 dead at 2 days, 1 ewe recorded barren, 1 with no recorded outcome — reads as
**120% / 100% / 80% / 200%** under four legitimate published definitions. A bare `double` leaving
this layer is a lie waiting to be quoted over a gate.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/05-domain-correctness.md` | §6.2, §6.4, §6.5, §6.6, §6.10, §6.11 | the four choices and the two pairs deliberately not offered; every edge case and caveat sentence for the three statistics; the fostering invariant; the refusal to compare two definitions |
| `docs/engineering/CONVENTIONS.md` | §2.6, §5.4, R61 | the function shapes, and that the definition string is rendered verbatim and never paraphrased |
| `docs/engineering/03-data-model-and-schema.md` | §5.6, §5.14 | the denominator rule: prefer `seasons.ewes_to_ram`, else `COUNT(ewe_seasons WHERE status='to_ram')`, else `notComputable` — it **never** falls back to ewes lambed |
| `docs/research/00-tech-decisions.md` | §2 #58, #59 | `StatResult`; the statistic inputs |
| `shed-book-spec.md` | §7.8 | *"with the definition configurable"* |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-domain` | the arithmetic and the definitions |
| `shed-testing` | each definition is a test case, not a comment |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/domain/stats/lambing_percentage_test.dart`
- **Test** — `'lambing percentage states its verbatim definition and both AHDB choices'`
- **Why it is red today** — nothing computes a season statistic.

```dart
final c = toySeason;   // 5 to the ram, 3 lambed, 6 born, 1 stillborn, 1 dead at 2 days
expect(lambingPercentage(c, LambingPercentageChoice.bornAlivePerEweToRam).value, 100.0);
expect(lambingPercentage(c, LambingPercentageChoice.bornAlivePerEweToRam).definition,
    'lambs born alive per ewe put to the ram');
expect(lambingPercentage(c, LambingPercentageChoice.bornInclStillbornPerEweToRam).value, 120.0);
expect(lambingPercentage(c, LambingPercentageChoice.bornInclStillbornPerEweToRam).definition,
    'lambs born incl. stillborn per ewe put to the ram');
```

```bash
fvm flutter test test/domain/stats/lambing_percentage_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — three pure functions over `SeasonCounts`, each returning a `StatResult` with its
definition string attached to the value, not to the screen.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

`00-README` §8 step 2 only; steps 1 and 3–6 are skipped and the commit message says so. These are
pure functions over the record T04 built. Nothing reads a database, nothing reads a clock, nothing
formats.

### 5.1 The files, in order

| # | File | What changes, and why |
|---|---|---|
| 1 | `lib/domain/stats/lambing_percentage.dart` | **New.** `StatResult lambingPercentage(SeasonCounts, LambingPercentageChoice)`. Numerator by `choice.definitionParts.count`, denominator by `.per`, `definition` copied from `choice.definition` — never rebuilt at the call site |
| 2 | `lib/domain/stats/litter_size.dart` | **New.** `StatResult averageLitterSize(SeasonCounts)`. Not configurable |
| 3 | `lib/domain/stats/barren_rate.dart` | **New.** `StatResult barrenRate(SeasonCounts)`. Recorded barren only |
| 4 | `test/domain/stats/lambing_percentage_test.dart` | **New.** The anchor plus §6.4's six edge cases |
| 5 | `test/domain/stats/litter_size_test.dart` · `barren_rate_test.dart` | **New.** §6.5's and §6.6's edge cases |

### 5.2 The signatures

```dart
// lib/domain/stats/lambing_percentage.dart
/// `value` is a PERCENTAGE: numerator / denominator * 100.
/// `definition` is `choice.definition`, verbatim (R61) — never rebuilt from
/// the parts, or two call sites word it differently and §6.11 then refuses to
/// compare two identical seasons.
StatResult lambingPercentage(SeasonCounts c, LambingPercentageChoice choice);

// lib/domain/stats/litter_size.dart
/// `value` is a MEAN, not a percentage: lambsBorn / ewesLambed. "avg 2.0".
/// Always aggregated by BIRTH dam. Not configurable — "litter size" has one
/// meaning, and offering a choice invents a disagreement the industry does
/// not have.
StatResult averageLitterSize(SeasonCounts c);

// lib/domain/stats/barren_rate.dart
/// `value` is a PERCENTAGE: ewesRecordedBarren / ewesPutToRam * 100.
/// Only ewes the user has EXPLICITLY marked barren are counted. Absence of a
/// lambing is never evidence of barrenness.
StatResult barrenRate(SeasonCounts c);
```

### 5.3 The edge cases, which are the specification

Every row is a named test. `05`'s definition of done lists them by name and this table is that list
for these three functions.

**`lambingPercentage` (§6.4)**

| Case | Behaviour |
|---|---|
| `ewesPutToRam` null and `per == ewesPutToRam` | `notComputable`, reason *"The number of ewes put to the ram has not been entered for this season."* **Never fall back to `ewesLambed`** — that silently swaps in a different published convention and reads high by every barren, sold, dead or unentered ewe (14 points on §6.2's worked contrast). **Never return 0.** |
| denominator is 0 | `notComputable`. No division by zero, no `NaN` in a PDF |
| more ewes lambed than were recorded to the ram | **Compute anyway** — over 100% is normal — and attach the caveat *"3 ewes have lambed but only 2 were recorded as put to the ram."* Warn, do not fix |
| a ewe with no recorded outcome | Affects nothing in the numerator; caveat *"1 ewe has no recorded outcome."* |
| a lamb that died before it was tagged | **Counted, fully.** Identity is the row id; `tag` is nullable at every layer |
| a fostered lamb | Counted **once**, on the birth dam (§6.10) |

**`averageLitterSize` (§6.5)**

| Case | Behaviour |
|---|---|
| a lambing with **zero** attached lambs | Excluded from **both** sides, with coverage reported: *"2 lambings have no lambs recorded yet and are excluded."* A lambing always produces at least one lamb even if stillborn, so zero attached lambs always means "not recorded yet" — and because the row is created on screen *entry* (decision #11) this state is common and transient. Including it would deflate the headline |
| `ewesLambed == 0` | `notComputable` |
| a fostered lamb | Counted in the **birth** dam's litter, never the receiving ewe's |

**`barrenRate` (§6.6)**

| Case | Behaviour |
|---|---|
| `ewesPutToRam` null | `notComputable` |
| ewes with no recorded outcome | Not counted as barren. Caveat *"4 ewes have no recorded outcome. They are not counted as barren."* |
| ewes that died or were sold before lambing | Stay in the denominator — AHDB's denominator is ewes put to the tup — and get their own caveat |

### 5.4 The details that are easy to get wrong

- **The rejected barren formula is the one you will reach for.** `(ewesToRam − ewesLambed) /
  ewesToRam` sweeps in ewes that died, were sold, aborted or were simply never entered. It is a
  silent inference about a commercially sensitive number (spec §4.5), and at 3am on night eleven the
  absence of data overwhelmingly means "not recorded yet". Numerator is `ewesRecordedBarren`,
  full stop.
- **`value` does not carry its unit and `StatResult` cannot express one.** Lambing percentage,
  barren rate and (in T06) assisted rate are `× 100`; average litter size is a plain mean. Put that in
  each function's doc comment and in the test names, because a renderer that appends `%` from the
  type would print "200%" for a pair of twins.
- **The four offered choices are not the six possible pairs.** `LambCount` × `FlockDenominator`
  admits six; `app_settings.percentage_definition` stores four. The 200% in `05` §6's epigraph is
  the fifth pair — *born incl. stillborn per ewe lambed*, OMAFRA's published convention — and the app
  deliberately does not offer it. Do not "complete the matrix": an unstorable pair is a `CHECK`
  violation in N07 and a broken comparison in §6.11.
- **On the toy season the four offered choices give 120%, 100%, 167% and 80%.** Compute them by hand
  before you write the test and put all four in it. If your implementation gives 200% for any of
  them, you have built the pair that is not offered.
- **`definition` is copied from `choice.definition`, never rebuilt from `definitionParts`.** R61
  pins the four strings because they are printed into CSVs and PDFs that outlive the app. Two call
  sites that word it differently produce two seasons that §6.11 refuses to compare — correct
  behaviour, impossible to explain to a shepherd with no support channel to call.
- **Caveats are facts, never judgements.** *"32 of 48 ewes lambed in the first 17 days"* is a fact;
  *"your tupping was tight"* is a judgement and is banned by §12.2 (`06` §86). The caveat strings in
  §5.3 are copied verbatim for the same reason the definitions are.
- **Caveats carry counts, so they are built with the numbers, not with a plural `s`.** `10` §8.5's
  rule holds here even though this file is not the ARB: the *sentence* eventually belongs to a
  message with placeholders, and the domain hands over the numbers. Keep the caveat plain and
  numeric.
- **Coverage is reported even when nothing is excluded**, so that "no caveats" means "we looked" and
  not "we forgot to check". An empty `caveats` list is a claim.
- **`?? 0` is not caught by the gate in this folder.** `stat.zero_default` scopes to
  `lib/features/season/` and `lib/features/flock/`. Every nullable arithmetic here is held by a test
  and by nothing else.
- **Fostering is already conserved by the record shape, and you must not re-derive it.** Every "born"
  count aggregates on `birth_dam`; every "reared" count on the current rearing dam; the two are never
  mixed in one query (§6.10). `SeasonCounts` hands you both; do not add a third.

### 5.5 The full test set

| File | Cases |
|---|---|
| `test/domain/stats/lambing_percentage_test.dart` | **anchor:** `'lambing percentage states its verbatim definition and both AHDB choices'` · `'the toy season reads 120, 100, 167 and 80 under the four offered choices'` · `'a blank ewes_to_ram returns notComputableReason and never falls back to ewesLambed'` · `'a zero denominator returns notComputable, not NaN'` · `'more ewes lambed than recorded to the ram computes anyway and attaches the caveat'` · `'a ewe with no recorded outcome changes no numerator and is named in a caveat'` · `'a tagless dead lamb is counted'` · `'a fostered lamb is counted once'` · `'the definition string is choice.definition, character for character'` (all four) |
| `test/domain/stats/litter_size_test.dart` | `'lambsBorn over ewesLambed, aggregated by birth dam'` · `'a lambing with zero attached lambs is excluded from both sides and reported as coverage'` · `'ewesLambed == 0 returns notComputable'` · `'a fostered lamb stays in the birth dam's litter'` · `'the value is a mean, not a percentage'` |
| `test/domain/stats/barren_rate_test.dart` | `'only ewes recorded barren are counted'` · `'absence of a lambing is never barren'` — the rejected formula, asserted to give a different (wrong) answer on the same counts, so a future "simplification" fails here · `'a blank ewes_to_ram returns notComputable'` · `'ewes with no recorded outcome are not barren and are named in a caveat'` · `'ewes that died or were sold stay in the denominator'` |

**No `uk-zone` case.** These three functions take counts, not instants. The season *bounds* that
produce those counts are T06's problem, and that is where the 01:00–01:59 cases live.

## 6. Constraints that bind this task

- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.
- **§12.2** — the app may arithmetic-transform a number the user supplied; it may never originate one that is a clinical or managerial judgement. Every caveat in this diff is a count, not an opinion.

## 7. Definition of Done

- [ ] `'lambing percentage states its verbatim definition and both AHDB choices'` passes, and was seen to fail first for the stated reason
- [ ] every statistic carries its definition in the result
- [ ] both percentage choices are computable and the choice is the user's
- [ ] every zero-denominator path returns `notComputableReason`
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
fvm flutter test test/domain/stats/lambing_percentage_test.dart
fvm flutter test test/domain/stats/
grep -rn "?? 0" lib/domain/stats/        # expect: nothing
make check
make test
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(domain): lambing percentage, litter size and barren rate`
