# Shed Book — Three Directions to Build

Design direction selection. Twelve candidates in, three out.
Date: 2026-07-27

---

## 1. How the twelve were screened

The twelve candidates are not twelve designs. They are four ideas, each generated three or four times with different paint. Before choosing, they were clustered:

| Family | Candidates | The shared spine |
|---|---|---|
| **Amber keypad instrument** | The Register · Nine Keys · Till Roll (a) · Till Roll (b) | No navigation, one morphing face; monospaced/oversized numerals; amber phosphor on near-black; keypad-first; bottom thumb-arc |
| **Append-only document** | Afterglow · Indelible · (Till Roll again) | Single vertical stream; hairline-ruled ledger geometry; monochrome ink; print-like ornament; corrections printed, never erased |
| **Spatial board** | Dark Board · Strip Bay · Jug Board | A persistent board that morphs; dense; spatial map as the primary datum; edge rail; position-is-identity |
| **Radical reduction** | Four Doors · Big Yellow · Nightwheel | Very few enormous targets; one screen that re-blooms; almost no reading |

Four of the twelve are effectively duplicates of another candidate (both Till Rolls against each other and against The Register; Nine Keys against The Register). Picking two from any one family would have failed the seven-of-nine orthogonality bar before the first pixel — Afterglow and Indelible, for example, share **navigation, geometry and ornament** outright, leaving only six axes to differ on.

So the method was: pick one family member each from three families, then **fold the best orphan ideas from the discarded siblings into the survivor** rather than losing them. Each of the three below is a merge, and each merge also deletes the risk its parents shared.

The fourth family — radical reduction — was screened out as a family, not as individuals. Reasons in §5.

---

## 2. The three

### A. `the-register` — The Register
*The instrument.* The ewe is **loaded**, not navigated to, and she stays loaded across events, modes and cold launches. Twelve keys that never move for the life of the app. **A digit always means a number** — press 2 and you have said "two"; the loaded context decides whether two is lambs, ease or days, and the welded mode line says which in words. Recall is a readout, never a document.

> *A week later you describe it as:* "the calculator one, where the ewe stays in the window and the keys never move."

### B. `strip-bay` — Strip Bay
*The wall.* Every animal in play is a horizontal strip in a labelled bay. You never search for her — you look at the wall. Strips are never wiped, they are **filed**: turning out slides a strip off the board into the book. Bays with nothing wrong in them render as flat black, so a quiet night is a nearly dark screen, and that darkness is the reading.

> *A week later you describe it as:* "the whiteboard one, where turning out files the strip instead of wiping it."

### C. `indelible` — Indelible
*The book.* One ruled page per night, one row per event, a madder-red margin rule carrying the auto-captured time. **There is no delete** — the delete button draws a red line through the row and prints STRUCK 03:41 in the margin, forever, including in the export. And because a lambing is a forty-minute window and not a form, the row **stays open**: press one corner slab once per lamb as each arrives, and the birth type is derived from the strokes and labelled as derived.

> *A week later you describe it as:* "the ledger one you can't erase, where you tap once per lamb like a tally counter."

---

## 3. The differentiation matrix

Nine axes, three designs. **All nine diverge** on every pairwise comparison. The bar was seven.

