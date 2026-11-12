import 'package:material_ui/material_ui.dart';

import '../services/auth_service.dart';

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({required this.title, super.key});
  final String title;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: Center(
      child: Text(
        AuthService().isAuthenticated
            ? 'Bientôt disponible'
            : 'Connecte-toi pour participer',
        style: Theme.of(context).textTheme.titleLarge,
      ),
    ),
  );
}
