// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:html' as html;
import 'dart:web_audio' as audio;
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'wav_encoder.dart';
import 'web_audio_recorder.dart';

WebAudioRecorder getWebAudioRecorder() {
  return WebAudioRecorderWeb();
}

class WebAudioRecorderWeb implements WebAudioRecorder {
  audio.AudioContext? _audioContext;
  html.MediaStream? _mediaStream;
  audio.MediaStreamAudioSourceNode? _sourceNode;
  audio.ScriptProcessorNode? _scriptProcessor;
  StreamSubscription? _audioSubscription;

  final List<double> _pcmBuffer = [];
  Function(Uint8List wavBytes, double maxAmp)? _onChunkCallback;
  Function(double currentAmp)? _onAmplitudeChangedCallback;
  Timer? _timer;
  bool _isRecording = false;

  @override
  Future<bool> hasPermission() async {
    try {
      final mediaDevices = html.window.navigator.mediaDevices;
      if (mediaDevices == null) return false;
      final stream = await mediaDevices.getUserMedia({'audio': true});
      for (final track in stream.getTracks()) {
        track.stop();
      }
      return true;
    } catch (e) {
      debugPrint('WebAudioRecorder: Permission check error: $e');
      return false;
    }
  }

  @override
  Future<void> start({
    required Function(Uint8List wavBytes, double maxAmp) onChunk,
    Duration chunkInterval = const Duration(seconds: 8),
    Function(double currentAmp)? onAmplitudeChanged,
  }) async {
    _onChunkCallback = onChunk;
    _onAmplitudeChangedCallback = onAmplitudeChanged;
    _pcmBuffer.clear();

    try {
      final mediaDevices = html.window.navigator.mediaDevices;
      if (mediaDevices == null) throw Exception('MediaDevices API not supported');

      _mediaStream = await mediaDevices.getUserMedia({
        'audio': {
          'echoCancellation': true,
          'noiseSuppression': true,
        }
      });

      _audioContext = audio.AudioContext();
      _sourceNode = _audioContext!.createMediaStreamSource(_mediaStream!);
      
      // Buffer size 4096, 1 input channel, 1 output channel
      _scriptProcessor = _audioContext!.createScriptProcessor(4096, 1, 1);

      _audioSubscription = _scriptProcessor!.onAudioProcess.listen((audio.AudioProcessingEvent event) {
        if (!_isRecording) return;
        final inputBuffer = event.inputBuffer;
        if (inputBuffer == null) return;
        
        final Float32List channelData = inputBuffer.getChannelData(0);
        double bufferMaxPeak = 0.0;

        for (int i = 0; i < channelData.length; i++) {
          final sample = channelData[i];
          _pcmBuffer.add(sample);
          final abs = sample.abs();
          if (abs > bufferMaxPeak) bufferMaxPeak = abs;
        }

        if (_onAmplitudeChangedCallback != null) {
          final ampDb = _peakToDb(bufferMaxPeak);
          _onAmplitudeChangedCallback!(ampDb);
        }
      });

      _sourceNode!.connectNode(_scriptProcessor!);
      _scriptProcessor!.connectNode(_audioContext!.destination!);

      _isRecording = true;

      _timer?.cancel();
      _timer = Timer.periodic(chunkInterval, (_) => _processChunk());
    } catch (e) {
      debugPrint('WebAudioRecorder: Failed to start recording: $e');
      rethrow;
    }
  }

  void _processChunk() {
    if (_pcmBuffer.isEmpty) return;

    final samplesToProcess = List<double>.from(_pcmBuffer);
    _pcmBuffer.clear();

    final inputSampleRate = _audioContext?.sampleRate?.toInt() ?? 44100;
    const targetSampleRate = 16000;

    final wavBytes = _convertAndEncode(samplesToProcess, inputSampleRate, targetSampleRate);
    final maxAmp = _computeMaxAmplitudedB(samplesToProcess);

    if (_onChunkCallback != null && wavBytes != null) {
      _onChunkCallback!(wavBytes, maxAmp);
    }
  }

  @override
  Future<Uint8List?> stop() async {
    _isRecording = false;
    _timer?.cancel();
    _timer = null;

    Uint8List? finalChunk;
    if (_pcmBuffer.isNotEmpty) {
      final samplesToProcess = List<double>.from(_pcmBuffer);
      _pcmBuffer.clear();

      final inputSampleRate = _audioContext?.sampleRate?.toInt() ?? 44100;
      const targetSampleRate = 16000;

      final wavBytes = _convertAndEncode(samplesToProcess, inputSampleRate, targetSampleRate);
      if (wavBytes != null) {
        final maxAmp = _computeMaxAmplitudedB(samplesToProcess);
        if (_onChunkCallback != null) {
          _onChunkCallback!(wavBytes, maxAmp);
        }
        finalChunk = wavBytes;
      }
    }

    _audioSubscription?.cancel();
    _audioSubscription = null;

    try {
      _scriptProcessor?.disconnect();
      _sourceNode?.disconnect();
    } catch (_) {}

    if (_mediaStream != null) {
      for (final track in _mediaStream!.getTracks()) {
        track.stop();
      }
      _mediaStream = null;
    }

    if (_audioContext != null) {
      try {
        await _audioContext!.close();
      } catch (_) {}
      _audioContext = null;
    }

    return finalChunk;
  }

  @override
  void dispose() {
    stop();
  }

  Uint8List? _convertAndEncode(List<double> samples, int srcRate, int targetRate) {
    if (samples.isEmpty) return null;

    final resampled = _resample(samples, srcRate, targetRate);
    final pcm16Bytes = Uint8List(resampled.length * 2);
    final byteData = ByteData.view(pcm16Bytes.buffer);

    for (int i = 0; i < resampled.length; i++) {
      final clamped = resampled[i].clamp(-1.0, 1.0);
      final int16Val = (clamped < 0 ? clamped * 32768 : clamped * 32767).round().toInt();
      byteData.setInt16(i * 2, int16Val, Endian.little);
    }

    return encodeWav(pcm16Bytes, targetRate, 1);
  }

  List<double> _resample(List<double> input, int srcRate, int targetRate) {
    if (srcRate == targetRate) return input;

    final ratio = srcRate / targetRate;
    final outputLength = (input.length / ratio).floor();
    final output = List<double>.filled(outputLength, 0.0);

    for (int i = 0; i < outputLength; i++) {
      final srcPos = i * ratio;
      final idx = srcPos.floor();
      final fract = srcPos - idx;

      if (idx + 1 < input.length) {
        output[i] = (1.0 - fract) * input[idx] + fract * input[idx + 1];
      } else if (idx < input.length) {
        output[i] = input[idx];
      }
    }
    return output;
  }

  double _computeMaxAmplitudedB(List<double> samples) {
    if (samples.isEmpty) return -160.0;
    double maxPeak = 0.0;
    for (final s in samples) {
      final abs = s.abs();
      if (abs > maxPeak) maxPeak = abs;
    }
    return _peakToDb(maxPeak);
  }

  double _peakToDb(double maxPeak) {
    if (maxPeak <= 1e-5) return -160.0;
    final db = 20 * (math.log(maxPeak) / math.ln10);
    return db.clamp(-160.0, 0.0);
  }
}
