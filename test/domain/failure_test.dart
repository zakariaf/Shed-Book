// test/domain/failure_test.dart — the two closed sets.
//
// Pure Dart. No TestWidgetsFlutterBinding, no database, no ProviderScope, no
// pumpWidget — these are types, and a widget binding here would be a widget
// binding somebody later relies on.
//
// Nothing here is time-shaped. T05's ResumePolicy is this epic's first
// time-shaped file and its ambiguous-hour case is written there.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/failure.dart';
import 'package:shed_book/core/write_outcome.dart';
import 'package:shed_book/domain/free_tier.dart';
import 'package:shed_book/domain/validation/warning.dart';

const String _failureFile = 'lib/core/failure.dart';
const String _outcomeFile = 'lib/core/write_outcome.dart';

String _declarations(String path) =>
    File(path).readAsLinesSync().where((String l) => !l.trimLeft().startsWith('//')).join('\n');

/// Every `ShedFailure` there is, constructed.
const List<ShedFailure> _allFailures = <ShedFailure>[
  DiskFull(),
  DatabaseUnreadable(11, 26),
  StorageWriteFailed(),
  StorageReadOnly(),
  MediaWriteFailed(),
  // **BOTH DOMAIN-OUTCOME FAILURES WERE MISSING FROM THIS LIST.**
  // `TagAlreadyInUse` landed at ruling N4 and only the exhaustive switch above
  // was updated — so the property below, which is the one that checks the
  // *words*, never saw it. A failure whose message ends without a full stop or
  // tells a shepherd to "try again" at something that cannot work would have
  // shipped. Added with `EweNotFound` at N26-T04.
  TagAlreadyInUse('412'),
  EweNotFound(),
];

