import 'dart:ui';

import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../widgets/doggo_logo.dart';

class RecuperarPasswordScreen extends StatefulWidget {
  const RecuperarPasswordScreen({super.key});

  @override
  State<RecuperarPasswordScreen> createState() =>
      _RecuperarPasswordScreenState();
}

class _RecuperarPasswordScreenState extends State<RecuperarPasswordScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codigoController = TextEditingController();
  final TextEditingController _nuevaPasswordController =
      TextEditingController();
  final TextEditingController _confirmarPasswordController =
      TextEditingController();

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  bool _enviandoCodigo = false;
  bool _cambiandoPassword = false;
  bool _codigoEnviado = false;
  bool _ocultarNuevaPassword = true;
  bool _ocultarConfirmarPassword = true;

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
    _emailController.dispose();
    _codigoController.dispose();
    _nuevaPasswordController.dispose();
    _confirmarPasswordController.dispose();
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

  bool _validarEmail() {
    final email = _emailController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      _mostrarMensaje('Escribe un correo válido.');
      return false;
    }

    return true;
  }

  bool _validarCambioPassword() {
    final email = _emailController.text.trim();
    final codigo = _codigoController.text.trim();
    final nuevaPassword = _nuevaPasswordController.text;
    final confirmarPassword = _confirmarPasswordController.text;

    if (email.isEmpty || !email.contains('@')) {
      _mostrarMensaje('Escribe un correo válido.');
      return false;
    }

    if (codigo.isEmpty) {
      _mostrarMensaje('Escribe el código de recuperación.');
      return false;
    }

    if (codigo.length < 4) {
      _mostrarMensaje('El código no parece válido.');
      return false;
    }

    if (nuevaPassword.length < 6) {
      _mostrarMensaje('La nueva contraseña debe tener al menos 6 caracteres.');
      return false;
    }

    if (nuevaPassword != confirmarPassword) {
      _mostrarMensaje('Las contraseñas no coinciden.');
      return false;
    }

    return true;
  }

  Future<void> _solicitarCodigo() async {
    if (_enviandoCodigo) return;
    if (!_validarEmail()) return;

    setState(() {
      _enviandoCodigo = true;
    });

    try {
      final result = await AuthService.solicitarRecuperacion(
        email: _emailController.text.trim(),
      );

      if (!mounted) return;

      if (result['success'] == true) {
        setState(() {
          _codigoEnviado = true;
        });

        _mostrarMensaje(
          result['message']?.toString() ?? 'Código enviado. Revisa tu correo.',
        );
      } else {
        _mostrarMensaje(
          result['message']?.toString() ??
              'No se pudo enviar el código de recuperación.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      _mostrarMensaje('Error de conexión: $e');
    } finally {
      if (mounted) {
        setState(() {
          _enviandoCodigo = false;
        });
      }
    }
  }

  Future<void> _cambiarPassword() async {
    if (_cambiandoPassword) return;
    if (!_validarCambioPassword()) return;

    setState(() {
      _cambiandoPassword = true;
    });

    try {
      final result = await AuthService.recuperarPassword(
        email: _emailController.text.trim(),
        codigo: _codigoController.text.trim(),
        nuevaPassword: _nuevaPasswordController.text,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        _mostrarMensaje(
          result['message']?.toString() ??
              'Contraseña actualizada correctamente.',
        );

        await Future.delayed(const Duration(milliseconds: 700));

        if (!mounted) return;

        Navigator.pop(context, true);
      } else {
        _mostrarMensaje(
          result['message']?.toString() ??
              'No se pudo actualizar la contraseña.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      _mostrarMensaje('Error de conexión: $e');
    } finally {
      if (mounted) {
        setState(() {
          _cambiandoPassword = false;
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
    final bloqueado = _enviandoCodigo || _cambiandoPassword;

    return Scaffold(
      backgroundColor: _cream,
      body: Stack(
        children: [
          const _AuthBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(bloqueado),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(22, 18, 22, 26),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Center(
                          child: _buildRecoveryCard(bloqueado),
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

  Widget _buildTopBar(bool bloqueado) {
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
            onPressed: bloqueado ? null : () => Navigator.maybePop(context),
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

  Widget _buildRecoveryCard(bool bloqueado) {
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
                  Icons.lock_reset_rounded,
                  size: 42,
                  color: _teal,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Recuperación DogGo',
                style: TextStyle(
                  fontSize: 12,
                  color: _tealDark,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .7,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Recuperar acceso',
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
                'Escribe tu correo, recibe un código y crea una nueva contraseña.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _muted,
                  fontSize: 14.5,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _emailController,
                enabled: !bloqueado,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: _decoracionCampo(
                  hint: 'Correo electrónico',
                  icon: Icons.email_outlined,
                ),
              ),
              const SizedBox(height: 13),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: bloqueado ? null : _solicitarCodigo,
                  icon: _enviandoCodigo
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.mark_email_read_rounded),
                  label: Text(
                    _codigoEnviado
                        ? 'Reenviar código'
                        : 'Enviar código de recuperación',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _tealDark,
                    side: const BorderSide(
                      color: _teal,
                      width: 1.3,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: _codigoEnviado
                    ? Column(
                        key: const ValueKey('codigo-enviado'),
                        children: [
                          const SizedBox(height: 17),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(13),
                            decoration: BoxDecoration(
                              color: _teal.withOpacity(.08),
                              borderRadius: BorderRadius.circular(17),
                              border: Border.all(
                                color: _teal.withOpacity(.18),
                              ),
                            ),
                            child: const Text(
                              'Código enviado. Revisa tu correo y escríbelo aquí abajo.',
                              style: TextStyle(
                                color: _ink,
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                                height: 1.3,
                              ),
                            ),
                          ),
                          const SizedBox(height: 13),
                          TextField(
                            controller: _codigoController,
                            enabled: !bloqueado,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            decoration: _decoracionCampo(
                              hint: 'Código de recuperación',
                              icon: Icons.password_rounded,
                            ),
                          ),
                          const SizedBox(height: 13),
                          TextField(
                            controller: _nuevaPasswordController,
                            enabled: !bloqueado,
                            obscureText: _ocultarNuevaPassword,
                            textInputAction: TextInputAction.next,
                            decoration: _decoracionCampo(
                              hint: 'Nueva contraseña',
                              icon: Icons.lock_outline_rounded,
                              suffixIcon: IconButton(
                                onPressed: bloqueado
                                    ? null
                                    : () {
                                        setState(() {
                                          _ocultarNuevaPassword =
                                              !_ocultarNuevaPassword;
                                        });
                                      },
                                icon: Icon(
                                  _ocultarNuevaPassword
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                  color: _muted,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 13),
                          TextField(
                            controller: _confirmarPasswordController,
                            enabled: !bloqueado,
                            obscureText: _ocultarConfirmarPassword,
                            textInputAction: TextInputAction.done,
                            decoration: _decoracionCampo(
                              hint: 'Confirmar contraseña',
                              icon: Icons.lock_reset_rounded,
                              suffixIcon: IconButton(
                                onPressed: bloqueado
                                    ? null
                                    : () {
                                        setState(() {
                                          _ocultarConfirmarPassword =
                                              !_ocultarConfirmarPassword;
                                        });
                                      },
                                icon: Icon(
                                  _ocultarConfirmarPassword
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                  color: _muted,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 19),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: bloqueado ? null : _cambiarPassword,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _teal,
                                disabledBackgroundColor:
                                    _teal.withOpacity(.45),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                              ),
                              child: _cambiandoPassword
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.3,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Cambiar contraseña',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 15,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
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