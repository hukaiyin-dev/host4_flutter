import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:host4_flutter_simulator_storage/host4_flutter_simulator_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('host4_flutter_simulator_storage');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('scanTfCardRoms sends system specs and parses scanned ROMs', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return <String, Object?>{
            'scanId': 'ios_tf_scan_1',
            'rootPath': '/Volumes/TF',
            'romsPath': '/Volumes/TF/roms',
            'platforms': <Object?>[
              <String, Object?>{
                'type': 21,
                'name': 'GBA',
                'fullName': 'Game Boy Advance',
                'dir': 'gba',
                'path': '/Volumes/TF/roms/gba',
                'gameCount': 1,
              },
            ],
            'games': <Object?>[
              <String, Object?>{
                'type': 21,
                'platformName': 'GBA',
                'platformFullName': 'Game Boy Advance',
                'name': 'Zelda',
                'fileName': 'Zelda.gba',
                'rootPath': '/Volumes/TF/roms/gba',
                'resourcePath': 'Zelda.gba',
                'romPath': '/Volumes/TF/roms/gba/Zelda.gba',
                'imagePath': './images/Zelda.png',
                'videoPath': './videos/Zelda.mp4',
                'description': 'demo',
              },
            ],
          };
        });

    final result = await Host4SimulatorStorage.scanTfCardRoms(
      systems: const <Host4RomSystemSpec>[
        Host4RomSystemSpec(
          type: 21,
          name: 'GBA',
          fullName: 'Game Boy Advance',
          dir: 'gba',
          extensions: <String>['.gba', '.zip'],
        ),
      ],
      forcePick: true,
    );

    expect(result.scanId, 'ios_tf_scan_1');
    expect(result.rootPath, '/Volumes/TF');
    expect(result.romsPath, '/Volumes/TF/roms');
    expect(result.platforms.single.type, 21);
    expect(result.games.single.type, 21);
    expect(result.games.single.name, 'Zelda');
    expect(result.games.single.resourcePath, 'Zelda.gba');
    expect(result.games.single.imagePath, './images/Zelda.png');
    expect(calls.single.method, 'scanTfCardRoms');
    expect(calls.single.arguments, <String, Object?>{
      'forcePick': true,
      'systems': <Object?>[
        <String, Object?>{
          'type': 21,
          'name': 'GBA',
          'fullName': 'Game Boy Advance',
          'dir': 'gba',
          'extensions': <String>['.gba', '.zip'],
        },
      ],
    });
  });

  test('scanTfCardRoms rejects empty system specs', () async {
    await expectLater(
      Host4SimulatorStorage.scanTfCardRoms(systems: const []),
      throwsArgumentError,
    );
  });

  test('TF scan event parses a discovered ROM immediately', () {
    final event = Host4TfCardScanEvent.fromMap(<String, Object?>{
      'phase': 'gameFound',
      'scanId': 'ios_tf_scan_1',
      'game': <String, Object?>{
        'type': 21,
        'platformName': 'GBA',
        'platformFullName': 'Game Boy Advance',
        'name': 'Zelda',
        'fileName': 'Zelda.gba',
        'rootPath': '/Volumes/TF/roms/gba',
        'resourcePath': 'Zelda.gba',
        'romPath': '/Volumes/TF/roms/gba/Zelda.gba',
      },
    });

    expect(event.phase, Host4TfCardScanPhase.gameFound);
    expect(event.scanId, 'ios_tf_scan_1');
    expect(event.game?.name, 'Zelda');
    expect(event.game?.resourcePath, 'Zelda.gba');
  });
}
