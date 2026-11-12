import 'package:flutter/services.dart';

class YamnetClassCatalog {
  static const assetPath = 'assets/models/yamnet_class_map.csv';
  static const classCount = 521;

  Future<List<String>> loadLabels() async {
    final csv = await rootBundle.loadString(assetPath);
    final labelsByIndex = <int, String>{};

    for (final line in csv.split(RegExp(r'\r?\n')).skip(1)) {
      if (line.trim().isEmpty) {
        continue;
      }

      final fields = _parseCsvLine(line);
      if (fields.length < 3) {
        throw const FormatException(
          'Le fichier de classes YAMNet est invalide.',
        );
      }

      final index = int.tryParse(fields[0]);
      if (index == null || index < 0 || index >= classCount) {
        throw const FormatException(
          'Le fichier de classes YAMNet contient un index invalide.',
        );
      }
      labelsByIndex[index] = fields[2];
    }

    if (labelsByIndex.length != classCount) {
      throw const FormatException(
        'Le fichier de classes YAMNet ne contient pas 521 classes.',
      );
    }

    return List<String>.generate(classCount, (index) => labelsByIndex[index]!);
  }

  List<String> _parseCsvLine(String line) {
    final fields = <String>[];
    final field = StringBuffer();
    var quoted = false;

    for (var index = 0; index < line.length; index++) {
      final character = line[index];
      if (character == '"') {
        if (quoted && index + 1 < line.length && line[index + 1] == '"') {
          field.write('"');
          index++;
        } else {
          quoted = !quoted;
        }
      } else if (character == ',' && !quoted) {
        fields.add(field.toString());
        field.clear();
      } else {
        field.write(character);
      }
    }
    fields.add(field.toString());
    return fields;
  }
}
