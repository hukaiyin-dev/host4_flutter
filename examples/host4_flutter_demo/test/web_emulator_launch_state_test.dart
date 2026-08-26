import 'package:flutter_test/flutter_test.dart';
import 'package:host4_flutter_demo/pages/web_emulator/web_emulator_launch_state.dart';

void main() {
  test('new session starts loading at attempt zero', () {
    const state = WebEmulatorLaunchState.loading();

    expect(state.phase, WebEmulatorLaunchPhase.loading);
    expect(state.attempt, 0);
    expect(state.error, isNull);
  });

  test('failure keeps the error and retry starts a clean new attempt', () {
    final failed = const WebEmulatorLaunchState.loading().failed(
      StateError('launch timeout'),
    );

    expect(failed.phase, WebEmulatorLaunchPhase.failed);
    expect(failed.error, contains('launch timeout'));

    final retrying = failed.retry();
    expect(retrying.phase, WebEmulatorLaunchPhase.loading);
    expect(retrying.attempt, 1);
    expect(retrying.error, isNull);
  });

  test('successful launch enters running without changing attempt', () {
    final running = const WebEmulatorLaunchState.loading(attempt: 2).running();

    expect(running.phase, WebEmulatorLaunchPhase.running);
    expect(running.attempt, 2);
    expect(running.error, isNull);
  });

  test('only an ok launched bridge envelope is launch success', () {
    expect(
      isSuccessfulLaunchBridgeMessage('launched', <String, Object?>{
        'type': 'launched',
        'requestId': 'launch-1',
        'ok': true,
        'data': null,
        'error': null,
      }),
      isTrue,
    );
    expect(
      isSuccessfulLaunchBridgeMessage('launched', <String, Object?>{
        'type': 'launched',
        'requestId': 'launch-1',
        'ok': false,
        'data': null,
        'error': 'download failed',
      }),
      isFalse,
    );
    expect(isSuccessfulLaunchBridgeMessage('launchError', const {}), isFalse);
  });
}
