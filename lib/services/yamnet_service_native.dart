import 'dart:io';

import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import '../models/yamnet_prediction.dart';
import 'yamnet_errors.dart';

class YamnetService {
  static const _modelAsset = 'assets/models/yamnet.tflite';
  static const _classMapAsset = 'assets/models/yamnet_class_map.csv';
  static const _classCount = 521;

  Interpreter? _interpreter;
  List<String>? _labels;

  Future<List<YamnetPrediction>> classify(String audioPath) async {
    await _ensureInitialized();

    final samples = await _readWavSamples(audioPath);
    final interpreter = _interpreter!;
    final inputShape = interpreter.getInputTensor(0).shape;
    final outputShape = interpreter.getOutputTensor(0).shape;

    final inputIsFlat = inputShape.length == 1;
    final inputHasBatch = inputShape.length == 2 && inputShape.first == 1;
    if ((!inputIsFlat && !inputHasBatch) || inputShape.last <= 0) {
      throw const YamnetException(
        'La forme d’entrée du modèle YAMNet est inattendue.',
      );
    }

    final outputIsFlat = outputShape.length == 1;
    final outputHasBatch = outputShape.length == 2 && outputShape.first == 1;
    if ((!outputIsFlat && !outputHasBatch) || outputShape.last != _classCount) {
      throw const YamnetException(
        'La sortie du modèle YAMNet ne contient pas 521 classes.',
      );
    }

    final windowSize = inputShape.last;
    final scores = List<double>.filled(_classCount, 0);
    final windowCount = (samples.length / windowSize).ceil();

    for (var windowIndex = 0; windowIndex < windowCount; windowIndex++) {
      final input = List<double>.filled(windowSize, 0);
      final start = windowIndex * windowSize;
      final end = (start + windowSize).clamp(0, samples.length);
      for (var sampleIndex = start; sampleIndex < end; sampleIndex++) {
        input[sampleIndex - start] = samples[sampleIndex];
      }

      final output = outputIsFlat
          ? List<double>.filled(_classCount, 0)
          : [List<double>.filled(_classCount, 0)];
      final inputTensor = inputIsFlat ? input : [input];
      interpreter.run(inputTensor, output);
      final outputScores = outputIsFlat
          ? output as List<double>
          : (output as List<List<double>>).first;
      for (var classIndex = 0; classIndex < _classCount; classIndex++) {
        scores[classIndex] += outputScores[classIndex];
      }
    }

    final labels = _labels!;
    final rankedIndexes = List<int>.generate(_classCount, (index) => index)
      ..sort((first, second) => scores[second].compareTo(scores[first]));

    return rankedIndexes.take(3).map((index) {
      return YamnetPrediction(
        label: labels[index],
        confidence: scores[index] / windowCount,
      );
    }).toList();
  }

  Future<void> _ensureInitialized() async {
    if (_interpreter != null && _labels != null) {
      return;
    }

    try {
      _interpreter ??= await Interpreter.fromAsset(_modelAsset);
      _labels ??= _parseClassMap(await rootBundle.loadString(_classMapAsset));
    } on PlatformException catch (error) {
      throw YamnetException(
        'Impossible de charger le modèle YAMNet : ${error.message}',
      );
    } on ArgumentError catch (error) {
      throw YamnetException('Modèle YAMNet invalide : $error');
    }
  }

  List<String> _parseClassMap(String csv) {
    final labelsByIndex = <int, String>{};
    for (final line in csv.split(RegExp(r'\r?\n')).skip(1)) {
      if (line.trim().isEmpty) {
        continue;
      }

      final fields = _parseCsvLine(line);
      if (fields.length < 3) {
        throw const YamnetException(
          'Le fichier yamnet_class_map.csv est invalide.',
        );
      }
      final index = int.tryParse(fields[0]);
      if (index == null || index < 0 || index >= _classCount) {
        throw const YamnetException(
          'Le fichier yamnet_class_map.csv contient un index invalide.',
        );
      }
      labelsByIndex[index] = fields[2];
    }

    if (labelsByIndex.length != _classCount) {
      throw const YamnetException(
        'Le fichier yamnet_class_map.csv ne contient pas 521 classes.',
      );
    }

    return List<String>.generate(_classCount, (index) => labelsByIndex[index]!);
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

  Future<List<double>> _readWavSamples(String path) async {
    final bytes = await File(path).readAsBytes();
    if (bytes.length < 12 ||
        _readAscii(bytes, 0, 4) != 'RIFF' ||
        _readAscii(bytes, 8, 4) != 'WAVE') {
      throw const YamnetException('Le fichier audio n’est pas un WAV valide.');
    }

    var offset = 12;
    var sampleRate = 0;
    var channels = 0;
    var bitsPerSample = 0;
    var dataOffset = -1;
    var dataLength = 0;

    while (offset + 8 <= bytes.length) {
      final chunkId = _readAscii(bytes, offset, 4);
      final chunkLength = _readUint32(bytes, offset + 4);
      final chunkStart = offset + 8;
      if (chunkStart + chunkLength > bytes.length) {
        break;
      }

      if (chunkId == 'fmt ' && chunkLength >= 16) {
        final audioFormat = _readUint16(bytes, chunkStart);
        channels = _readUint16(bytes, chunkStart + 2);
        sampleRate = _readUint32(bytes, chunkStart + 4);
        bitsPerSample = _readUint16(bytes, chunkStart + 14);
        if (audioFormat != 1) {
          throw const YamnetException(
            'Le fichier audio doit être encodé en PCM.',
          );
        }
      } else if (chunkId == 'data') {
        dataOffset = chunkStart;
        dataLength = chunkLength;
      }

      offset = chunkStart + chunkLength + (chunkLength.isOdd ? 1 : 0);
    }

    if (sampleRate != 16000 ||
        channels != 1 ||
        bitsPerSample != 16 ||
        dataOffset < 0) {
      throw const YamnetException(
        'Le WAV doit être en PCM 16 bits, mono, à 16 kHz.',
      );
    }

    final samples = <double>[];
    final dataEnd = (dataOffset + dataLength).clamp(0, bytes.length);
    for (var index = dataOffset; index + 1 < dataEnd; index += 2) {
      samples.add(_readInt16(bytes, index) / 32768.0);
    }

    if (samples.isEmpty) {
      throw const YamnetException(
        'Le fichier audio ne contient aucun échantillon.',
      );
    }
    return samples;
  }

  String _readAscii(Uint8List bytes, int offset, int length) {
    return String.fromCharCodes(bytes.sublist(offset, offset + length));
  }

  int _readUint16(Uint8List bytes, int offset) {
    return bytes[offset] | (bytes[offset + 1] << 8);
  }

  int _readUint32(Uint8List bytes, int offset) {
    return bytes[offset] |
        (bytes[offset + 1] << 8) |
        (bytes[offset + 2] << 16) |
        (bytes[offset + 3] << 24);
  }

  int _readInt16(Uint8List bytes, int offset) {
    final value = _readUint16(bytes, offset);
    return value >= 0x8000 ? value - 0x10000 : value;
  }

  Future<void> dispose() async {
    _interpreter?.close();
    _interpreter = null;
    _labels = null;
  }
}
