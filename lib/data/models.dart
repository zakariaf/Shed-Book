/// The **only** way a screen ever sees a drift row class (R20).
///
/// `lib/features/` may not import `lib/core/db/`, so this re-export is the one
/// legal concentration point — and it is deliberately a `show` list rather than
/// a blanket export, so what crosses the boundary is a decision somebody made
/// rather than everything the generator happened to emit.
///
/// **Empty of names today, on purpose.** N07-T03 through N07-T06 add row classes
/// as their clusters land. A blanket `export 'package:shed_book/core/db/database.dart';`
/// would compile now and would quietly widen with every future table.
library;
