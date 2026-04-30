import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import 'login_screen.dart';
import 'server_config_screen.dart';

class ConfiguracionScreen extends StatelessWidget {
  const ConfiguracionScreen({super.key});

  Future<void> _cerrarSesion(BuildContext context) async {
    await StorageService.limpiarToken();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  Future<void> _limpiarServidor(BuildContext context) async {
    await StorageService.limpiarBaseUrl();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const ServerConfigScreen(),
      ),
      (route) => false,
    );
  }

  Future<void> _mostrarConfirmacion({
    required BuildContext context,
    required String titulo,
    required String mensaje,
    required Future<void> Function() onConfirm,
  }) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(titulo),
          content: Text(mensaje),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Continuar'),
            ),
          ],
        );
      },
    );

    if (confirmar == true) {
      await onConfirm();
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
        title: const Text('Configuración'),
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
                  '⚙️ AJUSTES',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF14A89A),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Configuración',
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
          _ConfigCard(
            titulo: 'Sesión',
            child: Column(
              children: [
                _ConfigButton(
                  texto: 'Cerrar sesión',
                  icono: Icons.logout,
                  rojo: true,
                  onTap: () {
                    _mostrarConfirmacion(
                      context: context,
                      titulo: 'Cerrar sesión',
                      mensaje: '¿Seguro que quieres cerrar sesión?',
                      onConfirm: () => _cerrarSesion(context),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _ConfigCard(
            titulo: 'Servidor',
            child: Column(
              children: [
                _ConfigButton(
                  texto: 'Cambiar servidor',
                  icono: Icons.cloud_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ServerConfigScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                _ConfigButton(
                  texto: 'Limpiar servidor guardado',
                  icono: Icons.delete_outline,
                  rojo: true,
                  onTap: () {
                    _mostrarConfirmacion(
                      context: context,
                      titulo: 'Limpiar servidor',
                      mensaje: 'Se borrará la URL guardada del servidor.',
                      onConfirm: () => _limpiarServidor(context),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfigCard extends StatelessWidget {
  final String titulo;
  final Widget child;

  const _ConfigCard({
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

class _ConfigButton extends StatelessWidget {
  final String texto;
  final IconData icono;
  final VoidCallback onTap;
  final bool rojo;

  const _ConfigButton({
    required this.texto,
    required this.icono,
    required this.onTap,
    this.rojo = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = rojo ? const Color(0xFFE56B6F) : const Color(0xFF14A89A);

    return SizedBox(
      width: double.infinity,
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