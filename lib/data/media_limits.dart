// lib/data/media_limits.dart — the media caps, in one place.
//
// CONVENTIONS §1 gives this file to "kVoiceNoteMaxSeconds and the other media
// caps". A bare 2048 at the call site is a magic size and a build-breaking
// defect: the number has to be nameable so that changing it is one edit and one
// diff rather than a search.

/// Decision #40. The LONGEST edge, not the width — see `CameraService`'s
/// derivation for why that distinction is load-bearing.
const int kPhotoLongestEdgePx = 2048;

/// Decision #40.
const int kPhotoJpegQuality = 80;

/// The per-file ceiling `04 §4.4` asserts.
///
/// **NOT QUOTED ANYWHERE USER-FACING**, and not asserted in a unit test either:
/// it is a claim about what a real encoder produces from a real frame, which is
/// a device measurement. `docs/perf/measurements.md` is where it lands.
const int kPhotoMaxBytes = 900 * 1024;
