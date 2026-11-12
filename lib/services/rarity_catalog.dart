import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';
import '../widgets/sound_icon.dart';

enum SoundRarity { common, uncommon, rare, legendary }

class RarityCatalog {
  static const _assetPath = 'assets/rarity.json';
  Map<String, String>? _categories;
  String? _defaultRarity;
  final Map<int, SoundRarity> _remoteRarities = {};

  Future<void> load() async {
    if (_categories != null) return;
    final json = jsonDecode(await rootBundle.loadString(_assetPath));
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Le catalogue de rareté est invalide.');
    }
    final categories = json['categories'];
    if (categories is! Map<String, dynamic>) {
      throw const FormatException('Les catégories de rareté sont invalides.');
    }
    _categories = categories.map(
      (key, value) => MapEntry(key, value.toString()),
    );
    _defaultRarity = json['default']?.toString() ?? 'commun';
  }

  SoundRarity rarityFor(String label) {
    final category = soundCategoryForName(label);
    final value = _categories?[category] ?? _defaultRarity ?? 'commun';
    return switch (value) {
      'peu_commun' => SoundRarity.uncommon,
      'rare' => SoundRarity.rare,
      'legendaire' => SoundRarity.legendary,
      _ => SoundRarity.common,
    };
  }

  SoundRarity rarityForIndex(int index, String label) {
    return _remoteRarities[index] ?? rarityFor(label);
  }

  Future<void> loadRemote() async {
    final client = supabaseClient;
    if (client == null) return;
    try {
      final rows = await client
          .from('sound_rarity')
          .select('class_id,finders,players');
      for (final row in rows) {
        final classId = (row['class_id'] as num?)?.toInt();
        final finders = (row['finders'] as num?)?.toDouble();
        final players = (row['players'] as num?)?.toDouble();
        if (classId == null ||
            finders == null ||
            players == null ||
            players <= 0) {
          continue;
        }
        final percentage = finders / players;
        _remoteRarities[classId] = percentage >= 0.5
            ? SoundRarity.common
            : percentage >= 0.2
            ? SoundRarity.uncommon
            : percentage >= 0.05
            ? SoundRarity.rare
            : SoundRarity.legendary;
      }
    } on PostgrestException {
      // Le catalogue statique reste le secours hors ligne.
    } on Exception {
      // Le catalogue statique reste le secours hors ligne.
    }
  }
}
