# N32-T03 — Open the closed track and TestFlight — the fourteen-day clock starts

| | |
|---|---|
| **Epic** | [N32 — Signing and the closed track opens](epic.md) · `00-README` §9 step 12 (2 of 3) |
| **Task** | 3 of 3 |
| **Depends on** | N32-T02 |
| **Commit** | one commit · `chore(release): open the closed track and TestFlight` |

## 1. Why this task exists

The first signed AAB reaches a Play closed track with the twelve testers recruited in
N00-T07, and the iOS build reaches TestFlight. **The fourteen-day clock starts here, not at the end** —
which is the whole reason this epic sits before the sweeps.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/13-build-ci-release.md` | §10.2 | the 12-tester / 14-day rule, its exemptions, and *"start the closed test during the build, not after it"* |
| `docs/engineering/13-build-ci-release.md` | §10.1, §10.3 | TestFlight internal versus external, and which purchase loops need which account to exist |
| `docs/engineering/13-build-ci-release.md` | §9.1, §9.1.1, §9.4 | build name from the tag, build number from the run number, the two `--dart-define`s, and the symbols archive |
| `docs/engineering/13-build-ci-release.md` | §2.3, §6.1.1, §11 | G1 on the artefact you upload, the one tracked size number that only exists after upload, and the seasonal freeze |
| `docs/engineering/11-monetization-and-store.md` | §11, §4.2 | license testing, the three offline purchase paths, and the entitlement that is never revoked |
| `docs/research/00-tech-decisions.md` | §7.1 items 1 and 14, §2 #88 | the field night and the account question, and why a refund is not a code path |
| `epics/00-PLAN-CRITIQUE.md` | §2, §10 change 16, §11.5 | the seven commitments by name, why this epic moved in front of N33, and *"fourteen days of dead calendar at the end of the project"* |
| N00-T06 (this backlog) | §5, §6 | the ledger's shape, the `complete` rule, and the instruction that a row is never deleted to make a test pass |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-release` | runbook, invoked by name — the tracks and their requirements |
| `shed-monetization` | the closed test is also the first real purchase test |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/policy/calendar_commitments_test.dart`
- **Test** — `'the twelve-tester row records the date the closed track opened'`
- **Why it is red today** — the ledger row has a tester count and no start date, so the clock has not started.

```bash
fvm flutter test test/policy/calendar_commitments_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — upload, invite the twelve testers, and record the date in the ledger.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

This is the task that closes the loop N00-T06 opened. That file's Definition of Done says it plainly:
*"the test is red at the end of this task, deliberately, and each of T07–T09 turns one row green."*
This is the last one. Add the case beside T06's anchor and T07–T09's six; do not write a second
parser, and do not touch the ~25-line Markdown table reader — it has held six rows for thirty-one
epics.

## 5. What you build

Three files, two uploads, one archive that never enters git, and about forty minutes of waiting for
two review queues. Nothing here is `lib/`. Everything here is irreversible in some small way.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `docs/calendar.md` — `twelve_testers` | Owner, the **Recorded** ISO date the track went live, and an outcome cell carrying: the opted-in count, the track name, and the civil date the fourteen continuous days complete — **written, never computed** (§5.4) |
| 2 | `test/policy/calendar_commitments_test.dart` | The anchor plus two cases, beside the existing six. `@Tags(['calendar'])` is already at the top of the file, above the imports, and stays there |
| 3 | `RELEASES.md` | A row for a build that has **no tag**: build number, the Android and iOS upload dates, the arm64 download size once Play shows it, and a Notes cell saying *closed test, hand-built, untagged* and listing every build number this epic consumed |
| 4 | `symbols-archive/<name>+<build>/{android,ios}/` | **Not in git** (`00-README` §7.2). Copied off the laptop the same day. A tester's crash log from an obfuscated build is unreadable without exactly these files, and `flutter symbolize`'s read path must agree with where you put them (`13 §8.4`) |

No new ledger row. N00-T06's `'the ledger carries exactly the seven commitments the critique names'`
asserts set equality; a `closed_track` row of its own turns it red.

### 5.1 The two builds, with every flag that matters

