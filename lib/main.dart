import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'controllers/game_controller.dart';
import 'views/dashboard_view.dart';
import 'views/spectator_view.dart';
import 'utils/platform_utils.dart';
import 'theme/app_theme.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  setArguments(args);
  await initializeDesktopWindow();

  runApp(
    ChangeNotifierProvider(
      create: (context) {
        final controller = GameController();
        initWebSync(controller);
        return controller;
      },
      child: const CulturalCompetitionApp(),
    ),
  );
}

class CulturalCompetitionApp extends StatelessWidget {
  const CulturalCompetitionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'المسابقة الثقافية العقارية',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      initialRoute: isSpectatorUrl() ? '/spectator' : '/',
      routes: {
        '/': (context) => const DashboardView(),
        '/spectator': (context) => const Scaffold(
          backgroundColor: AppColors.ink,
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: SpectatorBody(showBackButton: false),
          ),
        ),
      },
    );
  }
}
