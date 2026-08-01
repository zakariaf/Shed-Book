# N15-T02 — `CameraService` over `image_picker`

| | |
|---|---|
| **Epic** | [N15 — Media and notes](epic.md) · `00-README` §9 step 6 (1 of 5) |
| **Task** | 2 of 6 |
| **Depends on** | N15-T01 |
| **Commit** | one commit · `feat(gateway): CameraService — resized, re-encoded, EXIF dropped` |

## 1. Why this task exists

2048 px longest edge, JPEG q80, **EXIF dropped** — a photo of a ewe carries GPS otherwise,
and location data in a shared flock book is a commercially sensitive detail nobody asked to publish —
and `retrieveLostData` on resume, because Android will kill the app behind the camera.

The task is also where **R47's split becomes code**. `CameraService` wraps `image_picker` and owns
`pickImage` and `retrieveLostData`; `MediaStore` owns the `flutter_image_compress` downscale and the
write. The capture flow is three hops and each hop has exactly one owner:
**`CameraService.pick()` → `MediaStore` compresses and writes → `NoteRepository` inserts the row**
(T04). Collapsing two hops into one class is what makes the hand-written fake test half the path and
leaves the other half untested forever.

The storage arithmetic is the reason the middle hop cannot be skipped. 1200 untouched 12 MP frames is
**~3.6 GB per season**; the same 1200 at 2048 px / q80 is **≤ 1.08 GB**, and 04 §4.7 names the first
row as the failure case *"entirely self-inflicted"*. **Downscale at capture; never keep the original.**

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/08-platform-integration.md` | §3.1 | `CameraService` printed in full — `CaptureSource`, `pick()`, `retrieveLostData` first, `requestFullMetadata: false`, and the narrowing of 04 §4.4 |
| `docs/engineering/08-platform-integration.md` | §3.2 | zero merged Android permissions, and why `camera` was rejected |
| `docs/engineering/08-platform-integration.md` | §3.3 | `keepExif`, the storage table, and the per-file ceiling to assert |
| `docs/engineering/08-platform-integration.md` | §1.1, §1.2, §8.2, §9 | no plugin type crosses the boundary; `layer.plugin_image_picker`; the camera prompt fires at the first tap; the `media.keep_exif` gate row |
| `docs/engineering/04-migrations-media-backup-restore.md` | §4.4 | the three-hop capture flow, the compress call, and the **unclosed** `minWidth`/`minHeight` verification item |
| `docs/engineering/04-migrations-media-backup-restore.md` | §4.7, §4.9 | the storage budget, and *"storing the camera original"* as a named anti-pattern |
| `docs/engineering/CONVENTIONS.md` | §2.12, §3.1, R9, R47 | the class, its file, `cameraServiceProvider`, and who owns capture versus storage |
| `docs/engineering/12-testing.md` | §4.2, §4.4, §5.1 | `FakeCameraService`'s scripted results including `null` for cancel; where `mocktail` earns its keep; the override list |
| `docs/research/00-tech-decisions.md` | §5 | `image_picker` **1.2.3**, `flutter_image_compress` **2.5.1** — and #77, #40, #125 |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-platform-gateways` | wrapping an approved plugin is exactly its subject — one import site, our own enum, a fake that tests the real path |
| `indelible-controls` | it owns the capture surface `indelible.md` §7 has no component for, and this task fixes the two facts that surface must render: `recovered`, and a cancel that returns `null` |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/data/camera_service_test.dart`
- **Test** — `'a captured photo is resized, re-encoded and carries no EXIF'`
- **Assertion, spelled out** — drive `CameraService.pick(CaptureSource.camera)` with a scripted
  4032 × 3024 source, hand the result to `MediaStore`, and assert three things about what reached
  `writeAtomically`: the compressor was called with **`keepExif: false` written explicitly** and
  `quality: kPhotoJpegQuality`; the `minWidth`/`minHeight` pair was **derived from the source aspect
  ratio** so that the longest edge lands at `kPhotoLongestEdgePx` and not the shortest; and the bytes
  contain a JPEG `FFD8` start-of-image with **no `FFE1` APP1 `Exif\0\0` segment**, scanned by
  `_hasExifApp1`, a private top-level walker in this same test file. Prove the walker is not vacuous
  in the same file by running it over `_jpegWithExif()` and asserting it finds one. See gotcha 1 for
  the half of decision #40 a unit test cannot reach.
- **Why it is red today** — nothing captures a photo, and the plugin's default keeps EXIF and full resolution.

```bash
fvm flutter test test/data/camera_service_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — the gateway, the resize and re-encode, the EXIF strip, `retrieveLostData`, and
`FakeCameraService` joining the override list.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

