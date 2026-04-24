import 'dart:ui';
import 'package:flutter/material.dart';
import 'backend_launcher.dart';
import 'home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Go backend'i başlat assetsten çıkarır localhost8080 de dinler
  await BackendLauncher.baslat();

  runApp(const HedefDorkingApp());
}

class HedefDorkingApp extends StatefulWidget {
  const HedefDorkingApp({super.key});

  @override
  State<HedefDorkingApp> createState() => _HedefDorkingAppState();
}

class _HedefDorkingAppState extends State<HedefDorkingApp> {
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    // Uygulama kapanınca Go backend'i öldür
    _lifecycleListener = AppLifecycleListener(
      onExitRequested: () async {
        BackendLauncher.durdur();
        return AppExitResponse.exit;
      },
    );
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hedef Dorking',
      debugShowCheckedModeBanner: false,
      theme: _tema(),
      home: const HomeScreen(),
    );
  }

  ThemeData _tema() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0A0D14),
      colorScheme: const ColorScheme.dark(
        surface: Color(0xFF0D1117),
        primary: Color(0xFF00FF9C),
        secondary: Color(0xFF58A6FF),
        error: Color(0xFFFF4757),
        onPrimary: Color(0xFF0A0D14),
        onSurface: Color(0xFFE2E8F0),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF00FF9C);
          }
          return const Color(0xFF1A2035);
        }),
        checkColor: WidgetStateProperty.all(const Color(0xFF0A0D14)),
        side: const BorderSide(color: Color(0xFF2A3550), width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      scrollbarTheme: const ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(Color(0xFF2A3550)),
        trackColor: WidgetStatePropertyAll(Colors.transparent),
      ),
    );
  }
}
