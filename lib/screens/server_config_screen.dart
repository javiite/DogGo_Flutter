import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import 'login_screen.dart';

class ServerConfigScreen extends StatefulWidget {
  const ServerConfigScreen({super.key});

  @override
  State<ServerConfigScreen> createState() => _ServerConfigScreenState();
}

class _ServerConfigScreenState extends State<ServerConfigScreen> {
  final TextEditingController _urlController = TextEditingController(
    text: 'http://',
  );

  bool _guardando = false;
  String _urlActual = '';

  @override
  void initState() {
    super.initState();
    _cargarUrlGuardada();
  }

  Future<void> _cargarUrlGuardada() async {
    final urlGuardada = await StorageService.obtenerBaseUrl();

    if (!mounted) return;

    setState(() {
      _urlActual = urlGuardada ?? '';
      if (urlGuardada != null && urlGuardada.isNotEmpty) {
        _urlController.text = urlGuardada;
      }
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _guardarUrl() async {
    final url = _urlController.text.trim();

    if (url.isEmpty || url == 'http://' || url == 'https://') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escribe una URL válida del servidor'),
        ),
      );
      return;
    }

    setState(() {
      _guardando = true;
    });

    try {
      await StorageService.guardarBaseUrl(url);
      final confirmacion = await StorageService.obtenerBaseUrl();

      if (!mounted) return;

      setState(() {
        _urlActual = confirmacion ?? '';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('URL guardada: ${confirmacion ?? url}'),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar URL: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _guardando = false;
        });
      }
    }
  }

  Future<void> _limpiarUrl() async {
    await StorageService.limpiarBaseUrl();
    if (!mounted) return;

    setState(() {
      _urlController.text = 'http://';
      _urlActual = '';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('URL eliminada'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6EF),
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
              'Aquí vas a poner la URL de tu API, por ejemplo la IP local de tu compu o la de Cloudflare.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Base URL',
                hintText: 'http://192.168.1.48:5230',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            if (_urlActual.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black12),
                ),
                child: Text(
                  'URL guardada actual:\n$_urlActual',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _guardando ? null : _guardarUrl,
                child: _guardando
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Guardar URL'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _limpiarUrl,
                child: const Text('Limpiar URL'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}