import 'package:flutter/material.dart';

import '../services/session_service.dart';
import '../services/storage_service.dart';
import 'configuracion_screen.dart';
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

  static const bg = Color(0xFFF4F0E8);
  static const surface = Colors.white;
  static const ink = Color(0xFF111827);
  static const inkSub = Color(0xFF6B7280);
  static const stroke = Color(0xFFE5E7EB);

  static List<BoxShadow> shadow({
    double opacity = .06,
    double blur = 18,
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
  bool _cargando = true;

  String _nombre = 'Usuario';
  String _rol = 'Usuario';
  String _baseUrl = 'Sin servidor';

  @override
  void initState() {
    super.initState();
    _cargarSesion();
  }

  Future<void> _cargarSesion() async {
    final nombre = await SessionService.obtenerNombre();
    final rol = await SessionService.obtenerRol();
    final baseUrl = await StorageService.obtenerBaseUrl();

    if (!mounted) return;

    setState(() {
      _nombre =
          nombre != null && nombre.trim().isNotEmpty ? nombre.trim() : 'Usuario';
      _rol = _rolBonito(rol);
      _baseUrl = baseUrl ?? 'Sin servidor';
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

    return rol?.trim().isNotEmpty == true ? rol!.trim() : 'Usuario';
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
            badge: true,
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
        onHome: () {},
        onPerros: () => _abrir(const MisPerrosScreen()),
        onPaseos: () => _abrir(const MisPaseosScreen()),
        onPerfil: () => _abrir(const PerfilUsuarioScreen()),
      ),
      body: RefreshIndicator(
        onRefresh: _cargarSesion,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            _HeroBanner(
              nombre: _nombre,
              rol: _rol,
              baseUrl: _baseUrl,
              onBuscarPaseador: () => _abrir(const PaseadoresScreen()),
              onMisPaseos: () => _abrir(const MisPaseosScreen()),
            ),
            _StatsRibbon(rol: _rol),
            _SectionHeader(
              title: '⚡ Accesos rápidos',
              subtitle: 'Funciones principales conectadas al servidor.',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _QuickAccessCard(
                    emoji: '🐕',
                    title: 'Mis perros',
                    subtitle: 'Registra, edita y consulta tus mascotas',
                    color: _T.violet,
                    surface: _T.violetSurf,
                    onTap: () => _abrir(const MisPerrosScreen()),
                  ),
                  _QuickAccessCard(
                    emoji: '👟',
                    title: 'Paseadores',
                    subtitle: 'Busca paseadores disponibles',
                    color: _T.teal,
                    surface: _T.tealSurface,
                    onTap: () => _abrir(const PaseadoresScreen()),
                  ),
                  _QuickAccessCard(
                    emoji: '🦮',
                    title: 'Mis paseos',
                    subtitle: 'Solicitudes, estados, mapa, chat y tracking',
                    color: _T.amber,
                    surface: _T.amberSurf,
                    onTap: () => _abrir(const MisPaseosScreen()),
                  ),
                  _QuickAccessCard(
                    emoji: '⚙️',
                    title: 'Configuración',
                    subtitle: 'Servidor, contraseña y preferencias',
                    color: _T.inkSub,
                    surface: const Color(0xFFF3F4F6),
                    onTap: () => _abrir(const ConfiguracionScreen()),
                  ),
                ],
              ),
            ),
            _SectionHeader(
              title: '🐾 Flujo DogGo',
              subtitle: 'Módulos reales que ya puedes probar.',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _FlowCard(
                    icon: Icons.verified_user_rounded,
                    title: 'Sesión real con JWT',
                    subtitle:
                        'Login, registro, confirmación y recuperación conectados al back.',
                    color: _T.teal,
                  ),
                  _FlowCard(
                    icon: Icons.pets_rounded,
                    title: 'Mascotas reales',
                    subtitle:
                        'Tus perros vienen desde MySQL por la API de DogGo.',
                    color: _T.violet,
                  ),
                  _FlowCard(
                    icon: Icons.map_rounded,
                    title: 'Mapa y ubicación',
                    subtitle:
                        'Selección de ubicación, mapa de paseo y tracking GPS.',
                    color: _T.emerald,
                  ),
                  _FlowCard(
                    icon: Icons.chat_bubble_rounded,
                    title: 'Chat y evidencias',
                    subtitle:
                        'Comunicación del paseo y fotos de inicio/finalización.',
                    color: _T.amber,
                  ),
                ],
              ),
            ),
            _SectionHeader(
              title: '💡 Cuidado & bienestar',
              subtitle: 'Secciones visuales como las del diseño de tu compa.',
            ),
            _HorizontalCards(
              items: const [
                _VisualItem(
                  emoji: '🍖',
                  title: 'Nutrición',
                  subtitle: 'Comida según talla y edad',
                  color: _T.teal,
                  surface: _T.tealSurface,
                ),
                _VisualItem(
                  emoji: '🏃',
                  title: 'Ejercicio',
                  subtitle: 'Paseos diarios por raza',
                  color: _T.violet,
                  surface: _T.violetSurf,
                ),
                _VisualItem(
                  emoji: '💉',
                  title: 'Salud',
                  subtitle: 'Vacunas y revisiones',
                  color: _T.emerald,
                  surface: _T.emeraldSurf,
                ),
                _VisualItem(
                  emoji: '🛁',
                  title: 'Higiene',
                  subtitle: 'Baño y cepillado',
                  color: _T.amber,
                  surface: _T.amberSurf,
                ),
              ],
            ),
            _SectionHeader(
              title: '🛍️ Productos recomendados',
              subtitle: 'Bloque visual para presentar ideas de cuidado.',
            ),
            _HorizontalCards(
              items: const [
                _VisualItem(
                  emoji: '🦷',
                  title: 'Kong Classic',
                  subtitle: 'Juguete resistente',
                  color: _T.teal,
                  surface: _T.tealSurface,
                ),
                _VisualItem(
                  emoji: '🛏️',
                  title: 'Cama ortopédica',
                  subtitle: 'Descanso cómodo',
                  color: _T.violet,
                  surface: _T.violetSurf,
                ),
                _VisualItem(
                  emoji: '🦺',
                  title: 'Arnés antipull',
                  subtitle: 'Mejor control al pasear',
                  color: _T.emerald,
                  surface: _T.emeraldSurf,
                ),
                _VisualItem(
                  emoji: '🥩',
                  title: 'Snacks',
                  subtitle: 'Premios para entrenamiento',
                  color: _T.amber,
                  surface: _T.amberSurf,
                ),
              ],
            ),
            _SectionHeader(
              title: '📍 Cerca de ti',
              subtitle: 'Lugares útiles para dueños y paseadores.',
            ),
            const _PlacesGrid(),
            _SectionHeader(
              title: '🧬 ¿Sabías que...?',
              subtitle: 'Curiosidades de razas populares.',
            ),
            _HorizontalCards(
              items: const [
                _VisualItem(
                  emoji: '🦮',
                  title: 'Golden Retriever',
                  subtitle: '25–34 kg · Grande',
                  color: _T.amber,
                  surface: _T.amberSurf,
                ),
                _VisualItem(
                  emoji: '🐩',
                  title: 'Poodle',
                  subtitle: 'Tamaños variados',
                  color: _T.violet,
                  surface: _T.violetSurf,
                ),
                _VisualItem(
                  emoji: '🐶',
                  title: 'French Bulldog',
                  subtitle: '8–14 kg · Pequeño',
                  color: _T.rose,
                  surface: _T.roseSurf,
                ),
                _VisualItem(
                  emoji: '🐕‍🦺',
                  title: 'Pastor Alemán',
                  subtitle: '22–40 kg · Grande',
                  color: _T.emerald,
                  surface: _T.emeraldSurf,
                ),
              ],
            ),
            _CtaBlock(
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
}

class _HeroBanner extends StatelessWidget {
  final String nombre;
  final String rol;
  final String baseUrl;
  final VoidCallback onBuscarPaseador;
  final VoidCallback onMisPaseos;

  const _HeroBanner({
    required this.nombre,
    required this.rol,
    required this.baseUrl,
    required this.onBuscarPaseador,
    required this.onMisPaseos,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0EC9A0),
            Color(0xFF057A5F),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _T.teal.withOpacity(.30),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -38,
            child: _Blob(size: 165, opacity: .06),
          ),
          Positioned(
            bottom: -22,
            right: 48,
            child: _Blob(size: 80, opacity: .07),
          ),
          Positioned(
            top: 28,
            right: 34,
            child: _Blob(size: 44, opacity: .10),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SmallPill(
                  text: 'BIENVENIDO DE VUELTA',
                  color: Colors.white,
                  background: Colors.white.withOpacity(.18),
                ),
                const SizedBox(height: 14),
                Text(
                  'Hola, $nombre.',
                  style: _ts(
                    30,
                    FontWeight.w900,
                    Colors.white,
                    spacing: -.7,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '¿Cómo están\ntus peludos hoy?',
                  style: _ts(
                    18,
                    FontWeight.w300,
                    Colors.white.withOpacity(.92),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Rol: $rol\nServidor: $baseUrl',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: _ts(
                    12.5,
                    FontWeight.w400,
                    Colors.white.withOpacity(.70),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _HeroButton(
                      label: 'Buscar paseador',
                      primary: true,
                      onTap: onBuscarPaseador,
                    ),
                    const SizedBox(width: 9),
                    _HeroButton(
                      label: 'Mis paseos',
                      primary: false,
                      onTap: onMisPaseos,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final double size;
  final double opacity;

  const _Blob({
    required this.size,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(opacity),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _StatsRibbon extends StatelessWidget {
  final String rol;

  const _StatsRibbon({
    required this.rol,
  });

  @override
  Widget build(BuildContext context) {
    final stats = [
      _StatData('API', 'Conectada', '🌐'),
      _StatData(rol, 'Rol', '👤'),
      _StatData('GPS', 'Tracking', '📍'),
      _StatData('JWT', 'Sesión', '🔐'),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0EC9A0),
            Color(0xFF0AA882),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _T.teal.withOpacity(.20),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (int i = 0; i < stats.length; i++) ...[
            if (i > 0)
              Container(
                width: 1,
                height: 34,
                color: Colors.white.withOpacity(.22),
              ),
            _StatTile(data: stats[i]),
          ],
        ],
      ),
    );
  }
}

class _StatData {
  final String value;
  final String label;
  final String emoji;

  const _StatData(this.value, this.label, this.emoji);
}

class _StatTile extends StatelessWidget {
  final _StatData data;

  const _StatTile({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          data.emoji,
          style: const TextStyle(fontSize: 18),
        ),
        const SizedBox(height: 4),
        Text(
          data.value,
          style: _ts(14.5, FontWeight.w900, Colors.white),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          data.label,
          style: _ts(9.5, FontWeight.w500, Colors.white.withOpacity(.70)),
        ),
      ],
    );
  }
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
            style: _ts(17, FontWeight.w900, _T.ink, spacing: -.3),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: _ts(12.5, FontWeight.w400, _T.inkSub),
          ),
        ],
      ),
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final Color surface;
  final VoidCallback onTap;

  const _QuickAccessCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.surface,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: _T.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _T.shadow(
            opacity: .045,
            blur: 14,
            offset: const Offset(0, 4),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 23),
                ),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: _ts(14.5, FontWeight.w800, _T.ink),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: _ts(11.5, FontWeight.w400, _T.inkSub),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: color.withOpacity(.65),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

class _FlowCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _FlowCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _T.shadow(
          opacity: .04,
          blur: 12,
          offset: const Offset(0, 3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withOpacity(.11),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 25,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: _ts(14.5, FontWeight.w900, _T.ink),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: _ts(11.5, FontWeight.w400, _T.inkSub, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VisualItem {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final Color surface;

  const _VisualItem({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.surface,
  });
}

class _HorizontalCards extends StatelessWidget {
  final List<_VisualItem> items;

  const _HorizontalCards({
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 148,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];

          return Container(
            width: 145,
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
                  style: _ts(12.2, FontWeight.w800, _T.ink, height: 1.25),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PlacesGrid extends StatelessWidget {
  const _PlacesGrid();

  @override
  Widget build(BuildContext context) {
    final places = [
      _PlaceItem(
        nombre: 'Hospital Veterinario',
        tipo: 'Veterinaria',
        subtipo: '24 horas',
        emoji: '🏥',
        color: _T.rose,
        surface: _T.roseSurf,
      ),
      _PlaceItem(
        nombre: 'Parque Canino',
        tipo: 'Parque',
        subtipo: 'Dog friendly',
        emoji: '🌳',
        color: _T.emerald,
        surface: _T.emeraldSurf,
      ),
      _PlaceItem(
        nombre: 'Pet Store',
        tipo: 'Tienda',
        subtipo: 'Grooming',
        emoji: '🛒',
        color: _T.violet,
        surface: _T.violetSurf,
      ),
      _PlaceItem(
        nombre: 'Centro de adopción',
        tipo: 'Adopción',
        subtipo: 'Rescate',
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
        childAspectRatio: 1.52,
      ),
      itemBuilder: (context, index) {
        return _PlaceCard(item: places[index]);
      },
    );
  }
}

class _PlaceItem {
  final String nombre;
  final String tipo;
  final String subtipo;
  final String emoji;
  final Color color;
  final Color surface;

  const _PlaceItem({
    required this.nombre,
    required this.tipo,
    required this.subtipo,
    required this.emoji,
    required this.color,
    required this.surface,
  });
}

class _PlaceCard extends StatelessWidget {
  final _PlaceItem item;

  const _PlaceCard({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _T.shadow(
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
                    color: item.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.emoji,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const Spacer(),
                Text(
                  'Ver mapa',
                  style: _ts(9, FontWeight.w700, _T.tealDeep),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                item.nombre,
                style: _ts(11.5, FontWeight.w800, _T.ink, height: 1.25),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Row(
              children: [
                _SmallPill(
                  text: item.tipo,
                  color: item.color,
                  background: item.surface,
                  darkText: true,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    item.subtipo,
                    style: _ts(9.5, FontWeight.w600, _T.inkSub),
                    overflow: TextOverflow.ellipsis,
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

class _CtaBlock extends StatelessWidget {
  final VoidCallback onPaseos;
  final VoidCallback onPaseadores;
  final VoidCallback onPerros;
  final VoidCallback onPerfil;
  final VoidCallback onCerrarSesion;

  const _CtaBlock({
    required this.onPaseos,
    required this.onPaseadores,
    required this.onPerros,
    required this.onPerfil,
    required this.onCerrarSesion,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _CtaItem('🐕', 'Mis paseos', 'Activos e historial', onPaseos),
      _CtaItem('🔍', 'Buscar', 'Paseadores', onPaseadores),
      _CtaItem('🐾', 'Perros', 'Mis mascotas', onPerros),
      _CtaItem('👤', 'Perfil', 'Mi cuenta', onPerfil),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
            decoration: BoxDecoration(
              color: _T.tealSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _T.teal.withOpacity(.15)),
            ),
            child: Column(
              children: [
                Text(
                  '🚀 TODO LISTO PARA TI',
                  style: _ts(9.5, FontWeight.w900, _T.tealDeep, spacing: 1.4),
                ),
                const SizedBox(height: 5),
                Text(
                  'Prueba el flujo principal',
                  style: _ts(17, FontWeight.w900, _T.ink, spacing: -.3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
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
                                style: _ts(11.5, FontWeight.w800, _T.ink),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                item.subtitle,
                                style: _ts(9.5, FontWeight.w400, _T.inkSub),
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

class _HeroButton extends StatelessWidget {
  final String label;
  final bool primary;
  final VoidCallback onTap;

  const _HeroButton({
    required this.label,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 11),
        decoration: BoxDecoration(
          color: primary ? Colors.white : Colors.white.withOpacity(.16),
          borderRadius: BorderRadius.circular(12),
          border: primary
              ? null
              : Border.all(color: Colors.white.withOpacity(.30)),
        ),
        child: Text(
          label,
          style: _ts(
            12.5,
            FontWeight.w800,
            primary ? _T.tealDeep : Colors.white,
          ),
        ),
      ),
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
          FontWeight.w800,
          darkText ? color : Colors.white,
          spacing: .3,
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final VoidCallback onHome;
  final VoidCallback onPerros;
  final VoidCallback onPaseos;
  final VoidCallback onPerfil;

  const _BottomNav({
    required this.onHome,
    required this.onPerros,
    required this.onPaseos,
    required this.onPerfil,
  });

  @override
  Widget build(BuildContext context) {
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
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _BottomItem(
              icon: Icons.home_rounded,
              label: 'Inicio',
              active: true,
              onTap: onHome,
            ),
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
          ],
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? _T.tealSurface : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 23),
            const SizedBox(height: 2),
            Text(
              label,
              style: _ts(
                10.5,
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