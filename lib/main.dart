import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'perfil_screen.dart';
import 'chat_screen.dart';
import 'config_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const DogGoApp());
}

// ─────────────────────────────────────────────────────────────────────────────
//  DESIGN TOKENS
// ─────────────────────────────────────────────────────────────────────────────
class T {
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

  static List<BoxShadow> shadowColor(
    Color c, {
    double opacity = .28,
    double blur = 22,
    Offset offset = const Offset(0, 8),
  }) => [
    BoxShadow(color: c.withOpacity(opacity), blurRadius: blur, offset: offset),
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
//  DATA CLASSES
// ─────────────────────────────────────────────────────────────────────────────
class _MascotaData {
  final String nombre, raza, edad, tamano, emoji;
  final String? nota;
  const _MascotaData(
    this.nombre,
    this.raza,
    this.edad,
    this.tamano,
    this.emoji,
    this.nota,
  );
}

class _PaseoData {
  final String perro, paseador, fecha, duracion, precio, estado;
  const _PaseoData(
    this.perro,
    this.paseador,
    this.fecha,
    this.duracion,
    this.precio,
    this.estado,
  );
}

class _PillData {
  final String title, cat, emoji;
  final Color color;
  const _PillData(this.title, this.cat, this.emoji, this.color);
}

class _CurioData {
  final String raza, peso, tamano, emoji;
  const _CurioData(this.raza, this.peso, this.tamano, this.emoji);
}

class _LugarData {
  final String nombre, tipo, subtipo, emoji;
  final Color color;
  const _LugarData(
    this.nombre,
    this.tipo,
    this.subtipo,
    this.emoji,
    this.color,
  );
}

class _QuickData {
  final String title, sub, emoji;
  final Color color, surf;
  const _QuickData(this.title, this.sub, this.emoji, this.color, this.surf);
}

class _StatData {
  final String value, label, emoji;
  const _StatData(this.value, this.label, this.emoji);
}

class _TabMeta {
  final String label;
  final IconData icon, activeIcon;
  const _TabMeta(this.label, this.icon, this.activeIcon);
}

// ─────────────────────────────────────────────────────────────────────────────
//  APP ROOT
// ─────────────────────────────────────────────────────────────────────────────
class DogGoApp extends StatelessWidget {
  const DogGoApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'DogGo',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: T.teal),
      scaffoldBackgroundColor: T.bg,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
    ),
    home: const AppShell(),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  APP SHELL
// ─────────────────────────────────────────────────────────────────────────────
class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _tab = 0;

  static const _tabs = [
    _TabMeta('Inicio', Icons.house_outlined, Icons.house_rounded),
    _TabMeta('Mis perros', Icons.pets_outlined, Icons.pets_rounded),
    _TabMeta(
      'Paseos',
      Icons.directions_walk_outlined,
      Icons.directions_walk_rounded,
    ),
    _TabMeta(
      'Mensajes',
      Icons.chat_bubble_outline_rounded,
      Icons.chat_bubble_rounded,
    ),
    _TabMeta('Perfil', Icons.person_outline_rounded, Icons.person_rounded),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(
      index: _tab,
      children: [
        const HomeScreen(),
        const MisPerrosScreen(),
        const PaseosScreen(),
        MensajesScreen(),
        PerfilScreen(),
      ],
    ),
    bottomNavigationBar: _buildNav(),
  );

