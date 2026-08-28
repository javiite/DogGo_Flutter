import 'package:flutter/material.dart';

import 'core/navigation/app_routes.dart';
import 'screens/app_start_screen.dart';
import 'services/app_preferences_service.dart';
import 'theme/doggo_theme.dart';

class DogGoApp extends StatefulWidget {
  const DogGoApp({super.key});

  @override
  State<DogGoApp> createState() => _DogGoAppState();
}

class _DogGoAppState extends State<DogGoApp> {
  final _preferences = AppPreferencesController.instance;

  @override
  void initState() {
    super.initState();
    _preferences.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _preferences,
      builder: (context, _) => MaterialApp(
        title: 'DogGo',
        debugShowCheckedModeBanner: false,
        theme: DogGoTheme.lightTheme,
        darkTheme: DogGoTheme.darkTheme,
        themeMode: _preferences.value.themeMode,
        builder: (context, child) {
          final media = MediaQuery.of(context);
          return MediaQuery(
            data: media.copyWith(
              textScaler: TextScaler.linear(_preferences.value.textScale),
            ),
            child: child!,
          );
        },
        onGenerateRoute: AppRoutes.onGenerateRoute,
        home: const AppStartScreen(),
      ),
    );
  }
}
