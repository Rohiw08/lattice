import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Dependency-closure guard for the V3 rewrite.
///
/// New code under `lib/src/v3/` must not import packages slated for removal at
/// cutover (Plan V3-7). Only `flutter`, `flutter_riverpod`, and `riverpod`
/// (plus `flutter_test` in tests) are allowed.
void main() {
  test('v3 sources import no banned packages', () {
    const banned = <String>[
      'package:freezed_annotation',
      'package:equatable',
      'package:uuid',
      'package:vector_math',
    ];
    final v3Dir = Directory('lib/src/v3');
    expect(v3Dir.existsSync(), isTrue, reason: 'lib/src/v3/ must exist');
    final offenders = <String>[];
    for (final entity in v3Dir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final source = entity.readAsStringSync();
      for (final package in banned) {
        if (source.contains(package)) {
          offenders.add('${entity.path} imports $package');
        }
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}