| Axis | A · The Register | B · Strip Bay | C · Indelible |
|---|---|---|---|
| **1 Navigation model** | **No navigation at all.** One instrument face that re-legends. The loaded subject persists across events, modes and relaunches. Secondary functions are readouts summoned onto the same face. | **One persistent board that morphs**, plus a five-key edge rail that re-legends by context. Drawers push up *over* the board and never replace it. | **Single vertical stream.** One long page filled downward. A ewe card is the book filtered to 412; the medicine book is the book filtered to treatments; the season summary is the book's totals footer. |
| **2 Density** | **Sparse and absolutely fixed** — four permanent zones, fourteen targets, never more, never fewer, in the same place all night. | **Dense instrument panel** — 9–12 strips at 72pt, each carrying tag, bay, hours, litter and flag at once. Capped at five per bay + a `+N MORE` strip so it never scrolls mid-entry. | **Medium and rhythmic** — 7–8 ruled 64pt rows plus the live row. Density from the grid, not from cramming. |
| **3 Typographic voice** | **Oversized numeral display over monospaced instrument.** Tag 120pt, key digits 56pt, machine text all-caps tracked tabular. Lowercase only inside a note. | **Heavy condensed grotesque + tabular monospace.** One rule: identity is condensed, duration is monospaced. Prose reverts to humanist sans. | **Editorial serif + humanist sans, strictly split.** The record is set in the book face; the buttons are set in the machine face. Stated in the app itself. |
| **4 Geometry** | **Chunky bevelled slabs** on a hard grid. 108×108pt keys, 1pt top-light bevel, 2pt bottom shadow rule, 10pt dead gutters. | **Hard rectilinear, rectangle-in-rectangle-in-rectangle** — strip, holder, bay. Zero radius. Bay dividers are 2pt rules, not gaps. | **Hairline-ruled ledger** (rules at 2pt, see §4). One vertical madder margin rule 68pt in, a double rule under a night's total. No containers, no radius in the record. |
| **5 Colour strategy** | **Amber-phosphor instrument.** One hue at four luminance steps, one 800ms commit green, one red used twice in the whole app. | **Semantic multi-hue coding**, confined to an 8pt strip-holder edge and never to type. Every coloured edge is redundant with a printed word. | **Inverted-paper ink.** Three ink densities and exactly one hue — a dull madder doing three jobs (margin rule, strike-through, query mark). No status palette at all. |
| **6 Data representation** | **Numerals-first readout.** The register head is an instrument reading: tag at 120pt, then one machine line — `412 · 3 SEASONS · AVG 2.0 · ASSISTED×2`. History is a value, not a page. | **Spatial map + bar-and-gauge.** Position is the primary datum. Each strip carries an hours-penned fill bar with a tick at the user's own threshold — time as a shape, read from three metres. | **Textual list + tally marks.** Numerals-first left column, literal strokes in the lamb column, tabular figures aligning into scannable columns. |
| **7 Primary input** | **Keypad-first, exclusively.** Every quantity in the app is the same twelve keys. Text is a detour, announced as one. | **List-tap and two-tap move.** Tap the strip, tap the destination bay. Never a drag. Keypad is the fallback for an animal not on the board. | **Stepper-and-counter over fill-the-row.** One 160×140pt corner slab pressed once per lamb; every other cell in the live row is its own 64pt inline target. The row *is* the form. |
| **8 Layout anchor** | **Bottom thumb-arc.** Keys and action slabs own the lower 62%; the register head owns the top and is never a target. | **Right edge rail** (mirrorable), five 72×72pt softkeys, with a tapped strip lifting to **centre stage** while the board holds at 35%. | **Bottom-pinned document** with the counter slab in the dominant-hand **corner**. The record reads upward into history; the thumb only ever works at the bottom. |
| **9 Ornament level** | **Material bevel + confined glow** — a 2px phosphor bloom on the register numerals *only*, so peripheral vision can find the readout while your eyes are on the lamb. | **Heavy borders and rules, all structural** — holders, bays, clip tabs, threshold ticks. No glow, no gradient, no shadow, no texture, no icon. | **Print-like ink and paper** — rules, margins, daggers, strikes, a printed page header and a printed export footer. No fake grain, no shadow; the ornament *is* the ruling. |

**Pairwise distance: 9/9 · 9/9 · 9/9.**

Sanity check on the near-collisions, because they are where a matrix lies:

- *A and C both use tabular figures.* Different jobs: A's are an instrument readout at 120pt; C's are a ledger column at 20pt in a serif. Different faces, different sizes, different purpose.
- *B and C both have an edge element.* B's rail is the primary control surface on the dominant side; C has **no rail at all** — its index is a printed line in the stream. (Indelible's original edge tabs were cut precisely to avoid this echo.)
- *A and B both have a fixed key block.* A's is the entire input model; B's is a fallback that only appears when the animal is not already on the board, and it rises *over* a live board rather than replacing anything.
- *B and C both use rules.* B's rules are structural containers under load-bearing borders; C's are print ruling on an otherwise borderless page.

---

## 4. What each merge added and deleted

### A · The Register = The Register ⊕ Nine Keys ⊕ Till Roll's one good rule

