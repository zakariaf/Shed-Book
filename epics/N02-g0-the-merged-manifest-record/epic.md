# N02 — G0 — the merged-manifest record

| | |
|---|---|
| **`00-README` §9 step** | 12, run at 2 |
| **Ships in** | `v1.0.0` |
| **Depends on** | N01 |
| **Size** | S |
| **Was** | E29-T01, moved forward twenty-seven epics |
| **Branch** | `epic/n02-g0-merged-manifest` — one pull request, merged before the next epic is cut |
| **Pipelines** | `gate` · `test` |
| **Machine** | Android SDK, **JDK 17**, AGP ≥ 8.12.1, `bundletool-all.jar` on disk. No emulator, no phone |
| **Touches `lib/`** | **No.** Three documents, one archived artefact, one `README.md` paragraph, one test file |

## Goal

Build a real release `.aab`, read the merged manifest off it, and write down what it actually
says — so that `13 §2.2`'s four-row table stops reading UNVERIFIED and G1 becomes writable at all.

Decision-record §1 item 5 is one of the **five decisions that must be taken before commit #1**, and
`13 §2.2` is unambiguous about its status: *"G0 is not a CI job. It is a one-afternoon empirical
procedure that must complete before a single `tools:node="remove"` line is committed, and until it
does, the offline gate in CI is unwritten, not merely unimplemented."* Three research notes
independently hard-coded the removal of `ACCESS_NETWORK_STATE`; the only Play Billing AAR manifest
anyone could fetch was **2.0.3**, six majors behind the **8.0.0** that `in_app_purchase_android`
actually pulls in (`REFERENCES` §22 A2). Nobody has read the 8.0.0 manifest. This epic reads it.

## Why it sits at position 2 and not at position 12

`00-README` §9 puts G0 in step 12 with the size and startup measurements, and its stated reason is
*"the measurements need a real device and a real release build, which do not exist until now."* That
reasoning splits cleanly, and the plan critique (§2, §9 change 1) splits it:

- the **measurements** genuinely need a real device — they stay at step 12 and land in N34;
- the **merged manifest** needs only a release build, and a release build needs only an `android/`
  folder (N00-T01) and `in_app_purchase` in the pubspec (N00-T03). Both exist by the end of N01.

The merged manifest is a Gradle-time artefact of the **dependency set**, not of the Dart code: every
plugin in `pubspec.yaml` contributes its manifest whether or not a single line of `lib/` imports it.
That is precisely why this epic can run with no `lib/` at all — and why running it later buys nothing.

What lateness costs, in the critique's words: if billing 8.0.0 contributes `ACCESS_NETWORK_STATE`,
the Play listing will show *"view network connections"*, which changes the store-listing honesty
paragraph, the About screen (N29-T07) and the Export screen wording (N21). Discovering that at N31
means re-opening copy in three merged epics. Running it here costs an afternoon.

## Entry conditions

Everything below is already merged on `main` before this branch is cut. Check them, because a
missing one turns the afternoon into a day:

| Needs | From | Why |
|---|---|---|
| `android/` exists, application id fixed | N00-T01 | there is nothing to build otherwise |
| `in_app_purchase` in `pubspec.yaml`, `pubspec.lock` committed | N00-T03 | billing's AAR is the whole question |
| `.fvmrc` pins 3.44.8 | N00-T01 | a different SDK is a different merge |
| `.gitignore` from `00-README` §7.2 | N01-T01 | it decides where the archived report may live — see N02-T01 §5 |
| `.github/pull_request_template.md` | N01-T07 | the five §12 questions are answered in this PR body |
| `gate` and `test` jobs | N01-T06 | the two pipelines this epic runs |

## Sources

| Document | Section | What it binds |
|---|---|---|
| `docs/engineering/13-build-ci-release.md` | §2.2 | G0's procedure verbatim, and the four-row table this epic replaces |
| `docs/engineering/13-build-ci-release.md` | §2.1, §2.3, §3.1 | the only permitted public wording, what G1 will assert, and the `minSdk` rule |
| `docs/research/00-tech-decisions.md` | §1 #5, §3.1–§3.4 | decision #5, the claimable tiers, the gates, the eight-entry set, the build-hook exception |
| `docs/engineering/11-monetization-and-store.md` | §3.1, §3.2 | what each layer contributes to the manifest, and the second place the answer is recorded |
| `docs/engineering/REFERENCES.md` | §22 A2, B19, B20, D8, §22.H | the four unverified claims one build closes, ranked first of five |
| `CLAUDE.md` | offline purity | the permitted wording, verbatim, and the phrases banned from our own prose |

