// test/support/harness.dart — the shared test seams (12 §2.1, §3.1).
//
// It grows, it does not fork. N07-T02 wraps [testConnection] in
// `testDatabase({bool seedOnCreate = true})` once AppDatabase exists; a second
// harness entry point is how two tests end up disagreeing about what "a fresh
// database" means.
library;

import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/connection.dart';
import 'package:shed_book/core/db/database.dart';

/// Runs [body] with the ambient clock pinned to [instant].
///
/// 12 §2.1: pin `now` and offset the SEED DATA to the instant you want, rather
/// than asserting on a moving clock. A test that reads the real time is a test
/// that fails at midnight, in March, once.
T atFixed<T>(DateTime instant, T Function() body) => withClock(Clock.fixed(instant), body);

/// An in-memory connection with the seven pragmas applied.
///
/// `NativeDatabase.memory(setup: configureConnection)` — the same function the
/// app passes, not a copy of it, so a pragma that stops being applied in
/// production stops being applied here too.
///
/// **`closeStreamsSynchronously: true`** is the trap this helper exists to
/// close: without it a stream still open at the end of a test is torn down
/// asynchronously, after the test has finished, and the failure surfaces in
/// whichever test happens to run next under
/// `--test-randomize-ordering-seed random`.
DatabaseConnection testConnection() => DatabaseConnection(
  NativeDatabase.memory(setup: configureConnection),
  closeStreamsSynchronously: true,
);

/// A fresh in-memory [AppDatabase], closed when the test ends.
///
/// **The one harness entry point**, grown rather than forked: N07-T01 landed
/// [testConnection] because AppDatabase did not exist yet, and this wraps it.
/// Two entry points is how two tests end up disagreeing about what "a fresh
/// database" means.
///
/// `addTearDown(db.close)` is inside the helper rather than at each call site,
/// because the call site that forgets it leaks a database into the next test and
/// the failure lands somewhere else entirely.
AppDatabase testDatabase({bool seedOnCreate = true}) {
  final AppDatabase db = AppDatabase(testConnection(), seedOnCreate: seedOnCreate);
  addTearDown(db.close);
  return db;
}
