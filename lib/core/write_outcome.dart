// lib/core/write_outcome.dart — what a write did.
import 'package:shed_book/core/failure.dart';
import 'package:shed_book/domain/free_tier.dart';
import 'package:shed_book/domain/validation/warning.dart';

/// **Deliberately not named `Ok`/`Error`**, and deliberately **not generic**:
/// there is no `WriteOutcome<T>`. A generic outcome invites a repository to
/// return a value that a caller then has to unwrap before it can ask whether the
/// write happened — and the answer to that question is the only thing any caller
/// needs.
sealed class WriteOutcome {
  const WriteOutcome();
}

final class WriteCommitted extends WriteOutcome {
  const WriteCommitted({this.insertedId, this.warnings = const <Warning>[]});

  /// A raw `int`, wrapped by the one call site that reads it.
  final int? insertedId;

  /// Populated by the **controller**, never by a repository (R53). The data
  /// layer cannot reach `lib/domain/validation/` at all, which is what makes
  /// safety rule §12.4 structural: the code that WRITES cannot produce a
  /// warning, and this class holds no way to remove, fix or reorder one.
  final List<Warning> warnings;
}

final class WriteFailed extends WriteOutcome {
  const WriteFailed(this.failure);

  final ShedFailure failure;
}

/// **Nothing was written, and nothing went wrong.**
///
/// Unreachable from `EntryContext.liveEntry` by construction — the free-tier cap
/// never blocks a lambing in progress. Distinct from [WriteFailed] because
/// telling a shepherd to try again after a refusal is telling them to do
/// something that will refuse again.
final class WriteRefused extends WriteOutcome {
  const WriteRefused(this.reason);

  final RefusalReason reason;
}
