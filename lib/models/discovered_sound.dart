class DiscoveredSound {
  const DiscoveredSound({
    this.id,
    required this.name,
    required this.discoveredAt,
    required this.bestScore,
    required this.audioPath,
    this.synced = false,
  });

  final int? id;
  final String name;
  final DateTime discoveredAt;
  final double bestScore;
  final String audioPath;
  final bool synced;

  factory DiscoveredSound.fromMap(Map<String, Object?> map) {
    return DiscoveredSound(
      id: map['id'] as int?,
      name: map['name'] as String,
      discoveredAt: DateTime.parse(map['discovered_at'] as String),
      bestScore: (map['best_score'] as num).toDouble(),
      audioPath: map['audio_path'] as String,
      synced: (map['synced'] as num?)?.toInt() == 1,
    );
  }
}
