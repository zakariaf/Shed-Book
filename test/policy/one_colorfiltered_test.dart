// test/policy/one_colorfiltered_test.dart
//
// Decision #96 as an executable assertion, on the same shape as N10-T07's
// one_overlay_test.dart. `test/policy/` files are named for the PROPERTY, not
// for the file under test.
@Tags(<String>['policy'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

List<String> _authoredDart(String root) =>
    Directory(root)
        .listSync(recursive: true)
        .whereType<File>()
        .map((File f) => f.path.replaceAll(r'\', '/'))
        .where(
          (String p) =>
              p.endsWith('.dart') &&
              !p.endsWith('.g.dart') &&
              !p.endsWith('.drift.dart') &&
              !p.contains('app_localizations'),
        )
        .toList()
      ..sort();

void main() {
  test('ShedPhoto is the only ColorFiltered in lib/', () {
    // Decision #96. A ColorFiltered pays for a saveLayer over its child's
    // bounds; over a photo that is bounded and cheap, and over a subtree it is
    // the whole screen, every frame. One sanctioned site is what keeps the
    // difference visible.
    //
    // The needle is split: this file lives under a scanned root and a whole one
    // would match itself. The thirty-first prohibition-versus-claim self-match.
    const String needle =
        'Color' // split
        'Filtered(';

    final List<String> sites = _authoredDart(
      'lib',
    ).where((String p) => File(p).readAsStringSync().contains(needle)).toList();

    expect(sites, <String>['lib/core/ui/components/shed_photo.dart']);
  });

  test('there is no identity filter anywhere', () {
    // An identity ColorFiltered still pays for its saveLayer — on every frame,
    // for nothing. The null-tint branch must return the plain Image rather than
    // wrapping it in a filter that does not filter.
    final String source = File('lib/core/ui/components/shed_photo.dart').readAsStringSync();
    expect(source, isNot(contains('ColorFilter.mode(Colors.transparent')));
    expect(source, contains('tint == null'), reason: 'the null branch is explicit');
  });
}
