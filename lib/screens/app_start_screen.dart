import 'package:flutter/material.dart';

import '../services/session_service.dart';
import '../shared/widgets/doggo_error_view.dart';
import '../theme/doggo_spacing.dart';
import '../theme/doggo_theme.dart';
import '../widgets/doggo_logo.dart';
import 'authenticated_entry_screen.dart';
import 'login_screen.dart';

class AppStartScreen extends StatefulWidget {
  const AppStartScreen({super.key});

  @override
  State<AppStartScreen> createState() {
    return _AppStartScreenState();
  }
}

class _AppStartScreenState extends State<AppStartScreen> {
  bool _loading = true;
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
      final hasSession = await SessionService.haySesionActiva();

      if (!mounted) {
        return;
      }

      setState(() {
        _hasSession = hasSession;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
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
              padding: const EdgeInsets.all(DogGoSpacing.lg),
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

    if (_hasSession) {
      return const AuthenticatedEntryScreen();
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
                style: DogGoTheme.body(size: 13, color: DogGoTheme.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
