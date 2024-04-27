/*
 * Droits d'auteur 2024 Fralacticus fralacticus@gmail.com
 * Licence CC BY-SA 4.0, voir le fichier LICENSE
 */

import '../core/PrettyHexExtensions.dart';
import 'dart:typed_data';

/// Le fichier contient des classes pour chaque partie de l'entête et données d'un fichier WAV

// Descripteur de bloc RIFF
class ChunkId {
  late final Uint8List value_bytes;
  late final String value_real;
  ChunkId(this.value_bytes) { value_real = String.fromCharCodes(value_bytes); }
  @override
  String toString() { return "ChunkId: ${value_bytes.toHexString()} => $value_real"; }
}

class ChunkSize{
  late final Uint8List value_bytes;
  late final int value_real;
  ChunkSize(this.value_bytes) { value_real = value_bytes.buffer.asByteData().getUint32(0, Endian.little); }
  @override
  String toString() { return "ChunkSize: ${value_bytes.toHexString()} => $value_real"; }
}

class Format {
  late final Uint8List value_bytes;
  late final String value_real;
  Format(this.value_bytes) { value_real = String.fromCharCodes(value_bytes); }
  @override
  String toString() { return "Format: ${value_bytes.toHexString()} => $value_real"; }
}

// Sous-bloc 'fmt'
class Subchunck1ID {
  late final Uint8List value_bytes;
  late final String value_real;
  Subchunck1ID(this.value_bytes) { value_real = String.fromCharCodes(value_bytes); }
  @override
  String toString() { return "Subchunck1ID: ${value_bytes.toHexString()} => $value_real"; }
}

class Subchunk1Size {
  late final Uint8List value_bytes;
  late final int value_real;
  Subchunk1Size(this.value_bytes) { value_real = value_bytes.buffer.asByteData().getUint32(0, Endian.little); }
  @override
  String toString() { return "Subchunk1Size: ${value_bytes.toHexString()} => $value_real"; }
}

class AudioFormat {
  late final Uint8List value_bytes;
  late final int value_real;
  AudioFormat(this.value_bytes) { value_real = value_bytes.buffer.asByteData().getUint16(0, Endian.little); }
  @override
  String toString() { return "AudioFormat: ${value_bytes.toHexString()} => $value_real (${_meaning(value_real)})"; }

  String _meaning(int value) {
    switch(value) {
      case 1 : return "PCM";
      case 3 : return "PCM Flottant";
      case 65534 : return "WAVE_FORMAT_EXTENSIBLE";
      default: throw "Impossible";
    }
  }
}

class NumChannels {
  late final Uint8List value_bytes;
  late final int value_real;
  NumChannels(this.value_bytes) { value_real = value_bytes.buffer.asByteData().getUint16(0, Endian.little); }
  @override
  String toString() { return "NumChannels: ${value_bytes.toHexString()} => $value_real"; }
}

class SampleRate {
  late final Uint8List value_bytes;
  late final int value_real;
  SampleRate(this.value_bytes) { value_real = value_bytes.buffer.asByteData().getUint32(0, Endian.little); }
  @override
  String toString() { return "SampleRate: ${value_bytes.toHexString()} => $value_real"; }
}

class ByteRate {
  late final Uint8List value_bytes;
  late final int value_real;
  ByteRate(this.value_bytes) { value_real = value_bytes.buffer.asByteData().getUint32(0, Endian.little); }
  @override
  String toString() { return "ByteRate: ${value_bytes.toHexString()} => $value_real"; }
}

class BlockAlign {
  late final Uint8List value_bytes;
  late final int value_real;
  BlockAlign(this.value_bytes) { value_real = value_bytes.buffer.asByteData().getUint16(0, Endian.little); }
  @override
  String toString() { return "BlockAlign: ${value_bytes.toHexString()} => $value_real"; }
}

class BitsPerSample {
  late final Uint8List value_bytes;
  late final int value_real;
  BitsPerSample(this.value_bytes) { value_real = value_bytes.buffer.asByteData().getUint16(0, Endian.little); }
  @override
  String toString() { return "BitsPerSample: ${value_bytes.toHexString()} => $value_real"; }
}

// Sous-bloc 'data'
class Subchunck2ID{
  late final Uint8List value_bytes;
  late final String value_real;
  Subchunck2ID(this.value_bytes) { value_real = String.fromCharCodes(value_bytes); }
  @override
  String toString() { return "Subchunck2ID: ${value_bytes.toHexString()} => $value_real"; }
}

class Subchunck2Size {
  late final Uint8List value_bytes;
  late final int value_real;
  Subchunck2Size(this.value_bytes) { value_real = value_bytes.buffer.asByteData().getUint32(0, Endian.little); }
  @override
  String toString() { return "Subchunck2Size: ${value_bytes.toHexString()} => $value_real"; }
}

class Data {
  late final Uint8List value_bytes;
  Data(this.value_bytes);
  @override
  String toString(){
    String first_part = value_bytes.sublist(0, value_bytes.length >= 8 ? 8 : value_bytes.length).toHexString();
    String last_part = value_bytes.sublist(value_bytes.length > 8 ? value_bytes.length - 8 : 0, value_bytes.length).toHexString();
    return "Data (partial): $first_part  ...  $last_part";
  }
}