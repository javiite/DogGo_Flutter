import 'package:flutter/material.dart';
import '../services/perfil_service.dart';
import '../services/storage_service.dart';
import 'login_screen.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  bool _cargando = true;
  String? _error;

  String _nombre = '';
  String _apellido = '';
  String _email = '';
  String _telefono = '';
  String _rol = '';

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final result = await PerfilService.obtenerPerfil();

      if (!mounted) return;

      if (result['success'] == true) {
        final data = result['data'];

        setState(() {
          _nombre = data['nombre'] ?? '';
          _apellido = data['apellido'] ?? '';
          _email = data['email'] ?? '';
          _telefono = data['telefono'] ?? '';
          _rol = data['rol'] ?? '';
          _cargando = false;
        });
      } else {
        setState(() {
          _error = result['message'];
          _cargando = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Error de conexión: $e';
        _cargando = false;
      });
    }
  }

  Future<void> _cerrarSesion() async {
    await StorageService.limpiarToken();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
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
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 70,
                          color: Colors.redAccent,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _cargarPerfil,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
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
                        children: [
                          const CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.person,
                              size: 42,
                              color: Color(0xFF14A89A),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            '${_nombre.trim()} ${_apellido.trim()}'.trim(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 28,
                              color: Color(0xFF25324A),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _rol,
                            style: const TextStyle(
                              color: Color(0xFF14A89A),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _PerfilCard(
                      child: Column(
                        children: [
                          _DatoPerfil(
                            icon: Icons.person_outline,
                            titulo: 'Nombre',
                            valor: _nombre,
                          ),
                          const Divider(),
                          _DatoPerfil(
                            icon: Icons.badge_outlined,
                            titulo: 'Apellido',
                            valor: _apellido,
                          ),
                          const Divider(),
                          _DatoPerfil(
                            icon: Icons.email_outlined,
                            titulo: 'Correo',
                            valor: _email,
                          ),
                          const Divider(),
                          _DatoPerfil(
                            icon: Icons.phone_outlined,
                            titulo: 'Teléfono',
                            valor: _telefono.isEmpty ? 'No registrado' : _telefono,
                          ),
                          const Divider(),
                          _DatoPerfil(
                            icon: Icons.verified_user_outlined,
                            titulo: 'Rol',
                            valor: _rol,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _PerfilCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Acciones',
                            style: TextStyle(
                              fontSize: 18,
                              color: Color(0xFF25324A),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _BotonPerfil(
                            texto: 'Recargar perfil',
                            icono: Icons.refresh,
                            onTap: _cargarPerfil,
                          ),
                          const SizedBox(height: 10),
                          _BotonPerfil(
                            texto: 'Editar perfil',
                            icono: Icons.edit_outlined,
                            onTap: () {
                              _mostrarMensaje('Editar perfil después');
                            },
                          ),
                          const SizedBox(height: 10),
                          _BotonPerfil(
                            texto: 'Cerrar sesión',
                            icono: Icons.logout,
                            rojo: true,
                            onTap: _cerrarSesion,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _PerfilCard extends StatelessWidget {
  final Widget child;

  const _PerfilCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: child,
    );
  }
}

class _DatoPerfil extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final String valor;

  const _DatoPerfil({
    required this.icon,
    required this.titulo,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF14A89A)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                valor,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF25324A),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BotonPerfil extends StatelessWidget {
  final String texto;
  final IconData icono;
  final VoidCallback onTap;
  final bool rojo;

  const _BotonPerfil({
    required this.texto,
    required this.icono,
    required this.onTap,
    this.rojo = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = rojo ? const Color(0xFFE56B6F) : const Color(0xFF14A89A);

    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icono, color: color),
        label: Text(
          texto,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}