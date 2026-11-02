import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:host4_flutter_gmacro_demo_ui/src/pages/gmacro/gmacro_connection_cleanup.dart';

void main() {
  test('protocol closes before its transport disconnects', () async {
    final calls = <String>[];
    final closeCompleter = Completer<void>();

    final cleanup = closeGmacroConnection(
      closeProtocol: () async {
        calls.add('closeProtocol');
        await closeCompleter.future;
      },
      disconnectTransport: () async => calls.add('disconnectTransport'),
    );

    await Future<void>.delayed(Duration.zero);
    expect(calls, <String>['closeProtocol']);
    closeCompleter.complete();
    await cleanup;
    expect(calls, <String>['closeProtocol', 'disconnectTransport']);
  });

  test(
    'USB session page can close its protocol without disconnecting',
    () async {
      var closed = false;
      await closeGmacroConnection(
        closeProtocol: () async => closed = true,
        disconnectTransport: null,
      );
      expect(closed, isTrue);
    },
  );
}
