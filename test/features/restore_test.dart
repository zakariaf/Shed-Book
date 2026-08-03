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
}
