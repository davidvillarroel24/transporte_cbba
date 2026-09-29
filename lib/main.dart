import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'theme/app_colors.dart';

void main() {
  runApp(const TransporteApp());
}

class TransporteApp extends StatelessWidget {
  const TransporteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'Maestrito',

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.verde,
        ),
        scaffoldBackgroundColor: AppColors.grisFondo,
        useMaterial3: true,
      ),

      home: const SplashScreen(),
    );
  }
}