void main() {
  test('ShedFailure has seven variants, WriteOutcome three, and neither is generic', () {
    // THE ANCHOR, and it is a COMPILE-TIME claim wearing a test's clothes: two
    // exhaustive switch expressions with no `default:` and no `_`. They compile
    // today and stop compiling the day a variant is added — which is the point.
    // The runtime assertions below are only there so the claim has a name in the
    // report.
    final ShedFailure failure = const DiskFull();
    final String named = switch (failure) {
      DiskFull() => 'DiskFull',
      DatabaseUnreadable() => 'DatabaseUnreadable',
      StorageWriteFailed() => 'StorageWriteFailed',
      StorageReadOnly() => 'StorageReadOnly',
      MediaWriteFailed() => 'MediaWriteFailed',
      // Added by ruling N4, and this switch is what forced the edit — it
      // stopped compiling the moment the variant landed, which is what the
      // comment above promises.
      TagAlreadyInUse() => 'TagAlreadyInUse',
      // Added by N26-T04's `setStatus`, and this switch stopped compiling the
      // moment it landed — twice now, which is the whole argument for writing
      // the anchor as an exhaustive switch rather than as a count.
      EweNotFound() => 'EweNotFound',
      UnexpectedFailure() => 'UnexpectedFailure',
    };
    expect(named, 'DiskFull');

    final WriteOutcome outcome = const WriteCommitted();
    final String kind = switch (outcome) {
      WriteCommitted() => 'committed',
      WriteFailed() => 'failed',
      WriteRefused() => 'refused',
    };
    expect(kind, 'committed');
  });

  test('no variant is named Ok or Error and no type is generic', () {
    // Cheap, and it catches the rename a refactor tool would happily perform.
    // `Error` shadows dart:core's, which produces confusing analyzer messages
    // the first time somebody writes `catch (e) { if (e is Error) … }`.
    for (final String path in <String>[_failureFile, _outcomeFile]) {
      final String source = _declarations(path);
      expect(source, isNot(matches(RegExp(r'class\s+(Ok|Error)\b'))), reason: path);
      expect(source, isNot(matches(RegExp(r'class\s+WriteOutcome\s*<'))), reason: path);
      expect(source, isNot(matches(RegExp(r'class\s+ShedFailure\s*<'))), reason: path);
    }
  });

  test('every userMessage is a non-empty sentence a shepherd could act on', () {
    // Eight variants. No stack traces, no SQLite codes, no blame — and none of
    // CONVENTIONS §5.3's banned words, including `should`, which turns a
    // statement of fact into an instruction nobody asked for.
    final List<ShedFailure> every = <ShedFailure>[
      ..._allFailures,
      UnexpectedFailure(Exception('x'), StackTrace.current),
    ];
    expect(every, hasLength(8));

    for (final ShedFailure f in every) {
      final String m = f.userMessage;
      expect(m, isNotEmpty, reason: '$f');
      expect(m.trim(), endsWith('.'), reason: '$f');
      expect(m, isNot(contains('Exception')), reason: '$f');
      expect(m, isNot(contains('null')), reason: '$f');
      expect(m, isNot(contains('#0')), reason: '$f');
      // **NO CODE LEAKS — BUT THE SHEPHERD'S OWN NUMBER IS NOT A CODE.** The
      // rule this holds is `DatabaseUnreadable`'s: a SQLite result code on
      // screen at 03:20 reads as blame and cannot be acted on. `TagAlreadyInUse`
      // names the tag, which is the opposite — it is the one fact that makes the
      // sentence actionable, and `flock_test.dart` asserts the tag is in it.
      //
      // So the property is scoped to failures that carry no number of the user's
      // own, rather than weakened for all of them. Widening it again means
      // adding a variant here, deliberately.
      if (f is! TagAlreadyInUse) {
        expect(m, isNot(matches(RegExp(r'\b\d+\b'))), reason: '$f leaks a code');
      }

      for (final String banned in <String>['should', 'sync', 'draft', 'invalid', 'error']) {
        expect(m.toLowerCase(), isNot(contains(banned)), reason: '$f says $banned');
      }
    }
  });

  test('StorageWriteFailed does not claim the phone is out of space', () {
    // THE ONE ASSERTION IN THIS FILE THAT IS ABOUT SAFETY RATHER THAN SHAPE.
    // SQLITE_IOERR means the app knows the write did not land and does NOT know
    // why. Telling a shepherd to free space when the real cause was a read-only
    // volume sends them to delete photos at 03:20 for nothing.
    expect(const StorageWriteFailed().userMessage, isNot(contains('out of space')));
    expect(const DiskFull().userMessage, contains('out of space'));
  });

  test('DatabaseUnreadable never renders its result codes', () {
    // The codes exist for the log. A number on screen at 03:20 reads as blame
    // and cannot be acted on.
    const DatabaseUnreadable f = DatabaseUnreadable(11, 26);
    expect(f.userMessage, isNot(contains('11')));
    expect(f.userMessage, isNot(contains('26')));
    expect(f.resultCode, 11);
    expect(f.extendedResultCode, 26);
  });

  test('four variants are const-constructible from nothing', () {
    // DatabaseUnreadable and UnexpectedFailure are EXCLUDED, and the reason is
    // in the two case names above: one carries codes for the log, the other
    // carries an error and a stack. Neither can be a value with no arguments,
    // and neither should be.
    const List<ShedFailure> constants = <ShedFailure>[
      DiskFull(),
      StorageWriteFailed(),
      StorageReadOnly(),
      MediaWriteFailed(),
    ];
    expect(constants, hasLength(4));
    expect(identical(const DiskFull(), const DiskFull()), isTrue);
  });

  test('WriteCommitted defaults to no inserted id and no warnings', () {
    const WriteCommitted a = WriteCommitted();
    const WriteCommitted b = WriteCommitted();

    expect(a.insertedId, isNull);
    expect(a.warnings, isEmpty);
    expect(identical(a.warnings, b.warnings), isTrue, reason: 'the default list is canonicalised');
  });

  test('WriteCommitted carries warnings without acting on them', () {
    // §12.4 AS A TYPE-LEVEL PROPERTY. Warning holds no writer and this class
    // holds no fix(): the outcome can carry what is questionable about a record
    // and has no way to remove, repair or reorder it.
    const WriteCommitted committed = WriteCommitted(
      insertedId: 7,
      warnings: <Warning>[
        Warning(WarningCode.implausibleBirthWeight, 'observed'),
        Warning(WarningCode.duplicateActiveTag, 'observed'),
      ],
    );

    expect(committed.warnings, hasLength(2));
    expect(committed.warnings.first.code, WarningCode.implausibleBirthWeight);
    expect(committed.warnings.last.code, WarningCode.duplicateActiveTag);

    final String source = _declarations(_outcomeFile);
    for (final String banned in <String>['fix(', 'repair(', 'clear(', 'removeWarning', 'sort(']) {
      expect(source, isNot(contains(banned)), reason: banned);
    }
  });

  test('WriteRefused carries a RefusalReason and is not a WriteFailed', () {
    // Telling a shepherd to try again after a REFUSAL is telling them to do
    // something that will refuse again. The two are different outcomes because
    // they lead to different sentences.
    const WriteRefused refused = WriteRefused(RefusalReason.eweCap);

    expect(refused, isNot(isA<WriteFailed>()));
    expect(refused.reason, RefusalReason.eweCap);
    expect(RefusalReason.values, <RefusalReason>[RefusalReason.secondSeason, RefusalReason.eweCap]);
  });

  test('neither file imports drift, sqlite3, flutter or riverpod', () {
    // Layer rule 8, proved here as well as by the gate — because THIS is the
    // file somebody will "just add a SqliteException case" to, and the moment it
    // does, the domain has a driver dependency.
    for (final String path in <String>[_failureFile, _outcomeFile]) {
      final String imports = _declarations(
        path,
      ).split('\n').where((String l) => l.trimLeft().startsWith('import ')).join('\n');

      for (final String forbidden in <String>[
        'drift',
        'sqlite3',
        'package:flutter/',
        'riverpod',
        'data/',
      ]) {
        expect(imports, isNot(contains(forbidden)), reason: '$path imports $forbidden');
      }
    }
  });
}
