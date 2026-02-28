import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'core/database/sync_service.dart';
import 'core/services/fare_service.dart';
import 'core/services/auth_service.dart';
import 'onboarding/onboarding_screen.dart';
import 'login/login_screen.dart';
import 'navigation/main_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Env error");
  }

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  await FareService.init();

  final prefs = await SharedPreferences.getInstance();
  final bool onboardingCompleted =
      prefs.getBool('onboarding_completed') ?? false;

  Map<String, dynamic>? activeUser;
  if (onboardingCompleted) {
    activeUser = await AuthService().getActiveSession();
  }

  runApp(
    MyApp(onboardingCompleted: onboardingCompleted, activeUser: activeUser),
  );
}

class MyApp extends StatelessWidget {
  final bool onboardingCompleted;
  final Map<String, dynamic>? activeUser;

  const MyApp({super.key, required this.onboardingCompleted, this.activeUser});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mati Byahe',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
        useMaterial3: true,
      ),
      home: _getInitialScreen(),
      debugShowCheckedModeBanner: false,
    );
  }

  Widget _getInitialScreen() {
    if (!onboardingCompleted) return const OnboardingScreen();

    if (activeUser != null) {
      return MainNavigation(
        email: activeUser!['email'],
        role: activeUser!['role'],
      );
    }

    return const LoginScreen();
  }
}