  Widget _buildNav() {
    return Container(
      decoration: BoxDecoration(
        color: T.surface,
        boxShadow: T.shadow(
          opacity: .06,
          blur: 28,
          offset: const Offset(0, -4),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: List.generate(_tabs.length, (i) {
              final sel = i == _tab;
              final tab = _tabs[i];
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _tab = i);
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: sel
                              ? T.teal.withOpacity(.12)
                              : Colors.transparent,
                          borderRadius: T.r12,
                        ),
                        child: Icon(
                          sel ? tab.activeIcon : tab.icon,
                          color: sel ? T.teal : T.inkSub,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 2),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: _ts(
                          9.5,
                          sel ? FontWeight.w800 : FontWeight.w500,
                          sel ? T.teal : T.inkSub,
                        ),
                        child: Text(tab.label),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  HOME SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final AnimationController _entry = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();
  late final Animation<double> _fade = CurvedAnimation(
    parent: _entry,
    curve: const Interval(0, .65, curve: Curves.easeOut),
  );
  late final Animation<Offset> _slide =
      Tween(begin: const Offset(0, .08), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _entry,
          curve: const Interval(0, .70, curve: Curves.easeOutCubic),
        ),
      );

  final PageController _pageCtrl = PageController(viewportFraction: .90);
  int _pageIdx = 0;

  final _ctrlConsejos = ScrollController();
  final _ctrlProductos = ScrollController();
  final _ctrlCurios = ScrollController();
  bool _pauseConsejos = false;
  bool _pauseProductos = false;
  bool _pauseCurios = false;
  Timer? _tConsejos, _tProductos, _tCurios;

  // ── DATA ──────────────────────────────────────────────────────────────────
  static const _mascotas = [
    _MascotaData(
      'Hikari',
      'Pomerania',
      '7 anos',
      'Pequeno',
      '🐕',
      'Obesidad extrema — se cansa rapido',
    ),
    _MascotaData('Rocky', 'Golden Retriever', '3 anos', 'Grande', '🦮', null),
  ];
  static const _paseos = [
    _PaseoData(
      'Max',
      'Carlos Rodriguez',
      'Hoy, 4:30 PM',
      '45 min',
      '\$25',
      'Confirmado',
    ),
    _PaseoData(
      'Luna',
      'Maria Gonzalez',
      'Manana, 10:00 AM',
      '60 min',
      '\$30',
      'Pendiente',
    ),
  ];
  static const _consejos = [
    _PillData('Que come tu\nperro segun talla', 'Nutricion', '🍖', T.teal),
    _PillData('Paseos diarios\npor raza y edad', 'Ejercicio', '🏃', T.violet),
    _PillData('Calendario de\nvacunacion', 'Salud', '💉', T.emerald),
    _PillData('Frecuencia de\nbano correcta', 'Higiene', '🛁', T.amber),
    _PillData('Senales de estres\nen perros', 'Comportamiento', '😰', T.rose),
    _PillData('Actividades en\ncasa con el', 'Bienestar', '❤️', T.tealDeep),
  ];
  static const _productos = [
    _PillData('Kong Classic', 'Juguete', '🦷', T.teal),
    _PillData('Cama ortopedica', 'Descanso', '🛏️', T.violet),
    _PillData('Arnes antipull', 'Paseo', '🦺', T.emerald),
    _PillData('Snacks deshidratados', 'Nutricion', '🥩', T.amber),
    _PillData('Shampoo hipoalergenico', 'Higiene', '🧴', T.rose),
    _PillData('Comedero automatico', 'Gadget', '🤖', T.tealDeep),
  ];
  static const _curios = [
    _CurioData('Golden Retriever', '25-34 kg', 'Grande', '🦮'),
    _CurioData('Poodle', '20-32 kg', 'Grande', '🐩'),
    _CurioData('Labrador Retriever', '25-36 kg', 'Grande', '🐕'),
    _CurioData('French Bulldog', '8-14 kg', 'Pequeno', '🐶'),
    _CurioData('Pastor Aleman', '22-40 kg', 'Grande', '🐕‍🦺'),
    _CurioData('Beagle', '9-11 kg', 'Mediano', '🐕'),
  ];
  static const _lugares = [
    _LugarData(
      'Hospital Veterinario Mascota Feliz',
      'Veterinaria',
      '24 horas',
      '🏥',
      T.rose,
    ),
    _LugarData(
      'Parque Canino Espana',
      'Parque',
      'Dog friendly',
      '🌳',
      T.emerald,
    ),
    _LugarData('PetCo Cumbres', 'Tienda', 'Grooming', '🛒', T.violet),
    _LugarData('Adopta Nuevo Leon', 'Adopcion', 'Rescate', '🐾', T.amber),
  ];
  static const _quickItems = [
    _QuickData(
      'Mis perros',
      'Administra tus mascotas',
      '🐕',
      T.violet,
      T.violetSurf,
    ),
    _QuickData(
      'Paseadores',
      'Busca paseadores disponibles',
      '👟',
      T.teal,
      T.tealSurface,
    ),
    _QuickData(
      'Mensajes',
      'Chats con paseadores',
      '💬',
      T.emerald,
      T.emeraldSurf,
    ),
    _QuickData(
      'Configuracion',
      'Preferencias y seguridad',
      '⚙️',
      T.inkSub,
      Color(0xFFF3F4F6),
    ),
  ];
  static const _ctaItems = [
    _QuickData(
      'Ver mis paseos',
      'Activos e historial',
      '🐕',
      T.teal,
      T.tealSurface,
    ),
    _QuickData(
      'Buscar paseador',
      'Encuentra el perfecto',
      '🔍',
      T.violet,
      T.violetSurf,
    ),
    _QuickData(
      'Mis perros',
      'Perfiles y datos',
      '🐾',
      T.emerald,
      T.emeraldSurf,
    ),
    _QuickData('Mi perfil', 'Foto y direccion', '👤', T.amber, T.amberSurf),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _auto(_ctrlConsejos, () => _pauseConsejos, .55, (t) => _tConsejos = t);
      _auto(_ctrlProductos, () => _pauseProductos, .60, (t) => _tProductos = t);
      _auto(_ctrlCurios, () => _pauseCurios, .50, (t) => _tCurios = t);
    });
  }

  // Auto-scroll infinito real — items triplicados + salto invisible
  void _auto(
    ScrollController c,
    bool Function() paused,
    double spd,
    void Function(Timer) set,
  ) {
    final t = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!mounted || paused() || !c.hasClients) return;
      final max = c.position.maxScrollExtent;
      if (max > 0 && c.offset >= max * 0.75) {
        c.jumpTo(max * 0.25);
      } else {
        c.jumpTo(c.offset + spd);
      }
    });
    set(t);
  }

  @override
  void dispose() {
    _entry.dispose();
    _pageCtrl.dispose();
    _ctrlConsejos.dispose();
    _ctrlProductos.dispose();
    _ctrlCurios.dispose();
    _tConsejos?.cancel();
    _tProductos?.cancel();
    _tCurios?.cancel();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: T.bg,
    body: NestedScrollView(
      headerSliverBuilder: (_, __) => [_appBar()],
      body: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _heroBanner(),
                _statsRibbon(),
                _sec('Tus mascotas 🐾', action: 'Ver todas'),
                _mascotaCarousel(),
                _sec('Proximos paseos 📅', action: 'Ver todos'),
                _paseoCards(),
                _sec('Accesos rapidos ⚡'),
                _quickAccess(),
                _sec(
                  'Cuidado y bienestar 💡',
                  sub: 'Consejos para tu mejor amigo',
                ),
                _autoRow(
                  _ctrlConsejos,
                  (v) => setState(() => _pauseConsejos = v),
                  _consejos,
                  162,
                  (d) => _consejoCard(d as _PillData),
                ),
                _sec(
                  'Productos recomendados 🛍️',
                  sub: 'Lo que los duenos de DogGo usan',
                ),
                _autoRow(
                  _ctrlProductos,
                  (v) => setState(() => _pauseProductos = v),
                  _productos,
                  170,
                  (d) => _productoCard(d as _PillData),
                ),
                _sec('Cerca de ti 📍', sub: 'Monterrey y Area Metro'),
                _lugarGrid(),
                _sec('Sabias que? 🧬', sub: 'Curiosidades de razas populares'),
                _autoRow(
                  _ctrlCurios,
                  (v) => setState(() => _pauseCurios = v),
                  _curios,
                  110,
                  (d) => _curioCard(d as _CurioData),
                ),
                _ctaBlock(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  // ── APP BAR ──────────────────────────────────────────────────────────────
  SliverAppBar _appBar() => SliverAppBar(
    pinned: true,
    floating: true,
    snap: true,
    backgroundColor: T.tealDeep,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    title: Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.15),
            borderRadius: T.r8,
          ),
          child: const Center(
            child: Text('🐾', style: TextStyle(fontSize: 18)),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'DogGo',
          style: _ts(21, FontWeight.w900, Colors.white, spacing: -.6),
        ),
      ],
    ),
    actions: [
      // Notificaciones
      Stack(
        children: [
          IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              color: Colors.white,
              size: 25,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'No tienes notificaciones nuevas',
                    style: _ts(13, FontWeight.w600, Colors.white),
                  ),
                  backgroundColor: T.teal,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: T.r12),
                ),
              );
            },
          ),
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFFEF4444),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
      // Perfil
      IconButton(
        icon: const Icon(
          Icons.person_outline_rounded,
          color: Colors.white,
          size: 25,
        ),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PerfilScreen()),
        ),
      ),
      const SizedBox(width: 4),
    ],
  );

  // ── HERO BANNER ───────────────────────────────────────────────────────────
  Widget _heroBanner() => Container(
    margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0EC9A0), Color(0xFF057A5F)],
      ),
      borderRadius: T.r24,
      boxShadow: T.shadowColor(
        T.teal,
        opacity: .32,
        blur: 30,
        offset: const Offset(0, 12),
      ),
    ),
    child: Stack(
      children: [
        Positioned(top: -36, right: -36, child: _blob(160, .06)),
        Positioned(bottom: -24, right: 48, child: _blob(80, .07)),
        Positioned(top: 30, right: 30, child: _blob(44, .10)),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.18),
                  borderRadius: T.r32,
                  border: Border.all(color: Colors.white.withOpacity(.22)),
                ),
                child: Text(
                  'BIENVENIDO DE VUELTA',
                  style: _ts(9.5, FontWeight.w800, Colors.white, spacing: 1.5),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Hola, Marco.',
                style: _ts(
                  30,
                  FontWeight.w900,
                  Colors.white,
                  spacing: -.8,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Como estan\ntus peludos hoy?',
                style: _ts(
                  18,
                  FontWeight.w300,
                  Colors.white.withOpacity(.92),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Todo lo que necesitas para cuidar\na tus mascotas esta aqui.',
                style: _ts(
                  12.5,
                  FontWeight.w400,
                  Colors.white.withOpacity(.60),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _HeroBtn(
                    label: 'Buscar paseador',
                    primary: true,
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Proximamente 🚀',
                          style: _ts(13, FontWeight.w600, Colors.white),
                        ),
                        backgroundColor: T.teal,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: T.r12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  _HeroBtn(label: 'Mis paseos', primary: false, onTap: () {}),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _blob(double size, double op) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(op),
      shape: BoxShape.circle,
    ),
  );

  // ── STATS RIBBON ──────────────────────────────────────────────────────────
  Widget _statsRibbon() {
    const stats = [
      _StatData('6', 'Mascotas', '🐕'),
      _StatData('3', 'Paseos', '✅'),
      _StatData('Hikari', 'Ultimo', '📅'),
      _StatData('—', 'Activos', '⏳'),
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0EC9A0), Color(0xFF0AA882)],
        ),
        borderRadius: T.r20,
        boxShadow: T.shadowColor(
          T.teal,
          opacity: .20,
          blur: 20,
          offset: const Offset(0, 6),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (int i = 0; i < stats.length; i++) ...[
            if (i > 0)
              Container(
                width: 1,
                height: 32,
                color: Colors.white.withOpacity(.20),
              ),
            _StatTile(stats[i]),
          ],
        ],
      ),
    );
  }

  // ── SECTION LABEL ─────────────────────────────────────────────────────────
  Widget _sec(String title, {String? action, String? sub}) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 26, 16, 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: _ts(17, FontWeight.w900, T.ink, spacing: -.3)),
            if (action != null)
              GestureDetector(
                onTap: () {},
                child: Text(
                  action,
                  style: _ts(12.5, FontWeight.w700, T.tealMid),
                ),
              ),
          ],
        ),
        if (sub != null) ...[
          const SizedBox(height: 3),
          Text(sub, style: _ts(12.5, FontWeight.w400, T.inkSub)),
        ],
      ],
    ),
  );

  // ── MASCOTA CAROUSEL ──────────────────────────────────────────────────────
  Widget _mascotaCarousel() => Column(
    children: [
      SizedBox(
        height: 150,
        child: PageView.builder(
          controller: _pageCtrl,
          onPageChanged: (i) => setState(() => _pageIdx = i),
          itemCount: _mascotas.length + 1,
          itemBuilder: (_, i) => i < _mascotas.length
              ? _mascotaCard(_mascotas[i])
              : _addMascotaCard(),
        ),
      ),
      const SizedBox(height: 10),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_mascotas.length + 1, (i) {
          final sel = i == _pageIdx;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: sel ? 24 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: sel ? T.teal : T.stroke,
              borderRadius: T.r32,
            ),
          );
        }),
      ),
    ],
  );

  Widget _mascotaCard(_MascotaData m) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 8),
    decoration: BoxDecoration(
      color: T.surface,
      borderRadius: T.r20,
      boxShadow: T.shadow(opacity: .055, blur: 18, offset: const Offset(0, 6)),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: T.tealSurface,
              borderRadius: T.r16,
            ),
            child: Center(
              child: Text(m.emoji, style: const TextStyle(fontSize: 38)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  m.nombre,
                  style: _ts(17.5, FontWeight.w900, T.ink, spacing: -.3),
                ),
                const SizedBox(height: 1),
                Text(m.raza, style: _ts(12.5, FontWeight.w500, T.inkSub)),
                const SizedBox(height: 9),
                Row(
                  children: [
                    _Chip(m.edad, T.teal, T.tealSurface),
                    const SizedBox(width: 5),
                    _Chip(m.tamano, T.violet, T.violetSurf),
                  ],
                ),
                if (m.nota != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: T.amberSurf,
                      borderRadius: T.r8,
                      border: Border.all(color: T.amber.withOpacity(.25)),
                    ),
                    child: Row(
                      children: [
                        const Text('⚠️', style: TextStyle(fontSize: 10)),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            m.nota!,
                            style: _ts(9.5, FontWeight.w700, T.amber),
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
        ],
      ),
    ),
  );

  Widget _addMascotaCard() => GestureDetector(
    onTap: () {},
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: T.surface,
        borderRadius: T.r20,
        border: Border.all(color: T.teal.withOpacity(.25), width: 1.6),
        boxShadow: T.shadow(opacity: .04),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: T.tealSurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add_rounded, color: T.teal, size: 26),
          ),
          const SizedBox(height: 10),
          Text('Anadir mascota', style: _ts(14, FontWeight.w800, T.teal)),
          const SizedBox(height: 3),
          Text(
            'Registrar nueva mascota',
            style: _ts(11, FontWeight.w400, T.inkSub),
          ),
        ],
      ),
    ),
  );

  // ── PASEO CARDS ───────────────────────────────────────────────────────────
  Widget _paseoCards() => ListView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    padding: const EdgeInsets.symmetric(horizontal: 16),
    itemCount: _paseos.length,
    itemBuilder: (_, i) => _paseoCard(_paseos[i], i),
  );

  Widget _paseoCard(_PaseoData p, int delay) {
    final ok = p.estado == 'Confirmado';
    final col = ok ? T.emerald : T.amber;
    final bg = ok ? T.emeraldSurf : T.amberSurf;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 380 + delay * 120),
      curve: Curves.easeOutCubic,
      builder: (_, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - v)),
          child: child,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: T.surface,
          borderRadius: T.r20,
          boxShadow: T.shadow(
            opacity: .055,
            blur: 16,
            offset: const Offset(0, 5),
          ),
        ),
        child: Column(
          children: [
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: col,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        p.perro,
                        style: _ts(17, FontWeight.w900, T.ink, spacing: -.3),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: T.r32,
                          border: Border.all(color: col.withOpacity(.28)),
                        ),
                        child: Text(
                          p.estado,
                          style: _ts(11, FontWeight.w800, col),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Paseador: ${p.paseador}',
                    style: _ts(12.5, FontWeight.w500, T.inkSub),
                  ),
                  const SizedBox(height: 11),
                  Wrap(
                    spacing: 8,
                    children: [
                      _InfoPill('📅', p.fecha),
                      _InfoPill('⏱️', p.duracion),
                      _InfoPill('💰', p.precio),
                    ],
                  ),
                  const SizedBox(height: 13),
                  Row(
                    children: [
                      Expanded(
                        child: _OutBtn(label: 'Detalles', onTap: () {}),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _FillBtn(
                          label: 'Chat',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => MensajesScreen()),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── QUICK ACCESS ──────────────────────────────────────────────────────────
  Widget _quickAccess() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Column(
      children: List.generate(_quickItems.length, (i) {
        final a = _quickItems[i];
        return GestureDetector(
          onTap: () {
            // Navega segun el item
            if (i == 0) {
              // Mis perros -> tab 1
              final shell = context.findAncestorStateOfType<_AppShellState>();
              shell?.setState(() => shell._tab = 1);
            } else if (i == 1) {
              // Paseadores -> proximamente
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Paseadores - Proximamente 🚀',
                    style: _ts(13, FontWeight.w600, Colors.white),
                  ),
                  backgroundColor: T.teal,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: T.r12),
                ),
              );
            } else if (i == 2) {
              // Mensajes -> tab 3
              final shell = context.findAncestorStateOfType<_AppShellState>();
              shell?.setState(() => shell._tab = 3);
            } else if (i == 3) {
              // Configuracion
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ConfigScreen()),
              );
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: T.surface,
              borderRadius: T.r16,
              boxShadow: T.shadow(
                opacity: .04,
                blur: 12,
                offset: const Offset(0, 3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: a.surf, borderRadius: T.r12),
                  child: Center(
                    child: Text(a.emoji, style: const TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.title, style: _ts(14.5, FontWeight.w800, T.ink)),
                      Text(a.sub, style: _ts(11.5, FontWeight.w400, T.inkSub)),
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
        );
      }),
    ),
  );

  // ── AUTO SCROLL ROW ───────────────────────────────────────────────────────
  Widget _autoRow(
    ScrollController ctrl,
    void Function(bool) onPause,
    List<dynamic> items,
    double height,
    Widget Function(dynamic) build,
  ) => SizedBox(
    height: height,
    child: NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n is ScrollStartNotification && n.dragDetails != null)
          onPause(true);
        if (n is ScrollEndNotification) {
          Future.delayed(const Duration(seconds: 2), () => onPause(false));
        }
        return false;
      },
      child: ListView.builder(
        controller: ctrl,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        // Triplicados para scroll infinito suave
        itemCount: items.length * 3,
        itemBuilder: (_, i) => build(items[i % items.length]),
      ),
    ),
  );

  Widget _consejoCard(_PillData c) => GestureDetector(
    onTap: () {},
    child: Container(
      width: 148,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: T.surface,
        borderRadius: T.r20,
        boxShadow: T.shadow(
          opacity: .055,
          blur: 14,
          offset: const Offset(0, 4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: c.color.withOpacity(.10),
                borderRadius: T.r8,
              ),
              child: Text(c.cat, style: _ts(9.5, FontWeight.w800, c.color)),
            ),
            const SizedBox(height: 10),
            Text(c.emoji, style: const TextStyle(fontSize: 30)),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                c.title,
                style: _ts(12, FontWeight.w800, T.ink, height: 1.4),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _productoCard(_PillData p) => GestureDetector(
    onTap: () {},
    child: Container(
      width: 144,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: T.surface,
        borderRadius: T.r20,
        boxShadow: T.shadow(
          opacity: .055,
          blur: 14,
          offset: const Offset(0, 4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(p.emoji, style: const TextStyle(fontSize: 30)),
            const SizedBox(height: 9),
            _Chip(p.cat, p.color, p.color.withOpacity(.10)),
            const SizedBox(height: 7),
            Expanded(
              child: Text(
                p.title,
                style: _ts(12.5, FontWeight.w800, T.ink, height: 1.3),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Text('🛒', style: TextStyle(fontSize: 11)),
                const SizedBox(width: 5),
                Text(
                  'Ver en Amazon',
                  style: _ts(10.5, FontWeight.w700, T.tealMid),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  Widget _curioCard(_CurioData c) => GestureDetector(
    onTap: () {},
    child: Container(
      width: 126,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: T.surface,
        borderRadius: T.r16,
        boxShadow: T.shadow(opacity: .05, blur: 12, offset: const Offset(0, 3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(c.emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 6),
            Text(
              c.raza,
              style: _ts(11, FontWeight.w800, T.ink),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              '${c.peso} - ${c.tamano}',
              style: _ts(9.5, FontWeight.w400, T.inkSub),
            ),
          ],
        ),
      ),
    ),
  );

  // ── LUGAR GRID ────────────────────────────────────────────────────────────
  Widget _lugarGrid() => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    padding: const EdgeInsets.symmetric(horizontal: 16),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.62,
    ),
    itemCount: _lugares.length,
    itemBuilder: (_, i) {
      final l = _lugares[i];
      return GestureDetector(
        onTap: () {},
        child: Container(
          decoration: BoxDecoration(
            color: T.surface,
            borderRadius: T.r16,
            boxShadow: T.shadow(
              opacity: .05,
              blur: 12,
              offset: const Offset(0, 3),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: l.color.withOpacity(.10),
                        borderRadius: T.r8,
                      ),
                      child: Text(
                        l.emoji,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const Spacer(),
                    Text('Ver mapa', style: _ts(9, FontWeight.w700, T.tealMid)),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Text(
                    l.nombre,
                    style: _ts(11.5, FontWeight.w800, T.ink, height: 1.25),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    _Chip(
                      l.tipo,
                      l.color,
                      l.color.withOpacity(.10),
                      small: true,
                    ),
                    const SizedBox(width: 5),
                    _Chip(
                      l.subtipo,
                      T.inkSub,
                      const Color(0xFFF3F4F6),
                      small: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );

  // ── CTA BLOCK ─────────────────────────────────────────────────────────────
  Widget _ctaBlock() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: T.tealSurface,
            borderRadius: T.r16,
            border: Border.all(color: T.teal.withOpacity(.15)),
          ),
          child: Column(
            children: [
              Text(
                'TODO LISTO PARA TI 🚀',
                style: _ts(9.5, FontWeight.w900, T.tealMid, spacing: 1.4),
              ),
              const SizedBox(height: 5),
              Text(
                'Prueba nuestros servicios hoy',
                style: _ts(17, FontWeight.w900, T.ink, spacing: -.3),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 2.1,
          children: List.generate(_ctaItems.length, (i) {
            final s = _ctaItems[i];
            return GestureDetector(
              onTap: () {
                if (i == 0) {
                  final shell = context
                      .findAncestorStateOfType<_AppShellState>();
                  shell?.setState(() => shell._tab = 2);
                } else if (i == 1) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Paseadores - Proximamente 🚀',
                        style: _ts(13, FontWeight.w600, Colors.white),
                      ),
                      backgroundColor: T.teal,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: T.r12),
                    ),
                  );
                } else if (i == 2) {
                  final shell = context
                      .findAncestorStateOfType<_AppShellState>();
                  shell?.setState(() => shell._tab = 1);
                } else if (i == 3) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PerfilScreen()),
                  );
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: T.surface,
                  borderRadius: T.r16,
                  boxShadow: T.shadow(
                    opacity: .04,
                    blur: 10,
                    offset: const Offset(0, 3),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: s.surf,
                          borderRadius: T.r10,
                        ),
                        child: Center(
                          child: Text(
                            s.emoji,
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              s.title,
                              style: _ts(11.5, FontWeight.w800, T.ink),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              s.sub,
                              style: _ts(9.5, FontWeight.w400, T.inkSub),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────────────────
class _HeroBtn extends StatelessWidget {
  final String label;
  final bool primary;
  final VoidCallback onTap;
  const _HeroBtn({
    required this.label,
    required this.primary,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 11),
      decoration: BoxDecoration(
        color: primary ? Colors.white : Colors.white.withOpacity(.16),
        borderRadius: T.r12,
        border: primary
            ? null
            : Border.all(color: Colors.white.withOpacity(.30)),
      ),
      child: Text(
        label,
        style: _ts(12.5, FontWeight.w800, primary ? T.tealDeep : Colors.white),
      ),
    ),
  );
}

class _StatTile extends StatelessWidget {
  final _StatData d;
  const _StatTile(this.d);
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(d.emoji, style: const TextStyle(fontSize: 18)),
      const SizedBox(height: 4),
      Text(
        d.value,
        style: _ts(15, FontWeight.w900, Colors.white, spacing: -.3),
      ),
      Text(
        d.label,
        style: _ts(9.5, FontWeight.w500, Colors.white.withOpacity(.65)),
      ),
    ],
  );
}

class _Chip extends StatelessWidget {
  final String label;
  final Color fg, bg;
  final bool small;
  const _Chip(this.label, this.fg, this.bg, {this.small = false});
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(
      horizontal: small ? 6 : 8,
      vertical: small ? 2 : 3,
    ),
    decoration: BoxDecoration(color: bg, borderRadius: T.r8),
    child: Text(label, style: _ts(small ? 9 : 10.5, FontWeight.w800, fg)),
  );
}

class _InfoPill extends StatelessWidget {
  final String icon, label;
  const _InfoPill(this.icon, this.label);
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(icon, style: const TextStyle(fontSize: 12)),
      const SizedBox(width: 3),
      Text(label, style: _ts(11.5, FontWeight.w500, T.inkMid)),
    ],
  );
}

class _OutBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _OutBtn({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onTap,
    style: OutlinedButton.styleFrom(
      foregroundColor: T.teal,
      side: const BorderSide(color: T.teal, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: T.r12),
      padding: const EdgeInsets.symmetric(vertical: 12),
    ),
    child: Text(label, style: _ts(13, FontWeight.w800, T.teal)),
  );
}

class _FillBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _FillBtn({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => ElevatedButton(
    onPressed: onTap,
    style: ElevatedButton.styleFrom(
      backgroundColor: T.teal,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: T.r12),
      padding: const EdgeInsets.symmetric(vertical: 12),
      elevation: 0,
    ),
    child: Text(label, style: _ts(13, FontWeight.w800, Colors.white)),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  PANTALLAS STUB (otros integrantes)
// ─────────────────────────────────────────────────────────────────────────────
class MisPerrosScreen extends StatelessWidget {
  const MisPerrosScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: T.bg,
    appBar: AppBar(
      backgroundColor: T.violet,
      elevation: 0,
      title: Text('Mis Perros', style: _ts(19, FontWeight.w900, Colors.white)),
    ),
    body: const Center(child: Text('En desarrollo - Mis Perros')),
  );
}

class PaseosScreen extends StatelessWidget {
  const PaseosScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: T.bg,
    appBar: AppBar(
      backgroundColor: T.amber,
      elevation: 0,
      title: Text('Paseos', style: _ts(19, FontWeight.w900, Colors.white)),
    ),
    body: const Center(child: Text('En desarrollo - Paseos')),
  );
}
