// test/support/reads.dart — READERS.
//
// `12 §5.3`'s third support file. It exists so an assertion never carries a
// `select` or a `jsonDecode` walk inline: a test that reads the database in its
// own body is a test whose failure message is about drift rather than about the
// claim.
//
// Three of the six today. `readLambs`, `readLamb` and `countTreatments` land
// with the epics that first need them, and `findColumn` over the committed
// schema JSON lands with N33's tier.
library;

import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/domain/ids.dart';

Future<Lambing> readLambing(AppDatabase db, LambingId id) =>
    (db.select(db.lambings)..where(($LambingsTable t) => t.id.equals(id.value))).getSingle();

Future<Lambing> readLambingByUid(AppDatabase db, String uid) =>
    (db.select(db.lambings)..where(($LambingsTable t) => t.uid.equals(uid))).getSingle();

Future<int> countLambings(AppDatabase db) async => (await db.select(db.lambings).get()).length;
