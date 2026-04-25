import 'package:flutter/material.dart';
import 'login_screen.dart';

class ConfirmarCorreoScreen extends StatefulWidget {
  const ConfirmarCorreoScreen({super.key});

  @override
  State<ConfirmarCorreoScreen> createState() => _ConfirmarCorreoScreenState();
}

class _ConfirmarCorreoScreenState extends State<ConfirmarCorreoScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codigoController = TextEditingController();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6EF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: const [
            Icon(Icons.pets, color: Color(0xFF14A89A)),
            SizedBox(width: 8),
            Text(
              'DogGo',
              style: TextStyle(
                color: Color(0xFF25324A),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Volver',
              style: TextStyle(color: Color(0xFF25324A)),
            ),
          ),
          const SizedBox(width: 8),
        ],
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
            child: Column(
              children: const [
                CircleAvatar(
                  radius: 38,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.mark_email_read_outlined,
                    size: 36,
                    color: Color(0xFF14A89A),
                  ),
                ),
                SizedBox(height: 14),
                Text(
                  'Confirmar correo',
                  style: TextStyle(
                    fontSize: 30,
                    color: Color(0xFF25324A),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Ingresa tu correo y el código que recibiste para activar tu cuenta.',
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
                const SizedBox(height: 14),
                TextField(
                  controller: _codigoController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Código de confirmación',
                    prefixIcon: const Icon(Icons.verified_outlined),
                    filled: true,
                    fillColor: const Color(0xFFF8F4EC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      _mostrarMensaje('Confirmación visual por ahora');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF14A89A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Confirmar correo',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () {
                    _mostrarMensaje('Reenviar código después');
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF14A89A)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    'Reenviar código',
                    style: TextStyle(
                      color: Color(0xFF14A89A),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const LoginScreen(),
                ),
              );
            },
            child: const Text(
              'Ir al login',
              style: TextStyle(
                color: Color(0xFF6B7280),
              ),
            ),
          ),
        ],
      ),
    );
  }
}