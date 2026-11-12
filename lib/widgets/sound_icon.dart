import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

class SoundIcon extends StatelessWidget {
  const SoundIcon({required this.name, this.size = 24, this.color, super.key});

  final String name;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final iconName = soundIconForName(name);
    return SvgPicture.asset(
      'assets/icons/$iconName.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(
        color ?? Theme.of(context).colorScheme.onSurface,
        BlendMode.srcIn,
      ),
      semanticsLabel: name,
    );
  }
}

String soundIconForName(String label) {
  final value = label.toLowerCase();
  const directNames = {
    'moteur',
    'oiseau',
    'cloche',
    'chien',
    'sirene',
    'vent',
    'orage',
    'micro',
    'carnet',
    'podium',
    'direct',
    'profil',
    'envoyer',
    'lecture',
    'musique',
    'voix',
    'maison',
    'inconnu',
  };
  if (directNames.contains(value)) return value;
  if (value.contains('bird') || value.contains('oiseau')) return 'oiseau';
  if (value.contains('dog') || value.contains('chien')) return 'chien';
  if (value.contains('engine') || value.contains('moteur')) return 'moteur';
  if (value.contains('siren') || value.contains('sirène')) return 'sirene';
  if (value.contains('bell') || value.contains('cloche')) return 'cloche';
  if (value.contains('thunder') || value.contains('orage')) return 'orage';
  if (value.contains('wind') || value.contains('vent')) return 'vent';
  if (value.contains('music') || value.contains('musique')) return 'musique';
  if (value.contains('speech') ||
      value.contains('voice') ||
      value.contains('voix')) {
    return 'voix';
  }
  if (value.contains('home') ||
      value.contains('house') ||
      value.contains('maison')) {
    return 'maison';
  }
  return 'inconnu';
}

String soundCategoryForName(String label) {
  final value = label.toLowerCase();
  if (value.contains('bird') ||
      value.contains('dog') ||
      value.contains('cat') ||
      value.contains('animal') ||
      value.contains('oiseau') ||
      value.contains('chien')) {
    return 'Animaux';
  }
  if (value.contains('engine') ||
      value.contains('vehicle') ||
      value.contains('car') ||
      value.contains('motor') ||
      value.contains('moteur')) {
    return 'Machines';
  }
  if (value.contains('siren') ||
      value.contains('alarm') ||
      value.contains('bell') ||
      value.contains('sirène') ||
      value.contains('cloche')) {
    return 'Alertes';
  }
  if (value.contains('rain') ||
      value.contains('thunder') ||
      value.contains('wind') ||
      value.contains('nature') ||
      value.contains('orage') ||
      value.contains('vent')) {
    return 'Nature';
  }
  if (value.contains('music') ||
      value.contains('instrument') ||
      value.contains('musique')) {
    return 'Musique';
  }
  if (value.contains('speech') ||
      value.contains('voice') ||
      value.contains('conversation') ||
      value.contains('voix')) {
    return 'Voix';
  }
  if (value.contains('home') ||
      value.contains('house') ||
      value.contains('door') ||
      value.contains('maison')) {
    return 'Maison';
  }
  return 'Autres';
}
