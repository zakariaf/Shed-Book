# Shed Book — Differentiation Audit and Ship Decision

> ## ✅ SELECTED BY THE OWNER — 2026-07-27: **Indelible**
>
> **`docs/design/indelible.md` is the design system of record.** It is the only direction that
> ships. `the-register.md` and `strip-bay.md` are retained for their reasoning and for the
> grafts named below, but **no element of either may enter the product or any skill** — a
> half-Register, half-Indelible screen is worse than either.
>
> Carried forward with the selection:
>
> 1. **The graft this audit recommends stands**: take The Register's *persistent loaded subject*
>    — the animal you are writing about is the largest object on the phone and stays there
>    across a cold launch. Not its keypad, not its amber, not its frozen chrome.
> 2. **The one blocking fix**: `indelible.html:1138` has the live row as the last child of the
>    scrolling `.stream`, contradicting the spec's own claim that it is welded above the bottom
>    edge. **You can scroll the open row off screen and lose track of whose row is open** —
>    exactly the error the graft above exists to prevent. Promote the live row out of the stream
>    into a fixed layer above `.band`, and lift its tag toward display size.
> 3. **The one hard spec violation to close**: `--t-stamp:14px` is used 49 times inside the
>    frames and `--t-head:16px` 13 more, against an 18px floor. Its own three-part exemption
>    test fails on `DEAD`, on `AUTO-CAPTURED` (the sole §12.5 provenance label) and on
>    `DERIVED FROM 3 STROKES` (the sole statement of its own §12.4 claim). Those three strings
>    carry meaning nothing else on the line carries, so they cannot be exempt stamps.
> 4. **The premise is untested.** Indelible rests on a claim borrowed from ships' deck logs and
>    GxP records — that an exhausted human wants their own mistake to stay legible. Test 3 below
>    settles it, and the design has no fallback if it is wrong.

**Design director's final review of the three candidate design systems.**
Built from the three HTML files as they actually exist, not from what the specs claim.
Date: 2026-07-27

Files audited:

| Direction | Mockup | Spec |
|---|---|---|
| The Register | `/Users/zakariafatahi/50-apps-challenge/E01/mockups/the-register.html` (1,194 lines) | `docs/design/the-register.md` |
| Strip Bay | `/Users/zakariafatahi/50-apps-challenge/E01/mockups/strip-bay.html` (2,061 lines) | `docs/design/strip-bay.md` |
| Indelible | `/Users/zakariafatahi/50-apps-challenge/E01/mockups/indelible.html` (1,783 lines) | `docs/design/indelible.md` |

---

## 1. The differentiation verdict

### 1.1 The matrix, measured from the files

Every cell below is a fact extracted from the markup or the `:root` block. Claims from the spec documents that the mockups do not support are marked.

