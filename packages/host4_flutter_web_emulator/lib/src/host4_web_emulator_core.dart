class Host4WebEmulatorCore {
  const Host4WebEmulatorCore({
    required this.name,
    required this.version,
    required this.zipUrl,
    required this.zipSha256,
  });

  static const mgba = Host4WebEmulatorCore(
    name: 'mgba',
    version: 'v1.22.2',
    zipUrl:
        'https://cdn.jsdelivr.net/gh/arianrhodsandlot/retroarch-emscripten-build@v1.22.2/retroarch/mgba_libretro.zip',
    zipSha256:
        'd195371c3ea626c9246e9d3ab82ded4d93f3f99f85634af1588724cc44d47644',
  );

  final String name;
  final String version;
  final String zipUrl;
  final String zipSha256;
}
