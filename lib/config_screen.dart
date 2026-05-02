import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  DESIGN TOKENS
// ─────────────────────────────────────────────────────────────────────────────
class _T {
  static const teal = Color(0xFF0EC9A0);
  static const tealDeep = Color(0xFF089B7A);
  static const tealMid = Color(0xFF12B48E);
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
  static const r16 = BorderRadius.all(Radius.circular(16));
  static const r20 = BorderRadius.all(Radius.circular(20));
  static const r32 = BorderRadius.all(Radius.circular(32));

  static List<BoxShadow> shadow({
    double opacity = .07,
    double blur = 20,
    Offset offset = const Offset(0, 6),
  }) => [
    BoxShadow(
      color: Colors.black.withOpacity(opacity),
      blurRadius: blur,
      offset: offset,
    ),
  ];
}

TextStyle _ts(
  double size,
  FontWeight w,
  Color c, {
  double spacing = 0,
  double height = 1.2,
}) => TextStyle(
  fontSize: size,
  fontWeight: w,
  color: c,
  letterSpacing: spacing,
  height: height,
);

// ─────────────────────────────────────────────────────────────────────────────
//  CONFIG SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});
  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  )..forward();
  late final Animation<double> _fade = CurvedAnimation(
    parent: _ctrl,
    curve: Curves.easeOut,
  );

  // Toggle states
  bool _notifPaseos = true;
  bool _notifMensajes = true;
  bool _notifPromos = false;
  bool _notifRecordatorio = true;
  bool _ubicacionTiempo = true;
  bool _ubicacionHistorial = false;
  bool _darkMode = false;
  bool _biometrico = true;
  bool _dosFactores = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.bg,
      appBar: AppBar(
        backgroundColor: _T.tealDeep,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
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
                titulo: '🔔 Notificaciones',
                children: [
                  _toggleRow(
                    'Paseos activos',
                    'Alertas de tu paseo en tiempo real',
                    Icons.directions_walk_rounded,
                    _T.teal,
                    _T.tealSurface,
                    _notifPaseos,
                    (v) => setState(() => _notifPaseos = v),
                  ),
                  _toggleRow(
                    'Nuevos mensajes',
                    'Notificaciones de chat',
                    Icons.chat_bubble_rounded,
                    _T.violet,
                    _T.violetSurf,
                    _notifMensajes,
                    (v) => setState(() => _notifMensajes = v),
                  ),
                  _toggleRow(
                    'Recordatorios',
                    'Próximos paseos agendados',
                    Icons.alarm_rounded,
                    _T.amber,
                    _T.amberSurf,
                    _notifRecordatorio,
                    (v) => setState(() => _notifRecordatorio = v),
                  ),
                  _toggleRow(
                    'Promociones',
                    'Ofertas y descuentos',
                    Icons.local_offer_rounded,
                    _T.emerald,
                    _T.emeraldSurf,
                    _notifPromos,
                    (v) => setState(() => _notifPromos = v),
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
                    (v) => setState(() => _ubicacionTiempo = v),
                  ),
                  _toggleRow(
                    'Guardar historial',
                    'Rutas de paseos anteriores',
                    Icons.history_rounded,
                    _T.violet,
                    _T.violetSurf,
                    _ubicacionHistorial,
                    (v) => setState(() => _ubicacionHistorial = v),
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
                    (v) => setState(() => _biometrico = v),
                  ),
                  _toggleRow(
                    'Verificación en 2 pasos',
                    'Código por SMS al iniciar',
                    Icons.security_rounded,
                    _T.amber,
                    _T.amberSurf,
                    _dosFactores,
                    (v) => setState(() => _dosFactores = v),
                  ),
                  _accionRow(
                    Icons.lock_reset_rounded,
                    'Cambiar contraseña',
                    _T.violet,
                    _T.violetSurf,
                    () => _showCambiarPassword(),
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
                    (v) => setState(() => _darkMode = v),
                  ),
                  _accionRow(
                    Icons.language_rounded,
                    'Idioma — Español',
                    _T.teal,
                    _T.tealSurface,
                    () {},
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
                    () {},
                  ),
                  _accionRow(
                    Icons.help_outline_rounded,
                    'Centro de ayuda',
                    _T.violet,
                    _T.violetSurf,
                    () {},
                  ),
                  _accionRow(
                    Icons.info_outline_rounded,
                    'Acerca de DogGo v1.0',
                    _T.inkSub,
                    const Color(0xFFF3F4F6),
                    () => _showAcercaDe(),
                  ),
                  _accionRow(
                    Icons.delete_outline_rounded,
                    'Eliminar cuenta',
                    _T.rose,
                    _T.roseSurf,
                    () => _showEliminarCuenta(),
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

  // ── SECCIÓN CARD ───────────────────────────────────────────────────────────
  Widget _seccion({required String titulo, required List<Widget> children}) {
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

  // ── TOGGLE ROW ─────────────────────────────────────────────────────────────
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

  // ── ACCION ROW ─────────────────────────────────────────────────────────────
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
              child: Text(label, style: _ts(13.5, FontWeight.w600, _T.ink)),
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

  // ── DIALOGS ────────────────────────────────────────────────────────────────
  void _showCambiarPassword() {
    final passCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: _T.r20),
        title: Text(
          'Cambiar contraseña',
          style: _ts(17, FontWeight.w900, _T.ink),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: passCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Contraseña actual',
                labelStyle: _ts(13, FontWeight.w500, _T.inkSub),
                border: OutlineInputBorder(borderRadius: _T.r12),
                focusedBorder: OutlineInputBorder(
                  borderRadius: _T.r12,
                  borderSide: const BorderSide(color: _T.teal, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Nueva contraseña',
                labelStyle: _ts(13, FontWeight.w500, _T.inkSub),
                border: OutlineInputBorder(borderRadius: _T.r12),
                focusedBorder: OutlineInputBorder(
                  borderRadius: _T.r12,
                  borderSide: const BorderSide(color: _T.teal, width: 1.5),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: _ts(13, FontWeight.w700, _T.inkSub)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: _T.teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: _T.r12),
              elevation: 0,
            ),
            child: Text(
              'Guardar',
              style: _ts(13, FontWeight.w800, Colors.white),
            ),
          ),
        ],
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Versión 1.0.0', style: _ts(13, FontWeight.w600, _T.inkSub)),
            const SizedBox(height: 8),
            Text(
              'Conectamos dueños de perros con paseadores verificados.',
              style: _ts(13, FontWeight.w400, _T.inkSub),
            ),
            const SizedBox(height: 12),
            Text(
              'Proyecto universitario — Tecmilenio 2026',
              style: _ts(11, FontWeight.w400, _T.inkSub),
            ),
          ],
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

  void _showEliminarCuenta() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: _T.r20),
        title: Text(
          'Eliminar cuenta',
          style: _ts(17, FontWeight.w900, _T.rose),
        ),
        content: Text(
          '¿Estás seguro? Esta acción es irreversible. Se eliminarán todos tus datos, mascotas y paseos.',
          style: _ts(13, FontWeight.w400, _T.inkSub),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: _ts(13, FontWeight.w700, _T.inkSub)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: _T.rose,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: _T.r12),
              elevation: 0,
            ),
            child: Text(
              'Eliminar',
              style: _ts(13, FontWeight.w800, Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