```bash
# Android — the artefact that goes on the closed track.
fvm flutter build appbundle --release \
  --build-name=0.9.0 --build-number=1 \
  --dart-define=APP_VERSION=0.9.0 --dart-define=APP_BUILD=1 \
  --obfuscate --split-debug-info=build/symbols/android

# iOS — the same numbers, on the Mac, per 13 §9.1.
fvm flutter build ipa --release \
  --build-name=0.9.0 --build-number=1 \
  --dart-define=APP_VERSION=0.9.0 --dart-define=APP_BUILD=1 \
  --obfuscate --split-debug-info=build/symbols/ios
```

**The build name is chosen by hand here, and this is the only build in the project's life where that
is true.** `13 §9.1` rule 2 says the build name comes from the tag, always — and there is no tag,
because `release.yml` does not exist until N34-T01 and `13 §9.1` rule 4 reserves store uploads for its
artefact. Both statements cannot hold at once for a closed test that must start now. The resolution is
not to reinterpret the rule: it is to **record the deviation in the PR body and in `RELEASES.md`'s
Notes**, name the numbers consumed, and hand N34-T01 the collision described in §5.4.

**Both `--dart-define`s are the point of the exercise, not decoration.** `13 §9.1.1`: there is no
package in the graph that can tell the running app its own version, so `kAppVersion` and `kAppBuild`
are compiled in. A closed-test build without them writes `0.0.0+0` into every diagnostics log
(`13 §7.2`, §8.3) — and those logs are the **only** feedback channel this product has, because there
is no crash reporter and never will be (`13 §8.1`). Twelve shepherds sending you unreadable logs for
fourteen days is the most expensive way available to waste this epic.

Before either upload, run G1 by hand on the artefact you are about to upload — not on a rebuild, not
on the AAB the `android` job made from a different commit:

```bash
bash tool/assert_permissions.sh build/app/outputs/bundle/release/app-release.aab
```

`13 §12` item 1: *"Do not just trust that G1 was green — read the seven `uses-permission` lines, and
confirm `INTERNET` is not the eighth."*

### 5.2 Play — the closed track

Play Console ▸ **Testing ▸ Closed testing**. The order below is the order the console enforces, and
each step blocks the next:

1. **License testing first, and it is account-level, not app-level.** Play Console ▸ Settings ▸
   License testing: add all twelve tester email addresses. `11 §11` states the consequence of
   skipping it in one line — *"the tester must also be opted into a test track or they are charged for
   real."* A tester who taps Unlock without being a license tester pays real money, and decision #88
   means **the entitlement is never revoked**, so a refund does not un-buy it. Do this before the
   track goes live, not after the first message.
2. **Create the track** (the default *Alpha* is a closed track) and attach a **tester list** — email
   addresses or a Google Group. The list is not the clock. Play counts **opted-in** testers.
3. **Create a release**, upload the AAB, paste the release notes from `docs/store/listing-play.md`
   (≤ 500 characters, en-GB), then *Review release* and *Start rollout*.
4. **Send the opt-in URL** to all twelve and confirm each one has opened it and accepted. The count in
   Play Console is the only count that exists; your spreadsheet is not evidence.
5. **Activate the unlock product.** `shed_book_unlock` was created at N00-T09; a managed product left
   **inactive** returns *item unavailable* from the billing flow, which reads exactly like a bug in
   `PurchaseService` and is not one.
6. **Read the arm64-v8a download size** in App Bundle Explorer once the bundle is processed. `13
   §6.1.1` calls this *"the one tracked number"*, and this is the first moment in the project it
   exists. Put it in `RELEASES.md`'s row. It is **not** a row in `docs/perf/measurements.md` — that
   file's first row belongs to the first release and to N34-T03's device measurements.

### 5.3 Apple — the record and TestFlight

The App Store Connect **app record is created here**, not in T02: T02's title scopes it to Play, and
TestFlight cannot accept a build without a record. Bundle id from `RELEASES.md`'s header, SKU
recorded in `docs/calendar.md`'s `store_identifiers` outcome cell.

Then upload — Transporter, or `13 §9.1`'s command:

```bash
xcrun altool --upload-app --type ios -f build/ios/ipa/*.ipa \
  --apiKey "$ASC_KEY_ID" --apiIssuer "$ASC_ISSUER_ID"
```

Two choices, and `13 §10.1` makes both explicit:

