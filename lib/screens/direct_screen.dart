import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../models/chat_message.dart';
import '../models/live_discovery.dart';
import '../services/auth_service.dart';
import '../services/direct_service.dart';
import '../services/onboarding_preferences.dart';
import '../theme/sounddex_colors.dart';
import '../theme/sounddex_typography.dart';
import '../widgets/sound_icon.dart';
import '../widgets/sounddex_primitives.dart';

class DirectScreen extends StatefulWidget {
  const DirectScreen({super.key});

  @override
  State<DirectScreen> createState() => _DirectScreenState();
}

class _DirectScreenState extends State<DirectScreen>
    with WidgetsBindingObserver {
  static const _blockedWords = ['putain', 'merde', 'connard', 'salope'];

  final _service = DirectService();
  final _preferences = OnboardingPreferences();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _reconnectTimer;
  List<LiveDiscovery> _discoveries = [];
  List<ChatMessage> _messages = [];
  Set<String> _hiddenUsers = {};
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isSending = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _load();
    }
  }

  Future<void> _load({bool refreshing = false}) async {
    if (!AuthService().isAuthenticated) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    if (mounted) {
      setState(() {
        _isLoading = !refreshing;
        _isRefreshing = refreshing;
        _errorMessage = null;
      });
    }
    try {
      final results = await Future.wait([
        _service.loadDiscoveries(),
        _service.loadMessages(),
        _preferences.hiddenUserIds(),
      ]);
      if (!mounted) return;
      setState(() {
        _discoveries = (results[0] as List<LiveDiscovery>).take(50).toList();
        _messages = (results[1] as List<ChatMessage>).take(50).toList();
        _hiddenUsers = (results[2] as List<String>).toSet();
        _isLoading = false;
        _isRefreshing = false;
      });
      _subscribe();
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  void _subscribe() {
    _service.subscribe(
      onDiscovery: (discovery) {
        if (!mounted || _hiddenUsers.contains(discovery.userId)) return;
        setState(() {
          _discoveries = [
            discovery,
            ..._discoveries.where(
              (item) =>
                  item.userId != discovery.userId ||
                  item.className != discovery.className,
            ),
          ].take(50).toList();
        });
      },
      onMessage: (message) {
        if (!mounted || _hiddenUsers.contains(message.userId)) return;
        setState(() {
          _messages = [
            ..._messages.where((item) => item.id != message.id),
            message,
          ].take(50).toList();
        });
      },
      onError: (error) {
        if (!mounted) return;
        setState(() => _errorMessage = 'Connexion au direct interrompue.');
        _reconnectTimer?.cancel();
        _reconnectTimer = Timer(const Duration(seconds: 3), () {
          if (mounted) _load(refreshing: true);
        });
      },
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;
    if (_blockedWords.any(text.toLowerCase().contains)) {
      _showMessage('Ce message contient un mot interdit.');
      return;
    }
    setState(() => _isSending = true);
    try {
      await _service.sendMessage(text);
      _messageController.clear();
    } on DirectServiceException catch (error) {
      _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _moderate(ChatMessage message) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: const Text('Signaler'),
              onTap: () => Navigator.pop(context, 'report'),
            ),
            ListTile(
              leading: const Icon(Icons.visibility_off_outlined),
              title: const Text('Masquer cet utilisateur'),
              onTap: () => Navigator.pop(context, 'hide'),
            ),
          ],
        ),
      ),
    );
    if (action == 'report') {
      try {
        await _service.reportMessage(message.id);
        _showMessage('Message signalé.');
      } on DirectServiceException catch (error) {
        _showMessage(error.message);
      }
    } else if (action == 'hide') {
      await _preferences.hideUser(message.userId);
      if (mounted) {
        setState(() {
          _hiddenUsers = {..._hiddenUsers, message.userId};
          _messages = _messages
              .where((item) => item.userId != message.userId)
              .toList();
          _discoveries = _discoveries
              .where((item) => item.userId != message.userId)
              .toList();
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _reconnectTimer?.cancel();
    unawaited(_service.dispose());
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AuthService().isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('En direct')),
        body: Center(child: Text('Connecte-toi pour participer')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Text('En direct'),
            SizedBox(width: 8),
            Icon(Icons.circle, size: 10, color: SoundDexColors.terracotta),
          ],
        ),
      ),
      body: _isLoading
          ? const Padding(
              padding: EdgeInsets.all(20),
              child: ThinProgressBar(value: null),
            )
          : _errorMessage != null && _discoveries.isEmpty && _messages.isEmpty
          ? _ErrorState(message: _errorMessage!, onRetry: _load)
          : RefreshIndicator(
              onRefresh: () => _load(refreshing: true),
              color: Colors.transparent,
              backgroundColor: Colors.transparent,
              child: ListView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                children: [
                  if (_isRefreshing) const ThinProgressBar(value: null),
                  _buildDiscoveries(context),
                  const SizedBox(height: 24),
                  _buildChat(context),
                ],
              ),
            ),
    );
  }

  Widget _buildDiscoveries(BuildContext context) {
    final visible = _discoveries
        .where((item) => !_hiddenUsers.contains(item.userId))
        .take(20)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dernières découvertes',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        if (visible.isEmpty)
          const Text('Aucune découverte récente.')
        else
          ...visible.map(
            (item) => _FadeIn(
              key: ValueKey(
                '${item.userId}-${item.className}-${item.discoveredAt}',
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(
                  children: [
                    SoundIcon(
                      name: item.className,
                      size: 22,
                      color: SoundDexColors.terracotta,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${item.username} a trouvé ${item.className}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      _relativeTime(item.discoveredAt),
                      style: SoundDexTypography.mono.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildChat(BuildContext context) {
    final visible = _messages
        .where((item) => !_hiddenUsers.contains(item.userId))
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: SoundDexColors.line),
        const SizedBox(height: 8),
        Text('Discussion', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        ...visible.map(
          (message) => GestureDetector(
            onLongPress: () => _moderate(message),
            child: Align(
              alignment: message.userId == AuthService().currentSession?.user.id
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 300),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                color: message.userId == AuthService().currentSession?.user.id
                    ? SoundDexColors.ink
                    : SoundDexColors.fiche,
                child: Text(
                  '${message.username}\n${_filterWords(message.content)}',
                  style: TextStyle(
                    color:
                        message.userId == AuthService().currentSession?.user.id
                        ? SoundDexColors.fiche
                        : SoundDexColors.ink,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _messageController,
          maxLength: 280,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'Écrire un message',
            counterText: '${_messageController.text.length}/280',
            suffixIcon: IconButton(
              onPressed: _isSending ? null : _sendMessage,
              icon: const SoundIcon(name: 'envoyer', size: 22),
            ),
          ),
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _sendMessage(),
        ),
      ],
    );
  }

  String _filterWords(String text) {
    var result = text;
    for (final word in _blockedWords) {
      result = result.replaceAll(
        RegExp(RegExp.escape(word), caseSensitive: false),
        '***',
      );
    }
    return result;
  }

  String _relativeTime(DateTime date) {
    final seconds = DateTime.now().difference(date).inSeconds;
    if (seconds < 60) return '${seconds.clamp(0, 59)} s';
    final minutes = seconds ~/ 60;
    if (minutes < 60) return '$minutes min';
    return '${minutes ~/ 60} h';
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          GhostButton(label: 'Réessayer', onPressed: onRetry),
        ],
      ),
    ),
  );
}

class _FadeIn extends StatefulWidget {
  const _FadeIn({required this.child, super.key});

  final Widget child;

  @override
  State<_FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<_FadeIn> {
  double _opacity = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _opacity = 1);
    });
  }

  @override
  Widget build(BuildContext context) => AnimatedOpacity(
    opacity: _opacity,
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeOut,
    child: widget.child,
  );
}
