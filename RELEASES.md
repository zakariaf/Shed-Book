# Releases — Shed Book
Application id / bundle id: `com.shedbook.shedbook`

Fixed once, before the first upload, and it can never change on either store
(`13-build-ci-release.md` §3.1). One string, one spelling, three files that must
agree: `android/app/build.gradle.kts` (`namespace` and `applicationId`), the Xcode
target's `PRODUCT_BUNDLE_IDENTIFIER` in Debug, Release **and** Profile, and this
header. It carries no underscore because an Apple bundle id may not contain one
and an Android application id may not contain a hyphen — the character set the
two stores share is alphanumeric and the period. Recorded as decision #129.

Build **name** comes from the tag, always. Build **number** is always the release
workflow's run number, passed at build time. `pubspec.yaml`'s `version:` is a
local default with no authority over a store artefact; if the tag and the pubspec
disagree, the tag wins and the artefact is correct (`13 §9.1`).

| Tag | Build number | Android uploaded | iOS uploaded | AAB arm64 download | Notes |
|---|---|---|---|---|---|
| | | | | | |

No release has been cut. The first row lands at N34.
