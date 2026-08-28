import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/errors/api_exception.dart';
import '../core/navigation/app_routes.dart';
import '../services/auth_service.dart';
import '../theme/doggo_radius.dart';
import '../theme/doggo_spacing.dart';
import '../theme/doggo_theme.dart';
import '../shared/widgets/doggo_progress_steps.dart';
import '../widgets/doggo_logo.dart';

class RecuperarPasswordScreen extends StatefulWidget {
  const RecuperarPasswordScreen({super.key});

  @override
  State<RecuperarPasswordScreen> createState() {
    return _RecuperarPasswordScreenState();
  }
}

class _RecuperarPasswordScreenState extends State<RecuperarPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _codeController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

  final TextEditingController _confirmationController = TextEditingController();

  final FocusNode _emailFocus = FocusNode();
  final FocusNode _codeFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmationFocus = FocusNode();

  bool _codeRequested = false;
  bool _requestingCode = false;
  bool _changingPassword = false;
  bool _hidePassword = true;
  bool _hideConfirmation = true;

  String? _emailError;
  String? _codeError;
  String? _passwordError;
  String? _confirmationError;
  String? _generalError;
  String? _successMessage;

  bool get _busy {
    return _requestingCode || _changingPassword;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();

    _emailFocus.dispose();
    _codeFocus.dispose();
    _passwordFocus.dispose();
    _confirmationFocus.dispose();

    super.dispose();
  }

  bool _isValidEmail(String value) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
  }

  bool _validateEmail() {
    final email = _emailController.text.trim();

    String? error;

    if (email.isEmpty) {
      error = 'Escribe tu correo electrónico.';
    } else if (!_isValidEmail(email)) {
      error = 'Escribe un correo válido.';
    }

    setState(() {
      _emailError = error;
      _generalError = null;
      _successMessage = null;
    });

    if (error != null) {
      _emailFocus.requestFocus();
      return false;
    }

    return true;
  }

  bool _validatePasswordChange() {
    final code = _codeController.text.trim();
    final password = _passwordController.text;
    final confirmation = _confirmationController.text;

    String? codeError;
    String? passwordError;
    String? confirmationError;

    if (code.isEmpty) {
      codeError = 'Escribe el código recibido.';
    } else if (code.length < 4) {
      codeError = 'El código es demasiado corto.';
    }

    if (password.isEmpty) {
      passwordError = 'Escribe una contraseña nueva.';
    } else if (password.length < 8) {
      passwordError = 'Usa al menos 8 caracteres.';
    } else if (!RegExp(r'[A-Za-z]').hasMatch(password) ||
        !RegExp(r'\d').hasMatch(password)) {
      passwordError = 'Incluye letras y números.';
    }

    if (confirmation.isEmpty) {
      confirmationError = 'Confirma la contraseña nueva.';
    } else if (confirmation != password) {
      confirmationError = 'Las contraseñas no coinciden.';
    }

    setState(() {
      _codeError = codeError;
      _passwordError = passwordError;
      _confirmationError = confirmationError;
      _generalError = null;
      _successMessage = null;
    });

    if (codeError != null) {
      _codeFocus.requestFocus();
      return false;
    }

    if (passwordError != null) {
      _passwordFocus.requestFocus();
      return false;
    }

    if (confirmationError != null) {
      _confirmationFocus.requestFocus();
      return false;
    }

    return true;
  }

  Future<void> _requestCode() async {
    if (_busy || !_validateEmail()) {
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _requestingCode = true;
      _generalError = null;
      _successMessage = null;
    });

    try {
      final result = await AuthService.solicitarRecuperacion(
        email: _emailController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      if (result['success'] == true) {
        setState(() {
          _codeRequested = true;
          _successMessage =
              result['message']?.toString() ??
              'Enviamos un código a tu correo.';
        });

        await Future<void>.delayed(const Duration(milliseconds: 250));

        if (mounted) {
          _codeFocus.requestFocus();
        }

        return;
      }

      setState(() {
        _generalError =
            result['message']?.toString() ?? 'No se pudo enviar el código.';
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
        _generalError = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _requestingCode = false;
        });
      }
    }
  }

  Future<void> _changePassword() async {
    if (_busy || !_validateEmail() || !_validatePasswordChange()) {
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _changingPassword = true;
      _generalError = null;
      _successMessage = null;
    });

    try {
      final result = await AuthService.recuperarPassword(
        email: _emailController.text.trim(),
        codigo: _codeController.text.trim(),
        nuevaPassword: _passwordController.text,
      );

      if (!mounted) {
        return;
      }

      if (result['success'] == true) {
        _showMessage(
          result['message']?.toString() ??
              'Contraseña actualizada correctamente.',
        );

        await Future<void>.delayed(const Duration(milliseconds: 500));

        if (!mounted) {
          return;
        }

        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
          (_) => false,
        );

        return;
      }

      setState(() {
        _generalError =
            result['message']?.toString() ??
            'No se pudo actualizar la contraseña.';
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
        _generalError = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _changingPassword = false;
        });
      }
    }
  }

  void _editEmail() {
    setState(() {
      _codeRequested = false;
      _codeController.clear();
      _passwordController.clear();
      _confirmationController.clear();
      _codeError = null;
      _passwordError = null;
      _confirmationError = null;
      _generalError = null;
      _successMessage = null;
    });

    _emailFocus.requestFocus();
  }

  void _goToLogin() {
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _clearError(_RecoveryField field) {
    setState(() {
      switch (field) {
        case _RecoveryField.email:
          _emailError = null;
        case _RecoveryField.code:
          _codeError = null;
        case _RecoveryField.password:
          _passwordError = null;
        case _RecoveryField.confirmation:
          _confirmationError = null;
      }

      _generalError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DogGoTheme.cream,
      appBar: AppBar(
        toolbarHeight: 72,
        leading: IconButton(
          onPressed: _busy ? null : _goToLogin,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const DogGoLogo(size: 48),
      ),
      body: SafeArea(
        top: false,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              DogGoSpacing.screenHorizontal,
              DogGoSpacing.md,
              DogGoSpacing.screenHorizontal,
              DogGoSpacing.xl,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Column(
                  children: [
                    _RecoveryHeader(codeRequested: _codeRequested),
                    const SizedBox(height: DogGoSpacing.md),
                    _buildForm(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DogGoSpacing.cardPadding),
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(DogGoRadius.large),
        border: Border.all(color: DogGoTheme.border),
      ),
      child: Column(
        children: [
          TextField(
            controller: _emailController,
            focusNode: _emailFocus,
            enabled: !_busy && !_codeRequested,
            keyboardType: TextInputType.emailAddress,
            textInputAction: _codeRequested
                ? TextInputAction.next
                : TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            autocorrect: false,
            enableSuggestions: false,
            onChanged: (_) {
              _clearError(_RecoveryField.email);
            },
            onSubmitted: (_) {
              if (!_codeRequested) {
                _requestCode();
              }
            },
            decoration: InputDecoration(
              labelText: 'Correo electrónico',
              hintText: 'correo@ejemplo.com',
              errorText: _emailError,
              prefixIcon: const Icon(Icons.email_outlined),
              suffixIcon: _codeRequested
                  ? IconButton(
                      onPressed: _busy ? null : _editEmail,
                      tooltip: 'Cambiar correo',
                      icon: const Icon(Icons.edit_outlined),
                    )
                  : null,
            ),
          ),
          if (_codeRequested) ...[
            const SizedBox(height: DogGoSpacing.fieldGap),
            TextField(
              controller: _codeController,
              focusNode: _codeFocus,
              enabled: !_busy,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.oneTimeCode],
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(8),
              ],
              onChanged: (_) {
                _clearError(_RecoveryField.code);
              },
              onSubmitted: (_) {
                _passwordFocus.requestFocus();
              },
              decoration: InputDecoration(
                labelText: 'Código de recuperación',
                hintText: 'Ej. 123456',
                errorText: _codeError,
                prefixIcon: const Icon(Icons.password_rounded),
              ),
            ),
            const SizedBox(height: DogGoSpacing.fieldGap),
            TextField(
              controller: _passwordController,
              focusNode: _passwordFocus,
              enabled: !_busy,
              obscureText: _hidePassword,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              autocorrect: false,
              enableSuggestions: false,
              onChanged: (_) {
                _clearError(_RecoveryField.password);
              },
              onSubmitted: (_) {
                _confirmationFocus.requestFocus();
              },
              decoration: InputDecoration(
                labelText: 'Contraseña nueva',
                errorText: _passwordError,
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  onPressed: _busy
                      ? null
                      : () {
                          setState(() {
                            _hidePassword = !_hidePassword;
                          });
                        },
                  tooltip: _hidePassword
                      ? 'Mostrar contraseña'
                      : 'Ocultar contraseña',
                  icon: Icon(
                    _hidePassword
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                  ),
                ),
              ),
            ),
            const SizedBox(height: DogGoSpacing.fieldGap),
            TextField(
              controller: _confirmationController,
              focusNode: _confirmationFocus,
              enabled: !_busy,
              obscureText: _hideConfirmation,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              autocorrect: false,
              enableSuggestions: false,
              onChanged: (_) {
                _clearError(_RecoveryField.confirmation);
              },
              onSubmitted: (_) => _changePassword(),
              decoration: InputDecoration(
                labelText: 'Confirmar contraseña',
                errorText: _confirmationError,
                prefixIcon: const Icon(Icons.lock_reset_rounded),
                suffixIcon: IconButton(
                  onPressed: _busy
                      ? null
                      : () {
                          setState(() {
                            _hideConfirmation = !_hideConfirmation;
                          });
                        },
                  tooltip: _hideConfirmation
                      ? 'Mostrar contraseña'
                      : 'Ocultar contraseña',
                  icon: Icon(
                    _hideConfirmation
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                  ),
                ),
              ),
            ),
          ],
          if (_successMessage != null) ...[
            const SizedBox(height: DogGoSpacing.md),
            _RecoveryMessage(message: _successMessage!, success: true),
          ],
          if (_generalError != null) ...[
            const SizedBox(height: DogGoSpacing.md),
            _RecoveryMessage(message: _generalError!, success: false),
          ],
          const SizedBox(height: DogGoSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _busy
                  ? null
                  : _codeRequested
                  ? _changePassword
                  : _requestCode,
              child: _busy
                  ? const SizedBox(
                      width: 21,
                      height: 21,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.3,
                      ),
                    )
                  : Text(
                      _codeRequested ? 'Cambiar contraseña' : 'Enviar código',
                    ),
            ),
          ),
          if (_codeRequested) ...[
            const SizedBox(height: DogGoSpacing.sm),
            TextButton(
              onPressed: _busy ? null : _requestCode,
              child: const Text('Enviar código nuevamente'),
            ),
          ],
          TextButton(
            onPressed: _busy ? null : _goToLogin,
            child: const Text('Volver al login'),
          ),
        ],
      ),
    );
  }
}

