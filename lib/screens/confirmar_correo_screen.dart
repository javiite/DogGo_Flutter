import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class ConfirmarCorreoScreen extends StatefulWidget {
  final String? email;

  const ConfirmarCorreoScreen({
    super.key,
    this.email,
  });

  @override
  State<ConfirmarCorreoScreen> createState() => _ConfirmarCorreoScreenState();
}

class _ConfirmarCorreoScreenState extends State<ConfirmarCorreoScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codigoController = TextEditingController();

  bool _confirmando = false;

  @override
  void initState() {
    super.initState();

    if (widget.email != null && widget.email!.trim().isNotEmpty) {
      _emailController.text = widget.email!.trim();
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codigoController.dispose();
    super.dispose();
  }

  void _mostrarMensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }

  bool _validar() {
    final email = _emailController.text.trim();
    final codigo = _codigoController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      _mostrarMensaje('Escribe un correo válido.');
      return false;
    }

    if (codigo.isEmpty) {
      _mostrarMensaje('Escribe el código de confirmación.');
      return false;
    }

    if (codigo.length < 4) {
      _mostrarMensaje('El código no parece válido.');
      return false;
    }

    return true;
  }

  Future<void> _confirmarCorreo() async {
    if (_confirmando) return;
    if (!_validar()) return;

    setState(() {
      _confirmando = true;
    });

    try {
      final result = await AuthService.confirmarCorreo(
        email: _emailController.text.trim(),
        codigo: _codigoController.text.trim(),
      );

      if (!mounted) return;

      if (result['success'] == true) {
        _mostrarMensaje(
          result['message']?.toString() ?? 'Correo confirmado correctamente.',
        );

        await Future.delayed(const Duration(milliseconds: 700));

        if (!mounted) return;

        Navigator.pop(context, true);
      } else {
        _mostrarMensaje(
          result['message']?.toString() ?? 'No se pudo confirmar el correo.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      _mostrarMensaje('Error de conexión: $e');
    } finally {
      if (mounted) {
        setState(() {
          _confirmando = false;
        });
      }
    }
  }

  InputDecoration _decoracionCampo({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
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
              'Confirmar correo',
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
                    Icons.mark_email_read_rounded,
                    size: 34,
                    color: Color(0xFF14A89A),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Verifica tu cuenta',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF14A89A),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Confirma tu correo',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 29,
                    color: Color(0xFF25324A),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Escribe el código que enviamos a tu correo electrónico.',
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
                  enabled: !_confirmando,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _decoracionCampo(
                    label: 'Correo electrónico',
                    icon: Icons.email_outlined,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _codigoController,
                  enabled: !_confirmando,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  decoration: _decoracionCampo(
                    label: 'Código de confirmación',
                    icon: Icons.password_rounded,
                    hint: 'Ej. 123456',
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _confirmando ? null : _confirmarCorreo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF14A89A),
                      disabledBackgroundColor:
                          const Color(0xFF14A89A).withOpacity(0.45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                      elevation: 0,
                    ),
                    child: _confirmando
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.3,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Confirmar correo',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _confirmando
                      ? null
                      : () {
                          Navigator.pop(context);
                        },
                  child: const Text(
                    'Volver al login',
                    style: TextStyle(
                      color: Color(0xFF25324A),
                      fontWeight: FontWeight.w700,
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
}