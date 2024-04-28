/*
 * Droits d'auteur 2024 Fralacticus fralacticus@gmail.com
 * Licence zlib, voir le fichier LICENSE
 */

/*
 * Ce fichier contient le nécessaires pour manipuler et construire
 * des fichiers S3M à partir de fichiers WAV. Les principales classes incluent :
 *
 * - S3M: Classe principale pour créer et manipuler des données S3M.
 * - S3MFileHeader: Représente l'en-tête de fichier S3M contenant des métadonnées de base.
 * - S3MSampleHeader: Représente les en-têtes d'échantillons individuels dans un fichier S3M.
 * - S3MLastHeader: Gère la création de l'en-tête final pour la finition des fichiers S3M.
 * - S3MData: Encapsule les données audio proprement dites converties à partir de fichiers WAV.
 *
 */

import 'dart:typed_data';
import 'dart:convert';
import '../core/PrettyHexExtensions.dart';
import '../wav/Wav.dart';

class S3M {
  late int nb_wav;
  late S3MFileHeader fileHeader;
  List<S3MSampleHeader> sampleHeaders = [];
  List<S3MLastHeader> lastHeaders = [];
  List<S3MData> datas = [];

  S3M(List<Wav> wavs) {
    nb_wav = wavs.length;
    fileHeader = S3MFileHeader(wavs.length);
    int accu_data_length = 0;
    for(int i = 0 ; i < nb_wav ; i++) {
      sampleHeaders.add(S3MSampleHeader(accu_data_length, fileHeader, nb_wav, wavs[i]));
      accu_data_length += wavs[i].subChunk2Size.value_real;
    }
    for(int i = 0 ; i < nb_wav ; i++) {
      lastHeaders.add(S3MLastHeader(i));
    }
    for(int i = 0 ; i < nb_wav ; i++) {
      datas.add(S3MData(wavs[i]));
    }
  }

  List<int> bytes = [];

  void build_file() {
    fileHeader.create_bytes();
    //print("- Building file header");
    //log_bytes(fileHeader.bytes);

    //print("- Building samples headers");
    List<int> samplesHeaderBytes = [];
    for(S3MSampleHeader header in sampleHeaders){
      header.create_bytes();
      samplesHeaderBytes += header.bytes;
    }
    //log_bytes(samplesHeaderBytes);

    //print("- Building last headers");
    List<int> lastHeaderBytes = [];
    for(S3MLastHeader header in lastHeaders){
      lastHeaderBytes += header.bytes;
    }
    //log_bytes(lastHeaderBytes);

    //print("- Building datas");
    List<int> dataBytes = [];
    for(S3MData data in datas){
      dataBytes += data.bytes;
    }
    //log_bytes(dataBytes);

    bytes = fileHeader.bytes + samplesHeaderBytes + lastHeaderBytes + dataBytes;
  }
}


class S3MFileHeader {
  final Uint8List title = Uint8List.fromList(List.filled(28, 0x00));
  final Uint8List  sig1 = Uint8List.fromList([0x1a]);
  final Uint8List  type = Uint8List.fromList([0x10]);
  final Uint8List reserved = Uint8List.fromList([0x00, 0x00]);

  late Uint8List ordNum;
  late Uint8List smpNum;
  late Uint8List patNum;
  final Uint8List flags = Uint8List.fromList([0x00, 0x00]);
  final Uint8List cwtv = Uint8List.fromList([0x31, 0x51]);
  final Uint8List formatVersion = Uint8List.fromList([0x02, 0x00]);
  final Uint8List  magic = Uint8List.fromList(ascii.encode("SCRM"));

  final Uint8List  globalVol = Uint8List.fromList([0x40]);
  final Uint8List  speed = Uint8List.fromList([0x04]);
  final Uint8List  tempo = Uint8List.fromList([0x80]);
  final Uint8List  masterVolume = Uint8List.fromList([0xB0]);
  final Uint8List  ultraClicks = Uint8List.fromList([0x10]);
  final Uint8List  usePanningTable = Uint8List.fromList([0xFC]);
  final Uint8List reserved2 = Uint8List.fromList([0x00, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]);
  final Uint8List special =  Uint8List.fromList([0x00, 0x00]);

  final Uint8List channels = Uint8List.fromList([
    0x00, 0x01, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
    0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
  ]);

  late Uint8List orders;
  late Uint8List instruments_parapointers;
  late Uint8List patterns_parapointers;
  late Uint8List parapointers_fillers;

  // Final bytes
  List<int> bytes = [];

  // Methodes
  void set_ordNum(int nb_wav) {
    ByteData byteData = ByteData(2);
    int value = nb_wav + (nb_wav.isOdd ? 1 : 0);
    byteData.setUint16(0, value, Endian.little);
    ordNum = byteData.buffer.asUint8List();
  }

  void set_smpNum(int nb_wav) {
    ByteData byteData = ByteData(2);
    byteData.setUint16(0, nb_wav, Endian.little);
    smpNum = byteData.buffer.asUint8List();
  }

  void set_patNum(int nb_wav) {
    ByteData byteData = ByteData(2);
    byteData.setUint16(0, nb_wav, Endian.little);
    patNum = byteData.buffer.asUint8List();
  }