- **Internal testing** — up to 100 members of your own team, **no App Review**, instant. The right
  loop for the developer and for anyone with an Apple Account you control.
- **External testing** — up to 10,000 testers, **requires a TestFlight review**. This is how real
  shepherds get on it, and it is a queue: budget a day, not an hour, and do not schedule it for the
  afternoon the Play track opens.

Expect the **export-compliance** question on every upload. The app uses no non-exempt encryption, so
the answer is no. Answering it in App Store Connect each time is free; suppressing it with
`ITSAppUsesNonExemptEncryption` in `Info.plist` is a change to `13 §3.2`'s key table, which is
N31-T04's file and an amendment, not a convenience. Answer the question.

### 5.4 The details that are easy to get wrong

- **Build numbers are spent forever, and `release.yml` will collide with these.** Both stores reject a
  re-used build number, including one burned by an upload that was later deleted, replaced or
  expired. `13 §9.1` rule 3 makes the build number `release.yml`'s `github.run_number` — a counter
  that is **per workflow file** and starts at **1**. If this task uploads build 1 and 2 by hand, then
  N34's first two tagged releases produce 1 and 2 and both uploads are rejected. Play also requires
  each new version code to be **higher** than the last, so a large hand-picked number is worse, not
  safer: it puts `release.yml`'s whole early sequence below the floor. **Consume as few numbers as
  possible — one per platform if you can — start at 1, list every number consumed in `RELEASES.md`,
  and say so in the PR body.** The decision about how N34 climbs past them is N34-T01's, and it is
  cheap to make in advance and expensive to discover on a release day.
- **Twelve *opted-in*, for fourteen *continuous* days.** `13 §10.2`, and every word of it is load
  bearing. Invited is not opted in. Eleven is not eleven-twelfths of a clock. The count is assessed
  daily, so a tester who opts out on day nine can cost the window — tell the twelve, in writing, that
  they must stay opted in and keep the app installed until you say otherwise. And the fourteen days
  buy you the *right to apply* for production access; the application itself is another review.
- **Play counts days, not hours — so do not compute the end date.** Write the completion date into the
  ledger as a civil date. If anybody ever computes it, the trap is decision #3's, one epic wider: a
  fourteen-day span that crosses UK spring-forward is **335 hours in absolute time, not 336**, exactly
  as `05 §3` measured seven days at 167 h. `docs/calendar.md`'s dates are civil dates in a document
  and N00-T06's `'the test reads no clock'` case forbids a clock read in this file — if a genuine
  interval assertion is ever wanted it takes `withClock` and a case at **01:30 on the clocks-back
  night** in `test/domain/uk_zone/`, never `DateTime.now()`.
- **The freeze does not bind a closed track, but the calendar does.** `13 §11`'s 1 February – 30 April
  window governs shipping an update to customers, and a closed test has none. `13 §10.2`'s second
  constraint is the one that binds: *"those fourteen days must not land inside the seasonal freeze if
  the plan is to ship immediately afterwards."* Count the days forward before you press *Start
  rollout*.
- **The ledger may still be red when this task is done, and that is information, not a failure.**
  N00-T09 records that the two remaining halves are `field_night`'s outcome and `twelve_testers`'
  opt-in count. This task closes the second. If the field night has not happened, the ledger stays red
  on a commitment whose due date was **before N13** — and N00-T06's rule holds without exception:
  *"A row is never deleted to make the test pass."* Neither is a cell invented. A red `field_night` row
  in this PR is the project telling the truth about itself.
- **Check whether CI has been running this test all along.** N00-T06 states the ledger test is kept
  out of the blocking set by its `calendar` tag; N01-T04's `ci-fast` preset as written excludes
  `golden` only. Both cannot be true. If `calendar` is not excluded, `make test` and the `test` job
  have been red since N00 and this commit is what makes them green; if it is excluded, the anchor is
  not run by `make test` at all and you must run it by tag. Find out which before you write the PR
  body — and now that N01-T04 has declared the tag, `--tags calendar` finally selects something
  instead of matching nothing (`12 §11.2`).
- **Archive the symbols the same day.** These builds ship `--obfuscate`, and `13 §9.4` calls the
  symbols *"the only artefact whose loss cannot be recovered by rebuilding."* N34-T02 formalises the
  archive; the first stack trace from a shepherd will arrive long before N34 does.
