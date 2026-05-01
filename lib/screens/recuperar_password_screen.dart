import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class RecuperarPasswordScreen extends StatefulWidget {
  const RecuperarPasswordScreen({super.key});

  @override
  State<RecuperarPasswordScreen> createState() =>
      _RecuperarPasswordScreenState();
}

class _RecuperarPasswordScreenState extends State<RecuperarPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codigoController = TextEditingController();
  final TextEditingController _nuevaPasswordController =
      TextEditingController();
  final TextEditingController _confirmarPasswordController =
      TextEditingController();

  bool _enviandoCodigo = false;
  bool _cambiandoPassword = false;
  bool _codigoEnviado = false;
  bool _ocultarNuevaPassword = true;
  bool _ocultarConfirmarPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _codigoController.dispose();
    _nuevaPasswordController.dispose();
    _confirmarPasswordController.dispose();
    super.dispose();
  }

  void _mostrarMensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
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
          result['message']?.toString() ??
              'Código enviado. Revisa tu correo.',
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
    required String label,
    required IconData icon,
    String? hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF8F4EC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bloqueado = _enviandoCodigo || _cambiandoPassword;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6EF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Row(
          children: [
            Icon(Icons.pets, color: Color(0xFF14A89A)),
            SizedBox(width: 8),
            Text(
              'Recuperar contraseña',
              style: TextStyle(
                color: Color(0xFF25324A),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF4EDE3),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: const Color(0xFFE7E0D5)),
            ),
            child: const Column(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.lock_reset_rounded,
                    size: 36,
                    color: Color(0xFF14A89A),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'DOGGO',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF14A89A),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Recuperar acceso',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 29,
                    color: Color(0xFF25324A),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Escribe tu correo, recibe un código y crea una nueva contraseña.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.94),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE7E2D9)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                TextField(
                  controller: _emailController,
                  enabled: !bloqueado,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: _decoracionCampo(
                    label: 'Correo electrónico',
                    icon: Icons.email_outlined,
                    hint: 'correo@ejemplo.com',
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 48,
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
                      foregroundColor: const Color(0xFF14A89A),
                      side: const BorderSide(
                        color: Color(0xFF14A89A),
                        width: 1.3,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: EdgeInsets.only(top: _codigoEnviado ? 4 : 0),
                  child: Column(
                    children: [
                      if (_codigoEnviado) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            'Código enviado. Revisa tu correo y escribe el código aquí abajo.',
                            style: TextStyle(
                              color: Colors.grey.shade800,
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      TextField(
                        controller: _codigoController,
                        enabled: !bloqueado,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        decoration: _decoracionCampo(
                          label: 'Código',
                          icon: Icons.password_rounded,
                          hint: 'Ej. 123456',
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _nuevaPasswordController,
                        enabled: !bloqueado,
                        obscureText: _ocultarNuevaPassword,
                        textInputAction: TextInputAction.next,
                        decoration: _decoracionCampo(
                          label: 'Nueva contraseña',
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
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _confirmarPasswordController,
                        enabled: !bloqueado,
                        obscureText: _ocultarConfirmarPassword,
                        textInputAction: TextInputAction.done,
                        decoration: _decoracionCampo(
                          label: 'Confirmar contraseña',
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
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: bloqueado ? null : _cambiarPassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF14A89A),
                            disabledBackgroundColor:
                                const Color(0xFF14A89A).withOpacity(0.45),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26),
                            ),
                            elevation: 0,
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
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                        ),
                      ),
                    ],
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