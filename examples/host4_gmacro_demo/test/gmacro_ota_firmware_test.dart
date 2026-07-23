import 'package:flutter_test/flutter_test.dart';
import 'package:host4_flutter_transport/host4_flutter_transport.dart';
import 'package:host4_gmacro_demo/pages/gmacro/gmacro_session_page.dart';

void main() {
  test('selects BLE bundled OTA firmware for BLE transport', () {
    final firmware = gmacroBundledOtaFirmwareForTransportKind(
      TransportKind.ble,
    );

    expect(firmware.fileName, contains('GDF-G560637'));
    expect(
      firmware.assetPath,
      'assets/ota/OTA_GDF-G560637_46D4_V1.0_260510a.bin',
    );
  });

  test('selects MFi bundled OTA firmware for MFi transport', () {
    final firmware = gmacroBundledOtaFirmwareForTransportKind(
      TransportKind.mfi,
    );

    expect(firmware.fileName, contains('GDF-G910202'));
    expect(
      firmware.assetPath,
      'assets/ota/OTA_GDF-G910202_8520_V1.0_260715a.bin',
    );
  });
}
