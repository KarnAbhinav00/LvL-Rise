import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'login_screen.dart';
import 'screens/home_screen.dart';
import 'theme/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const LevelRiseApp());
}

class LevelRiseApp extends StatelessWidget {
  const LevelRiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LVLRISE',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(
          surface: AppColors.surface,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Colors.white,
          surfaceContainerHighest: AppColors.surfaceVariant,
          outline: AppColors.primaryOutline,
        ),
        scaffoldBackgroundColor: AppColors.background,
        textTheme: Typography.whiteMountainView,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: AppColors.background,
              body: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            );
          }

          if (snapshot.hasData) {
            return const HomeScreen();
          }

          return const LVLRISELoginScreen();
        },
      ),
    );
  }
}
