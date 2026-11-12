import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../models/discovered_sound.dart';

class SoundCollectionRepository {
  static const _databaseName = 'sounddex.db';
  static const _tableName = 'discovered_sounds';

  Database? _database;

  Future<DiscoveredSound> saveDiscovery({
    required String name,
    required DateTime discoveredAt,
    required double score,
    required String audioPath,
  }) async {
    final database = await _openDatabase();
    return database.transaction((transaction) async {
      final existingRows = await transaction.query(
        _tableName,
        where: 'name = ?',
        whereArgs: [name],
        limit: 1,
      );

      if (existingRows.isEmpty) {
        final id = await transaction.insert(_tableName, {
          'name': name,
          'discovered_at': discoveredAt.toIso8601String(),
          'best_score': score,
          'audio_path': audioPath,
        });
        return DiscoveredSound(
          id: id,
          name: name,
          discoveredAt: discoveredAt,
          bestScore: score,
          audioPath: audioPath,
        );
      }

      final existing = DiscoveredSound.fromMap(existingRows.first);
      final isBetterScore = score > existing.bestScore;
      if (isBetterScore) {
        await transaction.update(
          _tableName,
          {'best_score': score, 'audio_path': audioPath},
          where: 'id = ?',
          whereArgs: [existing.id],
        );
      }

      return isBetterScore
          ? DiscoveredSound(
              id: existing.id,
              name: existing.name,
              discoveredAt: existing.discoveredAt,
              bestScore: score,
              audioPath: audioPath,
            )
          : existing;
    });
  }

  Future<Database> _openDatabase() async {
    if (_database != null) {
      return _database!;
    }

    final databasesPath = await getDatabasesPath();
    final databasePath = path.join(databasesPath, _databaseName);
    _database = await openDatabase(
      databasePath,
      version: 1,
      onCreate: (database, version) async {
        await database.execute('''
          CREATE TABLE $_tableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE,
            discovered_at TEXT NOT NULL,
            best_score REAL NOT NULL,
            audio_path TEXT NOT NULL
          )
        ''');
      },
    );
    return _database!;
  }

  Future<void> dispose() async {
    await _database?.close();
    _database = null;
  }
}
