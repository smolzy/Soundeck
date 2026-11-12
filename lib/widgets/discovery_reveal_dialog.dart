import 'package:material_ui/material_ui.dart';

import '../models/discovered_sound.dart';

Future<void> showDiscoveryRevealDialog(
  BuildContext context,
  DiscoveredSound sound,
) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => DiscoveryRevealDialog(sound: sound),
  );
}

class DiscoveryRevealDialog extends StatefulWidget {
  const DiscoveryRevealDialog({required this.sound, super.key});

  final DiscoveredSound sound;

  @override
  State<DiscoveryRevealDialog> createState() => _DiscoveryRevealDialogState();
}

class _DiscoveryRevealDialogState extends State<DiscoveryRevealDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _scale = Tween<double>(begin: 0.4, end: 1).animate(curve);
    _fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.45, curve: Curves.easeIn),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: const Text('Nouvelle découverte !'),
      content: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fade,
            child: ScaleTransition(scale: _scale, child: child),
          );
        },
        child: Card(
          color: colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.graphic_eq, size: 72, color: colorScheme.primary),
                const SizedBox(height: 16),
                Text(
                  widget.sound.name,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Score : ${(widget.sound.bestScore * 100).toStringAsFixed(1)} %',
                  style: TextStyle(color: colorScheme.onPrimaryContainer),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Continuer'),
        ),
      ],
    );
  }
}
