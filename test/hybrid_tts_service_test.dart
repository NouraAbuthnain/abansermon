import 'package:flutter_test/flutter_test.dart';
import 'package:abansermon/data/ai/hybrid_tts_service.dart';
import 'package:abansermon/data/ai/google_cloud_tts_provider.dart';
import 'package:abansermon/data/ai/flutter_tts_provider.dart';

class MockGoogleCloudTtsProvider implements GoogleCloudTtsProvider {
  bool speakCalled = false;
  bool stopCalled = false;
  double volume = 1.0;
  bool isMuted = false;
  bool initializeCalled = false;
  bool shouldThrow = false;

  @override
  Future<void> initialize() async {
    initializeCalled = true;
  }

  @override
  Future<void> speak(String text, String languageCode) async {
    speakCalled = true;
    if (shouldThrow) {
      throw Exception("GCP TTS synthetic error");
    }
  }

  @override
  Future<void> stop() async {
    stopCalled = true;
  }

  @override
  Future<void> setVolume(double volume) async {
    this.volume = volume;
  }

  @override
  Future<void> setMuted(bool isMuted) async {
    this.isMuted = isMuted;
  }

  @override
  void dispose() {}
}

class MockFlutterTtsProvider implements FlutterTtsProvider {
  bool speakCalled = false;
  bool stopCalled = false;
  double volume = 1.0;
  bool isMuted = false;
  bool initializeCalled = false;
  bool shouldThrow = false;

  @override
  Future<void> initialize() async {
    initializeCalled = true;
  }

  @override
  Future<void> speak(String text, String languageCode) async {
    speakCalled = true;
    if (shouldThrow) {
      throw Exception("Native TTS synthetic error");
    }
  }

  @override
  Future<void> stop() async {
    stopCalled = true;
  }

  @override
  Future<void> setVolume(double volume) async {
    this.volume = volume;
  }

  @override
  Future<void> setMuted(bool isMuted) async {
    this.isMuted = isMuted;
  }

  @override
  void dispose() {}
}

void main() {
  group('HybridTtsService Tests', () {
    late MockGoogleCloudTtsProvider mockGcp;
    late MockFlutterTtsProvider mockNative;
    late HybridTtsService service;

    setUp(() {
      mockGcp = MockGoogleCloudTtsProvider();
      mockNative = MockFlutterTtsProvider();
      service = HybridTtsService(
        gcpProvider: mockGcp,
        nativeProvider: mockNative,
      );
    });

    test('initialize calls initialize on both providers', () async {
      await service.initialize();
      expect(mockGcp.initializeCalled, isTrue);
      expect(mockNative.initializeCalled, isTrue);
    });

    test('routes to GCP TTS when GCP is healthy', () async {
      await service.initialize();
      expect(service.isGcpHealthy, isTrue);

      await service.speak("Hello", "en");

      expect(mockGcp.speakCalled, isTrue);
      expect(mockNative.speakCalled, isFalse);
    });

    test('routes to Native fallback when GCP fails', () async {
      await service.initialize();
      mockGcp.shouldThrow = true;

      await service.speak("Hello", "en");

      expect(mockGcp.speakCalled, isTrue);
      expect(service.isGcpHealthy, isFalse);
      expect(mockNative.speakCalled, isTrue);
    });

    test('updates volume and mute on both providers', () async {
      await service.setVolume(0.8);
      expect(mockGcp.volume, 0.8);
      expect(mockNative.volume, 0.8);

      await service.setMuted(true);
      expect(mockGcp.isMuted, isTrue);
      expect(mockNative.isMuted, isTrue);
    });

    test('stops both providers', () async {
      await service.stop();
      expect(mockGcp.stopCalled, isTrue);
      expect(mockNative.stopCalled, isTrue);
    });
  });
}
