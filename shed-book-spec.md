# Shed Book — Product Specification

**The lambing notebook for a phone. One tap per event, at 3am, in a shed with no signal, no account, and no subscription.**

Version 1.0 spec · Offline-only mobile app · iOS + Android

---

## 1. The idea in one paragraph

A shepherd with 20–400 ewes keeps lambing records in a wax-jacket notebook and on a whiteboard nailed to the pen wall. Both fail in the same way: the notebook is in a coat across the shed when both hands are occupied, and the whiteboard gets wiped. Records get written from memory hours later, and by the end of the season a portion of them are simply wrong. Shed Book replaces the notebook with a phone app built around a single fifteen-second interaction — pick the animal, tap what happened — that works permanently offline, requires no account, is bought once, and never asks for anything again. Its lasting value is not the entry, it is the recall: in year two, "what did 412 do last year?" takes one second instead of an evening with a shoebox.

---

## 2. The problem, concretely

03:20. Ewe 412 lambs triplets. One is slow and needs a stomach tube. The shepherd's hands are covered in iodine and lubricant, the head torch is the only light, and the notebook is thirty feet away in a coat pocket. The entry gets deferred. At 7am it gets written from memory, and by then two other ewes have lambed. By the end of the season three ewes' records are wrong, two singles have been recorded as twins, and nobody can say which ewe reliably produces a lamb that gets up on its own.

What they use today:

| Tool | Why it fails |
|---|---|
| Wax-jacket notebook | Requires two hands and a working pen; not searchable; written from memory when deferred |
| Whiteboard on the pen wall | Gets wiped; no history; only holds "who is in which pen right now" |
| Spreadsheet on a laptop | Transcribed weeks later, if ever; the transcription is where the errors enter |
| Farm SaaS (Herdwatch, FlockFinder, LambPlus, AgriWebb, My Sheep Manager) | All require an account, most require a subscription (up to €149/yr); "offline" means a sync queue, not independence; priced and designed for 500+ ewe commercial units |
| Memory | Fails at 3am on night eleven |

---

## 3. Who it is for

**Primary:** smallholders and small commercial flocks, roughly **20–400 ewes**, lambing indoors or in a field within walking distance. One or two people doing all the work, often alongside a day job.

**Where they gather:** The Farming Forum (sheep board), Accidental Smallholder, r/sheep, r/homestead, National Sheep Association, breed societies, local NFU and young farmer groups.

**What they type into an app store:** *lambing app · sheep records offline · flock book app · lambing records no subscription · lambing notebook*

**Explicitly not for:** 1,000-ewe commercial operations with EID readers and staff, pedigree breeders needing EBV analysis, or anyone whose primary need is regulatory movement reporting. Those people already have software and it already works for them.

---

## 4. Why offline is an advantage, not a limitation

1. **Sheds have no signal.** Metal or stone, in a valley, often with the phone inside a ziplock bag. Anything that queues and syncs is a liability at the exact moment it is needed.
2. **No login, ever.** At 3am there is no patience for a password, a lapsed subscription, an update prompt, or a spinner.
3. **It cannot break.** No server means no outage, no API deprecation, no company going out of business in 2029 taking five seasons of flock history with it.
4. **Price honesty.** A shepherd with sixty ewes will not pay €149/year for what a £3 notebook does. Offline-only removes the running cost, which is what makes a one-time price credible.
5. **The data is nobody else's business.** Losses, barren rates and treatment records are commercially sensitive and stay on the device.

---

## 5. Design spine: the 3am test

Every screen must pass this. If a feature cannot be operated under these conditions, it does not ship.

- **One thumb, one hand.** The other hand is holding a lamb.
- **Gloves, wet hands, or a phone in a bag.** Minimum tap target 60×60 pt. No swipe-to-delete, no drag, no long-press-only actions, no pinch, no force touch.
- **Cold fingers.** Poor capacitance — big targets, generous hit slop, no thin sliders.
- **Head torch or darkness.** Dark theme is the default, not an option. No white flash on launch. Optional red-shift mode. High-contrast type, minimum 18 pt body.
- **Under fifteen seconds** from unlock to a saved lambing event.
- **Zero interruptions.** No ads, no rating prompts, no onboarding after first run, no "what's new", no notification permission nags mid-season.
- **Assume the phone dies.** Every write is committed immediately. There is no draft state to lose.

---

## 6. The core loop

> Open → pick the ewe → tap the event → the app timestamps it and asks only for the two or three fields that matter → done.

Everything else in the app exists to serve that loop or to read back what it recorded.

---

## 7. Must-have features (v1)

### 7.1 Fast animal selection
This is the hardest UX problem in the app and deserves the most attention.

- **Giant numeric keypad** for tag entry — digits at least 40 pt, filtering the flock list as you type.
- **Recents strip** — the last 6 animals touched, one tap each. The ewe you just handled is usually the ewe you are still handling.
- **"In the pens" list** — animals currently in individual pens, shown first.
- **Partial tag matching** — typing `12` surfaces 412, 128, 12.
- **Create-on-the-fly** — if the tag does not exist, one tap creates the ewe and continues. Never block an entry to make the user go and set something up first.
- **Optional voice tag entry** using OS on-device speech recognition.
- **Optional tag OCR** using the OS text recogniser on the camera. Always a shortcut, never the only route.

