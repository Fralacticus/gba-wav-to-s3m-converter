/*
 * Droits d'auteur 2024 Fralacticus fralacticus@gmail.com
 * Licence zlib, voir le fichier LICENSE
 */

import "dart:io";
import "package:args/command_runner.dart";
import 'package:ansicolor/ansicolor.dart';

import "../wav/wav_library.dart";
import "../s3m/S3M.dart";
import 'ColorConsole.dart';

Future<int> main(List<String> arguments) async {
  ansiColorDisabled = false;
  ColorConsole.afficher_titre();

  Directory temp_dir = Directory("./temp");
  if (temp_dir.existsSync()) {
    clear_directory("./temp");
  }
  else {
    temp_dir.createSync();
  }


  var runner = CommandRunner("gba-wav-to-s3m-converter", "Description:\nPour la GBA, convertit un fichier .wav en segments ou fusionne des .wav segmentés en un .s3m\nFor the GBA, converts a .wav file into segments or merges segmented .wav files into a single .s3m")
    ..addCommand(FileCommand())
    ..addCommand(FolderCommand());

  if(arguments.isEmpty) {
    stderr.writeln("Erreur: arguments nécessaires (Error: need arguments)");
  }
  try {
    await runner.run(arguments);
  }
  catch (e) {
    stderr.write('${e}');
    exit(1);
  }

  return 0;
}


void clear_directory(String directoryPath) {
  Directory directory = Directory(directoryPath);
  if (directory.existsSync()) {
    for (FileSystemEntity entity in directory.listSync()) {
      if (entity is File) {
        entity.deleteSync();
      }
      else if (entity is Directory) {
        entity.deleteSync(recursive: true);
      }
    }
  }
}


void convertir_fichiers_wav_en_s3m(List<File> fichiers_wav, String output_path) {
  print(bleu("- Lecture des fichiers .wav") + " (Reading of .wav files)");
  List<Wav> wavs = [];
  for(File file in fichiers_wav) {
    wavs.add(Wav(file.path));
  }
  if(wavs.any((element) => !element.valid)) {
    exit(-1);
  }

  print(bleu("- Conversion au format .s3m") + " (Conversion to .s3m format)");
  S3M s3m = S3M(wavs);
  s3m.build_file();

  print(bleu("- Écriture du fichier .s3m") + " ( Writing the .s3m file)");
  File(output_path).writeAsBytesSync(s3m.bytes);
}

class FileCommand extends Command {
  @override
  final name = 'file';
  @override
  final description = 'Segmente et convertit un fichier .wav en un fichier .s3m / Segment and convert a .wav file into a .s3m file';

  FileCommand() {
    argParser.addOption('wav_path', abbr: 'i', help: 'Chemin du fichier .wav existant / Path to the existing .wav file');
    argParser.addOption('s3m_path', abbr: 'o', help: 'Chemin où le fichier .s3m généré sera enregistré / Path where the generated .s3m file will be saved');
    argParser.addOption('split_interval_sec', abbr: 's', help: '[Facultatif] Intervalle en secondes entières pour découper le fichier .wav (5s par défaut) / [Optional] Interval in integer seconds for splitting the .wav file (default: 5s)');
  }

  @override
  void run() {
    // Vérifie la présence des arguments obligatoires.
    if (argResults!['wav_path'] == null) {
      throw UsageException('wav_path est obligatoire / wav_path is mandatory', usage);
    }
    if(argResults!['s3m_path'] == null) {
      throw UsageException('s3m_path est obligatoire / s3m_path is mandatory', usage);
    }


    print(magenta('=> Traitement en cours...') + " (Processing...)");

    // Extrait les chemins des dossiers à partir des arguments.
    String wav_path = argResults!['wav_path'];
    String s3m_path = argResults!['s3m_path'];
    int split_time_interval = 5;
    if(argResults!['split_interval_sec'] != null ) {
      int? parse_value = int.tryParse(argResults!['split_interval_sec']);
      if(parse_value == null || parse_value <= 0){
        throw UsageException('split_interval_sec doit être un nombre entier supérieur à 0 / split_interval_sec must be an integer greater than 0.', usage);
      }
      split_time_interval = parse_value;
    }


    // Vérifie l'existence du .wav source
    if(!File(wav_path).existsSync()) {
      throw Exception("Le fichier $wav_path n'existe pas (The file $wav_path does not exists)");
    }

    print(bleu("- Segmentation du fichier .wav") + " (Segmentation of the .wav file)");
    Wav wav = Wav(wav_path);
    if(!wav.valid) {
      exit(-1);
    }
    wav.split_for_gba(split_time_interval);

    print(bleu("- Listage des fichiers .wav segmentés") + " (Listing the segmented .wav files)");
    List<File> wav_files = collect_wav_files_from_folder("./temp");

    // Opérations de conversion et d'écriture du fichier final
    convertir_fichiers_wav_en_s3m(wav_files, s3m_path);
    print(vert("=> Traitement terminé : Fichier .s3m créé avec succès") + " (Processing complete: .s3m file created successfully)");
  }
}


class FolderCommand extends Command {
  @override
  final name = 'folder';
  @override
  final description = 'Converts .wav files in a folder into a single .s3m file, processing them alphabetically.';

  FolderCommand() {
    argParser.addOption('folder_path', abbr: 'i', help: 'Path to the existing folder containing the .wav files');
    argParser.addOption('s3m_path', abbr: 'o', help: 'Path where the generated .s3m file will be saved.');
  }

  @override
  void run() {
    // Vérifie la présence des arguments obligatoires.
    if(argResults!['folder_path'] == null) {
      throw UsageException('folder_path est obligatoire / folder_path is mandatory', usage);
    }
    if(argResults!['s3m_path'] == null) {
      throw UsageException('s3m_path est obligatoire / s3m_path is mandatory', usage);
    }
    print(magenta('=> Traitement en cours...') + " (Processing...)");

    // Extrait les chemins des dossiers à partir des arguments.
    String folder_path = argResults!['folder_path'];
    String s3m_path = argResults!['s3m_path'];

    // Vérifie l'existence du dossier source
    if(!Directory(folder_path).existsSync()) {
      throw Exception("Le dossier $folder_path n'existe pas (The folder $folder_path does not exists)");
    }

    print(bleu("- Listage des fichiers .wav segmentés") + " (Listing the segmented .wav files)");
    List<File> wav_files = collect_wav_files_from_folder(folder_path);
    if(wav_files.isEmpty) {
      throw Exception("Le dossier $folder_path ne contient aucun fichier .wav (The folder $folder_path contains no .wav files");
    }

    // Vérifie si tous les fichiers wav

    // Opérations de conversion et d'écriture du fichier final
    convertir_fichiers_wav_en_s3m(wav_files, s3m_path);
    print(vert("=> Traitement terminé : Fichier .s3m créé avec succès") + " (Processing complete: .s3m file created successfully)");

  }
}

List<File> collect_wav_files_from_folder(String folder_path) {
  List<File> wav_files = Directory(folder_path)
    .listSync()
    .whereType<File>()
    .where((file) => file.path.endsWith('.wav'))
    .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  return wav_files;
}