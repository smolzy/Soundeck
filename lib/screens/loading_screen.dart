import 'package:material_ui/material_ui.dart';

import '../services/onboarding_preferences.dart';
import '../services/auth_service.dart';
import '../services/yamnet_service.dart';
import '../theme/sounddex_colors.dart';
import '../widgets/sound_icon.dart';
import '../widgets/sounddex_primitives.dart';
import 'app_shell.dart';
import 'login_screen.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  final _yamnetService = YamnetService();
  late final OnboardingPreferences _preferences;
  double _progress = 0.08;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      if (mounted) setState(() => _progress = 0.2);
      await _yamnetService.initialize();
      if (mounted) setState(() => _progress = 1);
      await Future<void>.delayed(const Duration(milliseconds: 250));
      _preferences = OnboardingPreferences();
      final isGuest = await _preferences.hasChosenGuestMode();
      final hasSession = AuthService().isAuthenticated;
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) =>
              hasSession || isGuest ? const AppShell() : const LoginScreen(),
        ),
      );
    } on UnsupportedError {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'YAMNet est disponible sur Android.';
        _progress = 1;
      });
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Impossible de charger YAMNet : $error';
      });
    }
  }

  @override
  void dispose() {
    _yamnetService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 118,
                    height: 118,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: SoundDexColors.ink),
                    ),
                  ),
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: SoundDexColors.locked),
                    ),
                  ),
                  const SoundIcon(
                    name: 'micro',
                    size: 48,
                    color: SoundDexColors.terracotta,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('SoundDex', style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 8),
            const Text(
              'Le carnet des sons du monde',
              style: TextStyle(
                color: SoundDexColors.warmGray,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 40),
            ThinProgressBar(value: _progress),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Chargement du modèle YAMNet…',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SoundIcon(
                  name: 'moteur',
                  size: 20,
                  color: SoundDexColors.locked,
                ),
                SoundIcon(
                  name: 'oiseau',
                  size: 20,
                  color: SoundDexColors.locked,
                ),
                SoundIcon(
                  name: 'sirene',
                  size: 20,
                  color: SoundDexColors.locked,
                ),
                SoundIcon(name: 'vent', size: 20, color: SoundDexColors.locked),
              ],
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              GhostButton(
                label: 'Réessayer',
                onPressed: () {
                  setState(() {
                    _errorMessage = null;
                    _progress = 0.08;
                  });
                  _loadModel();
                },
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