### 7.2 Lambing event entry
- Timestamped automatically; the time is editable afterwards for deferred entries.
- **Birth type:** single / twin / triplet / quad / more.
- **Lambing ease:** 1–5 (unassisted → vet/caesarean), as a row of five big buttons.
- **Per lamb:** sex, alive/dead/stillborn, birthweight (optional), tag number (optional — can be added later).
- **Assistance detail:** who assisted, malpresentation note, lubricant/ropes/vet.
- **Care checkboxes:** colostrum given (with volume/method), navel dipped, stomach tubed, warmed.
- **Free-text note** and optional voice note.
- **Photo attachment.**
- Every field except birth type is skippable. A valid record can be one tap.

### 7.3 Lamb records and fostering
- Each lamb is its own record, linked to its **birth dam** permanently.
- **Foster / adopt** flow: move a lamb to a different ewe in two taps, keeping birth dam and rearing dam as separate fields. This is the flow most likely to be abandoned if it takes five taps.
- **Pet lamb / bottle** status with a feeding count.
- **Death recording** with date and cause from a short editable list (starvation, hypothermia, watery mouth, joint ill, crushed, stillborn, unknown, other).

### 7.4 Pen board
The digital replacement for the whiteboard, and a feature paper genuinely cannot match.

- Grid of individual pens with occupant, entry time, and **hours since penned**.
- Colour or badge for "ready to turn out" based on a user-set threshold (e.g. 24 or 48 hours).
- Move / turn out / mark as group in one tap.
- Works as a glanceable board — legible from arm's length in a head torch.

### 7.5 Treatments and medicines
- Log product name, dose, route, batch number, date, and **withdrawal period in days**.
- **The withdrawal period is always entered by the user from the bottle label. The app ships no default values and makes no suggestion.** A wrong withdrawal number puts meat or milk into the food chain.
- Countdown per animal, with a clear "clear on" date.
- Repeat-last-treatment shortcut for treating a batch.
- A medicine book view that lists every treatment chronologically for export.

### 7.6 Reminders (local notifications only)
All timed on-device. No server, no push.

- Colostrum window after birth.
- Navel dip.
- Turn out from individual pen.
- Tag-by date (user-set interval).
- Ring / dock / castrate date.
- Second treatment dose.
- Withdrawal period ends.
- All intervals user-configurable; all reminders individually mutable. Nothing nags twice.

### 7.7 History and recall — the retention feature
- **Ewe card** showing every previous season: litter size, ease score, losses, mothering ability, prolapse, mastitis, and any note ever written about her.
- One-line summary at the top of the card, visible before anything else: *"3 seasons · avg 2.0 · assisted twice · prolapsed 2025."*
- Full-text offline search across every note, tag, and treatment.
- Filter the flock by anything: barren, not yet lambed, triplet-bearing, currently penned, under treatment.

### 7.8 Season summary
- Lambing percentage (with the definition configurable — lambs born / lambs reared, per ewe put to ram or per ewe lambed).
- Average litter size, barren rate, assisted rate.
- Losses broken down by cause and by age.
- **Lambing spread** — a simple bar chart of births per day, which tells you next year whether your tupping was tight.
- Comparison against previous seasons once they exist.

### 7.9 Export and backup
Because there is no cloud, this is a safety feature, not a convenience.

- **CSV** in three shapes: one row per lamb, one row per ewe, one row per treatment.
- **PDF flock book** for the season, printable.
- **Medicine record PDF** for the vet or an inspection.
- **Full JSON backup** for restore onto a new device.
- Via the system share sheet — email, AirDrop, a USB drive, whatever the user already uses.
- **A gentle end-of-day prompt to export**, at most once per day, dismissible for the season. The app must be honest that a lost phone is lost data unless the user exports.

### 7.10 Settings that actually matter
- Units: kg / lb, °C / °F.
- Terminology: ewe / gimmer / shearling / theave / hogget — editable labels, because these vary by county, let alone by country.
- Reminder intervals.
- Season start date and season switching.
- Dark / red-shift theme.
- Delete a season; delete everything.

---

## 8. What beats paper — state it explicitly

If the app cannot win on these, it loses to a £3 notebook and should not be built.

| Mechanism | What it does that paper cannot |
|---|---|
| **Search** | "412" returns her whole life in under a second |
| **Timestamp** | The record is right because it was written at the moment, not from memory at 7am |
| **Reminders** | Paper cannot wake you when a withdrawal period ends |
| **Calculation** | Lambing percentage, losses and spread are computed, not tallied by hand in March |
| **Structure** | Consistent fields mean the season summary is possible at all |
| **Export** | A CSV and a printable flock book, without a transcription step that introduces errors |
| **The pen board** | A live, timed view of who is penned and for how long, which the whiteboard approximates and loses |

