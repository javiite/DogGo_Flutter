import 'dart:ui';

import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../widgets/doggo_logo.dart';
import 'confirmar_correo_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  String _rolSeleccionado = 'Dueño';
  bool _ocultarPassword = true;
  bool _registrando = false;

  static const Color _teal = Color(0xFF0DBB9A);
  static const Color _tealDark = Color(0xFF078D78);
  static const Color _ink = Color(0xFF25283F);
  static const Color _muted = Color(0xFF6B7280);
  static const Color _cream = Color(0xFFF7F2EA);
  static const Color _input = Color(0xFFF4EFE7);
  static const Color _border = Color(0xFFE8DED2);

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, .05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nombreController.dispose();
    _apellidoController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _mostrarMensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _rolApi() {
    if (_rolSeleccionado == 'Dueño') {
      return 'Duenio';
    }

    return 'Paseador';
  }

  bool _validarFormulario() {
    final nombre = _nombreController.text.trim();
    final apellido = _apellidoController.text.trim();
    final email = _emailController.text.trim();
    final telefono = _telefonoController.text.trim();
    final password = _passwordController.text;

    if (nombre.isEmpty) {
      _mostrarMensaje('Escribe tu nombre.');
      return false;
    }

    if (apellido.isEmpty) {
      _mostrarMensaje('Escribe tu apellido.');
      return false;
    }

    if (email.isEmpty || !email.contains('@')) {
      _mostrarMensaje('Escribe un correo válido.');
      return false;
    }

    if (telefono.isEmpty) {
      _mostrarMensaje('Escribe tu teléfono.');
      return false;
    }

    if (password.length < 6) {
      _mostrarMensaje('La contraseña debe tener al menos 6 caracteres.');
      return false;
    }

    return true;
  }

  Future<void> _registrarUsuario() async {
    if (_registrando) return;
    if (!_validarFormulario()) return;

    setState(() {
      _registrando = true;
    });

    final email = _emailController.text.trim();

    try {
      final result = await AuthService.registrar(
        nombre: _nombreController.text.trim(),
        apellido: _apellidoController.text.trim(),
        email: email,
        password: _passwordController.text,
        telefono: _telefonoController.text.trim(),
        rol: _rolApi(),
      );

      if (!mounted) return;

      if (result['success'] == true) {
        _mostrarMensaje(
          result['message']?.toString() ??
              'Usuario registrado correctamente. Revisa tu correo.',
        );

        await Future.delayed(const Duration(milliseconds: 650));

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ConfirmarCorreoScreen(
              email: email,
            ),
          ),
        );
      } else {
        _mostrarMensaje(
          result['message']?.toString() ?? 'No se pudo registrar el usuario.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      _mostrarMensaje('Error de conexión: $e');
    } finally {
      if (mounted) {
        setState(() {
          _registrando = false;
        });
      }
    }
  }

  InputDecoration _decoracionCampo({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(
        icon,
        color: _muted,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: _input,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 17,
      ),
      hintStyle: const TextStyle(
        color: _muted,
        fontWeight: FontWeight.w500,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: BorderSide(
          color: _border.withOpacity(.70),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(
          color: _teal,
          width: 1.4,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      body: Stack(
        children: [
          const _AuthBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(22, 18, 22, 26),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Center(
                          child: _buildRegisterCard(),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 4),
      child: Row(
        children: [
          const DogGoLogo(size: 42),
          const SizedBox(width: 10),
          const Text(
            'DogGo',
            style: TextStyle(
              color: _ink,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -.4,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: _registrando ? null : () => Navigator.maybePop(context),
            child: const Text(
              'Volver',
              style: TextStyle(
                color: _ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 450),
          padding: const EdgeInsets.fromLTRB(22, 25, 22, 22),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.86),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.white.withOpacity(.72),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.09),
                blurRadius: 34,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.95),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _teal.withOpacity(.16),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person_add_alt_1_rounded,
                  size: 40,
                  color: _teal,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Únete a DogGo',
                style: TextStyle(
                  fontSize: 12,
                  color: _tealDark,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .7,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Crear cuenta',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 31,
                  color: _ink,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.8,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Regístrate como dueño o paseador para comenzar.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _muted,
                  fontSize: 14.5,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nombreController,
                      enabled: !_registrando,
                      textInputAction: TextInputAction.next,
                      decoration: _decoracionCampo(
                        hint: 'Nombre',
                        icon: Icons.person_outline_rounded,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _apellidoController,
                      enabled: !_registrando,
                      textInputAction: TextInputAction.next,
                      decoration: _decoracionCampo(
                        hint: 'Apellido',
                        icon: Icons.badge_outlined,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              TextField(
                controller: _emailController,
                enabled: !_registrando,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: _decoracionCampo(
                  hint: 'Correo electrónico',
                  icon: Icons.email_outlined,
                ),
              ),
              const SizedBox(height: 13),
              TextField(
                controller: _telefonoController,
                enabled: !_registrando,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                decoration: _decoracionCampo(
                  hint: 'Teléfono',
                  icon: Icons.phone_outlined,
                ),
              ),
              const SizedBox(height: 13),
              TextField(
                controller: _passwordController,
                enabled: !_registrando,
                obscureText: _ocultarPassword,
                textInputAction: TextInputAction.done,
                decoration: _decoracionCampo(
                  hint: 'Contraseña',
                  icon: Icons.lock_outline_rounded,
                  suffixIcon: IconButton(
                    onPressed: _registrando
                        ? null
                        : () {
                            setState(() {
                              _ocultarPassword = !_ocultarPassword;
                            });
                          },
                    icon: Icon(
                      _ocultarPassword
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: _muted,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 13),
              DropdownButtonFormField<String>(
                value: _rolSeleccionado,
                decoration: _decoracionCampo(
                  hint: 'Me registro como',
                  icon: Icons.assignment_ind_outlined,
                ),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(18),
                items: const [
                  DropdownMenuItem(
                    value: 'Dueño',
                    child: Text('Dueño'),
                  ),
                  DropdownMenuItem(
                    value: 'Paseador',
                    child: Text('Paseador'),
                  ),
                ],
                onChanged: _registrando
                    ? null
                    : (value) {
                        if (value == null) return;
                        setState(() {
                          _rolSeleccionado = value;
                        });
                      },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _registrando ? null : _registrarUsuario,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _teal,
                    disabledBackgroundColor: _teal.withOpacity(.45),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: _registrando
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.3,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Crear cuenta',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 13),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.72),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: _border.withOpacity(.80),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '¿Ya tienes cuenta?',
                      style: TextStyle(
                        color: _muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextButton(
                      onPressed: _registrando
                          ? null
                          : () => Navigator.maybePop(context),
                      child: const Text(
                        'Inicia sesión',
                        style: TextStyle(
                          color: _tealDark,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthBackground extends StatelessWidget {
  const _AuthBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFEAF8F3),
                  Color(0xFFF8F1E7),
                  Color(0xFFDDEFD8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        Positioned(
          top: -80,
          right: -70,
          child: _BlurCircle(
            size: 220,
            color: Color(0xFF0DBB9A),
            opacity: .23,
          ),
        ),
        Positioned(
          bottom: -110,
          left: -80,
          child: _BlurCircle(
            size: 260,
            color: Color(0xFFFFB84D),
            opacity: .20,
          ),
        ),
        Positioned(
          bottom: 120,
          right: -85,
          child: _BlurCircle(
            size: 210,
            color: Color(0xFF7C5CBF),
            opacity: .12,
          ),
        ),
      ],
    );
  }
}

class _BlurCircle extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  const _BlurCircle({
    required this.size,
    required this.color,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 42, sigmaY: 42),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withOpacity(opacity),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}