enum _RecoveryField { email, code, password, confirmation }

class _RecoveryHeader extends StatelessWidget {
  final bool codeRequested;

  const _RecoveryHeader({required this.codeRequested});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DogGoSpacing.lg),
      decoration: BoxDecoration(
        color: DogGoTheme.teal,
        borderRadius: BorderRadius.circular(DogGoRadius.extraLarge),
        boxShadow: DogGoTheme.elevatedShadow(),
      ),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              codeRequested ? Icons.password_rounded : Icons.lock_reset_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(height: DogGoSpacing.md),
          Text(
            codeRequested ? 'REVISA TU CORREO' : 'RECUPERA TU CUENTA',
            style: DogGoTheme.label(size: 10.5, color: DogGoTheme.orange),
          ),
          const SizedBox(height: DogGoSpacing.sm),
          Text(
            codeRequested
                ? 'Crea una contraseña nueva'
                : '¿Olvidaste tu contraseña?',
            textAlign: TextAlign.center,
            style: DogGoTheme.display(size: 27, color: Colors.white),
          ),
          const SizedBox(height: DogGoSpacing.sm),
          Text(
            codeRequested
                ? 'Escribe el código recibido y elige una contraseña segura.'
                : 'Te enviaremos un código para recuperar el acceso.',
            textAlign: TextAlign.center,
            style: DogGoTheme.body(
              size: 13,
              color: Colors.white.withValues(alpha: .80),
              weight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: DogGoSpacing.md),
          DogGoProgressSteps(
            current: codeRequested ? 2 : 1,
            total: 2,
            label: codeRequested ? 'Nueva contraseña' : 'Verificar cuenta',
            onDarkBackground: true,
          ),
        ],
      ),
    );
  }
}

class _RecoveryMessage extends StatelessWidget {
  final String message;
  final bool success;

  const _RecoveryMessage({required this.message, required this.success});

  @override
  Widget build(BuildContext context) {
    final color = success ? DogGoTheme.green : DogGoTheme.red;

    final background = success ? DogGoTheme.greenLight : DogGoTheme.redLight;

    return Semantics(
      liveRegion: true,
      label: message,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(DogGoSpacing.md),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(DogGoRadius.medium),
          border: Border.all(color: color.withValues(alpha: .20)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              success
                  ? Icons.check_circle_outline_rounded
                  : Icons.error_outline_rounded,
              color: color,
              size: 21,
            ),
            const SizedBox(width: DogGoSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: DogGoTheme.body(
                  size: 12,
                  color: color,
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
