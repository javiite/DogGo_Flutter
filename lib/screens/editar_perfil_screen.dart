import 'package:flutter/material.dart';
import '../services/usuario_service.dart';

class EditarPerfilScreen extends StatefulWidget {
  const EditarPerfilScreen({super.key});

  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidoController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();

  bool _cargando = true;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  void _mostrarMensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }

  Future<void> _cargarPerfil() async {
    setState(() {
      _cargando = true;
    });

    try {
      final result = await UsuarioService.obtenerPerfil();

      if (!mounted) return;

      if (result['success'] == true) {
        final data = result['data'];

        _nombreController.text = data['nombre']?.toString() ?? '';
        _apellidoController.text = data['apellido']?.toString() ?? '';
        _telefonoController.text = data['telefono']?.toString() ?? '';
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

  Future<void> _guardarCambios() async {
    final nombre = _nombreController.text.trim();
    final apellido = _apellidoController.text.trim();
    final telefono = _telefonoController.text.trim();

    if (nombre.isEmpty || apellido.isEmpty) {
      _mostrarMensaje('Nombre y apellido son obligatorios');
      return;
    }

    setState(() {
      _guardando = true;
    });

    try {
      final result = await UsuarioService.actualizarPerfil(
        nombre: nombre,
        apellido: apellido,
        telefono: telefono,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        _mostrarMensaje(result['message']);
        await Future.delayed(const Duration(milliseconds: 700));
        if (!mounted) return;
        Navigator.pop(context, true);
      } else {
        _mostrarMensaje(result['message']);
      }
    } catch (e) {
      _mostrarMensaje('Error de conexión: $e');
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
      backgroundColor: const Color(0xFFF8F6EF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text('Editar perfil'),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : ListView(
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
                        '📝 ACTUALIZA TUS DATOS',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF14A89A),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Editar perfil',
                        style: TextStyle(
                          fontSize: 28,
                          color: Color(0xFF25324A),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _EditCard(
                  titulo: 'Información personal',
                  child: Column(
                    children: [
                      _CampoEditar(
                        controller: _nombreController,
                        label: 'Nombre',
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 12),
                      _CampoEditar(
                        controller: _apellidoController,
                        label: 'Apellido',
                        icon: Icons.badge_outlined,
                      ),
                      const SizedBox(height: 12),
                      _CampoEditar(
                        controller: _telefonoController,
                        label: 'Teléfono',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _guardando ? null : _guardarCambios,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF14A89A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 0,
                    ),
                    child: _guardando
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.4,
                            ),
                          )
                        : const Text(
                            'Guardar cambios',
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

class _EditCard extends StatelessWidget {
  final String titulo;
  final Widget child;

  const _EditCard({
    required this.titulo,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE7E2D9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 18,
              color: Color(0xFF25324A),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _CampoEditar extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;

  const _CampoEditar({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: const Color(0xFFF8F4EC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}