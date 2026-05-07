import 'dart:typed_data';

class AudioUtils {
  /// Adds a standard 44-byte WAV header to raw PCM bytes.
  /// Assumes 16-bit, 16kHz, Mono.
  static Uint8List addWavHeader(List<int> pcmBytes, int sampleRate) {
    final int fileSize = pcmBytes.length + 36;
    final int byteRate = sampleRate * 2; // 16-bit = 2 bytes per sample
    
    final header = ByteData(44);
    
    // RIFF header
    header.setUint8(0, 0x52); // R
    header.setUint8(1, 0x49); // I
    header.setUint8(2, 0x46); // F
    header.setUint8(3, 0x46); // F
    header.setUint32(4, fileSize, Endian.little);
    
    // WAVE header
    header.setUint8(8, 0x57); // W
    header.setUint8(9, 0x41); // A
    header.setUint8(10, 0x56); // V
    header.setUint8(11, 0x45); // E
    
    // fmt subchunk
    header.setUint8(12, 0x66); // f
    header.setUint8(13, 0x6d); // m
    header.setUint8(14, 0x74); // t
    header.setUint8(15, 0x20); // space
    header.setUint32(16, 16, Endian.little); // Subchunk1Size
    header.setUint16(20, 1, Endian.little); // AudioFormat (1 = PCM)
    header.setUint16(22, 1, Endian.little); // NumChannels (1 = Mono)
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, 2, Endian.little); // BlockAlign
    header.setUint16(34, 16, Endian.little); // BitsPerSample
    
    // data subchunk
    header.setUint8(36, 0x64); // d
    header.setUint8(37, 0x61); // a
    header.setUint8(38, 0x74); // t
    header.setUint8(39, 0x61); // a
    header.setUint32(40, pcmBytes.length, Endian.little);
    
    final fullWav = Uint8List(44 + pcmBytes.length);
    fullWav.setRange(0, 44, header.buffer.asUint8List());
    fullWav.setRange(44, fullWav.length, pcmBytes);
    
    return fullWav;
  }
}
