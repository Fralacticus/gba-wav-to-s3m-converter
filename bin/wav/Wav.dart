/*
 * Droits d'auteur 2024 Fralacticus fralacticus@gmail.com
 * Licence zlib, voir le fichier LICENSE
 */

import 'dart:io';
import 'dart:typed_data';
import 'WavHeaders.dart';

/// Cette classe offre un moyen pratique de lire les différents composants d'un fichier WAV.
class Wav {
  // Descripteur de bloc RIFF
  late ChunkId chunkID;
  late ChunkSize chunkSize;
  late Format format;
  // Sous-bloc 'fmt'
  late Subchunck1ID subChunk1ID;
  late Subchunk1Size subChunk1Size;
  late AudioFormat audioFormat;
  late NumChannels numChannels;
  late SampleRate sampleRate;
  late ByteRate byteRate;
  late BlockAlign blockAlign;
  late BitsPerSample bitsPerSample;
  // Sous-bloc 'data'
  late Subchunck2ID subChunk2ID;
  late Subchunck2Size subChunk2Size;
  late Data data;

  /// Crée une instance de [Wav] pour lire les informations à partir du chemin de fichier spécifié.
  Wav(String file_path) {
    read_from_file(file_path);
  }

  /// Lit le fichier WAV spécifié et initialise les champs de l'entête et des données.
  ///
  /// [file_path] Chemin d'accès au fichier WAV à lire.
  /// Lance une exception et termine le programme si la lecture échoue.
  void read_from_file(String file_path) {
    RandomAccessFile? file;

    try {
      file = File(file_path).openSync();

      // RIFF chunk descriptor
      chunkID = ChunkId(file.readSync(4));
      chunkSize = ChunkSize(file.readSync(4));
      format = Format(file.readSync(4));

      // fmt sub_chunck
      subChunk1ID = Subchunck1ID(file.readSync(4));
      subChunk1Size = Subchunk1Size(file.readSync(4));
      audioFormat = AudioFormat(file.readSync(2));
      numChannels = NumChannels(file.readSync(2));
      sampleRate = SampleRate(file.readSync(4));
      byteRate = ByteRate(file.readSync(4));
      blockAlign = BlockAlign(file.readSync(2));
      bitsPerSample = BitsPerSample(file.readSync(2));

      // data sub_chunck
      subChunk2ID = Subchunck2ID(file.readSync(4));
      subChunk2Size = Subchunck2Size(file.readSync(4));
      data = Data(file.readSync(file.lengthSync() - file.positionSync()));

    } catch (e) {
        print('Error: $e');
        exit(-1);
    } finally {
        file?.closeSync();
    }
  }

  /// Retourne une chaîne de caractères représentant les infos du [Wav].
  @override
  String toString() {
    return [
      chunkID.toString(),
      chunkSize.toString(),
      format.toString(),
      subChunk1ID.toString(),
      subChunk1Size.toString(),
      audioFormat.toString(),
      numChannels.toString(),
      sampleRate.toString(),
      byteRate.toString(),
      blockAlign.toString(),
      bitsPerSample.toString(),
      subChunk2ID.toString(),
      subChunk2Size.toString(),
      data.toString()
    ].join('\n');
  }

  void split_for_gba(int seconds) {
    assert(numChannels.value_real == 1);
    assert(sampleRate.value_real == 22050);
    assert(bitsPerSample.value_real == 8);

    List<List<int>> splitted_datas = _split_datas_for_gba(seconds);

    int saved_chunkSize = chunkSize.value_real;
    int saved_subChunk2Size = subChunk2Size.value_real;
    Uint8List saved_data = Uint8List.fromList(data.value_bytes);

    int i = 0;
    for(List<int> data_part in splitted_datas) {
      data = Data(Uint8List.fromList(data_part));
      subChunk2Size = Subchunck2Size.fromInt(data_part.length);
      chunkSize = ChunkSize.fromInt(36 + subChunk2Size.value_real);

      List<int> bytes = _combine_in_bytes();
      String file_name = "part-${(i+1).toString().padLeft(6, '0')}.wav";
      File("./temp/$file_name").writeAsBytesSync(bytes);
      i +=1;
    }

    data = Data(Uint8List.fromList(saved_data));
    subChunk2Size = Subchunck2Size.fromInt(saved_subChunk2Size);
    chunkSize = ChunkSize.fromInt(saved_chunkSize);

  }

  List<List<int>> _split_datas_for_gba(int seconds) {
    List<List<int>> divided = [];
    int max_size = seconds * sampleRate.value_real;

    for (int i = 0; i < data.value_bytes.lengthInBytes ; i += max_size) {
      divided.add(data.value_bytes.sublist(i, i + max_size > data.value_bytes.lengthInBytes ? data.value_bytes.lengthInBytes : i + max_size));
    }
    return divided;
  }

  List<int> _combine_in_bytes() {
    return
      chunkID.value_bytes +
      chunkSize.value_bytes +
      format.value_bytes +
      subChunk1ID.value_bytes +
      subChunk1Size.value_bytes +
      audioFormat.value_bytes +
      numChannels.value_bytes +
      sampleRate.value_bytes +
      byteRate.value_bytes +
      blockAlign.value_bytes +
      bitsPerSample.value_bytes +
      subChunk2ID.value_bytes +
      subChunk2Size.value_bytes +
      data.value_bytes;
  }
}
