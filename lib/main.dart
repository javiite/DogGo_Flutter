import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/background_tracking_service.dart';
import 'services/session_service.dart';
import 'services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await BackgroundTrackingService.inicializarServicio();

  runApp(const DogGoApp());
}

class DogGoApp extends StatelessWidget {
  const DogGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DogGo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0EC9A0),
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F0E8),
      ),
      home: const ArranqueScreen(),
    );
  }
}

class ArranqueScreen extends StatefulWidget {
  const ArranqueScreen({super.key});

  @override
  State<ArranqueScreen> createState() => _ArranqueScreenState();
}

class _ArranqueScreenState extends State<ArranqueScreen> {
  bool _cargando = true;
  bool _tieneServidor = false;
  bool _haySesion = false;

  @override
  void initState() {
    super.initState();
    _revisarEstadoInicial();
  }

  Future<void> _revisarEstadoInicial() async {
    final baseUrl = await StorageService.obtenerBaseUrl();
    final haySesion = await SessionService.haySesionActiva();

    if (!mounted) return;

    setState(() {
      _tieneServidor = baseUrl != null && baseUrl.trim().isNotEmpty;
      _haySesion = haySesion;
      _cargando = false;
    });
  }

  void _servidorConfigurado() {
    setState(() {
      _tieneServidor = true;
      _haySesion = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(
        backgroundColor: Color(0xFFF4F0E8),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_tieneServidor) {
      return ConfigurarServidorInicialScreen(
        onConfigurado: _servidorConfigurado,
      );
    }

    if (_haySesion) {
      return const HomeScreen();
    }

    return const LoginScreen();
  }
}

class ConfigurarServidorInicialScreen extends StatefulWidget {
  final VoidCallback onConfigurado;

  const ConfigurarServidorInicialScreen({
    super.key,
    required this.onConfigurado,
  });

  @override
  State<ConfigurarServidorInicialScreen> createState() =>
      _ConfigurarServidorInicialScreenState();
}

class _ConfigurarServidorInicialScreenState
    extends State<ConfigurarServidorInicialScreen> {
  final TextEditingController _urlController = TextEditingController();
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _cargarUrlGuardada();
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _cargarUrlGuardada() async {
    final url = await StorageService.obtenerBaseUrl();

    if (!mounted) return;

    if (url != null && url.trim().isNotEmpty) {
      _urlController.text = url;
    }
  }

  String _limpiarUrl(String url) {
    var limpia = url.trim();

    while (limpia.endsWith('/')) {
      limpia = limpia.substring(0, limpia.length - 1);
    }

    return limpia;
  }

  void _mensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }

  Future<void> _guardarServidor() async {
    final url = _limpiarUrl(_urlController.text);

    if (url.isEmpty) {
      _mensaje('Escribe la URL del servidor.');
      return;
    }

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      _mensaje('La URL debe empezar con http:// o https://');
      return;
    }

    if (url.endsWith('/api')) {
      _mensaje('No agregues /api al final. Solo pega la URL base.');
      return;
    }

    setState(() {
      _guardando = true;
    });

    try {
      await StorageService.guardarBaseUrl(url);

      if (!mounted) return;

      _mensaje('Servidor guardado correctamente.');

      await Future.delayed(const Duration(milliseconds: 400));

      if (!mounted) return;

      widget.onConfigurado();
    } catch (e) {
      if (!mounted) return;
      _mensaje('No se pudo guardar el servidor: $e');
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
      backgroundColor: const Color(0xFFF4F0E8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF089B7A),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Row(
          children: [
            Text('🐾', style: TextStyle(fontSize: 22)),
            SizedBox(width: 8),
            Text(
              'DogGo',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF0EC9A0),
                  Color(0xFF057A5F),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0EC9A0).withOpacity(0.28),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CONFIGURACIÓN INICIAL',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Conecta DogGo\ncon tu servidor',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Pega la URL base de Cloudflare o de tu servidor local. No agregues /api al final.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                TextField(
                  controller: _urlController,
                  enabled: !_guardando,
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(
                    labelText: 'URL base',
                    hintText: 'https://algo.trycloudflare.com',
                    prefixIcon: const Icon(Icons.link_rounded),
                    filled: true,
                    fillColor: const Color(0xFFF8F4EC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE4FAF4),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'Ejemplo:\nhttps://somerset-assignments-leg-anna.trycloudflare.com\n\nNo pongas /api al final.',
                    style: TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 12.5,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _guardando ? null : _guardarServidor,
                    icon: _guardando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_rounded),
                    label: Text(
                      _guardando ? 'Guardando...' : 'Guardar y continuar',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0EC9A0),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          const Color(0xFF0EC9A0).withOpacity(0.45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 0,
                    ),
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