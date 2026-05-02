import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'config_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  DESIGN TOKENS
// ─────────────────────────────────────────────────────────────────────────────
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
  static const inkMid = Color(0xFF374151);
  static const inkSub = Color(0xFF6B7280);
  static const stroke = Color(0xFFE5E7EB);

  static const r8 = BorderRadius.all(Radius.circular(8));
  static const r10 = BorderRadius.all(Radius.circular(10));
  static const r12 = BorderRadius.all(Radius.circular(12));
  static const r16 = BorderRadius.all(Radius.circular(16));
  static const r20 = BorderRadius.all(Radius.circular(20));
  static const r24 = BorderRadius.all(Radius.circular(24));
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
//  PERFIL SCREEN — detecta tipo_usuario y muestra el perfil correcto
// ─────────────────────────────────────────────────────────────────────────────
class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});
  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();
  late final Animation<double> _fade = CurvedAnimation(
    parent: _ctrl,
    curve: Curves.easeOut,
  );
  late final Animation<Offset> _slide = Tween(
    begin: const Offset(0, .06),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

  // Simula tipo_usuario de BD: 'dueno' o 'paseador'
  // En producción esto vendrá del JWT / sesión
  String _tipoUsuario = 'dueno';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.bg,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [_appBar()],
        body: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: _tipoUsuario == 'dueno'
                ? _PerfilDueno(
                    onSwitch: () => setState(() => _tipoUsuario = 'paseador'),
                  )
                : _PerfilPaseador(
                    onSwitch: () => setState(() => _tipoUsuario = 'dueno'),
                  ),
          ),
        ),
      ),
    );
  }

  SliverAppBar _appBar() => SliverAppBar(
    pinned: true,
    backgroundColor: _tipoUsuario == 'dueno'
        ? _T.tealDeep
        : const Color(0xFF5B3FA8),
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    title: Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.15),
            borderRadius: _T.r8,
          ),
          child: Center(
            child: Text(
              _tipoUsuario == 'dueno' ? '🐾' : '👟',
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Mi Perfil',
          style: _ts(20, FontWeight.w900, Colors.white, spacing: -.4),
        ),
      ],
    ),
    actions: [
      // Switch de tipo de usuario (demo) — en prod no estaría
      GestureDetector(
        onTap: () => setState(
          () => _tipoUsuario = _tipoUsuario == 'dueno' ? 'paseador' : 'dueno',
        ),
        child: Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.18),
            borderRadius: _T.r20,
          ),
          child: Text(
            _tipoUsuario == 'dueno' ? 'Ver como Paseador' : 'Ver como Dueño',
            style: _ts(10, FontWeight.w700, Colors.white),
          ),
        ),
      ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  PERFIL DUEÑO
//  Campos BD: USUARIO(nombre, email, telefono, ciudad, fecha_registro, activo)
//             PERRO(nombre, raza, tamaño, edad_años, descripcion, necesidades_especiales)
//             PASEO(estado, precio, duracion_minutos)
// ─────────────────────────────────────────────────────────────────────────────
class _PerfilDueno extends StatefulWidget {
  final VoidCallback onSwitch;
  const _PerfilDueno({required this.onSwitch});
  @override
  State<_PerfilDueno> createState() => _PerfilDuenoState();
}

class _PerfilDuenoState extends State<_PerfilDueno> {
  bool _editMode = false;

  // Mock data — campos reales de la BD USUARIO
  final _nombreCtrl = TextEditingController(text: 'Marco Eugenio Zavala');
  final _emailCtrl = TextEditingController(text: 'marco.zavala@tecmilenio.mx');
  final _telefonoCtrl = TextEditingController(text: '+52 81 1234 5678');
  final _ciudadCtrl = TextEditingController(
    text: 'San Nicolás de los Garza, NL',
  );

