import 'package:flutter_test/flutter_test.dart';
import 'package:host4_flutter_web_emulator/src/host4_web_emulator_output_probe.dart';

void main() {
  const supportedSource = '''
var Module = {};
var RWA = { context: { sampleRate: 48000 } };
function _RWebAudioQueueBuffer(num_frames,left,right){
  return num_frames;
}
var _glTexImage2D=(target,level,internalFormat,width,height,border,format,type,pixels)=>{
  return pixels;
};
var _glTexSubImage2D=(target,level,xoffset,yoffset,width,height,format,type,pixels)=>{
  return pixels;
};
var wasmImports = { Fa: _RWebAudioQueueBuffer };
''';

  test('leaves core source byte-for-byte unchanged when disabled', () {
    expect(
      instrumentWebEmulatorCoreSource(supportedSource, enabled: false),
      supportedSource,
    );
  });

  test('instruments the audio queue definition before the Wasm import map', () {
    final transformed = instrumentWebEmulatorCoreSource(
      supportedSource,
      enabled: true,
    );

    expect(hasWebEmulatorOutputProbe(transformed), isTrue);
    expect(
      transformed.indexOf('host4-output-probe-v1'),
      lessThan(transformed.indexOf('var wasmImports')),
    );
    expect(transformed, contains('audioCallbacks'));
    expect(transformed, contains('audioFrames'));
    expect(transformed, contains('return num_frames;'));
  });

  test('records texture-upload metadata before WebGL calls without copying pixels', () {
    final transformed = instrumentWebEmulatorCoreSource(
      supportedSource,
      enabled: true,
    );

    expect(transformed, contains('textureUploadCalls'));
    expect(transformed, contains('textureUploadPixelCalls'));
    expect(transformed, contains('textureUploadWidth=width'));
    expect(transformed, contains('textureUploadHeight=height'));
    expect(transformed, contains('textureUploadPointer=pixels'));
    expect(transformed, contains('return pixels;'));
    expect(transformed, isNot(contains('host4OutputVideoFrame')));
  });

  test('keeps a rate-limited RGBA frame copy while the Wasm pixels are valid', () {
    final transformed = instrumentWebEmulatorCoreSource(
      supportedSource,
      enabled: true,
    );

    expect(transformed, contains('HEAPU8.subarray'));
    expect(transformed, contains('host4OutputProbe.videoFrame.set'));
    expect(transformed, contains('videoCapturedFrames'));
    expect(transformed, contains('videoCaptureIntervalMs'));
    expect(transformed, contains('videoCaptureIntervalMs||100;'));
    expect(transformed, contains('format===6408&&type===5121'));
    expect(transformed, contains('return pixels;'));
  });

  test('adds a bounded stereo PCM capture without changing playback return', () {
    final transformed = instrumentWebEmulatorCoreSource(
      supportedSource,
      enabled: true,
    );

    expect(transformed, contains('new Float32Array'));
    expect(transformed, contains('HEAPF32.subarray'));
    expect(transformed, contains('pcmCaptureAvailable'));
    expect(transformed, contains('pcmCapturedFrames'));
    expect(transformed, contains('pcmBufferedFrames'));
    expect(transformed, contains('mediaTimestampUs'));
    expect(transformed, contains('try{'));
    expect(transformed, contains('catch(_){'));
    expect(transformed, contains('return num_frames;'));
  });

  test('installs the standard RetroArch video callback receiver', () {
    final transformed = instrumentWebEmulatorCoreSource(
      supportedSource,
      enabled: true,
    );

    expect(transformed, contains('captureCoreVideoFrame'));
    expect(transformed, contains('coreVideoPixelFormat'));
    expect(transformed, contains('coreVideoCapturedFrames'));
    expect(transformed, contains('pixelFormat!==1'));
  });

  test('fails closed for an unsupported core source format', () {
    const unsupportedSource = 'function queueAudio() {}';

    final transformed = instrumentWebEmulatorCoreSource(
      unsupportedSource,
      enabled: true,
    );

    expect(transformed, unsupportedSource);
    expect(hasWebEmulatorOutputProbe(transformed), isFalse);
  });
}
