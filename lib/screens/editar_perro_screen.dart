import 'package:flutter/material.dart';
import '../services/perros_service.dart';

class EditarPerroScreen extends StatefulWidget {
  final Map<String, dynamic> perro;

  const EditarPerroScreen({
    super.key,
    required this.perro,
  });

  @override
  State<EditarPerroScreen> createState() => _EditarPerroScreenState();
}

class _EditarPerroScreenState extends State<EditarPerroScreen> {
  late final TextEditingController _nombreController;
  late final TextEditingController _razaController;
  late final TextEditingController _edadController;
  late final TextEditingController _tamanoController;
  late final TextEditingController _notasController;

  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(
      text: widget.perro['nombre']?.toString() ?? '',
    );
    _razaController = TextEditingController(
      text: widget.perro['raza']?.toString() ?? '',
    );
    _edadController = TextEditingController(
      text: widget.perro['edad']?.toString() ?? '',
    );
    _tamanoController = TextEditingController(
      text: widget.perro['tamano']?.toString() ??
          widget.perro['tamaño']?.toString() ??
          '',
    );
    _notasController = TextEditingController(
      text: widget.perro['notas']?.toString() ??
          widget.perro['nota']?.toString() ??
          widget.perro['descripcion']?.toString() ??
          '',
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _razaController.dispose();
    _edadController.dispose();
    _tamanoController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  void _mostrarMensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }

  Future<void> _guardar() async {
    final nombre = _nombreController.text.trim();
    final raza = _razaController.text.trim();
    final edadTexto = _edadController.text.trim();
    final tamano = _tamanoController.text.trim();
    final notas = _notasController.text.trim();

    if (nombre.isEmpty || raza.isEmpty || edadTexto.isEmpty || tamano.isEmpty) {
      _mostrarMensaje('Completa nombre, raza, edad y tamaño');
      return;
    }

    final edad = int.tryParse(edadTexto);
    if (edad == null) {
      _mostrarMensaje('La edad debe ser un número válido');
      return;
    }

    setState(() {
      _guardando = true;
    });

    try {
      final result = await PerrosService.editarPerro(
        id: widget.perro['id'] as int,
        nombre: nombre,
        raza: raza,
        edad: edad,
        tamano: tamano,
        notas: notas,
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
        title: const Text('Editar perro'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _FormCard(
            titulo: 'Datos del perro',
            child: Column(
              children: [
                _CampoDoggo(
                  controller: _nombreController,
                  label: 'Nombre',
                  icon: Icons.pets,
                ),
                const SizedBox(height: 12),
                _CampoDoggo(
                  controller: _razaController,
                  label: 'Raza',
                  icon: Icons.badge_outlined,
                ),
                const SizedBox(height: 12),
                _CampoDoggo(
                  controller: _edadController,
                  label: 'Edad',
                  icon: Icons.cake_outlined,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                _CampoDoggo(
                  controller: _tamanoController,
                  label: 'Tamaño',
                  icon: Icons.straighten,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _FormCard(
            titulo: 'Notas',
            child: TextField(
              controller: _notasController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Cuidados, temperamento, alergias, etc.',
                filled: true,
                fillColor: const Color(0xFFF8F4EC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _guardando ? null : _guardar,
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

class _FormCard extends StatelessWidget {
  final String titulo;
  final Widget child;

  const _FormCard({
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

class _CampoDoggo extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;

  const _CampoDoggo({
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