// test/domain/policy/export_envelope_test.dart — §12.3, unconstructible.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/domain/policy/disclaimers.dart';
import 'package:shed_book/domain/policy/export_envelope.dart';
import 'package:shed_book/domain/time/instant.dart';

void main() {
  test('standard() carries Disclaimers.exportFooter', () {
    // Compared by REFERENCE to the constant, never to a re-typed string — a
    // literal here would make this file the second definition site.
    final ExportEnvelope e = ExportEnvelope.standard(
      now: Instant.fromDateTime(DateTime.utc(2026, 3, 4)),
      appVersion: '1.0.0',
    );

    expect(e.disclaimer, same(Disclaimers.exportFooter));
  });

  test('there is no constructor that takes a disclaimer', () {
    // THE COMPILE IS THE ASSERTION. ExportEnvelope.standard's parameter list is
    // {now, appVersion} and the generative constructor is private, so there is
    // no expression anywhere that produces an envelope with a shortened,
    // softened or absent disclaimer. Nothing at a call site can forget it,
    // because there is nothing to pass.
    final ExportEnvelope e = ExportEnvelope.standard(
      now: Instant.fromDateTime(DateTime.utc(2026, 3, 4)),
      appVersion: '1.0.0',
    );

    expect(e.disclaimer, isNotEmpty);
    expect(e.disclaimer, contains('must not be presented as one'));
  });

  test('generatedAt is the Instant passed in', () {
    final Instant now = Instant.fromDateTime(DateTime.utc(2026, 3, 4, 3, 20));
    final ExportEnvelope e = ExportEnvelope.standard(now: now, appVersion: '1.2.3');

    expect(e.generatedAt, now);
    expect(e.appVersion, '1.2.3');
  });
}
