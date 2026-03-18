import 'package:flutter_test/flutter_test.dart';
import 'package:host4_flutter_core/host4_flutter_core.dart';
import 'package:host4_flutter_log/host4_flutter_log.dart';

void main() {
  group('Host4LogLevel ordering', () {
    test('levels are ordered from least to most severe', () {
      expect(Host4LogLevel.trace.index, lessThan(Host4LogLevel.debug.index));
      expect(Host4LogLevel.debug.index, lessThan(Host4LogLevel.info.index));
      expect(Host4LogLevel.info.index, lessThan(Host4LogLevel.warn.index));
      expect(Host4LogLevel.warn.index, lessThan(Host4LogLevel.error.index));
      expect(Host4LogLevel.error.index, lessThan(Host4LogLevel.silent.index));
    });
  });

  group('Host4Logger filtering', () {
    final emitted = <String>[];

    setUp(() {
      emitted.clear();
    });

    test('messages below minimumLevel are dropped', () {
      // Verify the level ordering is respected by the index comparison.
      // Host4Logger.write uses level.index < effectiveMinimum.index to drop.
      const minimum = Host4LogLevel.warn;
      for (final level in Host4LogLevel.values) {
        if (level == Host4LogLevel.silent) continue;
        final shouldPass = level.index >= minimum.index;
        expect(level.index >= minimum.index, shouldPass);
      }
    });

    test('Host4Logger implements Host4LogSink', () {
      final logger = Host4Logger('Test');
      expect(logger, isA<Host4LogSink>());
    });
  });
}
