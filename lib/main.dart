import 'package:flutter/material.dart';
import 'screens/server_config_screen.dart';

void main() {
  runApp(const DogGoApp());
}

class DogGoApp extends StatelessWidget {
  const DogGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DogGo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: ServerConfigScreen(),
    );
  }
}