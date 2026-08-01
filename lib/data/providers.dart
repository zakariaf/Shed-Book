// lib/data/providers.dart — the DI root.
//
// MINIMUM SURFACE. N12-T01 grows this into the real graph; what is here is the
// one provider app.dart's boot kick names, so that kick can exist and be tested
// before the graph does.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shed_book/core/db/connection.dart';
import 'package:shed_book/core/db/database.dart';

/// The database, opened **after the first frame** and never before it.
///
/// `main()` awaits nothing and `app.dart` kicks this from a post-frame callback
/// (`01 §6.3`). Making it a `FutureProvider` rather than something `main()`
/// awaits is what keeps the first painted frame the page colour: an `await`
/// before `runApp` is a frame the shepherd spends looking at the platform's
/// launch colour.
final FutureProvider<AppDatabase> databaseProvider = FutureProvider<AppDatabase>((Ref ref) async {
  final AppDatabase db = await openAppDatabase();
  ref.onDispose(db.close);
  return db;
});
