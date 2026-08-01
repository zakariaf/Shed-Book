# The offline paragraph

The single authored source of every public sentence this project makes about the offline claim.
**Nothing below is re-typed anywhere.** N21 (the export screen), N29-T07 (About) and N32-T02 (the
Play and App Store listing drafts) quote this file, on the same discipline `CLAUDE.md` §12.3 holds
over `Disclaimers`: referenced, never re-typed.

It is authored here, in a file a test can read, rather than typed into Play Console at N32, because
store metadata is outside every scanner this project has and always will be — `13 §2.1` and `13 §12`
item 9, which puts it plainly: *"you are the gate."*

## 1. Permitted wording — decision-record §3.1, verbatim. Quoted, never edited.

> "Shed Book has no account, no server and no sync. The Android build ships without the internet permission, so the app itself cannot connect to anything. Your records only leave the phone when you deliberately export and share them."

Copied out of the decision record by machine, and `test/policy/offline_wording_test.dart` compares it
character for character at run time. If it does not fit a store field, the field gets a **shorter
sentence that is also true** — never a trimmed version of this one.

## 2. The permission-list paragraph

Gate G0 ran on 2026-08-01 and this paragraph is the consequence. It exists because a shepherd reads a
*permission list*, not a document set — write for that reader.

> Android shows every permission an app declares. Shed Book's list includes **view network
> connections**. That entry lets an app ask whether a network exists; it cannot open one. It is
> there because the Google Play billing library — the code that takes the one-time unlock payment —
> declares it, and a library's own permission is not something to strip out on a hunch. The
> permission that *would* let the app connect is **internet access**, and the Android build ships
> without it. Nothing in Shed Book can reach a network, whatever the list shows.

Three things that paragraph must keep, and one it must not acquire:

- It names what the reader will actually see — the Play Store's own wording, *view network
  connections* — not `ACCESS_NETWORK_STATE`, which means nothing to a shepherd.
- It says what the permission **cannot** do. That is the honest half, and it is the half a hedge
  would drop.
- It says who put it there. "A dependency declares it" is true; naming the billing library is what
  makes it checkable.
- It must not imply parity with iOS. **iOS merges nothing**, because iOS has no manifest permission
  model at all (`11 §3.1`, `13 §2.7`). There is no iOS permission list to explain, and a sentence
  written as though there were is a sentence nobody can verify.

## 3. Never written, anywhere public

These are listed rather than only banned, because a copywriter has to be able to recognise them. The
test that scans this folder skips the region between the two markers below and asserts separately
that the region still names all four — deleting it would otherwise make the scan trivially greener.
The markers are a comment pair rather than a code fence, so the exemption cannot be acquired by
accident, and there is at most one such region in any file.

<!-- prohibitions: these name banned phrasings, never claim them -->

- **"your data never leaves your phone"** — it does, the moment they share a CSV, which is the
  backup story this product depends on. Tier 3 of decision-record §3.1 is not claimable and never
  becomes claimable: the share sheet and the system photo picker are **other processes** with their
  own network access.
- **"offline-first"** — Shed Book is offline-**only**. Flutter's offline-first pattern is
  cache-over-network and is rejected outright (decision-record §2 row 7). The word is banned in our
  own prose, not only in public copy.
- **"a lost phone is lost data", unqualified** — banned unqualified, not banned. The qualified form,
  the one that names the export as the backup in the same sentence, is the honest sentence this
  product needs. A blanket ban would delete a true statement.
- **"verified" or "secure" about the backup checksum** — the checksum detects corruption. It is not
  a signature and nothing about it is secure. N22-T04 adds that case to the same test file.

<!-- end prohibitions -->

## 4. Who quotes this file

| Epic | What it takes |
|---|---|
| N21 | the export screen's wording |
| N29-T07 | the About screen message, authored as ARB there and quoting §1 here |
| N32-T02 | the Play and App Store listing drafts, §1 and §2 |

None of them re-types a sentence. A second copy is a copy that goes stale, and this one goes stale in
public, where both stores keep the old version.
