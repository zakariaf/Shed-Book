# N03 — The gate

| | |
|---|---|
| **`00-README` §9 step** | 1 |
| **Depends on** | N02 |
| **Size** | L |
| **Was** | E02, with the two `copy.*` content rules deferred to N06-T09 |
| **Branch** | `epic/n03-the-gate` — one pull request, merged before the next epic is cut |
| **Pipelines** | `gate` · `test` |

## Goal

One script, one rule table, one allowlist, one exit code — the layer rules, the network scan
(G3), the dependency allowlist (G2), the design rules and the vocabulary rules. Every rule is proved
by the task that adds it, not by one thirty-cycle task at the end.

## Why it sits here

`00-README` §9 puts this in step 1, and gives two reasons that are not about tidiness:

> "A gate is cheap on an empty tree and impossible to retrofit across twelve screens. A rule nobody
> has seen fire is indistinguishable from a broken rule."

Both are load-bearing. The first is arithmetic: `layer.sibling` on an empty `lib/features/` costs
one commit; the same rule introduced after nine feature folders exist is a refactor of every screen
that took the easy import. The second is why `00-PLAN-CRITIQUE` §3 re-cut E02 — the old plan proved
thirty rules in one closing task, which is *"thirty commits pretending to be one"*. Here each rule is
planted, watched to fire and un-planted inside the commit that adds it.

