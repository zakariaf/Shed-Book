# A4 — Mechanical validation

**Lens:** mechanical validation. Is the skill set *well formed*? Not: is it well written.
**Artefact built:** `tool/validate_skills.py` — dependency-free, stdlib-only, exit-code driven.
**Date:** 2026-07-28. **Verdict:** PASS with warnings (exit 0), with one caveat about *when* it
passed — see §6.

---

## 1. What the checker enforces

Every threshold is a named constant at the top of `tool/validate_skills.py`. Provenance below.

| Check | Level | Threshold | Where the number comes from |
|---|---|---|---|
| Skill directory has a `SKILL.md` | FAIL | — | structural |
| Frontmatter present and closed | FAIL | — | structural |
| Unquoted inline value containing `": "` | FAIL | — | documented silent-failure mode |
| Duplicate frontmatter key | FAIL | — | structural |
| `name` absent / mismatched / not kebab-case | FAIL | — | platform constraint |
| `name` length | FAIL | `NAME_MAX_CHARS = 64` | platform limit |
| `name` contains a reserved word | FAIL | `anthropic`, `claude` | platform constraint |
| `description` absent or empty | FAIL | — | without it the skill never auto-triggers |
| `description` length | FAIL | `DESCRIPTION_MAX_CHARS = 1024` | platform limit |
| `description` opens in first/second person | FAIL | `I `, `You `, `I can`, `Use this to` | third-person rule |
| `description` contains a 1st/2nd-person pronoun | WARN | — | style, not a defect |
| Unknown frontmatter key | WARN | verified key set | **see §2** |
| Body length | FAIL / WARN | `BODY_FAIL_LINES = 500` / `BODY_WARN_LINES = 200` | 500 is Anthropic's documented ceiling; 200 is this project's target, just above the ~132-line median of Anthropic's shipped skills |
| Total listing budget (names + descriptions) | FAIL / WARN | `LISTING_FAIL_CHARS = 8000` / `LISTING_WARN_CHARS = 6000` | **see §5** |
| Supporting file on disk never named in SKILL.md | FAIL | — | progressive disclosure only works if the file is announced |
| Supporting file named but absent from disk | FAIL | — | structural |
| Reference file with no table of contents | FAIL | `REFERENCE_TOC_LINES = 100` | documented authoring rule |
| Backslash in a documented path | FAIL | — | **see §3** |
| Pointer to a sibling skill that does not exist | FAIL | — | added; see §4 |
| Empty directory inside a skill | FAIL | — | task item 4 |
| Stray file at the skills root | FAIL | — | task item 4 |

Exit codes: `0` clean or warnings only, `1` at least one failure, `2` no skills root.
An optional argv root (`validate_skills.py <dir>`) lets CI point elsewhere and lets the checker be
tested against a broken fixture — which is how §7 was done.

## 2. Why the frontmatter parser is hand-rolled, and why unknown keys only warn

PyYAML is not stdlib. This script has to run on a bare `python3` in CI with no `pip install`, so
importing a third-party parser to validate a file whose whole point is "no surprises" would be
self-defeating. The subset that must be parsed is small and closed: a flat mapping of scalars whose
only non-trivial construct is a block scalar (`>-`, `>`, `|`, `|-`) wrapping a long description. No
nesting, no anchors, no flow mappings, no multi-document streams. That parses correctly by hand.

The trade-off is real and is stated in the file: the hand parser is **more permissive** than YAML on
constructs it does not model. It therefore explicitly checks the one documented silent-failure trap —
an unquoted inline value containing `": "`, which real YAML rejects and which Claude Code answers by
loading the skill with **empty metadata**: the skill still responds to its slash command and never
auto-triggers again. Anything stranger passes here and belongs to `claude plugin validate`, which is
the authority on YAML parseability.

**Unknown keys warn rather than fail** because the field set is versioned by the Claude Code release.
An unrecognised key is either a typo the loader silently drops or a field newer than this script's
verified list, and *from disk alone those two are indistinguishable*. Failing the build would make
the checker go stale and wrong every time the CLI grows a field. The allowed set is the Claude Code
frontmatter reference plus the agentskills.io spec fields (`license`, `compatibility`, `metadata`).

