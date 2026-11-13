import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/chat_message.dart';
import '../models/live_discovery.dart';
import 'supabase_config.dart';

class DirectServiceException implements Exception {
  const DirectServiceException(this.message);
  final String message;

  @override
  String toString() => message;
}

class DirectService {
  final Map<String, String> _profileCache = {};
  RealtimeChannel? _discoveriesChannel;
  RealtimeChannel? _messagesChannel;

  SupabaseClient get _client {
    final client = supabaseClient;
    if (client == null) {
      throw const DirectServiceException('Le direct nécessite une connexion.');
    }
    return client;
  }

  Future<List<LiveDiscovery>> loadDiscoveries() async {
    try {
      final rows = await _client
          .from('discoveries')
          .select('user_id,class_name,discovered_at,profiles(username)')
          .order('discovered_at', ascending: false)
          .limit(20);
      final result = <LiveDiscovery>[];
      for (final raw in rows) {
        final row = Map<String, dynamic>.from(raw as Map);
        final profile = row['profiles'];
        final username = profile is Map<String, dynamic>
            ? profile['username']?.toString()
            : null;
        final userId = row['user_id'] as String;
        result.add(
          LiveDiscovery.fromMap(
            row,
            username: _cacheProfile(userId, username ?? 'Explorateur'),
          ),
        );
      }
      return result;
    } on PostgrestException catch (error) {
      throw DirectServiceException(
        'Impossible de charger le direct : ${error.message}',
      );
    }
  }

  Future<List<ChatMessage>> loadMessages() async {
    try {
      final rows = await _client
          .from('messages')
          .select('id,user_id,content,created_at,profiles(username)')
          .order('created_at', ascending: false)
          .limit(50);
      final result = <ChatMessage>[];
      for (final raw in rows) {
        final row = Map<String, dynamic>.from(raw as Map);
        final profile = row['profiles'];
        final userId = row['user_id'] as String;
        final username = profile is Map<String, dynamic>
            ? profile['username']?.toString()
            : null;
        result.add(
          ChatMessage.fromMap(
            row,
            username: _cacheProfile(userId, username ?? 'Explorateur'),
          ),
        );
      }
      return result.reversed.toList();
    } on PostgrestException catch (error) {
      throw DirectServiceException(
        'Impossible de charger la discussion : ${error.message}',
      );
    }
  }

  Future<String> resolveProfile(String userId) async {
    final cached = _profileCache[userId];
    if (cached != null) return cached;
    try {
      final row = await _client
          .from('profiles')
          .select('username')
          .eq('id', userId)
          .maybeSingle();
      return _cacheProfile(
        userId,
        row?['username']?.toString() ?? 'Explorateur',
      );
    } on PostgrestException {
      return _cacheProfile(userId, 'Explorateur');
    }
  }

  String _cacheProfile(String userId, String username) {
    _profileCache[userId] = username;
    return username;
  }

  void subscribe({
    required void Function(LiveDiscovery discovery) onDiscovery,
    required void Function(ChatMessage message) onMessage,
    required void Function(Object error) onError,
  }) {
    _unsubscribeChannels();
    final client = _client;
    _discoveriesChannel = client
        .channel('sounddex-direct-discoveries')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'discoveries',
          callback: (payload) async {
            try {
              final row = payload.newRecord;
              final userId = row['user_id'] as String?;
              if (userId == null) return;
              final username = await resolveProfile(userId);
              onDiscovery(LiveDiscovery.fromMap(row, username: username));
            } catch (error) {
              onError(error);
            }
          },
        )
        .subscribe((status, error) {
          if (error != null) onError(error);
        });
    _messagesChannel = client
        .channel('sounddex-direct-messages')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (payload) async {
            try {
              final row = payload.newRecord;
              final userId = row['user_id'] as String?;
              if (userId == null) return;
              final username = await resolveProfile(userId);
              onMessage(ChatMessage.fromMap(row, username: username));
            } catch (error) {
              onError(error);
            }
          },
        )
        .subscribe((status, error) {
          if (error != null) onError(error);
        });
  }

  Future<void> sendMessage(String content) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty || trimmed.length > 280) {
      throw const DirectServiceException(
        'Le message doit contenir entre 1 et 280 caractères.',
      );
    }
    try {
      await _client.from('messages').insert({
        'user_id': _client.auth.currentUser!.id,
        'content': trimmed,
      });
    } on PostgrestException catch (error) {
      if (error.message.toLowerCase().contains('patiente')) {
        throw const DirectServiceException(
          'Patiente quelques secondes avant le prochain message.',
        );
      }
      throw DirectServiceException(
        'Impossible d’envoyer le message : ${error.message}',
      );
    }
  }

  Future<void> reportMessage(int messageId) async {
    try {
      await _client.from('reports').insert({
        'message_id': messageId,
        'reporter_id': _client.auth.currentUser!.id,
      });
    } on PostgrestException catch (error) {
      throw DirectServiceException(
        'Impossible de signaler ce message : ${error.message}',
      );
    }
  }

  void _unsubscribeChannels() {
    final client = supabaseClient;
    if (client == null) return;
    final discoveries = _discoveriesChannel;
    final messages = _messagesChannel;
    if (discoveries != null) unawaited(client.removeChannel(discoveries));
    if (messages != null) unawaited(client.removeChannel(messages));
    _discoveriesChannel = null;
    _messagesChannel = null;
  }

  Future<void> dispose() async {
    _unsubscribeChannels();
  }
}
