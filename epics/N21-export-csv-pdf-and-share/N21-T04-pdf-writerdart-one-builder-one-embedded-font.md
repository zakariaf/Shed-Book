# N21-T04 — `pdf_writer.dart` — one builder, one embedded font

| | |
|---|---|
| **Epic** | [N21 — Export: CSV, PDF and share](epic.md) · `00-README` §9 step 8 (1 of 3) |
| **Task** | 4 of 8 |
| **Depends on** | N21-T03 |
| **Commit** | one commit · `feat(export): the PDF builder with an embedded font` |

## 1. Why this task exists

One builder, the **mandatory embedded TTF** — a PDF with a non-embedded font renders as
tofu on the vet's machine — and the page furniture: title, season, page numbers, and the footer from
T03.

The base-14 fonts do worse than tofu: they are Latin-1 / WinAnsi only, and `pdf` **throws** on a
character outside that set. The characters that trip it are the ones an iOS keyboard inserts *by
itself* — the curly apostrophe in `didn't`, the en-dash, the ellipsis — plus `℃`, Welsh `ŵ`/`ŷ` and
every Irish fada. `dart_pdf` issues #810, #252 and #405 are that crash, with the message *"Helvetica
has no Unicode support"*. **A crash while exporting the medicine record for a vet visit is a
catastrophic failure of the one safety feature the app has**, so the ban is a gate row and not a
convention.

This task also adds the first of the epic's two runtime dependencies, and establishes the rule that
makes every future PDF carry its footer: **this file is the only place in the app permitted to say
`pw.Document(` or `pw.MultiPage(`.**

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/09-export-formats.md` | **§4.1** (`pdf` and not `printing`, and the honest cost: there is no in-app print dialog) · **§4.2** (the font — embedding is mandatory; which TTF; the `ByteData.sublistView` rule; the two unverified questions) · **§4.3** (`_buildDocument` printed in full, `footer:` unreachable from a caller, the `subject:` belt, the `compress:` parameter and why it is not `@visibleForTesting`) · **§4.5** (page furniture, the print sizes, and why they are not the 18 pt screen floor) · §4.9 (memory) · §6.4 (the PDF arm of `containsDisclaimer` and the ASCII dependency) · §9 (`export.pdf_document`, `export.base_14_font`) · **§10 items 1, 2, 3, 13** (the four unverified questions this task must answer) | the file, its one function, and every rule that keeps it the only one |
| `docs/research/00-tech-decisions.md` | **§5.1** (`pdf` **3.13.0**, nfet.net, verified — the only source of that number) · **§5.3** (`printing` 5.15.0, rejected: `http >=0.13.0 <2.0.0`, and `PdfGoogleFonts` / `networkImage` are one-line footguns) · §3.1 tier 2 (the offline claim the `printing` drop is part of) · §3.2 (G2, G3) · #83 · #98 (Atkinson Hyperlegible Next, SIL OFL 1.1, w700 cap) · #127 (bundled assets < 5 MB) | the version, the ban, and the font |
| `docs/engineering/06-design-system.md` | §5.2 (`LicenseRegistry.addLicense` and `OFL.txt`) · §2.4 (typography, and the w700 cap) | the licence registration and the single-weight argument |
| `docs/engineering/CONVENTIONS.md` | §1 (`assets/fonts/` holds the TTF and `OFL.txt`; `lib/data/` is flat) · **§1.1 rule 3** (`lib/data/`'s permitted packages — the row this task amends to add `package:pdf`) · §1.1 rule 4 (`lib/data/` may not import `material.dart`) · §4.7 (rule-id grammar) · **R60** (no human-facing date is all-numeric) · §5.3 (banned words) | **BINDING** on the file path and the layer-rule amendment |
| `docs/engineering/12-testing.md` | **§1.3** (*"PDF byte output — a byte assertion on a 60-page document is a re-baselining chore that proves nothing"*; what is asserted instead) · §11.1 (policy tests are named for the property) · §8.2 (the eight goldens, and why none of them is a PDF) | the shape of every assertion in this task |
| `docs/engineering/01-architecture.md` | §3.2 (the dependency allowlist and `_checkLockfile`) | what adding `pdf` obliges |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-export-and-restore` | the PDF builder and its page furniture are its subject |
| `shed-dependencies-and-toolchain` | `pdf` 3.13.0 enters `pubspec.yaml` and the offline allowlist in this commit, and decision-record §5 is the only source of that number |

