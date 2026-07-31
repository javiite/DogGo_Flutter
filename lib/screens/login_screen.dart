import 'package:flutter/material.dart';

import '../core/errors/api_exception.dart';
import '../core/navigation/app_routes.dart';
import '../services/auth_service.dart';
import '../theme/doggo_radius.dart';
import '../theme/doggo_spacing.dart';
import '../theme/doggo_theme.dart';
import '../widgets/doggo_logo.dart';
import 'recuperar_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() {
    return _LoginScreenState();
  }
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _passwordController =
      TextEditingController();

  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  bool _hidePassword = true;
  bool _loading = false;

  String? _emailError;
  String? _passwordError;
  String? _generalError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  bool _validate() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    String? emailError;
    String? passwordError;

    if (email.isEmpty) {
      emailError = 'Escribe tu correo electrónico.';
    } else if (!_isValidEmail(email)) {
      emailError = 'Escribe un correo electrónico válido.';
    }

    if (password.isEmpty) {
      passwordError = 'Escribe tu contraseña.';
    }

    setState(() {
      _emailError = emailError;
      _passwordError = passwordError;
      _generalError = null;
    });

    if (emailError != null) {
      _emailFocus.requestFocus();
      return false;
    }

    if (passwordError != null) {
      _passwordFocus.requestFocus();
      return false;
    }

    return true;
  }

  bool _isValidEmail(String email) {
    return RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    ).hasMatch(email);
  }

  Future<void> _login() async {
    if (_loading || !_validate()) {
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _loading = true;
      _generalError = null;
    });

    try {
      final result = await AuthService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) {
        return;
      }

      if (result['success'] == true) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.home,
          (_) => false,
        );

        return;
      }

      final statusCode = result['statusCode'];

      setState(() {
        _generalError = _loginMessage(
          statusCode: statusCode is int
              ? statusCode
              : int.tryParse(
                  statusCode?.toString() ?? '',
                ),
          serverMessage:
              result['message']?.toString(),
        );
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _generalError = error.message;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _generalError = error
            .toString()
            .replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  String _loginMessage({
    required int? statusCode,
    required String? serverMessage,
  }) {
    final cleanMessage = serverMessage?.trim() ?? '';

    if (statusCode == 400 || statusCode == 401) {
      return cleanMessage.isNotEmpty
          ? cleanMessage
          : 'El correo o la contraseña no son correctos.';
    }

    if (statusCode == 403) {
      return cleanMessage.isNotEmpty
          ? cleanMessage
          : 'Debes confirmar tu correo antes de iniciar sesión.';
    }

    if (statusCode != null && statusCode >= 500) {
      return 'El servidor no está disponible en este momento.';
    }

    return cleanMessage.isNotEmpty
        ? cleanMessage
        : 'No se pudo iniciar sesión. Inténtalo nuevamente.';
  }

  Future<void> _openRecovery() async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) =>
            const RecuperarPasswordScreen(),
      ),
    );
  }

  Future<void> _openRegister() async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const RegisterScreen(),
      ),
    );
  }

  void _clearEmailError(String value) {
    if (_emailError == null &&
        _generalError == null) {
      return;
    }

    setState(() {
      _emailError = null;
      _generalError = null;
    });
  }

  void _clearPasswordError(String value) {
    if (_passwordError == null &&
        _generalError == null) {
      return;
    }

    setState(() {
      _passwordError = null;
      _generalError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DogGoTheme.cream,
      body: SafeArea(
        child: AutofillGroup(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              FocusManager.instance.primaryFocus?.unfocus();
            },
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior
                            .onDrag,
                    physics:
                        const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      DogGoSpacing.screenHorizontal,
                      DogGoSpacing.md,
                      DogGoSpacing.screenHorizontal,
                      DogGoSpacing.xl,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 430,
                        ),
                        child: _LoginCard(
                          emailController:
                              _emailController,
                          passwordController:
                              _passwordController,
                          emailFocus: _emailFocus,
                          passwordFocus:
                              _passwordFocus,
                          hidePassword:
                              _hidePassword,
                          loading: _loading,
                          emailError: _emailError,
                          passwordError:
                              _passwordError,
                          generalError:
                              _generalError,
                          onEmailChanged:
                              _clearEmailError,
                          onPasswordChanged:
                              _clearPasswordError,
                          onTogglePassword: () {
                            setState(() {
                              _hidePassword =
                                  !_hidePassword;
                            });
                          },
                          onLogin: _login,
                          onRecovery: _openRecovery,
                          onRegister: _openRegister,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        18,
        10,
        18,
        4,
      ),
      child: Row(
        children: [
          const DogGoLogo(size: 48),
          const Spacer(),
          if (Navigator.canPop(context))
            TextButton.icon(
              onPressed: _loading
                  ? null
                  : () => Navigator.maybePop(context),
              icon: const Icon(
                Icons.arrow_back_rounded,
                size: 18,
              ),
              label: const Text('Volver'),
            ),
        ],
      ),
    );
  }
}

