import 'package:flutter_test/flutter_test.dart';

import 'package:sounddex/main.dart';

void main() {
  testWidgets('affiche l’écran d’accueil SoundDex', (WidgetTester tester) async {
    await tester.pumpWidget(const SoundDexApp());

    expect(find.text('SoundDex'), findsOneWidget);
    expect(find.text('Découvre les sons autour de toi'), findsOneWidget);
    expect(find.text('Écouter'), findsOneWidget);
  });
}
