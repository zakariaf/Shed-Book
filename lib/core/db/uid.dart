import 'package:uuid/uuid.dart';

const Uuid _uuid = Uuid();

/// The identity that survives export → re-import.
///
/// **The only `package:uuid` call site in the app** (R15), which is why it lives
/// here and not beside the id extension types in `lib/domain/ids.dart`:
/// `lib/domain/` may not import the package at all.
///
/// v7, not v4. A v7 uid is time-ordered, so `uid` sorts the way the rows were
/// written — which makes a JSON backup diffable and an index on it useful,
/// where v4 would scatter.
String newUid() => _uuid.v7();