Two auto-firing skills is the cap and the dependency edit takes the second slot: `pdf` drags nothing
with `http` in its graph and that property is what keeps G2 green — it is checked in §8, not assumed.
The typography that has to survive into a printed page is `indelible-design-system`'s; it is not
reloaded because the page furniture uses the embedded TTF and the type scale named in §5.2, and the
`CONVENTIONS` layer rule this commit amends is quoted in §5.1.
## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/pdf_writer_test.dart`
- **Test** — `'the produced PDF embeds its font and carries the footer on every page'`
- **Why it is red today** — nothing writes a PDF, so there is no builder, no embedded font, and nothing that could render on a vet's machine without tofu.

```bash
fvm flutter test test/features/pdf_writer_test.dart   # expect: failing, for the reason above
```

Make the assertion specific while you are writing it. Build a **two-page** document at
`compress: false` whose body contains a string with a curly apostrophe and an `℃`, then assert three
things about the bytes: the file starts `%PDF-`; it contains `/FontFile2` (the TrueType embedding
key — a non-embedded base-14 font produces `/BaseFont /Helvetica` and no `FontFile2`); and it
contains the UTF-8 of `Disclaimers.exportFooter`, which reaches the file through the
document-information `subject:` rather than through the drawn glyphs. Then assert the page count is
2 by counting `/Type /Page` occurrences. **Do not** assert on drawn text — see §5.3.

**Green.** The minimum code that passes, and nothing beyond it — the builder, the embedded font, and byte-level assertions on the output.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

No schema (**this task stores nothing**), no domain, no provider, no controller, no screen, no route,
**no ARB** — nothing in this task is user-facing, because nothing in this task is on a screen. Say so
in the commit message. The work is one dependency, one data-layer file, one asset registration and
two gate rows.

