import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'WebRTC capture canvas is independent from the rate-limited Flutter preview',
    () {
      final source = File('assets/emulator/index.html').readAsStringSync();

      expect(source, contains('probe.webRtcCaptureCanvas'));
      expect(source, contains('probe.webRtcCaptureTrack.requestFrame'));
      expect(source, contains('publisherProbe.webRtcEnabled = true'));
      expect(source, contains('probe.webRtcEnabled === true'));
      expect(source, contains('transportCapturedFrames'));
      expect(source, contains('Number(probe.webRtcCapturedFrames)'));
      expect(source, contains("webrtc_video_stats"));
      expect(source, contains('framesPerSecond'));
      expect(source, contains('maxFramerate = 60'));
      expect(source, contains('webRtcCaptureTimerActive'));
      expect(
        source,
        contains('state.captureInFlight'),
        reason:
            'The default media path must allow at most one requested canvas '
            'frame to wait for the encoder. Otherwise WKWebView can retain a '
            'stale pre-RTP capture FIFO that RTP statistics cannot observe.',
      );
      expect(source, contains('state.captureSender.getStats()'));
      expect(source, contains('probe.webRtcFrameDirty = true'));
      expect(source, contains('playoutDelayHint = 0'));
      expect(source, contains('webRtcLastRequestedAt'));
      expect(
        source,
        contains('state.stream = probeCanvas.captureStream(0)'),
        reason:
            'The release path must be driven by fresh Core callbacks rather '
            'than WebKit\'s autonomous captureStream frame FIFO.',
      );
      expect(source, contains('webRtcLatencyProbeEnabled'));
      expect(source, contains('var markerWidth = 256'));
      expect(
        source,
        contains('128 + markerBit * 4'),
        reason:
            'The timestamp follows the magic in the same source row so the '
            'optical probe survives native video rotation and cropping.',
      );
      expect(
        source,
        contains('0xA55A3CC3'),
        reason:
            'The debug-only optical latency marker needs a 16-bit preamble so '
            'a scaled, encoded frame cannot be mistaken for arbitrary game art.',
      );
      expect(source, contains('visualLatencyP95Ms'));
      expect(source, contains('function signalPublisherOffer(reason)'));
      expect(source, contains("config.webRtcTransport === 'data' ? 'data' : 'media'"));
      expect(source, contains("webrtc_transport_selected"));
      expect(source, contains("host4-core-frames"));
      expect(source, contains("signalPublisherOffer('initial_data_channel_ready')"));
      expect(source, contains("state.transport === 'data'"));
      expect(source, contains("createPublisherDataChannel()"));
      expect(source, contains("webrtc_data_stats"));
      expect(source, contains("webrtc_data_frame"));
      expect(
        source,
        contains('function decodeLatestDataFrame()'),
        reason:
            'The data-channel viewer must decode only its newest pending frame; '
            'parallel decodes can paint an older game state after a newer one.',
      );
      expect(source, contains('state.pendingDataFrame = frame.data'));
      expect(source, contains('state.dataFrameDecoding = true'));
      expect(
        source,
        contains(
          "state.dataFirstFrameReported = false;\n" 
          "              var canvas = document.createElement('canvas');",
        ),
        reason:
            'A reconnected data channel must report its first rendered frame '
            'again. Otherwise a recoverable peer failure leaves Flutter\'s '
            'waiting overlay over a live game image.',
      );
      expect(
        source,
        contains(
          "state.transport === 'data' &&\n" 
          "                  peer.connectionState === 'connected' &&\n" 
          "                  state.dataFramesReceived > 0",
        ),
        reason:
            'A recoverable transport failure can reuse the same data channel. '
            'When it reconnects after frames were already rendered, Flutter '
            'needs an explicit frame-ready event to remove its error cover.',
      );
      expect(source, contains("signalPublisherOffer('initial_peer_ready')"));
      expect(source, contains('function resetPublisherTransport()'));
      expect(source, contains('resetPublisherTransport();\n                  startPublisherTrack();'));
      expect(
        source,
        contains('if (probe.webRtcEnabled === true) return;'),
        reason:
            'A WebRTC publisher must not also PNG/Base64 every Core frame over '
            'the Flutter bridge; that duplicate path adds avoidable latency.',
      );
      expect(source, contains('requestVideoFrameCallback'));
      expect(source, isNot(contains('var isWebRtcPublisher = webRtcPreview')));
      expect(source, contains('probe.flutterPreviewLastAt'));
      expect(
        source.indexOf('probe.webRtcCaptureCanvas'),
        lessThan(source.indexOf('probe.flutterPreviewLastAt')),
        reason:
            'The WebRTC frame must be written before the preview throttle can return.',
      );
    },
  );
}