---

## 9. Screens

1. **Flock** — searchable list, filters, quick add.
2. **Ewe Card** — history, current status, actions.
3. **Quick Entry** — the 3am screen: keypad, recents, event buttons.
4. **Lambing Entry** — birth type, ease, lambs.
5. **Lamb Card** — sex, weight, dam, foster, death.
6. **Foster** — two-tap reassignment.
7. **Pen Board** — grid with timers.
8. **Treatments** — log, withdrawal countdowns, medicine book.
9. **Reminders** — due today, overdue, upcoming.
10. **Season Summary** — stats and spread chart.
11. **Export** — CSV, PDF, backup.
12. **Settings**.

---

## 10. Local data model

```
Season       (id, year, label, start_date, ewes_to_ram, scanning_result, notes)
Ewe          (id, tag, eid?, breed, dob/age, source, status, notes, seasons[])
Lambing      (id, season, ewe, datetime, birth_type, ease_1_5, assisted_by,
              presentation_note, note, voice_note?, photos[])
Lamb         (id, lambing, tag?, sex, birth_weight?, status, death_date?,
              death_cause?, birth_dam, rearing_dam, pet_lamb, notes)
Pen          (id, label, occupant_ewe?, occupant_lambs[], entered_at, turned_out_at?)
Treatment    (id, animal_ref, product_name, dose, route, batch_no,
              date, withdrawal_days_user_entered, clear_date, note)
Reminder     (id, animal_ref, type, due_at, completed_at?, muted)
Note         (id, animal_ref, text, photo?, created_at)
Settings     (units, temperature, terminology_map, reminder_intervals,
              season_current, theme, percentage_definition)
```

Storage: a local SQLite database plus a media folder. Nothing leaves the device unless the user exports it.

---

## 11. Bundled content

**None that is licensed.** Everything is user-generated. The only shipped data is roughly 40 authored terms — lambing ease scale descriptions, common death causes, common malpresentations, common treatment routes — all generic husbandry vocabulary written from scratch. Total app payload well under 20 MB, dominated by fonts and icons.

No breed database, no medicine database, no regulatory forms.

---

## 12. Safety and correctness rules

These are non-negotiable and should be visible in the code review checklist.

1. **Never default a medicine withdrawal period.** The user reads it off the bottle. The app stores what they typed and shows its source as "as entered by you."
2. **Never give veterinary advice.** No suggested doses, no diagnosis from symptoms, no "you should" text anywhere.
3. **Never present the app as a compliance or regulatory record.** It is a notebook. Holding numbers, movement reporting and statutory medicine books are out of scope, and the export should say so in its footer.
4. **Never silently correct a user's entry.** If a birth type of "twin" has three lambs attached, flag it; do not fix it.
5. **Timestamps are honest.** Auto-captured time is labelled as such; edited time is labelled as edited.

---

## 13. Explicitly not in v1

- Bluetooth EID stick readers.
- Weights over time, EBVs, genetic indexes.
- Movement reporting, holding registers, statutory compliance exports.
- Pasture or grazing management.
- Multi-user, sharing, or any sync.
- Cloud backup of any kind.
- Cattle, goats, pigs, poultry.
- Weather.
- Scanning-to-lambing prediction models.

Each of these is a reasonable v2 candidate. None of them belongs in the first version, because none of them is the thing that fails at 3am.

---

## 14. Money

**One-time unlock, €10–15.** No subscription, ever — the absence of a recurring price is a core part of the positioning, not a pricing experiment.

Free tier: full app, capped at a small flock (e.g. 15 ewes) or one season, so the shepherd can try it for a night before committing. The cap must not degrade the 3am experience.

This group buys tools constantly and is vocally hostile to farm-software subscriptions. That hostility is the wedge.

---

## 15. Success criteria

- A shepherd uses it on night two, and night eleven.
- Median time from unlock to a saved lambing event is under 15 seconds.
- More than half of entries are made within five minutes of the event, not batched at dawn.
- At least one user opens a ewe's previous-season history during their second season. That is the moment the app becomes irreplaceable.

## 16. Kill criteria

Drop this if one week of research on The Farming Forum and Accidental Smallholder shows any of:

- Smallholders are content with the free tiers of Herdwatch or FlockFinder and do not mind the account.
- The paper notebook is actively preferred because it survives a bucket of water and a cold-dead phone does not.
- National regulatory recording is pushing everyone onto an official scheme app regardless of what else exists.

## 17. Open questions to resolve before building

1. Can we observe one full night in a real lambing shed? The entry flow is the product, and it cannot be designed correctly from forum posts.
2. Does the app aim to replace the paper record entirely, or sit alongside it for the first season? This changes how hard the export needs to work.
3. Which region first — UK/Ireland has the densest smallholder population, an entrenched notebook culture, and incumbents priced for commercial units.
4. Ziplock-bag operation: does the target hardware register taps reliably through a freezer bag? If not, the whole interaction model needs rethinking around volume-button shortcuts.
