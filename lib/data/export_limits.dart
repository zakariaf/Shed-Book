// lib/data/export_limits.dart — the caps and tripwires the export path measures
// itself against.
//
// One file for all of them, because `09 §1.2` names one file — and because a
// number that lives beside the code that reads it is a number nobody else knows
// exists.
//
// **`kPdfRowsPerVolume` IS NOT HERE YET.** N21-T05 was to create this file for
// it; P15 moves the two PDF tasks to `v1.1.0`, so the file arrives with N22's
// tripwire instead and the PDF cap joins it when the flock book is built.
library;

/// 20 MB (`09 §5.7`, `04 §6.8`).
///
/// **A TRIPWIRE, NOT A LIMIT. It refuses nothing and must not.** The backup is
/// the only recovery this product has, and an export that declines to run
/// because a flock got large is an export that fails exactly the shepherd who
/// most needs it.
///
/// Crossing it means *measure before assuming this is still fine*. The fix, if
/// it is ever needed, is a streaming writer emitting one table at a time to the
/// same `IOSink` — **never an isolate**, because a drift connection cannot cross
/// an isolate boundary (#125).
const int kBackupSizeTripwireBytes = 20 * 1024 * 1024;
