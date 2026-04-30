import 'package:flutter/material.dart';
import '../services/perros_service.dart';
import 'detalle_perro_screen.dart';
import 'editar_perro_screen.dart';
import 'registrar_perro_screen.dart';

class MisPerrosScreen extends StatefulWidget {
  const MisPerrosScreen({super.key});

  @override
  State<MisPerrosScreen> createState() => _MisPerrosScreenState();
}

class _MisPerrosScreenState extends State<MisPerrosScreen> {
  bool _cargando = true;
  String? _error;
  List<dynamic> _perros = [];

  @override
  void initState() {
    super.initState();
    _cargarPerros();
  }

  Future<void> _cargarPerros() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final result = await PerrosService.obtenerMisPerros();

      if (!mounted) return;

      if (result['success'] == true) {
        setState(() {
          _perros = result['data'] as List<dynamic>;
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

  void _mostrarMensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }

  String _textoSeguro(dynamic valor, [String fallback = 'Sin dato']) {
    if (valor == null) return fallback;
    final texto = valor.toString().trim();
    return texto.isEmpty ? fallback : texto;
  }

  String _edadTexto(dynamic edad) {
    if (edad == null) return 'Sin edad';
    return '${edad.toString()} años';
  }

  Future<void> _confirmarEliminar(Map<String, dynamic> perro) async {
    final nombre = _textoSeguro(perro['nombre'], 'este perro');

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar perro'),
          content: Text('¿Seguro que quieres eliminar a $nombre?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    try {
      final result = await PerrosService.eliminarPerro(perro['id'] as int);

      if (!mounted) return;

      _mostrarMensaje(result['message']);

      if (result['success'] == true) {
        await _cargarPerros();
      }
    } catch (e) {
      if (!mounted) return;
      _mostrarMensaje('Error de conexión: $e');
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
        centerTitle: false,
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
            onPressed: () {
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
                          size: 72,
                          color: Colors.redAccent,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _cargarPerros,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF4EDE3),
                        border: Border(
                          bottom: BorderSide(
                            color: Color(0xFFE7E0D5),
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '🐶 TU MANADA',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF14A89A),
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Mis perros',
                            style: TextStyle(
                              fontSize: 30,
                              height: 1.1,
                              color: Color(0xFF25324A),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tienes ${_perros.length} perros registrados.',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final creado = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const RegistrarPerroScreen(),
                                  ),
                                );

                                if (!mounted) return;

                                if (creado == true) {
                                  await _cargarPerros();
                                }
                              },
                              icon: const Icon(Icons.add, color: Colors.white),
                              label: const Text(
                                'Añadir perro',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF14A89A),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _perros.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.pets_outlined,
                                      size: 76,
                                      color: Color(0xFFB8B3AA),
                                    ),
                                    const SizedBox(height: 14),
                                    const Text(
                                      'Todavía no tienes perros registrados',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Color(0xFF25324A),
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Cuando agregues uno, aparecerá aquí.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Color(0xFF6B7280),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _cargarPerros,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(18),
                                itemCount: _perros.length,
                                itemBuilder: (context, index) {
                                  final perro =
                                      _perros[index] as Map<String, dynamic>;

                                  final nombre = _textoSeguro(perro['nombre']);
                                  final raza = _textoSeguro(
                                    perro['raza'],
                                    'Sin raza',
                                  );
                                  final tamano = _textoSeguro(
                                    perro['tamano'] ?? perro['tamaño'],
                                    'Sin tamaño',
                                  );
                                  final notas = _textoSeguro(
                                    perro['notas'] ??
                                        perro['nota'] ??
                                        perro['descripcion'],
                                    '',
                                  );
                                  final edad = _edadTexto(perro['edad']);

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: _PerroCard(
                                      nombre: nombre,
                                      edad: edad,
                                      raza: raza,
                                      tamano: tamano,
                                      nota: notas,
                                      onVerPerfil: () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => DetallePerroScreen(
                                              perro: perro,
                                            ),
                                          ),
                                        );
                                      },
                                      onEditar: () async {
                                        final editado = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => EditarPerroScreen(
                                              perro: perro,
                                            ),
                                          ),
                                        );

                                        if (!mounted) return;

                                        if (editado == true) {
                                          await _cargarPerros();
                                        }
                                      },
                                      onEliminar: () {
                                        _confirmarEliminar(perro);
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }
}

class _PerroCard extends StatelessWidget {
  final String nombre;
  final String edad;
  final String raza;
  final String tamano;
  final String nota;
  final VoidCallback onVerPerfil;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  const _PerroCard({
    required this.nombre,
    required this.edad,
    required this.raza,
    required this.tamano,
    required this.nota,
    required this.onVerPerfil,
    required this.onEditar,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 180,
            decoration: const BoxDecoration(
              color: Color(0xFFDCEEEE),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 12,
                  top: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      tamano,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF14A89A),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const Center(
                  child: Text(
                    '🐶',
                    style: TextStyle(fontSize: 72),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        nombre,
                        style: const TextStyle(
                          fontSize: 22,
                          color: Color(0xFF25324A),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Text(
                      edad,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDF4F1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    raza,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF14A89A),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _MiniInfoBox(
                        titulo: tamano,
                        subtitulo: 'Tamaño',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MiniInfoBox(
                        titulo: edad,
                        subtitulo: 'Edad',
                      ),
                    ),
                  ],
                ),
                if (nota.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6ECD8),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      '📝 $nota',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF8A6A1F),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onVerPerfil,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Color(0xFF14A89A),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: const Text(
                          'Ver perfil',
                          style: TextStyle(
                            color: Color(0xFF14A89A),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _CircleActionButton(
                      icon: Icons.edit_outlined,
                      onTap: onEditar,
                    ),
                    const SizedBox(width: 8),
                    _CircleActionButton(
                      icon: Icons.delete_outline,
                      onTap: onEliminar,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniInfoBox extends StatelessWidget {
  final String titulo;
  final String subtitulo;

  const _MiniInfoBox({
    required this.titulo,
    required this.subtitulo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F4EC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF25324A),
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

class _CircleActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleActionButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF4EDE3),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(
            icon,
            size: 18,
            color: const Color(0xFFB57A4B),
          ),
        ),
      ),
    );
  }
}