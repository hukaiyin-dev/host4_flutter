import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:host4_flutter_ui/host4_flutter_ui.dart';

void main() {
  const initial = Host4SystemStatusData(
    timeLabel: '14:51',
    wifiEnabled: true,
    batteryLevel: 86,
    batteryCharging: false,
  );

  test('static system status source exposes a snapshot', () {
    const source = Host4StaticSystemStatusSource(initial);

    expect(source.currentTime, '14:51');
    expect(source.currentWifi, isTrue);
    expect(source.currentBatteryLevel, 86);
    expect(source.currentCharging, isFalse);
  });

  test('value listenable source emits only changed fields', () async {
    final notifier = ValueNotifier<Host4SystemStatusData>(initial);
    final source = Host4ValueListenableSystemStatusSource(notifier);
    addTearDown(source.dispose);

    final times = <String>[];
    final wifi = <bool>[];
    final batteries = <int>[];
    final charging = <bool>[];
    final subscriptions = [
      source.timeStream.listen(times.add),
      source.wifiStream.listen(wifi.add),
      source.batteryLevelStream.listen(batteries.add),
      source.chargingStream.listen(charging.add),
    ];
    addTearDown(() async {
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
    });

    notifier.value = const Host4SystemStatusData(
      timeLabel: '14:52',
      wifiEnabled: true,
      batteryLevel: 80,
      batteryCharging: true,
    );
    await Future<void>.delayed(Duration.zero);

    expect(source.currentTime, '14:52');
    expect(source.currentWifi, isTrue);
    expect(source.currentBatteryLevel, 80);
    expect(source.currentCharging, isTrue);
    expect(times, ['14:52']);
    expect(wifi, isEmpty);
    expect(batteries, [80]);
    expect(charging, [true]);
  });
}
