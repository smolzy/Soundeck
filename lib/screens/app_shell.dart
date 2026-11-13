import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../services/auth_service.dart';
import '../services/onboarding_preferences.dart';
import '../services/sync_service.dart';
import '../theme/sounddex_colors.dart';
import '../widgets/sound_icon.dart';
import 'collection_screen.dart';
import 'direct_screen.dart';
import 'home_screen.dart';
import 'leaderboard_screen.dart';
import 'placeholder_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  int _collectionVersion = 0;
  final _authService = AuthService();
  final _preferences = OnboardingPreferences();
  late final SyncService _syncService;

  List<Widget> get _screens => [
    CollectionScreen(key: ValueKey(_collectionVersion)),
    const LeaderboardScreen(),
    const HomeScreen(),
    const DirectScreen(),
    const PlaceholderScreen(title: 'Profil'),
  ];

  @override
  void initState() {
    super.initState();
    _syncService = SyncService();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSync();
    });
  }

  Future<void> _initializeSync() async {
    final userId = _authService.currentSession?.user.id;
    if (userId == null || !mounted) {
      await _syncService.start();
      return;
    }

    final hasBeenOffered = await _preferences.hasBeenOfferedSync(userId);
    final hasPending = await _syncService.pendingCount() > 0;
    if (!hasBeenOffered && hasPending && mounted) {
      await _preferences.markSyncOffered(userId);
      if (!mounted) return;
      final shouldSync = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Synchroniser ton carnet ?'),
          content: const Text(
            'Tes découvertes locales peuvent être associées à ton compte. '
            'Les fichiers audio restent sur ton téléphone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Plus tard'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Synchroniser'),
            ),
          ],
        ),
      );
      await _syncService.start(syncImmediately: shouldSync == true);
      return;
    }
    await _syncService.start();
  }

  @override
  void dispose() {
    unawaited(_syncService.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(index: _selectedIndex, children: _screens),
    bottomNavigationBar: SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: SoundDexColors.fiche,
          border: Border(top: BorderSide(color: SoundDexColors.line)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _NavigationIcon(
              name: 'carnet',
              selected: _selectedIndex == 0,
              onPressed: () => _select(0),
            ),
            _NavigationIcon(
              name: 'podium',
              selected: _selectedIndex == 1,
              onPressed: () => _select(1),
            ),
            _NavigationIcon(
              name: 'micro',
              selected: _selectedIndex == 2,
              isMain: true,
              onPressed: () => _select(2),
            ),
            _NavigationIcon(
              name: 'direct',
              selected: _selectedIndex == 3,
              onPressed: () => _select(3),
            ),
            _NavigationIcon(
              name: 'profil',
              selected: _selectedIndex == 4,
              onPressed: () => _select(4),
            ),
          ],
        ),
      ),
    ),
  );

  void _select(int index) {
    setState(() {
      _selectedIndex = index;
      if (index == 0) {
        _collectionVersion++;
      }
    });
  }
}

class _NavigationIcon extends StatelessWidget {
  const _NavigationIcon({
    required this.name,
    required this.selected,
    required this.onPressed,
    this.isMain = false,
  });

  final String name;
  final bool selected;
  final bool isMain;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? SoundDexColors.terracotta
        : SoundDexColors.warmGray;
    final icon = SoundIcon(name: name, size: 22, color: color);
    return IconButton(
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: BoxConstraints.tightFor(
        width: isMain ? 48 : 32,
        height: isMain ? 48 : 32,
      ),
      style: isMain
          ? IconButton.styleFrom(
              backgroundColor: selected
                  ? SoundDexColors.terracotta
                  : SoundDexColors.ink,
              shape: const CircleBorder(),
            )
          : null,
      icon: isMain
          ? SoundIcon(name: name, size: 24, color: SoundDexColors.fiche)
          : icon,
    );
  }
}