| # | Path | What changes in it, and why |
|---|---|---|
| 1 | `pubspec.yaml` | **Edit.** `pdf: 3.13.0` under `dependencies`, exactly that version, from decision-record §5.1 and from nowhere else — not from memory and not from pub.dev's "latest". Also confirm `assets/fonts/` is already declared (N09 declared it for the app's own face) |
| 2 | `pubspec.lock` | **Committed, and read.** `pdf` brings `archive`, `barcode`, `bidi`, `crypto`, `image`, `meta`, `path_parsing`, `vector_math`, `xml`. **None of them is an HTTP client** — that is the whole argument for `pdf` over `printing`, and G2 is where it is proved rather than asserted |
| 3 | `tool/policy_allowlist.txt` | **Edit.** `pdf` joins `[dependencies]`; its nine transitive packages join `[transitive]`. `dep.direct_main` and `dep.transitive` are different rule ids because they read different sections — a package in the wrong section fails with the wrong message |
| 4 | `docs/engineering/CONVENTIONS.md` §1.1 rule 3 | **Edit, same commit.** `lib/data/`'s permitted-package list gains `package:pdf`. `09 §1.3` requires it; CONVENTIONS outranks every other document on a layer rule, and an un-catalogued permitted package is one the next fixer removes |
| 5 | `lib/data/pdf_writer.dart` | **New.** `_buildDocument`, `_runningHeader`, `_runningFooter`, and nothing else yet. The two top-level `compute` entry points are T05's |
| 6 | `lib/app.dart` **or** `lib/main.dart` | **Confirm only.** `LicenseRegistry.addLicense` already registers `assets/fonts/OFL.txt` (06 §5.2, landed with the app's own face). If it does not, it lands here — the font is now in a **document that leaves the phone**, which makes the licence registration less optional, not more |
| 7 | `tool/check_policy.dart` | **Edit.** Two rows: **`export.pdf_document`** (`pw.Document(` or `pw.MultiPage(` outside `lib/data/pdf_writer.dart`) and **`export.base_14_font`** (`Font.helvetica`, `Font.times`, `Font.courier`, `Font.symbol`, `Font.zapfDingbats` anywhere under `lib/`). Both use the `export` namespace T01 added to `CONVENTIONS §4.7` |
| 8 | `test/policy/gate_rules_test.dart` | **Edit.** A `firesOn` entry per new rule id; plant, watch, delete |
| 9 | `test/features/pdf_writer_test.dart` | **New. The anchor, written first.** T05 grows it |
| 10 | `docs/perf/measurements.md` | **Edit.** §10 item 2's answer: does `pdf` subset the embedded face, measured by diffing a 1-row and a 500-row document. The number belongs on paper before anyone promises a printable flock book by email |

**G3 already exists and now has teeth.** It greps `PdfGoogleFonts` and `networkImage` on every push;
until this commit there was no `package:pdf` in the graph for either identifier to be reachable from.

### 5.2 The signature

`09 §4.3` prints it. This is the whole public surface of the file at T04, and every parameter that
is *not* there is the point.

```dart
// lib/data/pdf_writer.dart — the only pw.Document( / pw.MultiPage( site.
Future<Uint8List> _buildDocument({
  required ExportEnvelope envelope,
  required String title,
  required List<pw.Widget> Function(pw.Context) body,
  required pw.Font base,
  pw.Widget? titleBoxUnderHeading,          // medicine record only (§4.7)

  // TEST ONLY. §6.4's byte assertion needs an uncompressed document.
  // NOT annotated @visibleForTesting: that annotation has no parameter
  // target and the analyzer rejects it there. The guard is the review of
  // the one file `export.pdf_document` confines this code to.
  bool compress = true,
}) {
  final doc = pw.Document(
    title: title,
    author: 'Shed Book ${envelope.appVersion}',
    subject: envelope.disclaimer,           // greppable in the bytes — see §6.4
    compress: compress,
  );
  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4.landscape,
    margin: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    theme: pw.ThemeData.withFont(base: base),
    header: (c) => _runningHeader(c, title),
    footer: (c) => _runningFooter(c, envelope),   // NOT optional, NOT a parameter
    build: (c) => [
      // The box is page-1 furniture, so it is prepended here rather than
      // being the caller's job to remember. `pageNumber` is 1-based.
      if (titleBoxUnderHeading != null && c.pageNumber == 1) titleBoxUnderHeading,
      ...body(c),
    ],
  ));
  return doc.save();   // Future<Uint8List> — materialises the whole document
}
```

**Page furniture** (`09 §4.5`), built by `_runningHeader` and `_runningFooter`:

| Element | Content |
|---|---|
| Front matter (page 1 only) | Title `Shed Book — <season label>` and the document name. Generated: `27 Jul 2026 21:04 (IST, UTC+01:00)` — **`d MMM y HH:mm`, never all-numeric** (R60). App version. Row counts |
| Running header (every page) | `<season label> · <document name> · part N of M` if split, left. One hairline rule under it |
| Table header row | Repeated on every page the table spans — `pw.TableHelper.fromTextArray(headerCount: 1, …)` |
| Rows | Hairline rule between rows. **No fills, no zebra striping** — grey fills cost toner and reduce contrast on the cheap mono laser this will actually be printed on |
| Running footer (every page) | `Disclaimers.exportFooter` at 7 pt across the full width, left; `Page N of M` right. Set inside `_buildDocument`, unreachable from a caller |

### 5.3 The details that are easy to get wrong

- **`ByteData.sublistView(fontBytes)`, never `fontBytes.buffer.asByteData()`.** `.buffer` hands back
  the *whole* backing store and throws away the view's `offsetInBytes` and `lengthInBytes`. A
  `Uint8List` is a **view**, not necessarily a whole buffer: one derived from the `ByteData` that
  `rootBundle.load(...)` returns, or from any slice, is not guaranteed to start at offset 0 — and
  when it does not, the parser is handed the wrong bytes and fails deep inside a table offset with an
  error that names neither the font nor the offset. It works on your machine whenever the view
  happens to start at 0, which is most of the time. The same rule runs the other way on the way in:
  `Uint8List.sublistView(byteData)`, never `byteData.buffer.asUint8List()`.
- **A byte search for the *drawn* footer does not work, and a test that seems to find it is finding
  something else.** Text drawn with an embedded TTF is written as **glyph indices into that font's
  encoding**, so the sentence is not present in the bytes at all, compressed or not. That is the
  entire reason `subject:` is set and the entire reason `compress:` exists. The drawn footer is
  proved **structurally** instead — there is exactly one `pw.MultiPage(` in the codebase and it
  always sets `footer:`, so a reviewer checks one line, once.
- **The `subject:` assertion is `09 §10` item 13 and it is asserted from the PDF format, not measured
  from the package.** Run it: build a two-page document with `compress: false`, `grep` the raw bytes
  for the first six words of `Disclaimers.exportFooter`, then **repeat with `compress: true` and
  record whether it still hits** — if it does, the test does not need the parameter at all. If the
  string is not findable either way, the fallback is a structural assertion only, and `09 §6.3`'s
  "footer on every page" loses its byte-level proof. **Say that in the PR body rather than deleting
  the row.**
- **The `subject:` assertion also depends on `Disclaimers.exportFooter` being pure ASCII** (T03
  asserts it). A PDF string object holds non-ASCII text as UTF-16BE behind a byte-order mark, at
  which point a UTF-8 search finds nothing and the safety test goes green for the wrong reason.
- **`compress:` is a parameter for exactly one reason and it is not `@visibleForTesting`.** That
  annotation has no parameter target and the analyzer rejects it there. The guard is that this file
  is the one place `export.pdf_document` allows any of this code to live, so a reviewer reads the
  whole surface in one sitting. Do not add a second optional parameter "while you are here" —
  nothing else about the signature is reachable from a caller and that is the design.
- **`footer:` is set inside `_buildDocument` and is not a parameter.** There is no code path that
  produces a Shed Book PDF without it. Hoisting it into the parameter list to "make the medicine
  record's box easier" defeats the mechanism; `titleBoxUnderHeading` exists precisely so the box can
  be passed **without** the footer becoming passable.
- **Does `pdf` 3.13.0 accept a *variable* font? Unverified, and it blocks T05.** `09 §10` item 1.
  `AtkinsonHyperlegibleNext[wght].ttf` carries `fvar`/`gvar` tables that a static-only parser may
  ignore, mis-render or reject, and `pdf` has its own parser. **The check is twenty minutes**: build a
  one-page document with `pw.Font.ttf(ByteData.sublistView(fontBytes))`, write it, open it in Preview
  **and in Acrobat**, and confirm the glyphs and the metrics. If it works, build the whole document
  at one weight — hierarchy comes from size, rules and spacing, and `pdf` has no synthetic bold, so a
  single-weight document is the honest design either way (#98 caps weight at w700). If it does not,
  commit two static instances beside the variable file, use them for the PDF only, and count the
  extra ~200–400 KB against the < 5 MB asset budget in `docs/perf/measurements.md`. **Record the
  answer in the PR body; do not leave it as "it looked fine".**
- **`pw.TableHelper.fromTextArray`, not `pw.Table.fromTextArray`.** It moved in an earlier major, and
  the specific thing to confirm against 3.13.0 is the **header-repeat behaviour inside `MultiPage`**
  (`09 §10` item 3): generate a 5-page table and look at page 3. A header that only appears on page 1
  is a flock book whose columns are unlabelled from page 2 onward.
- **The print sizes are 9 pt body, 8 pt for the widest tables, 7 pt footer, 16 pt title — and they
  have nothing to do with the 18 pt on-screen floor.** A document read in daylight at arm's length is
  not a screen read at 3am with wet gloves. **Say this in a code comment**, because the next reader
  will otherwise "fix" it, and a 5-page flock book becomes a 40-page one.
- **No date drawn in a PDF is ever all-numeric** (R60, #108). Numeric dates exist only inside a CSV
  and only beside an ISO-8601 column; a PDF has no ISO column to sit beside, so `14/03` is ambiguous
  to half the planet. `grep -n "dd/MM" lib/data/pdf_writer.dart` returning nothing is in the DoD.
- **Photos are never embedded in any PDF** (#83). Media goes out as a separate share. This is a
  memory decision, not a taste one.
- **A4 landscape, and the reason is written down.** §7.0 rules UK/Ireland first. If the first market
  ever changes, `PdfPageFormat.letter` is a one-line change and belongs beside the locale defaults,
  not scattered through the builder.
- **`printing` 5.15.0 is not an option, and neither is "just for the print dialog".** It declares
  `http >=0.13.0 <2.0.0` and hands every future contributor `PdfGoogleFonts.robotoRegular()` and
  `networkImage(...)` — one-liners that quietly turn the app into a networked app on iOS, where there
  is no permission gate to stop it. The cost is stated honestly and is not hidden: **there is no
  in-app print dialog**, spec §7.9's "printable" is *degraded*, and printing is the OS Print action
  from inside the share sheet. Decision-record §7.1 q16 is the only thing that reopens it.
- **`pw.Document.save()` materialises the whole document as a `Uint8List` and `pw.MultiPage` builds
  its widget tree before paginating.** At T04's scale that is irrelevant; at T05's it is the OOM
  case. The signature returns `Future<Uint8List>` here and T05 is what stops that byte list ever
  crossing an isolate boundary.

### 5.4 The full test set

`test/features/pdf_writer_test.dart` — pure Dart plus one file read for the TTF. No database, no
`pumpApp`.

| Case | What it asserts |
|---|---|
| `'the produced PDF embeds its font and carries the footer on every page'` | **The anchor.** Two pages at `compress: false`: starts `%PDF-`; contains `/FontFile2`; contains the UTF-8 of `Disclaimers.exportFooter`; `/Type /Page` occurs twice |
| `'a curly apostrophe, an en-dash, an ellipsis and ℃ do not throw'` | The exact character set an iOS keyboard inserts by itself, plus the one a temperature note contains. This is issues #810 / #252 / #405, turned into a test |
| `'a Welsh ŵ and an Irish fada render and do not throw'` | The names half of the same property. `09 §4.2` names both |
| `'no base-14 font is constructed anywhere under lib/'` | Source text over `lib/**/*.dart` for all five constructors. Complements `export.base_14_font` — the gate is the build, the test is the reason, and the test names the file that broke it |
| `'pw.Document( and pw.MultiPage( appear in exactly one file'` | A count-and-name assertion against a literal one-entry list, in the shape N11-T02 used: same property, no regex false positives, and the failure message says which file joined |
| `'footer: is not reachable from a caller'` | Source text: `_buildDocument`'s parameter list contains no `footer`, and `_runningFooter` has exactly one call site |
| `'the document-information subject carries the disclaimer at compress: true as well as false'` | **§10 item 13, executed.** If it hits at `compress: true`, record that the parameter is not needed by the assertion and keep it anyway for the reason in the code comment. If it does not hit at all, the test is rewritten as a structural assertion in this commit and the loss is written into the PR body |
| `'the running header repeats the table header on page 3 of a five-page table'` | **§10 item 3, executed.** Build 300 rows, count the header row's text occurrences, assert it equals the page count |
| `'no format string in pdf_writer.dart is all-numeric'` | R60. Source text for `dd/MM`, `MM/dd`, `dd-MM` and `yyyy-MM-dd` inside a drawn string |
| `'the front matter renders d MMM y HH:mm with a zone'` | `27 Jul 2026 21:04 (IST, UTC+01:00)` shape — a month name, never a month number |
| `'a document with an empty body still produces one page with a footer'` | The zero-row case, at the builder level. T05 has the artefact-level version |
| `'the embedded font is the app\'s own face and no second family is bundled'` | `assets/fonts/` contains one family (or two static instances of it, if §10 item 1 forced the fallback) and the total is under the #127 budget |

**Nothing in this task is time-shaped**, so there is no `uk-zone` case here: the front matter's
instant is formatted from `envelope.generatedAt` and its DST behaviour is T05's `Born` cell, where a
row's own time is rendered. Do not invent a case to fill the row.

### 5.5 The gate rows, proved by hand

```bash
printf 'import "package:pdf/widgets.dart" as pw;\nfinal d = pw.Document();\n' > lib/data/_scratch.dart
dart run tool/check_policy.dart ; echo "exit=$?"    # POLICY [export.pdf_document] …, exit=1
rm lib/data/_scratch.dart
```

Repeat with a planted `pw.Font.helvetica()` for `export.base_14_font`.

## 6. Constraints that bind this task

- **The five safety rules** — §12.3 is the one this task carries: the running footer is set inside the builder, on every page of every document, and no caller can suppress it. §12.1's box is T05's, and this task's job is that `titleBoxUnderHeading` exists so that T05 cannot place the box *instead of* the footer.
- **R60 — no human-facing date is all-numeric.** A PDF is read by a human and has no ISO column beside it. This binds every format string in the file.
- **Offline** — no network path may be added, and this is the task where one could be. `pdf` has no HTTP client; `printing` does, and is banned by name. G2 (the dependency allowlist) and G3 (the `PdfGoogleFonts` / `networkImage` scan) stay green, and the permission set never changes without G0's recorded evidence.
- **The print sizes are not the 3am sizes.** The 18 pt floor, the 60×60 targets and the gesture ban govern **screens**. Nothing in this file is interactive and nothing in it is read at arm's length in the dark — but the comment saying so is required, because the next reader will otherwise apply the wrong rule.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'the produced PDF embeds its font and carries the footer on every page'` passes, and was seen to fail first for the stated reason
- [ ] the font is embedded, asserted by reading the PDF
- [ ] the footer is on every page
- [ ] page numbers are present and correct
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] `pdf` is pinned at **3.13.0** from decision-record §5.1, and `pubspec.lock`'s diff was **read**, with every new transitive package accounted for in `tool/policy_allowlist.txt`
- [ ] `CONVENTIONS §1.1` rule 3 lists `package:pdf` among `lib/data/`'s permitted packages
- [ ] `export.pdf_document` and `export.base_14_font` exist, have `firesOn` entries, and were each watched to fire
- [ ] `grep -rn 'package:printing\|PdfGoogleFonts\|networkImage' lib/` returns nothing
- [ ] `grep -n "dd/MM" lib/data/pdf_writer.dart` returns nothing
- [ ] `09 §10` items 1, 2, 3 and 13 have been **run** and their answers written into the PR body — including a negative answer, if that is the answer
- [ ] the print-size comment exists and says why 7–16 pt is not a violation of the 18 pt floor

## 8. Verification

```bash
fvm flutter test test/features/pdf_writer_test.dart
make check
make test
```

Then the confinements, by hand:

```bash
grep -rn "pw.Document(\|pw.MultiPage(" lib/ --include='*.dart'
# expect exactly: lib/data/pdf_writer.dart

grep -rnE "Font\.(helvetica|times|courier|symbol|zapfDingbats)" lib/
# expect nothing

grep -rn "package:printing\|PdfGoogleFonts\|networkImage" lib/ ios/ android/
# expect nothing — this is G3's grep, run by hand
```

Then the twenty-minute font check, which no test can do for you:

```bash
fvm flutter test test/features/pdf_writer_test.dart --plain-name 'embeds its font'
# then open the artefact the test writes, in Preview AND in Acrobat, and look at
# the glyphs and the metrics. §10 item 1. Record the answer in the PR body.
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(export): the PDF builder with an embedded font`
