/// A unique marker used by both source validation and the injected runtime.
const webEmulatorOutputProbeMarker = 'host4-output-probe-v1';

const _audioQueueFunctionStart =
    'function _RWebAudioQueueBuffer(num_frames,left,right){';
const _textureImage2dFunctionStart =
    'var _glTexImage2D=(target,level,internalFormat,width,height,border,format,type,pixels)=>{';
const _textureSubImage2dFunctionStart =
    'var _glTexSubImage2D=(target,level,xoffset,yoffset,width,height,format,type,pixels)=>{';

/// Adds aggregate-only telemetry at the WebAudio queue callback definition.
///
/// The Emscripten runtime stores this function in its Wasm import map during
/// initialization. It therefore must be instrumented at its definition rather
/// than replaced after the emulator reports that it is ready. The injected code
/// neither reads PCM memory nor changes the callback's return value.
String instrumentWebEmulatorCoreSource(
  String source, {
  required bool enabled,
}) {
  if (!enabled || hasWebEmulatorOutputProbe(source)) return source;
  if (!source.contains(_audioQueueFunctionStart)) return source;

  const instrumentation = '''
/*host4-output-probe-v1*/
var host4OutputProbe=Module.host4OutputProbe;
if(!host4OutputProbe){host4OutputProbe={audioCallbacks:0,audioFrames:0};Module.host4OutputProbe=host4OutputProbe;}
host4OutputProbe.audioCallbacks+=1;
host4OutputProbe.audioFrames+=num_frames;
host4OutputProbe.audioLastFrames=num_frames;
if(RWA&&RWA.context){host4OutputProbe.audioSampleRate=RWA.context.sampleRate;}
try{
var pcmRate=host4OutputProbe.audioSampleRate||48000;
var pcmCapacity=host4OutputProbe.pcmCapacityFrames||Math.max(1,Math.round(pcmRate));
if(!host4OutputProbe.pcmBuffer){host4OutputProbe.pcmBuffer=new Float32Array(pcmCapacity*2);host4OutputProbe.pcmCapacityFrames=pcmCapacity;host4OutputProbe.pcmWriteFrame=0;host4OutputProbe.pcmCapturedFrames=0;host4OutputProbe.pcmBufferedFrames=0;}
var pcmLeft=HEAPF32.subarray(left>>2,(left>>2)+num_frames);
var pcmRight=HEAPF32.subarray(right>>2,(right>>2)+num_frames);
for(var pcmIndex=0;pcmIndex<num_frames;pcmIndex+=1){var pcmFrame=(host4OutputProbe.pcmWriteFrame+pcmIndex)%pcmCapacity;host4OutputProbe.pcmBuffer[pcmFrame*2]=pcmLeft[pcmIndex];host4OutputProbe.pcmBuffer[pcmFrame*2+1]=pcmRight[pcmIndex];}
host4OutputProbe.pcmWriteFrame=(host4OutputProbe.pcmWriteFrame+num_frames)%pcmCapacity;
host4OutputProbe.pcmCapturedFrames+=num_frames;
host4OutputProbe.pcmBufferedFrames=Math.min(pcmCapacity,host4OutputProbe.pcmBufferedFrames+num_frames);
host4OutputProbe.mediaTimestampUs=Math.round(host4OutputProbe.pcmCapturedFrames*1000000/pcmRate);
host4OutputProbe.pcmCaptureAvailable=true;
}catch(_){host4OutputProbe.pcmCaptureAvailable=false;}
host4OutputProbe.captureCoreVideoFrame=function(pointer,width,height,pitch,pixelFormat){try{if(!pointer||!width||!height||pixelFormat!==1){return;}var now=typeof performance!=="undefined"?performance.now():Date.now();var interval=host4OutputProbe.coreVideoCaptureIntervalMs||100;if(host4OutputProbe.coreVideoLastCaptureAt&&now-host4OutputProbe.coreVideoLastCaptureAt<interval){return;}var byteLength=width*height*4;if(!host4OutputProbe.coreVideoFrame||host4OutputProbe.coreVideoFrame.byteLength!==byteLength){host4OutputProbe.coreVideoFrame=new Uint8Array(byteLength);}var copyStarted=now;for(var y=0;y<height;y+=1){var src=pointer+y*pitch;var dst=y*width*4;for(var x=0;x<width*4;x+=4){host4OutputProbe.coreVideoFrame[dst+x]=HEAPU8[src+x+2];host4OutputProbe.coreVideoFrame[dst+x+1]=HEAPU8[src+x+1];host4OutputProbe.coreVideoFrame[dst+x+2]=HEAPU8[src+x];host4OutputProbe.coreVideoFrame[dst+x+3]=255;}}host4OutputProbe.coreVideoLastCaptureAt=now;host4OutputProbe.coreVideoCapturedFrames=(host4OutputProbe.coreVideoCapturedFrames||0)+1;host4OutputProbe.coreVideoWidth=width;host4OutputProbe.coreVideoHeight=height;host4OutputProbe.coreVideoPitch=pitch;host4OutputProbe.coreVideoPixelFormat=pixelFormat;host4OutputProbe.coreVideoByteLength=byteLength;host4OutputProbe.coreVideoCopyDurationMs=(typeof performance!=="undefined"?performance.now():Date.now())-copyStarted;host4OutputProbe.coreVideoCaptureAvailable=true;}catch(_){host4OutputProbe.coreVideoCaptureAvailable=false;}};
''';

  var transformed = source.replaceFirst(
    _audioQueueFunctionStart,
    '$_audioQueueFunctionStart$instrumentation',
  );

  const textureInstrumentation = '''
var host4OutputProbe=Module.host4OutputProbe;
if(!host4OutputProbe){host4OutputProbe={audioCallbacks:0,audioFrames:0};Module.host4OutputProbe=host4OutputProbe;}
host4OutputProbe.textureUploadCalls=(host4OutputProbe.textureUploadCalls||0)+1;
if(pixels&&width&&height){host4OutputProbe.textureUploadPixelCalls=(host4OutputProbe.textureUploadPixelCalls||0)+1;host4OutputProbe.textureUploadWidth=width;host4OutputProbe.textureUploadHeight=height;host4OutputProbe.textureUploadFormat=format;host4OutputProbe.textureUploadType=type;host4OutputProbe.textureUploadPointer=pixels;if(format===6408&&type===5121){try{var videoNow=typeof performance!=="undefined"?performance.now():Date.now();var videoCaptureIntervalMs=host4OutputProbe.videoCaptureIntervalMs||100;if(!host4OutputProbe.videoLastCaptureAt||videoNow-host4OutputProbe.videoLastCaptureAt>=videoCaptureIntervalMs){var videoByteLength=width*height*4;if(!host4OutputProbe.videoFrame||host4OutputProbe.videoFrame.byteLength!==videoByteLength){host4OutputProbe.videoFrame=new Uint8Array(videoByteLength);}var videoCopyStarted=videoNow;host4OutputProbe.videoFrame.set(HEAPU8.subarray(pixels,pixels+videoByteLength));host4OutputProbe.videoLastCaptureAt=videoNow;host4OutputProbe.videoCapturedFrames=(host4OutputProbe.videoCapturedFrames||0)+1;host4OutputProbe.videoByteLength=videoByteLength;host4OutputProbe.videoCopyDurationMs=(typeof performance!=="undefined"?performance.now():Date.now())-videoCopyStarted;host4OutputProbe.videoCaptureAvailable=true;}}catch(_){host4OutputProbe.videoCaptureAvailable=false;}}}
''';
  if (transformed.contains(_textureImage2dFunctionStart)) {
    transformed = transformed.replaceFirst(
      _textureImage2dFunctionStart,
      '$_textureImage2dFunctionStart$textureInstrumentation',
    );
  }
  if (transformed.contains(_textureSubImage2dFunctionStart)) {
    transformed = transformed.replaceFirst(
      _textureSubImage2dFunctionStart,
      '$_textureSubImage2dFunctionStart$textureInstrumentation',
    );
  }
  return transformed;
}

bool hasWebEmulatorOutputProbe(String source) {
  return source.contains(webEmulatorOutputProbeMarker);
}