  // Mock data — campos reales de la BD PERRO
  final _perros = [
    {
      'nombre': 'Hikari',
      'raza': 'Pomerania',
      'tamano': 'Pequeño',
      'edad_anos': '7',
      'descripcion': 'Muy activo y juguetón',
      'necesidades_especiales': 'Obesidad extrema — cansa rápido',
      'emoji': '🐕',
    },
    {
      'nombre': 'Rocky',
      'raza': 'Golden Retriever',
      'tamano': 'Grande',
      'edad_anos': '3',
      'descripcion': 'Amigable con todos',
      'necesidades_especiales': '',
      'emoji': '🦮',
    },
  ];

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _emailCtrl.dispose();
    _telefonoCtrl.dispose();
    _ciudadCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _avatarDueno(),
          _statsRow(),
          _infoPersonal(),
          _misPerros(),
          _historialPaseos(),
          _cuenta(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── AVATAR ──
  Widget _avatarDueno() => Container(
    width: double.infinity,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF089B7A), Color(0xFFF4F0E8)],
      ),
    ),
    child: Column(
      children: [
        const SizedBox(height: 24),
        Stack(
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0EC9A0), Color(0xFF089B7A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _T.teal.withOpacity(.40),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'MZ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            if (_editMode)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: _T.surface,
                    shape: BoxShape.circle,
                    boxShadow: _T.shadow(opacity: .12, blur: 8),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    size: 16,
                    color: _T.tealDeep,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Marco Eugenio Zavala',
          style: _ts(20, FontWeight.w900, Colors.white, spacing: -.4),
        ),
        const SizedBox(height: 4),
        // tipo_usuario badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.18),
            borderRadius: _T.r20,
          ),
          child: Text(
            'Dueño de mascotas 🐾',
            style: _ts(12, FontWeight.w600, Colors.white.withOpacity(.90)),
          ),
        ),
        const SizedBox(height: 6),
        // ciudad de BD
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.location_on_rounded,
              color: Colors.white60,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              'San Nicolás de los Garza, NL',
              style: _ts(12, FontWeight.w400, Colors.white60),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // activo badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: _T.emerald.withOpacity(.20),
            borderRadius: _T.r20,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: _T.emerald,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                'Cuenta activa',
                style: _ts(10.5, FontWeight.w700, _T.emerald),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Edit button
        GestureDetector(
          onTap: () {
            setState(() => _editMode = !_editMode);
            if (!_editMode) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Perfil actualizado ✅',
                    style: _ts(13, FontWeight.w600, Colors.white),
                  ),
                  backgroundColor: _T.teal,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: _T.r12),
                ),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
            decoration: BoxDecoration(
              color: _editMode ? Colors.white : Colors.white.withOpacity(.18),
              borderRadius: _T.r20,
              border: _editMode
                  ? null
                  : Border.all(color: Colors.white.withOpacity(.30)),
            ),
            child: Text(
              _editMode ? 'Guardar cambios' : 'Editar perfil',
              style: _ts(
                12.5,
                FontWeight.w800,
                _editMode ? _T.tealDeep : Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    ),
  );

  // ── STATS — datos de PASEO y PERRO ──
  Widget _statsRow() => Container(
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
    padding: const EdgeInsets.symmetric(vertical: 16),
    decoration: BoxDecoration(
      color: _T.surface,
      borderRadius: _T.r20,
      boxShadow: _T.shadow(opacity: .06, blur: 20, offset: const Offset(0, 6)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _statItem('2', 'Perros', '🐕'),
        _div(),
        _statItem('3', 'Paseos', '🦮'),
        _div(),
        _statItem('\$85', 'Gastado', '💰'),
        _div(),
        _statItem('4.9 ⭐', 'Rating', '🏆'),
      ],
    ),
  );

  Widget _statItem(String val, String label, String emoji) => Column(
    children: [
      Text(emoji, style: const TextStyle(fontSize: 16)),
      const SizedBox(height: 3),
      Text(val, style: _ts(13.5, FontWeight.w900, _T.ink, spacing: -.3)),
      Text(label, style: _ts(9.5, FontWeight.w500, _T.inkSub)),
    ],
  );

  Widget _div() => Container(width: 1, height: 32, color: _T.stroke);

  // ── INFO PERSONAL — campos USUARIO ──
  Widget _infoPersonal() => _card(
    margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
    child: Column(
      children: [
        _secHeader('👤 Información personal — USUARIO'),
        _fieldRow(Icons.person_rounded, 'nombre', _nombreCtrl, _T.teal),
        _divider(),
        _fieldRow(Icons.email_rounded, 'email', _emailCtrl, _T.violet),
        _divider(),
        _fieldRow(Icons.phone_rounded, 'telefono', _telefonoCtrl, _T.emerald),
        _divider(),
        _fieldRow(Icons.location_city_rounded, 'ciudad', _ciudadCtrl, _T.amber),
        _divider(),
        // fecha_registro (solo lectura)
        _staticRow(
          Icons.calendar_today_rounded,
          'fecha_registro',
          '20 Enero 2026',
          _T.inkSub,
        ),
        const SizedBox(height: 8),
      ],
    ),
  );

  // ── MIS PERROS — campos PERRO ──
  Widget _misPerros() => _card(
    margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _secHeader('🐾 Mis perros — PERRO'),
        ..._perros.map(
          (p) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: _T.tealSurface,
                        borderRadius: _T.r12,
                      ),
                      child: Center(
                        child: Text(
                          p['emoji']!,
                          style: const TextStyle(fontSize: 26),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p['nombre']!,
                            style: _ts(15, FontWeight.w800, _T.ink),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              _chip(p['raza']!, _T.teal, _T.tealSurface),
                              const SizedBox(width: 5),
                              _chip(p['tamano']!, _T.violet, _T.violetSurf),
                              const SizedBox(width: 5),
                              _chip(
                                '${p['edad_anos']} años',
                                _T.amber,
                                _T.amberSurf,
                              ),
                            ],
                          ),
                          if (p['necesidades_especiales']!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _T.amberSurf,
                                borderRadius: _T.r8,
                                border: Border.all(
                                  color: _T.amber.withOpacity(.25),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Text(
                                    '⚠️',
                                    style: TextStyle(fontSize: 10),
                                  ),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      p['necesidades_especiales']!,
                                      style: _ts(
                                        9.5,
                                        FontWeight.w700,
                                        _T.amber,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFFD1D5DB),
                      size: 22,
                    ),
                  ],
                ),
              ),
              if (_perros.indexOf(p) < _perros.length - 1)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(height: 1, color: _T.stroke),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    ),
  );

  // ── HISTORIAL PASEOS — campos PASEO ──
  Widget _historialPaseos() {
    final paseos = [
      {
        'perro': 'Hikari',
        'paseador': 'Carlos Rodríguez',
        'duracion_minutos': '45',
        'precio': '\$25.00',
        'estado': 'completado',
        'fecha': '2 May 2026',
      },
      {
        'perro': 'Rocky',
        'paseador': 'María González',
        'duracion_minutos': '60',
        'precio': '\$30.00',
        'estado': 'completado',
        'fecha': '28 Abr 2026',
      },
      {
        'perro': 'Hikari',
        'paseador': 'Carlos Rodríguez',
        'duracion_minutos': '45',
        'precio': '\$25.00',
        'estado': 'pendiente',
        'fecha': '3 May 2026',
      },
    ];
    return _card(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _secHeader('📅 Historial de paseos — PASEO'),
          ...paseos.map((p) {
            final ok = p['estado'] == 'completado';
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: ok ? _T.emeraldSurf : _T.amberSurf,
                      borderRadius: _T.r10,
                    ),
                    child: Icon(
                      ok ? Icons.check_circle_rounded : Icons.schedule_rounded,
                      color: ok ? _T.emerald : _T.amber,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${p['perro']} con ${p['paseador']}',
                          style: _ts(13, FontWeight.w700, _T.ink),
                        ),
                        Row(
                          children: [
                            Text(
                              '${p['duracion_minutos']} min · ${p['precio']} · ${p['fecha']}',
                              style: _ts(11, FontWeight.w400, _T.inkSub),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _chip(
                    p['estado']!,
                    ok ? _T.emerald : _T.amber,
                    ok ? _T.emeraldSurf : _T.amberSurf,
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── CUENTA ──
  Widget _cuenta() => _card(
    margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
    child: Column(
      children: [
        _secHeader('⚙️ Cuenta'),
        _accionRow(
          Icons.settings_rounded,
          'Configuración',
          _T.inkSub,
          const Color(0xFFF3F4F6),
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ConfigScreen()),
          ),
        ),
        _divider(),
        _accionRow(
          Icons.notifications_rounded,
          'Notificaciones',
          _T.violet,
          _T.violetSurf,
          () {},
        ),
        _divider(),
        _accionRow(
          Icons.lock_rounded,
          'Privacidad',
          _T.amber,
          _T.amberSurf,
          () {},
        ),
        _divider(),
        _accionRow(
          Icons.help_outline_rounded,
          'Ayuda y soporte',
          _T.teal,
          _T.tealSurface,
          () {},
        ),
        _divider(),
        _accionRow(
          Icons.logout_rounded,
          'Cerrar sesión',
          _T.rose,
          _T.roseSurf,
          () => _showLogout(),
        ),
        const SizedBox(height: 8),
      ],
    ),
  );

  void _showLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: _T.r20),
        title: Text('Cerrar sesión', style: _ts(17, FontWeight.w900, _T.ink)),
        content: Text(
          '¿Seguro que quieres cerrar sesión?',
          style: _ts(14, FontWeight.w400, _T.inkSub),
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
              'Cerrar sesión',
              style: _ts(13, FontWeight.w800, Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ── HELPERS ──
  Widget _card({required Widget child, required EdgeInsets margin}) =>
      Container(
        margin: margin,
        decoration: BoxDecoration(
          color: _T.surface,
          borderRadius: _T.r20,
          boxShadow: _T.shadow(
            opacity: .05,
            blur: 16,
            offset: const Offset(0, 4),
          ),
        ),
        child: child,
      );

  Widget _secHeader(String t) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
    child: Text(t, style: _ts(13.5, FontWeight.w900, _T.ink, spacing: -.2)),
  );

  Widget _divider() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Divider(height: 1, color: _T.stroke),
  );

  Widget _fieldRow(
    IconData icon,
    String label,
    TextEditingController ctrl,
    Color color,
  ) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    child: Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withOpacity(.10),
            borderRadius: _T.r10,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: _ts(10.5, FontWeight.w700, _T.inkSub)),
              const SizedBox(height: 2),
              _editMode
                  ? TextField(
                      controller: ctrl,
                      style: _ts(14, FontWeight.w600, _T.ink),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 4),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: color.withOpacity(.40)),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: color, width: 1.5),
                        ),
                      ),
                    )
                  : Text(ctrl.text, style: _ts(14, FontWeight.w600, _T.ink)),
            ],
          ),
        ),
        if (_editMode)
          Icon(Icons.edit_rounded, size: 16, color: color.withOpacity(.50)),
      ],
    ),
  );

  Widget _staticRow(IconData icon, String label, String value, Color color) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withOpacity(.10),
                borderRadius: _T.r10,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: _ts(10.5, FontWeight.w700, _T.inkSub)),
                Text(value, style: _ts(14, FontWeight.w600, _T.ink)),
              ],
            ),
          ],
        ),
      );

  Widget _accionRow(
    IconData icon,
    String label,
    Color color,
    Color surf,
    VoidCallback onTap,
  ) => GestureDetector(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: surf, borderRadius: _T.r10),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: _ts(14, FontWeight.w600, _T.ink))),
          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFFD1D5DB),
            size: 20,
          ),
        ],
      ),
    ),
  );

  Widget _chip(String label, Color fg, Color bg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(color: bg, borderRadius: _T.r8),
    child: Text(label, style: _ts(9.5, FontWeight.w700, fg)),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  PERFIL PASEADOR
//  Campos BD: PASEADOR(estado_verificacion, documento_tipo, documento_numero,
//             tarifa_por_hora, bio, zona_cobertura, calificacion_promedio,
//             fecha_verificacion, fecha_alta)
//             + USUARIO(nombre, email, telefono, ciudad)
//             + PASEO(estado, precio, duracion_minutos, fecha_hora_inicio)
//             + CALIFICACION(puntuacion, comentario, fecha_calificacion)
// ─────────────────────────────────────────────────────────────────────────────
class _PerfilPaseador extends StatefulWidget {
  final VoidCallback onSwitch;
  const _PerfilPaseador({required this.onSwitch});
  @override
  State<_PerfilPaseador> createState() => _PerfilPaseadorState();
}

class _PerfilPaseadorState extends State<_PerfilPaseador> {
  bool _editMode = false;

  // Mock data — campos USUARIO
  final _nombreCtrl = TextEditingController(text: 'Carlos Rodríguez');
  final _emailCtrl = TextEditingController(text: 'carlos.rod@gmail.com');
  final _telefonoCtrl = TextEditingController(text: '+52 81 9876 5432');
  final _ciudadCtrl = TextEditingController(text: 'Monterrey, NL');

  // Mock data — campos PASEADOR
  final _tarifaCtrl = TextEditingController(text: '120.00');
  final _bioCtrl = TextEditingController(
    text:
        'Amante de los animales con 3 años de experiencia. Me especializo en razas grandes y perros con necesidades especiales.',
  );
  final _zonaCoberturaCtrl = TextEditingController(
    text: 'Cumbres, San Nicolás, Apodaca',
  );
  final _docTipo = 'INE';
  final _docNumero = TextEditingController(text: 'ROMC950312HNLDRR09');

  // estado_verificacion de PASEADOR
  final String _estadoVerificacion = 'verificado';

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _emailCtrl.dispose();
    _telefonoCtrl.dispose();
    _ciudadCtrl.dispose();
    _tarifaCtrl.dispose();
    _bioCtrl.dispose();
    _zonaCoberturaCtrl.dispose();
    _docNumero.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _avatarPaseador(),
          _statsRow(),
          _verificacionBanner(),
          _infoPersonal(),
          _infoPaseador(),
          _calificaciones(),
          _paseoRecientes(),
          _cuenta(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── AVATAR PASEADOR ──
  Widget _avatarPaseador() => Container(
    width: double.infinity,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF5B3FA8), Color(0xFFF4F0E8)],
      ),
    ),
    child: Column(
      children: [
        const SizedBox(height: 24),
        Stack(
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C5CBF), Color(0xFF5B3FA8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C5CBF).withOpacity(.40),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'CR',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            // Verificado badge
            if (_estadoVerificacion == 'verificado')
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: _T.emerald,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.verified_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Carlos Rodríguez',
          style: _ts(20, FontWeight.w900, Colors.white, spacing: -.4),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.18),
            borderRadius: _T.r20,
          ),
          child: Text(
            'Paseador profesional 👟',
            style: _ts(12, FontWeight.w600, Colors.white.withOpacity(.90)),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.location_on_rounded,
              color: Colors.white60,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              'Monterrey, NL',
              style: _ts(12, FontWeight.w400, Colors.white60),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // calificacion_promedio
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.15),
            borderRadius: _T.r20,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('⭐', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Text(
                '4.8 · 47 calificaciones',
                style: _ts(12, FontWeight.w700, Colors.white),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () {
            setState(() => _editMode = !_editMode);
            if (!_editMode) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Perfil actualizado ✅',
                    style: _ts(13, FontWeight.w600, Colors.white),
                  ),
                  backgroundColor: const Color(0xFF7C5CBF),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: _T.r12),
                ),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
            decoration: BoxDecoration(
              color: _editMode ? Colors.white : Colors.white.withOpacity(.18),
              borderRadius: _T.r20,
              border: _editMode
                  ? null
                  : Border.all(color: Colors.white.withOpacity(.30)),
            ),
            child: Text(
              _editMode ? 'Guardar cambios' : 'Editar perfil',
              style: _ts(
                12.5,
                FontWeight.w800,
                _editMode ? const Color(0xFF5B3FA8) : Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    ),
  );

  // ── STATS — datos de PASEO y CALIFICACION ──
  Widget _statsRow() => Container(
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
    padding: const EdgeInsets.symmetric(vertical: 16),
    decoration: BoxDecoration(
      color: _T.surface,
      borderRadius: _T.r20,
      boxShadow: _T.shadow(opacity: .06, blur: 20, offset: const Offset(0, 6)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _statItem('47', 'Paseos', '🦮'),
        _div(),
        _statItem('4.8 ⭐', 'Calificación', '🏆'),
        _div(),
        _statItem('\$120', 'Tarifa/hora', '💰'),
        _div(),
        _statItem('2 años', 'Experiencia', '📅'),
      ],
    ),
  );

  Widget _statItem(String val, String label, String emoji) => Column(
    children: [
      Text(emoji, style: const TextStyle(fontSize: 16)),
      const SizedBox(height: 3),
      Text(val, style: _ts(13.5, FontWeight.w900, _T.ink, spacing: -.3)),
      Text(label, style: _ts(9.5, FontWeight.w500, _T.inkSub)),
    ],
  );

  Widget _div() => Container(width: 1, height: 32, color: _T.stroke);

  // ── VERIFICACION BANNER — estado_verificacion ──
  Widget _verificacionBanner() {
    final ok = _estadoVerificacion == 'verificado';
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ok ? _T.emeraldSurf : _T.amberSurf,
        borderRadius: _T.r16,
        border: Border.all(
          color: ok ? _T.emerald.withOpacity(.25) : _T.amber.withOpacity(.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: ok
                  ? _T.emerald.withOpacity(.15)
                  : _T.amber.withOpacity(.15),
              borderRadius: _T.r10,
            ),
            child: Icon(
              ok ? Icons.verified_rounded : Icons.pending_rounded,
              color: ok ? _T.emerald : _T.amber,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ok ? 'Paseador verificado ✅' : 'Verificación pendiente ⏳',
                  style: _ts(13.5, FontWeight.w800, ok ? _T.emerald : _T.amber),
                ),
                Text(
                  ok
                      ? 'Documento (${_docTipo}) validado por DogGo'
                      : 'Tu documento está siendo revisado',
                  style: _ts(11.5, FontWeight.w400, _T.inkSub),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── INFO PERSONAL — campos USUARIO ──
  Widget _infoPersonal() => _card(
    margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
    child: Column(
      children: [
        _secHeader('👤 Información personal — USUARIO'),
        _fieldRow(
          Icons.person_rounded,
          'nombre',
          _nombreCtrl,
          const Color(0xFF7C5CBF),
        ),
        _divider(),
        _fieldRow(Icons.email_rounded, 'email', _emailCtrl, _T.teal),
        _divider(),
        _fieldRow(Icons.phone_rounded, 'telefono', _telefonoCtrl, _T.emerald),
        _divider(),
        _fieldRow(Icons.location_city_rounded, 'ciudad', _ciudadCtrl, _T.amber),
        const SizedBox(height: 8),
      ],
    ),
  );

  // ── INFO PASEADOR — campos PASEADOR ──
  Widget _infoPaseador() => _card(
    margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
    child: Column(
      children: [
        _secHeader('👟 Datos de paseador — PASEADOR'),
        _fieldRow(
          Icons.attach_money_rounded,
          'tarifa_por_hora',
          _tarifaCtrl,
          const Color(0xFF7C5CBF),
        ),
        _divider(),
        _fieldRow(
          Icons.map_rounded,
          'zona_cobertura',
          _zonaCoberturaCtrl,
          _T.teal,
        ),
        _divider(),
        _fieldRow(Icons.edit_note_rounded, 'bio', _bioCtrl, _T.amber),
        _divider(),
        _fieldRow(
          Icons.badge_rounded,
          'documento_numero',
          _docNumero,
          _T.inkSub,
        ),
        const SizedBox(height: 8),
      ],
    ),
  );

  // ── CALIFICACIONES — campos CALIFICACION ──
  Widget _calificaciones() {
    final cals = [
      {
        'puntuacion': '5',
        'comentario':
            'Excelente paseador, Rocky llegó feliz y cansado. Lo recomiendo 100%',
        'fecha_calificacion': '1 May 2026',
        'usuario': 'Marco Z.',
      },
      {
        'puntuacion': '5',
        'comentario': 'Muy puntual y cariñoso con mi perrita Luna ❤️',
        'fecha_calificacion': '28 Abr 2026',
        'usuario': 'Ana L.',
      },
      {
        'puntuacion': '4',
        'comentario':
            'Buen servicio, llegó un poco tarde pero el paseo fue perfecto',
        'fecha_calificacion': '20 Abr 2026',
        'usuario': 'Pedro M.',
      },
    ];
    return _card(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _secHeader('⭐ Calificaciones — CALIFICACION'),
          ...cals.map(
            (c) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        c['usuario']!,
                        style: _ts(13, FontWeight.w700, _T.ink),
                      ),
                      Row(
                        children: [
                          ...List.generate(
                            int.parse(c['puntuacion']!),
                            (_) =>
                                const Text('⭐', style: TextStyle(fontSize: 12)),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            c['fecha_calificacion']!,
                            style: _ts(10.5, FontWeight.w400, _T.inkSub),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    c['comentario']!,
                    style: _ts(12, FontWeight.w400, _T.inkSub, height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (cals.indexOf(c) < cals.length - 1) ...[
                    const SizedBox(height: 10),
                    Divider(height: 1, color: _T.stroke),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── PASEOS RECIENTES — campos PASEO ──
  Widget _paseoRecientes() {
    final paseos = [
      {
        'perro': 'Rocky',
        'dueno': 'Marco Z.',
        'duracion_minutos': '60',
        'precio': '\$30',
        'estado': 'completado',
        'fecha_hora_inicio': '2 May · 10:00 AM',
      },
      {
        'perro': 'Luna',
        'dueno': 'Ana L.',
        'duracion_minutos': '45',
        'precio': '\$25',
        'estado': 'completado',
        'fecha_hora_inicio': '28 Abr · 4:30 PM',
      },
      {
        'perro': 'Max',
        'dueno': 'Pedro M.',
        'duracion_minutos': '30',
        'precio': '\$20',
        'estado': 'completado',
        'fecha_hora_inicio': '20 Abr · 9:00 AM',
      },
    ];
    return _card(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _secHeader('🦮 Paseos recientes — PASEO'),
          ...paseos.map(
            (p) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _T.violetSurf,
                      borderRadius: _T.r10,
                    ),
                    child: const Icon(
                      Icons.directions_walk_rounded,
                      color: Color(0xFF7C5CBF),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${p['perro']} · ${p['dueno']}',
                          style: _ts(13, FontWeight.w700, _T.ink),
                        ),
                        Text(
                          '${p['duracion_minutos']} min · ${p['precio']} · ${p['fecha_hora_inicio']}',
                          style: _ts(11, FontWeight.w400, _T.inkSub),
                        ),
                      ],
                    ),
                  ),
                  _chip(p['estado']!, _T.emerald, _T.emeraldSurf),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── CUENTA ──
  Widget _cuenta() => _card(
    margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
    child: Column(
      children: [
        _secHeader('⚙️ Cuenta'),
        _accionRow(
          Icons.settings_rounded,
          'Configuración',
          const Color(0xFF6B7280),
          const Color(0xFFF3F4F6),
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ConfigScreen()),
          ),
        ),
        _divider(),
        _accionRow(
          Icons.account_balance_wallet_rounded,
          'Mis pagos — PAGO',
          _T.emerald,
          _T.emeraldSurf,
          () {},
        ),
        _divider(),
        _accionRow(
          Icons.schedule_rounded,
          'Disponibilidad',
          const Color(0xFF7C5CBF),
          _T.violetSurf,
          () {},
        ),
        _divider(),
        _accionRow(
          Icons.logout_rounded,
          'Cerrar sesión',
          _T.rose,
          _T.roseSurf,
          () => _showLogout(),
        ),
        const SizedBox(height: 8),
      ],
    ),
  );

  void _showLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: _T.r20),
        title: Text('Cerrar sesión', style: _ts(17, FontWeight.w900, _T.ink)),
        content: Text(
          '¿Seguro que quieres cerrar sesión?',
          style: _ts(14, FontWeight.w400, _T.inkSub),
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
              'Cerrar sesión',
              style: _ts(13, FontWeight.w800, Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ── HELPERS ──
  Widget _card({required Widget child, required EdgeInsets margin}) =>
      Container(
        margin: margin,
        decoration: BoxDecoration(
          color: _T.surface,
          borderRadius: _T.r20,
          boxShadow: _T.shadow(
            opacity: .05,
            blur: 16,
            offset: const Offset(0, 4),
          ),
        ),
        child: child,
      );

  Widget _secHeader(String t) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
    child: Text(t, style: _ts(13.5, FontWeight.w900, _T.ink, spacing: -.2)),
  );

  Widget _divider() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Divider(height: 1, color: _T.stroke),
  );

  Widget _fieldRow(
    IconData icon,
    String label,
    TextEditingController ctrl,
    Color color,
  ) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    child: Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withOpacity(.10),
            borderRadius: _T.r10,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: _ts(10.5, FontWeight.w700, _T.inkSub)),
              const SizedBox(height: 2),
              _editMode
                  ? TextField(
                      controller: ctrl,
                      style: _ts(14, FontWeight.w600, _T.ink),
                      maxLines: label == 'bio' ? 3 : 1,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 4),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: color.withOpacity(.40)),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: color, width: 1.5),
                        ),
                      ),
                    )
                  : Text(
                      ctrl.text,
                      style: _ts(14, FontWeight.w600, _T.ink),
                      maxLines: label == 'bio' ? 3 : 1,
                      overflow: TextOverflow.ellipsis,
                    ),
            ],
          ),
        ),
        if (_editMode)
          Icon(Icons.edit_rounded, size: 16, color: color.withOpacity(.50)),
      ],
    ),
  );

  Widget _accionRow(
    IconData icon,
    String label,
    Color color,
    Color surf,
    VoidCallback onTap,
  ) => GestureDetector(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: surf, borderRadius: _T.r10),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: _ts(14, FontWeight.w600, _T.ink))),
          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFFD1D5DB),
            size: 20,
          ),
        ],
      ),
    ),
  );

  Widget _chip(String label, Color fg, Color bg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(color: bg, borderRadius: _T.r8),
    child: Text(label, style: _ts(9.5, FontWeight.w700, fg)),
  );
}
