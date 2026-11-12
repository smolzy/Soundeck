import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

class AuthServiceException implements Exception {
  const AuthServiceException(this.message);
  final String message;

  @override
  String toString() => message;
}

class AuthService {
  SupabaseClient get _client {
    final client = supabaseClient;
    if (client == null) {
      throw AuthServiceException(
        supabaseConfigurationError ??
            'Supabase n’est pas configuré. Relance avec --dart-define.',
      );
    }
    return client;
  }

  Session? get currentSession => supabaseClient?.auth.currentSession;

  bool get isAuthenticated => currentSession != null;

  Stream<Session?> get sessionChanges {
    final client = supabaseClient;
    if (client == null) return const Stream<Session?>.empty();
    return client.auth.onAuthStateChange.map((data) => data.session);
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      await _client.auth.signUp(
        email: email,
        password: password,
        data: {'username': username},
      );
    } on AuthServiceException {
      rethrow;
    } on AuthException catch (error) {
      throw AuthServiceException(_translateError(error));
    } on SocketException {
      throw const AuthServiceException(
        'Connexion internet impossible. Vérifie ton réseau.',
      );
    } catch (_) {
      throw const AuthServiceException(
        'Impossible de créer le compte pour le moment.',
      );
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
    } on AuthServiceException {
      rethrow;
    } on AuthException catch (error) {
      throw AuthServiceException(_translateError(error));
    } on SocketException {
      throw const AuthServiceException(
        'Connexion internet impossible. Vérifie ton réseau.',
      );
    } catch (_) {
      throw const AuthServiceException(
        'Impossible de se connecter pour le moment.',
      );
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on AuthException catch (error) {
      throw AuthServiceException(_translateError(error));
    } on SocketException {
      throw const AuthServiceException(
        'Connexion internet impossible. Vérifie ton réseau.',
      );
    }
  }

  String _translateError(AuthException error) {
    final message = error.message.toLowerCase();
    if (message.contains('invalid api key') ||
        message.contains('apikey') && message.contains('invalid')) {
      return 'La clé Supabase est invalide. Vérifie la clé anon/publishable.';
    }
    if (message.contains('already registered') ||
        message.contains('already been registered') ||
        message.contains('user already exists')) {
      return 'Cette adresse email est déjà utilisée.';
    }
    if (message.contains('invalid login credentials')) {
      return 'Email ou mot de passe incorrect.';
    }
    if (message.contains('email not confirmed')) {
      return 'Confirme ton adresse email avant de te connecter.';
    }
    if (message.contains('signup') && message.contains('disabled')) {
      return 'Les inscriptions sont désactivées dans Supabase.';
    }
    if (message.contains('rate limit') || message.contains('email rate')) {
      return 'Trop de tentatives. Réessaie dans quelques minutes.';
    }
    if (message.contains('network') ||
        message.contains('connection') ||
        message.contains('failed to fetch') ||
        message.contains('timeout')) {
      return 'Connexion internet impossible. Vérifie ton réseau.';
    }
    return 'Supabase : ${error.message}';
  }
}
