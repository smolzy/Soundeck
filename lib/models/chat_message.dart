class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.userId,
    required this.username,
    required this.content,
    required this.createdAt,
  });

  final int id;
  final String userId;
  final String username;
  final String content;
  final DateTime createdAt;

  factory ChatMessage.fromMap(
    Map<String, dynamic> map, {
    required String username,
  }) {
    return ChatMessage(
      id: (map['id'] as num).toInt(),
      userId: map['user_id'] as String,
      username: username,
      content: map['content'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
