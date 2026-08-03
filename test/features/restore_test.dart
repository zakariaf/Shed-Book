// test/features/restore_test.dart — the most destructive code in the app, and
// the four states an interrupted swap can leave behind.
//
// **AN APP THAT KNOWS ONLY TWO STATES REPORTS THE FIRST ROW AS SUCCESS.** That
// is the specific lie `RestoreOutcome` exists to prevent: a crash between the
// sentinel and the first rename has changed nothing at all, and telling a
// shepherd their restore worked when their old records are still there — and the
// new ones are not — is worse than telling them it failed.
//
// The fault is injected **between step 10 and step 11**, through a seam the
// service exposes for exactly this. Not a `try`/`catch` round the whole flow:
// that proves the flow can fail, which nobody doubted, and proves nothing about
// where.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shed_book/core/ui/components/shed_primary_button.dart';
import 'package:drift/native.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/core/write_outcome.dart';
import 'package:shed_book/data/backup_format.dart';
import 'package:shed_book/data/restore_service.dart';
import 'package:shed_book/features/settings/widgets/restore_confirmation.dart';

import '../support/harness.dart';

/// The three files a SQLite database is, and the reason `_moveInto` moves all
/// three: a main file reunited with a stale `-wal` is the corruption `04 §8.1`
/// describes, and it looks like a working database until it does not.
const List<String> _sidecars = <String>['', '-wal', '-shm'];

Directory _support() {
  final Directory dir = Directory.systemTemp.createTempSync('shed_support');
  addTearDown(() {
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  });
  return dir;
}

void _writeDb(Directory support, String name, String contents) {
  for (final String suffix in _sidecars) {
    File('${support.path}/$name$suffix').writeAsStringSync('$contents$suffix');
  }
}

String? _read(Directory support, String name) {
  final File f = File('${support.path}/$name');
  return f.existsSync() ? f.readAsStringSync() : null;
}

