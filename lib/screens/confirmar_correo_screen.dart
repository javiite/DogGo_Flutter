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

class ConfirmarCorreoScreen extends StatefulWidget {
  final String? email;

  const ConfirmarCorreoScreen({super.key, this.email});

  @override
  State<ConfirmarCorreoScreen> createState() {
    return _ConfirmarCorreoScreenState();
  }
}

class _ConfirmarCorreoScreenState extends State<ConfirmarCorreoScreen> {
  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _codeController = TextEditingController();

  final FocusNode _emailFocus = FocusNode();
  final FocusNode _codeFocus = FocusNode();

  bool _confirming = false;

  String? _emailError;
  String? _codeError;
  String? _generalError;

  @override
  void initState() {
    super.initState();

    final initialEmail = widget.email?.trim() ?? '';

    if (initialEmail.isNotEmpty) {
      _emailController.text = initialEmail;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _emailFocus.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  bool _validate() {
    final email = _emailController.text.trim();
    final code = _codeController.text.trim();

    String? emailError;
    String? codeError;

    if (email.isEmpty) {
      emailError = 'Escribe tu correo electrónico.';
    } else if (!_isValidEmail(email)) {
      emailError = 'Escribe un correo válido.';
    }

    if (code.isEmpty) {
      codeError = 'Escribe el código de confirmación.';
    } else if (code.length < 4) {
      codeError = 'El código es demasiado corto.';
    }

    setState(() {
      _emailError = emailError;
      _codeError = codeError;
      _generalError = null;
    });

    if (emailError != null) {
      _emailFocus.requestFocus();
      return false;
    }

    if (codeError != null) {
      _codeFocus.requestFocus();
      return false;
    }

    return true;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  Future<void> _confirmEmail() async {
    if (_confirming || !_validate()) {
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _confirming = true;
      _generalError = null;
    });

    try {
      final result = await AuthService.confirmarCorreo(
        email: _emailController.text.trim(),
        codigo: _codeController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      if (result['success'] == true) {
        _showMessage(
          result['message']?.toString() ?? 'Correo confirmado correctamente.',
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
            result['message']?.toString() ?? 'No se pudo confirmar el correo.';
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
          _confirming = false;
        });
      }
    }
  }

  void _clearEmailError(String value) {
    if (_emailError == null && _generalError == null) {
      return;
    }

    setState(() {
      _emailError = null;
      _generalError = null;
    });
  }

  void _clearCodeError(String value) {
    if (_codeError == null && _generalError == null) {
      return;
    }

    setState(() {
      _codeError = null;
      _generalError = null;
    });
  }

  void _goToLogin() {
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DogGoTheme.cream,
      appBar: AppBar(
        toolbarHeight: 72,
        leading: IconButton(
          onPressed: _confirming ? null : _goToLogin,
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
                    const _ConfirmationHeader(),
                    const SizedBox(height: DogGoSpacing.md),
                    _ConfirmationForm(
                      emailController: _emailController,
                      codeController: _codeController,
                      emailFocus: _emailFocus,
                      codeFocus: _codeFocus,
                      confirming: _confirming,
                      emailError: _emailError,
                      codeError: _codeError,
                      generalError: _generalError,
                      onEmailChanged: _clearEmailError,
                      onCodeChanged: _clearCodeError,
                      onConfirm: _confirmEmail,
                      onBackToLogin: _goToLogin,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfirmationHeader extends StatelessWidget {
  const _ConfirmationHeader();

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
            child: const Icon(
              Icons.mark_email_read_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(height: DogGoSpacing.md),
          Text(
            'VERIFICA TU CUENTA',
            style: DogGoTheme.label(size: 10.5, color: DogGoTheme.orange),
          ),
          const SizedBox(height: DogGoSpacing.sm),
          Text(
            'Confirma tu correo',
            textAlign: TextAlign.center,
            style: DogGoTheme.display(size: 28, color: Colors.white),
          ),
          const SizedBox(height: DogGoSpacing.sm),
          Text(
            'Escribe el código que enviamos a tu correo electrónico.',
            textAlign: TextAlign.center,
            style: DogGoTheme.body(
              size: 13,
              color: Colors.white.withValues(alpha: .80),
              weight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: DogGoSpacing.md),
          const DogGoProgressSteps(
            current: 2,
            total: 3,
            label: 'Verificación de correo',
            onDarkBackground: true,
          ),
        ],
      ),
    );
  }
}

class _ConfirmationForm extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController codeController;
  final FocusNode emailFocus;
  final FocusNode codeFocus;

  final bool confirming;

  final String? emailError;
  final String? codeError;
  final String? generalError;

  final ValueChanged<String> onEmailChanged;
  final ValueChanged<String> onCodeChanged;
  final VoidCallback onConfirm;
  final VoidCallback onBackToLogin;

  const _ConfirmationForm({
    required this.emailController,
    required this.codeController,
    required this.emailFocus,
    required this.codeFocus,
    required this.confirming,
    required this.emailError,
    required this.codeError,
    required this.generalError,
    required this.onEmailChanged,
    required this.onCodeChanged,
    required this.onConfirm,
    required this.onBackToLogin,
  });

  @override
  Widget build(BuildContext context) {
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
            controller: emailController,
            focusNode: emailFocus,
            enabled: !confirming,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            autocorrect: false,
            enableSuggestions: false,
            onChanged: onEmailChanged,
            onSubmitted: (_) {
              codeFocus.requestFocus();
            },
            decoration: InputDecoration(
              labelText: 'Correo electrónico',
              hintText: 'correo@ejemplo.com',
              errorText: emailError,
              prefixIcon: const Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: DogGoSpacing.fieldGap),
          TextField(
            controller: codeController,
            focusNode: codeFocus,
            enabled: !confirming,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.oneTimeCode],
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(8),
            ],
            onChanged: onCodeChanged,
            onSubmitted: (_) => onConfirm(),
            decoration: InputDecoration(
              labelText: 'Código de confirmación',
              hintText: 'Ej. 123456',
              errorText: codeError,
              prefixIcon: const Icon(Icons.password_rounded),
            ),
          ),
          if (generalError != null) ...[
            const SizedBox(height: DogGoSpacing.md),
            _ConfirmationError(message: generalError!),
          ],
          const SizedBox(height: DogGoSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: confirming ? null : onConfirm,
              child: confirming
                  ? const SizedBox(
                      width: 21,
                      height: 21,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.3,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Confirmar correo'),
            ),
          ),
          const SizedBox(height: DogGoSpacing.sm),
          TextButton(
            onPressed: confirming ? null : onBackToLogin,
            child: const Text('Volver al login'),
          ),
        ],
      ),
    );
  }
}

class _ConfirmationError extends StatelessWidget {
  final String message;

  const _ConfirmationError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DogGoSpacing.md),
      decoration: BoxDecoration(
        color: DogGoTheme.redLight,
        borderRadius: BorderRadius.circular(DogGoRadius.medium),
        border: Border.all(color: DogGoTheme.red.withValues(alpha: .20)),
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
    );
  }
}