**Added:** The Register's persistent *loaded subject* — the structural fix for the single most dangerous 3am error, recording against the wrong ewe, because she is always the largest object on the phone. Nine Keys' fixed muscle-memory grid, which is what makes the thing operable without looking.

**Deleted:** the fatal flaw both parents shared — **mode error**. Till Roll's insight is imported wholesale: *the digit block never re-legends.* Then sharpened past where any parent got to — **a digit always means a number**. Pressing 2 always means "two"; the mode only decides what two is attached to, and the mode line states it in words at 24pt. The one remaining hazard (tag digits vs quantity digits) is resolved by the register head itself: if a ewe is loaded and an event is open, digits are quantities; LOAD is a permanent key that returns to tag entry.

**Also deleted:** the receipt tape. History on the instrument face is capped at a three-line, non-scrolling machine echo. The instrument shows a *readout*; the document belongs to C.

### B · Strip Bay = Strip Bay ⊕ Dark Board ⊕ Jug Board

**Added:** Dark Board's two best ideas. First, **black-when-fine** — an empty bay renders as flat board with a hairline label and no fill, so a quiet night is a nearly dark screen. Second, the **acknowledge-vs-clear split**: tapping a flashing strip turns it steady, which means "I have seen it", is itself a timestamped write, and does *not* clear the underlying condition. The app never claims something was done because you looked at it. Also Dark Board's keypad-over-a-live-board move, which converts the recents strip from a history list into a reading of the shed's actual state — at 3am, the ewe you are handling is usually the ewe the shed is already worried about. From Jug Board: the hours-penned fill bar, so time is a shape rather than a number.

**Deleted:** the failure all three parents shared — **a board that scrolls is a list in a costume**. Bays cap at five full strips plus a `+N MORE` strip, and the board never scrolls during entry. Jug Board's fatal assumption is also cut: bays are **states, not a floor plan**, so the design does not collapse for a ewe who lambed on the group-pen floor, in a field, or in a trailer, and there is no shed to configure before night one.

### C · Indelible = Indelible ⊕ Afterglow

**Added:** Afterglow's two ideas Indelible lacked. First, the **open subject** — a lambing is a forty-minute window, not a form-filling event, so the row stays open, you can walk away and come back, and the second lamb needs no reselection. Second, **thumb-tally counting**: press once per lamb and the birth type is *derived from the count and labelled as derived* (`TWIN (COUNTED)`). Nobody ever chooses "twin" from a list, which quietly makes safety rule 4 structural — a declared type that disagrees with the strokes prints a query mark and stays there.

**Deleted:** the legibility risk both parents carried. Afterglow's five-step luminance decay is cut to Indelible's **three measured ink densities with a 4.5:1 floor**, so no row is ever a 12% ghost through a wet screen. Every rule is raised from 1pt to **2pt**, because the ruling is the entire structure of this design and a hairline is the least head-torch-proof mark available on a mid-range Android at low brightness.

---

## 5. What was rejected, and why

**Nine Keys, Till Roll (a), Till Roll (b)** — folded into A. All three are the same instrument as The Register: no navigation, amber phosphor, monospace or oversized numerals, keypad-first, bottom thumb-arc. Five to seven axes identical to each other. Their orphan ideas (fixed 3×3 grid, "the digits never re-legend", the printed-receipt commit model) are all in A.

**Afterglow** — folded into C. Shares navigation, geometry *and* ornament with Indelible; only six axes apart, below the bar. Its two orphan ideas (open subject, thumb tally) are in C; its phosphor-decay signature was cut on legibility grounds rather than kept as decoration.

**Dark Board** — folded into B. Its own risk note is correct and disqualifying as a standalone: it is *a reading instrument built for a product whose core loop is writing*, and on night one with an empty flock it is a black rectangle that reads as broken. As a discipline layered onto a board that also writes, it is excellent.

**Jug Board** — folded into B, spine discarded. The map assumes she is in a pen, and a great many lambings are not; for those, the spatial conceit is a detour and the "not penned" rail slab is the actual primary path, which makes the map decorative for exactly the events that most need recording fast. It also requires you to describe your shed before it is right, and a *wrong* map actively misleads a tired person into tapping the wrong jug.

