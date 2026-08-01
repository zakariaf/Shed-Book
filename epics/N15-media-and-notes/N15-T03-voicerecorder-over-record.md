# N15-T03 — `VoiceRecorder` over `record`

| | |
|---|---|
| **Epic** | [N15 — Media and notes](epic.md) · `00-README` §9 step 6 (1 of 5) |
| **Task** | 3 of 6 |
| **Depends on** | N15-T02 |
| **Commit** | one commit · `feat(gateway): VoiceRecorder, AAC-LC and capped` |

## 1. Why this task exists

AAC-LC `.m4a`, **never opus** — because the file has to open on the vet's laptop and in a
mail client, not only on the phone that made it — with `kVoiceNoteMaxSeconds` from N00-T02's ruling.

The codec is not a preference. `record` containers Opus as **OGG on Android** and **CAF on iOS**;
those two files are not interchangeable, so a backup made on an Android phone would not play after a
restore onto an iPhone — and cross-device restore is the entire point of spec §7.9. AAC-LC produces
MPEG-4 `.m4a` on both platforms, playable by both, and is what the OS voice-memo apps use.

The cap is not a preference either. It lives **in the gateway**, on a one-shot `Timer`, because a UI
countdown ring can be starved by a rebuild storm or a slow frame and a gateway cannot — and because
the storage budget is arithmetic the screen has no business owning: at 32 kbps mono the rate is
4 KB/s ⇒ **~240 KB per minute**, and 400 notes averaging 30 s is ~48 MB.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/08-platform-integration.md` | §4 | `VoiceRecorder` printed in full — the class name, `RecordConfig`, the one-shot cap `Timer`, `onCapReached`, `levelDbfs`, the row-at-start ordering, the truncated-`.m4a` honesty rule, and the 3am control shape |
| `docs/engineering/08-platform-integration.md` | §1.1, §8.2, §8.3, §9 | no plugin type crosses the boundary; the microphone prompt at the first tap and never at launch; `RECORD_AUDIO` is the one merged permission; the `media.opus` gate row |
| `docs/engineering/04-migrations-media-backup-restore.md` | §4.4 | the `record` snippet, `kVoiceNoteMaxSeconds` in `lib/data/media_limits.dart`, and **ship 60** until the owner answers |
| `docs/engineering/04-migrations-media-backup-restore.md` | §4.5, §4.7 | the write-ordering rule the audio path refines, and the voice-note storage rows at 60 s and 120 s |
| `docs/engineering/00-README.md` | §5.2 item 18 | *"Voice note cap: 60 s or 120 s? Drives the storage budget."* — open, owner's, and blocking nothing because the constant is one line |
| `docs/engineering/CONVENTIONS.md` | §2.12, §3.1, §1, R9, R47 | the class and its file, `voiceRecorderProvider`, `media_limits.dart`'s place in the tree |
| `docs/engineering/12-testing.md` | §4.2, §5.1 | `FakeVoiceRecorder` records scripted recordings and elapsed seconds; its tripwire is a recording longer than the cap |
| `docs/research/00-tech-decisions.md` | §5 | `record` **7.1.1** — *"class is `AudioRecorder`, AAC-LC `.m4a`, **never opus**"* (#76, #40) |
| `shed-book-spec.md` | §7.2, §5 | the optional voice note; press-and-hold is banned |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-platform-gateways` | the recorder seam, its one merged permission, and the fake that carries the cap as a tripwire |
| `indelible-controls` | the record control is tap-to-start / tap-to-stop with a level meter — this gateway's surface is what makes that buildable, and `levelDbfs` exists for no other consumer |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/data/voice_recorder_test.dart`
- **Test** — `'a recording is AAC-LC m4a and stops at kVoiceNoteMaxSeconds'`
- **Assertion, spelled out** — start a recording through `VoiceRecorder.start()` against an injected
  `AudioRecorder`, and assert the `RecordConfig` it was handed names `AudioEncoder.aacLc` (never
  `opus`), `bitRate` 32000, `numChannels` 1, `sampleRate` 44100, and a path ending `.m4a` that came
  from `MediaStore.newRelativePath('m4a')`. Then advance the `FakeAsync` zone by exactly
  `kVoiceNoteMaxSeconds` and assert `onCapReached` fired **once**, with the same path `stop()` would
  have returned, and that a further advance fires nothing. Read the container brand out of the bytes
  with `_ftypBrand`, a private top-level reader in this same test file, and assert it is an MPEG-4
  brand and not `OggS`; prove the reader is not vacuous in the same file by running it over
  `_oggHeader()` and asserting it refuses.
