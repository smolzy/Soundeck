import 'discovered_sound.dart';

class DiscoverySaveResult {
  const DiscoverySaveResult({
    required this.sound,
    required this.isNewDiscovery,
  });

  final DiscoveredSound sound;
  final bool isNewDiscovery;
}