## Tasks

| Task | Depends on | One line |
|---|---|---|
| [N02-T01](N02-T01-run-g0-against-a-real-release-aab-and-record-what-it-says.md) | outside this epic | Run G0 against a real release AAB and record what it says |
| [N02-T02](N02-T02-the-ruling-g0-produces-and-the-honesty-paragraph-it-may-forc.md) | N02-T01 | The ruling G0 produces, and the honesty paragraph it may force |
| [N02-T03](N02-T03-g0-recorded-testdart-the-guard-on-toolsnode-remove.md) | N02-T02 | `g0_recorded_test.dart` — the guard on `tools:node="remove"` |

The order is not cosmetic. T01 produces evidence, T02 rules on it, T03 makes the ruling
enforceable. Running T03 first would produce a guard that passes because there is nothing to guard.

## Demoable on merge

Things you can run, see or show someone, none of which was true before this branch:

1. `docs/gates/manifest-merger-release-report.txt` is in the repository — the merger's own decision
   tree, copied byte-for-byte out of `build/`, naming which library contributed which permission.
2. `13 §2.2`'s four-row table has **no cell reading UNVERIFIED and no cell reading *not yet run***,
   and each row carries an ISO date in its *Recorded on* column.
3. The permission set in decision-record §3.3 is the set a real `.aab` declares, each line naming its
   contributing library — including `flutter_image_compress`, whose contribution `REFERENCES` §22 D8
   records as never having been verified at all.
4. The effective `minSdk` is a read number, not `13 §3.1`'s remembered 24.
5. `README.md` names which of `pub get`, `gen`, `test` and `build` first needs the network on a cold
   cache (`REFERENCES` §22 B20), so the first plane-mode build failure is not mistaken for a regression.
6. `fvm flutter test test/policy/g0_recorded_test.dart` is green — and you can demonstrate it going
   red by planting a `tools:node="remove"` line while the table is reverted.
7. `docs/store/offline-honesty.md` exists and holds the one paragraph N21, N29-T07 and N32-T02 quote
   rather than re-type.

## The pull request workflow

Concretely, in order. Nothing here is optional and nothing here is parallel.

1. **Cut the branch from the merged `main`** — the one carrying N01's merge, never from N01's branch:
   `git switch main && git pull && git switch -c epic/n02-g0-merged-manifest`.
2. **Three commits, one per task**, in task order, with the message the task file names. Before each
   commit: **`/simplify`**, then **`/code-review`**, then **`/shed-code-review`** — that order, every
   task, no exceptions.
3. **`/shed-code-review` once more over the whole branch**, read in order of irreversibility. For
   this epic that order is not `00-README` §10's layer order (this branch reaches no layer): it is
   `docs/research/00-tech-decisions.md` first because it outranks everything and is marked FINAL,
   then `docs/engineering/13-build-ci-release.md`, then `docs/store/offline-honesty.md` because it is
   public copy, then the archived report, then `README.md`, then the test.
4. **Push and open the PR.** `git push -u origin epic/n02-g0-merged-manifest`, then `gh pr create`.
5. **Answer the five §12 questions in the PR body**, from the template N01-T07 committed. Four of the
   five are genuinely not reached by this branch — say so rather than ticking them. The fifth, §12.3
   *never present the app as a regulatory record*, **is** reached: `docs/store/offline-honesty.md` is
   copy about what the app is and is not, and the store listing is outside `tool/check_policy.dart`'s
   reach forever (`13 §12` item 9 — *"you are the gate"*).
6. **Record in the PR body what CI cannot reproduce.** No job in this epic builds an `.aab`: the
   `android` job arrives at N31-T03. So the PR body names the machine, the Flutter version, the AGP
   version, the `bundletool` version and the date the build ran. Without that, the archived report is
   evidence of nothing in particular.
7. **Wait for the pipelines.** Two run:
   - **`gate`** — the toolchain pin agrees with `.fvmrc`, `flutter pub get` resolves, `dart format
     --set-exit-if-changed`, `flutter analyze --fatal-infos --fatal-warnings`, and
     `ios/Runner/Info.plist` carries no `NSAppTransportSecurity`. **`tool/check_policy.dart` is not
     in this job yet** — N01-T06 leaves the slot for it and N03-T07 fills it — so G2 and G3 prove
     nothing on this branch. The offline claim here rests on an artefact you read by hand.
     Locally, `make check` adds `python3 tool/validate_epics.py`, which is what keeps a
     documents-only branch's check non-vacuous: it re-parses these very task files.
   - **`test`** — `-P ci-fast` with randomised ordering, `TZ=Europe/London --tags uk-zone`, and
     `TZ=Pacific/Chatham test/domain --exclude-tags uk-zone`. On this branch it is proving
     `test/policy/g0_recorded_test.dart` and `test/policy/offline_wording_test.dart`. Nothing in this
     epic is time-shaped, so it adds no `test/domain/uk_zone/` case; the first of those lands at N04.