**Nightwheel** — rejected outright. Three independent problems, any one fatal: the Fitts's-law case for pie menus depends on the pointer starting at the centre, which a tap-only wheel cannot guarantee, so it inherits the geometry without the proof; the mirror problem destroys the trained-angle premise for anyone who doesn't always hold the lamb in the same arm; and glow-and-halation on an arc is precisely the worst case for the ~40% of adults with astigmatism, in a user base that skews older.

**Big Yellow** — rejected, and it was the hardest to lose. Its counter-slab and giant tag numeral are genuinely thrilling. But it collides with A on three axes (oversized numeral voice, numerals-plus-tally data, bottom thumb-arc) and near-collides on colour (single warm accent on black), so it cannot ship alongside the instrument. Independently: a counter with **no confirmation step** is the most dangerous input in the whole set — a cold thumb bouncing through a freezer bag registers a triplet where there were twins — and "the app opens on the last-touched animal" is confidently wrong for a two-person flock or a shepherd returning after an hour, which is worse than a menu. Its tally idea survives inside C, where the stroke prints into a visible ruled row you can read back.

**Four Doors** — rejected, and it is the reserve. It is genuinely orthogonal to all three (humanist sans mixed-case words, monochrome grey with no hue, big quaternary choices, centre-stage full-bleed, zero chrome) and would have qualified on distance alone. It loses on depth cost: a treatment with a batch number and a withdrawal period is five or six screens where a dense row is one, and a system whose entire authority rests on having no exceptions already makes one for the pen board. If the owner rejects all three below, this is the fourth to build.

---

## 6. Do all three pass the 3am test?

| Requirement | A · The Register | B · Strip Bay | C · Indelible |
|---|---|---|---|
| One thumb, one hand | All targets in lower 62% | Rail on dominant side, mirrorable; entry in lower two-thirds | Live row + corner slab welded to bottom edge |
| ≥60×60pt targets | 108×108pt keys, 10pt dead gutters | 72pt strips full-width, 76pt slabs, 72×72pt rail keys | 64pt ruled cells, 160×140pt counter slab |
| No banned gestures | Everything is a labelled key; delete is `CLR` | Two-tap move replaces every drag; nudge keys arrange bays | Strike-through button replaces swipe-to-delete; vertical scroll only |
| Dark primary, no white flash | First frame `#0A0806` | First frame `#0C0D0E`, board mostly black | First frame `#0A0A0B` |
| ≥18pt body | 20pt machine body, 19pt prose | 19pt prose, 22pt mono times | 20pt record, 19pt controls, nothing below 18pt |
| Under 15s to a saved event | ~6s, 4–5 presses | ~10s, 5 taps (1 tap if she's lit on the board) | ~6s, 3 taps |
| Zero interruptions | No navigation, therefore nowhere to put a modal | Only the user's own thresholds can light a strip | Export nag prints as a row you can ignore |
| Assume the phone dies | Every press is its own commit; no Save exists | Commits at the tag, before the litter | Row commits at the first keystroke; visible in ink one line up |

All three also honour §12 without special-casing: the withdrawal field ships empty and labelled as the user's own entry in every direction (A states `NO DEFAULT VALUES` on an inert legend plate, B on a clipped sub-strip, C under a dotted rule reading *READ FROM THE BOTTLE*); no direction contains a suggestion mechanism at all; and a contradiction is flagged and left standing in all three (A's amber head, B's red CHECK tab, C's madder query mark), with the resolution always a choice the shepherd makes, never one the app makes.

---

## 7. Do they span the space?

They are three genuinely different answers to "what is this object?":

- **A says it is a machine.** You are an operator. Speed comes from muscle memory and from never having to look.
- **B says it is a place.** You are in a shed. Speed comes from already knowing where she is, and the app's second job — telling you who needs you — is its first.
- **C says it is a record.** You are keeping a night that will be impossible to reconstruct. Speed comes from the page already being open, and the app's moral position is legible in its ornament.

Sparse / dense / medium. Amber-mono / semantic hue / ink-and-madder. Keypad / spatial tap / counter. An owner choosing between these is choosing a philosophy, not a palette.
