import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'confirmar_correo_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _rolSeleccionado = 'Dueño';
  bool _ocultarPassword = true;
  bool _registrando = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _mostrarMensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
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
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
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
            onPressed: _registrando
                ? null
                : () {
                    Navigator.pop(context);
                  },
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
            child: const Column(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person_add_alt_1,
                    size: 34,
                    color: Color(0xFF14A89A),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Únete a DogGo',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF14A89A),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Crear cuenta',
                  style: TextStyle(
                    fontSize: 30,
                    color: Color(0xFF25324A),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Regístrate como dueño o paseador para comenzar.',
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
                  controller: _nombreController,
                  enabled: !_registrando,
                  textInputAction: TextInputAction.next,
                  decoration: _decoracionCampo(
                    label: 'Nombre',
                    icon: Icons.person_outline,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _apellidoController,
                  enabled: !_registrando,
                  textInputAction: TextInputAction.next,
                  decoration: _decoracionCampo(
                    label: 'Apellido',
                    icon: Icons.badge_outlined,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _emailController,
                  enabled: !_registrando,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: _decoracionCampo(
                    label: 'Correo electrónico',
                    icon: Icons.email_outlined,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _telefonoController,
                  enabled: !_registrando,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: _decoracionCampo(
                    label: 'Teléfono',
                    icon: Icons.phone_outlined,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _passwordController,
                  enabled: !_registrando,
                  obscureText: _ocultarPassword,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    filled: true,
                    fillColor: const Color(0xFFF8F4EC),
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
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F4EC),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _rolSeleccionado,
                      isExpanded: true,
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
                              if (value != null) {
                                setState(() {
                                  _rolSeleccionado = value;
                                });
                              }
                            },
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _registrando ? null : _registrarUsuario,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF14A89A),
                      disabledBackgroundColor:
                          const Color(0xFF14A89A).withOpacity(0.45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                      elevation: 0,
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
    );
  }
}