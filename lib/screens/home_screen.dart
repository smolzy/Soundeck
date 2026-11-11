import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../services/audio_recorder_service.dart';
import '../services/yamnet_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AudioRecorderService _audioRecorderService = AudioRecorderService();
  final YamnetService _yamnetService = YamnetService();
  Timer? _recordingTimer;
  Duration _elapsed = Duration.zero;
  bool _isRecording = false;
  bool _isBusy = false;
  String? _recordedPath;
  String? _errorMessage;
  List<YamnetPrediction>? _predictions;

  Future<void> _toggleRecording() async {
    if (_isBusy) {
      return;
    }

    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    setState(() {
      _isBusy = true;
      _errorMessage = null;
      _recordedPath = null;
      _predictions = null;
    });

    try {
      await _audioRecorderService.start();
      if (!mounted) {
        return;
      }

      setState(() {
        _isRecording = true;
        _isBusy = false;
        _elapsed = Duration.zero;
      });
      _recordingTimer = Timer.periodic(
        const Duration(milliseconds: 100),
        (_) => _updateRecordingProgress(),
      );
    } on AudioPermissionDeniedException catch (error) {
      _showError(error.toString());
    } on PlatformException catch (error) {
      _showError('Impossible de démarrer le microphone : ${error.message}');
    } on FileSystemException catch (error) {
      _showError('Impossible de préparer le fichier audio : ${error.message}');
    } on StateError catch (error) {
      _showError(error.message);
    } finally {
      if (mounted && !_isRecording) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  Future<void> _stopRecording() async {
    _recordingTimer?.cancel();
    _recordingTimer = null;
    setState(() {
      _isBusy = true;
    });

    String path;
    try {
      path = await _audioRecorderService.stop();
    } on RecordingTooShortException catch (error) {
      _showError(error.toString());
      return;
    } on PlatformException catch (error) {
      _showError('Impossible d’arrêter le microphone : ${error.message}');
      return;
    } on FileSystemException catch (error) {
      _showError('Impossible de finaliser le fichier audio : ${error.message}');
      return;
    } on StateError catch (error) {
      _showError(error.message);
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isRecording = false;
      _recordedPath = path;
      _predictions = null;
      _elapsed = Duration.zero;
    });

    try {
      final predictions = await _yamnetService.classify(path);
      if (!mounted) {
        return;
      }

      setState(() {
        _predictions = predictions;
        _isBusy = false;
      });
    } on UnsupportedError catch (error) {
      _showError(error.message ?? error.toString());
    } on YamnetException catch (error) {
      _showError(error.message);
    } on FileSystemException catch (error) {
      _showError('Impossible de lire le fichier audio : ${error.message}');
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  void _updateRecordingProgress() {
    if (!mounted || !_isRecording) {
      return;
    }

    final elapsed = _elapsed + const Duration(milliseconds: 100);
    setState(() {
      _elapsed = elapsed;
    });

    if (elapsed >= AudioRecorderService.maxDuration) {
      unawaited(_stopRecording());
    }
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }

    setState(() {
      _errorMessage = message;
      _isRecording = false;
      _isBusy = false;
      _elapsed = Duration.zero;
    });
  }

  String _formatDuration(Duration duration) {
    final seconds = duration.inSeconds.toString().padLeft(2, '0');
    return '00:$seconds';
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    unawaited(_audioRecorderService.dispose());
    unawaited(_yamnetService.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress =
        _elapsed.inMilliseconds /
        AudioRecorderService.maxDuration.inMilliseconds;

    return Scaffold(
      appBar: AppBar(title: const Text('SoundDex'), centerTitle: true),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.graphic_eq,
                size: 96,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                _isRecording
                    ? 'Écoute le son autour de toi'
                    : 'Découvre les sons autour de toi',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 32),
              if (_isRecording) ...[
                Text(
                  _formatDuration(_elapsed),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0).toDouble(),
                ),
                const SizedBox(height: 24),
              ],
              FilledButton.icon(
                onPressed: _isBusy ? null : _toggleRecording,
                icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                label: Text(_isRecording ? 'Arrêter' : 'Écouter'),
              ),
              if (_recordedPath != null) ...[
                const SizedBox(height: 16),
                Text(
                  'Enregistrement prêt',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              if (_predictions != null) ...[
                const SizedBox(height: 16),
                Text(
                  'Résultats YAMNet',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ..._predictions!.asMap().entries.map((entry) {
                  final prediction = entry.value;
                  return Text(
                    '${entry.key + 1}. ${prediction.label} '
                    '(${(prediction.confidence * 100).toStringAsFixed(1)} %)',
                  );
                }),
              ],
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
