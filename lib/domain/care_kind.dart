// lib/domain/care_kind.dart
//
// THREE CLOSED SETS AND ONE SEALED SUBJECT. `CONVENTIONS §2.9`'s rule is that a
// Dart member and its stored key are readable off each other; a bare
// `String kind` crossing the repository boundary is exactly what that rule
// exists to prevent.
library;

import 'package:shed_book/domain/ids.dart';

/// The four care events spec §7.2 names.
///
/// **A CLOSED `CHECK`, NOT A VOCABULARY FOREIGN KEY.** `vocab_terms` holds the
/// lists the shepherd may rename and extend; this is not one of them. Each key
/// is also wired to an Android notification channel id that is **byte-identical
/// to the key and frozen at release** (decision #65, R49), so adding a fifth is
/// a schema migration AND a channel decision — the correct amount of friction.
///
/// `turnout`, `dose` and `withdrawal` are banned channel ids for the same
/// reason: there is one set of strings, `03`'s.
enum CareKind {
  colostrum('colostrum'),
  navelDip('navel_dip'),
  stomachTube('stomach_tube'),
  warmed('warmed');

  const CareKind(this.key);

  /// **Frozen** by `care_events`'
  /// `CHECK (kind IN ('colostrum','navel_dip','stomach_tube','warmed'))`, then
  /// by every CSV column, every JSON backup and every notification channel id.
  final String key;

  static CareKind fromKey(String k) => CareKind.values.firstWhere(
    (CareKind c) => c.key == k,
    orElse: () => throw FormatException('Unknown care kind', k),
  );
}

/// How the colostrum went in. **Skippable, and never defaulted** — a shepherd
/// who did not say is not claiming a teat feed.
enum ColostrumMethod {
  teat('teat'),
  tube('tube'),
  bottle('bottle');

  const ColostrumMethod(this.key);

  final String key;

  static ColostrumMethod fromKey(String k) => ColostrumMethod.values.firstWhere(
    (ColostrumMethod m) => m.key == k,
    orElse: () => throw FormatException('Unknown colostrum method', k),
  );
}

/// Who the care was given to — **exactly one of a lamb or a lambing**.
///
/// `care_events` carries `CHECK ((lambing IS NOT NULL) + (lamb IS NOT NULL) = 1)`.
/// Two nullable id parameters on `addCare` would make the unstorable
/// combinations — both set, neither set — CONSTRUCTIBLE, and the `CHECK` would
/// then fire as a `WriteFailed` at 03:20 instead of as a compile error at 09:00.
/// This is the safety-rule hierarchy applied to an ordinary column: unstorable
/// becomes unconstructible.
///
/// On Lambing Entry every care event is written against a **lamb**. The lambing
/// arm exists for care taken before any lamb is attached — warming a ewe's first
/// lamb before it is tallied — and `_lambingEntrySql`'s second `LEFT JOIN` arm
/// is what reads those back.
sealed class CareSubject {
  const CareSubject();
}

final class CareForLamb extends CareSubject {
  const CareForLamb(this.lamb);

  final LambId lamb;
}

final class CareForLambing extends CareSubject {
  const CareForLambing(this.lambing);

  final LambingId lambing;
}