class _LoginCard extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final FocusNode emailFocus;
  final FocusNode passwordFocus;

  final bool hidePassword;
  final bool loading;

  final String? emailError;
  final String? passwordError;
  final String? generalError;

  final ValueChanged<String> onEmailChanged;
  final ValueChanged<String> onPasswordChanged;
  final VoidCallback onTogglePassword;
  final VoidCallback onLogin;
  final VoidCallback onRecovery;
  final VoidCallback onRegister;

  const _LoginCard({
    required this.emailController,
    required this.passwordController,
    required this.emailFocus,
    required this.passwordFocus,
    required this.hidePassword,
    required this.loading,
    required this.emailError,
    required this.passwordError,
    required this.generalError,
    required this.onEmailChanged,
    required this.onPasswordChanged,
    required this.onTogglePassword,
    required this.onLogin,
    required this.onRecovery,
    required this.onRegister,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        22,
        25,
        22,
        22,
      ),
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(
          DogGoRadius.extraLarge,
        ),
        border: Border.all(color: DogGoTheme.border),
        boxShadow: DogGoTheme.softShadow(),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: const BoxDecoration(
              color: DogGoTheme.tealLight,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: DogGoLogo(size: 58),
            ),
          ),
          const SizedBox(height: DogGoSpacing.md),
          Text(
            'BIENVENIDO DE VUELTA',
            style: DogGoTheme.label(size: 10.5),
          ),
          const SizedBox(height: DogGoSpacing.sm),
          Text(
            'Iniciar sesión',
            textAlign: TextAlign.center,
            style: DogGoTheme.display(size: 31),
          ),
          const SizedBox(height: DogGoSpacing.sm),
          Text(
            'Accede para ver tus mascotas, paseos y paseadores disponibles.',
            textAlign: TextAlign.center,
            style: DogGoTheme.subtitle(size: 14),
          ),
          const SizedBox(height: DogGoSpacing.lg),
          TextField(
            controller: emailController,
            focusNode: emailFocus,
            enabled: !loading,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [
              AutofillHints.email,
              AutofillHints.username,
            ],
            autocorrect: false,
            enableSuggestions: false,
            onChanged: onEmailChanged,
            onSubmitted: (_) {
              passwordFocus.requestFocus();
            },
            decoration: InputDecoration(
              labelText: 'Correo electrónico',
              hintText: 'correo@ejemplo.com',
              errorText: emailError,
              prefixIcon:
                  const Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: DogGoSpacing.fieldGap),
          TextField(
            controller: passwordController,
            focusNode: passwordFocus,
            enabled: !loading,
            obscureText: hidePassword,
            textInputAction: TextInputAction.done,
            autofillHints: const [
              AutofillHints.password,
            ],
            autocorrect: false,
            enableSuggestions: false,
            onChanged: onPasswordChanged,
            onSubmitted: (_) => onLogin(),
            decoration: InputDecoration(
              labelText: 'Contraseña',
              errorText: passwordError,
              prefixIcon:
                  const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                onPressed:
                    loading ? null : onTogglePassword,
                tooltip: hidePassword
                    ? 'Mostrar contraseña'
                    : 'Ocultar contraseña',
                icon: Icon(
                  hidePassword
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                ),
              ),
            ),
          ),
          if (generalError != null) ...[
            const SizedBox(height: DogGoSpacing.md),
            _LoginError(message: generalError!),
          ],
          const SizedBox(height: DogGoSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: loading ? null : onLogin,
              child: loading
                  ? const SizedBox(
                      width: 21,
                      height: 21,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.3,
                      ),
                    )
                  : const Text('Iniciar sesión'),
            ),
          ),
          const SizedBox(height: DogGoSpacing.sm),
          TextButton(
            onPressed: loading ? null : onRecovery,
            child: const Text(
              '¿Olvidaste tu contraseña?',
            ),
          ),
          const SizedBox(height: DogGoSpacing.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(
              DogGoSpacing.md,
            ),
            decoration: BoxDecoration(
              color: DogGoTheme.cream,
              borderRadius: BorderRadius.circular(
                DogGoRadius.large,
              ),
              border: Border.all(
                color: DogGoTheme.border,
              ),
            ),
            child: Column(
              children: [
                Text(
                  '¿No tienes cuenta?',
                  style: DogGoTheme.title(size: 16),
                ),
                const SizedBox(height: DogGoSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed:
                        loading ? null : onRegister,
                    child: const Text('Crear cuenta'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginError extends StatelessWidget {
  final String message;

  const _LoginError({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: message,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(
          DogGoSpacing.md,
        ),
        decoration: BoxDecoration(
          color: DogGoTheme.redLight,
          borderRadius: BorderRadius.circular(
            DogGoRadius.medium,
          ),
          border: Border.all(
            color:
                DogGoTheme.red.withValues(alpha: .20),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: DogGoTheme.red,
              size: 21,
            ),
            const SizedBox(width: DogGoSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: DogGoTheme.body(
                  size: 12,
                  color: DogGoTheme.red,
                  weight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}