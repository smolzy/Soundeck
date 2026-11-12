import 'package:material_ui/material_ui.dart';

import '../services/auth_service.dart';
import '../services/onboarding_preferences.dart';
import '../theme/sounddex_colors.dart';
import '../widgets/sounddex_primitives.dart';
import 'app_shell.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  final _preferences = OnboardingPreferences();
  bool _isBusy = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });
    try {
      await _authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const AppShell()),
      );
    } on AuthServiceException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _playAsGuest() async {
    await _preferences.chooseGuestMode();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const AppShell()),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Rejoins l’expédition',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Classement, direct et chat avec les autres explorateurs.',
                  style: TextStyle(
                    color: SoundDexColors.warmGray,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)
                        ? null
                        : 'Entre un email valide.';
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Mot de passe'),
                  validator: (value) => (value ?? '').length >= 8
                      ? null
                      : '8 caractères minimum.',
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: _isBusy ? 'Connexion…' : 'Se connecter',
                  onPressed: _isBusy ? null : _signIn,
                ),
                TextButton(
                  onPressed: _isBusy
                      ? null
                      : () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const SignupScreen(),
                          ),
                        ),
                  child: const Text('Créer un compte'),
                ),
                const SizedBox(height: 12),
                const Text('ou', textAlign: TextAlign.center),
                const SizedBox(height: 12),
                GhostButton(label: 'Continuer avec Google', onPressed: null),
                const SizedBox(height: 12),
                GhostButton(
                  label: 'Jouer sans compte',
                  onPressed: _isBusy ? null : _playAsGuest,
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                const Text(
                  'Tes enregistrements restent sur ton téléphone.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: SoundDexColors.warmGray),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
