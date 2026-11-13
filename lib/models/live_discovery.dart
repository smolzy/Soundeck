class LiveDiscovery {
  const LiveDiscovery({
    required this.userId,
    required this.username,
    required this.className,
    required this.discoveredAt,
  });

  final String userId;
  final String username;
  final String className;
  final DateTime discoveredAt;

  factory LiveDiscovery.fromMap(
    Map<String, dynamic> map, {
    required String username,
  }) {
    return LiveDiscovery(
      userId: map['user_id'] as String,
      username: username,
      className: map['class_name'] as String,
      discoveredAt: DateTime.parse(map['discovered_at'] as String),
    );
  }
}
