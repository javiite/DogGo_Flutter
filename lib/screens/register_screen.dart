import 'package:flutter/material.dart';

import '../core/errors/api_exception.dart';
import '../services/auth_service.dart';
import '../theme/doggo_radius.dart';
import '../theme/doggo_spacing.dart';
import '../theme/doggo_theme.dart';
import '../widgets/doggo_logo.dart';
import 'confirmar_correo_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() {
    return _RegisterScreenState();
  }
}

class _RegisterScreenState
    extends State<RegisterScreen> {
  final TextEditingController _nameController =
      TextEditingController();

  final TextEditingController _lastNameController =
      TextEditingController();

  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _phoneController =
      TextEditingController();

  final TextEditingController _passwordController =
      TextEditingController();

  final TextEditingController _confirmPasswordController =
      TextEditingController();

  String _selectedRole = 'Dueño';

  bool _hidePassword = true;
  bool _hideConfirmation = true;
  bool _registering = false;

  Map<_RegisterField, String> _errors = {};
  String? _generalError;

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validate() {
    final errors = <_RegisterField, String>{};

    final name = _nameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final confirmation =
        _confirmPasswordController.text;

    if (name.isEmpty) {
      errors[_RegisterField.name] =
          'Escribe tu nombre.';
    } else if (name.length < 2) {
      errors[_RegisterField.name] =
          'El nombre es demasiado corto.';
    }

    if (lastName.isEmpty) {
      errors[_RegisterField.lastName] =
          'Escribe tu apellido.';
    } else if (lastName.length < 2) {
      errors[_RegisterField.lastName] =
          'El apellido es demasiado corto.';
    }

    if (email.isEmpty) {
      errors[_RegisterField.email] =
          'Escribe tu correo electrónico.';
    } else if (!_isValidEmail(email)) {
      errors[_RegisterField.email] =
          'Escribe un correo válido.';
    }

    final phoneDigits =
        phone.replaceAll(RegExp(r'\D'), '');

    if (phone.isEmpty) {
      errors[_RegisterField.phone] =
          'Escribe tu teléfono.';
    } else if (phoneDigits.length < 10) {
      errors[_RegisterField.phone] =
          'El teléfono debe tener al menos 10 dígitos.';
    }

    if (password.isEmpty) {
      errors[_RegisterField.password] =
          'Crea una contraseña.';
    } else if (password.length < 8) {
      errors[_RegisterField.password] =
          'Usa al menos 8 caracteres.';
    } else if (!_hasLetterAndNumber(password)) {
      errors[_RegisterField.password] =
          'Incluye letras y números.';
    }

    if (confirmation.isEmpty) {
      errors[_RegisterField.confirmation] =
          'Confirma tu contraseña.';
    } else if (confirmation != password) {
      errors[_RegisterField.confirmation] =
          'Las contraseñas no coinciden.';
    }

    setState(() {
      _errors = errors;
      _generalError = null;
    });

    return errors.isEmpty;
  }

  bool _isValidEmail(String email) {
    return RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    ).hasMatch(email);
  }

  bool _hasLetterAndNumber(String password) {
    return RegExp(r'[A-Za-z]').hasMatch(password) &&
        RegExp(r'\d').hasMatch(password);
  }

  Future<void> _register() async {
    if (_registering || !_validate()) {
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _registering = true;
      _generalError = null;
    });

    final email = _emailController.text.trim();

    try {
      final result = await AuthService.registrar(
        nombre: _nameController.text.trim(),
        apellido: _lastNameController.text.trim(),
        email: email,
        password: _passwordController.text,
        telefono: _phoneController.text.trim(),
        rol: _apiRole,
      );

      if (!mounted) {
        return;
      }

      if (result['success'] == true) {
        _showMessage(
          result['message']?.toString() ??
              'Cuenta creada. Revisa tu correo.',
        );

        await Future<void>.delayed(
          const Duration(milliseconds: 500),
        );

        if (!mounted) {
          return;
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute<void>(
            builder: (_) => ConfirmarCorreoScreen(
              email: email,
            ),
          ),
        );

        return;
      }

      setState(() {
        _generalError =
            result['message']?.toString() ??
                'No se pudo crear la cuenta.';
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
          _registering = false;
        });
      }
    }
  }

  String get _apiRole {
    return _selectedRole == 'Dueño'
        ? 'Duenio'
        : 'Paseador';
  }

  void _clearError(_RegisterField field) {
    if (!_errors.containsKey(field) &&
        _generalError == null) {
      return;
    }

    setState(() {
      _errors = Map.of(_errors)..remove(field);
      _generalError = null;
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  int get _passwordStrength {
    final value = _passwordController.text;

    if (value.isEmpty) {
      return 0;
    }

    var strength = 0;

    if (value.length >= 8) {
      strength++;
    }

    if (RegExp(r'[A-Z]').hasMatch(value) &&
        RegExp(r'[a-z]').hasMatch(value)) {
      strength++;
    }

    if (RegExp(r'\d').hasMatch(value)) {
      strength++;
    }

    if (RegExp(r'[^A-Za-z0-9]').hasMatch(value)) {
      strength++;
    }

    return strength;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DogGoTheme.cream,
      appBar: AppBar(
        toolbarHeight: 72,
        leading: IconButton(
          onPressed: _registering
              ? null
              : () => Navigator.maybePop(context),
          icon: const Icon(
            Icons.arrow_back_rounded,
          ),
        ),
        title: const DogGoLogo(size: 48),
      ),
      body: SafeArea(
        top: false,
        child: AutofillGroup(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              FocusManager.instance.primaryFocus?.unfocus();
            },
            child: SingleChildScrollView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                DogGoSpacing.screenHorizontal,
                DogGoSpacing.md,
                DogGoSpacing.screenHorizontal,
                DogGoSpacing.xl,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 470,
                  ),
                  child: _buildCard(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        DogGoSpacing.cardPadding,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: DogGoTheme.tealLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_add_alt_1_rounded,
                size: 35,
                color: DogGoTheme.teal,
              ),
            ),
          ),
          const SizedBox(height: DogGoSpacing.md),
          Center(
            child: Text(
              'ÚNETE A DOGGO',
              style: DogGoTheme.label(size: 10.5),
            ),
          ),
          const SizedBox(height: DogGoSpacing.sm),
          Center(
            child: Text(
              'Crear cuenta',
              style: DogGoTheme.display(size: 30),
            ),
          ),
          const SizedBox(height: DogGoSpacing.sm),
          Center(
            child: Text(
              'Regístrate como dueño o paseador para comenzar.',
              textAlign: TextAlign.center,
              style: DogGoTheme.subtitle(size: 13.5),
            ),
          ),
          const SizedBox(height: DogGoSpacing.lg),
          _RoleSelector(
            selectedRole: _selectedRole,
            enabled: !_registering,
            onChanged: (role) {
              setState(() {
                _selectedRole = role;
              });
            },
          ),
          const SizedBox(height: DogGoSpacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              final useColumns =
                  constraints.maxWidth >= 390;

              if (!useColumns) {
                return Column(
                  children: [
                    _nameField(),
                    const SizedBox(
                      height: DogGoSpacing.fieldGap,
                    ),
                    _lastNameField(),
                  ],
                );
              }

              return Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Expanded(child: _nameField()),
                  const SizedBox(
                    width: DogGoSpacing.fieldGap,
                  ),
                  Expanded(child: _lastNameField()),
                ],
              );
            },
          ),
          const SizedBox(height: DogGoSpacing.fieldGap),
          TextField(
            controller: _emailController,
            enabled: !_registering,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [
              AutofillHints.email,
            ],
            autocorrect: false,
            enableSuggestions: false,
            onChanged: (_) {
              _clearError(_RegisterField.email);
            },
            decoration: InputDecoration(
              labelText: 'Correo electrónico',
              hintText: 'correo@ejemplo.com',
              prefixIcon:
                  const Icon(Icons.email_outlined),
              errorText:
                  _errors[_RegisterField.email],
            ),
          ),
          const SizedBox(height: DogGoSpacing.fieldGap),
          TextField(
            controller: _phoneController,
            enabled: !_registering,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            autofillHints: const [
              AutofillHints.telephoneNumber,
            ],
            onChanged: (_) {
              _clearError(_RegisterField.phone);
            },
            decoration: InputDecoration(
              labelText: 'Teléfono',
              hintText: '10 dígitos',
              prefixIcon:
                  const Icon(Icons.phone_outlined),
              errorText:
                  _errors[_RegisterField.phone],
            ),
          ),
          const SizedBox(height: DogGoSpacing.fieldGap),
          TextField(
            controller: _passwordController,
            enabled: !_registering,
            obscureText: _hidePassword,
            textInputAction: TextInputAction.next,
            autofillHints: const [
              AutofillHints.newPassword,
            ],
            autocorrect: false,
            enableSuggestions: false,
            onChanged: (_) {
              _clearError(_RegisterField.password);
            },
            decoration: InputDecoration(
              labelText: 'Contraseña',
              prefixIcon: const Icon(
                Icons.lock_outline_rounded,
              ),
              errorText:
                  _errors[_RegisterField.password],
              suffixIcon: IconButton(
                onPressed: _registering
                    ? null
                    : () {
                        setState(() {
                          _hidePassword =
                              !_hidePassword;
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
          const SizedBox(height: DogGoSpacing.sm),
          _PasswordStrength(
            strength: _passwordStrength,
          ),
          const SizedBox(height: DogGoSpacing.fieldGap),
          TextField(
            controller: _confirmPasswordController,
            enabled: !_registering,
            obscureText: _hideConfirmation,
            textInputAction: TextInputAction.done,
            autofillHints: const [
              AutofillHints.newPassword,
            ],
            autocorrect: false,
            enableSuggestions: false,
            onChanged: (_) {
              _clearError(
                _RegisterField.confirmation,
              );
            },
            onSubmitted: (_) => _register(),
            decoration: InputDecoration(
              labelText: 'Confirmar contraseña',
              prefixIcon: const Icon(
                Icons.lock_reset_rounded,
              ),
              errorText:
                  _errors[_RegisterField.confirmation],
              suffixIcon: IconButton(
                onPressed: _registering
                    ? null
                    : () {
                        setState(() {
                          _hideConfirmation =
                              !_hideConfirmation;
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
          if (_generalError != null) ...[
            const SizedBox(height: DogGoSpacing.md),
            _RegisterError(message: _generalError!),
          ],
          const SizedBox(height: DogGoSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  _registering ? null : _register,
              child: _registering
                  ? const SizedBox(
                      width: 21,
                      height: 21,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.3,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Crear cuenta'),
            ),
          ),
          const SizedBox(height: DogGoSpacing.sm),
          Center(
            child: TextButton(
              onPressed: _registering
                  ? null
                  : () => Navigator.maybePop(context),
              child: const Text(
                'Ya tengo una cuenta',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _nameField() {
    return TextField(
      controller: _nameController,
      enabled: !_registering,
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.next,
      autofillHints: const [
        AutofillHints.givenName,
      ],
      onChanged: (_) {
        _clearError(_RegisterField.name);
      },
      decoration: InputDecoration(
        labelText: 'Nombre',
        prefixIcon:
            const Icon(Icons.person_outline_rounded),
        errorText: _errors[_RegisterField.name],
      ),
    );
  }

  Widget _lastNameField() {
    return TextField(
      controller: _lastNameController,
      enabled: !_registering,
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.next,
      autofillHints: const [
        AutofillHints.familyName,
      ],
      onChanged: (_) {
        _clearError(_RegisterField.lastName);
      },
      decoration: InputDecoration(
        labelText: 'Apellido',
        prefixIcon: const Icon(Icons.badge_outlined),
        errorText:
            _errors[_RegisterField.lastName],
      ),
    );
  }
}

enum _RegisterField {
  name,
  lastName,
  email,
  phone,
  password,
  confirmation,
}

class _RoleSelector extends StatelessWidget {
  final String selectedRole;
  final bool enabled;
  final ValueChanged<String> onChanged;

  const _RoleSelector({
    required this.selectedRole,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '¿Cómo usarás DogGo?',
          style: DogGoTheme.title(size: 17),
        ),
        const SizedBox(height: DogGoSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _RoleOption(
                icon: Icons.pets_outlined,
                title: 'Dueño',
                selected: selectedRole == 'Dueño',
                enabled: enabled,
                onTap: () => onChanged('Dueño'),
              ),
            ),
            const SizedBox(width: DogGoSpacing.sm),
            Expanded(
              child: _RoleOption(
                icon: Icons.directions_walk_rounded,
                title: 'Paseador',
                selected:
                    selectedRole == 'Paseador',
                enabled: enabled,
                onTap: () => onChanged('Paseador'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RoleOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _RoleOption({
    required this.icon,
    required this.title,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: title,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 15,
          ),
          decoration: BoxDecoration(
            color: selected
                ? DogGoTheme.tealLight
                : DogGoTheme.card,
            borderRadius: BorderRadius.circular(
              DogGoRadius.medium,
            ),
            border: Border.all(
              color: selected
                  ? DogGoTheme.teal
                  : DogGoTheme.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: selected
                    ? DogGoTheme.teal
                    : DogGoTheme.muted,
                size: 21,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  title,
                  style: DogGoTheme.body(
                    size: 12.5,
                    color: selected
                        ? DogGoTheme.teal
                        : DogGoTheme.ink,
                    weight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PasswordStrength extends StatelessWidget {
  final int strength;

  const _PasswordStrength({
    required this.strength,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (strength) {
      0 || 1 => DogGoTheme.red,
      2 => DogGoTheme.orange,
      3 => DogGoTheme.teal,
      _ => DogGoTheme.green,
    };

    final label = switch (strength) {
      0 => 'Escribe una contraseña',
      1 => 'Contraseña débil',
      2 => 'Contraseña aceptable',
      3 => 'Contraseña segura',
      _ => 'Contraseña muy segura',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (index) {
            return Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(
                  right: index == 3 ? 0 : 5,
                ),
                decoration: BoxDecoration(
                  color: index < strength
                      ? color
                      : DogGoTheme.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: DogGoTheme.caption(
            color: strength == 0
                ? DogGoTheme.muted
                : color,
            weight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _RegisterError extends StatelessWidget {
  final String message;

  const _RegisterError({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DogGoSpacing.md),
      decoration: BoxDecoration(
        color: DogGoTheme.redLight,
        borderRadius: BorderRadius.circular(
          DogGoRadius.medium,
        ),
        border: Border.all(
          color: DogGoTheme.red.withValues(alpha: .20),
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
    );
  }
}