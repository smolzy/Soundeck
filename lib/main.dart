import 'package:material_ui/material_ui.dart';

import 'services/supabase_config.dart';
import 'screens/loading_screen.dart';
import 'theme/sounddex_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeSupabase();
  runApp(const SoundDexApp());
}

class SoundDexApp extends StatelessWidget {
  const SoundDexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SoundDex',
      theme: sounddexTheme,
      home: const LoadingScreen(),
    );
  }
}