8. **Merge, preserving the three commits** — rebase or a merge commit, never a squash. The three
   commits are the record of the procedure: evidence, ruling, guard.
9. **Delete the branch**, confirm `main` is green after the merge, and only then cut N03's branch
   from the merged `main`.

## Risks, and what is irreversible

**The loud one first. The line this epic must not commit.** No `tools:node="remove"` may be written
into any manifest on this branch. That line is N31-T01's, and it is the one line which — if the
evidence behind it is wrong — makes the product's central public claim false **in a shipped binary**,
discovered by a shepherd whose purchase flow misbehaves on a flaky connection. T01 has to write it
temporarily to answer `REFERENCES` §22 B19; it is reverted before the commit, and `git diff --cached`
is what proves it.

**What is irreversible here is a claim, not a file.** Nothing on this branch is a schema snapshot, a
native file or a published artefact. Two things still do not come back cleanly:

- `docs/store/offline-honesty.md` becomes a **public** store listing and an About screen paragraph.
  Correcting published copy is a store update, in public, and both stores keep the old version.
- `docs/research/00-tech-decisions.md` is dated and marked **FINAL**. Amending §3.3 fires the
  amendment rule: strike the superseded line **with its reason**, never rewrite it quietly, and
  update every document that names decision #5 *in the same commit* — `13 §2.2`, `11 §3.1`/§3.2,
  `08 §11` items 7, 13 and 14, `REFERENCES` §22 A2/B19/D8 and `CODE-REVIEW-CHECKLIST`. Half a
  fan-out leaves two authoritative documents disagreeing, which is worse than no record.

| Risk | Why it bites | What to do |
|---|---|---|
| The machine has no Android toolchain or no JDK 17 | The epics are strictly sequential; this one blocks all thirty-two after it | Check before cutting the branch, not after |
| The plane-mode observation is done **after** the online build | The `sqlite3` build-hook artefact is cached; a warm laptop builds in plane mode and you record a wrong answer | Do the cold-cache sweep first, or `flutter clean` and clear the pub cache before it |
| `bundletool` is fetched as `latest` in CI | `13 §2.3` carries this as unverified: the gate's tool floats | Record the exact version you used in the PR body; pin only if the dump format ever moves |
| Billing 8.0.0 contributes something nobody listed | The eight-entry set grows, and the store's permission list with it | Record it, do not remove it, and let T02 rule on it |
| The evidence goes stale | G0's record describes one dependency set; the next `pub add` invalidates it | That is exactly what G1 (N31-T03) exists to catch on every push |

## Definition of Done

- [ ] every task above is merged on this branch, one commit each unless the task file states the exception
- [ ] every task ran `/simplify`, then `/code-review`, then `/shed-code-review`, before its commit
- [ ] `/shed-code-review` run once more over the **whole branch**, in irreversibility order, before the PR opens
- [ ] the five §12 questions in `.github/pull_request_template.md` are answered in the PR body
- [ ] the pipelines are green: `gate` · `test`
- [ ] `main` is green after the merge, and the next epic's branch is cut from the merged `main`
- [ ] `13 §2.2`'s table has four filled rows, each with an ISO date, and the words UNVERIFIED and *not yet run* appear nowhere in it
- [ ] the recorded permission set is identical in `13 §2.2` and decision-record §3.3, and every entry names its contributing library
- [ ] the merger report is committed and is not swallowed by an ignore rule — `git check-ignore -v <path>` finds nothing
- [ ] no `tools:node="remove"` line exists anywhere under `android/` on this branch
- [ ] `REFERENCES` §22 A2, B19, B20 and D8 are each struck or updated with the answer this epic produced

## Notes

This epic exists because the old plan scheduled G0 at epic 29 of 31. `REFERENCES` §22.H ranks it
**first of the five things to run if only one afternoon is available**, because it closes A2, B19 and
most of D8 at once and unblocks the offline gate. It needs only `in_app_purchase` in the pubspec
(N00-T03) and an `android/` folder (N00-T01), both of which exist.
