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

/// **60, NOT 120** (`04 §4.4`, decision-record §7.0 ruling 18). AAC-LC mono at
/// 32 kbps is ~240 KB at 60 s against ~480 KB at 120 s, on a typical-season
/// media figure of ~300 MB. 60 is chosen as the RECOVERABLE direction rather
/// than the cheap one: raising a cap orphans nothing, whereas lowering one makes
/// recordings that already exist unreproducible.
const int kVoiceNoteMaxSeconds = 60;

/// AAC-LC mono at 32 kbps — speech in a shed, not music.
const int kVoiceNoteBitRate = 32000;

/// Mono. A second channel doubles the bytes and carries nothing: the shepherd
/// is talking into the phone in their own hand.
const int kVoiceNoteChannels = 1;

const int kVoiceNoteSampleRate = 44100;
