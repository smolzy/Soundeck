import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class AudioPermissionDeniedException implements Exception {
  const AudioPermissionDeniedException();

  @override
  String toString() => 'La permission d’utiliser le microphone a été refusée.';
}

class RecordingTooShortException implements Exception {
  const RecordingTooShortException(this.minimumDuration);

  final Duration minimumDuration;

  @override
  String toString() =>
      'L’enregistrement doit durer au moins '
      '${minimumDuration.inSeconds} secondes.';
}

class AudioRecorderService {
  static const minDuration = Duration(seconds: 3);
  static const maxDuration = Duration(seconds: 5);

  final AudioRecorder _recorder = AudioRecorder();
  DateTime? _startedAt;
  String? _currentPath;

  bool get isRecording => _startedAt != null;

  Future<void> start() async {
    if (isRecording) {
      throw StateError('Un enregistrement est déjà en cours.');
    }

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      throw const AudioPermissionDeniedException();
    }

    final fileName = 'sounddex_${DateTime.now().microsecondsSinceEpoch}.wav';
    final path = kIsWeb
        ? ''
        : '${(await getTemporaryDirectory()).path}'
              '${Platform.pathSeparator}$fileName';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: path,
    );

    _startedAt = DateTime.now();
    _currentPath = path;
  }

  Future<String> stop() async {
    final startedAt = _startedAt;
    if (startedAt == null) {
      throw StateError('Aucun enregistrement n’est en cours.');
    }

    late final String? path;
    try {
      path = await _recorder.stop() ?? _currentPath;
    } finally {
      _startedAt = null;
      _currentPath = null;
    }

    final duration = DateTime.now().difference(startedAt);
    if (duration < minDuration) {
      if (!kIsWeb && path != null) {
        await _deleteFile(path);
      }
      throw const RecordingTooShortException(minDuration);
    }

    if (path == null) {
      throw StateError('Le fichier audio n’a pas été créé.');
    }

    return path;
  }

  Future<void> cancel() async {
    if (!isRecording) {
      return;
    }

    await _recorder.cancel();
    _startedAt = null;
    _currentPath = null;
  }

  Future<void> dispose() => _recorder.dispose();

  Future<void> _deleteFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
