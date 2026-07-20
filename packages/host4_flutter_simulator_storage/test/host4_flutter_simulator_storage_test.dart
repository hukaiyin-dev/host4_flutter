import 'dart:io';

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

  test(
    'simulator ROM folder picker uses the requested platform slot',
    () async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            return <Object?>[
              <String, Object?>{
                'path': '/private/var/mobile/Media/TF/gb',
                'displayName': 'gb',
              },
            ];
          });

      final folders = await Host4SimulatorStorage.pickSimulatorRomFolder(
        systemType: 9,
        replacingPath: '/private/var/mobile/Media/TF/old-gb',
      );

      expect(folders.single.path, '/private/var/mobile/Media/TF/gb');
      expect(folders.single.displayName, 'gb');
      expect(calls.single.method, 'pickSimulatorRomFolder');
      expect(calls.single.arguments, <String, Object?>{
        'systemType': 9,
        'replacingPath': '/private/var/mobile/Media/TF/old-gb',
      });
    },
  );

  test(
    'simulator ROM scan sends one platform spec and returns its scan id',
    () async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            return <String, Object?>{'scanId': 'ios_simulator_path_scan_1'};
          });

      final scanId = await Host4SimulatorStorage.startSimulatorRomFolderScan(
        system: const Host4RomSystemSpec(
          type: 9,
          name: 'GB',
          fullName: 'Game Boy',
          dir: 'gb',
          extensions: <String>['.gb', '.zip'],
        ),
      );

      expect(scanId, 'ios_simulator_path_scan_1');
      expect(calls.single.method, 'startSimulatorRomFolderScan');
      expect(calls.single.arguments, <String, Object?>{
        'system': <String, Object?>{
          'type': 9,
          'name': 'GB',
          'fullName': 'Game Boy',
          'dir': 'gb',
          'extensions': <String>['.gb', '.zip'],
        },
      });
    },
  );

  test(
    'iOS stores up to two additional folders for each simulator',
    () async {
      final pluginSource = await File(
        'ios/Classes/Host4FlutterSimulatorStoragePlugin.swift',
      ).readAsString();

      expect(pluginSource, contains('Host4SimulatorRomFolderBookmarkStore'));
      expect(pluginSource, contains('case "pickSimulatorRomFolder"'));
      expect(pluginSource, contains('case "startSimulatorRomFolderScan"'));
      expect(pluginSource, contains('private let maximumFolderCount = 2'));
    },
  );

  test('iOS reports accessibility for every configured simulator folder', () async {
    final pluginSource = await File(
      'ios/Classes/Host4FlutterSimulatorStoragePlugin.swift',
    ).readAsString();

    expect(pluginSource, contains('"accessible":'));
    expect(
      pluginSource,
      contains('isSimulatorFolderAccessible(entry)'),
    );
  });

  test('iOS keeps a replaced ROM folder in its original UI slot', () async {
    final pluginSource = await File(
      'ios/Classes/Host4FlutterSimulatorStoragePlugin.swift',
    ).readAsString();

    expect(pluginSource, contains('systemEntries[index] = Entry('));
  });

  test(
    'iOS keeps a selected folder visible even before access is retained',
    () async {
      final pluginSource = await File(
        'ios/Classes/Host4FlutterSimulatorStoragePlugin.swift',
      ).readAsString();

      expect(
        pluginSource,
        isNot(
          contains(
            'guard didStartAccessing else {\n'
            '        simulatorFolderResult(FlutterError(',
          ),
        ),
      );
    },
  );

  test('replacing a folder keeps the previous session access alive', () async {
    final pluginSource = await File(
      'ios/Classes/Host4FlutterSimulatorStoragePlugin.swift',
    ).readAsString();
    final start = pluginSource.indexOf('public func documentPicker(');
    final end = pluginSource.indexOf('if let streamingResult', start);
    final folderSelectionFlow = pluginSource.substring(start, end);

    expect(
      folderSelectionFlow,
      isNot(contains('Host4TfCardFileAccessRegistry.clearActiveDirectory(')),
    );
  });

  test(
    'iOS persists TF folders while their security scope is active',
    () async {
      final pluginSource = await File(
        'ios/Classes/Host4FlutterSimulatorStoragePlugin.swift',
      ).readAsString();

      expect(
        pluginSource,
        contains('normalizedURL.startAccessingSecurityScopedResource()'),
      );
      expect(pluginSource, contains('guard didStartAccessing else'));
      expect(pluginSource, contains('options: []'));
    },
  );

  test(
    'iOS checks the TF folder selected in the current session first',
    () async {
      final pluginSource = await File(
        'ios/Classes/Host4FlutterSimulatorStoragePlugin.swift',
      ).readAsString();

      expect(pluginSource, contains('private var activeTfCardURL: URL?'));
      expect(
        pluginSource,
        contains('let url = activeTfCardURL ?? bookmarkStore.resolve()?.url'),
      );
    },
  );

  test(
    'iOS keeps selected TF directory access for the entire app session',
    () async {
      final pluginSource = await File(
        'ios/Classes/Host4FlutterSimulatorStoragePlugin.swift',
      ).readAsString();

      expect(
        pluginSource,
        contains('public enum Host4TfCardFileAccessRegistry'),
      );
      expect(
        pluginSource,
        contains('public static func retainAccess(forROMPath romPath: String)'),
      );
      expect(
        pluginSource,
        contains(
          'private static var activeDirectoryAccess: Host4TfCardRetainedFileAccess?',
        ),
      );
      expect(
        pluginSource,
        contains('guard let access = Host4TfCardRetainedFileAccess('),
      );
      expect(pluginSource, contains('ownsExistingSecurityScope: Bool = false'));
      expect(pluginSource, contains('ownsExistingSecurityScope: true'));
    },
  );

  test(
    'iOS verifies TF availability by reading the retained directory',
    () async {
      final pluginSource = await File(
        'ios/Classes/Host4FlutterSimulatorStoragePlugin.swift',
      ).readAsString();

      expect(
        pluginSource,
        contains('FileManager.default.contentsOfDirectory('),
      );
    },
  );

  test(
    'iOS checks an active TF session through its retained security scope first',
    () async {
      final pluginSource = await File(
        'ios/Classes/Host4FlutterSimulatorStoragePlugin.swift',
      ).readAsString();

      expect(
        pluginSource,
        contains(
          'public static func isActiveDirectoryAccessible(at directoryURL: URL) -> Bool?',
        ),
      );
      expect(
        pluginSource,
        contains(
          'Host4TfCardFileAccessRegistry.isActiveDirectoryAccessible(at: url)',
        ),
      );
    },
  );

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

  test('TF scan event preserves a skipped directory selection', () {
    final event = Host4TfCardScanEvent.fromMap(<String, Object?>{
      'phase': 'skipped',
      'scanId': 'ios_tf_scan_1',
      'message': 'No roms folder was found in the selected TF card folder.',
    });

    expect(event.phase, Host4TfCardScanPhase.skipped);
    expect(event.message, contains('No roms folder'));
  });
}
