import 'package:flutter_test/flutter_test.dart';

import 'package:sounddex/models/discovered_sound.dart';
import 'package:sounddex/main.dart';

void main() {
  testWidgets('affiche l’écran de chargement SoundDex', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SoundDexApp());

    expect(find.text('SoundDex'), findsOneWidget);
    expect(find.text('Le carnet des sons du monde'), findsOneWidget);
    expect(find.textContaining('Chargement du modèle YAMNet'), findsOneWidget);
  });

  test('reconstruit une découverte depuis la base locale', () {
    final discoveredAt = DateTime.utc(2026, 11, 12);
    final sound = DiscoveredSound.fromMap({
      'id': 1,
      'name': 'Siren',
      'discovered_at': discoveredAt.toIso8601String(),
      'best_score': 0.87,
      'audio_path': '/tmp/siren.wav',
    });

    expect(sound.name, 'Siren');
    expect(sound.discoveredAt, discoveredAt);
    expect(sound.bestScore, 0.87);
    expect(sound.audioPath, '/tmp/siren.wav');
  });
}
