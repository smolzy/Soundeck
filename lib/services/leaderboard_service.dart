import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/leaderboard_entry.dart';
import 'supabase_config.dart';

class LeaderboardData {
  const LeaderboardData({
    required this.entries,
    required this.currentUser,
    required this.currentUserRank,
  });

  final List<LeaderboardEntry> entries;
  final LeaderboardEntry? currentUser;
  final int? currentUserRank;
}

class LeaderboardServiceException implements Exception {
  const LeaderboardServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class LeaderboardService {
  Future<LeaderboardData> load({required bool weekly}) async {
    final client = supabaseClient;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) {
      throw const LeaderboardServiceException(
        'Connecte-toi pour participer au classement.',
      );
    }

    try {
      final orderColumn = weekly ? 'weekly' : 'total';
      final rows = await client
          .from('leaderboard')
          .select('user_id,username,total,weekly')
          .order(orderColumn, ascending: false)
          .order('total', ascending: false)
          .limit(50);
      final entries = (rows as List)
          .map(
            (row) =>
                LeaderboardEntry.fromMap(Map<String, dynamic>.from(row as Map)),
          )
          .toList();

      final currentUserRows = await client
          .from('leaderboard')
          .select('user_id,username,total,weekly')
          .eq('user_id', userId)
          .limit(1);
      final currentUser = currentUserRows.isEmpty
          ? null
          : LeaderboardEntry.fromMap(
              Map<String, dynamic>.from(currentUserRows.first as Map),
            );
      if (currentUser == null) {
        return LeaderboardData(
          entries: entries,
          currentUser: null,
          currentUserRank: null,
        );
      }

      final currentValue = weekly ? currentUser.weekly : currentUser.total;
      final higherRows = await client
          .from('leaderboard')
          .select('user_id')
          .gt(orderColumn, currentValue);
      final rank = (higherRows as List).length + 1;
      return LeaderboardData(
        entries: entries,
        currentUser: currentUser,
        currentUserRank: rank,
      );
    } on PostgrestException catch (error) {
      throw LeaderboardServiceException(
        'Impossible de charger le classement : ${error.message}',
      );
    } on Exception catch (error) {
      throw LeaderboardServiceException(
        'Impossible de charger le classement : $error',
      );
    }
  }
}
