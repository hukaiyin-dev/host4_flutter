import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:host4_flutter_demo/pages/web_emulator/web_emulator_session_host.dart';

void main() {
  testWidgets('launch state rebuild keeps the same emulator state alive', (
    tester,
  ) async {
    var initCount = 0;
    var disposeCount = 0;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: _LaunchHarness(
          onEmulatorInit: () => initCount += 1,
          onEmulatorDispose: () => disposeCount += 1,
        ),
      ),
    );

    expect(find.text('loading'), findsOneWidget);
    expect(initCount, 1);

    await tester.tap(find.byKey(const ValueKey<String>('mark-running')));
    await tester.pump();

    expect(find.text('running'), findsOneWidget);
    expect(initCount, 1);
    expect(disposeCount, 0);
  });
}

class _LaunchHarness extends StatefulWidget {
  const _LaunchHarness({
    required this.onEmulatorInit,
    required this.onEmulatorDispose,
  });

  final VoidCallback onEmulatorInit;
  final VoidCallback onEmulatorDispose;

  @override
  State<_LaunchHarness> createState() => _LaunchHarnessState();
}

class _LaunchHarnessState extends State<_LaunchHarness> {
  bool _running = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        WebEmulatorSessionHost(
          romPicker: const SizedBox(key: ValueKey<String>('rom-picker')),
          emulator: _EmulatorProbe(
            key: const ValueKey<String>('session'),
            label: _running ? 'running' : 'loading',
            onInit: widget.onEmulatorInit,
            onDispose: widget.onEmulatorDispose,
          ),
        ),
        GestureDetector(
          key: const ValueKey<String>('mark-running'),
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _running = true),
          child: const SizedBox(width: 40, height: 40),
        ),
      ],
    );
  }
}

class _EmulatorProbe extends StatefulWidget {
  const _EmulatorProbe({
    super.key,
    required this.label,
    required this.onInit,
    required this.onDispose,
  });

  final String label;
  final VoidCallback onInit;
  final VoidCallback onDispose;

  @override
  State<_EmulatorProbe> createState() => _EmulatorProbeState();
}

class _EmulatorProbeState extends State<_EmulatorProbe> {
  @override
  void initState() {
    super.initState();
    widget.onInit();
  }

  @override
  void dispose() {
    widget.onDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Text(widget.label);
}
