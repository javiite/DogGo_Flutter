import 'package:flutter/material.dart';
import 'mis_perros_screen.dart';
import 'mis_paseos_screen.dart';
import 'paseadores_screen.dart';
import 'server_config_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _mostrarMensaje(BuildContext context, String texto) {
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
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'Javier',
                style: TextStyle(
                  color: Color(0xFF25324A),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            decoration: const BoxDecoration(
              color: Color(0xFFF4EDE3),
              border: Border(
                bottom: BorderSide(color: Color(0xFFE7E0D5)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDF4F1),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Text(
                    '👋 BIENVENIDO DE VUELTA',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF14A89A),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Hola, Javier.\n¿Cómo están tus peludos hoy?',
                  style: TextStyle(
                    fontSize: 34,
                    height: 1.05,
                    color: Color(0xFF25324A),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Todo lo que necesitas para cuidar a tus mascotas está aquí.',
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF7AD4C9),
                    ),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Color(0xFFF4EDE3),
                        child: Icon(
                          Icons.access_time,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Paseo pendiente — wdqqwdqwd',
                              style: TextStyle(
                                color: Color(0xFF14A89A),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'con Javier Terrones',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          _mostrarMensaje(context, 'Mapa después');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF14A89A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Ver en mapa',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _ActionButton(
                      texto: 'Buscar paseador',
                      filled: true,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PaseadoresScreen(),
                          ),
                        );
                      },
                    ),
                    _ActionButton(
                      texto: 'Mis paseos',
                      filled: false,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MisPaseosScreen(),
                          ),
                        );
                      },
                    ),
                    _ActionButton(
                      texto: 'Mis perros',
                      filled: false,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MisPerrosScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Container(
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
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Tus mascotas',
                            style: TextStyle(
                              fontSize: 22,
                              color: Color(0xFF25324A),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            _mostrarMensaje(context, 'Añadir después');
                          },
                          child: const Text(
                            '+ Añadir',
                            style: TextStyle(
                              color: Color(0xFF14A89A),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      height: 220,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCEEEE),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Center(
                        child: Text(
                          '🐶',
                          style: TextStyle(fontSize: 82),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Center(
                      child: Text(
                        'CHOCOROL',
                        style: TextStyle(
                          fontSize: 24,
                          color: Color(0xFF25324A),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Center(
                      child: Text(
                        'CHIHUAHUA',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: const [
                        Expanded(
                          child: _MiniDato(
                            titulo: '6 años',
                            subtitulo: 'Edad',
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: _MiniDato(
                            titulo: 'Pequeño',
                            subtitulo: 'Tamaño',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Color(0xFFF6ECD8),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        '📝 Notas: El perro es bonito',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF8A6A1F),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MisPerrosScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Ver perfil completo →',
                          style: TextStyle(
                            color: Color(0xFF14A89A),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 18,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF14A89A),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: const [
                  Expanded(
                    child: _BottomStat(
                      numero: '3',
                      texto: 'Mascotas registradas',
                    ),
                  ),
                  Expanded(
                    child: _BottomStat(
                      numero: '1',
                      texto: 'Paseo completado',
                    ),
                  ),
                  Expanded(
                    child: _BottomStat(
                      numero: 'Activo',
                      texto: 'Paseo pendiente',
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Center(
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ServerConfigScreen(),
                    ),
                  );
                },
                child: const Text(
                  'Configurar servidor',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String texto;
  final bool filled;
  final VoidCallback onTap;

  const _ActionButton({
    required this.texto,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF14A89A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
        ),
        child: Text(
          texto,
          style: const TextStyle(color: Colors.white),
        ),
      );
    }

    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFFE2D8C9)),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      child: Text(
        texto,
        style: const TextStyle(
          color: Color(0xFF25324A),
        ),
      ),
    );
  }
}

class _MiniDato extends StatelessWidget {
  final String titulo;
  final String subtitulo;

  const _MiniDato({
    required this.titulo,
    required this.subtitulo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F4EC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            titulo,
            style: const TextStyle(
              color: Color(0xFF25324A),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitulo,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomStat extends StatelessWidget {
  final String numero;
  final String texto;

  const _BottomStat({
    required this.numero,
    required this.texto,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          numero,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          texto,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}