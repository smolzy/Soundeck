import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../services/audio_recorder_service.dart';
import '../services/sound_collection_repository.dart';
import '../services/sync_service.dart';
import '../services/yamnet_service.dart';
import '../theme/sounddex_colors.dart';
import '../widgets/discovery_reveal_dialog.dart';
import '../widgets/sound_icon.dart';
import '../widgets/sounddex_primitives.dart';
import 'collection_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AudioRecorderService _audioRecorderService = AudioRecorderService();
  final SoundCollectionRepository _collectionRepository =
      SoundCollectionRepository();
  final YamnetService _yamnetService = YamnetService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final SyncService _syncService = SyncService();
  Timer? _recordingTimer;
  StreamSubscription<double>? _amplitudeSubscription;
  Duration _elapsed = Duration.zero;
  bool _isRecording = false;
  bool _isBusy = false;
  String? _recordedPath;
  String? _errorMessage;
  String? _collectionStatus;
  List<YamnetPrediction>? _predictions;
  int? _selectedPredictionIndex;
  List<double> _waveform = List<double>.filled(28, 0.08);

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
      _collectionStatus = null;
      _selectedPredictionIndex = null;
      _waveform = List<double>.filled(28, 0.08);
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
      _amplitudeSubscription = _audioRecorderService.amplitudeStream.listen((
        level,
      ) {
        if (!mounted || !_isRecording) return;
        setState(() {
          _waveform = [..._waveform.skip(1), 0.08 + (level * 0.92)];
        });
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
    await _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;
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
        final usablePredictions = predictions
            .where((prediction) => prediction.confidence >= 0.05)
            .toList();
        if (usablePredictions.isEmpty) {
          _showError('Aucun résultat fiable au-dessus de 5 %.');
          return;
        }
        _predictions = usablePredictions;
        _selectedPredictionIndex = 0;
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

  Future<void> _saveSelectedPrediction() async {
    final predictions = _predictions;
    final selectedIndex = _selectedPredictionIndex;
    final audioPath = _recordedPath;
    if (_isBusy ||
        predictions == null ||
        selectedIndex == null ||
        audioPath == null) {
      return;
    }

    final selectedPrediction = predictions[selectedIndex];
    setState(() {
      _isBusy = true;
      _collectionStatus = null;
      _errorMessage = null;
    });

    try {
      final saveResult = await _collectionRepository.saveDiscovery(
        name: selectedPrediction.label,
        discoveredAt: DateTime.now(),
        score: selectedPrediction.confidence,
        audioPath: audioPath,
      );
      if (mounted) {
        setState(() {
          _collectionStatus = 'Ajouté au Pokédex : ${saveResult.sound.name}';
        });
        if (saveResult.isNewDiscovery) {
          await showDiscoveryRevealDialog(context, saveResult.sound);
        }
        unawaited(_syncService.syncPending());
      }
    } on UnsupportedError {
      if (mounted) {
        setState(() {
          _collectionStatus = 'Collection locale indisponible dans Chrome';
        });
      }
    } on SoundCollectionException catch (error) {
      if (mounted) {
        setState(() {
          _collectionStatus = error.message;
        });
      }
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

  Future<void> _replayRecording() async {
    final path = _recordedPath;
    if (path == null || _isBusy) return;
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(DeviceFileSource(path));
    } on Exception catch (error) {
      if (mounted) {
        _showError('Impossible de lire l’enregistrement : $error');
      }
    }
  }

  String _formatDuration(Duration duration) {
    final seconds = duration.inSeconds.toString().padLeft(2, '0');
    return '00:$seconds';
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    unawaited(_amplitudeSubscription?.cancel());
    unawaited(_audioRecorderService.dispose());
    unawaited(_yamnetService.dispose());
    unawaited(_collectionRepository.dispose());
    unawaited(_audioPlayer.dispose());
    unawaited(_syncService.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_predictions == null ? 'Écouter' : 'Qu’as-tu entendu ?'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const CollectionScreen(),
                ),
              );
            },
            tooltip: 'Ouvrir le Pokédex',
            icon: const Icon(Icons.collections_bookmark),
          ),
        ],
      ),
      body: _predictions == null
          ? _buildListeningView(context)
          : _buildChoiceView(context),
    );
  }

  Widget _buildListeningView(BuildContext context) {
    final progress =
        _elapsed.inMilliseconds /
        AudioRecorderService.maxDuration.inMilliseconds;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Rapproche-toi du son',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 190,
              height: 190,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  for (final size in [190.0, 160.0])
                    Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: SoundDexColors.line),
                      ),
                    ),
                  IconButton(
                    onPressed: _isBusy ? null : _toggleRecording,
                    style: IconButton.styleFrom(
                      backgroundColor: SoundDexColors.terracotta,
                      foregroundColor: SoundDexColors.fiche,
                      fixedSize: const Size(96, 96),
                    ),
                    icon: SoundIcon(
                      name: _isRecording ? 'inconnu' : 'micro',
                      size: 42,
                      color: SoundDexColors.fiche,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 52,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: _waveform.map((value) {
                  return Container(
                    width: 4,
                    height: 10 + value * 40,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    color: _isRecording
                        ? SoundDexColors.terracotta
                        : SoundDexColors.locked,
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${_formatDuration(_elapsed)} / 00:05',
              style: const TextStyle(
                fontFamily: 'IBMPlexMono',
                color: SoundDexColors.warmGray,
              ),
            ),
            const SizedBox(height: 20),
            ThinProgressBar(value: progress),
            if (_errorMessage != null) ...[
              const SizedBox(height: 20),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceView(BuildContext context) {
    final predictions = _predictions!;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        TextButton.icon(
          onPressed: _replayRecording,
          icon: const SoundIcon(name: 'lecture', size: 18),
          label: const Text('Réécouter l’enregistrement'),
        ),
        const SizedBox(height: 16),
        ...predictions.asMap().entries.map((entry) {
          final index = entry.key;
          final prediction = entry.value;
          final selected = index == _selectedPredictionIndex;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: _isBusy
                  ? null
                  : () => setState(() {
                      _selectedPredictionIndex = index;
                      _collectionStatus = null;
                    }),
              child: SpecimenCard(
                isRare: selected,
                child: Row(
                  children: [
                    SoundIcon(name: prediction.label, size: 30),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            prediction.label,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          ThinProgressBar(value: prediction.confidence),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${(prediction.confidence * 100).toStringAsFixed(0)} %',
                      style: const TextStyle(fontFamily: 'IBMPlexMono'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        const Text('Aucun ne correspond ? Réessaie.'),
        const SizedBox(height: 20),
        PrimaryButton(
          label: 'Ajouter au carnet',
          onPressed: _selectedPredictionIndex == null || _isBusy
              ? null
              : _saveSelectedPrediction,
        ),
        if (_collectionStatus != null) ...[
          const SizedBox(height: 12),
          Text(_collectionStatus!, textAlign: TextAlign.center),
        ],
      ],
    );
  }
}
