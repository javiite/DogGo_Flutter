import 'package:flutter/material.dart';
import 'login_screen.dart';


class ServerConfigScreen extends StatefulWidget {
  const ServerConfigScreen({super.key});

  @override
  State<ServerConfigScreen> createState() => _ServerConfigScreenState();
}

class _ServerConfigScreenState extends State<ServerConfigScreen> {
  final TextEditingController _urlController = TextEditingController(
    text: 'https://',
  );

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _guardarUrl() {
    final url = _urlController.text.trim();

    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escribe la URL del servidor'),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
        content: Text('URL guardada: $url'),
    ),
    );

    Navigator.push(
    context,
    MaterialPageRoute(
        builder: (context) => const LoginScreen(),
    ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurar servidor'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_done,
              size: 90,
            ),
            const SizedBox(height: 24),
            const Text(
              'URL del servidor DogGo',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Aquí vas a poner la URL de tu API, por ejemplo la de Cloudflare o la de Tailscale.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Base URL',
                hintText: 'https://tu-api.trycloudflare.com',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _guardarUrl,
                child: const Text('Guardar URL'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}