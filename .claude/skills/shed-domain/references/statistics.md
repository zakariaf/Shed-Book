# Statistics — denominators, edge cases and not-computable reasons

Load when adding, changing or debugging a statistic. The authority is `docs/engineering/05-domain-correctness.md` §6 (spec §7.8) and `docs/engineering/CONVENTIONS.md` §2.6; open §6 for the reasoning, the published-source contrasts and the test code. This file carries the operative rules only.

## Contents

- [Standing rule — the definition string](#standing-rule--the-definition-string)
- [The return type](#the-return-type)
- [Inputs — plain records, one watch](#inputs--plain-records-one-watch)
- [Lambing percentage](#lambing-percentage)
- [Average litter size](#average-litter-size)
- [Barren rate](#barren-rate)
- [Assisted rate](#assisted-rate)
- [Losses by cause and by age](#losses-by-cause-and-by-age)
- [Lambing spread](#lambing-spread)
- [The fostering invariant](#the-fostering-invariant)
- [Comparing seasons](#comparing-seasons)
- [Checklist for a new statistic](#checklist-for-a-new-statistic)

## Standing rule — the definition string

**Every `definition` string is read from `lib/domain/stats/definitions.dart` and is never quoted, retyped, paraphrased or reworded anywhere else** — not in a screen, a test expectation, a comment, a doc, or this file (R61). Those strings are printed into CSVs and PDFs that outlive the app; a second spelling makes two identical seasons refuse to compare (see [Comparing seasons](#comparing-seasons)). A screen may render a formula *alongside* the definition; it may never render a different definition.

A test pins the strings literally and a second test asserts the choice keys equal the `CHECK` strings in the committed schema JSON. Both live with the statistics tests, not here.

## The return type

`StatResult` (CONVENTIONS §2.6). Four parts of its contract are mandatory at every call site:

1. `definition` renders under the headline number, always — not behind an info icon.
2. `numerator / denominator` renders too. It is the cheapest way for a shepherd to sanity-check a number that looks wrong, and at 18 pt it costs one line.
3. CSV and PDF carry the definition string verbatim beside the value.
4. `value == null` means **not computable**, and `notComputableReason` is displayed as the value's replacement. No blank cell, no `NaN`, no em-dash that might mean zero, and never `0`.

`?? 0` is banned in `lib/features/season/**` and `lib/features/flock/**` (`check_policy` + the review checklist).

## Inputs — plain records, one watch

Statistics take plain Dart records (`SeasonCounts`, `DayBirths`, `LambOutcome`); no drift row and no repository reaches a domain function. The data layer builds them with `customSelect` plus an explicit `readsFrom:` — never a `groupBy` inside a Dart-defined drift `View` (decision #60). Omit `readsFrom:` and the Season Summary silently stops updating.

One `watch()` per screen. The `combineLatest`-over-drift-streams ban and its mechanism belong to **shed-riverpod-providers** (decision #12); the consequence here is that a torn Season Summary is a wrong headline number. If you need a second statement, put it inside the same `customSelect` or read it non-reactively inside the first's `map`.

`.distinct()` lives in the repository and only works because `SeasonCounts` and `DayBirths` write their own `==`/`hashCode`; a `List` result needs `listEquals` on top.

## Lambing percentage

Numerator and denominator both come from the chosen `LambingPercentageChoice` — `choice.definitionParts.count` and `.per` (05 §6.2). The default is the **AHDB** convention (owner ruling, `00-README.md` §5.1) and stays user-configurable. The four choices' wordings are R61's pinned strings and live only in `lib/domain/stats/definitions.dart`; this file deliberately does not spell any of them.

| Edge case | Behaviour |
|---|---|
| `ewes_to_ram` not entered, denominator is ewes put to ram | Not computable, with the reason naming the missing input. **Never fall back to ewes lambed** — that silently swaps in a different published convention and reads high by every ewe that was barren, sold, died or was never entered (14 points on the worked contrast in §6.2). **Never return 0.** |
| Denominator is 0 | Not computable. No division by zero, no `NaN` in a PDF. |
| More ewes lambed than were recorded put to the ram | **Compute anyway** — over 100% is normal for this metric — and attach a caveat naming the discrepancy. Warn, do not fix. |
| A ewe with no recorded outcome | Affects nothing in the numerator; she is inside the denominator if the shepherd entered it, and she is named in a caveat. |
| A lamb that died before it was tagged | **Counted, fully.** Lamb identity is the row id and `tag` is nullable at every layer. Anything else loses exactly the losses that matter most. |
| A fostered lamb | Counted once at season level. |

Build the `definition` from the choice, never from the parts at the call site.

## Average litter size

Lambs born ÷ ewes lambed, aggregated by **birth dam**, always. **Not configurable** — litter size has one meaning, and a choice here invents a disagreement the industry does not have.

| Edge case | Behaviour |
|---|---|
| A lambing with zero attached lambs | Excluded from **both** sides, with coverage reported in a caveat. A lambing always produces at least one lamb even if stillborn, so zero attached lambs always means "not recorded yet" — and because the lambing row is created on screen *entry* (decision #11) this state is common and transient. Including it deflates the headline. |
| Ewes lambed is 0 | Not computable. |
| A fostered lamb | Counted in the **birth** dam's litter, never the receiving ewe's. |

## Barren rate

Numerator is ewes the user **explicitly marked barren**; denominator is ewes put to the ram. **Absence of a lambing is never evidence of barrenness.** The rejected alternative — (ewes to ram − ewes lambed) ÷ ewes to ram — sweeps in ewes that died, were sold, aborted or were never entered. It is a silent inference about a commercially sensitive number, and at 3am on night eleven missing data overwhelmingly means "not recorded yet".

| Edge case | Behaviour |
|---|---|
| `ewes_to_ram` not entered | Not computable. |
| Ewes with no recorded outcome | Not counted as barren; named in their own caveat. |
| Ewes that died or were sold before lambing | Stay in the denominator (AHDB counts ewes put to the tup) and are named in their own caveat. |

Route this through `EweSeasonOutcome`, the derived four-way bucketing over the stored `ewe_seasons.status` keys (R43), so it is a lookup and not an inference. It never round-trips to the database and never replaces the stored keys.

## Assisted rate

Numerator is lambings scored as assisted; denominator is lambings **with an ease score**. Both sides exclude unscored lambings, and coverage is always reported. A blank score means "not scored" — reading it as "unassisted" deflates the rate and is exactly the silent inference safety rule 4 forbids.

| Edge case | Behaviour |
|---|---|
| No lambing has a score | Not computable — **not** `0%`. |
| Partial coverage | Caveat stating how many lambings are excluded from both sides. |
| Per-lamb vs per-lambing | The score sits on the lambing, not the lamb. Make the definition string say so and label the CSV column accordingly, so a future consumer is not misled. |

The 1–5 scale is spec §7.2 and stays at five. The five labels are `vocab_terms` + ARB, never domain text (R44), and must be **paraphrased at the same semantic granularity** as the published scales, never copied.

## Losses by cause and by age

Bucket boundaries match Teagasc's published breakdown (same day, 1–3 days, 4–7 days, then 8–30 and over 30 which sum back to their ">day 7" band). A `1–2 / 3–7` split straddles the published boundary and makes the comparison impossible.

| Edge case | Behaviour |
|---|---|
| Stillborn | **Its own bucket**, never "died at age 0". A stillborn lamb has no age at death, and folding it in double-counts against any "first 24 h losses" figure. |
| Died with no death date | Unknown-age bucket, counted in the total. |
| Died with no cause | Counted in the total and tallied as **unattributed** — never merged with "unknown". "Unknown" is a cause the user can pick; "unattributed" is our word for a blank field. Two columns, always. |
| Death date before the lambing date | Unknown-age bucket, plus `WarningCode.deathBeforeBirth`. |
| Died before tagging | Counted, fully. Keep a tagless dead lamb in the test fixtures. |
| A fostered lamb that died | Counted once at season level. On a ewe card there are two different numbers, labelled differently — lambs born to her that died (birth dam) and lambs lost while rearing (rearing dam). Never one number. |

Age comes from **civil dates** (`lambingDate.daysUntil(deathDate)`), so the first bucket is labelled "born and died the same day" and **never** "under 24 hours" — a day-resolution death date cannot support that claim, and claiming it is silent precision inflation.

Give unattributed a prominent row rather than hiding it: even in a studied population roughly a fifth of deaths reach no diagnosis, so a large unattributed share is real information, not a personal failing.

A loss *rate* must state its denominator (lambs lost ÷ lambs born). Prefer counts; a rate here is easy to quote wrongly.

## Lambing spread

1. **Group by the denormalised `local_date`**, never by UTC and never by a SQL date function. A 00:05 lambing belongs to that day; a 23:55 one to the day before. Getting this wrong is a once-per-night off-by-one for a whole season.
2. **Dense and zero-filled.** A gap day renders as a zero bar — the gaps are the information, because "was my tupping tight?" is a question about gaps.
3. **Anchored on the first lambing** with a day index, so two seasons overlay from day 0.
4. **Report ewes lambed within one oestrous cycle.** The cycle length comes from `app_settings.cycle_days` and the app always passes it explicitly; any default in the signature exists only so a unit test can omit it. Present it as a fact, never as a judgement.

Bar height counts **lambs**; the first-cycle figure counts **ewes**. Label both. No lambings → empty bars, null first-cycle figure, and the chart's named empty state — never a spinner, never a zero-height chart.

## The fostering invariant

**Every "born" count aggregates on the birth dam. Every "reared" count aggregates on the current rearing dam. The two are never mixed in one query.** A lamb has exactly one birth dam, so the sum of litter sizes equals total lambs by construction. A fostered lamb raises the receiving ewe's reared count and never her born count. No rearing dam means artificially reared — a third state, not a missing value. Death clears neither dam.

## Checklist for a new statistic

- [ ] The `definition` string is added to `lib/domain/stats/definitions.dart` and read from there by every consumer.
- [ ] The function takes a plain record and returns `StatResult`; it imports nothing from `lib/data/` or drift.
- [ ] Every path that cannot produce a number returns `notComputable` with a reason a shepherd can act on — no 0, no `NaN`, no blank.
- [ ] The denominator is named in the definition string and matches the numerator's population.
- [ ] Missing data produces a caveat, never an inference.
- [ ] Fostered lambs are counted once, on the correct dam.
- [ ] Unit tests cover: empty season, denominator 0, missing `ewes_to_ram`, partial coverage, and the over-100% case.
