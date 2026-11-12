import 'package:material_ui/material_ui.dart';

import '../theme/sounddex_colors.dart';
import '../theme/sounddex_shapes.dart';
import '../theme/sounddex_typography.dart';

class SpecimenCard extends StatelessWidget {
  const SpecimenCard({required this.child, this.isRare = false, super.key});
  final Widget child;
  final bool isRare;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: SoundDexColors.fiche,
      border: Border.all(
        color: isRare ? SoundDexColors.terracotta : SoundDexColors.ink,
        width: isRare ? 2 : 1,
      ),
      borderRadius: const BorderRadius.all(SoundDexShapes.radius),
    ),
    padding: const EdgeInsets.all(12),
    child: child,
  );
}

class LockedCard extends StatelessWidget {
  const LockedCard({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: SoundDexColors.paper,
      border: Border.all(color: SoundDexColors.locked),
      borderRadius: const BorderRadius.all(SoundDexShapes.radius),
    ),
    padding: const EdgeInsets.all(12),
    child: DefaultTextStyle.merge(
      style: const TextStyle(color: SoundDexColors.locked),
      child: child,
    ),
  );
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    super.key,
  });
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    child: FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: SoundDexColors.ink,
        foregroundColor: SoundDexColors.fiche,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(SoundDexShapes.radius),
        ),
      ),
      child: Text(label),
    ),
  );
}

class GhostButton extends StatelessWidget {
  const GhostButton({required this.label, required this.onPressed, super.key});
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      foregroundColor: SoundDexColors.ink,
      side: const BorderSide(color: SoundDexColors.ink),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(SoundDexShapes.radius),
      ),
    ),
    child: Text(label),
  );
}

class ThinProgressBar extends StatelessWidget {
  const ThinProgressBar({required this.value, super.key});
  final double value;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.zero,
    child: LinearProgressIndicator(
      value: value.clamp(0, 1),
      minHeight: 3,
      backgroundColor: SoundDexColors.line,
      color: SoundDexColors.terracotta,
    ),
  );
}

class StampLabel extends StatelessWidget {
  const StampLabel(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: -0.17,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: SoundDexColors.terracotta, width: 2),
      ),
      child: Text(
        label,
        style: SoundDexTypography.mono.copyWith(
          color: SoundDexColors.terracotta,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}
