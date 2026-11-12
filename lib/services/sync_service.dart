import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_service.dart';
import 'sound_collection_repository.dart';
import 'supabase_config.dart';
import 'yamnet_class_catalog.dart';

class SyncService {
  SyncService({SoundCollectionRepository? repository, AuthService? authService})
    : _repository = repository ?? SoundCollectionRepository(),
      _authService = authService ?? AuthService();

  final SoundCollectionRepository _repository;
  final AuthService _authService;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<Session?>? _sessionSubscription;
  bool _isSyncing = false;

  Future<int> pendingCount() async {
    final sounds = await _repository.getDiscoveredSounds();
    return sounds.where((sound) => !sound.synced).length;
  }

  Future<void> start({bool syncImmediately = true}) async {
    if (!isSupabaseConfigured) return;
    if (syncImmediately) await syncPending();
    _connectivitySubscription ??= Connectivity().onConnectivityChanged.listen(
      (_) => syncPending(),
    );
    _sessionSubscription ??= _authService.sessionChanges.listen((session) {
      if (session != null) syncPending();
    });
  }

  Future<void> syncPending() async {
    if (_isSyncing || !isSupabaseConfigured) return;
    final userId = _authService.currentSession?.user.id;
    if (userId == null) return;

    _isSyncing = true;
    try {
      final labels = await YamnetClassCatalog().loadLabels();
      final classIds = {
        for (var index = 0; index < labels.length; index++)
          labels[index]: index,
      };
      final pending = (await _repository.getDiscoveredSounds())
          .where((sound) => !sound.synced)
          .where((sound) => classIds.containsKey(sound.name))
          .toList();
      if (pending.isEmpty) return;

      final rows = pending.map((sound) {
        return {
          'user_id': userId,
          'class_id': classIds[sound.name],
          'class_name': sound.name,
          'confidence': sound.bestScore,
          'discovered_at': sound.discoveredAt.toIso8601String(),
        };
      }).toList();

      await supabaseClient!
          .from('discoveries')
          .upsert(rows, onConflict: 'user_id,class_id', ignoreDuplicates: true);
      await _repository.markSynced(
        pending.where((sound) => sound.id != null).map((sound) => sound.id!),
      );
    } on PostgrestException {
      // Une erreur réseau laisse les lignes en attente pour le prochain essai.
    } on TimeoutException {
      // Une erreur réseau laisse les lignes en attente pour le prochain essai.
    } on SocketException {
      // Une erreur réseau laisse les lignes en attente pour le prochain essai.
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    await _sessionSubscription?.cancel();
    await _repository.dispose();
  }
}
