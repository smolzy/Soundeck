import '../models/yamnet_prediction.dart';

class YamnetService {
  Future<void> initialize() {
    return Future.error(
      UnsupportedError(
        'Le chargement de YAMNet nécessite Android, Windows, macOS ou Linux.',
      ),
    );
  }

  Future<List<YamnetPrediction>> classify(String audioPath) {
    return Future.error(
      UnsupportedError(
        'L’identification YAMNet nécessite Android, Windows, macOS ou Linux.',
      ),
    );
  }

  Future<void> dispose() async {}
}
