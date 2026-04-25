import 'package:flutter/material.dart';

class MisPerrosScreen extends StatelessWidget {
  const MisPerrosScreen({super.key});

  void _mostrarMensaje(BuildContext context, String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }

  Widget _buildPerroCard(
    BuildContext context, {
    required String nombre,
    required String raza,
    required String edad,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.10),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.pets,
                size: 34,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nombre,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('Raza: $raza'),
                  Text('Edad: $edad'),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                _mostrarMensaje(context, '$value de $nombre después');
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'Editar',
                  child: Text('Editar'),
                ),
                PopupMenuItem(
                  value: 'Eliminar',
                  child: Text('Eliminar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final perrosDemo = [
      {'nombre': 'Rocky', 'raza': 'Labrador', 'edad': '3 años'},
      {'nombre': 'Luna', 'raza': 'French Poodle', 'edad': '2 años'},
      {'nombre': 'Max', 'raza': 'Pastor Alemán', 'edad': '4 años'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis perros'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _mostrarMensaje(context, 'Registrar perro después');
        },
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tus mascotas',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Aquí puedes ver y administrar los perros registrados.',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: ListView.separated(
                itemCount: perrosDemo.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final perro = perrosDemo[index];
                  return _buildPerroCard(
                    context,
                    nombre: perro['nombre']!,
                    raza: perro['raza']!,
                    edad: perro['edad']!,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}