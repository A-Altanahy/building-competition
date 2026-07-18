import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'controllers/game_controller.dart';
import 'views/dashboard_view.dart';
import 'views/spectator_view.dart';
import 'utils/platform_utils.dart';

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
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFEF4444),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        textTheme: GoogleFonts.cairoTextTheme(
          ThemeData.dark().textTheme,
        ),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF3B82F6), // Cobalt Blue
          secondary: Color(0xFFEF4444), // Rose Red
          background: Color(0xFF0F172A),
          surface: Color(0xFF1E293B),
        ),
        useMaterial3: true,
      ),
      initialRoute: isSpectatorUrl() ? '/spectator' : '/',
      routes: {
        '/': (context) => const DashboardView(),
        '/spectator': (context) => const Scaffold(
              backgroundColor: Color(0xFF090D16),
              body: Directionality(
                textDirection: TextDirection.rtl,
                child: SpectatorBody(showBackButton: false),
              ),
            ),
      },
    );
  }
}

