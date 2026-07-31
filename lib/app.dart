import 'package:flutter/material.dart';

import 'core/navigation/app_routes.dart';
import 'screens/app_start_screen.dart';
import 'theme/doggo_theme.dart';

class DogGoApp extends StatelessWidget {
  const DogGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DogGo',
      debugShowCheckedModeBanner: false,
      theme: DogGoTheme.lightTheme,
      themeMode: ThemeMode.light,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      home: const AppStartScreen(),
    );
  }
}