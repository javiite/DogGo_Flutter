import 'package:flutter/material.dart';

import '../services/storage_service.dart';
import 'cambiar_password_screen.dart';

class _T {
  static const teal = Color(0xFF0EC9A0);
  static const tealDeep = Color(0xFF089B7A);
  static const tealSurface = Color(0xFFE4FAF4);
  static const violet = Color(0xFF7C5CBF);
  static const violetSurf = Color(0xFFF0EBFA);
  static const amber = Color(0xFFFFAB2E);
  static const amberSurf = Color(0xFFFFF4E0);
  static const emerald = Color(0xFF22C55E);
  static const emeraldSurf = Color(0xFFE6FAF0);
  static const rose = Color(0xFFEF4444);
  static const roseSurf = Color(0xFFFEEEEE);
  static const bg = Color(0xFFF4F0E8);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF111827);
  static const inkSub = Color(0xFF6B7280);
  static const stroke = Color(0xFFE5E7EB);

  static const r8 = BorderRadius.all(Radius.circular(8));
  static const r10 = BorderRadius.all(Radius.circular(10));
  static const r12 = BorderRadius.all(Radius.circular(12));
  static const r20 = BorderRadius.all(Radius.circular(20));

  static List<BoxShadow> shadow({
    double opacity = .07,
    double blur = 20,
    Offset offset = const Offset(0, 6),
  }) =>
      [
        BoxShadow(
          color: Colors.black.withOpacity(opacity),
          blurRadius: blur,
          offset: offset,
        ),
      ];
}

TextStyle _ts(
  double size,
  FontWeight weight,
  Color color, {
  double spacing = 0,
  double height = 1.2,
}) {
  return TextStyle(
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: spacing,
    height: height,
  );
}

