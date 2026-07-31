import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/errors/api_exception.dart';
import '../services/usuario_service.dart';
import '../theme/doggo_radius.dart';
import '../theme/doggo_spacing.dart';
import '../theme/doggo_theme.dart';

class CambiarPasswordScreen extends StatefulWidget {
  const CambiarPasswordScreen({super.key});

  @override
  State<CambiarPasswordScreen> createState() =>
      _CambiarPasswordScreenState();
}

class _CambiarPasswordScreenState
    extends State<CambiarPasswordScreen> {
  final UsuarioService _usuarioService = UsuarioService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _actualController =
      TextEditingController();
  final TextEditingController _nuevaController =
      TextEditingController();
  final TextEditingController _confirmarController =
      TextEditingController();

  bool _guardando = false;
  bool _mostrarActual = false;
  bool _mostrarNueva = false;
  bool _mostrarConfirmacion = false;
  bool _intentoGuardar = false;

  @override
  void initState() {
    super.initState();

    _actualController.addListener(_actualizar);
    _nuevaController.addListener(_actualizar);
    _confirmarController.addListener(_actualizar);
  }

  @override
  void dispose() {
    _actualController
      ..removeListener(_actualizar)
      ..dispose();

    _nuevaController
      ..removeListener(_actualizar)
      ..dispose();

    _confirmarController
      ..removeListener(_actualizar)
      ..dispose();

    super.dispose();
  }

  void _actualizar() {
    if (mounted) {
      setState(() {});
    }
  }

  String get _actual => _actualController.text;
  String get _nueva => _nuevaController.text;
  String get _confirmacion => _confirmarController.text;

  bool get _longitudCorrecta => _nueva.length >= 8;

  bool get _tieneMayuscula =>
      RegExp(r'[A-ZÁÉÍÓÚÑ]').hasMatch(_nueva);

  bool get _tieneMinuscula =>
      RegExp(r'[a-záéíóúñ]').hasMatch(_nueva);

  bool get _tieneNumero =>
      RegExp(r'[0-9]').hasMatch(_nueva);

  bool get _esDiferente =>
      _nueva.isNotEmpty && _nueva != _actual;

  bool get _coinciden =>
      _nueva.isNotEmpty && _nueva == _confirmacion;

  int get _securityScore {
    var score = 0;

    if (_longitudCorrecta) score++;
    if (_tieneMayuscula) score++;
    if (_tieneMinuscula) score++;
    if (_tieneNumero) score++;
    if (_nueva.length >= 12) score++;

    return score;
  }

  String get _securityLabel {
    if (_nueva.isEmpty) return 'Sin evaluar';
    if (_securityScore <= 2) return 'Débil';
    if (_securityScore <= 4) return 'Buena';
    return 'Muy segura';
  }

  Color get _securityColor {
    if (_nueva.isEmpty) return DogGoTheme.muted;
    if (_securityScore <= 2) return DogGoTheme.red;
    if (_securityScore <= 4) return DogGoTheme.orange;
    return DogGoTheme.green;
  }

  Color get _securityBackground {
    if (_nueva.isEmpty) return DogGoTheme.purpleLight;
    if (_securityScore <= 2) return DogGoTheme.redLight;
    if (_securityScore <= 4) return DogGoTheme.orangeLight;
    return DogGoTheme.greenLight;
  }

  bool get _puedeGuardar {
    return !_guardando &&
        _actual.isNotEmpty &&
        _longitudCorrecta &&
        _tieneMayuscula &&
        _tieneMinuscula &&
        _tieneNumero &&
        _esDiferente &&
        _coinciden;
  }

  String? _validarActual(String? value) {
    if ((value ?? '').isEmpty) {
      return 'Escribe tu contraseña actual.';
    }

    return null;
  }

  String? _validarNueva(String? value) {
    final password = value ?? '';

    if (password.isEmpty) {
      return 'Escribe la nueva contraseña.';
    }

    if (password.length < 8) {
      return 'Debe tener al menos 8 caracteres.';
    }

    if (!RegExp(r'[A-ZÁÉÍÓÚÑ]').hasMatch(password)) {
      return 'Agrega al menos una letra mayúscula.';
    }

    if (!RegExp(r'[a-záéíóúñ]').hasMatch(password)) {
      return 'Agrega al menos una letra minúscula.';
    }

    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Agrega al menos un número.';
    }

    if (password == _actual) {
      return 'Debe ser diferente a la contraseña actual.';
    }

    return null;
  }

  String? _validarConfirmacion(String? value) {
    final password = value ?? '';

    if (password.isEmpty) {
      return 'Confirma la nueva contraseña.';
    }

    if (password != _nueva) {
      return 'Las contraseñas no coinciden.';
    }

    return null;
  }

  String _cleanError(Object error) {
    if (error is ApiException) {
      return error.message;
    }

    final message = error
        .toString()
        .replaceFirst('Exception: ', '')
        .replaceFirst('ApiException: ', '')
        .trim();

    return message.isEmpty
        ? 'No se pudo actualizar la contraseña.'
        : message;
  }

  void _showMessage(
    String message, {
    bool error = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor:
              error ? DogGoTheme.red : DogGoTheme.ink,
          content: Row(
            children: [
              Icon(
                error
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_outline_rounded,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }

  Future<void> _save() async {
    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _intentoGuardar = true;
    });

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _guardando = true;
    });

    try {
      await _usuarioService.cambiarPassword(
        passwordActual: _actual,
        passwordNueva: _nueva,
      );

      if (!mounted) return;

      TextInput.finishAutofillContext(
        shouldSave: true,
      );

      _showMessage(
        'Tu contraseña se actualizó correctamente.',
      );

      await Future<void>.delayed(
        const Duration(milliseconds: 600),
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (error) {
      _showMessage(
        _cleanError(error),
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _guardando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cambiar contraseña'),
      ),
      body: SafeArea(
        child: AutofillGroup(
          child: Form(
            key: _formKey,
            autovalidateMode: _intentoGuardar
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            child: ListView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(
                DogGoSpacing.screenHorizontal,
                DogGoSpacing.md,
                DogGoSpacing.screenHorizontal,
                DogGoSpacing.xl,
              ),
              children: [
                _buildHeader(),
                const SizedBox(
                  height: DogGoSpacing.largeGap,
                ),
                _PasswordField(
                  controller: _actualController,
                  label: 'Contraseña actual',
                  hint: 'Escribe tu contraseña actual',
                  visible: _mostrarActual,
                  autofillHints: const [
                    AutofillHints.password,
                  ],
                  textInputAction: TextInputAction.next,
                  validator: _validarActual,
                  onToggleVisibility: () {
                    setState(() {
                      _mostrarActual = !_mostrarActual;
                    });
                  },
                ),
                const SizedBox(height: DogGoSpacing.md),
                _PasswordField(
                  controller: _nuevaController,
                  label: 'Nueva contraseña',
                  hint: 'Crea una contraseña segura',
                  visible: _mostrarNueva,
                  autofillHints: const [
                    AutofillHints.newPassword,
                  ],
                  textInputAction: TextInputAction.next,
                  validator: _validarNueva,
                  onToggleVisibility: () {
                    setState(() {
                      _mostrarNueva = !_mostrarNueva;
                    });
                  },
                ),
                const SizedBox(height: DogGoSpacing.md),
                _PasswordField(
                  controller: _confirmarController,
                  label: 'Confirmar contraseña',
                  hint: 'Escríbela nuevamente',
                  visible: _mostrarConfirmacion,
                  autofillHints: const [
                    AutofillHints.newPassword,
                  ],
                  textInputAction: TextInputAction.done,
                  validator: _validarConfirmacion,
                  onFieldSubmitted: (_) {
                    if (_puedeGuardar) {
                      _save();
                    }
                  },
                  onToggleVisibility: () {
                    setState(() {
                      _mostrarConfirmacion =
                          !_mostrarConfirmacion;
                    });
                  },
                ),
                const SizedBox(
                  height: DogGoSpacing.largeGap,
                ),
                _buildSecurityCard(),
                const SizedBox(height: DogGoSpacing.lg),
                SizedBox(
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed:
                        _puedeGuardar ? _save : null,
                    icon: _guardando
                        ? const SizedBox(
                            width: 19,
                            height: 19,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.lock_reset_rounded,
                          ),
                    label: Text(
                      _guardando
                          ? 'Actualizando...'
                          : 'Actualizar contraseña',
                    ),
                  ),
                ),
                const SizedBox(height: DogGoSpacing.md),
                _buildInformation(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(
        DogGoSpacing.cardPadding,
      ),
      decoration: BoxDecoration(
        color: DogGoTheme.tealLight,
        borderRadius: BorderRadius.circular(
          DogGoRadius.large,
        ),
        border: Border.all(
          color: DogGoTheme.teal.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: DogGoTheme.card,
              borderRadius: BorderRadius.circular(
                DogGoRadius.medium,
              ),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: DogGoTheme.teal,
              size: 28,
            ),
          ),
          const SizedBox(width: DogGoSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Protege tu cuenta',
                  style: DogGoTheme.title(size: 20),
                ),
                const SizedBox(height: DogGoSpacing.xs),
                Text(
                  'Usa una contraseña distinta a las que utilizas en otros servicios.',
                  style: DogGoTheme.subtitle(size: 13.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityCard() {
    final progress =
        (_securityScore / 5).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(
        DogGoSpacing.cardPadding,
      ),
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(
          DogGoRadius.large,
        ),
        border: Border.all(
          color: DogGoTheme.border,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _securityBackground,
                  borderRadius: BorderRadius.circular(
                    DogGoRadius.medium,
                  ),
                ),
                child: Icon(
                  Icons.security_rounded,
                  color: _securityColor,
                ),
              ),
              const SizedBox(width: DogGoSpacing.compactGap),
              Expanded(
                child: Text(
                  'Seguridad',
                  style: DogGoTheme.title(size: 16),
                ),
              ),
              Text(
                _securityLabel,
                style: DogGoTheme.body(
                  size: 12.5,
                  weight: FontWeight.w800,
                  color: _securityColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: DogGoSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(
              DogGoRadius.pill,
            ),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              color: _securityColor,
              backgroundColor: DogGoTheme.divider,
            ),
          ),
          const SizedBox(height: DogGoSpacing.md),
          _PasswordRule(
            text: 'Al menos 8 caracteres',
            completed: _longitudCorrecta,
          ),
          _PasswordRule(
            text: 'Una letra mayúscula',
            completed: _tieneMayuscula,
          ),
          _PasswordRule(
            text: 'Una letra minúscula',
            completed: _tieneMinuscula,
          ),
          _PasswordRule(
            text: 'Al menos un número',
            completed: _tieneNumero,
          ),
          _PasswordRule(
            text: 'Diferente a la contraseña actual',
            completed: _esDiferente,
          ),
          _PasswordRule(
            text: 'Las contraseñas coinciden',
            completed: _coinciden,
            last: true,
          ),
        ],
      ),
    );
  }

  Widget _buildInformation() {
    return Container(
      padding: const EdgeInsets.all(DogGoSpacing.md),
      decoration: BoxDecoration(
        color: DogGoTheme.orangeLight,
        borderRadius: BorderRadius.circular(
          DogGoRadius.medium,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: DogGoTheme.orange,
          ),
          const SizedBox(width: DogGoSpacing.compactGap),
          Expanded(
            child: Text(
              'Después de actualizarla, utiliza la nueva contraseña en tus próximos inicios de sesión.',
              style: DogGoTheme.body(
                size: 12.5,
                color: DogGoTheme.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool visible;
  final Iterable<String>? autofillHints;
  final TextInputAction textInputAction;
  final String? Function(String?) validator;
  final ValueChanged<String>? onFieldSubmitted;
  final VoidCallback onToggleVisibility;

  const _PasswordField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.visible,
    required this.autofillHints,
    required this.textInputAction,
    required this.validator,
    required this.onToggleVisibility,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: !visible,
      enableSuggestions: false,
      autocorrect: false,
      autofillHints: autofillHints,
      textInputAction: textInputAction,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: const Icon(
          Icons.lock_outline_rounded,
        ),
        suffixIcon: IconButton(
          tooltip: visible
              ? 'Ocultar contraseña'
              : 'Mostrar contraseña',
          onPressed: onToggleVisibility,
          icon: Icon(
            visible
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
          ),
        ),
      ),
    );
  }
}

class _PasswordRule extends StatelessWidget {
  final String text;
  final bool completed;
  final bool last;

  const _PasswordRule({
    required this.text,
    required this.completed,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: last ? 0 : DogGoSpacing.sm,
      ),
      child: Row(
        children: [
          Icon(
            completed
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: completed
                ? DogGoTheme.green
                : DogGoTheme.muted,
            size: 19,
          ),
          const SizedBox(width: DogGoSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: DogGoTheme.body(
                size: 12.5,
                color: completed
                    ? DogGoTheme.ink
                    : DogGoTheme.muted,
                weight: completed
                    ? FontWeight.w700
                    : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}