import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:host4_flutter_demo/pages/web_emulator/web_emulator_launch_state.dart';
import 'package:host4_flutter_demo/pages/web_emulator/web_emulator_launch_status_panel.dart';

void main() {
  testWidgets('loading state shows a visible progress message', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WebEmulatorLaunchStatusPanel(
          state: WebEmulatorLaunchState.loading(),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('正在启动模拟器…'), findsOneWidget);
  });

  testWidgets('failure shows error and exposes retry and ROM actions', (
    tester,
  ) async {
    var retryCount = 0;
    var selectCount = 0;
    final state = const WebEmulatorLaunchState.loading().failed(
      StateError('launch timeout'),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: WebEmulatorLaunchStatusPanel(
          state: state,
          onRetry: () => retryCount += 1,
          onSelectRom: () => selectCount += 1,
        ),
      ),
    );

    expect(find.text('模拟器启动失败'), findsOneWidget);
    expect(find.textContaining('launch timeout'), findsOneWidget);

    await tester.tap(find.text('重新启动'));
    await tester.tap(find.text('重新选择 ROM'));

    expect(retryCount, 1);
    expect(selectCount, 1);
  });
}
