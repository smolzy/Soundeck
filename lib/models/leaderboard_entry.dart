class LeaderboardEntry {
  const LeaderboardEntry({
    required this.userId,
    required this.username,
    required this.total,
    required this.weekly,
  });

  final String userId;
  final String username;
  final int total;
  final int weekly;

  factory LeaderboardEntry.fromMap(Map<String, dynamic> map) {
    return LeaderboardEntry(
      userId: map['user_id'] as String,
      username: map['username'] as String,
      total: (map['total'] as num).toInt(),
      weekly: (map['weekly'] as num).toInt(),
    );
  }
}
