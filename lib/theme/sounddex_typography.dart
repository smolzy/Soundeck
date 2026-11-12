import 'package:material_ui/material_ui.dart';

import 'sounddex_colors.dart';

abstract final class SoundDexTypography {
  static const title = TextStyle(
    fontFamily: 'Fraunces',
    color: SoundDexColors.ink,
    fontWeight: FontWeight.w600,
  );
  static const body = TextStyle(
    fontFamily: 'DMSans',
    color: SoundDexColors.ink,
  );
  static const mono = TextStyle(
    fontFamily: 'IBMPlexMono',
    color: SoundDexColors.ink,
  );

  static TextTheme get textTheme => const TextTheme(
    displayLarge: title,
    displayMedium: title,
    displaySmall: title,
    headlineLarge: title,
    headlineMedium: title,
    headlineSmall: title,
    titleLarge: title,
    titleMedium: body,
    titleSmall: body,
    bodyLarge: body,
    bodyMedium: body,
    bodySmall: body,
    labelLarge: body,
    labelMedium: body,
    labelSmall: body,
  );
}