| Axis | A · The Register | B · Strip Bay | C · Indelible |
|---|---|---|---|
| **1 Navigation** | **Zero.** All twelve frames carry a byte-identical chrome: `<div class="keys">` with 12 buttons and `<div class="rail">` with `TREAT NOTE DIED PEN MORE`. Verified: 12/12 frames, 12/12 identical rail strings, 144 key buttons in the file. No tab, no back, no push. | **One board + a re-legending 5-key rail + a drawer over the board.** Six distinct rail legend sets across 12 frames: `New Move File Find Book` · `New Lamb Treat Move Close` · `New Words Voice Scan Close` · `New Foster Weigh Tag Close` · `New Move File Remind Book` · `New Season Export Setup Close`. `New` is the only invariant key. | **One vertical stream.** All 12 frames are `.hdr` + `.stream` (scrolling ruled rows) + `.band` (Index + optional slab). No rail, no tabs. The index is a 96×64 button, not a structure. |
| **2 Density** | 18 fixed targets per frame (12 keys + 1–3 slabs + 5 rail), never more; plus up to 6 candidate slabs during LOAD only. Head carries 3–8 read-only lines. | Highest. Screen 01 = 13 targets, each strip carrying 6 data cells at once (boot, tag, state word, sub-state, litter, tab) plus a 6pt hours bar. | Medium. Screen 01 = 15 targets. Each ewe row is a 32px tag + a trailing state + one 18px summary line, in an 88px ruled row. |
| **3 Type** | **Mono-first.** JetBrains Mono is the default voice; Source Sans 3 is a three-use exception. All-caps everywhere except a free-text note. Tag 120px. Floor 18px. | **Three faces, one job each.** Roboto Condensed (identity), IBM Plex Mono (every duration, without exception), Source Sans 3 (prose). Tag 44px. Floor 18px, zero hardcoded font sizes anywhere in the file. | **Two faces, strictly split.** Source Serif 4 = the record; Source Sans 3 = every control. The app prints the rule on screen 12: *"If it is serif, it happened. If it is sans, it is a thing you can press."* Tag 32px / live tag 44px. Floor 18px **for body — but see §2.2**. |
| **4 Geometry** | Bevelled slabs. `border-top:1px solid #8A5E00` + `inset 0 -2px 0 #6B4A00` + `0 2px 0 #000`; on press the bevel migrates to the bottom edge. Radius ceiling 4px. The only one of the three that simulates physical depth. | Rectangle in rectangle in rectangle. `--radius:0` everywhere; the single 4px drawer lip is the only soft edge in the product. Structure is 2pt rules, never gaps. | Ruled page. `--radius-record:0`, `--shadow:none`, `--rule-w:2px`. One vertical madder spine at `left:68px` running the full height of every frame. No containers in the record; the only filled shapes are buttons. |
| **5 Colour** | **One hue, everything.** Amber `#FFB000` / `#C98A00` carries every glyph in the app on `#0A0806`. Plus a green that exists for 800ms per write and a red used exactly twice. | **Six semantic hues**, confined absolutely to an 8pt `.boot` and a 6pt tab outline, never to type: `#6E7B8B` `#C8892E` `#4E8C55` `#96607D` `#9A958A` `#C4453B`. | **One hue, three marks.** Bone `#EDE8DC` on `#0A0A0B` carries the type; madder does the margin rule, the strike and the dagger. There is no status palette at all. |
| **6 Data** | Numerals-first readout. 120px tag + one dense machine line + a 3-line non-scrolling echo. Chart = 14 **vertical** bars, 18px wide, 2025 as a 2px outline overlay, **no value labels at all** — you press a key to read a day. | Spatial map + gauge. Position is the datum. Every strip carries a 6pt hours bar with a 3pt tick at the user's own threshold. Chart = 14 **horizontal** rows with proportional fill bars. | Ruled table + tally marks. Tags right-aligned in a fixed tabular column so `12`, `77`, `91` sit under the units of `412`. Chart = 14 **horizontal** rows of discrete 8×24 blocks, one block per birth — the same mark as the lamb tally. |
| **7 Input** | Keypad, exclusively. The 12-key block is present and identical on all 12 screens. Every quantity in the app is typed. | Tap the strip. The keypad appears on **exactly one** of twelve frames (`class="keypad"` count = 1) and rises *over* a live board. | One 160×140 corner slab pressed once per lamb. The keypad appears on **exactly one** of twelve frames, inside a sheet, for the tag cell only. |
| **8 Anchor** | Bottom, full width. Keys y≈263–597, primary slab 605–689, event rail 699–759. Lower 66%. Zone 1 is never a target. | Right edge, vertical. 88pt rail, bottom-anchored block y 418–786, mirrorable. Board occupies the left 302pt. | Bottom corner. A 152px `.band` with the slab at `right:16px bottom:12px` and Index at `left:16px`, with 102px of dead board between them. |
| **9 Ornament** | Material. Bevel plus a confined phosphor bloom: `text-shadow: 0 0 2px rgba(255,176,0,.22), 0 0 8px rgba(255,176,0,.14)` on register numerals **only**. | Structural. Explicitly: "No shadow. No gradient. No glow. No blur." Only borders, rules, boots, tabs and bars. | Print. `--shadow:none`. Rules, a margin spine, daggers `†`, strikes, query marks, printed page headers and a printed export footer. |

### 1.2 The verdict: no two converged

**These are three genuinely different design systems.** All nine axes diverge on all three pairwise comparisons. The proof is not rhetorical, it is structural: put the three quick-entry frames side by side and the DOM has almost nothing in common. The Register's screen 03 is a 120px numeral over a permanent key block. Strip Bay's is a live board with a keypad risen over it. Indelible's is a scrolling ruled page with a sheet on top.

More telling, the three make **incompatible bets about what the object is**, and the code carries the bet:

- The Register's rail is identical in 12/12 frames. That is a design that has staked everything on muscle memory and cannot change its mind later without spending the asset.
- Strip Bay's rail re-legends six ways. That is a design that has staked everything on context and accepted that you must read the rail before you press it.
- Indelible has no rail at all, and its slab is absent from 4 of 12 frames. That is a design that has staked everything on the page and accepted that some pages have nothing to press.

You cannot merge any two of those without breaking one.

### 1.3 The near-collisions, named precisely

A matrix that reports 9/9 on every pair is usually lying. Here is where these three come closest, and why each is not convergence.

**(a) The lambing spread chart — Strip Bay and Indelible.** This is the one real collision. Both render it as **fourteen horizontal rows**, and both arrived there for the *same stated reason*: an 18pt type floor makes fourteen vertical bar labels impossible. Same layout, same constraint, same conclusion.

It is not convergence because the mark differs and the marks are ideological. Strip Bay draws `.cfill` as a continuous proportional fill inside a track — an instrument gauge, matching its hours bars. Indelible draws fourteen discrete `8×24` blocks, one per birth, in the same shape as the lamb tally, so a shepherd who has learned the tally has learned the chart. And the comparison strategy differs: Strip Bay overlays a `.gauge` with a tick; Indelible prints the whole of 2025 as a second set of fourteen rows below. Still — this is one component, and it is the only place in the three files where a screenshot of one could be mistaken for the other. Worth knowing.

The Register did not collide here because it kept a vertical bar chart and paid a real price for it: **no value labels anywhere**, and the mode line reads `SPREAD — DAY 1-14` because you must press a key to read a number off the chart. That is either the most disciplined decision in the set or the most user-hostile, and §5 lists it as a thing to test.

**(b) Source Sans 3 appears in all three.** The Register uses it for three things (mode prose, notes, export footer). Strip Bay uses it for prose only, with condensed and mono owning identity and duration. Indelible uses it for **every button in the app**. Same font, three completely different jobs and three different proportions of the total. Two of the three specs also cite the same MIT AgeLab / Monotype glance-time study to justify it. That is shared *evidence*, not shared design — but it does mean a single font licence decision touches all three.

