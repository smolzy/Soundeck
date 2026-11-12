import 'package:supabase_flutter/supabase_flutter.dart';

SupabaseClient? _client;
String? _configurationError;

SupabaseClient? get supabaseClient => _client;

bool get isSupabaseConfigured => _client != null;

String? get supabaseConfigurationError => _configurationError;

Future<void> initializeSupabase() async {
  const url = String.fromEnvironment('SUPABASE_URL');
  const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  if (url.isEmpty || anonKey.isEmpty) {
    _configurationError =
        'Supabase n’est pas configuré. Relance avec --dart-define.';
    return;
  }
  if (anonKey.startsWith('sb_secret_') || anonKey.contains('service_role')) {
    _configurationError =
        'Une clé secrète Supabase a été fournie. Utilise uniquement la clé '
        'anon/publishable dans l’application.';
    return;
  }

  await Supabase.initialize(url: url, publishableKey: anonKey);
  _client = Supabase.instance.client;
}
