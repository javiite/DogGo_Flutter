import 'package:flutter/material.dart';

class CrearPaseoScreen extends StatefulWidget {
  final Map<String, dynamic>? paseador;

  const CrearPaseoScreen({
    super.key,
    this.paseador,
  });

  @override
  State<CrearPaseoScreen> createState() => _CrearPaseoScreenState();
}

class _CrearPaseoScreenState extends State<CrearPaseoScreen> {
  String? _perroSeleccionado;
  int _duracion = 30;
  DateTime? _fechaSeleccionada;
  final TextEditingController _notasController = TextEditingController();

  final List<Map<String, dynamic>> perrosDemo = [
    {'id': 1, 'nombre': 'CHOCOROL'},
    {'id': 2, 'nombre': 'Luna'},
    {'id': 3, 'nombre': 'Max'},
  ];

  @override
  void dispose() {
    _notasController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final ahora = DateTime.now();
    final fecha = await showDatePicker(
      context: context,
      initialDate: ahora,
      firstDate: ahora,
      lastDate: DateTime(2030),
    );

    if (fecha == null) return;

    if (!mounted) return;

    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (hora == null) return;

    setState(() {
      _fechaSeleccionada = DateTime(
        fecha.year,
        fecha.month,
        fecha.day,
        hora.hour,
        hora.minute,
      );
    });
  }

  void _mostrarMensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nombrePaseador =
        widget.paseador?['nombre']?.toString() ?? 'Paseador seleccionado';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6EF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text('Crear paseo'),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🦮 NUEVO PASEO',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF14A89A),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Agenda un paseo',
                  style: TextStyle(
                    fontSize: 28,
                    color: Color(0xFF25324A),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Paseador: $nombrePaseador',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _FormCard(
            titulo: 'Selecciona tu perro',
            child: DropdownButtonFormField<String>(
              value: _perroSeleccionado,
              items: perrosDemo
                  .map(
                    (perro) => DropdownMenuItem<String>(
                      value: perro['nombre'].toString(),
                      child: Text(perro['nombre'].toString()),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _perroSeleccionado = value;
                });
              },
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF8F4EC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _FormCard(
            titulo: 'Duración',
            child: Column(
              children: [
                Slider(
                  value: _duracion.toDouble(),
                  min: 30,
                  max: 120,
                  divisions: 3,
                  label: '$_duracion min',
                  onChanged: (value) {
                    setState(() {
                      _duracion = value.toInt();
                    });
                  },
                ),
                Text(
                  '$_duracion minutos',
                  style: const TextStyle(
                    color: Color(0xFF25324A),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _FormCard(
            titulo: 'Fecha y hora',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _fechaSeleccionada == null
                      ? 'No seleccionada'
                      : _fechaSeleccionada.toString(),
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _seleccionarFecha,
                  child: const Text('Seleccionar fecha'),
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
                hintText: 'Indica algo importante para el paseo...',
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
              onPressed: () {
                _mostrarMensaje('Crear paseo real después');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF14A89A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Confirmar paseo',
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