import 'package:shed_book/domain/policy/disclaimers.dart';
import 'package:shed_book/domain/time/instant.dart';

/// What every export carries besides its rows (R65).
///
/// Safety rule §12.3 at the **unconstructible** level: [disclaimer] is **not a
/// parameter of any constructor**, so an export cannot be built without the real
/// one, cannot be built with a shortened one, and cannot be built with a
/// softened one. There is nothing to pass and nothing to forget.
///
/// The generative constructor is private and [ExportEnvelope.standard] is the
/// only entry point, for the same reason `WithdrawalDays._` is private: a second
/// entry point is a second thing to get wrong, whatever it is called.
final class ExportEnvelope {
  const ExportEnvelope._(this.disclaimer, this.generatedAt, this.appVersion);

  /// The only constructor. Note what is missing from its parameter list.
  factory ExportEnvelope.standard({required Instant now, required String appVersion}) =>
      ExportEnvelope._(Disclaimers.exportFooter, now, appVersion);

  final String disclaimer;
  final Instant generatedAt;
  final String appVersion;
}