No schema step and no domain step. `media_assets` is frozen; `CaptureSource` is a gateway enum and
belongs in `lib/data/`, not `lib/domain/`, because it exists only to keep `ImageSource` off the
boundary.

| # | File | What changes, and why |
|---|---|---|
| 1 | `lib/data/media_limits.dart` | **New.** `kPhotoLongestEdgePx = 2048`, `kPhotoJpegQuality = 80`, `kPhotoMaxBytes`. `CONVENTIONS` §1 gives this file to *"`kVoiceNoteMaxSeconds` and the other media caps"*; T03 adds the fourth. A bare `2048` at the call site is a magic size and a build-breaking defect. |
| 2 | `lib/data/camera_service.dart` | **New.** `enum CaptureSource { camera, library }` and `final class CameraService`. The **only** `package:image_picker` import site in the app (R9, R47, `layer.plugin_image_picker`). |
| 3 | `lib/data/media_store.dart` | Edit: add the downscale + write hop. This is the **only** `package:flutter_image_compress` import site (`layer.plugin_flutter_image_compress`). T01 built `writeAtomically`; this adds the method that feeds it. |
| 4 | `lib/data/providers.dart` | Edit: add `cameraServiceProvider` — `Provider<CameraService>`, keepAlive, `CONVENTIONS` §3.1. |
| 5 | `test/support/fake_camera_service.dart` | **New.** `FakeCameraService implements CameraService` — scripted results including `null` for *"the shepherd cancelled"*, and a `List<String> calls` so ordering is a plain list comparison. |
| 6 | `test/support/harness.dart` | Edit: `shedContainer()` gains `FakeCameraService? camera` and `cameraServiceProvider.overrideWithValue(camera ?? FakeCameraService())`. |
| 7 | `test/data/camera_service_test.dart` | **New.** The anchor plus §5.4's cases — and the two private top-level helpers `_hasExifApp1(List<int>)` and `_jpegWithExif()`, which live **in this file** and not in `test/support/` (gotcha 10). |
| 8 | `test/domain/uk_zone/media_shard_dst_test.dart` | Edit: the capture-ordering case at the ambiguous hour. |
| 9 | `docs/perf/measurements.md` | **New or edited.** The measured bytes and dimensions at 2048 / q80 from one portrait and one landscape frame off a real phone. Both owning documents (04 §4.4, 08 §3.3) require this before shipping and neither has closed it. |

### 5.2 The signatures

```dart
// lib/data/media_limits.dart
const int kPhotoLongestEdgePx = 2048;   // decision #40
const int kPhotoJpegQuality   = 80;     // decision #40
const int kPhotoMaxBytes      = 900 * 1024;   // the per-file ceiling 04 §4.4 asserts
```

```dart
// lib/data/camera_service.dart

/// OURS, not the plugin's `ImageSource` — no plugin type crosses the
/// boundary (08 §1.1).
enum CaptureSource { camera, library }

final class CameraService {
  CameraService([ImagePicker? picker]);

  /// Returns an absolute path in the OS's own temp area, plus whether it was
  /// recovered from a killed capture. The caller compresses and rehomes it
  /// through MediaStore; nothing else in lib/ constructs a media File.
  /// `null` means the shepherd cancelled — not an error, not an exception.
  Future<({String path, bool recovered})?> pick(CaptureSource source);
}
```

```dart
// lib/data/media_store.dart — the second hop. NEW MEMBER: neither 04 §4.4 nor
// 08 §3.3 names it, both print the call inline. Flagged in the PR body rather
// than added silently, on 08 §1.3's precedent for `RestoreService.restoreFrom`.
Future<File> writePhoto({
  required String sourcePath,     // absolute, the OS temp file image_picker returned
  required String relativePath,   // from newRelativePath('jpg')
});
```