  Uint8List get_ordNum_asList(){
    return ordNum;
  }

  int get_ordNum_asValue(){
    return ordNum.buffer.asByteData().getUint16(0, Endian.little);
  }

  void set_orders(int nb_wav) {
    List<int> orderList = List.generate(nb_wav, (index) => index);
    if (nb_wav.isOdd) {
      orderList.add(0xFF);
    }
    orders = Uint8List.fromList(orderList);
  }

  Uint8List calculate_instruments_parapointers(int nb_wav) {
    int sampleHeaderOffset = 0x60 + get_ordNum_asValue() + (nb_wav) * 4 + 32;
    sampleHeaderOffset = (sampleHeaderOffset + 15) & ~15;
    List<int> paras = List.generate(nb_wav, (index) => ( (sampleHeaderOffset ~/16) + (5 * index) ));
    Uint16List parapointers = Uint16List.fromList(paras);
    Uint8List uint8list = parapointers.buffer.asUint8List();
    return uint8list;
  }

  Uint8List calculate_patterns_parapointers(int nb_wav) {
    int sampleHeaderOffset = 0x60 + get_ordNum_asValue() +(nb_wav) * 4 + 32 + (80 * nb_wav);
    sampleHeaderOffset = (sampleHeaderOffset + 15) & ~15;
    List<int> paras = List.generate(nb_wav, (index) => ( (sampleHeaderOffset ~/16) + (5 * index) ));
    Uint16List parapointers = Uint16List.fromList(paras);
    Uint8List uint8list = parapointers.buffer.asUint8List();
    return uint8list;
  }

  Uint8List calculate_parapointers_fillers(int nb_wav) {
    int sampleHeaderOffset = 0x60 + get_ordNum_asValue() + (nb_wav) * 4;
    int sampleHeaderOffset_corrected = (sampleHeaderOffset + 32 + 15) & ~15;
    int nb_filler = sampleHeaderOffset_corrected - sampleHeaderOffset;
    Uint8List fillers = Uint8List.fromList([0x20, 0x2f] + List.filled(nb_filler-2, 0x08));
    return fillers;
  }

  S3MFileHeader(int nb_wav){
    set_ordNum(nb_wav);
    set_smpNum(nb_wav);
    set_patNum(nb_wav);
    set_orders(nb_wav);
    instruments_parapointers = calculate_instruments_parapointers(nb_wav);
    patterns_parapointers = calculate_patterns_parapointers(nb_wav);
    parapointers_fillers = calculate_parapointers_fillers(nb_wav);
  }

  void create_bytes() {
    bytes =
        title + sig1 + type + reserved +
        ordNum + smpNum + patNum + flags + cwtv + formatVersion + magic +
        globalVol + speed + tempo + masterVolume + ultraClicks + usePanningTable + reserved2 + special +
        channels + orders +
        instruments_parapointers +
        patterns_parapointers +
        parapointers_fillers
    ;
  }
}

class S3MSampleHeader {
  List<int> bytes = [];

  final Uint8List sampleType = Uint8List.fromList([0x01]);
  final Uint8List fileName = Uint8List.fromList(List.filled(12, 0x00));
  late Uint8List memSeg;
  late Uint8List length;
  final Uint8List mix = Uint8List.fromList([
                        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x40,0x00,0x00,0x00,
    0x22,0x56,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x53,0x43,0x52,0x53
  ]);

  S3MSampleHeader(int accu_data_length, S3MFileHeader file_header, int nb_wav, Wav wav) {
    memSeg = calculer_memSeg(accu_data_length, nb_wav, file_header.get_ordNum_asValue());
    length = wav.subChunk2Size.value_bytes;
  }

  Uint8List calculer_memSeg(int accu_datas_length, int nb_wav, int ordNum) {
    int sampleDataOffset = ((0x60 + ordNum +(nb_wav) * 4 + 32 + (80 * nb_wav * 2)) + 15) & ~15;
    sampleDataOffset = (sampleDataOffset + accu_datas_length +15) & ~15;
    int dataPointer_1 = (sampleDataOffset >> 4) & 0xFF;
    int dataPointer_2 = (sampleDataOffset >> 12) & 0xFF;
    int dataPointer_0 = (sampleDataOffset >> 20) & 0xFF;
    Uint8List liste = Uint8List.fromList([dataPointer_0, dataPointer_1, dataPointer_2]);
    return liste;
  }

  void create_bytes(){
    bytes = sampleType + fileName + memSeg + length + mix;
  }
}

class S3MLastHeader {
  List<int> bytes = [
    0x48,0x00,0x20,0x40,0x01,0x21,0x40,0x01,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
  ];

  S3MLastHeader(int index) {
    bytes[4] = index+1;
    bytes[7] = index+1;
  }
}

class S3MData{
  List<int> bytes = [];

  S3MData(Wav wav) {
    int nb_fillers = ((wav.subChunk2Size.value_real + 15) & ~15) - wav.subChunk2Size.value_real;
    bytes = wav.data.value_bytes + List.filled(nb_fillers, 0x80);
  }
}

void log_bytes(List<int> bytes) {
  print(bytes.toHexString());
}
