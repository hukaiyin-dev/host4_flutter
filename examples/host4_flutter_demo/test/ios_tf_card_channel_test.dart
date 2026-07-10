import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:host4_flutter_demo/platform/ios_tf_card_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('host4_flutter_demo/ios_tf_card');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('scanIosTfCard returns typed scan result from native payload', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'scanRoms');
          expect(call.arguments, isNull);
          return <String, Object?>{
            'rootPath': '/Volumes/TF',
            'romsPath': '/Volumes/TF/roms',
            'platformCount': 1,
            'gameCount': 2,
            'platforms': <Object?>[
              <String, Object?>{
                'name': 'gba',
                'fullName': 'Game Boy Advance',
                'directory': '/Volumes/TF/roms/gba',
                'gameCount': 2,
              },
            ],
            'games': <Object?>[
              <String, Object?>{
                'platform': 'gba',
                'platformName': 'Game Boy Advance',
                'name': '塞尔达传说 缩小帽',
                'fileName': '塞尔达传说 缩小帽.zip',
                'relativePath': '塞尔达传说 缩小帽.zip',
                'absolutePath': '/Volumes/TF/roms/gba/塞尔达传说 缩小帽.zip',
                'image': './images/zelda.png',
                'video': './videos/zelda.mp4',
                'desc': '示例游戏',
              },
              <String, Object?>{
                'platform': 'gba',
                'platformName': 'Game Boy Advance',
                'name': '星际传送者',
                'fileName': '星际传送者.zip',
                'relativePath': '星际传送者.zip',
                'absolutePath': '/Volumes/TF/roms/gba/星际传送者.zip',
              },
            ],
          };
        });

    final result = await scanIosTfCard();

    expect(result.rootPath, '/Volumes/TF');
    expect(result.romsPath, '/Volumes/TF/roms');
    expect(result.platformCount, 1);
    expect(result.gameCount, 2);
    expect(result.platforms.single.name, 'gba');
    expect(result.platforms.single.fullName, 'Game Boy Advance');
    expect(result.games.first.name, '塞尔达传说 缩小帽');
    expect(result.games.first.image, './images/zelda.png');
    expect(result.games.last.desc, isNull);
  });

  test('scanIosTfCard can force opening directory picker', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'scanRoms');
          expect(call.arguments, <String, Object?>{'forcePick': true});
          return <String, Object?>{
            'rootPath': '/Volumes/TF',
            'romsPath': '/Volumes/TF/roms',
            'platformCount': 0,
            'gameCount': 0,
            'platforms': <Object?>[],
            'games': <Object?>[],
          };
        });

    final result = await scanIosTfCard(forcePick: true);

    expect(result.rootPath, '/Volumes/TF');
    expect(result.platforms, isEmpty);
    expect(result.games, isEmpty);
  });
}
