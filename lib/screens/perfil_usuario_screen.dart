import 'package:flutter/material.dart';

import '../services/storage_service.dart';
import '../services/usuario_service.dart';
import 'editar_perfil_screen.dart';
import 'cambiar_password_screen.dart';

class PerfilUsuarioScreen extends StatefulWidget {
  const PerfilUsuarioScreen({super.key});

  @override
  State<PerfilUsuarioScreen> createState() => _PerfilUsuarioScreenState();
}

class _PerfilUsuarioScreenState extends State<PerfilUsuarioScreen> {
  final UsuarioService _usuarioService = UsuarioService();

  Map<String, dynamic>? _perfil;
  bool _cargando = true;
  String? _error;

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
      final perfil = await _usuarioService.obtenerPerfil();

      if (!mounted) return;

      setState(() {
        _perfil = perfil;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _cargando = false;
      });
    }
  }

  Future<void> _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cerrar sesión'),
          content: const Text(
            '¿Seguro que quieres cerrar sesión? La URL del servidor se conservará.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Cerrar sesión'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    await StorageService.limpiarSesion();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sesión cerrada correctamente.'),
      ),
    );

    try {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
    } catch (_) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  String _texto(dynamic valor, {String fallback = 'No disponible'}) {
    if (valor == null) return fallback;
    final texto = valor.toString().trim();
    if (texto.isEmpty || texto.toLowerCase() == 'null') return fallback;
    return texto;
  }

  String get _nombre {
    return _texto(
      _perfil?['nombre'] ?? _perfil?['Nombre'],
      fallback: '',
    );
  }

  String get _apellido {
    return _texto(
      _perfil?['apellido'] ?? _perfil?['Apellido'],
      fallback: '',
    );
  }

  String get _nombreCompleto {
    final completo = '$_nombre $_apellido'.trim();
    return completo.isEmpty ? 'Usuario' : completo;
  }

  String get _email {
    return _texto(
      _perfil?['email'] ?? _perfil?['Email'],
      fallback: 'Correo no disponible',
    );
  }

  String get _telefono {
    return _texto(
      _perfil?['telefono'] ?? _perfil?['Telefono'],
      fallback: 'Teléfono no disponible',
    );
  }

  String get _rol {
    return _texto(
      _perfil?['rol'] ?? _perfil?['Rol'],
      fallback: 'Rol no disponible',
    );
  }

  bool get _emailConfirmado {
    final valor = _perfil?['emailConfirmado'] ?? _perfil?['EmailConfirmado'];
    if (valor is bool) return valor;
    return valor?.toString().toLowerCase() == 'true';
  }

  Color get _colorRol {
    final rol = _rol.toLowerCase();

    if (rol.contains('paseador')) {
      return Colors.green;
    }

    if (rol.contains('duenio') || rol.contains('dueño')) {
      return Colors.blue;
    }

    return Colors.grey;
  }

  Future<void> _abrirEditarPerfil() async {
    if (_perfil == null) return;

    final actualizado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditarPerfilScreen(
          perfil: _perfil!,
        ),
      ),
    );

    if (actualizado == true) {
      await _cargarPerfil();
    }
  }

  Future<void> _abrirCambiarPassword() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CambiarPasswordScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('Mi perfil'),
        backgroundColor: const Color(0xFF1F8A70),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _cargarPerfil,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 16),
                      _buildDatosPersonales(),
                      const SizedBox(height: 16),
                      _buildCuentaCard(),
                      const SizedBox(height: 16),
                      _buildAcciones(),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 62,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 14),
            const Text(
              'No se pudo cargar tu perfil.',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _cargarPerfil,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F8A70),
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _cerrarSesion,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Cerrar sesión'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1F8A70),
            Color(0xFF35A98A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.40),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 48,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _nombreCompleto,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _email,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeaderChip(
                texto: _rol,
                icono: Icons.badge_rounded,
              ),
              _HeaderChip(
                texto:
                    _emailConfirmado ? 'Correo confirmado' : 'Correo pendiente',
                icono: _emailConfirmado
                    ? Icons.verified_rounded
                    : Icons.mark_email_unread_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDatosPersonales() {
    return _SeccionCard(
      titulo: 'Datos personales',
      icono: Icons.account_circle_rounded,
      children: [
        _InfoTile(
          icono: Icons.person_rounded,
          titulo: 'Nombre',
          valor: _nombreCompleto,
        ),
        _InfoTile(
          icono: Icons.phone_rounded,
          titulo: 'Teléfono',
          valor: _telefono,
        ),
        _InfoTile(
          icono: Icons.email_rounded,
          titulo: 'Correo',
          valor: _email,
        ),
      ],
    );
  }

  Widget _buildCuentaCard() {
    return _SeccionCard(
      titulo: 'Cuenta',
      icono: Icons.security_rounded,
      children: [
        _InfoTile(
          icono: Icons.badge_rounded,
          titulo: 'Rol',
          valor: _rol,
          color: _colorRol,
        ),
        _InfoTile(
          icono:
              _emailConfirmado ? Icons.check_circle_rounded : Icons.warning_rounded,
          titulo: 'Estado del correo',
          valor: _emailConfirmado ? 'Confirmado' : 'Pendiente de confirmar',
          color: _emailConfirmado ? Colors.green : Colors.orange,
        ),
      ],
    );
  }

  Widget _buildAcciones() {
    return _SeccionCard(
      titulo: 'Acciones',
      icono: Icons.tune_rounded,
      children: [
        _BotonPerfil(
          texto: 'Editar perfil',
          icono: Icons.edit_rounded,
          color: const Color(0xFF1F8A70),
          onPressed: _abrirEditarPerfil,
        ),
        const SizedBox(height: 10),
        _BotonPerfil(
          texto: 'Cambiar contraseña',
          icono: Icons.lock_reset_rounded,
          color: Colors.blue,
          onPressed: _abrirCambiarPassword,
        ),
        const SizedBox(height: 10),
        _BotonPerfil(
          texto: 'Cerrar sesión',
          icono: Icons.logout_rounded,
          color: Colors.red,
          onPressed: _cerrarSesion,
        ),
      ],
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final String texto;
  final IconData icono;

  const _HeaderChip({
    required this.texto,
    required this.icono,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.24),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icono,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            texto,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SeccionCard extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final List<Widget> children;

  const _SeccionCard({
    required this.titulo,
    required this.icono,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 12,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 39,
                height: 39,
                decoration: BoxDecoration(
                  color: const Color(0xFF1F8A70).withOpacity(0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icono,
                  color: const Color(0xFF1F8A70),
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String valor;
  final Color? color;

  const _InfoTile({
    required this.icono,
    required this.titulo,
    required this.valor,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final itemColor = color ?? Colors.grey.shade700;

    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        children: [
          Icon(
            icono,
            color: itemColor,
            size: 21,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
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

class _BotonPerfil extends StatelessWidget {
  final String texto;
  final IconData icono;
  final Color color;
  final VoidCallback onPressed;

  const _BotonPerfil({
    required this.texto,
    required this.icono,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icono),
        label: Text(texto),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}