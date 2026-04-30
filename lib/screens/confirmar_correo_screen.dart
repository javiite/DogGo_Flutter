import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class ConfirmarCorreoScreen extends StatefulWidget {
  const ConfirmarCorreoScreen({super.key});

  @override
  State<ConfirmarCorreoScreen> createState() => _ConfirmarCorreoScreenState();
}

class _ConfirmarCorreoScreenState extends State<ConfirmarCorreoScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codigoController = TextEditingController();

  bool _cargando = false;

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

  Future<void> _confirmarCorreo() async {
    final email = _emailController.text.trim();
    final codigo = _codigoController.text.trim();

    if (email.isEmpty || codigo.isEmpty) {
      _mostrarMensaje('Completa correo y código');
      return;
    }

    setState(() {
      _cargando = true;
    });

    try {
      final result = await AuthService.confirmarCorreo(
        email: email,
        codigo: codigo,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        _mostrarMensaje(result['message']);

        await Future.delayed(const Duration(milliseconds: 800));

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const LoginScreen(),
          ),
        );
      } else {
        _mostrarMensaje(result['message']);
      }
    } catch (e) {
      _mostrarMensaje('Error de conexión: $e');
    } finally {
      if (mounted) {
        setState(() {
          _cargando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6EF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text('Confirmar correo'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF4EDE3),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE7E0D5)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📩 ACTIVAR CUENTA',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF14A89A),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Confirmar correo',
                  style: TextStyle(
                    fontSize: 28,
                    color: Color(0xFF25324A),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Escribe tu correo y el código de confirmación.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.94),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE7E2D9)),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Correo electrónico',
                    prefixIcon: const Icon(Icons.email_outlined),
                    filled: true,
                    fillColor: const Color(0xFFF8F4EC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _codigoController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Código',
                    prefixIcon: const Icon(Icons.verified_outlined),
                    filled: true,
                    fillColor: const Color(0xFFF8F4EC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _cargando ? null : _confirmarCorreo,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF14A89A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
              ),
              child: _cargando
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.4,
                      ),
                    )
                  : const Text(
                      'Confirmar',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}