```dart
// lib/data/providers.dart
final cameraServiceProvider = Provider<CameraService>((ref) => CameraService());
```

The compress call, from 04 §4.4, with the one parameter that must be written even though it is the
default:

```dart
final result = await FlutterImageCompress.compressAndGetFile(
  sourcePath,
  '${target.path}.part',
  minWidth: /* derived — gotcha 2 */,
  minHeight: /* derived — gotcha 2 */,
  quality: kPhotoJpegQuality,
  format: CompressFormat.jpeg,
  keepExif: false,   // the default. Written anyway so the intent is visible.
);
```

### 5.3 The details that are easy to get wrong

1. **`flutter_image_compress` is a native plugin with no Dart fallback, so half of decision #40 is
   not unit-testable and must not be pretended into a unit test.** `compressAndGetFile` throws
   `MissingPluginException` under `flutter_test`. Split the assertion honestly:
   - **Unit (this task, blocking):** the compressor is invoked through a narrow injected function on
     `MediaStore`, and the test asserts the *arguments* — `keepExif: false`, `quality:
     kPhotoJpegQuality`, `format: CompressFormat.jpeg`, and the derived `(minWidth, minHeight)` pair
     — plus that the bytes handed to `writeAtomically` carry no APP1 `Exif` segment.
   - **Device (before shipping, not blocking this PR):** open the real output and assert
     `max(width, height) <= kPhotoLongestEdgePx` and `bytes <= kPhotoMaxBytes`. This is the
     measurement 04 §4.4 and 08 §3.3 both demand and neither has taken; record it in
     `docs/perf/measurements.md`. **Do not quote the 500–900 KB figure anywhere user-facing until it
     has been measured** — 04 §4.7 labels it an estimate extrapolated from 1600 px numbers.
2. **`minWidth` and `minHeight` are documented as *minimums*, not caps.** The plugin scales
   proportionally and will not produce an image smaller than either bound, so passing `2048, 2048` may
   cap the **shorter** edge and leave the longer one above 2048 — which is the opposite of decision
   #40. Derive the pair from the source aspect ratio before compressing: for a landscape source pass
   `minWidth: kPhotoLongestEdgePx, minHeight: (kPhotoLongestEdgePx * h / w).round()`, and mirrored for
   portrait. This is 04 §4.4's live verification item and it is still open; the derivation is safe
   under either reading of the parameters, which is why you write it now rather than waiting.
3. **`retrieveLostData()` is called at the top of `pick()`, not from a resume handler.** 08 §3.1
   **narrows** 04 §4.4 here and 08 is the owning document (`CONVENTIONS` §2.12): *"a resume handler
   that recovers a photo has nowhere to put it — the attach slot that asked for it may no longer be on
   screen."* The Definition of Done's *"called on resume"* is satisfied by exactly this: the next
   `pick()` after a resume is the first moment that both a recovered file and a record to attach it to
   exist at the same time. Ask for the lost picture **first**, before offering the camera — the
   shepherd already took that photo, and making them take it twice at 3am is the failure this call
   exists to prevent.
4. **`recovered: true` is a §12.4 obligation, not a nicety.** Attaching a recovered photo without
   saying so attributes one record's photo to another, which is *silently correcting a user's entry*
   in image form. The record type must carry the flag or the screen (N16) structurally cannot print
   *"Recovered from your last photo"* beside the normal 60 pt Remove control. Not a dialog, not a
   modal, not a question.
