# N32-T02 — The Play app record and the store listing draft

| | |
|---|---|
| **Epic** | [N32 — Signing and the closed track opens](epic.md) · `00-README` §9 step 12 (2 of 3) |
| **Task** | 2 of 3 |
| **Depends on** | N32-T01 |
| **Commit** | one commit · `docs(store): the Play app record and the listing draft` |

## 1. Why this task exists

The app record, and the listing draft carrying **N02-T02's honesty paragraph** — written at
epic 2 precisely so it could be used here without re-opening any screen's copy. The listing says what
the app is, what it is not, and what the permission set means.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/research/00-tech-decisions.md` | §3.1 | the only permitted public wording, all 230 characters of it, and the phrase that may never be written |
| `docs/engineering/13-build-ci-release.md` | §2.1, §12 item 9 | store metadata is outside every scanner, forever — *"you are the gate"* |
| `docs/engineering/13-build-ci-release.md` | §6.1 | nothing user-facing promises an install size; spec §11's "under 20 MB" is about bundled content |
| `docs/engineering/11-monetization-and-store.md` | §9.4, §9.5 | the Play data-safety exemption, the App Review notes **verbatim**, and the four things not needed because there is no account |
| `docs/engineering/11-monetization-and-store.md` | §10, §6.7 | price and territories, and *"the price never appears as a literal anywhere in the repository"* |
| `docs/engineering/CONVENTIONS.md` | §5.1, §5.3, §5.4 | *unlock* not *purchase*, *the free tier* not *trial*, the absolute ban list, and `en_GB` copy conventions |
| `shed-book-spec.md` | §12, §14 | the five safety rules the copy is judged against, and one-time unlock €10–15, no subscription ever |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-monetization` | the store record, the price and the territories from N00-T09 |
| `shed-accessibility-and-copy` | the listing copy, which is bound by the same wording rules as the app |
| `shed-release` | runbook, invoked by name — its gotcha list is the only place that says store metadata is outside every gate |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/policy/offline_wording_test.dart`
- **Test** — `'the store listing draft uses decision-record §3.1 verbatim and adds no new claim'`
- **Why it is red today** — there is no listing, and the first draft written would improvise the offline claim.

```bash
fvm flutter test test/policy/offline_wording_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — the listing draft in `docs/store/`, quoting the recorded paragraph.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

Two things about the anchor, both of which decide whether it is worth anything. **The file already
exists** — N02-T02 wrote it and N22-T04 added a case to it. Add cases to that file and to its existing
`const` banned-phrase list; a second list in `test/support/` acquires a second allowlist, which is the
failure `12 §1.4` describes. And **`_publicCopy` already names `docs/store/`**, so the two new files
fall inside the banned-phrase scan the moment they are created — the anchor's job is the other half:
that the permitted paragraph is present *character for character*, read out of decision-record §3.1 at
run time and never inlined in the test.

## 5. What you build

Two authored documents, one test file extended, one ledger cell completed, and roughly forty form
fields typed into two browsers. Everything typed into a console is a **copy** of something in
`docs/store/` — nothing is composed in a text box.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `docs/store/listing-play.md` | **New.** Every Play listing field, one heading per field, with its character limit in the heading. Follows `docs/store/offline-honesty.md`'s precedent for the folder and the hyphenated name; no authority names either path |
| 2 | `docs/store/listing-app-store.md` | **New.** The App Store fields, which are a different set with different limits, plus the App Review notes. Two files rather than one because a single file is how a 4000-character description gets pasted into an 80-character box |
| 3 | `test/policy/offline_wording_test.dart` | **Edit.** The anchor plus four cases, added to N02-T02's file and its existing `const` banned-phrase list |
| 4 | `docs/calendar.md` — `store_identifiers` | The **outcome** cell gains the date the Play record was created under the application id, and the App Store record's SKU. No new row: N00-T06's `'the ledger carries exactly the seven commitments the critique names'` asserts set equality, and an eighth row turns it red |
| 5 | `docs/engineering/11-monetization-and-store.md` §9.5 | One pointer line: the App Review notes are filed in `docs/store/listing-app-store.md` and quoted from here. 11 stays the source; the test reads §9.5 at run time, exactly as N02-T02's reads decision-record §3.1 |

