import 'package:material_ui/material_ui.dart';

import '../models/leaderboard_entry.dart';
import '../services/leaderboard_service.dart';
import '../services/auth_service.dart';
import '../theme/sounddex_colors.dart';
import '../theme/sounddex_typography.dart';
import '../widgets/sounddex_primitives.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _service = LeaderboardService();
  Future<LeaderboardData>? _future;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _load();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    _load();
  }

  void _load() {
    if (!AuthService().isAuthenticated) {
      setState(() => _future = null);
      return;
    }
    setState(() {
      _future = _service.load(weekly: _tabController.index == 0);
    });
  }

  Future<void> _refresh() async {
    if (!AuthService().isAuthenticated) return;
    setState(() {
      _isRefreshing = true;
      _future = _service.load(weekly: _tabController.index == 0);
    });
    try {
      await _future;
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_onTabChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Classement'),
      bottom: TabBar(
        controller: _tabController,
        labelColor: SoundDexColors.terracotta,
        unselectedLabelColor: SoundDexColors.warmGray,
        indicatorColor: SoundDexColors.terracotta,
        tabs: const [
          Tab(text: 'Cette semaine'),
          Tab(text: 'Global'),
        ],
      ),
    ),
    body: _buildBody(context),
  );

  Widget _buildBody(BuildContext context) {
    if (!AuthService().isAuthenticated) {
      return const Center(child: Text('Connecte-toi pour participer'));
    }
    final future = _future;
    if (future == null) {
      return const Center(child: ThinProgressBar(value: 0.2));
    }
    return FutureBuilder<LeaderboardData>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _ErrorState(onRetry: _load);
        }
        if (!snapshot.hasData) {
          return const Column(
            children: [
              SizedBox(height: 24),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: ThinProgressBar(value: null),
              ),
            ],
          );
        }
        return _LeaderboardList(
          data: snapshot.data!,
          weekly: _tabController.index == 0,
          isRefreshing: _isRefreshing,
          onRefresh: _refresh,
        );
      },
    );
  }
}

class _LeaderboardList extends StatelessWidget {
  const _LeaderboardList({
    required this.data,
    required this.weekly,
    required this.isRefreshing,
    required this.onRefresh,
  });

  final LeaderboardData data;
  final bool weekly;
  final bool isRefreshing;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final currentIsInTop =
        data.currentUser != null &&
        data.entries.any((entry) => entry.userId == data.currentUser!.userId);
    final entries = [
      ...data.entries,
      if (!currentIsInTop && data.currentUser != null) data.currentUser!,
    ];

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: onRefresh,
          color: Colors.transparent,
          backgroundColor: Colors.transparent,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            itemCount: entries.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1, color: SoundDexColors.line),
            itemBuilder: (context, index) {
              final entry = entries[index];
              final isCurrent = entry.userId == data.currentUser?.userId;
              final rank = isCurrent && !currentIsInTop
                  ? data.currentUserRank!
                  : index + 1;
              return _LeaderboardRow(
                entry: entry,
                rank: rank,
                score: weekly ? entry.weekly : entry.total,
                isCurrentUser: isCurrent,
              );
            },
          ),
        ),
        if (isRefreshing)
          const Positioned(
            top: 0,
            left: 20,
            right: 20,
            child: ThinProgressBar(value: null),
          ),
      ],
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({
    required this.entry,
    required this.rank,
    required this.score,
    required this.isCurrentUser,
  });

  final LeaderboardEntry entry;
  final int rank;
  final int score;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    final isTopThree = rank <= 3;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: isCurrentUser ? const Color(0xFFE9DFC9) : null,
        border: isCurrentUser ? Border.all(color: SoundDexColors.ink) : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              '$rank',
              style: isTopThree
                  ? SoundDexTypography.title.copyWith(
                      color: SoundDexColors.terracotta,
                      fontSize: 20,
                    )
                  : const TextStyle(
                      color: SoundDexColors.warmGray,
                      fontFamily: 'IBMPlexMono',
                    ),
            ),
          ),
          CircleAvatar(
            radius: 16,
            backgroundColor: isTopThree
                ? SoundDexColors.fiche
                : SoundDexColors.paper,
            child: Text(
              entry.username.isEmpty ? '?' : entry.username[0].toUpperCase(),
              style: const TextStyle(color: SoundDexColors.ink),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isCurrentUser ? '${entry.username} (toi)' : entry.username,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text('$score', style: const TextStyle(fontFamily: 'IBMPlexMono')),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Impossible de charger le classement.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          GhostButton(label: 'Réessayer', onPressed: onRetry),
        ],
      ),
    ),
  );
}
