class Host4WebEmulatorCore {
  const Host4WebEmulatorCore({
    required this.name,
    required this.version,
    required this.zipUrl,
    required this.zipSha256,
    required this.wasmSha256,
  });

  static const fceumm = Host4WebEmulatorCore(
    name: 'fceumm',
    version: 'v1.22.2',
    zipUrl:
        'https://cdn.jsdelivr.net/gh/arianrhodsandlot/retroarch-emscripten-build@v1.22.2/retroarch/fceumm_libretro.zip',
    zipSha256:
        'c890126923a13586b7735c4a551e6010afe06ed059dc8fdeb6b55d8fadf2cf1e',
    wasmSha256:
        '99c4da050e7f341f09e42edc86d15fdecc51cb043b3dcf609b82a92f37960e20',
  );

  static const genesisPlusGx = Host4WebEmulatorCore(
    name: 'genesis_plus_gx',
    version: 'v1.22.2',
    zipUrl:
        'https://cdn.jsdelivr.net/gh/arianrhodsandlot/retroarch-emscripten-build@v1.22.2/retroarch/genesis_plus_gx_libretro.zip',
    zipSha256:
        '7bd0f36eef6f61e63541a0f51c3ccecb8a7139235d9c3734739acd9c4249b3c8',
    wasmSha256:
        '98de5d0096b82461c3a8bb999c617ecfbc913b585055fcfa5102161e774d44bb',
  );

  static const mgba = Host4WebEmulatorCore(
    name: 'mgba',
    version: 'v1.22.2',
    zipUrl:
        'https://cdn.jsdelivr.net/gh/arianrhodsandlot/retroarch-emscripten-build@v1.22.2/retroarch/mgba_libretro.zip',
    zipSha256:
        'd195371c3ea626c9246e9d3ab82ded4d93f3f99f85634af1588724cc44d47644',
    wasmSha256:
        '3a80ac96ae8e82628ed483e8bb528669b03e7186a2cf90abf89a6d66c3aba6bb',
  );

  static const snes9x = Host4WebEmulatorCore(
    name: 'snes9x',
    version: 'v1.22.2',
    zipUrl:
        'https://cdn.jsdelivr.net/gh/arianrhodsandlot/retroarch-emscripten-build@v1.22.2/retroarch/snes9x_libretro.zip',
    zipSha256:
        '0d50b0e18607af87c0c6ed2d9068fcfd19514be09b004068c2b5f06783499ef4',
    wasmSha256:
        '0a5f17704f96239ef05647d362b0dd478605368efce141382b8e22945062f1fd',
  );

  final String name;
  final String version;
  final String zipUrl;
  final String zipSha256;

  /// 解压后 `.wasm` 文件的 SHA-256，用于本地缓存校验。
  final String wasmSha256;

  /// 缓存目录下的子路径：`<name>/<version>/`。
  String get cacheSubPath => '$name/$version';

  /// 解压后的 `.js` 文件名。
  String get jsFileName => '${name}_libretro.js';

  /// 解压后的 `.wasm` 文件名。
  String get wasmFileName => '${name}_libretro.wasm';
}