## 3. The backslash rule, and its declared blind spot

The naive rule — any backslash between word characters — is useless in this corpus. It produced four
false positives on the first run, all from prose that quotes patterns rather than paths:

```
`save\w*\(`                  a grep pattern            shed-screens-and-routing
`SemanticsService\.`         a grep pattern            shed-accessibility-and-copy
`PK\x03\x04`                 a ZIP magic number        shed-export-and-restore
`SQLite format 3\0`          a SQLite magic number     shed-export-and-restore
```

None is a path; all four are correct as written. The rule now reports a backslash only where it is
demonstrably acting as a **path separator**: a drive-letter prefix, mixed separators in one token, a
final segment that is a filename with an extension, or a leading segment that is a known repo or
skill directory name.

**Declared blind spot:** a two-segment Windows path with no extension, no drive letter and an
unfamiliar first segment (`foo\bar`) is not reported, because on disk it is indistinguishable from a
regex escape. Widening the rule to catch it costs four false positives in this repo alone. This is
written into the source, not hidden.

## 4. Two checker bugs found and fixed, and one check added

The first run reported **7 failures. All 7 were checker defects, not skill defects.** Each context
was opened and read before the checker was touched — the finding is that the skills were right and
the checker was wrong, and that is recorded here rather than quietly reversed.

1. **Four false backslash positives** — the four quoted above. Fixed as §3.
2. **Three false "file does not exist" positives.** The checker treated `assets/` as a skill-internal
   support directory, so `assets/fonts/AtkinsonHyperlegibleNext[wght].ttf` (shed-goldens-rebaseline)
   and `assets/` (shed-monetization, shed-screens-and-routing) resolved against the skill directory
   and failed. In a Flutter repo `assets/` is the **application's** asset directory —
   `shed-conventions` line 26 creates it with `mkdir -p … assets/{fonts,content}`. Those SKILL.mds
   were naming project paths correctly. The checker now treats only `references/`, `reference/`,
   `examples/` and `scripts/` as unconditionally skill-internal, plus any directory that actually
   exists inside the skill. `assets/` and `templates/` count only when the skill really contains one.

**Added:** a cross-reference integrity check. Descriptions in this set end with
`Do NOT use for X (other-skill)`; a pointer at a renamed or never-built skill sends Claude nowhere
and no other check can see it. The prefixes are derived from the directories on disk, so the check
configures itself. All 24 referenced skill names resolve to real directories.

## 5. The listing budget — the one finding that matters

`LISTING_WARN_CHARS = 6000` / `LISTING_FAIL_CHARS = 8000` are **this project's guard rails, not
published limits.** The published constraint is that Claude Code loads every skill name and
description at startup within `skillListingBudgetFraction`, default **1% of the model's context
window**, and that on overflow it **silently drops descriptions starting with the least-invoked
skills**. At a 200k context that is ~2,000 tokens ≈ **~8,000 characters**, which is where the
ceiling comes from.

The set currently measures **7,795 chars — about 97% of the real budget.** During this audit it was
also measured at **8,037 chars, i.e. over the ceiling** (see §6). It straddles the line.

This is the one warning worth acting on, and it was deliberately **not** fixed here:

- The threshold is not wrong, so it was not weakened.
- The safest lever is the four `disable-model-invocation: true` skills — `shed-code-review` (388),
  `shed-goldens-rebaseline` (404), `shed-migrations` (360), `shed-release` (409), **1,561 chars
  combined**. These never auto-trigger, so their descriptions carry **no keyword-matching burden**;
  they only have to tell a developer what the skill does at the point of invoking it by name.
  Trimming those four to ~200 chars each recovers ~760 chars with zero risk to auto-triggering.
  That is an editorial call on another lens's prose, and it was left to the owner.
- The alternative is configuration: `skillListingBudgetFraction: 0.02` in `.claude/settings.json`.
  **Deliberately not applied** — a subagent does not edit the user's configuration.

Whichever is chosen, verify with `/doctor` and the **Skills** row of `/context`, which reports the
post-budget size. The failure mode if it overflows is silent: "my skill stopped triggering" with
nothing changed in the file.

## 6. Caveat: the tree moved during the audit

**The skill files were being rewritten by a concurrent process throughout this audit.** This is not
speculation — it was measured. Twelve `SKILL.md` files changed between the first and second
validator runs, and `mtime` polling showed continuous writes for over seven minutes:

```
idle=  19.0s   idle=   4.9s   idle=   5.8s   idle=   1.0s   idle=   1.0s
idle=   3.8s   idle=   3.4s   idle=   3.6s   idle=   1.0s   idle=  18.8s
idle=  10.2s   idle=  15.4s   idle=   4.3s   idle=   2.8s   idle=   4.3s
idle=   1.7s   idle=   3.2s   idle=   3.2s   idle=   0.1s   idle=  20.1s
idle=   4.8s   STILL CHANGING after 7min
```

Consequences, stated plainly:

- Descriptions were rewritten mid-audit. `indelible-controls` measured 303 → 255 → 228 chars;
  `shed-platform-gateways` 288 → 431 → 391; `shed-monetization` 274 → 232 → 172.
- The **listing budget crossed the ceiling and came back**: 7,602 → **8,037 (FAIL)** → 7,795 (warn).
  The 8,037 reading is why §5 says the set straddles the line rather than sits safely under it.
- A second-person pronoun warning on `indelible-design-system` ("sans means **you** press it")
  appeared in run 1 and was gone by run 3 — resolved by the other process, not by this lens.
- **No skill file was edited by this lens.** Editing prose that another agent is actively rewriting
  would have raced and clobbered. The final run below was taken only after the tree had been idle
  for 131 seconds.

**This report certifies the tree as of the timestamp of the run in §8.** Re-run the checker after
the concurrent work lands. It is one command and it is the whole point of building it.

## 7. Proof the checker is not vacuous

A validator that only ever passes is worthless. The checker was run against two deliberately broken
fixtures. **All 22 failure modes fired; both fixtures exited 1.**

Fixture 1 — 16 failures, exit 1: stray root file; no `SKILL.md`; empty directory; missing
frontmatter; unclosed frontmatter; unquoted inline `": "`; name/directory mismatch; non-kebab name;
reserved word `claude` in name; first-person description opener; backslash path
(`android\app\build.gradle`); dangling sibling-skill pointer; named-but-absent `references/ghost.md`;
521-line body; orphan file on disk; 140-line reference with no table of contents. Plus 2 warnings
(unknown key `frobnicate`, pronoun in description).

Fixture 2 — 6 failures, exit 1: `name` absent; `description` absent; `description` empty (whitespace
only, proving the emptiness test is not a truthiness test); `description` 1,299 chars (over 1024,
proving block-scalar folding feeds the length check); `name` 70 chars; duplicate frontmatter key.

## 8. The real run

Verified stable first: tree idle 131s before the run.

```
$ python3 /Users/zakariafatahi/50-apps-challenge/E01/tool/validate_skills.py
validate_skills.py — /Users/zakariafatahi/50-apps-challenge/E01/.claude/skills
24 skill directories

PER SKILL
  skill                               desc  body
  indelible-controls                   228   204  warn body
  indelible-design-system              371   242  warn body
  indelible-marks-and-strikes          272   249  warn body
  indelible-page-and-screens           305   201  warn body
  indelible-states-and-feedback        292   213  warn body
  shed-accessibility-and-copy          250   241  warn body
  shed-bootstrap-and-errors            259   101
  shed-code-review                     388   124
  shed-conventions                     262   142
  shed-dependencies-and-toolchain      367   161
  shed-domain                          317   120
  shed-drift-schema                    344   217  warn body
  shed-export-and-restore              246   199
  shed-goldens-rebaseline              404    97
  shed-migrations                      360   131
  shed-monetization                    172   176
  shed-platform-gateways               391   191
  shed-release                         409   185
  shed-riverpod-providers              301   217  warn body
  shed-safety-rules                    268   172
  shed-screens-and-routing             258   260  warn body
  shed-testing                         264   216  warn body
  shed-withdrawal                      263   129
  shed-write-path                      320   150

  listing budget: 7795 chars (warn 6000 / fail 8000)

WARNINGS (11)
  [WARN] indelible-controls: body is 204 lines, over the 200-line target (ceiling is 500). Consider moving detail to a reference file.
  [WARN] indelible-design-system: body is 242 lines, over the 200-line target (ceiling is 500). Consider moving detail to a reference file.
  [WARN] indelible-marks-and-strikes: body is 249 lines, over the 200-line target (ceiling is 500). Consider moving detail to a reference file.
  [WARN] indelible-page-and-screens: body is 201 lines, over the 200-line target (ceiling is 500). Consider moving detail to a reference file.
  [WARN] indelible-states-and-feedback: body is 213 lines, over the 200-line target (ceiling is 500). Consider moving detail to a reference file.
  [WARN] shed-accessibility-and-copy: body is 241 lines, over the 200-line target (ceiling is 500). Consider moving detail to a reference file.
  [WARN] shed-drift-schema: body is 217 lines, over the 200-line target (ceiling is 500). Consider moving detail to a reference file.
  [WARN] shed-riverpod-providers: body is 217 lines, over the 200-line target (ceiling is 500). Consider moving detail to a reference file.
  [WARN] shed-screens-and-routing: body is 260 lines, over the 200-line target (ceiling is 500). Consider moving detail to a reference file.
  [WARN] shed-testing: body is 216 lines, over the 200-line target (ceiling is 500). Consider moving detail to a reference file.
  [WARN] <listing budget>: names + descriptions total 7795 chars, over the 6000-char target (ceiling 8000). Headroom is thin; check `/context` before adding more skills.

SUMMARY: PASS with warnings — 24 skills, 0 failures, 11 warnings, listing 7795/8000 chars

$ echo $?
0
```

## 9. Tree verification (task item 4)

Verified independently of the checker:

- **40 files**: 24 `SKILL.md` + 16 supporting files. No others.
- **No empty directories** anywhere in the tree, including hidden ones.
- **No stray files**: every non-`SKILL.md` file sits in `references/`, `examples/` or `scripts/`.
- **No hidden entries** — no `.DS_Store`, no editor droppings. (The repo root has a `.DS_Store`; the
  skills tree does not.)
- **All 16 supporting files are named in their SKILL.md** with a load condition. Zero orphans.
- **All 24 cross-skill pointers resolve** to real skill directories.
- Sub-directory naming is uniform: 11 `references/`, 5 `examples/`, 1 `scripts/`, 9 skills flat.

## 10. Warnings left standing, and why

**Ten body-length warnings (201–260 lines).** Not fixed and not defects. The documented ceiling is
500 and every skill is under half of it. The 200-line figure is this project's own target, set just
above the ~132-line median of Anthropic's shipped skills to make growth visible. Ten of 24 sitting
just over a *target* is a signal to watch, not a queue of work — and splitting ten skills to silence
a self-imposed warning would trade real cohesion for a clean console. The threshold is right; leave
it, and let it complain.

**The listing budget warning.** Genuinely load-bearing. See §5.

## 11. Verdict

**The skill set is mechanically sound.** 24 skills, 0 failures, exit 0. Frontmatter parses, every
name matches its directory and is kebab-case and reserved-word-free, every description is present,
third-person and inside 1024 chars, no body approaches the 500-line ceiling, every supporting file
is announced and every announced file exists, every long reference carries a table of contents,
every cross-skill pointer resolves, and the tree has no empty directories or strays.

Two honest qualifications:

1. **The audit found no skill defects — it found two checker defects.** All 7 first-run failures were
   the validator's fault. That is a good outcome for the skill set and a warning about trusting a
   new checker's first red run; every one was read in context before anything was changed.
2. **The set is at ~97% of its listing budget and was measured over the ceiling during this audit.**
   That is the single real risk here, it is invisible when it bites, and it is one skill away from
   biting. Fix it by trimming the four manual-only descriptions (~760 chars, no trigger risk) or by
   raising `skillListingBudgetFraction` to `0.02`.

Because the tree was rewritten by a concurrent process throughout, **this verdict is valid as of the
run in §8 and no later.** Re-run `python3 tool/validate_skills.py` once the other work lands.
