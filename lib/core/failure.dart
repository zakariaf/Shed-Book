// lib/core/failure.dart — what went wrong, in words a shepherd can act on.
//
// Layer rule 8: this file imports nothing but `dart:` and siblings. It is the
// file somebody will "just add a SqliteException case" to, and the moment it
// imports a database package the domain has a driver dependency.

/// A failure the app can describe.
///
/// **Not named `Error`.** `Error` shadows `dart:core`'s, which produces
/// confusing analyzer messages the first time somebody writes
/// `catch (e) { if (e is Error) … }`. CLAUDE.md bans the name outright.
sealed class ShedFailure {
  const ShedFailure();

  /// Plain, non-technical, actionable. **No stack traces, no SQLite codes, no
  /// blame.** This is read at 3am by someone holding a lamb, and every sentence
  /// says what happened to the record before it says what to do.
  String get userMessage;
}

final class DiskFull extends ShedFailure {
  const DiskFull();

  @override
  String get userMessage =>
      'Your phone is out of space. Nothing was saved. Free some space and try again.';
}

final class DatabaseUnreadable extends ShedFailure {
  const DatabaseUnreadable(this.resultCode, this.extendedResultCode);

  /// Logged, **never shown**. A shepherd cannot act on `SQLITE_CORRUPT`, and a
  /// number on screen at 03:20 reads as blame.
  final int resultCode;
  final int extendedResultCode;

  @override
  String get userMessage =>
      'Shed Book cannot read its records file. Do not delete the app. '
      'Open Settings › Diagnostics to save a copy of what is there.';
}

/// `SQLITE_IOERR`. The app knows the write did not land and does **not** know
/// why — so this message must not claim the phone is out of space. Only
/// [DiskFull] may say that, because only [DiskFull] knows it.
final class StorageWriteFailed extends ShedFailure {
  const StorageWriteFailed();

  @override
  String get userMessage =>
      'Shed Book could not write to your phone. Nothing was saved. '
      'Check you have free space, then try again.';
}

final class StorageReadOnly extends ShedFailure {
  const StorageReadOnly();

  @override
  String get userMessage =>
      'Shed Book cannot write to its records file. Nothing was saved. '
      'Restart your phone, then try again.';
}

final class MediaWriteFailed extends ShedFailure {
  const MediaWriteFailed();

  @override
  String get userMessage =>
      'Shed Book could not store that photo. The record was saved without it.';
}

/// Bugs. R8 fixes the constructor at exactly two positional arguments.
/// The tag is already on a live animal in this flock (`03 §6`'s partial unique
/// index; ruling N4).
///
/// **ITS OWN TYPE BECAUSE THE ADVICE IS DIFFERENT.** `UnexpectedFailure` says
/// *"Try again"*, and trying again fails identically — the same reason
/// `WriteRefused` exists apart from `WriteFailed`. Nothing went wrong: the flock
/// already has a live `412`, and a second one makes *"what did 412 do last
/// year?"* unanswerable, which is the question the product exists to answer.
final class TagAlreadyInUse extends ShedFailure {
  const TagAlreadyInUse(this.tag);

  final String tag;

  @override
  String get userMessage =>
      'Tag $tag is already on an animal in this flock. '
      'Cull or sell that one first, or use a different tag.';
}

final class UnexpectedFailure extends ShedFailure {
  const UnexpectedFailure(this.error, this.stack);

  final Object error;
  final StackTrace stack;

  @override
  String get userMessage =>
      'Something went wrong and nothing was saved. Try again. '
      'If it keeps happening, open Settings › Diagnostics and save a copy.';
}
