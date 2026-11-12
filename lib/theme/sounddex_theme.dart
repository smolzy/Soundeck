import 'package:material_ui/material_ui.dart';

import 'sounddex_colors.dart';
import 'sounddex_shapes.dart';
import 'sounddex_typography.dart';

ThemeData get sounddexTheme {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: SoundDexColors.terracotta,
        brightness: Brightness.light,
      ).copyWith(
        primary: SoundDexColors.terracotta,
        onPrimary: SoundDexColors.fiche,
        surface: SoundDexColors.fiche,
        onSurface: SoundDexColors.ink,
        outline: SoundDexColors.line,
      );
  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: SoundDexColors.paper,
    textTheme: SoundDexTypography.textTheme,
    useMaterial3: true,
    cardTheme: const CardThemeData(
      color: SoundDexColors.fiche,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(SoundDexShapes.radius),
        side: BorderSide(color: SoundDexColors.ink),
      ),
    ),
  );
}
