import 'package:test/test.dart';

import 'package:host4_flutter_core/host4_flutter_core.dart';

void main() {
  // ── Host4Module ────────────────────────────────────────────────────────────

  group('Host4Module lifecycle contract', () {
    test('attach marks module as attached', () {
      final module = _FakeModule();
      expect(module.isAttached, isFalse);
      module.attach();
      expect(module.isAttached, isTrue);
    });

    test('detach marks module as detached', () {
      final module = _FakeModule();
      module.attach();
      module.detach();
      expect(module.isAttached, isFalse);
    });

    test('reset clears state and leaves module detached', () {
      final module = _FakeModule();
      module.attach();
      module.reset();
      expect(module.isAttached, isFalse);
      expect(module.resetCount, 1);
    });

    test('reset without prior attach does not throw', () {
      final module = _FakeModule();
      expect(() => module.reset(), returnsNormally);
    });

    test('attach is idempotent — double attach does not double-register', () {
      final module = _FakeModule();
      module.attach();
      module.attach();
      expect(module.attachCount, 1);
    });
  });

  // ── Host4Exception ─────────────────────────────────────────────────────────

  group('Host4Exception', () {
    test('toString includes message', () {
      const e = Host4Exception('something went wrong');
      expect(e.toString(), contains('something went wrong'));
    });

    test('toString includes cause when provided', () {
      const inner = Host4Exception('root cause');
      const e = Host4Exception('outer error', cause: inner);
      expect(e.toString(), contains('outer error'));
      expect(e.toString(), contains('Caused by'));
    });

    test('toString omits cause section when cause is null', () {
      const e = Host4Exception('no cause');
      expect(e.toString(), isNot(contains('Caused by')));
    });

    test('Host4ModuleNotAttachedException message includes module name', () {
      const e = Host4ModuleNotAttachedException('UserModule');
      expect(e.toString(), contains('UserModule'));
    });

    test('Host4DependencyNotFoundException message includes dependency name', () {
      const e = Host4DependencyNotFoundException('AnalyticsLogger');
      expect(e.toString(), contains('AnalyticsLogger'));
    });

    test('exceptions are caught as Host4Exception', () {
      void throwIt() => throw const Host4ModuleNotAttachedException('X');
      expect(throwIt, throwsA(isA<Host4Exception>()));
    });
  });

  // ── Host4LogLevel ──────────────────────────────────────────────────────────

  group('Host4LogLevel ordering', () {
    test('severity increases with index', () {
      expect(Host4LogLevel.trace.index, lessThan(Host4LogLevel.debug.index));
      expect(Host4LogLevel.debug.index, lessThan(Host4LogLevel.info.index));
      expect(Host4LogLevel.info.index, lessThan(Host4LogLevel.warn.index));
      expect(Host4LogLevel.warn.index, lessThan(Host4LogLevel.error.index));
      expect(Host4LogLevel.error.index, lessThan(Host4LogLevel.silent.index));
    });

    test('silent is strictly higher than all writable levels', () {
      for (final level in Host4LogLevel.values) {
        if (level == Host4LogLevel.silent) continue;
        expect(level.index, lessThan(Host4LogLevel.silent.index),
            reason: '$level should be below silent');
      }
    });
  });

  // ── Host4LogSink ───────────────────────────────────────────────────────────

  group('Host4LogSink contract', () {
    test('write delivers all arguments to the implementation', () {
      final sink = _CapturingSink();
      final stack = StackTrace.current;

      sink.write(
        Host4LogLevel.warn,
        'NET',
        'connection timeout',
        error: Exception('timeout'),
        stackTrace: stack,
      );

      expect(sink.lastLevel, Host4LogLevel.warn);
      expect(sink.lastTag, 'NET');
      expect(sink.lastMessage, 'connection timeout');
      expect(sink.lastError, isA<Exception>());
      expect(sink.lastStackTrace, same(stack));
    });

    test('write with optional fields omitted does not throw', () {
      final sink = _CapturingSink();
      expect(
        () => sink.write(Host4LogLevel.info, 'App', 'started'),
        returnsNormally,
      );
    });
  });

  // ── Host4Environment ───────────────────────────────────────────────────────

  group('Host4Environment contract', () {
    test('debug implementation reports isDebug true', () {
      final env = _DebugEnvironment();
      expect(env.isDebug, isTrue);
    });

    test('release implementation reports isDebug false', () {
      final env = _ReleaseEnvironment();
      expect(env.isDebug, isFalse);
    });

    test('platformName is non-empty', () {
      expect(_DebugEnvironment().platformName, isNotEmpty);
      expect(_ReleaseEnvironment().platformName, isNotEmpty);
    });
  });
}

// ── Test doubles ──────────────────────────────────────────────────────────────

class _FakeModule implements Host4Module {
  bool isAttached = false;
  int attachCount = 0;
  int resetCount = 0;

  @override
  void attach() {
    if (isAttached) return; // idempotent
    isAttached = true;
    attachCount++;
  }

  @override
  void detach() => isAttached = false;

  @override
  void reset() {
    isAttached = false;
    resetCount++;
  }
}

class _CapturingSink implements Host4LogSink {
  Host4LogLevel? lastLevel;
  String? lastTag;
  String? lastMessage;
  Object? lastError;
  StackTrace? lastStackTrace;

  @override
  void write(
    Host4LogLevel level,
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    lastLevel = level;
    lastTag = tag;
    lastMessage = message;
    lastError = error;
    lastStackTrace = stackTrace;
  }
}

class _DebugEnvironment implements Host4Environment {
  @override
  bool get isDebug => true;

  @override
  String get platformName => 'ios';
}

class _ReleaseEnvironment implements Host4Environment {
  @override
  bool get isDebug => false;

  @override
  String get platformName => 'android';
}