- **Why it is red today** — nothing records audio: there is no `VoiceRecorder`, so the codec, the container and the length cap are all unspecified and unenforced.

```bash
fvm flutter test test/data/voice_recorder_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — the gateway, the codec configuration, the cap, and `FakeVoiceRecorder` joining the
override list.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

No schema step and no domain step: `media_assets.kind` already carries `CHECK (kind IN ('photo','voice'))`
from N07-T06, and `duration_ms` already exists. This task stores nothing itself — T04 writes the row.

| # | File | What changes, and why |
|---|---|---|
| 1 | `lib/data/media_limits.dart` | Edit: add `kVoiceNoteMaxSeconds = 60` beside T02's photo caps, plus the three `RecordConfig` values so the call site holds no magic number. **60, not 120** — gotcha 4. |
| 2 | `lib/data/voice_recorder.dart` | **New.** `final class VoiceRecorder`. The **only** `package:record` import site in the app (R9, R47, `layer.plugin_record`). |
| 3 | `lib/data/providers.dart` | Edit: add `voiceRecorderProvider` — `Provider<VoiceRecorder>`, keepAlive, `CONVENTIONS` §3.1. |
| 4 | `test/support/fake_voice_recorder.dart` | **New.** `FakeVoiceRecorder implements VoiceRecorder` — scripted recordings and elapsed seconds, throwing on one longer than the cap. |
| 5 | `test/support/harness.dart` | Edit: `shedContainer()` gains `FakeVoiceRecorder? recorder` and `voiceRecorderProvider.overrideWithValue(recorder ?? FakeVoiceRecorder())`. With this commit the override list holds **three** of `12 §5.1`'s seven. |
| 6 | `test/data/voice_recorder_test.dart` | **New.** The anchor plus §5.4's cases — and the private top-level helpers `_ftypBrand(List<int>)`, `_mp4Header()` and `_oggHeader()`, which live **in this file**: `12 §5.3` closes `test/support/` at twelve files and gives one-file helpers exactly this home. |
| 7 | `test/domain/uk_zone/media_shard_dst_test.dart` | Edit: the cap-across-the-fallback case. |

### 5.2 The signatures

From 08 §4, with the constants lifted out of the call site:

```dart
// lib/data/media_limits.dart
const int kVoiceNoteMaxSeconds = 60;      // 04 §4.4: ship 60 until §7.1 #18 is answered
const int kVoiceNoteBitRate    = 32000;   // mono speech ⇒ 4 KB/s ⇒ ~240 KB/minute
const int kVoiceNoteChannels   = 1;
const int kVoiceNoteSampleRate = 44100;
```

```dart
// lib/data/voice_recorder.dart
// The class is `AudioRecorder`. `Record` was renamed in 5.0.0.
final class VoiceRecorder {
  VoiceRecorder([AudioRecorder? recorder]);

  /// Prompts for RECORD_AUDIO / NSMicrophoneUsageDescription natively.
  /// Called on the FIRST tap of the record button and never earlier.
  Future<bool> hasPermission();

  /// `onCapReached` fires if the cap stops the recording before the shepherd
  /// does; the write controller uses it to update the row exactly as it would
  /// on a manual stop, so there is no second code path for a capped note.
  Future<void> start(
    String absolutePath, {
    required void Function(String? path) onCapReached,
  });

