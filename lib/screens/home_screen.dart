import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/session_service.dart';
import 'login_screen.dart';
import 'mis_perros_screen.dart';
import 'mis_paseos_screen.dart';
import 'notificaciones_screen.dart';
import 'paseadores_screen.dart';
import 'perfil_usuario_screen.dart';

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

  static const blue = Color(0xFF2563EB);
  static const blueSurf = Color(0xFFEFF6FF);

  static const bg = Color(0xFFF4F0E8);
  static const surface = Colors.white;
  static const ink = Color(0xFF111827);
  static const inkSub = Color(0xFF6B7280);
  static const stroke = Color(0xFFE5E7EB);

  static List<BoxShadow> shadow({
    double opacity = .055,
    double blur = 16,
    Offset offset = const Offset(0, 5),
  }) {
    return [
      BoxShadow(
        color: Colors.black.withOpacity(opacity),
        blurRadius: blur,
        offset: offset,
      ),
    ];
  }
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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController(viewportFraction: .90);

  bool _cargando = true;
  String _nombre = 'Usuario';
  String _rol = 'Usuario';
  int _paginaActual = 0;
  Timer? _timerCarrusel;

  final List<_HeroSlideData> _slides = const [
    _HeroSlideData(
      etiqueta: 'Paseos seguros',
      titulo: 'Encuentra paseadores confiables',
      subtitulo: 'Agenda, chatea y revisa el avance del paseo desde DogGo.',
      emoji: '🦮',
      color1: Color(0xFF0EC9A0),
      color2: Color(0xFF057A5F),
    ),
    _HeroSlideData(
      etiqueta: 'Tus mascotas',
      titulo: 'Cuida el perfil de tus perros',
      subtitulo: 'Mantén datos, fotos y detalles importantes actualizados.',
      emoji: '🐶',
      color1: Color(0xFF7C5CBF),
      color2: Color(0xFF4C2E91),
    ),
    _HeroSlideData(
      etiqueta: 'Seguimiento',
      titulo: 'Mapa, chat y evidencias',
      subtitulo: 'Consulta ubicación, fotos de inicio/fin y mensajes del paseo.',
      emoji: '📍',
      color1: Color(0xFFFFAB2E),
      color2: Color(0xFFD97706),
    ),
  ];

  final List<_TipData> _tips = const [
    _TipData(
      emoji: '🍖',
      title: 'Nutrición',
      subtitle: 'Comida según talla y edad',
      detail:
          'La cantidad de alimento depende del peso, edad y actividad. Un perro activo suele requerir más energía que uno sedentario.',
      color: _T.teal,
      surface: _T.tealSurface,
    ),
    _TipData(
      emoji: '🏃',
      title: 'Ejercicio',
      subtitle: 'Paseos diarios por raza',
      detail:
          'Los perros con mucha energía necesitan paseos más largos y juegos. Razas pequeñas también requieren actividad diaria.',
      color: _T.violet,
      surface: _T.violetSurf,
    ),
    _TipData(
      emoji: '💉',
      title: 'Salud',
      subtitle: 'Vacunas y revisiones',
      detail:
          'Las revisiones veterinarias ayudan a detectar problemas antes de que se vuelvan graves. Mantén al día vacunas y desparasitación.',
      color: _T.emerald,
      surface: _T.emeraldSurf,
    ),
    _TipData(
      emoji: '🛁',
      title: 'Higiene',
      subtitle: 'Baño y cepillado',
      detail:
          'El cepillado frecuente reduce nudos, caída de pelo y suciedad. La frecuencia de baño depende del pelaje y actividad.',
      color: _T.amber,
      surface: _T.amberSurf,
    ),
  ];

  final List<_TipData> _curiosidades = const [
    _TipData(
      emoji: '🦮',
      title: 'Golden Retriever',
      subtitle: '25–34 kg · Grande',
      detail:
          'Suelen ser sociables, inteligentes y activos. Necesitan ejercicio constante y convivencia para mantenerse equilibrados.',
      color: _T.amber,
      surface: _T.amberSurf,
    ),
    _TipData(
      emoji: '🐩',
      title: 'Poodle',
      subtitle: 'Tamaños variados',
      detail:
          'Son muy inteligentes y aprenden rápido. Requieren cepillado frecuente y estimulación mental.',
      color: _T.violet,
      surface: _T.violetSurf,
    ),
    _TipData(
      emoji: '🐶',
      title: 'French Bulldog',
      subtitle: '8–14 kg · Pequeño',
      detail:
          'Son perros de compañía, pero pueden ser sensibles al calor. Conviene evitar ejercicio intenso en horas calurosas.',
      color: _T.rose,
      surface: _T.roseSurf,
    ),
    _TipData(
      emoji: '🐕‍🦺',
      title: 'Pastor Alemán',
      subtitle: '22–40 kg · Grande',
      detail:
          'Es una raza activa, protectora y muy entrenable. Necesita ejercicio, obediencia y socialización.',
      color: _T.emerald,
      surface: _T.emeraldSurf,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _cargarSesion();
    _iniciarCarrusel();
  }

  @override
  void dispose() {
    _timerCarrusel?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _iniciarCarrusel() {
    _timerCarrusel?.cancel();

    _timerCarrusel = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_pageController.hasClients) return;

      final siguiente = (_paginaActual + 1) % _slides.length;

      _pageController.animateToPage(
        siguiente,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _cargarSesion() async {
    final nombre = await SessionService.obtenerNombre();
    final rol = await SessionService.obtenerRol();

    if (!mounted) return;

    setState(() {
      _nombre =
          nombre != null && nombre.trim().isNotEmpty ? nombre.trim() : 'Usuario';
      _rol = _rolBonito(rol);
      _cargando = false;
    });
  }

  String _rolBonito(String? rol) {
    final value = rol?.trim().toLowerCase() ?? '';

    if (value == 'duenio' || value == 'dueño' || value == 'cliente') {
      return 'Dueño';
    }

    if (value == 'paseador') {
      return 'Paseador';
    }

    if (value == 'admin' || value == 'administrador') {
      return 'Admin';
    }

    return rol?.trim().isNotEmpty == true ? rol!.trim() : 'Usuario';
  }

  bool get _esDuenio {
    final value = _rol.toLowerCase();
    return value == 'dueño' || value == 'duenio' || value == 'cliente';
  }

  bool get _esPaseador {
    return _rol.toLowerCase() == 'paseador';
  }

  bool get _esAdmin {
    return _rol.toLowerCase() == 'admin' || _rol.toLowerCase() == 'administrador';
  }

  Future<void> _abrir(Widget screen) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );

    if (mounted) {
      await _cargarSesion();
    }
  }

  Future<void> _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Cerrar sesión'),
          content: const Text('¿Seguro que quieres salir de tu cuenta?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: _T.rose,
                foregroundColor: Colors.white,
              ),
              child: const Text('Salir'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    await SessionService.cerrarSesion();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _abrirLugarReal(String busqueda) async {
    String query = busqueda;

    try {
      var permiso = await Geolocator.checkPermission();

      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }

      if (permiso != LocationPermission.denied &&
          permiso != LocationPermission.deniedForever) {
        final posicion = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
        );

        query =
            '$busqueda cerca de ${posicion.latitude},${posicion.longitude}';
      }
    } catch (_) {
      query = '$busqueda cerca de mí';
    }

    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}',
    );

    final ok = await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    );

    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir el mapa.'),
        ),
      );
    }
  }

  void _mostrarDetalleTip(_TipData item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _T.surface,
              borderRadius: BorderRadius.circular(26),
              boxShadow: _T.shadow(
                opacity: .14,
                blur: 24,
                offset: const Offset(0, 8),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: _T.stroke,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    color: item.surface,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Center(
                    child: Text(
                      item.emoji,
                      style: const TextStyle(fontSize: 34),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  item.title,
                  textAlign: TextAlign.center,
                  style: _ts(22, FontWeight.w900, _T.ink, spacing: -.4),
                ),
                const SizedBox(height: 6),
                Text(
                  item.subtitle,
                  textAlign: TextAlign.center,
                  style: _ts(13, FontWeight.w700, item.color),
                ),
                const SizedBox(height: 14),
                Text(
                  item.detail,
                  textAlign: TextAlign.center,
                  style: _ts(14, FontWeight.w500, _T.inkSub, height: 1.4),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: item.color,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    child: const Text('Entendido'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<_QuickItemData> _quickItems() {
    final items = <_QuickItemData>[];

    if (_esDuenio || _esAdmin) {
      items.add(
        _QuickItemData(
          emoji: '👟',
          title: 'Paseadores',
          subtitle: 'Busca paseadores disponibles',
          color: _T.teal,
          surface: _T.tealSurface,
          onTap: () => _abrir(const PaseadoresScreen()),
        ),
      );

      items.add(
        _QuickItemData(
          emoji: '🐕',
          title: 'Mis perros',
          subtitle: 'Consulta y edita tus mascotas',
          color: _T.violet,
          surface: _T.violetSurf,
          onTap: () => _abrir(const MisPerrosScreen()),
        ),
      );
    }

    items.add(
      _QuickItemData(
        emoji: '🦮',
        title: 'Mis paseos',
        subtitle: _esPaseador
            ? 'Solicitudes, paseos activos y evidencias'
            : 'Solicitudes, estados, mapa y chat',
        color: _T.amber,
        surface: _T.amberSurf,
        onTap: () => _abrir(const MisPaseosScreen()),
      ),
    );

    items.add(
      _QuickItemData(
        emoji: '👤',
        title: 'Perfil',
        subtitle: 'Tu cuenta y datos personales',
        color: _T.blue,
        surface: _T.blueSurf,
        onTap: () => _abrir(const PerfilUsuarioScreen()),
      ),
    );

    return items;
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(
        backgroundColor: _T.bg,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _T.bg,
      appBar: AppBar(
        backgroundColor: _T.tealDeep,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  '🐾',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'DogGo',
              style: _ts(
                21,
                FontWeight.w900,
                Colors.white,
                spacing: -.5,
              ),
            ),
          ],
        ),
        actions: [
          _TopIconButton(
            icon: Icons.notifications_outlined,
            badge: false,
            onTap: () => _abrir(const NotificacionesScreen()),
          ),
          _TopIconButton(
            icon: Icons.person_outline_rounded,
            badge: false,
            onTap: () => _abrir(const PerfilUsuarioScreen()),
          ),
          const SizedBox(width: 6),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        esDuenio: _esDuenio || _esAdmin,
        onHome: () {},
        onPaseadores: () => _abrir(const PaseadoresScreen()),
        onPerros: () => _abrir(const MisPerrosScreen()),
        onPaseos: () => _abrir(const MisPaseosScreen()),
        onPerfil: () => _abrir(const PerfilUsuarioScreen()),
      ),
      body: RefreshIndicator(
        onRefresh: _cargarSesion,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: EdgeInsets.zero,
          children: [
            const SizedBox(height: 14),
            _buildCarruselPrincipal(),
            const SizedBox(height: 18),
            _WelcomeCard(
              nombre: _nombre,
              rol: _rol,
              onPrincipal: _esPaseador
                  ? () => _abrir(const MisPaseosScreen())
                  : () => _abrir(const PaseadoresScreen()),
              onSecundario: () => _abrir(const MisPaseosScreen()),
              textoPrincipal: _esPaseador ? 'Ver paseos' : 'Buscar paseador',
              textoSecundario: 'Mis paseos',
            ),
            _SectionHeader(
              title: 'Accesos rápidos',
              subtitle: 'Todo lo principal para usar DogGo.',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: _quickItems()
                    .map(
                      (item) => _QuickAccessCard(item: item),
                    )
                    .toList(),
              ),
            ),
            _SectionHeader(
              title: 'Cuidado y bienestar',
              subtitle: 'Consejos útiles para cuidar mejor a tu perro.',
            ),
            _HorizontalTipCards(
              items: _tips,
              onTap: _mostrarDetalleTip,
            ),
            _SectionHeader(
              title: 'Cerca de ti',
              subtitle: 'Busca lugares reales útiles para tu mascota.',
            ),
            _PlacesGrid(
              onOpen: _abrirLugarReal,
            ),
            _SectionHeader(
              title: '¿Sabías que...?',
              subtitle: 'Toca una tarjeta para ver más información.',
            ),
            _HorizontalTipCards(
              items: _curiosidades,
              onTap: _mostrarDetalleTip,
            ),
            _CtaBlock(
              esDuenio: _esDuenio || _esAdmin,
              onPaseos: () => _abrir(const MisPaseosScreen()),
              onPaseadores: () => _abrir(const PaseadoresScreen()),
              onPerros: () => _abrir(const MisPerrosScreen()),
              onPerfil: () => _abrir(const PerfilUsuarioScreen()),
              onCerrarSesion: _cerrarSesion,
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildCarruselPrincipal() {
    return Column(
      children: [
        SizedBox(
          height: 190,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _slides.length,
            onPageChanged: (index) {
              setState(() {
                _paginaActual = index;
              });
            },
            itemBuilder: (context, index) {
              final slide = _slides[index];

              return _HeroSlide(
                data: slide,
                onTap: index == 1
                    ? () => _abrir(const MisPerrosScreen())
                    : index == 2
                        ? () => _abrir(const MisPaseosScreen())
                        : () => _abrir(const PaseadoresScreen()),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _slides.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: _paginaActual == index ? 18 : 7,
              height: 7,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: _paginaActual == index ? _T.tealDeep : _T.stroke,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroSlideData {
  final String etiqueta;
  final String titulo;
  final String subtitulo;
  final String emoji;
  final Color color1;
  final Color color2;

  const _HeroSlideData({
    required this.etiqueta,
    required this.titulo,
    required this.subtitulo,
    required this.emoji,
    required this.color1,
    required this.color2,
  });
}

class _HeroSlide extends StatelessWidget {
  final _HeroSlideData data;
  final VoidCallback onTap;

  const _HeroSlide({
    required this.data,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              data.color1,
              data.color2,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: data.color1.withOpacity(.25),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -28,
              child: Text(
                data.emoji,
                style: TextStyle(
                  fontSize: 92,
                  color: Colors.white.withOpacity(.20),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SmallPill(
                  text: data.etiqueta,
                  color: Colors.white,
                  background: Colors.white.withOpacity(.18),
                ),
                const Spacer(),
                Text(
                  data.titulo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: _ts(26, FontWeight.w900, Colors.white, height: 1.05),
                ),
                const SizedBox(height: 8),
                Text(
                  data.subtitulo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: _ts(
                    13,
                    FontWeight.w500,
                    Colors.white.withOpacity(.88),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  final String nombre;
  final String rol;
  final String textoPrincipal;
  final String textoSecundario;
  final VoidCallback onPrincipal;
  final VoidCallback onSecundario;

  const _WelcomeCard({
    required this.nombre,
    required this.rol,
    required this.textoPrincipal,
    required this.textoSecundario,
    required this.onPrincipal,
    required this.onSecundario,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: _T.shadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SmallPill(
            text: rol,
            color: _T.tealDeep,
            background: _T.tealSurface,
            darkText: true,
          ),
          const SizedBox(height: 10),
          Text(
            'Hola, $nombre',
            style: _ts(25, FontWeight.w900, _T.ink, spacing: -.5),
          ),
          const SizedBox(height: 4),
          Text(
            '¿Qué quieres hacer hoy?',
            style: _ts(14, FontWeight.w500, _T.inkSub),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: textoPrincipal,
                  icon: Icons.search_rounded,
                  primary: true,
                  onTap: onPrincipal,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  label: textoSecundario,
                  icon: Icons.route_rounded,
                  primary: false,
                  onTap: onSecundario,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool primary;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: primary
          ? ElevatedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, size: 18),
              label: Text(label),
              style: ElevatedButton.styleFrom(
                backgroundColor: _T.teal,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            )
          : OutlinedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, size: 18),
              label: Text(label),
              style: OutlinedButton.styleFrom(
                foregroundColor: _T.tealDeep,
                side: const BorderSide(color: _T.tealDeep),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
    );
  }
}

class _QuickItemData {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final Color surface;
  final VoidCallback onTap;

  const _QuickItemData({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.surface,
    required this.onTap,
  });
}

class _QuickAccessCard extends StatelessWidget {
  final _QuickItemData item;

  const _QuickAccessCard({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: item.onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: _T.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: _T.shadow(
            opacity: .045,
            blur: 14,
            offset: const Offset(0, 4),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: item.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  item.emoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: _ts(15, FontWeight.w900, _T.ink),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    style: _ts(12, FontWeight.w500, _T.inkSub),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: item.color.withOpacity(.70),
              size: 25,
            ),
          ],
        ),
      ),
    );
  }
}

class _TipData {
  final String emoji;
  final String title;
  final String subtitle;
  final String detail;
  final Color color;
  final Color surface;

  const _TipData({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.detail,
    required this.color,
    required this.surface,
  });
}

class _HorizontalTipCards extends StatelessWidget {
  final List<_TipData> items;
  final void Function(_TipData item) onTap;

  const _HorizontalTipCards({
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 152,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];

          return GestureDetector(
            onTap: () => onTap(item),
            child: Container(
              width: 148,
              margin: EdgeInsets.only(
                right: index == items.length - 1 ? 0 : 10,
              ),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _T.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: _T.shadow(
                  opacity: .055,
                  blur: 14,
                  offset: const Offset(0, 4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: item.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        item.emoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _SmallPill(
                    text: item.title,
                    color: item.color,
                    background: item.surface,
                    darkText: true,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.subtitle,
                    style: _ts(12.3, FontWeight.w800, _T.ink, height: 1.25),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PlacesGrid extends StatelessWidget {
  final Future<void> Function(String busqueda) onOpen;

  const _PlacesGrid({
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final places = [
      _PlaceItem(
        nombre: 'Veterinarias',
        busqueda: 'veterinarias para perros',
        subtipo: 'Cerca de ti',
        emoji: '🏥',
        color: _T.rose,
        surface: _T.roseSurf,
      ),
      _PlaceItem(
        nombre: 'Parques caninos',
        busqueda: 'parques para perros',
        subtipo: 'Dog friendly',
        emoji: '🌳',
        color: _T.emerald,
        surface: _T.emeraldSurf,
      ),
      _PlaceItem(
        nombre: 'Pet shops',
        busqueda: 'tiendas para mascotas',
        subtipo: 'Comida y accesorios',
        emoji: '🛒',
        color: _T.violet,
        surface: _T.violetSurf,
      ),
      _PlaceItem(
        nombre: 'Adopción',
        busqueda: 'centros de adopción de perros',
        subtipo: 'Rescate animal',
        emoji: '🐾',
        color: _T.amber,
        surface: _T.amberSurf,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: places.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.45,
      ),
      itemBuilder: (context, index) {
        return _PlaceCard(
          item: places[index],
          onTap: () => onOpen(places[index].busqueda),
        );
      },
    );
  }
}

class _PlaceItem {
  final String nombre;
  final String busqueda;
  final String subtipo;
  final String emoji;
  final Color color;
  final Color surface;

  const _PlaceItem({
    required this.nombre,
    required this.busqueda,
    required this.subtipo,
    required this.emoji,
    required this.color,
    required this.surface,
  });
}

class _PlaceCard extends StatelessWidget {
  final _PlaceItem item;
  final VoidCallback onTap;

  const _PlaceCard({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _T.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: _T.shadow(
              opacity: .045,
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
                        color: item.surface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        item.emoji,
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Ver mapa',
                      style: _ts(10, FontWeight.w800, _T.tealDeep),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Text(
                    item.nombre,
                    style: _ts(14, FontWeight.w900, _T.ink, height: 1.2),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  item.subtipo,
                  style: _ts(11, FontWeight.w600, _T.inkSub),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CtaBlock extends StatelessWidget {
  final bool esDuenio;
  final VoidCallback onPaseos;
  final VoidCallback onPaseadores;
  final VoidCallback onPerros;
  final VoidCallback onPerfil;
  final VoidCallback onCerrarSesion;

  const _CtaBlock({
    required this.esDuenio,
    required this.onPaseos,
    required this.onPaseadores,
    required this.onPerros,
    required this.onPerfil,
    required this.onCerrarSesion,
  });

  @override
  Widget build(BuildContext context) {
    final items = <_CtaItem>[
      _CtaItem('🦮', 'Mis paseos', 'Activos e historial', onPaseos),
      if (esDuenio) _CtaItem('🔍', 'Buscar', 'Paseadores', onPaseadores),
      if (esDuenio) _CtaItem('🐾', 'Perros', 'Mis mascotas', onPerros),
      _CtaItem('👤', 'Perfil', 'Mi cuenta', onPerfil),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.05,
            ),
            itemBuilder: (context, index) {
              final item = items[index];

              return GestureDetector(
                onTap: item.onTap,
                child: Container(
                  decoration: BoxDecoration(
                    color: _T.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: _T.shadow(
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
                        Text(
                          item.emoji,
                          style: const TextStyle(fontSize: 22),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                item.title,
                                style: _ts(12, FontWeight.w900, _T.ink),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                item.subtitle,
                                style: _ts(10, FontWeight.w500, _T.inkSub),
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
            },
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: onCerrarSesion,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Cerrar sesión'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _T.rose,
                side: const BorderSide(color: _T.rose),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CtaItem {
  final String emoji;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _CtaItem(
    this.emoji,
    this.title,
    this.subtitle,
    this.onTap,
  );
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 26, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: _ts(18, FontWeight.w900, _T.ink, spacing: -.3),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: _ts(12.5, FontWeight.w500, _T.inkSub),
          ),
        ],
      ),
    );
  }
}

class _TopIconButton extends StatelessWidget {
  final IconData icon;
  final bool badge;
  final VoidCallback onTap;

  const _TopIconButton({
    required this.icon,
    required this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          onPressed: onTap,
          icon: Icon(
            icon,
            color: Colors.white,
            size: 25,
          ),
        ),
        if (badge)
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: _T.rose,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}

class _SmallPill extends StatelessWidget {
  final String text;
  final Color color;
  final Color background;
  final bool darkText;

  const _SmallPill({
    required this.text,
    required this.color,
    required this.background,
    this.darkText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        text,
        style: _ts(
          9.5,
          FontWeight.w900,
          darkText ? color : Colors.white,
          spacing: .4,
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final bool esDuenio;
  final VoidCallback onHome;
  final VoidCallback onPaseadores;
  final VoidCallback onPerros;
  final VoidCallback onPaseos;
  final VoidCallback onPerfil;

  const _BottomNav({
    required this.esDuenio,
    required this.onHome,
    required this.onPaseadores,
    required this.onPerros,
    required this.onPaseos,
    required this.onPerfil,
  });

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[
      _BottomItem(
        icon: Icons.home_rounded,
        label: 'Inicio',
        active: true,
        onTap: onHome,
      ),
      if (esDuenio)
        _BottomItem(
          icon: Icons.search_rounded,
          label: 'Buscar',
          active: false,
          onTap: onPaseadores,
        ),
      if (esDuenio)
        _BottomItem(
          icon: Icons.pets_rounded,
          label: 'Perros',
          active: false,
          onTap: onPerros,
        ),
      _BottomItem(
        icon: Icons.directions_walk_rounded,
        label: 'Paseos',
        active: false,
        onTap: onPaseos,
      ),
      _BottomItem(
        icon: Icons.person_rounded,
        label: 'Perfil',
        active: false,
        onTap: onPerfil,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: _T.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.08),
            blurRadius: 18,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
      child: SafeArea(
        top: false,
        child: Row(
          children: items.map((item) => Expanded(child: item)).toList(),
        ),
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _BottomItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? _T.tealDeep : _T.inkSub;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
        decoration: BoxDecoration(
          color: active ? _T.tealSurface : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _ts(
                10,
                active ? FontWeight.w900 : FontWeight.w600,
                color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}