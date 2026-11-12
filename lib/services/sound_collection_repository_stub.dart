import '../models/discovered_sound.dart';

class SoundCollectionRepository {
  Future<DiscoveredSound> saveDiscovery({
    required String name,
    required DateTime discoveredAt,
    required double score,
    required String audioPath,
  }) {
    return Future.error(
      UnsupportedError(
        'La collection locale est disponible sur Android, pas dans Chrome.',
      ),
    );
  }

  Future<List<DiscoveredSound>> getDiscoveredSounds() async => [];

  Future<void> dispose() async {}
}
