import 'package:flutter/material.dart';

import '../services/session_service.dart';
import '../services/storage_service.dart';
import '../shared/widgets/doggo_error_view.dart';
import '../theme/doggo_spacing.dart';
import '../theme/doggo_theme.dart';
import '../widgets/doggo_logo.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'server_setup_screen.dart';

class AppStartScreen extends StatefulWidget {
  const AppStartScreen({super.key});

  @override
  State<AppStartScreen> createState() {
    return _AppStartScreenState();
  }
}

class _AppStartScreenState extends State<AppStartScreen> {
  bool _loading = true;
  bool _hasServer = false;
  bool _hasSession = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkInitialState();
  }

  Future<void> _checkInitialState() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
    }

    try {
      final results = await Future.wait<dynamic>([
        StorageService.obtenerBaseUrl(),
        SessionService.haySesionActiva(),
      ]);

      if (!mounted) {
        return;
      }

      final baseUrl =
          results[0]?.toString().trim() ?? '';

      setState(() {
        _hasServer = baseUrl.isNotEmpty;
        _hasSession = results[1] == true;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _errorMessage = error
            .toString()
            .replaceFirst('Exception: ', '');
      });
    }
  }

  void _serverConfigured() {
    setState(() {
      _hasServer = true;
      _hasSession = false;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const _AppLoadingScreen();
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: DogGoTheme.cream,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(
                DogGoSpacing.lg,
              ),
              child: DogGoErrorView(
                title: 'No pudimos iniciar DogGo',
                message: _errorMessage!,
                onRetry: _checkInitialState,
              ),
            ),
          ),
        ),
      );
    }

    if (!_hasServer) {
      return ServerSetupScreen(
        onConfigured: _serverConfigured,
      );
    }

    if (_hasSession) {
      return const HomeScreen();
    }

    return const LoginScreen();
  }
}

class _AppLoadingScreen extends StatelessWidget {
  const _AppLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DogGoTheme.cream,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const DogGoLogo(size: 86),
              const SizedBox(height: DogGoSpacing.lg),
              const CircularProgressIndicator(),
              const SizedBox(height: DogGoSpacing.md),
              Text(
                'Preparando DogGo',
                style: DogGoTheme.body(
                  size: 13,
                  color: DogGoTheme.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}