void main() {
  test('a restore interrupted before the swap leaves the live database untouched', () async {
    // THE ANCHOR. Crashed after the sentinel, before the first rename.
    final Directory support = _support();
    _writeDb(support, kLiveDatabaseName, 'ORIGINAL');
    File('${support.path}/$kRestoreSentinelName').writeAsStringSync('');

    // `(live: true, rollback: false)` — nothing has moved.
    final RestoreOutcome outcome = await completeInterruptedRestore(support);

    // **NOT `completed`, NOT `rolledBack`.** The restore did not start.
    expect(outcome, RestoreOutcome.notStarted);

    // The live file still holds the ORIGINAL rows, all three parts of it.
    for (final String suffix in _sidecars) {
      expect(_read(support, '$kLiveDatabaseName$suffix'), 'ORIGINAL$suffix');
    }

    // AND THE EVIDENCE IS CLEARED. A sentinel left behind makes the next launch
    // resolve the same state again, for ever.
    expect(File('${support.path}/$kRestoreSentinelName').existsSync(), isFalse);
    expect(Directory('${support.path}/$kRestoreStagingDir').existsSync(), isFalse);
  });

  test('a restore interrupted between the two renames is rolled back', () async {
    // `(live: false, rollback: true)` — the live file was moved aside and the
    // incoming one had not landed. The original comes back.
    final Directory support = _support();
    _writeDb(support, kRestoreRollbackName, 'ORIGINAL');
    File('${support.path}/$kRestoreSentinelName').writeAsStringSync('');

    expect(await completeInterruptedRestore(support), RestoreOutcome.rolledBack);

    for (final String suffix in _sidecars) {
      expect(_read(support, '$kLiveDatabaseName$suffix'), 'ORIGINAL$suffix');
    }
    expect(File('${support.path}/$kRestoreRollbackName').existsSync(), isFalse);
    expect(File('${support.path}/$kRestoreSentinelName').existsSync(), isFalse);
  });

  test('a restore interrupted after the second rename is a success we failed to record', () async {
    // `(live: true, rollback: true)` — the new file landed and the old one had
    // not been cleared yet. **This is `completed`**, and it is the arm that
    // most invites a wrong answer: the new file was fully validated at step 7,
    // so it is a success we merely failed to write down.
    final Directory support = _support();
    _writeDb(support, kLiveDatabaseName, 'INCOMING');
    _writeDb(support, kRestoreRollbackName, 'ORIGINAL');
    File('${support.path}/$kRestoreSentinelName').writeAsStringSync('');

    expect(await completeInterruptedRestore(support), RestoreOutcome.completed);

    expect(_read(support, kLiveDatabaseName), 'INCOMING');
    expect(
      File('${support.path}/$kRestoreRollbackName').existsSync(),
      isFalse,
      reason: 'the old file is cleared, which is what step 13 was going to do',
    );
  });

  test('both files gone is recovered from staging, and only otherwise is it fatal', () async {
    // `(live: false, rollback: false)` — mid-rename, or somebody was tidying up.
    // Staging is tried FIRST, because the validated file may still be sitting
    // there, and `lostBothFiles` is the only branch that reaches `04 §8.4`'s
    // corruption screen. Reaching it when a good file exists two directories
    // away would be the worst possible false alarm.
    final Directory recoverable = _support();
    Directory('${recoverable.path}/$kRestoreStagingDir').createSync();
    _writeDb(recoverable, '$kRestoreStagingDir/$kLiveDatabaseName', 'STAGED');
    File('${recoverable.path}/$kRestoreSentinelName').writeAsStringSync('');

    expect(await completeInterruptedRestore(recoverable), RestoreOutcome.completed);
    expect(_read(recoverable, kLiveDatabaseName), 'STAGED');

    final Directory lost = _support();
    File('${lost.path}/$kRestoreSentinelName').writeAsStringSync('');
    expect(await completeInterruptedRestore(lost), RestoreOutcome.lostBothFiles);
  });

  test('no sentinel is nothing to do, and it is the answer on every ordinary launch', () async {
    // The common case, and it must be cheap: one `existsSync` on a path that is
    // not there. This runs before the database opens, on every cold start,
    // including the 03:20 one.
    expect(await completeInterruptedRestore(_support()), RestoreOutcome.nothingToDo);
  });

  test('every move carries the -wal and the -shm with it', () async {
    // `04 §8.1`: a main file reunited with a stale write-ahead log is
    // corruption that looks like a working database until it does not. Both
    // sidecars travel in both directions, or neither does.
    final Directory support = _support();
    _writeDb(support, kRestoreRollbackName, 'ORIGINAL');
    File('${support.path}/$kRestoreSentinelName').writeAsStringSync('');

    await completeInterruptedRestore(support);

    for (final String suffix in _sidecars) {
      expect(_read(support, '$kLiveDatabaseName$suffix'), 'ORIGINAL$suffix', reason: suffix);
      expect(File('${support.path}/$kRestoreRollbackName$suffix').existsSync(), isFalse);
    }
  });

  test('notStarted is never a legal answer to "did the restore work"', () {
    // `09 §7.3`. The enum has five members and only two of them mean the
    // shepherd's records changed. Stated as an assertion so a sixth member
    // cannot be added without somebody deciding which side it is on.
    const Set<RestoreOutcome> changedTheRecords = <RestoreOutcome>{
      RestoreOutcome.completed,
      RestoreOutcome.rolledBack,
    };
    expect(RestoreOutcome.values, hasLength(5));
    expect(changedTheRecords, isNot(contains(RestoreOutcome.notStarted)));
    expect(changedTheRecords, isNot(contains(RestoreOutcome.nothingToDo)));
    expect(changedTheRecords, isNot(contains(RestoreOutcome.lostBothFiles)));
  });

  testWidgets('the confirmation names the live counts and requires two steps', (
    WidgetTester tester,
  ) async {
    // AWKWARD NUMBERS ON BOTH SIDES, and they are different on purpose:
    // rendering the backup's counts under *what is on this phone now* is the one
    // bug that makes the whole confirmation a lie, and it looks right in every
    // screenshot.
    const RestoreCounts live = (seasons: 1, ewes: 38, lambs: 41, treatments: 6);
    const RestoreCounts backup = (seasons: 3, ewes: 412, lambs: 861, treatments: 145);

    bool? answer;
    await tester.pumpApp(
      Builder(
        builder: (BuildContext context) => TextButton(
          onPressed: () async {
            answer = await showRestoreConfirmation(
              context,
              backup: backup,
              live: live,
              backupDate: '14 Jul 2026',
              backupVersion: '1.1.0',
              mediaCount: 452,
            );
          },
          child: const Text('open'),
        ),
      ),
      db: testDatabase(),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // BOTH SETS RENDER, and each carries its own numbers.
    expect(find.textContaining('412 ewes'), findsOneWidget);
    expect(find.textContaining('38 ewes'), findsOneWidget);

    // AND IN `04 §7.3`'s ORDER: gain, lose, mean, exclude, controls.
    // READ BEFORE ANY SCROLL. The dialog is taller than a small viewport at
    // default scale — which is correct: five statements before a control is the
    // point — so the order is read from the unscrolled layout.
    final double gain = tester
        .getTopLeft(find.byKey(const Key('settings.restore.backup_summary')))
        .dy;
    final double lose = tester
        .getTopLeft(find.byKey(const Key('settings.restore.live_summary')))
        .dy;
    final double mean = tester.getTopLeft(find.byKey(const Key('settings.restore.destruction'))).dy;
    final double exclude = tester
        .getTopLeft(find.byKey(const Key('settings.restore.media_notice')))
        .dy;
    final double controls = tester
        .getTopLeft(find.byKey(const Key('settings.restore.step_one')))
        .dy;
    expect(<double>[
      gain,
      lose,
      mean,
      exclude,
      controls,
    ], orderedEquals(<double>[gain, lose, mean, exclude, controls]..sort()));

    // THE MEDIA SENTENCE IS BEFORE THE CONTROLS, said in time to change the
    // decision rather than after it.
    expect(exclude, lessThan(controls));

    // STEP TWO IS NOT READY UNTIL STEP ONE IS TAKEN — and it is `refusing`
    // rather than dead, because `ShedPrimaryButton` has no disabled state and
    // `onTap` is non-nullable *"and that is the whole task"*.
    ShedPrimaryButtonState stateOfStepTwo() => tester
        .widget<ShedPrimaryButton>(find.byKey(const Key('settings.restore.replace_everything')))
        .state;

    expect(stateOfStepTwo(), ShedPrimaryButtonState.refusing);

    await tester.ensureVisible(find.byKey(const Key('settings.restore.step_one')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings.restore.step_one')));
    await tester.pumpAndSettle();
    expect(stateOfStepTwo(), ShedPrimaryButtonState.ready);
    expect(answer, isNull, reason: 'step one commits to nothing');

    await tester.closeApp();
  });

  testWidgets('a thumb that lands on step two first takes step one, and restores nothing', (
    WidgetTester tester,
  ) async {
    // Indelible's `refusing` in one case: *"what is missing, said in words…
    // `onTap` still fires: it opens the thing that is missing."* A dead
    // rectangle would announce as a disabled button, make `06 §6.3`'s geometric
    // gate skip it, and leave a cold thumb pressing something that does nothing.
    //
    // **The two-step guarantee is unchanged**: the restore still needs two
    // presses, and the first one cannot be the destructive one.
    bool? answer;
    await tester.pumpApp(
      Builder(
        builder: (BuildContext context) => TextButton(
          onPressed: () async {
            answer = await showRestoreConfirmation(
              context,
              backup: const (seasons: 3, ewes: 412, lambs: 861, treatments: 145),
              live: const (seasons: 1, ewes: 38, lambs: 41, treatments: 6),
              backupDate: '14 Jul 2026',
              backupVersion: '1.1.0',
              mediaCount: 452,
            );
          },
          child: const Text('open'),
        ),
      ),
      db: testDatabase(),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('settings.restore.replace_everything')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings.restore.replace_everything')));
    await tester.pumpAndSettle();

    expect(answer, isNull, reason: 'the first press was not the destructive one');
    expect(
      tester
          .widget<ShedPrimaryButton>(find.byKey(const Key('settings.restore.replace_everything')))
          .state,
      ShedPrimaryButtonState.ready,
      reason: 'it took step one instead of doing nothing',
    );

    // AND THE SECOND PRESS RESTORES.
    await tester.ensureVisible(find.byKey(const Key('settings.restore.replace_everything')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings.restore.replace_everything')));
    await tester.pumpAndSettle();
    expect(answer, isTrue);

    await tester.closeApp();
  });

  testWidgets('the confirmation cannot be dismissed by tapping outside it', (
    WidgetTester tester,
  ) async {
    // R85's whole reason. A `ShedBottomSheet` closes when a thumb lands outside
    // it — correct for a chooser, exactly wrong here.
    bool? answer;
    await tester.pumpApp(
      Builder(
        builder: (BuildContext context) => TextButton(
          onPressed: () async {
            answer = await showRestoreConfirmation(
              context,
              backup: const (seasons: 3, ewes: 412, lambs: 861, treatments: 145),
              live: const (seasons: 1, ewes: 38, lambs: 41, treatments: 6),
              backupDate: '14 Jul 2026',
              backupVersion: '1.1.0',
              mediaCount: 452,
            );
          },
          child: const Text('open'),
        ),
      ),
      db: testDatabase(),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('settings.restore.destruction')), findsOneWidget);
    expect(answer, isNull);

    // **AND BOTH MECHANISMS ARE ASSERTED, because the behavioural half cannot
    // tell them apart.** Drilled: flipping `barrierDismissible` to `true` left
    // this case green — `PopScope(canPop: false)` was already refusing the pop,
    // so the barrier flag was carrying nothing a test could see.
    //
    // They guard different doors. `PopScope` refuses a pop from any source,
    // including the Android back gesture; `barrierDismissible` decides whether
    // the barrier offers one at all. Relying on one silently is how the other
    // gets deleted in a tidy-up, and the tidy-up is always green.
    // COMMENTS STRIPPED FIRST, and that is the second thing this case had to
    // learn: the file's own doc comment names `canPop: false` to explain it, so
    // a raw `contains` passed while the argument said `true`. The scan reads
    // declarations, which is what every policy test in this project already
    // does and what I should have copied rather than re-derived.
    final String source = File(
      'lib/features/settings/widgets/restore_confirmation.dart',
    ).readAsLinesSync().where((String l) => !l.trimLeft().startsWith('//')).join('\n');
    expect(source, contains('barrierDismissible: false'));
    expect(source, contains('canPop: false'));

    await tester.closeApp();
  });

  testWidgets('cancel is always live and is never the destructive side', (
    WidgetTester tester,
  ) async {
    bool? answer;
    await tester.pumpApp(
      Builder(
        builder: (BuildContext context) => TextButton(
          onPressed: () async {
            answer = await showRestoreConfirmation(
              context,
              backup: const (seasons: 3, ewes: 412, lambs: 861, treatments: 145),
              live: const (seasons: 1, ewes: 38, lambs: 41, treatments: 6),
              backupDate: '14 Jul 2026',
              backupVersion: '1.1.0',
              mediaCount: 452,
            );
          },
          child: const Text('open'),
        ),
      ),
      db: testDatabase(),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // OPPOSITE SIDES OF THE SCREEN.
    final double cancel = tester.getCenter(find.byKey(const Key('settings.restore.cancel'))).dx;
    final double destroy = tester
        .getCenter(find.byKey(const Key('settings.restore.replace_everything')))
        .dx;
    expect(cancel, lessThan(destroy));

    await tester.ensureVisible(find.byKey(const Key('settings.restore.cancel')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings.restore.cancel')));
    await tester.pumpAndSettle();
    expect(answer, isFalse);

    await tester.closeApp();
  });

  test('importInto resolves every uid to a new id, and re-issues none of the old ones', () async {
    // **IDENTITY IS `uid`; INTEGER IDS ARE RE-ISSUED** (#32). The map is built as
    // each parent lands, and every `<parent>_uid` resolves against it. An
    // importer that wrote the file's integers back would produce a database
    // whose foreign keys point at whatever happens to occupy that row number.
    final AppDatabase target = testDatabase(seedOnCreate: false);

    await RestoreService(Directory.systemTemp).importInto(
      target,
      _header(counts: <String, int>{'seasons': 1, 'ewes': 2, 'lambings': 1, 'lambs': 2}),
      <String, List<Map<String, Object?>>>{
        'seasons': <Map<String, Object?>>[_season()],
        // **A DECOY EWE, FIRST.** Without it every row lands at id 1 and an
        // importer that writes a constant `1` instead of resolving the uid
        // passes — which the drill proved, and which is exactly the bug this
        // case exists to catch. The lambing points at the SECOND ewe.
        'ewes': <Map<String, Object?>>[_decoyEwe(), _ewe()],
        'lambings': <Map<String, Object?>>[_lambing()],
        'lambs': <Map<String, Object?>>[_lamb('lamb-a'), _lamb('lamb-b')],
      },
    );

    final Lambing lambing = await target.select(target.lambings).getSingle();
    final Ewe ewe = (await target.select(target.ewes).get()).firstWhere(
      (Ewe e) => e.uid == 'ewe-0000-0000-0000-0000-00000000',
    );
    final Season season = await target.select(target.seasons).getSingle();

    expect(ewe.id, isNot(1), reason: 'the decoy took id 1, so a constant would be wrong');

    // THE CHILDREN POINT AT THE PARENTS THAT LANDED, not at the file's numbers.
    expect(lambing.ewe, ewe.id);
    expect(lambing.season, season.id);
    for (final Lamb lamb in await target.select(target.lambs).get()) {
      expect(lamb.lambing, lambing.id);
      expect(lamb.birthDam, ewe.id);
    }

    // AND THE UIDS SURVIVED UNCHANGED — they are the identity, so a restore that
    // regenerated them would make the next backup a different flock.
    expect(ewe.uid, 'ewe-0000-0000-0000-0000-00000000');
    expect(
      (await target.select(target.lambs).get()).map((Lamb l) => l.uid),
      containsAll(<String>['lamb-a', 'lamb-b']),
    );

    await target.close();
  });

  test('nothing is re-stamped: created_at and updated_at come from the file', () async {
    // `09 §7.2` item 13. Freshening `updated_at` breaks byte equality on every
    // row in the database at once **and** destroys the only evidence of when a
    // record was actually made — which is the half that matters at 03:20 in
    // March, two seasons later.
    final AppDatabase target = testDatabase(seedOnCreate: false);

    await RestoreService(Directory.systemTemp).importInto(
      target,
      _header(counts: <String, int>{'seasons': 1, 'ewes': 1}),
      <String, List<Map<String, Object?>>>{
        'seasons': <Map<String, Object?>>[_season()],
        'ewes': <Map<String, Object?>>[_ewe()],
      },
    );

    final Ewe ewe = await target.select(target.ewes).getSingle();
    expect(ewe.createdAt.epochMillis, _madeAt);
    expect(ewe.updatedAt.epochMillis, _madeAt);

    await target.close();
  });

  test('a seasonless backup gets seedFirstRun, and one with a season does not', () async {
    // **GET THE CONDITION BACKWARDS AND EVERY RESTORED DATABASE GAINS A SEED
    // NOBODY ASKED FOR** — and N23-T07's round trip then fails, because the
    // vocabulary rows it wrote are not the ones the file carried.
    //
    // **AND `seedFirstRun` SEEDS NO SEASON.** The task's reason for this branch
    // is *"every event table's `season` is `NOT NULL`, so a seasonless restored
    // database cannot accept a lambing"* — which is true, and the seed does not
    // fix it: it seeds the forty vocabulary rows, the reminder rules and the two
    // singletons, and no season. Measured, not assumed.
    //
    // A backup with no season restores to a database with no season, and the
    // first lambing is refused until one exists. That is arguably correct — the
    // app must not invent a season a shepherd did not name — but it is NOT what
    // the task says the branch is for, and it is recorded here rather than
    // resolved by widening `seedFirstRun` on the restore path of all places.
    final AppDatabase empty = testDatabase(seedOnCreate: false);
    await RestoreService(Directory.systemTemp).importInto(
      empty,
      _header(counts: const <String, int>{}),
      const <String, List<Map<String, Object?>>>{},
    );
    expect(
      await empty.select(empty.vocabTerms).get(),
      isNotEmpty,
      reason: 'the seed is what makes a seasonless database usable at all',
    );
    expect(
      await empty.select(empty.seasons).get(),
      isEmpty,
      reason: 'and it seeds no season — the app does not invent one',
    );
    await empty.close();

    final AppDatabase withSeason = testDatabase(seedOnCreate: false);
    await RestoreService(Directory.systemTemp).importInto(
      withSeason,
      _header(counts: <String, int>{'seasons': 1}),
      <String, List<Map<String, Object?>>>{
        'seasons': <Map<String, Object?>>[_season()],
      },
    );
    expect(
      (await withSeason.select(withSeason.seasons).getSingle()).uid,
      'season-0000-0000-0000-0000-0000000',
      reason: 'the shepherd\'s own season, and no phantom beside it',
    );
    expect(
      await withSeason.select(withSeason.vocabTerms).get(),
      isEmpty,
      reason: 'and no seed ran, so the file is the only source of vocabulary',
    );
    await withSeason.close();
  });

  test('the entitlement row is skipped, and a neighbour\'s backup unlocks nothing', () async {
    // #88. It is in `kBackupExcludedTables` so it is never written — but a
    // hand-edited file can still carry one, and the importer refuses it there
    // too. A fixture whose `unlocked` is 1 imports to nothing at all.
    final AppDatabase target = testDatabase(seedOnCreate: false);

    await RestoreService(Directory.systemTemp).importInto(
      target,
      _header(counts: <String, int>{'entitlements': 1}),
      <String, List<Map<String, Object?>>>{
        'entitlements': <Map<String, Object?>>[
          <String, Object?>{'uid': 'ent', 'unlocked': 1},
        ],
      },
    );

    // **THE PROPERTY IS `unlocked = false`, NOT AN EMPTY TABLE.** `seedFirstRun`
    // creates the singleton with its default, so *empty* was the wrong
    // assertion — and the right one is stronger anyway: the neighbour's `1` did
    // not carry.
    expect(
      (await target.select(target.entitlements).getSingle()).unlocked,
      isFalse,
      reason: 'restoring a neighbour\'s backup unlocks nothing',
    );
    await target.close();
  });

  test('a vocabulary key is written as itself, never resolved as a uid', () async {
    // The five vocabulary foreign keys carry a `vocab_terms.key`, not a uid.
    // Treating one as a uid fails `foreign_key_check`, which is the GOOD
    // outcome; treating it as unknown and writing `NULL` is a silently empty
    // column, which is not.
    final AppDatabase target = testDatabase(seedOnCreate: false);

    await RestoreService(Directory.systemTemp).importInto(
      target,
      _header(counts: <String, int>{'vocab_terms': 1, 'seasons': 1, 'ewes': 1, 'lambings': 1}),
      <String, List<Map<String, Object?>>>{
        'seasons': <Map<String, Object?>>[_season()],
        'ewes': <Map<String, Object?>>[_ewe()],
        // THE TERM TRAVELS WITH THE ROW THAT USES IT. Without it the FK check
        // refuses the import — which is the GOOD outcome the document names, and
        // the first draft of this case proved it by forgetting.
        'vocab_terms': <Map<String, Object?>>[
          <String, Object?>{
            'uid': 'vocab-0000-0000-0000-0000-00000',
            'created_at': _madeAt,
            'updated_at': _madeAt,
            // The CHECK names six lists and 'presentation' is not one of them —
            // the column is 'malpresentation'. Another spelling the schema had
            // to tell me, rather than one I remembered.
            'list': 'malpresentation',
            'key': 'mp_head_back',
            'sort_order': 1,
            // 'seeded', not 'seed' — the third spelling this one row got wrong.
            'origin': 'seeded',
          },
        ],
        'lambings': <Map<String, Object?>>[
          <String, Object?>{..._lambing(), 'presentation': 'mp_head_back'},
        ],
      },
    );

    expect((await target.select(target.lambings).getSingle()).presentation, 'mp_head_back');
    await target.close();
  });

  test('restore builds a new file beside the live one and swaps it in', () async {
    // THE WHOLE OF STEPS 5 TO 14, end to end. The live file holds ORIGINAL; the
    // backup holds one ewe. Afterwards the live file is the imported one, the
    // rollback is cleared, the sentinel is gone and staging is gone.
    final Directory support = _support();
    _writeDb(support, kLiveDatabaseName, 'ORIGINAL');

    final WriteOutcome outcome = await RestoreService(support).restore(
      header: _header(counts: <String, int>{'seasons': 1, 'ewes': 1}),
      tables: <String, List<Map<String, Object?>>>{
        'seasons': <Map<String, Object?>>[_season()],
        'ewes': <Map<String, Object?>>[_ewe()],
      },
      // A REAL SQLITE FILE, opened where the service says to put it — which is
      // what makes the checkpoint assertion at step 9 mean anything.
      openStaging: (File file) async {
        file.parent.createSync(recursive: true);
        return AppDatabase(NativeDatabase(file), seedOnCreate: false);
      },
    );

    expect(outcome, isA<WriteCommitted>());

    // THE SWAP HAPPENED, and the file is the imported one rather than ORIGINAL.
    final AppDatabase reopened = AppDatabase(
      NativeDatabase(File('${support.path}/$kLiveDatabaseName')),
      seedOnCreate: false,
    );
    expect((await reopened.select(reopened.ewes).getSingle()).tag, '412');
    await reopened.close();

    // AND NOTHING IS LEFT BEHIND. A sentinel that survives makes the next launch
    // resolve a state that is over.
    expect(File('${support.path}/$kRestoreSentinelName').existsSync(), isFalse);
    expect(File('${support.path}/$kRestoreRollbackName').existsSync(), isFalse);
    expect(Directory('${support.path}/$kRestoreStagingDir').existsSync(), isFalse);
  });

  test(
    'the sentinel is written before the first rename, and a crash there is recoverable',
    () async {
      // **THE FAULT IS INJECTED BETWEEN STEP 10 AND STEP 11**, through the seam
      // the service exposes for exactly this. Not a `try`/`catch` round the whole
      // flow: that proves the flow can fail and nothing about where.
      //
      // Drilled by moving the sentinel to after the first rename — without this
      // case it passed, because nothing observed the sentinel mid-flight.
      final Directory support = _support();
      _writeDb(support, kLiveDatabaseName, 'ORIGINAL');

      bool sentinelExisted = false;

      final WriteOutcome outcome = await RestoreService(support).restore(
        header: _header(counts: <String, int>{'seasons': 1}),
        tables: <String, List<Map<String, Object?>>>{
          'seasons': <Map<String, Object?>>[_season()],
        },
        openStaging: (File file) async {
          file.parent.createSync(recursive: true);
          return AppDatabase(NativeDatabase(file), seedOnCreate: false);
        },
        afterSentinel: () async {
          sentinelExisted = File('${support.path}/$kRestoreSentinelName').existsSync();
          throw StateError('the phone died');
        },
      );

      expect(outcome, isA<WriteFailed>());
      expect(
        sentinelExisted,
        isTrue,
        reason: 'the sentinel is step 10 — the LAST non-destructive step',
      );

      // AND THE LIVE FILE IS UNTOUCHED, because step 11 never ran.
      for (final String suffix in _sidecars) {
        expect(_read(support, '$kLiveDatabaseName$suffix'), 'ORIGINAL$suffix');
      }
    },
  );

  test('a failure before the swap leaves the live database untouched', () async {
    // **EVERYTHING UP TO STEP 9 CAN BE ABANDONED WITH NOTHING LOST**, and this
    // is the case that holds it. The import throws on an unresolvable foreign
    // key; the live file must be exactly as it was.
    final Directory support = _support();
    _writeDb(support, kLiveDatabaseName, 'ORIGINAL');

    final WriteOutcome outcome = await RestoreService(support).restore(
      header: _header(counts: <String, int>{'lambings': 1}),
      tables: <String, List<Map<String, Object?>>>{
        // A lambing whose ewe and season are not in the file at all.
        'lambings': <Map<String, Object?>>[_lambing()],
      },
      openStaging: (File file) async {
        file.parent.createSync(recursive: true);
        return AppDatabase(NativeDatabase(file), seedOnCreate: false);
      },
    );

    expect(outcome, isA<WriteFailed>());

    for (final String suffix in _sidecars) {
      expect(
        _read(support, '$kLiveDatabaseName$suffix'),
        'ORIGINAL$suffix',
        reason: 'the live database is untouched',
      );
    }
    expect(
      File('${support.path}/$kRestoreSentinelName').existsSync(),
      isFalse,
      reason: 'the sentinel is step 10 and the failure was before it',
    );
    expect(Directory('${support.path}/$kRestoreStagingDir').existsSync(), isFalse);
  });
}

// ---------------------------------------------------------------------------
// Rows as the file carries them: uids, no integer ids, `<parent>_uid` pointers.
// ---------------------------------------------------------------------------

const int _madeAt = 1773446400000; // 2026-03-14T00:00Z

BackupHeader _header({required Map<String, int> counts}) => BackupHeader(
  schema: kSchemaVersion,
  appVersion: '1.0.0',
  exportedAtUtc: '2026-03-14T00:00:00.000Z',
  exportedAtOffsetMinutes: 0,
  exportedAtZoneAbbreviation: 'GMT',
  counts: counts,
  media: const BackupMedia(included: false, count: 0, bytes: 0),
);

Map<String, Object?> _season() => <String, Object?>{
  'uid': 'season-0000-0000-0000-0000-0000000',
  'created_at': _madeAt,
  'updated_at': _madeAt,
  'year': 2026,
  'label': '2026',
  'start_date': '2026-01-01',
};

/// Lands first and is pointed at by nothing — its only job is to occupy id 1.
Map<String, Object?> _decoyEwe() => <String, Object?>{
  'uid': 'decoy-0000-0000-0000-0000-0000000',
  'created_at': _madeAt,
  'updated_at': _madeAt,
  'tag': '999',
  'tag_digits': '999',
  'status': 'active',
};

Map<String, Object?> _ewe() => <String, Object?>{
  'uid': 'ewe-0000-0000-0000-0000-00000000',
  'created_at': _madeAt,
  'updated_at': _madeAt,
  'tag': '412',
  'tag_digits': '412',
  'status': 'active',
};

Map<String, Object?> _lambing() => <String, Object?>{
  'uid': 'lambing-0000-0000-0000-0000-000000',
  'created_at': _madeAt,
  'updated_at': _madeAt,
  'season_uid': 'season-0000-0000-0000-0000-0000000',
  'ewe_uid': 'ewe-0000-0000-0000-0000-00000000',
  'occurred_at': _madeAt,
  'captured_at': _madeAt,
  'local_date': '2026-03-14',
  'time_source': 'auto',
};

Map<String, Object?> _lamb(String uid) => <String, Object?>{
  'uid': uid,
  'created_at': _madeAt,
  'updated_at': _madeAt,
  'lambing_uid': 'lambing-0000-0000-0000-0000-000000',
  'birth_dam_uid': 'ewe-0000-0000-0000-0000-00000000',
  'status': 'alive',
};