No `lib/`, no `assets/`, no ARB. The About screen's copy is **N29-T07's** and the export screen's is
**N21's**; both quote `docs/store/offline-honesty.md` rather than re-typing it, and neither is re-opened
here. That separation is the entire reason N02-T02 wrote the paragraph twenty-nine epics early.

### 5.1 The Play app record — the fields that cannot be changed later

Play Console ▸ Create app. Four answers on that first screen outlive the app:

| Field | Answer | Why it matters |
|---|---|---|
| App name | as `docs/store/listing-play.md` records it, ≤ 30 characters | Changeable, but it is what the twelve testers will search for |
| Default language | **en-GB** | Owner ruling 3 puts UK/Ireland first. `en-US` here means American spellings in the one place a shepherd judges the app before installing it |
| App or game | App | — |
| Free or paid | **Free** | **One-way.** A paid app can be made free; a free app can never be made paid. Shed Book is free with one non-consumable unlock (decision #87), so Free is correct — and this is the moment any other pricing shape becomes impossible |

The package name is chosen by the **first upload**, not on this screen, and `13 §3.1` is unambiguous:
*"chosen once, before the first upload, and can never change on either store."* It was fixed at
N00-T01 and recorded in `RELEASES.md`'s header. Read it from there. Do not type it from memory.

Then the declarations, none of which is a listing field and all of which block the track:

- **App access** — *all functionality is available without special access*. There is no account, so
  there is no test-login block to fill in. `11 §9.5`: do not add an account-deletion URL "for parity";
  it would create the account model the app does not have.
- **Ads** — no. There are none and there never will be.
- **Content rating** — the IARC questionnaire, completed honestly. It is a hard gate on publishing to
  any track, including a closed one.
- **Target audience** — adults. Not a children's app, so no Families policy surface.
- **Data safety** — **"No data collected or shared."** The answers are **N30-T07's**; the typing is
  here. `11 §9.4` carries Google's own exemption for payment services verbatim, which is why an
  `in_app_purchase` integration keeps a clean form and RevenueCat would not have.
- **Government / financial / health declarations** — no, no, no. A one-time unlock is not a financial
  feature, and an animal-husbandry notebook that gives no advice and is not a record (spec §12.2,
  §12.3) is not a health app. If a form asks whether the app provides medical information, the answer
  is no and the reason is a safety rule, not a marketing choice.
- **Privacy policy URL** — mandatory, hosted, and §5.4 below is about the fact that it has no owner.

### 5.2 The listing files — one heading per field, limit in the heading

```markdown
# Play listing — en-GB

## App name (≤ 30)
## Short description (≤ 80)
## Full description (≤ 4000)
## Release notes, closed track (≤ 500)
## Category · Contact email · Privacy policy URL
## Graphics: icon 512×512 · feature graphic 1024×500 · ≥ 2 phone screenshots
```

```markdown
# App Store listing — en-GB

## Name (≤ 30)
## Subtitle (≤ 30)
## Promotional text (≤ 170)
## Description (≤ 4000)
## Keywords (≤ 100, comma-separated, no spaces)
## Support URL · Privacy policy URL
## App Review notes — 11 §9.5, quoted, never re-typed
## Screenshots: one iPhone display-size set, dark
```

The limits above are the ones both consoles enforced when this was written. **Read them off the
console on the day** — they move, and a listing that is four characters over is a form that will not
save while you are holding twelve testers' attention.

### 5.3 The paragraph, and the field it does not fit

Decision-record §3.1's permitted wording is **230 characters**. The Play short description is **80**.
The paragraph therefore goes in the **full description** and in the App Store **description**, quoted
whole, and the short description gets a *different sentence that is also true*.

> If it does not fit a field, the field gets a shorter sentence that is **also** true, not a trimmed
> version of this one. (N02-T02 §6)

A trimmed quotation is the single most likely defect in this task, and it is worse than a paraphrase:
*"Shed Book has no account, no server and no sync"* on its own is true, but dropped from its second
sentence it starts to read as the tier-3 claim the project explicitly does not make. The test compares
the full description against the whole 230 characters for exactly this reason.

### 5.4 The details that are easy to get wrong

- **Store metadata is outside every scanner, forever.** `13 §2.1` says the listing and the release
  notes *"are outside its reach and are a human checklist item"*; `13 §12` item 9 says *"you are the
  gate."* That is why the copy is authored in a file a test can read, and why the console is a
  **paste target**. Type nothing into Play Console or App Store Connect that is not in
  `docs/store/`. When a field is later edited in the console, edit the file in the same sitting or the
  file stops being the source and becomes a fossil.
- **This task's own commit message contains a banned word, and it is not a typo to fix quietly.**
  `CONVENTIONS.md` §5.3 bans `draft` absolutely, and §6 of this file repeats the ban for commit
  messages — yet the commit line the backlog fixes is `docs(store): the Play app record and the
  listing draft`, and Play Console's own word for an unpublished listing is *draft*. The ban exists
  because there is no draft **state** in the write path (spec §5, `00-README` §2.4); it was never
  aimed at a document. Do not silently reword the commit and do not silently reword §5.3. **Raise it**
  — the honest resolution is a numbered ruling in `CONVENTIONS.md` §6 scoping the ban to the app and
  its code. Until then, use *the listing copy* in your own prose, as this file does, and leave the
  fixed commit line alone.
- **Do not write the price into the copy.** `11 §6.7` and `CONVENTIONS §5.4`: the price is never a
  literal. Both stores render it per territory from the price you set, and `docs/calendar.md`'s
  `price_and_territories` row is the one place the number is written down. `copy.currency_literal`
  scans `lib/` and `assets/` and cannot see `docs/` — which is precisely why this is a discipline
  item and gets a test case of its own (§5.5).
- **Say `unlock`, `the free tier`, `the cap`.** Never *trial*, *freemium*, *paywall*, *purchase*,
  *subscribe* (`CONVENTIONS §5.1`). Never *sync*, never *offline-first*, never *cloud backup*. And
  keep `export` and `backup` apart the way §5.2 does: *export* is records leaving the phone, *the
  backup* is the JSON file. A listing that offers "cloud backup" describes a different app and would
  be a false claim in a store.
- **Nothing user-facing promises an install size.** `13 §6.1`: spec §11's *"well under 20 MB"* is about
  bundled content and *"saying otherwise in a store listing, a README or a forum post is a claim the
  project cannot keep."* The listing may say there is no breed database and no licensed data; it may
  not name megabytes.
- **The permission list is public, and the honesty paragraph is why.** A shepherd reads
  POST_NOTIFICATIONS, RECORD_AUDIO, SCHEDULE_EXACT_ALARM and the billing entry on the store page. If
  G0 found that Play Billing 8.0.0 contributes `ACCESS_NETWORK_STATE`, the page will also say *"view
  network connections"*, and `docs/store/offline-honesty.md` block 2 is the paragraph that answers it
  (`13 §2.2`, second permitted outcome). Check which outcome N02-T02 recorded before you write a word.
- **The hosted privacy-policy URL has no owner in this backlog, and it blocks this task.**
  Decision-record §3.4 #5 calls it *"the one piece of internet infrastructure this project cannot
  avoid"*; N00-T09 explicitly deferred it here. Both consoles require it before a listing can be
  saved. The **in-app** half is already covered and must stay that way: `11 §9.1` ships the full policy
  text as static Dart strings on Settings ▸ About, which is N29-T07's — *"and it avoids
  `url_launcher`, which is itself on Apple's privacy-manifest SDK list."* Do not add a link-out to
  satisfy a form.
- **Screenshots are of a dark app, and never of the Unlock row.** There is no light theme
  (`06 §9.2`), which makes the store page unusual and is fine. The Unlock row renders
  `ProductDetails.price` from the store; in a screenshot harness there is no store, so any price on
  screen is a fabrication in public. `golden_screenshot` lives in `tool/`, never `test/` (`13 §4.6`),
  and generating the images is not this commit's work.
- **Run the app's own content policy over the listing.** `lib/domain/policy/content_policy.dart` is a
  pure-Dart scanner for §12.2 phrasings — dose, diagnosis, *"you should"*. A `test/policy/` test may
  import `lib/domain/`, so use it rather than writing a second regex list. Reusing it is also the
  thing `/simplify` would ask for.

### 5.5 The full test set

| File | Case | What it catches |
|---|---|---|
| `test/policy/offline_wording_test.dart` | `'the store listing draft uses decision-record §3.1 verbatim and adds no new claim'` | the anchor; a trimmed or paraphrased 230-character paragraph in either full description |
| `test/policy/offline_wording_test.dart` | `'every listing field is inside its store's character limit'` | a description that will not save, discovered while twelve testers are waiting |
| `test/policy/offline_wording_test.dart` | `'the App Review notes are 11 §9.5's block character for character'` | the notes drifting from the document that owns them, resubmission after resubmission |
| `test/policy/offline_wording_test.dart` | `'no listing field contains a currency symbol followed by a digit'` | the `copy.currency_literal` rule applied where the gate structurally cannot reach |
| `test/policy/offline_wording_test.dart` | `'the listing text passes ContentPolicy'` | *dose*, *diagnosis*, *should* — spec §12.2 in the one artefact a vet-adjacent claim would be read from |
| `test/policy/offline_wording_test.dart` | *edge* — both new files are inside `_publicCopy`'s scope, asserted rather than assumed | a listing file added outside `docs/store/` and silently skipped by the banned-phrase scan |
| `test/policy/offline_wording_test.dart` | *edge* — the short description is exempt from the quotation rule but still scanned for banned phrasings | a test that either demands 230 characters in an 80-character field or stops scanning it altogether |
| `test/policy/offline_wording_test.dart` | *edge* — the quotation is read from decision-record §3.1 at run time, never inlined | the test drifting from the document and then defending the wrong sentence |

Nothing here is time-shaped: no instant is computed, stored or formatted, so no `test/domain/uk_zone/`
case is added. The one date in this task is the ISO date written into `docs/calendar.md`'s
`store_identifiers` outcome cell, and it is written, never derived.

## 6. Constraints that bind this task

- **No ARB here, and that is not a skipped step.** This task writes no `lib/` and no `assets/`, so `app_en.arb`'s rules — a `description` on every message, a `<screen>.<element>` key, a `headingLevel:` on every heading, no domain noun as a literal — bind **N29-T07**, which authored the About message that quotes `docs/store/offline-honesty.md`. Say so in the commit message rather than ticking a line the diff does not reach.
- **Offline** — no network path may be added. G2 (the dependency allowlist) and G3 (the import scan) stay green, and the permission set never changes without G0's recorded evidence.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.
- **Safety rules §12.2 and §12.3 are reached here.** No dose, no diagnosis, no *"you should"*; and no sentence that presents the app as a compliance, official or regulatory record. These are two of the five §12 questions the PR body must answer, and they are the two this branch genuinely touches.

## 7. Definition of Done

- [ ] `'the store listing draft uses decision-record §3.1 verbatim and adds no new claim'` passes, and was seen to fail first for the stated reason
- [ ] the offline wording is §3.1 verbatim
- [ ] the honesty paragraph from N02-T02 is present if G0 required it
- [ ] no banned phrasing anywhere in the listing
- [ ] price and territories match the ledger
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
fvm flutter test test/policy/offline_wording_test.dart
make check
make test
```

Then the checks no test can make, because they are about a browser and about a human reading:

```bash
grep -rniE "never leaves your phone|offline-first|cloud|sync|compliance record|you should" docs/store
grep -rnE "[€£$][0-9]" docs/store
wc -m docs/store/listing-play.md docs/store/listing-app-store.md
```

The first two must print nothing. The third is a sanity read before you paste — no field may exceed
its limit, and the whole Play file being under 4000 characters is not the same fact as the
description being under 4000.

Finally, the two-console check, by hand:

- Every field in Play Console and App Store Connect is byte-identical to the file it came from.
- The privacy-policy URL resolves from a phone that is not yours, on mobile data.
- Read the full description **aloud, once**. It is the only paragraph in this project judged by
  somebody who will never open the app.

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `docs(store): the Play app record and the listing draft`