5. **A `LostDataResponse` can carry an `exception` instead of a file, and swallowing it hides a real
   capture failure.** `lost.isEmpty` is false and `lost.file` is null in that case. Log it through
   `LocalLog` — never the message, only what you control (decision #124) — and fall through to a fresh
   `pickImage`. Returning `null` there would tell the caller *"the shepherd cancelled"*, which is a
   lie about a thing that failed.
6. **`retrieveLostData()` is documented as a no-op on iOS.** The code path still runs; it simply never
   returns a file there. Do not branch on `Platform.isAndroid` to skip it — a platform check in a
   gateway is a second source of truth about which platform loses data, and iOS's behaviour is the
   plugin's to change, not ours.
7. **`requestFullMetadata: false`, always.** The plugin documents that the microphone permission is
   never requested when this is always false. It does **not** remove the `Info.plist` keys, which App
   Store policy still requires (08 §8.4) — those are N31-T04's, and shipping the flag while forgetting
   the key set is an App Review finding.
8. **`image_picker` merges zero Android permissions and the app never asks for gallery access.**
   `image_picker_android`'s manifest declares no `uses-permission` at all; on Android 13+ the plugin
   uses the system photo picker, which grants per-URI access and needs neither `READ_MEDIA_IMAGES` nor
   `READ_MEDIA_VISUAL_USER_SELECTED`. On iOS `PHPickerViewController` needs no library authorisation.
   The **camera** path does produce one real `NSCameraUsageDescription` prompt, at first use, which the
   3am rules tolerate. If you find yourself reaching for `permission_handler`, stop: it is decision
   #78 and it is rejected.
9. **Do not add `BackgroundIsolateBinaryMessenger.ensureInitialized` speculatively.** It is needed only
   if the compressor runs off the root isolate (#125), it is `MediaStore`'s business rather than
   `CameraService`'s (08 §3.1), and nothing in this task runs off the root isolate. Adding it now is a
   line nobody can delete later because nobody remembers what it was for.
10. **The EXIF walker and its fixture are private top-level functions in the test file, not a
    thirteenth file in `test/support/`.** `12 §5.3` closes that folder at **twelve files** and gives
    the rule for exactly this case: a helper used by one file is a private top-level function *in*
    that file, because hoisting it makes every change to it a shared-harness change. Two knock-on
    points a reviewer will raise: the `token.raw_color` rule scans `lib/` for **colour** literals, so
    `0xFF, 0xD8` in a test is not a violation — pre-empt it in the commit body; and do **not** commit
    a binary `test/fixtures/*.jpg`, because `00-README` §7.1's committed-files list has no binary
    fixture kind and a JPEG built in Dart keeps the diff readable and the test self-explaining.
11. **The camera original is never kept.** The plugin's temp file belongs to the OS; the app stores
    only the compressed output under the media root. 04 §4.7's last row — 1200 originals at 3 MB,
    **~3.6 GB** — is the one number in that table that is a bug rather than a budget.
12. **`FakeCameraService` `implements`, never `extends`, and its `null` result is a first-class
    script step.** `12 §4.2` lists *"scripted `pickImage` results, including `null` for 'user
    cancelled'"* as the whole of what it records. A fake that can only succeed makes the cancel path
    untested, and cancel is the single most common outcome of a capture tap at 3am with wet hands.
13. **`mocktail` is the right tool for the ordering assertion and the wrong tool for everything else
    here** (`12 §4.4`). *"`retrieveLostData` was asked before `pickImage`"* is `verifyInOrder` over a
    mocked `ImagePicker` inside the gateway's own test; everywhere above the seam it is
    `expect(fake.calls, ['retrieveLostData', 'pickImage'])`.

### 5.4 The test set this task ends with

| File | Case | Edge it covers |
|---|---|---|
| `test/data/camera_service_test.dart` | `'a captured photo is resized, re-encoded and carries no EXIF'` | The anchor, all three clauses. |
| | `'the APP1 walker finds an Exif segment in a fixture that has one'` | Proves the negative assertion above is not vacuous — the single most likely way this test lies. |
| | `'pick asks retrieveLostData before it asks for a new photo'` | `verifyInOrder`. The whole point of the recovery path is that it comes first. |
| | `'a recovered capture returns recovered: true and the recovered path'` | The §12.4 flag exists and carries the right value. |
| | `'a lost-data response carrying an exception falls through to pickImage and is logged, not returned as a cancel'` | Gotcha 5. A failure reported as a cancel is a lie. |
| | `'pick returns null when the shepherd cancels, and writes nothing'` | The commonest outcome. Assert `FakeMediaStore` recorded zero writes. |
| | `'pickImage is called with requestFullMetadata false'` | The one flag that keeps the microphone prompt off the photo path. |
| | `'CaptureSource.camera maps to the camera and CaptureSource.library to the gallery'` | The translation at the plugin call — the only place `ImageSource` is allowed to appear. |
| | `'a 4032x3024 source and a 3024x4032 source both derive a pair whose longest edge is 2048'` | Gotcha 2, both orientations. The square case (`3000x3000`) is the third row. |
| | `'the compressor is called with keepExif false, written explicitly'` | Belt and braces with the `media.keep_exif` gate row: the gate catches `keepExif: true`, this catches the parameter being dropped entirely and defaulting. |
| | `'constructing CameraService requests no permission'` | Spec §5's zero interruptions: the prompt belongs to the first tap, not to the DI graph. |
| | `'a compress failure leaves no file under the media root and no row anywhere'` | Hands the disk-full case to T05 in a known-clean state. |
| `test/support/harness_test.dart` | `'shedContainer resolves cameraServiceProvider to FakeCameraService'` | The override landed in this commit. |
| `test/domain/uk_zone/media_shard_dst_test.dart` | `'two photos captured at the two 01:30s on 25 October 2026 sort in capture order by filename'` | `@Tags(['uk-zone'])`. The wall clock reads 01:30 twice; the uid v7 prefix is epoch milliseconds, so the filenames must still order by the instant. A v4 uid — or a filename built from the local time — silently reverses them. |

## 6. Constraints that bind this task

- **Offline** — no network path may be added. G2 (the dependency allowlist) and G3 (the import scan) stay green, and the permission set never changes without G0's recorded evidence. `image_picker` merges **zero** Android permissions; the `ModuleDependencies` service it declares is a Play Services action in a Play Services process and belongs under the decision record's tier-3 honesty (08 §3.2). It does not put `INTERNET` in our manifest.
- **Privacy** — spec §4.5 calls losses and treatment records commercially sensitive. An untouched iPhone photo carries GPS, and a CSV export accompanied by a photo of the farm's exact coordinates is a leak the shepherd never consented to. `keepExif: false` is the mechanism; `media.keep_exif` is the gate.
- **No plugin type crosses the boundary** — not `ImageSource`, not `XFile`, not `LostDataResponse`. Each would drag `package:image_picker` into `lib/features/` and make `layer.plugin_image_picker` unsatisfiable.
- **3am** — every interactive element ≥ 64 × 64 with ≥ the ruled separation, 18 px text floor, dark only, and none of the banned gestures: no swipe, no drag, no long-press, no pinch, no slider. This task builds no widget; the constraint binds it because `pick()`'s return shape is what the capture surface in N16 has to render, and a shape that cannot express *cancelled* or *recovered* forces a dialog onto the 3am path.
- **Accessibility and the ARB, authored here** — every string in `app_en.arb` with a `description`, every element a `semanticLabel` and a `<screen>.<element>` key, every heading a `headingLevel:`. There is no later sweep that adds them; N33 only verifies. This task adds **no** ARB string: a gateway renders nothing, and the recovered-photo line belongs to the screen that owns the attach slot.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'a captured photo is resized, re-encoded and carries no EXIF'` passes, and was seen to fail first for the stated reason
- [ ] longest edge 2048, JPEG q80
- [ ] no EXIF survives, asserted by reading the bytes
- [ ] `retrieveLostData` is called on resume and its result is attached to the right record
- [ ] the fake joins `pumpApp`'s override list in this commit
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
# 1. Red first, then green.
fvm flutter test test/data/camera_service_test.dart

# 2. The capture-ordering case at the ambiguous hour.
TZ=Europe/London fvm flutter test --tags uk-zone

# 3. The override landed and nothing above the seam broke.
fvm flutter test test/support/harness_test.dart test/data/

# 4. Watch both gate rows fire, then revert.
printf "// keepExif: true\n" >> lib/data/media_store.dart
dart tool/check_policy.dart ; echo "exit=$?"   # POLICY [media.keep_exif] …, exit=1
git checkout -- lib/data/media_store.dart

printf "import 'package:image_picker/image_picker.dart';\n" > lib/features/quick_entry/_plant.dart
dart tool/check_policy.dart ; echo "exit=$?"   # POLICY [layer.plugin_image_picker] …, exit=1
rm lib/features/quick_entry/_plant.dart

# 5. Nothing generated moved.
make gen && git status --short

# 6. Both gates.
make check
make test
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(gateway): CameraService — resized, re-encoded, EXIF dropped`