**(c) All three banned icons.** Register has five drawn primitives, Strip Bay has two SVG paths, Indelible has one delete-key glyph plus tally blocks. All three concluded independently that a word beats a pictogram under a head torch. That is the brief converging them, not the designers.

**(d) All three solve §12.5 the same way** (`TIME AUTO` / `TIME EDITED` · `Auto` / `Edited · was` · `AUTO` / `EDITED †`) and **all three ship the withdrawal field empty** with a read-the-bottle line. Again brief-driven, and correctly so.

**(e) All three quick-entry screens are a 12-key numeric pad plus a filtered candidate list.** This is the closest the three come at the level of the screen that matters, and it is worth being honest about: spec §7.1 mandates a giant numeric keypad, a recents strip, an in-the-pens list, partial matching and create-on-the-fly. Everyone had to build the same components. What differs is where the pad lives and what the candidates are made of:

- Register: the pad is *always there* (it costs nothing to summon), the candidates are 116×64 slabs in the head, and they vanish the instant a subject resolves.
- Strip Bay: the pad is the *fallback*, and the candidates are the shed's live state — 300×72 strips carrying pen, hours and litter — so you can pick her by what she is doing rather than by her number.
- Indelible: the pad is a sheet, and the candidates are 64pt ruled lines right-aligned on the same tabular column as the rest of the book, with create-on-the-fly as the last printed line rather than a modal.

Nobody converged. But the brief pre-converged them here more than anywhere else, which is why §5 puts a shed test on exactly this screen.

**Conclusion: ship none of them for being different — they are all sufficiently different. Choose on merit.**

---

## 2. The 3am scorecard

Scored against spec §5, from the markup only.

