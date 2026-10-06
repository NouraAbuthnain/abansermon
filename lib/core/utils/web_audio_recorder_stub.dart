import 'dart:typed_data';
import 'web_audio_recorder.dart';

WebAudioRecorder getWebAudioRecorder() {
  return WebAudioRecorderStub();
}

class WebAudioRecorderStub implements WebAudioRecorder {
  @override
  Future<bool> hasPermission() async => false;

  @override
  Future<void> start({
    required Function(Uint8List wavBytes, double maxAmp) onChunk,
    Duration chunkInterval = const Duration(seconds: 8),
    Function(double currentAmp)? onAmplitudeChanged,
  }) async {}

  @override
  Future<Uint8List?> stop() async => null;

  @override
  void dispose() {}
}
