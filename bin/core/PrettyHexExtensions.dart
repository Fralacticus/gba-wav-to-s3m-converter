/*
 * Droits d'auteur 2024 Fralacticus fralacticus@gmail.com
 * Licence CC BY-SA 4.0, voir le fichier LICENSE
 */

import 'dart:typed_data';

extension HexString on Uint8List {
  String toHexString() {
    return map((byte) => "0x${byte.toRadixString(16).padLeft(2, '0')}").join(' ');
  }
}

extension IntListHexString on List<int> {
  String toHexString({int perLine = 16}) {
    var result = StringBuffer();  // Utilisez un StringBuffer pour construire la chaîne efficacement
    for (int i = 0; i < length; i++) {
      // Ajouter la représentation hexadécimale de l'élément actuel
      result.write(this[i].toRadixString(16).padLeft(2, '0'));

      // Ajouter un espace après chaque élément, sauf après le dernier de la ligne
      if ((i + 1) % perLine == 0 || i == length - 1) {
        result.writeln();  // Ajouter un saut de ligne après 16 éléments ou après le dernier élément
      } else {
        result.write(' ');  // Sinon, ajouter juste un espace
      }
    }
    return result.toString();
  }
}
