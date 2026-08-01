# Pre-release checklist — the ordered manual list

Load this when cutting a tag. Work it top to bottom; the order matters, because §F's **four** items
can only be done *after* upload and two of §A's can veto the release before you build anything.

Source of record: `docs/engineering/13-build-ci-release.md` §12, plus §9.1 (versioning), §9.4
(artefacts), §10 (tracks), §11 (freeze), §6.1.1 (the size row). CI proves the mechanical things —
every item below is one a pipeline structurally cannot see, and every one has bitten somebody.

## A. Before you build (any of these can stop the release)

1. **G0 is closed** — 2026-08-01, and §2.2's table carries four answers and four dates. Re-run it
   whenever the Billing Library, `androidx.core` or the plugin set moves: the record is true of one
   `pubspec.lock`, which is exactly what G1 re-checks on every push.
2. **Freeze check.** Is today between 1 February and 30 April? If yes, this release must be a defect
   that destroys or corrupts records or prevents the app opening at all (§11.1). Not a crash on a
   secondary screen, not a wrong statistic, not a layout bug. If you have to argue for it, stop and
   wait for 1 May — and then ship under May's rule: staged rollout, 10% for 72 hours.
3. **Track readiness.** If this is the first production release on a personal Play account created
   after 13 November 2023, the 12-tester / 14-day closed test must already be *finished*, not
   started (§10.2).
4. `make check`, `make test` and `make gen` are clean and every generated artefact is committed.
5. `pubspec.yaml`'s `version:` bumped to `x.y.z+1` **in the commit you tag**. Hygiene only — the tag
   is the mechanism.

## B. Build and tag

6. Tag `vX.Y.Z` and push it. `release.yml` derives `--build-name` from the tag and
   `--build-number` from `github.run_number`, writes the keystore from the `SHEDBOOK_*` secrets, runs
   G1, and archives the AAB, the symbols, `merged-manifest.xml`, the merger report and the
   `--analyze-size` JSON.
7. **Read the permission list yourself.** `bundletool dump manifest` on the artefact you are about to
   upload — not on a rebuild, not on the per-push AAB. Read the eight `uses-permission` lines and
   confirm `INTERNET` is not among them. A green G1 is not a substitute for looking.
8. **Xcode → Archive → Generate Privacy Report.** Read the aggregate report, not just your own
   `PrivacyInfo.xcprivacy`. Redo after any plugin bump and after the SwiftPM migration.
9. **Goldens.** If any changed, they were deliberately re-baselined with `make goldens-update` and
   every changed pixel was looked at. A golden that changed and nobody can say why is a red build.

## C. On a real device, before upload

10. **Airplane-mode pass.** Cold launch → save a lambing event → export a CSV → open Unlock → tap
    Restore. All five must behave. The four offline purchase paths in
    `docs/engineering/11-monetization-and-store.md` §11 are run here — nothing in CI can test a
    purchase.
11. **Dark-launch check.** No white flash: the iOS `LaunchScreen` background and the Android
    `windowBackground` are the base surface `#0B0D0E`, and the Android 12+ splash exit fade is
    disabled. This is a release-configuration bug, so no test in the suite will ever catch it.
12. **The four integration journeys** on a plugged-in phone (`make integration`). Reported, never
    blocking — but read the report.
13. **Startup on two physical devices in profile mode** — the oldest supported iPhone and the low-end
    Android, median of five cold starts, force-stopped between. Plus DB open + migrate, and the
    flock-book PDF duration for a 400-ewe book with the battery under 20%. Emulator and simulator
    numbers do not go in the file.

## D. Copy and compliance

14. **Release notes and store listing read for spec §12.2.** No dose, no diagnosis, no "you should".
    No "your data never leaves your phone" — only §2.1's wording is permitted.
    `tool/check_policy.dart` cannot see store metadata; you are the gate.
15. **"Did anything gain a network path this release?"** If a dependency was added or bumped, re-read
    its transitive graph and its merged manifest. If the answer is yes, the Apple privacy label and
    the Play Data safety form are versioned artefacts and must be updated **before** this build
    ships.
16. **First release only:** the eight notification channel ids are byte-identical to `reminders.kind`'s
    CHECK (R49) and asserted against the committed schema JSON. They are frozen from this release on.

## E. Upload

17. Upload the AAB by hand. Read the staged-rollout percentage before you confirm it. A
    freeze-clearing release goes out at 10% for 24 hours before going wider, and phased on iOS.
18. iOS: `flutter build ipa --release` on your Mac with **the same build number** the release
    workflow produced for this tag, plus `--obfuscate --split-debug-info`, then Transporter or
    `xcrun altool`.

## F. After upload — do not skip these, they are the record

19. **Archive the symbols** to `symbols-archive/<name>+<build>/{android,ios}/`, off the laptop, not in
    git. Losing them makes every stack trace from that build permanently unreadable, and it is the
    only artefact whose loss cannot be fixed by rebuilding.
20. **`docs/perf/measurements.md`**: fill the AAB arm64 **download** size from the Play Console's App
    Bundle Explorer into this release's row. It does not exist until now, which is why this step is
    here and not in CI.
21. **`RELEASES.md`**: tag, build number, both upload dates, the download size, and a note if the size
    grew. From the release after the first, an unexplained growth over 5% against the previous tag's
    archived `--analyze-size` JSON is a failure, not a note.
22. Keep the release artefacts: the `.aab`, the size JSON, `merged-manifest.xml` and the merger
    report are the evidence for the permission claim on a shipped build.
