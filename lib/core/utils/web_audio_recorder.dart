import 'dart:async';
import 'dart:typed_data';

import 'web_audio_recorder_stub.dart'
    if (dart.library.html) 'web_audio_recorder_web.dart';

abstract class WebAudioRecorder {
  factory WebAudioRecorder() => getWebAudioRecorder();

  Future<bool> hasPermission();
  Future<void> start({
    required Function(Uint8List wavBytes, double maxAmp) onChunk,
    Duration chunkInterval = const Duration(seconds: 8),
    Function(double currentAmp)? onAmplitudeChanged,
  });
  Future<Uint8List?> stop();
  void dispose();
}