- **The `.storekit` loop is not what is being tested here.** `13 §10.3`: the local StoreKit
  configuration works fully offline and needed no account, which is why it ran at N30. What starts
  here is the first purchase test that involves a real store — and `11 §11`'s three untested paths
  (Unlock in airplane mode, Restore in airplane mode, buy on A and install on B with no signal) are
  release-checklist items to run on a real device, not CI, and not this commit.
- **Do not tag anything.** `git tag v*` triggers `release.yml`, which does not exist yet, and a tag is
  the mechanism `13 §9.1` reserves for a release. This epic uploads; it does not release.

### 5.5 The full test set

| File | Case | What it catches |
|---|---|---|
| `test/policy/calendar_commitments_test.dart` | `'the twelve-tester row records the date the closed track opened'` | the anchor; the clock claimed but not dated |
| `test/policy/calendar_commitments_test.dart` | `'the twelve-tester outcome records an opt-in count of at least twelve'` | eleven testers and a start date — a window that will not qualify, recorded as if it will |
| `test/policy/calendar_commitments_test.dart` | `'the fourteen-day completion date is an ISO civil date, written and not derived'` | a computed end date, and with it the DST hour and the clock read this file has banned since N00-T06 |
| `test/policy/calendar_commitments_test.dart` | *existing* — `'every commitment in docs/calendar.md has an owner, a date and an outcome'` | the whole ledger; green here for the first time, or red on `field_night` and honestly so |
| `test/policy/calendar_commitments_test.dart` | *existing* — `'the ledger carries exactly the seven commitments the critique names'` | an eighth `closed_track` row added out of enthusiasm |
| `test/policy/calendar_commitments_test.dart` | *existing* — `'the test reads no clock'` | a recency assertion added here, which would change verdict at midnight and be ambiguous for an hour once a year |

No `test/domain/uk_zone/` case is added. Nothing in this task computes, stores or formats an instant —
the dates are civil dates in a document, and the case above exists to keep it that way. The ambiguous
**01:00–01:59** hour is named in the third case's reason precisely so the next person to reach for
`Duration(days: 14)` reads why not.

## 6. Constraints that bind this task

- **Offline** — no network path may be added. G2 (the dependency allowlist) and G3 (the import scan) stay green, and the permission set never changes without G0's recorded evidence.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.
- **Gate integrity.** G1 runs on the artefact that is uploaded. If it goes red, the finding is what changed and where — `android/expected_permissions.txt` is never edited to make an upload possible, which `13 §2.8` names as *"the single worst thing you can do to this project."*
- **No ledger row is added, deleted or invented.** The row set is fixed at seven and a cell is filled only by something that happened.

## 7. Definition of Done

- [ ] `'the twelve-tester row records the date the closed track opened'` passes, and was seen to fail first for the stated reason
- [ ] a signed AAB is on a closed track
- [ ] twelve testers are invited and the count is recorded
- [ ] TestFlight has the iOS build
- [ ] the ledger row carries the start date — the clock is running while N33 proceeds
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
fvm flutter test test/policy/calendar_commitments_test.dart
make check
make test
```

The anchor's failure message is a deliverable in its own right — before the ledger is filled it must
name the row by key, not count rows. Then run the tag, which now selects something:

```bash
fvm flutter test --tags calendar
```

Prove the artefact, before and after upload:

```bash
bash tool/assert_permissions.sh build/app/outputs/bundle/release/app-release.aab
keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab
ls symbols-archive/0.9.0+1/android symbols-archive/0.9.0+1/ios
```

G1 must exit `0`; the certificate owner must be the upload key from N32-T01, never `CN=Android Debug`;
and both symbol directories must exist before the AAB leaves the laptop.

The rest cannot be verified from a shell, and each one has its own failure:

- Play Console shows the track **live** and the opted-in count at **twelve** — read it in the console,
  not from your own list.
- All twelve appear in account-level **License testing**, so nobody is charged for a test.
- The opt-in URL installs the app on a phone that is not yours.
- TestFlight shows the build, at the same build number, installable.
- `docs/calendar.md`'s completion date, counted forward on a calendar, lands outside 1 February –
  30 April if the plan is to ship straight afterwards.

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `chore(release): open the closed track and TestFlight`
