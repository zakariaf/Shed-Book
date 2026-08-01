---
name: shed-goldens-rebaseline
description: >-
  Re-baselines Shed Book's eight golden images — loads the real bundled fonts so nothing renders in
  Ahem, runs the tolerant comparator, regenerates with make goldens-update, inspects every changed
  image by eye, and lands the new PNGs as their own commit rather than bundled with the change that
  moved them. This overwrites committed reference images, so it runs only when the developer asks for
  it by name.
disable-model-invocation: true
---

# Re-baselining the eight goldens

Manual only. You are reading this because the developer asked for it by name. It **overwrites
committed reference images** — never a step you take on your own initiative, and never to turn a red
golden green (see *Not this skill*).

`docs/engineering/12-testing.md` §8 is the policy: §8.2's table names the eight images and what each
pins, §8.4 pins the runner. Images are committed at `test/features/goldens/*.png` (`00-README.md`
§7.1), keys are relative — `matchesGoldenFile('goldens/quick_entry_default.png')` — and there is no
`test/golden/` directory (CONVENTIONS R57).

## Preconditions — all four, before you run anything

1. **The diff is intended.** A golden that moved when you did not expect it to is a bug report, not a
   chore (§8.5.1). Say which change moved which image before regenerating anything.
2. **macOS, and `fvm flutter --version` reports exactly the string in `.fvmrc`** — which is
   decision-record §5 row 1's pin; read it from the file, never from memory. Goldens are OS-, font-
   and Flutter-version-sensitive (§8.4), so re-baselining on Linux or on any other Flutter version
   rewrites all eight to bytes the pinned macOS runner then rejects.
3. **`test/flutter_test_config.dart` loads every real bundled font** — a `FontLoader` per family over
   the files actually listed in `pubspec.yaml`'s `fonts:` block, after
   `TestWidgetsFlutterBinding.ensureInitialized()` (§8.3). Without it every glyph renders as Ahem —
   solid black boxes — and these goldens exist to prove legibility, so an Ahem baseline asserts the
   opposite of its claim. `12 §8.3` writes one loader over
   `assets/fonts/AtkinsonHyperlegibleNext[wght].ttf` (decision #98, `CONVENTIONS §1`); Indelible §3.2
   needs **two** families. **That is P7's open typeface half** (`indelible-design-system`) — check
   the loader list against the pubspec before you re-baseline, because a family that ships and is not
   loaded silently re-baselines eight images in Ahem.
4. **`TolerantFileComparator` is installed** — `test/support/tolerant_comparator.dart`, one of the
   twelve closed support files (§5.3), tolerance `0.005`. Prove it the way §8.3 prescribes before
   trusting a green run: corrupt one pixel of a committed PNG → still green; corrupt 5% → red, with
   four images in `failures/`.

## The ritual — verify first, and the order is not interchangeable

```bash
make goldens          # VERIFY against the committed PNGs (12 §11.4)
# inspect test/features/failures/ — four images per failure:
#   master, test, isolated diff, masked diff
make goldens-update   # RE-BASELINE. Only after you have looked.
git status            # exactly the images you predicted, and nothing else
```

- **Look at all four failure images for every changed golden**, at size. The review question is not
  *did it change* but the one this suite exists for: **can you still read the tag number?** (§8.5.3)
- Run `make goldens-update` **through the Makefile target**, never by typing `--update-goldens`
  yourself: a `PreToolUse` hook blocks that flag outright. If a hook blocks you, stop and tell the
  developer — do not route around it.
- **Delete `test/features/failures/` before staging.** It is a CI artifact and is never committed
  (§8.4.5).

## Gotchas

- **The four diff images only exist from a verify run.** `--update-goldens` overwrites
  unconditionally and produces no comparison at all, so once you have re-baselined, the old PNG is
  gone and there is nothing left to inspect. Running `make goldens-update` first destroys the only
  evidence the review needs.
- **`--update-goldens` rewrites every image the `golden` tag selects, not only the failing ones.**
  `git status` is your whole audit: any PNG in the changed set you cannot explain stops the
  re-baseline.
- **The 0.005 tolerance means a sub-0.5% drift never turns red.** A green `make goldens` is not proof
  the baselines are current; it is proof nothing moved by more than half a percent.
- **If a diff is only a moving timestamp, that is a test bug, not a re-baseline.** Every golden is
  pumped through `pumpApp` with `atFixed` and a committed fixture (§8.1, §11.5). Fix the test.
- **Never `--update-goldens` on CI.** Regeneration is a local, reviewed act (§8.4.4), and the macOS
  golden job runs only on a `v*` tag or manual dispatch (decision #116).

## The commit

- **Its own commit, and its own PR.** `make goldens-update` is a deliberate act, never bundled with
  the change that moved the images (`00-README.md` §7.4; §8.5.4). A re-baseline mixed into a feature
  PR is a re-baseline nobody reviewed. The PR body is one line: what changed and why.
- **A Flutter version bump is its own PR too**, whose entire diff is the re-baselined PNGs plus the
  pin — `.fvmrc` and the `FLUTTER_VERSION` block in each of `ci.yml`, `release.yml`, `goldens.yml`
  (13 §1.1), which must all agree (§8.5.5).
- Commit messages use the project vocabulary (CONVENTIONS §5): *record* not entry, *warning* not flag.

## Not this skill

- **Writing, fixing or tagging a test; the golden policy** (which eight, why eight, what is
  deliberately not goldened) **and the standing `--update-goldens` prohibition** → `shed-testing`.
  The prohibition lives there because a manual-only runbook the agent cannot load prevents nothing.
- Choosing a colour, a size or a type scale → the Indelible design skills. A golden records what the
  design system decided; it never decides it.

## Definition of done

- [ ] The host is macOS on the Flutter version `.fvmrc` names, and the comparator plus **every family
      in `pubspec.yaml`'s `fonts:` block** were confirmed loaded.
- [ ] `make goldens` ran **before** `make goldens-update`, and all four failure images were opened
      for every changed golden.
- [ ] Every changed PNG in `git status` was predicted and can be explained in one sentence.
- [ ] Text is legible in every regenerated image — no Ahem boxes, tag numbers readable.
- [ ] `test/features/failures/` is deleted, and the PNGs are staged **alone** in their own commit and
      their own PR with a one-line body.
- [ ] `make goldens` is green afterwards on the same host.
