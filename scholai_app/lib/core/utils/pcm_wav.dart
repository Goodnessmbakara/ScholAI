import 'dart:typed_data';

/// Wraps raw little-endian 16-bit PCM in a minimal WAV header for playback.
Uint8List pcmToWav(
  Uint8List pcm, {
  int sampleRate = 24000,
  int channels = 1,
  int bitsPerSample = 16,
}) {
  final byteRate = sampleRate * channels * bitsPerSample ~/ 8;
  final blockAlign = channels * bitsPerSample ~/ 8;
  final dataSize = pcm.length;
  final buffer = BytesBuilder(copy: false)
    ..add(ascii('RIFF'))
    ..add(_u32le(36 + dataSize))
    ..add(ascii('WAVE'))
    ..add(ascii('fmt '))
    ..add(_u32le(16))
    ..add(_u16le(1)) // PCM
    ..add(_u16le(channels))
    ..add(_u32le(sampleRate))
    ..add(_u32le(byteRate))
    ..add(_u16le(blockAlign))
    ..add(_u16le(bitsPerSample))
    ..add(ascii('data'))
    ..add(_u32le(dataSize))
    ..add(pcm);
  return buffer.toBytes();
}

List<int> ascii(String s) => s.codeUnits;

Uint8List _u16le(int v) =>
    Uint8List(2)..buffer.asByteData().setUint16(0, v, Endian.little);

Uint8List _u32le(int v) =>
    Uint8List(4)..buffer.asByteData().setUint32(0, v, Endian.little);
