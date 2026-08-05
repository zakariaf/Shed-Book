# App review notes — attached to every submission

> `11 §9.5`, verbatim. **Nothing in the app may depend on this being read**: reviewers test on a
> networked device, in a simulator, in a few minutes, and may never open this box. It exists to answer
> the question a reviewer is most likely to ask, not to excuse anything.

---

Shed Book is an offline notebook for shepherds recording lambings, treatments and pen movements
during the lambing season. It has no account, no server and no sync.

**There is nothing to sign in to.** The app opens straight onto its entry screen with an empty
notebook. To exercise it: tap the keypad to enter an ear-tag number such as `412`, confirm, and tap
LAMBING to record a birth. Everything is stored in a local SQLite database.

**The single in-app purchase is a non-consumable unlock**, product id `shed_book_unlock`. The free
version holds one season and fifteen animals; the unlock removes both limits. It is bought once, it
restores, and there is no subscription. **Restore purchases** is in Settings ▸ Unlock, above the
purchase action.

**The Android build ships without the internet permission.** It is removed from the merged manifest
with `tools:node="remove"` because Google Play Billing's telemetry transport contributes it
transitively. The iOS build has no network code. Records leave the phone only when the user
deliberately exports a CSV or PDF and shares it through the system share sheet.

**Camera, photo library and microphone** are used to attach a photo or a voice note to a record. Each
is requested only when the user taps that specific action, and the app is fully usable if all three
are declined.
