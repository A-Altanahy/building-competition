import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cultural_building_competition/main.dart';
import 'package:cultural_building_competition/controllers/game_controller.dart';

void main() {
  testWidgets('App renders dashboard smoke test', (WidgetTester tester) async {
    // Set desktop window size for testing to prevent layout overflows in test context
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => GameController(),
        child: const CulturalCompetitionApp(),
      ),
    );

    // Verify that the title of the competition app is rendered
    expect(find.text('دوري فتية الرشد'), findsWidgets);

    // Reset size
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