Two dependencies make this epic possible now and not earlier. `pubspec.lock` is committed (N00-T03,
decision #5), so G2 has a real lockfile to read on a fresh clone. `.github/workflows/ci.yml` and the
`Makefile` already name `dart run tool/check_policy.dart` (N01-T05, N01-T06) — this epic is what
makes that line succeed, which is why N01 and N02 leave the `gate` job's policy step red and N03-T01
is the commit that turns it green.

Everything after this epic is written *inside* the gate. N04's `lib/domain/` cannot import
`package:clock` because `layer.domain` lands here; N07's schema cannot say `customStatement(` outside
`lib/core/db/` because `db.raw_statement` lands here; N09's widgets cannot hold a hex because
`token.raw_color` lands here.

## Sources

| Document | Section | What it binds |
|---|---|---|
| `docs/engineering/01-architecture.md` | §3.1, §3.2, §3.3 | the eight layer rules, the printed driver, the allowlist format, how it runs |
| `docs/engineering/CONVENTIONS.md` | §1, §1.1, §4.7, §5.1–§5.3 | the tree, the amended layer table, the rule-id grammar, the vocabulary |
| `docs/engineering/06-design-system.md` | §3.5 | the `_bannedPattern` table — tokens, themes, typography, the gesture ban |
| `docs/engineering/02-state-di-navigation.md` | §2.4 | the Riverpod-3 rows, which 13 §2.5 counts at thirteen |
| `docs/engineering/13-build-ci-release.md` | §2.4, §2.5, §2.8, §4.3 | G2, G3, the gate table, the `gate` job's step order |
| `docs/research/00-tech-decisions.md` | §3.2, §3.4, §5.1–§5.2 | the gates, why a *"no `http` in `pubspec.lock`"* rule is unsatisfiable, the allowlist's contents |
| `CLAUDE.md` | the four non-negotiables, the vocabulary table | the banned words and the two files that may never be edited to green a build |

## Tasks

| Task | Depends on | One line |
|---|---|---|
| [N03-T01](N03-T01-the-gate-skeleton-the-rule-table-the-walk-the-allowlist.md) | the merged N02 branch | The gate skeleton — the rule table, the walk, the allowlist |
| [N03-T02](N03-T02-the-layer-rules.md) | T01 | The layer rules |
| [N03-T03](N03-T03-the-net-rules-g3.md) | T02 | The `net.*` rules — G3 |
| [N03-T04](N03-T04-g2-the-direct-dependency-allowlist-over-pubspeclock.md) | T03 | G2 — the direct-dependency allowlist over `pubspec.lock` |
| [N03-T05](N03-T05-the-design-rules.md) | T04 | The design rules |
| [N03-T06](N03-T06-the-time-db-rp3-and-vocabulary-rules.md) | T05 | The `time`, `db`, `rp3` and vocabulary rules |
| [N03-T07](N03-T07-wire-the-gate-into-ci-and-assert-the-rule-inventory-is-compl.md) | T06 | Wire the gate into CI and assert the rule inventory is complete |

The chain is strictly linear because every task after the first adds rows to the same two tables in
the same file and a proving case to the same test file. Two of them in parallel is a merge conflict
in `tool/check_policy.dart` and a silently dropped rule. Each task file's header names its own
predecessor precisely.

## The pull request, concretely

1. **Cut the branch from the merged `main`** that carries N02:
   `git switch main && git pull && git switch -c epic/n03-the-gate`.
2. **One commit per task**, in T01…T07 order, each with the commit line its task file names. No task
   here has an exception. Two commits need their reason in the message body rather than the subject:
   T01, because it adds the four day-one `[exempt]` lines and `00-README` §7.4 requires the reason for
   an exempt line to live in the commit that adds it; and T04, because it authors the file
   `CLAUDE.md` forbids editing to make a build pass.
3. **Every commit runs `/simplify`, then `/code-review`, then `/shed-code-review` before it is made**,
   and leaves `make check` and `make test` green. A commit that leaves the branch red is a commit that
   makes the next task's red-first step unreadable.
4. **Open the PR** and answer the five §12 questions in `.github/pull_request_template.md` in the body.
   For this epic four of the five are answered *"no code path reaches this rule yet"* and §12.4 is
   answered by `layer.data_no_validation`, which is the epic's one direct safety mechanism.
5. **Wait for the pipelines. Do not merge on a local green.** Two jobs run on this branch:

   | Job | What runs | What it proves for this epic |
   |---|---|---|
   | `gate` | toolchain pin equals `.fvmrc` · `flutter pub get` · `dart run tool/check_policy.dart` · `dart format --output=none --set-exit-if-changed .` · `flutter analyze --fatal-infos --fatal-warnings` · the `NSAppTransportSecurity` text check | The gate runs on a machine that is not yours, from a clean checkout, against the committed `pubspec.lock`. **G2 and G3 both live in this one step**, so a green `gate` is the epic's product working, not a proxy for it |
   | `test` | `flutter test -P ci-fast --test-randomize-ordering-seed random --coverage` · `TZ=Europe/London flutter test --tags uk-zone` · `TZ=Pacific/Chatham flutter test test/domain --exclude-tags uk-zone` | Every rule in the table has a case that watches it fire. The randomised ordering is what proves the planted-violation cases do not leak temp directories into each other. The two zone commands pass trivially here — `test/domain/` does not exist until N04 — and that is expected, not a skipped job |

   `codegen` (N08) and `android` (N31) do not exist yet, so this epic's PR shows two checks, not four.
6. **Merge**, then **delete the branch** (`git push origin --delete epic/n03-the-gate`), then confirm
   `main` is green after the merge commit.
7. **Only then cut `epic/n04-domain-time-and-units` from the merged `main`.** N04's first commit adds
   `lib/domain/time/instant.dart`, and the whole point of the ordering is that it lands inside a gate
   that already refuses `package:clock` there.

## Risks, and what is irreversible

**Nothing here writes a schema snapshot, a native file or a published artefact.** The irreversibility
in this epic is of a different kind and it is real:

- **A `[exempt]` line deletes one rule for one file, forever, and silently.** R56 fixes the day-one
  count at **four** and `00-README` §7.4 makes each one carry its reason in the commit message.
  **A fifth is a review conversation, not a keystroke.** `CLAUDE.md`: never add a line to
  `tool/policy_allowlist.txt` to silence a gate; if a gate is genuinely wrong, say so and stop.
- **Rule ids are a naming surface with no migration path.** Every `[exempt]` line is keyed
  `'<path> :: <id>'`; every later epic's Definition of Done names ids; commit messages quote them.
  Renaming a shipped id orphans every allowlist line keyed to it, silently — the lookup simply stops
  matching and the exemption evaporates. So the ids must be **`CONVENTIONS` §4.7's from the first
  commit**: dotted `namespace.name`, `lower_snake`, namespace drawn from `layer`, `net`, `time`,
  `rp3`, `stream`, `db`, `stat`, `a11y`, `gesture`, `token`, `theme`, `type`, `ui`, `main`, `dep`,
  `launch`, `copy`. Several task titles in this epic use plan shorthand (`design.raw_hex`,
  `time.wall_clock`, `db.custom_statement`) that §4.7 does not admit; each task file says which
  canonical id it means.
- **A rule that is too broad is worse than no rule**, because the first person to meet its false
  positive weakens it and nobody looks again (01 §3.3). The three known traps are a bare `sync`, a
  bare `Uri.parse(` and a bare `strftime`/`datetime`; decision #47 already excludes the last pair for
  exactly this reason.
- **A *"no `http` in `pubspec.lock`"* rule is unsatisfiable and must never be written.** `http 1.6.0`
  sits on two regular edges — `flutter_local_notifications → timezone → http` and
  `wakelock_plus → package_info_plus → http` — so the rule is permanently red and gets deleted by
  whoever meets it. Four research notes wrote it. Decision-record §3.4 #1 records why it is banned;
  N03-T03 puts that reason in the source, not only in a document.
- **The gate walks `test/` as well as `lib/`**, so a proving case that pastes a banned literal into
  `test/policy/gate_rules_test.dart` can trip the gate on itself. Most rows are scoped `lib/` and
  cannot; the rows scoped to both roots can. T06 states the two ways out and neither is a fifth
  exempt line.
- **`tool/` is deliberately never walked** — the script's own tables contain every banned literal, so
  scanning it would fail the build on itself. Do not "fix" that, and do not add a second scanning
  script (decision #10): the answer to a new rule is a new row.
- **The rule table is not closed at N03** (see Notes). A reader who thinks it is will "tidy" the two
  missing `copy.*` rows into existence with a literal allowlist, which is the mechanism 12 §10
  explicitly rejects.

## Definition of Done

- [ ] every task above is merged on this branch, one commit each unless the task file states the exception
- [ ] every task ran `/simplify`, then `/code-review`, then `/shed-code-review`, before its commit
- [ ] `/shed-code-review` run once more over the **whole branch**, in irreversibility order, before the PR opens
- [ ] the five §12 questions in `.github/pull_request_template.md` are answered in the PR body
- [ ] the pipelines are green: `gate` · `test`
- [ ] `main` is green after the merge, and the next epic's branch is cut from the merged `main`
- [ ] `dart run tool/check_policy.dart` exits **0** on the tree and **1** on every planted violation, naming the rule id
- [ ] `tool/policy_allowlist.txt` has exactly **four** `[exempt]` lines (R56) and each has its reason in the commit that added it
- [ ] every rule id in the table has a proving case, and the inventory assertion in `test/policy/gate_rules_test.dart` holds that true for the next epic as well

## Demoable on merge

`dart run tool/check_policy.dart` exits 0 on the tree; plant any violation and it exits 1
naming the rule id. Every rule in the table has been watched to fire in the commit that added it.

Two runnable demonstrations, in order:

```bash
dart run tool/check_policy.dart ; echo "exit=$?"      # policy ok, exit=0

mkdir -p lib/features/flock
printf "import 'package:drift/drift.dart';\n" > lib/features/flock/_plant.dart
dart run tool/check_policy.dart ; echo "exit=$?"      # POLICY [layer.features] …, exit=1
rm lib/features/flock/_plant.dart
```

## Notes

**The rule table is not closed at N03.** `copy.vet_advice` and `copy.disclaimer_retyped` need
`ContentPolicy` and `Disclaimers`, which are N06-T09; their rows land in that commit. Say this out
loud in the script's header comment so the next reader does not think the table is complete.

Two other rows arrive later for the same reason — the type they assert on does not exist yet:
`db.destructive_ddl` and its four siblings from `CONVENTIONS` §4.7's rename table land with the
migration harness (N08), and `layer.in_app_purchase` / `launch.store_call` land with monetization
(N30). None of them changes the driver; each is a row and a proving case, added together, which is
what N03-T07's inventory assertion is for.