| §5 rule | A · The Register | B · Strip Bay | C · Indelible | Winner |
|---|---|---|---|---|
| **Min target 60×60** | Smallest interactive: **64×60** event slab (`--event-w:64 --event-h:60`). Keys 116×76. Primary slab 368×84 (largest single area in the set, 30,912px²). Ewe rows and pen tiles are `<div>`, not targets — you press the printed number. Unique: a **10px dead gutter that no hit-slop crosses**, so a 14–20mm gloved contact patch cannot straddle two keys. | Smallest: **276×60** sub-strip. Strip 300×72, rail key 72×72, keypad key ~98×72, slab 100×110, check 150×76. Empty pen slots are 24pt but are `<div>`, correctly read-only. Unique: **"never five across"** — birth type and ease are 3+2, not 5, because five 60pt cells are legal and wrong. | Smallest: **64×64** (`--tap:64`, the only system whose floor exceeds the spec's). Slab **160×140**, keypad key 117×84, rows 64/88. Largest thumb-shaped target in the set. | **C** — highest floor and the best-shaped primary. **A** close second on the dead gutter, which is the only cold-finger provision anyone actually enforced in code. |
| **Min 18pt body** | Floor holds. Every token ≥18, every hardcoded size in the file ≥18 (34/28/26/24/22/20/19/18). Prose 19, machine 20. | Floor holds, most cleanly of the three: **zero hardcoded font sizes in the entire file**; every size resolves through a token and the smallest token is 18. Body 19. | **Fails.** `--t-stamp:14px` is used **49 times inside the twelve app frames** and `--t-head:16px` **13 times**, plus 4 `gap-label` at 14px. See §2.2 — this is a real finding, not a nitpick. | **B** |
| **Dark primary, no white flash** | `#0A0806`, L 0.00251 — darkest first frame. The only file that explicitly writes `@media (prefers-color-scheme:light){/* intentionally empty */}`. Spec details `LaunchScreen.storyboard` and `windowSplashScreenBackground` at the platform level. | `#0C0D0E`, `color-scheme:dark`, comment: "NO LIGHT THEME EXISTS… the OS launch background is `--board`". 400ms cold-start budget stated. | `#0A0A0B`, `color-scheme:dark`, `html{background:var(--page)}`. | **A** on darkness and launch rigour. All three pass. |
| *(Red-shift, extra credit)* | Nearly free — the system was already monochrome. Correctly removes green (it destroys dark adaptation) and makes commit `#FF9E6B` + full inversion. | Hardest problem, best solution: **six hues collapse into a single ordinal luminance ramp**, and the loss is provably free because every boot was already redundant with a printed word. Bottom three steps sit under 3:1 *on purpose* — calm must not attract a dark-adapted eye. | Best single line in the set: `--mark-double: block`. **The strike line doubles in red-shift because hue can no longer carry it.** | **B** for the ramp, **C** for the doubling. |
| **No colour-alone status** | Structurally impossible — monochrome. Pen over threshold = 4px double rule (drawn as a `background-image` gradient) + printed `!! OVER` + inverted hours cell. Three channels, none of them colour. Withdrawal band = solid fill + 45° hatch cap + words. | Most colour used, most rigorously redundant: five named channels (position, printed state word, clip-tab word, hours bar, flash rate) with colour as a throwaway sixth. Verified: every `.s-*` strip in the markup carries a `.sw2` state word. | **No status palette exists.** Madder does three non-status jobs. Status is a word plus a dagger plus a doubled rule plus an ink lift. | **C** — you cannot fail a rule you have no mechanism to break. **A** second. **B** third only because it is the one that *could* fail if the redundancy discipline slipped in v2. |
| **No banned gestures** | Zero. Every control is a `<button>`. Delete is a `DEL` key with one invariant meaning. **And the face does not scroll at all** — `.head{overflow:hidden}`, everything else is a fixed-height zone. | Zero gesture vocabulary; tap is the only primitive. Two-tap move replaces every drag. `DEL` has no hold-to-repeat ("a repeat-on-hold is a long-press in disguise"). Drawer lip explicitly not a drag handle. But `.bview{overflow-y:auto}` and entry screens scroll ~1,200pt in a 695pt viewport. | Zero gestures; strike replaces swipe-to-delete; the concept of erasure does not exist. But `.stream{overflow-y:auto}` and the app is a scrolling document by definition. Screen 10 is ~1,900pt tall. | **A**, decisively. It is the only design with **no scrolling surface anywhere**. In a ziplock bag with a wet screen, a momentum-fling that moves the thing you were about to tap is a real hazard, and A is the only one that cannot do it. |
| **Taps to save a lambing — best case** | **2 presses.** She is already loaded (the entire thesis): `LAMBED` slab commits, then one digit for litter. Zero scrolls. | **3 taps.** Tap her lit strip → rail `Lamb` → birth-type slab. Zero scrolls (birth type sits at y≈160–270, above the fold). Spec claims 3.5s. | **3 taps.** Page is already open with a live row and the time already inked: tag cell → her line in the sheet → `+ Lamb`. Zero scrolls. | **A** |
| **Taps to save a lambing — worst case** *(unknown ewe, create on the fly)* | `LOAD` + 3 digits + `CREATE` slab + `LAMBED` + litter digit = **7**. | rail `New` + 3 digits + `Create 412 and carry on` + rail `Lamb` + type slab = **7**. | tag cell + 3 digits + `no such tag — write 412 into the book` + `+ Lamb` = **6**, and **there is no birth-type press at all** because the type derives from the strokes. | **C** |
| **Second lamb, 40 minutes later** | Ewe stays loaded. Re-press the litter digit — you must **remember the previous count and press the next number** (`3` instead of `2`). 1 press, but it is a revision. | Re-tap her strip (she is still on the board), re-press the type slab. 2 taps, and again a revision. | Press the same slab in the same corner again. **1 press, no revision, nothing to remember.** The row stayed open. | **C**, and this is the single strongest interaction argument in the whole set. |
| **Foster (spec §7.3: "abandoned if it takes five taps")** | Reach FOSTER mode via `MORE` → tap 305 in the rack → tap the slab = **3+**. | rail `Foster` → tap destination strip = **2**, written with no confirmation. | Tap the `REARING DAM` cell → tap 305 in the sheet = **2**, and the old value prints struck beside the new one. | **B / C tie** |
| **Zero interruptions** | No navigation, therefore nowhere to put a modal. Export nag is a slab legend. | No dialogs anywhere; even `DELETE EVERYTHING` is type-to-arm on the app's one input surface. | Export nag is a printed row you scroll past. Mute is a strike, not a removal, so nothing nags twice. | Three-way tie. All three eliminated dialogs entirely. |
| **Assume the phone dies** | Every press is its own SQLite commit. No Save exists in the vocabulary. One documented exception: `DELETE EVERYTHING`. | Every press is a committed write whose timestamp prints on the control. "The confirmation *is* the write, made visible." | The row commits at the first keystroke and you can see it in ink one line above the one you are writing. | Three-way tie, and this is the most impressive thing about the set: three independent designs all removed the Save button and all three can defend it. |

**Row wins: A 3 · B 3 · C 5** (plus three ties and one split).

### 2.1 The two facts the scorecard understates

**Register's "2 presses" is the most fragile number in the table.** It is true only when the correct ewe is loaded. The design's answer to the wrong-ewe risk is genuinely the strongest of the three — a 120px numeral with a bloom, visible in peripheral vision — but it converts a *transient* error (picking the wrong row) into a *persistent* one (a stale subject sitting in the register while you walk to a different pen). The mitigation is excellent. The hazard is real and it is new.

**Strip Bay's "3 taps" is true and its "entry screen" is not.** Screen 04 stacks a strip (72) + timerow (60) + five bay headers (140) + four slab rows (~440) + three sub-strips (180) + four checks (152) + three fields (228) — roughly 1,270pt in a 695pt viewport. The required tap is above the fold, correctly. Everything else is a long thumb journey down a scrolling page, which is exactly the thing the design's own R1 ("a board that scrolls is a list in a costume") argues against. The no-scroll guarantee holds for the board morphs and nowhere else.

### 2.2 The one hard spec violation: Indelible's 14px stamps

This needs stating precisely, because Indelible's spec (§3.4) argues the exemption explicitly and the argument is good — it just does not survive contact with the markup.

The spec's three-part test for a legal 14px stamp: (a) never body text, ≤12 chars, all-caps at 0.14em; (b) always `--ink-full` at 16.19:1; (c) **"no stamp is ever the sole carrier of its meaning — remove every stamp from the app and it still works."**

Test (c) against the file:

| Location | Markup | Verdict |
|---|---|---|
| Screen 4, lamb 3 | `<span class="gap-label">WEIGHT — NOT RECORDED · SKIPPABLE</span><span class="stamp boxed">DEAD</span>` | **Fails.** Remove the stamp and the row reads "LAMB 3 · RAM LAMB / WEIGHT — NOT RECORDED". Nothing says the lamb is dead. Both strings on that line are 14px. |
| Screen 4, time cell | `<span class="stamp">AUTO-CAPTURED</span>` is the only line under `time 03:20` | **Fails §12.5.** And the spec's defence ("`AUTO` sits beside a time that is obviously the current time") does not hold — the status bar reads 03:24. |
| Screen 4, birth type | `<span class="stamp">DERIVED FROM 3 STROKES</span>`, and `TRIPLET <span class="stamp">COUNTED</span>` above it | **Fails §12.4.** Remove both stamps and the row reads "birth type TRIPLET" with no indication it was counted rather than declared. This is the direction's signature safety claim, and it is carried entirely at 14px. |
| Screen 8, withdrawal | `<span class="flabel">Days — read it from the bottle label. <span class="stamp boxed">YOUR ENTRY</span></span>` | Passes. The 19px `flabel` carries the message. |
| Screen 1, ewe 219 | `<span class="stamp boxed">TO LAMB</span>` with an 18px summary "not yet lambed · scanned for twins" | Passes. |

So the exemption holds for most stamps and fails on at least three that are load-bearing for spec §12.4 and §12.5 — the two safety rules the direction is *proudest* of.

**This is fixable and it is a precondition of shipping.** `--t-stamp: 14px → 18px` and `--t-head: 16px → 18px`, then re-flow the ~66 affected strings. The margin cell is 68px wide and already holds an 18px tabular time; an 18px `STRUCK` at 0.14em tracking is roughly 78px and will need the tracking cut to 0.06em or the margin widened to 80px, which moves the spine. That is a half-day of layout work, not a redesign, and it must happen before a line of Flutter is written.

---

## 3. Honest trade-offs

### 3.1 The Register

**Best at:** never having to look. It is the only design where a shepherd on night eleven can perform `412, LAMBED, two` as a thumb shape with the phone at their hip. Twelve keys in the same place on 12/12 screens is not a claim, it is verifiable in the file. It is also the only design with **no scrolling surface at all**, which is the single most underrated 3am property in the set — nothing can ever move under your thumb because nothing moves, full stop. And it has the best answer to the wrong-ewe error: she is a 120px numeral with a bloom, findable in peripheral vision while your eyes are on a lamb.

**Worst at:** read-back, which is what the spec calls the retention feature. The head is capped at three non-scrolling echo lines *forever* (§7.5 of its own spec: "non-scrolling, capped at three lines, forever"). Screen 02 gives you `2026 TRIPLET E3 ASSIST 03:20 / 2025 TWIN E2 PROLAPSED / 2024 TWIN E1 · OLDER VIA MORE` at 18px. Spec §7.7 calls the ewe card "the retention feature" and §15 says the moment the app becomes irreplaceable is "at least one user opens a ewe's previous-season history during their second season." The Register deliberately makes that a value rather than a page. That is a bet against the spec's own stated retention mechanism, taken with open eyes, and it may be wrong.

**Delights:** the numerate shepherd who knows her tag before he looks at her ear. Anyone who has used a till, a calculator or a farm weigh-head. A one-person operation on night eleven.

**Annoys:** anyone on night one, who opens it to a keypad with no obvious starting point. Anyone whose ewes are not tagged with numbers they remember. Anyone over 55 reading an 18px `!!OVER` inside a 48px pen tile. And an accessibility auditor, on the frozen keypad.

**Flutter cost — moderate widget count, highest custom-paint cost, highest layout risk.**
- Stock: `Column` of five fixed-height boxes; `GridView.count(crossAxisCount:3)` for the keys; `Text` with `FontFeature.tabularFigures()`. The 120px bloom is `Text(shadows:[Shadow(blurRadius:2), Shadow(blurRadius:8)])` — free.
- Custom-painted: **the bevel.** `inset 0 -2px 0 var(--reg-etch)` and `inset 0 2px 0 #000` are both inset shadows and **Flutter has no inset `BoxShadow`.** You need a `KeyFace` `CustomPainter` (~150 lines) or a `Stack` of `Container`s. Written once, reused 18× per frame, so the cost amortises — but it is a real component you must own and test at 10 nits. The 45° hatch is a `LinearGradient` with hard stops (cheap). The chart is a `CustomPainter`, ~120 lines.
- **The real risk is Law 5.** "The key block is dimensionally frozen at every text scale" means wrapping the keypad in `MediaQuery(data: mq.copyWith(textScaler: TextScaler.noScaling))`. Trivial to write, non-trivial to defend to an accessibility auditor or an App Store review. Worse: `.head{overflow:hidden}` with `flex:0 0 auto` children means the head **clips rather than compresses**, and the mockup already runs with roughly 4px of vertical slack on screens 04, 07 and 10. In Flutter that is `ClipRect` + `OverflowBox` and it will silently drop content on a shorter device. Pen tile arithmetic is tighter still: a 4-digit tag at 34px plus a `31H` cell needs ~118px inside a 114px content box and will clip. Many UK flocks use 4-digit management numbers.

### 3.2 Strip Bay

**Best at:** telling you who needs you. It is the only design where the app's second job — "who has been penned too long, whose reminder is overdue, who is under withdrawal" — is its first, and it does it without asking a question. The 6pt hours bar with a 3pt tick at the user's own threshold is the only element in any of the three files that is legible at three metres, and it is the one thing paper genuinely cannot do (spec §8, §7.4). The `SEEN` vs `DONE` split on reminders — `SEEN` writes `acknowledged_at`, stops the flash and **leaves the reminder due**; `DONE` writes `completed_at` and files the strip — is better thinking about reminders than either of the other two produced. "The app never claims something was done because you looked at it" is a sentence the other two designs cannot say.

**Worst at:** night one, and the small flock. The design's whole reading is "black means fine", and a 20-ewe flock on night one is a black rectangle with a single `NEW` strip on it. Strip Bay's own spec quotes Dark Board's disqualifying risk — "on night one with an empty flock it is a black rectangle that reads as broken" — and then imports the discipline anyway. The mitigation (a permanent `NEW` strip at the bottom of the board plus a `NEW` rail key) is good but does not change what the screen *reads as*. Spec §15's first success criterion is "a shepherd uses it on night two", and this design is at its worst on night one and its best on night eleven.

**Delights:** the shepherd with twelve individual pens who currently runs a whiteboard. The second person coming on shift at 4am who needs to know what happened. Anyone who has ever walked the shed to check who has been in too long.

**Annoys:** the smallholder with 20 ewes lambing in a field. The mitigation — "bays are states, not a floor plan" — is real and it works (four of screen 01's five bays are fine for a field), but four of five bays on the default board are still pen or treatment states. Also annoys anyone filling a full record: screen 04 is ~1,270pt of scroll.

**Flutter cost — cheapest to build, most conventional, most code.**
- **Nothing in Strip Bay needs a `CustomPainter`.** The boot is an 8pt `Container`. The clip tab is a `Container` with a 6pt border. The hours bar is a `Stack` of three `Container`s with a `Positioned` tick. The chart is fourteen `Row`s with `FractionallySizedBox`. The drawer is a `Stack` + `AnimatedPositioned` (not `showModalBottomSheet` — it must not replace the board and must sit above the rail).
- The one expressive motion, the 260ms file-off, is `SlideTransition` + `SizeTransition`, both stock, ~20 lines.
- The 1Hz/2Hz flash is an `AnimationController(..)..repeat()` with a `StepTween`. Stock.
- The 200% reflow (3-across to 2-across, strip 72→148, rail 88→132) is genuine work but it is `LayoutBuilder` + `MediaQuery.textScalerOf` and it is conventional Flutter.
- **The cost is breadth, not depth.** Seven surfaces, six semantic hues with a second full red-shift palette, and roughly 25 components. This is the most code of the three, and all of it is code a competent Flutter developer writes without thinking hard. That is a virtue for a shipping schedule and a risk for a solo build, because there is a lot of it.

### 3.3 Indelible

**Best at:** being true in year two, and at being impossible to get wrong. Screen 02 is the strongest recall screen in the set — 2026, 2025 and 2024 in one scroll, including a note from March 2025 ruled through with `STRUCK` in the margin. That is exactly what spec §15 says makes the app irreplaceable, rendered.

And the tally is the best safety idea anyone produced. Spec §12.4 says *"if a birth type of twin has three lambs attached, flag it; do not fix it."* Register implements that as a contradiction head after the fact. Strip Bay implements it as a red `CHECK` tab — and screen 04 of Strip Bay literally shows the failure occurring, `Twin` pressed at 04:01 with three lamb rows attached, flagged forever. **Indelible makes the failure unenterable.** You never declare a type; you press once per lamb and it prints `TRIPLET (COUNTED)`. A safety rule you cannot violate beats a safety rule you get warned about, every time.

It also has the lowest worst-case tap count (6 vs 7 and 7), the highest target floor (64 vs 60 and 60), the largest thumb-shaped primary target (160×140), and the only design where the second lamb costs one press with nothing to remember.

**Worst at:** glanceability. It is the only one of the three where you must *read* to know anything. There is no wall to look at and no 120px numeral. Everything is 20px serif on ruled lines. Related: the page gets longer every night and never gets shorter — struck rows and muted reminders accumulate by design. On night eleven of a 400-ewe season the stream is very long and the index is a 96×64 button in the corner.

**Delights:** anyone who keeps a paper day book and will recognise the object on sight. Anyone who has been burned by an app quietly changing a record. The vet or inspector reading the medicine PDF. The shepherd in year two.

**Annoys:** anyone who wants status at a glance. Anyone who wants a tidy screen. And anyone with cold, tired eyes trying to read a 14px `STRUCK` — until §2.2 is fixed.

**Flutter cost — cheapest widgets, most expensive data layer, and the data layer is the product.**
- Stock: `ListView` of ruled rows; the spine is one `Positioned` 2pt `Container`; the band is a `Positioned` box; two `TextTheme`s do the entire serif/sans discipline. The tally is a `Row` of `Container(width:8, height:24)`. The strike is a `Positioned` 3pt `Container` over the row. All free.
- Only custom paint: the dotted rule for an unset field (`repeating-linear-gradient` has no Flutter equivalent) — a `DashedLinePainter`, ~30 lines. That is the entire custom-paint bill.
- **The expensive part is the schema.** "There is no delete, only strikes" means every table carries `struck` + `struck_at`; every query filters or does not filter; every aggregate must decide whether struck rows count (they must not count toward litter size but must appear in the CSV); the CSV export carries `struck` and `struck_at` columns and the PDF prints them. That cost is spread across the whole app rather than concentrated in a widget — and it is also *exactly where the differentiation lives*, so it is money well spent.
- The "open row" is a real but small state machine: a persisted `current_open_lambing_id`, cleared by `Close row` or by opening another.
- The 165% text scale is the friendliest of the three, because a document reflows and a frozen keypad does not.

---

## 4. Recommendation

### Ship **Indelible**.

Not because it is the prettiest — Strip Bay is. Not because it is the fastest — the Register is, in the best case. Ship it because it is the only one of the three that is right about what the product *is*.

The five reasons, in order:

**1. It is the only design whose primary structure is the thing the spec says creates retention.** §1: *"Its lasting value is not the entry, it is the recall."* §15: *"At least one user opens a ewe's previous-season history during their second season. That is the moment the app becomes irreplaceable."* The Register explicitly deletes the document — "history is a value, not a page" — and caps recall at three non-scrolling echo lines forever. Strip Bay files strips off the board into a "book" that the twelve mockups never once show. Indelible *is* the book; the ewe card is the book filtered to 412 and it costs nothing extra to build because it is the same component.

**2. The tally makes safety rule §12.4 structural instead of procedural.** Nobody ever chooses "triplet". You count, and the app prints `TRIPLET (COUNTED)` and labels it as derived. This is the only place in the three files where a safety rule is enforced by making the error impossible to enter rather than by flagging it afterwards. Strip Bay's own screen 04 is a live demonstration of the error Indelible designs out.

**3. It wins the numbers that actually matter.** Lowest worst-case tap count (6). Highest target floor (64 vs the spec's 60). Largest thumb-shaped primary target (160×140). And the second-lamb case — one press, same corner, nothing remembered, no revision — which at 3am on the third of a set of triplets forty minutes apart is the whole ballgame.

**4. Its safety posture is best on every §12 rule simultaneously.** No delete (12.4 by construction). Struck rows exported and marked, never dropped — the export screen says so in a printed footer (12.3). `DAYS NOT COPIED — READ THE BOTTLE` on repeat-last-treatment (12.1). Auto and edited times both kept, both printed, forever (12.5). And it never gives advice because it has nothing to say (12.2).

**5. It is the cheapest widget build and it spends its budget in the right place.** One `CustomPainter` in the whole app. The money goes into a schema that never destroys a row, which is the durable asset.

**The cost of choosing it, stated plainly:** the 14px stamps must go to 18px first (§2.2), and its worst weakness — you must read to know anything — is real. The hybrid below fixes that weakness for the price of 9pt of screen.

**Why not the Register:** it is the best *instrument* and the worst *notebook*, and the spec asked for a notebook. Its bet against read-back is deliberate and defensible, but §15's fourth success criterion is a bet the other way. Its layout has ~4px of slack in three places and clips rather than compresses. And its frozen keypad is an accessibility deviation you will defend more than once.

**Why not Strip Bay:** it is the best-engineered of the three and the easiest to build, and it would be my answer if the spec's primary user were a 400-ewe indoor unit with twelve numbered pens. It is not: §3 says 20–400 ewes, "indoors **or in a field within walking distance**", one or two people, often alongside a day job. Strip Bay's reading is at its weakest exactly where that user starts — night one, small flock, black screen. Keep it as the reserve. If shed testing (§5 below) shows that shepherds genuinely think spatially about their pens and want the board first, this is the design to build instead, and it will take less time than the other two.

### 4.1 The hybrid — one graft from each loser

**From The Register: the persistent loaded subject, at display size, welded to the bottom.**

Not the keypad. Not the amber. Not the frozen chrome. The single idea worth taking is that **the animal you are writing about is the largest object on the phone and stays there across a cold launch.**

Indelible already half-has this: the live row's tag is `--t-tag-xl` at 44px. But the markup contradicts the design's own axis-8 claim. Indelible's spec says *"the live row is welded above the bottom edge"*; the file has the live row as the last child of a scrolling `.stream`, which means **you can scroll the open row off the screen and lose track of whose row is open.** That is Indelible's one genuine safety gap and it is the exact error the Register exists to prevent.

The graft: pin the live row above the `.band` as a fixed element rather than a stream child, and lift its tag toward Register's display size. It costs nothing structurally — the `.band` is already `position:absolute`, so the live row becomes a second fixed layer above it — and it closes the gap using the losing design's best idea.

**From Strip Bay: the hours-penned fill bar with a tick at the user's own threshold.**

`--hours-bar-h: 6px`, a `--bar-fill` fill, and a 3pt `--ink` tick positioned at `(threshold_hours / 48) × width`. Nine points of screen. It is the only element in any of the three files legible at three metres, the tick moves when the shepherd moves their own threshold so the shape stays true, and it is the specific mechanism spec §7.4 asks for ("legible from arm's length in a head torch").

Indelible's pen board (screen 07) currently carries hours as a numeral with a dagger — a number you must read, on a screen you are reading from across a pen. Add a 6pt bar under each pen row and the board becomes glanceable **without adding a single colour and without breaking the ruled-page geometry, because a 6pt bar is just another rule.** This is the graft that fixes Indelible's worst weakness, and it fits the winning design's own vocabulary so completely that it will look like it was always there.

**Runner-up graft, also from Strip Bay, if there is budget:** the `SEEN` / `DONE` split on reminders. `SEEN` writes `acknowledged_at`, stops the flash and leaves the reminder due; `DONE` writes `completed_at`. One column and one button, and it stops the app from ever claiming something was done because you looked at it. Indelible's current reminders screen has only `Done` and `Mute`.

---

## 5. What to test with a real shepherd

Three questions. Five minutes. In an actual shed, at an actual hour, with actual hands. No amount of design reasoning settles any of them, and each one can change the answer above.

### 1. Does a tap register through what is really on your hands and your phone?

Hand them the phone in whatever it actually lives in — ziplock bag, cracked case, nothing — with whatever is actually on their hands: iodine, lubricant, a wet nitrile glove. Have them press the 160×140 slab ten times and a 64×64 word button ten times. Count the misses.

**Why it settles something no reasoning can:** spec §17.4 already flags this as an open question and it is the one that can invalidate all three directions at once. If a 64pt target through a freezer bag misses one time in five, the floor is not 60 or 64, it is 88, and every layout in this document is wrong. Indelible's slab probably survives that; its 64pt word buttons probably do not, and its word buttons are visually just an underlined word, which is the least object-like control in the set. If the answer is bad, the whole interaction model moves to volume-button shortcuts and none of these three ships.

### 2. When you walk up to a ewe, do you already know her number before you look at her ear?

Ask it plainly, then watch them do it once.

**Why it settles something no reasoning can:** this decides between the three input models outright, and it is a fact about their flock, not an opinion about design.

- If **yes** — a numerate shepherd with a small flock and a good memory — then typing is a one-hand operation, the Register's keypad-first model is right, and Strip Bay's board is a detour around a step that costs nothing.
- If **no** — you have to read the tag off her ear, or she isn't tagged yet, or you know her as "the big Texel in pen four" — then typing is a two-hand operation at the worst possible moment, and Strip Bay's "don't search, look at the wall, tap her strip" wins outright.
- Indelible's recents sheet is the hedge that works either way, which is part of why it is the recommendation — but if the answer is a strong yes or a strong no, the hedge is no longer the right buy.

### 3. Show them a struck row and ask what it means.

Print Indelible's screen 02. Point at `note · mastitis left side — wrong ewe`, ruled through in madder with `STRUCK` in the margin, still sitting in a page of live records. Ask two questions: *"What happened here?"* and *"Would you want that on the page, or gone?"*

**Why it settles something no reasoning can:** the entire winning design rests on a premise borrowed from ships' deck logs and GxP records — that an exhausted human wants their mistake to stay legible. That premise has never been tested in a lambing shed. It is a *cultural* claim, not an ergonomic one, and the design has no fallback if it is wrong.

If the shepherd says *"good, I'd want to know I'd written that"* — ship Indelible and the accumulating-clutter weakness is a feature.

If the shepherd says *"no, get it off my page, I'd never find anything in that"* — the signature move is a liability rather than an asset, the clutter weakness becomes fatal, and **the recommendation flips to Strip Bay**, which is the better product for someone who wants a clean board and a filed history they can go and look at when they choose to.

---

## Appendix — evidence index

Every claim above is traceable. The load-bearing ones:

| Claim | Where |
|---|---|
| Register rail identical on 12/12 frames | `the-register.html` — `<div class="rail">` × 12, all `TREAT NOTE DIED PEN MORE` |
| Register key block on 12/12 frames | `the-register.html` — `<div class="keys">` × 12, 144 buttons |
| Strip Bay rail has six legend sets | `strip-bay.html` — `<nav class="rail">` blocks, lines 1273, 1321, 1380, 1455, 1515, 1574, 1646, 1717, 1775, 1811, 1903, 1955 |
| Keypad appears once in Strip Bay, once in Indelible | `class="keypad"` count = 1 in each frames section |
| Indelible 14px in-app strings | `--t-stamp:14px` at `indelible.html:66`, used via `class="stamp"` × 49 and `class="gap-label"` × 4 inside lines 994–1695; `--t-head:16px` at line 65 via `.hdr .t` × 13 |
| Strip Bay has zero hardcoded font sizes | `grep -o "font-size:[ ]*[0-9]*px" strip-bay.html` returns nothing |
| Register's dead gutter | `--sp-5:10px` at `the-register.html:60`, comment: "THE DEAD GUTTER — no hit-slop crosses it" |
| Register head clips, does not compress | `the-register.html:274-277` — `.head{overflow:hidden}`, `.head>*{flex:0 0 auto}` |
| Indelible live row scrolls with the stream | `indelible.html:1138` — `.row.live` is the last child of `.stream`, not of `.band` |
| Strip Bay's SEEN/DONE split | `strip-bay.html:1749-1751` — `Seen / stays due`, `Done / files off`, `Mute / for good` |
| Strip Bay flags the twin-vs-three-lambs error rather than preventing it | `strip-bay.html:1416` — `slab is-warn`, `Twin`, `was 04:01` |
| Indelible prevents it | `indelible.html:1214, 1217` — `TRIPLET COUNTED`, `DERIVED FROM 3 STROKES` |
| Red-shift strike doubling | `indelible.html:140` — `--mark-double: block` |
| Strip Bay ordinal red-shift ramp | `strip-bay.html:171-176` |
