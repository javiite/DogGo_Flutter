import 'package:flutter/material.dart';
import '../services/perros_service.dart';

class RegistrarPerroScreen extends StatefulWidget {
  const RegistrarPerroScreen({super.key});

  @override
  State<RegistrarPerroScreen> createState() => _RegistrarPerroScreenState();
}

class _RegistrarPerroScreenState extends State<RegistrarPerroScreen> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _razaController = TextEditingController();
  final TextEditingController _edadController = TextEditingController();
  final TextEditingController _notasController = TextEditingController();

  String _tamanoSeleccionado = 'Mediano';
  bool _guardando = false;

  final List<String> _tamanos = const [
    'Pequeño',
    'Mediano',
    'Grande',
  ];

  @override
  void dispose() {
    _nombreController.dispose();
    _razaController.dispose();
    _edadController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  void _mostrarMensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }

  bool _validar() {
    final nombre = _nombreController.text.trim();
    final raza = _razaController.text.trim();
    final edadTexto = _edadController.text.trim();

    if (nombre.isEmpty) {
      _mostrarMensaje('Escribe el nombre del perro.');
      return false;
    }

    if (raza.isEmpty) {
      _mostrarMensaje('Escribe la raza del perro.');
      return false;
    }

    if (edadTexto.isEmpty) {
      _mostrarMensaje('Escribe la edad del perro.');
      return false;
    }

    final edad = int.tryParse(edadTexto);

    if (edad == null) {
      _mostrarMensaje('La edad debe ser un número válido.');
      return false;
    }

    if (edad < 0 || edad > 30) {
      _mostrarMensaje('La edad debe estar entre 0 y 30 años.');
      return false;
    }

    return true;
  }

  Future<void> _guardarPerro() async {
    if (_guardando) return;

    if (!_validar()) return;

    final edad = int.parse(_edadController.text.trim());

    setState(() {
      _guardando = true;
    });

    try {
      final result = await PerrosService.registrarPerro(
        nombre: _nombreController.text.trim(),
        raza: _razaController.text.trim(),
        edad: edad,
        tamano: _tamanoSeleccionado,
        notas: _notasController.text.trim(),
      );

      if (!mounted) return;

      if (result['success'] == true) {
        _mostrarMensaje(
          result['message']?.toString() ?? 'Perro registrado correctamente.',
        );

        await Future.delayed(const Duration(milliseconds: 700));

        if (!mounted) return;

        Navigator.pop(context, true);
      } else {
        final statusCode = result['statusCode'];

        _mostrarMensaje(
          statusCode == null
              ? result['message']?.toString() ?? 'No se pudo registrar el perro.'
              : '${result['message']} Código: $statusCode',
        );
      }
    } catch (e) {
      if (!mounted) return;

      _mostrarMensaje('Error de conexión: $e');
    } finally {
      if (mounted) {
        setState(() {
          _guardando = false;
        });
      }
    }
  }

  InputDecoration _decoracionCampo({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
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
        title: const Text('Registrar perro'),
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
                  'NUEVO PELUDO',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF14A89A),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Registrar perro',
                  style: TextStyle(
                    fontSize: 28,
                    color: Color(0xFF25324A),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Agrega la información básica de tu mascota.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _FormCard(
            titulo: 'Datos del perro',
            child: Column(
              children: [
                TextField(
                  controller: _nombreController,
                  enabled: !_guardando,
                  textInputAction: TextInputAction.next,
                  decoration: _decoracionCampo(
                    label: 'Nombre',
                    icon: Icons.pets,
                    hint: 'Ej. Max',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _razaController,
                  enabled: !_guardando,
                  textInputAction: TextInputAction.next,
                  decoration: _decoracionCampo(
                    label: 'Raza',
                    icon: Icons.badge_outlined,
                    hint: 'Ej. Labrador',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _edadController,
                  enabled: !_guardando,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  decoration: _decoracionCampo(
                    label: 'Edad',
                    icon: Icons.cake_outlined,
                    hint: 'Ej. 3',
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F4EC),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _tamanoSeleccionado,
                      isExpanded: true,
                      items: _tamanos.map((tamano) {
                        return DropdownMenuItem<String>(
                          value: tamano,
                          child: Text(tamano),
                        );
                      }).toList(),
                      onChanged: _guardando
                          ? null
                          : (value) {
                              if (value == null) return;

                              setState(() {
                                _tamanoSeleccionado = value;
                              });
                            },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _FormCard(
            titulo: 'Notas',
            child: TextField(
              controller: _notasController,
              enabled: !_guardando,
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
              onPressed: _guardando ? null : _guardarPerro,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF14A89A),
                disabledBackgroundColor:
                    const Color(0xFF14A89A).withOpacity(0.45),
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
                      'Guardar perro',
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