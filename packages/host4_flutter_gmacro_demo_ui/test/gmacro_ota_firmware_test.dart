import 'package:flutter_test/flutter_test.dart';
import 'package:host4_flutter_gmacro_demo_ui/host4_flutter_gmacro_demo_ui.dart';
import 'package:host4_flutter_transport/host4_flutter_transport.dart';

void main() {
  test('selects BLE bundled OTA firmware for BLE transport', () {
    final firmware = gmacroBundledOtaFirmwareForTransportKind(
      TransportKind.ble,
    );

    expect(firmware.fileName, contains('GDF-G560637'));
    expect(
      firmware.assetPath,
      'packages/host4_flutter_gmacro_demo_ui/assets/ota/OTA_GDF-G560637_46D4_V1.0_260510a.bin',
    );
  });

  test('selects MFi bundled OTA firmware for MFi transport', () {
    final firmware = gmacroBundledOtaFirmwareForTransportKind(
      TransportKind.mfi,
    );

    expect(firmware.fileName, contains('GDF-G910202'));
    expect(
      firmware.assetPath,
      'packages/host4_flutter_gmacro_demo_ui/assets/ota/OTA_GDF-G910202_8520_V1.0_260715a.bin',
    );
  });
}
