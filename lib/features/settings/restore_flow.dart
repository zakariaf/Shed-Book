// lib/features/settings/restore_flow.dart
//
// **THE ONE `file_selector` CALL SITE IN THE APP.** `layer.plugin_file_selector`
// fails the build on a second import anywhere, and the reason is not tidiness: a
// second picker is a second set of type filters, and the one that greys out a
// shepherd's own backup is always the one nobody tested on Android.
//
// It returns the picked path and touches nothing else. **It constructs no
// filesystem handle** — that constructor is banned under `lib/features/` by
// `layer.features` (`04 §4.9`), because the UI layer does not know the
// filesystem exists — and it parses nothing: the bytes are
// `readBackupPrelude`'s to judge.
//
// The constructor's name is not written in this file, because
// `backup_import_test.dart` scans the whole text for it and a comment naming the
// thing it forbids fails the rule that forbids it. The thirteenth time this
// project has caught a prohibition matching itself.
library;

import 'package:file_selector/file_selector.dart';

/// **`application/octet-stream` IS IN THE LIST ON PURPOSE.** Android MIME
/// filtering is unreliable and some providers report a `.json` as
/// octet-stream — so the filter accepts too much and the app rejects clearly,
/// rather than greying out the shepherd's own backup in the picker with no
/// explanation and no way forward.
///
/// Which is also why the extension filter is a convenience for them and never a
/// guarantee for us: the file that arrives may be anything at all.
const XTypeGroup _backupType = XTypeGroup(
  label: 'Shed Book backup',
  extensions: <String>['json'],
  mimeTypes: <String>['application/json', 'application/octet-stream'],
  uniformTypeIdentifiers: <String>['public.json'],
);

/// `null` when the shepherd backed out. **Not an error** — backing out of a file
/// picker is a decision, and rendering it as a failure is how a screen tells
/// somebody they did something wrong when they did not.
Future<XFile?> pickBackupFile() => openFile(acceptedTypeGroups: <XTypeGroup>[_backupType]);
