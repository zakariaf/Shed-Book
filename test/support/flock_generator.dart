// test/support/flock_generator.dart — a re-export, and the direction matters.
//
// The implementation lives in `tool/flock_generator.dart` because
// **`tool/seed.dart` is a plain Dart script and cannot import from `test/`**.
// `12 §5.3` names this path as the twelfth support file and T04's §5.2 names the
// `tool/` one; both are satisfied by putting the code where the script can reach
// it and the name where the file list expects it.
//
// One generator, two callers: the seed script and N23-T07's round-trip property.
// Two generators would be two definitions of *plausible*.
library;

export '../../tool/flock_generator.dart';
