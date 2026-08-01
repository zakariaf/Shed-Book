# Where the shipped vocabulary came from

Spec §11 asks what licensed content this app bundles.

> **None that is licensed.**

Every term in every list below was written for this app.

The *concept* of each list is common husbandry and is not ownable — a five-point
assistance scale, a set of malpresentations, the usual routes of administration.
The *sentences* are. So the concepts are used and no published wording is
reproduced, at any length, from any source.

Each line names the list, its size, and the basis on which its terms were
written.

- **lambing_ease** (5) — authored for this app. A five-point assistance scale is
  common to several published schemes; none of their wording is used here. The
  research cited an SRUC technical note, whose text is image-based and whose
  licence terms could not be verified, so decision-record §4 overturned the
  earlier plan to adopt it verbatim. The five points are paraphrased at the same
  semantic granularity and in the app's own words. Long form:
  `assets/content/lambing_ease.md`.
- **death_cause** (8) — authored for this app. Ordinary causes a shepherd records
  in a notebook. `dc_unknown` is a cause the shepherd *picks*; it is not the same
  as a blank field, which the statistics tally as **unattributed** and never
  merge with this one.
- **malpresentation** (8) — authored for this app. The standard positions, named
  as they are named in a shed.
- **treatment_route** (8) — authored for this app. Routes of administration only.
  No product, no dose, no course, no interval: the app knows no medicine and
  suggests no value, and the withdrawal period is always read off the bottle by
  the user.
- **ewe_observation** (6) — authored for this app. What a shepherd notices and
  writes down, phrased as an observation and never as a judgement.
- **foster_method** (5) — authored for this app. The methods themselves, with no
  guidance on when to use which.

Every one of these terms is a **default**. `vocab_terms.label` is `NULL` until
the shepherd edits it, and hiding or renaming a term is an ordinary thing
to do rather than a repair.
