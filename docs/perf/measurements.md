# Measurements

Numbers read off real artefacts, with the date they were read. Nothing in this file is copied from a
document; if a figure here and a document disagree, this file is right and the document is stale.

## The bundled font — `REFERENCES §22` C1 (N09-T05)

**Read 2026-08-01**, off
`assets/fonts/AtkinsonHyperlegibleNext[wght].ttf`, downloaded from the Google Fonts OFL distribution
(`google/fonts` → `ofl/atkinsonhyperlegiblenext`). `06 §5.2` requires all of this *before* the
`pubspec.yaml` `fonts:` block is written.

| What | Measured | Notes |
|---|---|---|
| **Byte count** | **114 552** bytes (111.9 KiB) | Against decision #127's < 5 MB bundled-asset budget this is **2.2%**. `06 §5.2`'s "~114 KB" was right |
| **`wght` axis** | **min 200 · default 400 · max 800** | **`06 §5.2` recorded 500–700 and that was wrong.** Read out of the `fvar` table, one axis, seven named instances |
| **Axis count** | 1 (`wght` only) | The italic face is a separate file and is **not** bundled — `indelible.md §3.3` says nothing italic |
| **`tnum`** | **present** | The feature `FontFeature.tabularFigures()` selects. Decision #98 claims it and it is confirmed |
| **Other GSUB features** | `aalt case ccmp frac locl ordn pnum sups tnum` | |
| **GPOS features** | `kern mark mkmk` | |
| **`zero` (slashed zero)** | **absent** | As `06 §5.2` warned. There is no `ss01`/`cv` variant either; `0` and `O` separate by counter shape and width alone |
| **Tables** | `GDEF GPOS GSUB HVAR MVAR OS/2 STAT avar cmap fvar gasp glyf gvar head hhea hmtx loca maxp name post prep` | `gvar` present, which is what `REFERENCES §22` B8 needs to know about for the PDF path |

### What is NOT measured, and must not be read as measured

- **The `0` / `O` check has not been run.** `06 §5.2` asks for it *"on a real device under a head torch"*
  and this session has neither. It is an open item, and the documented fallback if it fails is Inter
  (also OFL 1.1) with `FontFeature.slashedZero()` — a change that would move this file, the `fonts:`
  block, the PDF embed in `09 §4.2` and `test/flutter_test_config.dart` together.
- **`REFERENCES §22` B8** — whether `package:pdf` accepts a *variable* font at all — is **not** answered
  here. `pdf` has its own TTF parser and `fvar`/`gvar` may not survive it. The font ships `gvar`, so
  the question is live. It belongs to the export epic, not to N09.
