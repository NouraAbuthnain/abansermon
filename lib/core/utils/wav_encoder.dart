import 'dart:io';
import 'dart:typed_data';

/// Encodes raw PCM16 bytes into a valid WAV file with a 44-byte header.
Uint8List encodeWav(List<int> audioData, int sampleRate, int channels) {
  final numSamples = audioData.length ~/ 2;
  final numBytes = numSamples * channels * 2;
  
  final header = Uint8List(44);
  final byteData = ByteData.view(header.buffer);
  
  // "RIFF"
  byteData.setUint32(0, 0x52494646, Endian.big);
  // ChunkSize
  byteData.setUint32(4, 36 + numBytes, Endian.little);
  // "WAVE"
  byteData.setUint32(8, 0x57415645, Endian.big);
  // "fmt "
  byteData.setUint32(12, 0x666D7420, Endian.big);
  // Subchunk1Size (16 for PCM)
  byteData.setUint32(16, 16, Endian.little);
  // AudioFormat (1 for PCM)
  byteData.setUint16(20, 1, Endian.little);
  // NumChannels
  byteData.setUint16(22, channels, Endian.little);
  // SampleRate
  byteData.setUint32(24, sampleRate, Endian.little);
  // ByteRate
  byteData.setUint32(28, sampleRate * channels * 2, Endian.little);
  // BlockAlign
  byteData.setUint16(32, channels * 2, Endian.little);
  // BitsPerSample
  byteData.setUint16(34, 16, Endian.little);
  // "data"
  byteData.setUint32(36, 0x64617461, Endian.big);
  // Subchunk2Size
  byteData.setUint32(40, numBytes, Endian.little);

  final builder = BytesBuilder();
  builder.add(header);
  builder.add(audioData);
  
  return builder.toBytes();
}