  Future<String?> stop();
  Future<void> cancel();
  Future<bool> isRecording();

  /// dBFS, not the plugin's `Amplitude` — no plugin type crosses the
  /// boundary (08 §1.1). The level meter is the only consumer.
  Stream<double> levelDbfs(Duration interval);
}
```

```dart
// lib/data/providers.dart
final voiceRecorderProvider = Provider<VoiceRecorder>((ref) => VoiceRecorder());
```

The configuration, exactly:

```dart
await _recorder.start(
  const RecordConfig(
    encoder: AudioEncoder.aacLc,        // NEVER opus — gotcha 2
    bitRate: kVoiceNoteBitRate,
    sampleRate: kVoiceNoteSampleRate,
    numChannels: kVoiceNoteChannels,
  ),
  path: absolutePath,
);
_cap = Timer(const Duration(seconds: kVoiceNoteMaxSeconds),
    () async => onCapReached(await stop()));
```

### 5.3 The details that are easy to get wrong

1. **The class is `AudioRecorder`, not `Record`.** It was renamed in `record` 5.0.0 and this project
   is on **7.1.1**. Every snippet on the internet older than that constructs `Record()`, which does
   not exist; and `record`'s own README history is the reason 08 §1.1 lists plugin churn as the second
   argument for the gateway pattern.
2. **`AudioEncoder.opus` is a build-breaking defect, not a taste question.** OGG on Android, CAF on
   iOS: a backup made on one and restored onto the other yields a file the phone cannot open, which
   defeats spec §7.9. `media.opus` is the `check_policy` row and §8 below plants it to watch it fire.
3. **The cap is a `Duration` on a one-shot `Timer`, not wall-clock arithmetic.** Anything of the form
   *"stop when `appNow()` is past start + 60 s"* computed against local civil time is an hour wrong at
   the October fallback and an hour wrong the other way in March. The policy rule bans
   `Timer.periodic(`; it does not ban `Timer(`, and this is the one place a bare `Timer(` is correct.
   §5.4 has the DST case.
4. **Ship 60, not 120.** `00-README` §5.2 item 18 is open and it is the owner's. 04 §4.4 gives the
   reasoning and it is asymmetric: **raising a cap orphans nothing; lowering one makes existing
   recordings unreproducible.** One constant in `lib/data/media_limits.dart`, referenced everywhere
   including the storage-budget test, so the owner's answer is a one-line change and not a migration.
5. **The `media_assets` row is inserted when recording *starts*, not when it stops** (08 §4), which is
   the audio refinement of 04 §4.5's ordering. The file exists from the moment `start()` returns, so a
   phone death mid-note must leave a **linked, truncated** file rather than an orphan the sweeper
   removes. `byte_size` is written on `stop()`. The insert itself is T04's; the contract is set here,
   and getting it backwards produces a file the sweeper trashes and a note the shepherd remembers
   making.
6. **Do not route the recording through `MediaStore.writeAtomically`, and this is not an
   inconsistency.** `record` writes the file itself, so the recorder is handed
   `resolve(newRelativePath('m4a')).path` and writes straight to the final name. Writing to
   `<target>.part` would be *worse*: `MediaSweeper.sweepOrphanFiles()` (N23-T03) deletes `.part` files
   outright because nothing ever referenced them — and here something does, from the first second.
   The atomicity guarantee that matters for a photo is exactly the wrong guarantee for a recording.
7. **Be honest about what a truncated `.m4a` is.** MPEG-4 finalisation writes the `moov` atom at the
   *end*, so a note interrupted by a process kill may not be playable at all. A `media_assets` row
   with `byte_size` still `0` renders *"Recording interrupted"* and offers **Delete, not Play**. The
   app must never claim otherwise — offering Play on a file that cannot open is the app asserting
   something it cannot see.
8. **`stop()` and `cancel()` must both cancel the cap timer, and `stop()` must be idempotent.** A
   timer left alive after a manual stop fires `onCapReached` on a recording that has already ended,
   which writes `byte_size` twice and, worse, calls `stop()` on an idle recorder. Null the field as
   well as cancelling it, so `isRecording()` and the timer cannot disagree.
9. **`levelDbfs` returns `double`, never the plugin's `Amplitude`.** A single `Amplitude` in a return
   type drags `package:record` into `lib/features/` and makes `layer.plugin_record` unsatisfiable —
   08 §1.1's confinement rule and its plugin-free public surface are the same rule seen from two ends.
   The meter is not decoration: the shepherd cannot read a small icon through a freezer bag and needs
   to see at a glance that it is actually recording.
10. **Press-and-hold is banned** (#101, spec §5, the gesture list in `CLAUDE.md`). The control is a
    tap-to-start / tap-to-stop toggle at ≥ 60 pt — Indelible builds 64 × 64 — with an unmissable state
    change. `isRecording()` is the source of truth for that state, not a `bool` field on a widget: a
    rebuild resets the field and the gateway keeps recording.
11. **The microphone permission is requested at the first tap of the record button and never at
    launch.** `AudioRecorder.hasPermission()` prompts natively; there is no `permission_handler`
    (decision #78). `record_android`'s manifest merges exactly one permission — `RECORD_AUDIO`, no
    foreground service, no `MODIFY_AUDIO_SETTINGS`, no provider, no receiver. iOS needs
    `NSMicrophoneUsageDescription` and nothing else, and that key is **N31-T04's**, not this task's.
12. **This epic is what puts `RECORD_AUDIO` into the merged manifest, and no CI job will notice.** The
    `android` job and G1 arrive at N31-T03. `RECORD_AUDIO` is expected — it is on decision-record
    §3.3's list — but *"expected"* and *"asserted"* are different words. The epic's PR body carries the
    one-off `manifest-merger-release-report.txt` read; do not skip it because the permission is on a
    list somebody wrote in July.
13. **`record` is a native plugin with no Dart fallback.** `AudioRecorder.start()` throws
    `MissingPluginException` under `flutter_test`, so the unit tier asserts the *configuration* through
    the injected `AudioRecorder` and reads container bytes from a fixture the test builds. The
    device-tier check — that a real 10-second recording opens in the OS voice-memo app on both
    platforms — belongs beside T02's photo measurement in `docs/perf/measurements.md`.
14. **`FakeVoiceRecorder` `implements`, never `extends`, and its tripwire is the cap** (`12 §4.2`). A
    scripted recording longer than `kVoiceNoteMaxSeconds` throws a `StateError` naming the constant,
    so a screen test that fakes a 90-second note fails loudly instead of proving a UI that cannot
    happen.

### 5.4 The test set this task ends with

| File | Case | Edge it covers |
|---|---|---|
| `test/data/voice_recorder_test.dart` | `'a recording is AAC-LC m4a and stops at kVoiceNoteMaxSeconds'` | The anchor: codec, container, config and the cap. |
| | `'_ftypBrand accepts an MPEG-4 header and refuses an OggS header'` | Proves the container assertion is not vacuous — the one way this test could pass while asserting nothing. |
| | `'the RecordConfig names aacLc, 32000, 1 channel and 44100, all from media_limits'` | No magic number at the call site; the encoder is asserted by identity, not by string. |
| | `'the path passed to the plugin is resolve(newRelativePath("m4a")) and ends .m4a, not .part'` | Gotcha 6, which reads like a bug until you know why. |
| | `'stop cancels the cap and onCapReached never fires afterwards'` | Advance the zone past the cap after a manual stop; assert zero calls. |
| | `'a second stop is a no-op and does not call the plugin twice'` | Idempotence. Double-tap is a real event at 3am and `guard()` is one layer up. |
| | `'cancel cancels the cap and removes the partially written file'` | The user changed their mind; nothing is left for the sweeper to find. |
| | `'the cap fires exactly once and reports the same path a manual stop would'` | 08 §4's *"no second code path for a capped note"*. |
| | `'constructing VoiceRecorder and reading voiceRecorderProvider requests no permission'` | Spec §5's zero interruptions: the prompt belongs to the first tap, not to the DI graph. |
| | `'levelDbfs emits doubles and no Amplitude appears in the public surface'` | The boundary rule, asserted where a refactor would break it. |
| | `'FakeVoiceRecorder throws naming kVoiceNoteMaxSeconds on a 90-second scripted recording'` | The tripwire fires, so every widget test above it inherits the cap. |
| `test/support/harness_test.dart` | `'shedContainer resolves voiceRecorderProvider to FakeVoiceRecorder, and the override list now holds three fakes'` | The third of seven landed in this commit. |
| `test/domain/uk_zone/media_shard_dst_test.dart` | `'a recording started at 01:30:30 on 25 October 2026 is capped 60 seconds later, not an hour and 60 seconds later'` | `@Tags(['uk-zone'])`, `TZ=Europe/London`. The wall clock repeats 01:00–01:59; a cap computed from civil time waits 3660 s and produces a ~14 MB file the storage budget never accounted for. |
| | `'a recording started at 00:59:45 GMT on 1 November 2026 shards to 2026/11'` | The recording spans a minute boundary and a day is not involved — proves the shard is minted once, at start, and not re-derived on stop. |

## 6. Constraints that bind this task

- **Cross-platform restore** — the codec choice is a backup-integrity decision, not an audio one. AAC-LC in `.m4a` is the only configuration that survives an Android → iPhone restore, and spec §7.9 is the reason the product has any recovery story at all.
- **3am** — every interactive element ≥ 64 × 64 with ≥ the ruled separation, 18 px text floor, dark only, and none of the banned gestures: no swipe, no drag, no long-press, no pinch, no slider. Press-and-hold to record is the specific temptation here and it is banned by name (#101).
- **Accessibility and the ARB, authored here** — every string in `app_en.arb` with a `description`, every element a `semanticLabel` and a `<screen>.<element>` key, every heading a `headingLevel:`. There is no later sweep that adds them; N33 only verifies. This task authors **no** ARB string — a gateway renders nothing — but it fixes the two states the control must be able to say: *recording* (from `isRecording()`) and *interrupted* (from `byte_size == 0`).
- **Offline** — no network path may be added. G2 (the dependency allowlist) and G3 (the import scan) stay green, and the permission set never changes without G0's recorded evidence. This is the task that adds `RECORD_AUDIO` to the merged manifest; it is on decision-record §3.3's list and **nothing in CI checks that until N31-T03**.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name. It is a **voice note**, never a "recording" in user-facing copy and never a "memo".

## 7. Definition of Done

- [ ] `'a recording is AAC-LC m4a and stops at kVoiceNoteMaxSeconds'` passes, and was seen to fail first for the stated reason
- [ ] AAC-LC `.m4a`, asserted by reading the container
- [ ] the cap is enforced by the gateway, not by the screen
- [ ] the microphone permission is requested at first use, never at launch
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
# 1. Red first, then green.
fvm flutter test test/data/voice_recorder_test.dart

# 2. The cap across the October fallback.
TZ=Europe/London fvm flutter test --tags uk-zone

# 3. Three of the seven fakes are now on the override list.
fvm flutter test test/support/harness_test.dart test/data/
grep -c overrideWithValue test/support/harness.dart      # expect: 3

# 4. Watch both gate rows fire, then revert.
printf "// encoder: AudioEncoder.opus\n" >> lib/data/voice_recorder.dart
dart tool/check_policy.dart ; echo "exit=$?"   # POLICY [media.opus] …, exit=1
git checkout -- lib/data/voice_recorder.dart

printf "import 'package:record/record.dart';\n" > lib/features/quick_entry/_plant.dart
dart tool/check_policy.dart ; echo "exit=$?"   # POLICY [layer.plugin_record] …, exit=1
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
3. **Commit** — `feat(gateway): VoiceRecorder, AAC-LC and capped`