class ConfiguracionScreen extends StatefulWidget {
  const ConfiguracionScreen({super.key});

  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  )..forward();

  late final Animation<double> _fade = CurvedAnimation(
    parent: _ctrl,
    curve: Curves.easeOut,
  );

  final TextEditingController _urlController = TextEditingController();

  bool _guardandoUrl = false;

  bool _notifPaseos = true;
  bool _notifMensajes = true;
  bool _notifPromos = false;
  bool _notifRecordatorio = true;
  bool _ubicacionTiempo = true;
  bool _ubicacionHistorial = false;
  bool _darkMode = false;
  bool _biometrico = false;
  bool _dosFactores = false;

  @override
  void initState() {
    super.initState();
    _cargarUrl();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _cargarUrl() async {
    final url = await StorageService.obtenerBaseUrl();

    if (!mounted) return;

    _urlController.text = url ?? '';
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

  Future<void> _guardarUrl() async {
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
      _mensaje('No agregues /api al final.');
      return;
    }

    setState(() {
      _guardandoUrl = true;
    });

    try {
      await StorageService.guardarBaseUrl(url);

      if (!mounted) return;

      _mensaje('Servidor actualizado correctamente.');
    } catch (e) {
      if (!mounted) return;
      _mensaje('No se pudo guardar la URL: $e');
    } finally {
      if (mounted) {
        setState(() {
          _guardandoUrl = false;
        });
      }
    }
  }

  Future<void> _abrirCambiarPassword() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CambiarPasswordScreen(),
      ),
    );
  }

  void _showAcercaDe() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: _T.r20),
        title: Row(
          children: [
            const Text('🐾', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Text('DogGo', style: _ts(20, FontWeight.w900, _T.ink)),
          ],
        ),
        content: Text(
          'DogGo móvil conecta dueños con paseadores usando la API real del proyecto.',
          style: _ts(13, FontWeight.w400, _T.inkSub, height: 1.35),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: _T.teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: _T.r12),
              elevation: 0,
            ),
            child: Text('OK', style: _ts(13, FontWeight.w800, Colors.white)),
          ),
        ],
      ),
    );
  }

  void _pendiente(String modulo) {
    _mensaje('$modulo todavía es visual por ahora.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.bg,
      appBar: AppBar(
        backgroundColor: _T.tealDeep,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.15),
                borderRadius: _T.r8,
              ),
              child: const Center(
                child: Text('⚙️', style: TextStyle(fontSize: 17)),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Configuración',
              style: _ts(20, FontWeight.w900, Colors.white, spacing: -.4),
            ),
          ],
        ),
      ),
      body: FadeTransition(
        opacity: _fade,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 16),
              _seccion(
                titulo: '🌐 Servidor',
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                    child: TextField(
                      controller: _urlController,
                      enabled: !_guardandoUrl,
                      keyboardType: TextInputType.url,
                      decoration: InputDecoration(
                        labelText: 'URL base',
                        hintText: 'https://algo.trycloudflare.com',
                        prefixIcon: const Icon(Icons.link_rounded),
                        filled: true,
                        fillColor: const Color(0xFFF8F4EC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: _guardandoUrl ? null : _guardarUrl,
                        icon: _guardandoUrl
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_rounded),
                        label: Text(
                          _guardandoUrl ? 'Guardando...' : 'Guardar servidor',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _T.teal,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: _T.teal.withOpacity(.45),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _seccion(
                titulo: '🔔 Notificaciones',
                children: [
                  _toggleRow(
                    'Paseos activos',
                    'Alertas de tu paseo en tiempo real',
                    Icons.directions_walk_rounded,
                    _T.teal,
                    _T.tealSurface,
                    _notifPaseos,
                    (value) => setState(() => _notifPaseos = value),
                  ),
                  _toggleRow(
                    'Nuevos mensajes',
                    'Notificaciones de chat',
                    Icons.chat_bubble_rounded,
                    _T.violet,
                    _T.violetSurf,
                    _notifMensajes,
                    (value) => setState(() => _notifMensajes = value),
                  ),
                  _toggleRow(
                    'Recordatorios',
                    'Próximos paseos agendados',
                    Icons.alarm_rounded,
                    _T.amber,
                    _T.amberSurf,
                    _notifRecordatorio,
                    (value) => setState(() => _notifRecordatorio = value),
                  ),
                  _toggleRow(
                    'Promociones',
                    'Ofertas y descuentos',
                    Icons.local_offer_rounded,
                    _T.emerald,
                    _T.emeraldSurf,
                    _notifPromos,
                    (value) => setState(() => _notifPromos = value),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _seccion(
                titulo: '📍 Ubicación',
                children: [
                  _toggleRow(
                    'Ubicación en tiempo real',
                    'Durante los paseos activos',
                    Icons.gps_fixed_rounded,
                    _T.teal,
                    _T.tealSurface,
                    _ubicacionTiempo,
                    (value) => setState(() => _ubicacionTiempo = value),
                  ),
                  _toggleRow(
                    'Guardar historial',
                    'Rutas de paseos anteriores',
                    Icons.history_rounded,
                    _T.violet,
                    _T.violetSurf,
                    _ubicacionHistorial,
                    (value) => setState(() => _ubicacionHistorial = value),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _seccion(
                titulo: '🔐 Seguridad',
                children: [
                  _toggleRow(
                    'Autenticación biométrica',
                    'Huella o Face ID para entrar',
                    Icons.fingerprint_rounded,
                    _T.emerald,
                    _T.emeraldSurf,
                    _biometrico,
                    (value) => setState(() => _biometrico = value),
                  ),
                  _toggleRow(
                    'Verificación en 2 pasos',
                    'Código adicional al iniciar',
                    Icons.security_rounded,
                    _T.amber,
                    _T.amberSurf,
                    _dosFactores,
                    (value) => setState(() => _dosFactores = value),
                  ),
                  _accionRow(
                    Icons.lock_reset_rounded,
                    'Cambiar contraseña',
                    _T.violet,
                    _T.violetSurf,
                    _abrirCambiarPassword,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _seccion(
                titulo: '🎨 Apariencia',
                children: [
                  _toggleRow(
                    'Modo oscuro',
                    'Tema oscuro para la app',
                    Icons.dark_mode_rounded,
                    _T.ink,
                    const Color(0xFFF3F4F6),
                    _darkMode,
                    (value) => setState(() => _darkMode = value),
                  ),
                  _accionRow(
                    Icons.language_rounded,
                    'Idioma — Español',
                    _T.teal,
                    _T.tealSurface,
                    () => _pendiente('Idioma'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _seccion(
                titulo: '📱 Cuenta',
                children: [
                  _accionRow(
                    Icons.download_rounded,
                    'Exportar mis datos',
                    _T.teal,
                    _T.tealSurface,
                    () => _pendiente('Exportar datos'),
                  ),
                  _accionRow(
                    Icons.help_outline_rounded,
                    'Centro de ayuda',
                    _T.violet,
                    _T.violetSurf,
                    () => _pendiente('Centro de ayuda'),
                  ),
                  _accionRow(
                    Icons.info_outline_rounded,
                    'Acerca de DogGo',
                    _T.inkSub,
                    const Color(0xFFF3F4F6),
                    _showAcercaDe,
                  ),
                  _accionRow(
                    Icons.delete_outline_rounded,
                    'Eliminar cuenta',
                    _T.rose,
                    _T.roseSurf,
                    () => _pendiente('Eliminar cuenta'),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _seccion({
    required String titulo,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: _T.r20,
        boxShadow: _T.shadow(
          opacity: .05,
          blur: 16,
          offset: const Offset(0, 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              titulo,
              style: _ts(15, FontWeight.w900, _T.ink, spacing: -.2),
            ),
          ),
          ...children,
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _toggleRow(
    String label,
    String sub,
    IconData icon,
    Color color,
    Color surf,
    bool value,
    void Function(bool) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: surf, borderRadius: _T.r10),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: _ts(13.5, FontWeight.w700, _T.ink)),
                Text(sub, style: _ts(11, FontWeight.w400, _T.inkSub)),
              ],
            ),
          ),
          Transform.scale(
            scale: .85,
            child: Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeColor: color,
              activeTrackColor: color.withOpacity(.25),
            ),
          ),
        ],
      ),
    );
  }

  Widget _accionRow(
    IconData icon,
    String label,
    Color color,
    Color surf,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: surf, borderRadius: _T.r10),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: _ts(13.5, FontWeight.w600, _T.ink),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFD1D5DB),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}