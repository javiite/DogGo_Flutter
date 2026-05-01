import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

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

// ─────────────────────────────────────────────
//  PALETA DE COLORES
// ─────────────────────────────────────────────
class DogGoColors {
  static const teal = Color(0xFF1ABC9C);
  static const tealDark = Color(0xFF16A085);
  static const tealLight = Color(0xFFD5F5EE);
  static const purple = Color(0xFF8E44AD);
  static const green = Color(0xFF27AE60);
  static const orange = Color(0xFFF39C12);
  static const cream = Color(0xFFF5F1E8);
  static const creamDark = Color(0xFFEDE8DB);
  static const dark = Color(0xFF2C3E50);
  static const grey = Color(0xFF7F8C8D);
  static const greyLight = Color(0xFFBDC3C7);
  static const white = Colors.white;
  static const red = Color(0xFFE74C3C);
}

// ─────────────────────────────────────────────
//  APP PRINCIPAL
// ─────────────────────────────────────────────
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
          seedColor: DogGoColors.teal,
          brightness: Brightness.light,
        ),
        fontFamily: 'Nunito',
      ),
      home: const MainShell(),
    );
  }
}

// ─────────────────────────────────────────────
//  SHELL PRINCIPAL CON BOTTOM NAV
// ─────────────────────────────────────────────
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with TickerProviderStateMixin {
  int _selectedIndex = 0;

  final List<_NavItem> _navItems = [
    _NavItem(
      icon: Icons.home_rounded,
      activeIcon: Icons.home_rounded,
      label: 'Inicio',
    ),
    _NavItem(
      icon: Icons.pets_outlined,
      activeIcon: Icons.pets,
      label: 'Mis perros',
    ),
    _NavItem(
      icon: Icons.directions_walk_outlined,
      activeIcon: Icons.directions_walk,
      label: 'Paseos',
    ),
    _NavItem(
      icon: Icons.chat_bubble_outline_rounded,
      activeIcon: Icons.chat_bubble_rounded,
      label: 'Mensajes',
    ),
    _NavItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Perfil',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DogGoColors.cream,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          const HomeScreen(),
          _PlaceholderScreen(
            title: 'Mis Perros',
            icon: Icons.pets,
            color: DogGoColors.purple,
          ),
          _PlaceholderScreen(
            title: 'Paseos',
            icon: Icons.directions_walk,
            color: DogGoColors.orange,
          ),
          _PlaceholderScreen(
            title: 'Mensajes',
            icon: Icons.chat_bubble_rounded,
            color: DogGoColors.green,
          ),
          _PlaceholderScreen(
            title: 'Mi Perfil',
            icon: Icons.person_rounded,
            color: DogGoColors.teal,
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: DogGoColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_navItems.length, (i) {
              final item = _navItems[i];
              final isActive = i == _selectedIndex;
              return GestureDetector(
                onTap: () => setState(() => _selectedIndex = i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? DogGoColors.teal.withOpacity(0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          isActive ? item.activeIcon : item.icon,
                          key: ValueKey(isActive),
                          color: isActive ? DogGoColors.teal : DogGoColors.grey,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: isActive ? DogGoColors.teal : DogGoColors.grey,
                        ),
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

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

// ─────────────────────────────────────────────
//  HOME SCREEN COMPLETA
// ─────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _bannerController;
  late AnimationController _cardsController;
  late Animation<double> _bannerFade;
  late Animation<Offset> _bannerSlide;
  late Animation<double> _cardsFade;

  final ScrollController _scrollController = ScrollController();
  int _activeMascotaIndex = 0;

  // ── Datos mock ──
  final List<_Mascota> _mascotas = [
    _Mascota(
      nombre: 'Hikari',
      raza: 'Pomerania',
      edad: '7 años',
      tamano: 'Pequeño',
      emoji: '🐕',
      nota: 'Tiene obesidad extrema y se puede cansar rápido',
    ),
    _Mascota(
      nombre: 'Rocky',
      raza: 'Golden Retriever',
      edad: '3 años',
      tamano: 'Grande',
      emoji: '🦮',
      nota: null,
    ),
  ];

  final List<_Paseo> _paseos = [
    _Paseo(
      perro: 'Max',
      paseador: 'Carlos Rodríguez',
      fecha: 'Hoy, 4:30 PM',
      duracion: '45 min',
      precio: '\$25.00',
      estado: 'Confirmado',
    ),
    _Paseo(
      perro: 'Luna',
      paseador: 'María González',
      fecha: 'Mañana, 10:00 AM',
      duracion: '60 min',
      precio: '\$30.00',
      estado: 'Pendiente',
    ),
  ];

  final List<_Consejo> _consejos = [
    _Consejo(
      titulo: '¿Qué debe comer tu perro según su tamaño?',
      categoria: 'Nutrición',
      emoji: '🍖',
      tiempo: '5 min de lectura',
    ),
    _Consejo(
      titulo: '¿Cuántos paseos necesita tu perro al día?',
      categoria: 'Ejercicio',
      emoji: '🏃',
      tiempo: '3 min de lectura',
    ),
    _Consejo(
      titulo: 'Calendario de vacunación: lo esencial',
      categoria: 'Salud',
      emoji: '💉',
      tiempo: '4 min de lectura',
    ),
    _Consejo(
      titulo: '¿Con qué frecuencia bañar a tu perro?',
      categoria: 'Higiene',
      emoji: '🛁',
      tiempo: '3 min de lectura',
    ),
    _Consejo(
      titulo: 'Señales de estrés en perros que debes conocer',
      categoria: 'Comportamiento',
      emoji: '😰',
      tiempo: '6 min de lectura',
    ),
    _Consejo(
      titulo: 'Actividades para hacer con tu perro en casa',
      categoria: 'Bienestar',
      emoji: '❤️',
      tiempo: '4 min de lectura',
    ),
  ];

  final List<_Producto> _productos = [
    _Producto(
      nombre: 'Juguete Kong Classic',
      descripcion: 'Para perros que mastican mucho',
      categoria: 'Juguete',
      emoji: '🦷',
    ),
    _Producto(
      nombre: 'Cama ortopédica para perros',
      descripcion: 'Especialmente recomendada para razas grandes',
      categoria: 'Descanso',
      emoji: '🛏️',
    ),
    _Producto(
      nombre: 'Arnés antipull ajustable',
      descripcion: 'Reduce el jalón al caminar',
      categoria: 'Paseo',
      emoji: '🦺',
    ),
    _Producto(
      nombre: 'Snacks naturales deshidratados',
      descripcion: 'Son conservantes ni colorantes',
      categoria: 'Nutrición',
      emoji: '🥩',
    ),
  ];

  final List<_Lugar> _lugares = [
    _Lugar(
      nombre: 'Hospital Veterinario Mascota Feliz',
      tipo: 'Veterinaria',
      subtipo: '24 horas',
      emoji: '🏥',
      color: DogGoColors.red,
    ),
    _Lugar(
      nombre: 'Parque Canino España',
      tipo: 'Parque',
      subtipo: 'Dog friendly',
      emoji: '🌳',
      color: DogGoColors.green,
    ),
    _Lugar(
      nombre: 'PetCo Cumbres',
      tipo: 'Tienda',
      subtipo: 'Grooming',
      emoji: '🛒',
      color: DogGoColors.purple,
    ),
    _Lugar(
      nombre: 'Adopta Nuevo León',
      tipo: 'Adopción',
      subtipo: 'Rescate',
      emoji: '🐾',
      color: DogGoColors.orange,
    ),
  ];

  final List<_Curiosidad> _curiosidades = [
    _Curiosidad(
      raza: 'Golden Retriever',
      peso: '25-34 kg',
      tamano: 'Grande',
      emoji: '🦮',
    ),
    _Curiosidad(
      raza: 'Poodle (Caniche)',
      peso: '20-32 kg',
      tamano: 'Grande',
      emoji: '🐩',
    ),
    _Curiosidad(
      raza: 'Labrador Retriever',
      peso: '25-36 kg',
      tamano: 'Grande',
      emoji: '🐕',
    ),
    _Curiosidad(
      raza: 'French Bulldog',
      peso: '8-14 kg',
      tamano: 'Pequeño',
      emoji: '🐶',
    ),
    _Curiosidad(
      raza: 'Pastor Alemán',
      peso: '22-40 kg',
      tamano: 'Grande',
      emoji: '🐕‍🦺',
    ),
    _Curiosidad(
      raza: 'Beagle',
      peso: '9-11 kg',
      tamano: 'Mediano',
      emoji: '🐕',
    ),
  ];

  @override
  void initState() {
    super.initState();

    _bannerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _cardsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _bannerFade = CurvedAnimation(
      parent: _bannerController,
      curve: Curves.easeOut,
    );
    _bannerSlide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _bannerController, curve: Curves.easeOut),
        );
    _cardsFade = CurvedAnimation(
      parent: _cardsController,
      curve: Curves.easeOut,
    );

    _bannerController.forward();
    Future.delayed(
      const Duration(milliseconds: 300),
      () => _cardsController.forward(),
    );
  }

  @override
  void dispose() {
    _bannerController.dispose();
    _cardsController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DogGoColors.cream,
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildAppBar(innerBoxIsScrolled),
        ],
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Banner bienvenida
              _buildWelcomeBanner(),
              const SizedBox(height: 20),

              // 2. Mis mascotas
              _buildSectionHeader('🐾 Tus mascotas', 'Ver todas', onTap: () {}),
              _buildMascotas(),
              const SizedBox(height: 8),

              // 3. Stats rápidos
              _buildStatsRow(),
              const SizedBox(height: 20),

              // 4. Próximos paseos
              _buildSectionHeader(
                '📅 Próximos paseos',
                'Ver todos',
                onTap: () {},
              ),
              _buildPaseos(),
              const SizedBox(height: 20),

              // 5. Accesos rápidos
              _buildAccesosRapidos(),
              const SizedBox(height: 24),

              // 6. Consejos
              _buildSectionHeader(
                '💡 Cuidado y bienestar',
                null,
                subtitle: 'Consejos para tu mejor amigo',
              ),
              _buildConsejos(),
              const SizedBox(height: 24),

              // 7. Productos recomendados
              _buildSectionHeader(
                '🛍️ Productos recomendados',
                null,
                subtitle: 'Lo que los dueños de DogGo usan y recomiendan',
              ),
              _buildProductos(),
              const SizedBox(height: 24),

              // 8. Lugares cerca
              _buildSectionHeader(
                '📍 Lugares cerca de ti',
                null,
                subtitle: 'Monterrey y Área Metro',
              ),
              _buildLugares(),
              const SizedBox(height: 24),

              // 9. Curiosidades de razas
              _buildSectionHeader(
                '🧬 ¿Sabías que...?',
                null,
                subtitle: 'Curiosidades de razas populares',
              ),
              _buildCuriosidades(),
              const SizedBox(height: 24),

              // 10. CTA final
              _buildCTAFinal(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ── APP BAR ──
  SliverAppBar _buildAppBar(bool innerBoxIsScrolled) {
    return SliverAppBar(
      pinned: true,
      floating: true,
      snap: true,
      backgroundColor: DogGoColors.teal,
      elevation: 0,
      expandedHeight: 0,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text('🐾', style: TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 10),
          const Text(
            'DogGo',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
      actions: [
        Stack(
          children: [
            IconButton(
              icon: const Icon(
                Icons.notifications_outlined,
                color: Colors.white,
                size: 26,
              ),
              onPressed: () {},
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFE74C3C),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(
            Icons.person_outline_rounded,
            color: Colors.white,
            size: 26,
          ),
          onPressed: () {},
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ── BANNER BIENVENIDA ──
  Widget _buildWelcomeBanner() {
    return FadeTransition(
      opacity: _bannerFade,
      child: SlideTransition(
        position: _bannerSlide,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1ABC9C), Color(0xFF0E8C72)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: DogGoColors.teal.withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Círculos decorativos
              Positioned(
                top: -20,
                right: -20,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                bottom: -30,
                right: 60,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'BIENVENIDO DE VUELTA',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Hola, Marco.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                          const Text(
                            '¿Cómo están tus\npeludos hoy?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Todo lo que necesitas para cuidar\na tus mascotas está aquí.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _BannerButton(
                                label: 'Buscar paseador',
                                isPrimary: true,
                                onTap: () {},
                              ),
                              const SizedBox(width: 8),
                              _BannerButton(
                                label: 'Mis paseos',
                                isPrimary: false,
                                onTap: () {},
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── SECTION HEADER ──
  Widget _buildSectionHeader(
    String title,
    String? actionLabel, {
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: DogGoColors.dark,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (actionLabel != null)
                GestureDetector(
                  onTap: onTap,
                  child: Text(
                    actionLabel,
                    style: const TextStyle(
                      color: DogGoColors.teal,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(color: DogGoColors.grey, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  // ── MASCOTAS (CAROUSEL) ──
  Widget _buildMascotas() {
    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: PageController(viewportFraction: 0.85, initialPage: 0),
            onPageChanged: (i) => setState(() => _activeMascotaIndex = i),
            itemCount: _mascotas.length + 1,
            itemBuilder: (context, i) {
              if (i == _mascotas.length) {
                return _buildAddMascotaCard();
              }
              return _buildMascotaCard(_mascotas[i]);
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_mascotas.length + 1, (i) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == _activeMascotaIndex ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: i == _activeMascotaIndex
                    ? DogGoColors.teal
                    : DogGoColors.greyLight,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildMascotaCard(_Mascota m) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DogGoColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: DogGoColors.tealLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(m.emoji, style: const TextStyle(fontSize: 36)),
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
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: DogGoColors.dark,
                  ),
                ),
                Text(
                  m.raza,
                  style: const TextStyle(fontSize: 13, color: DogGoColors.grey),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _TagChip(label: m.edad, color: DogGoColors.teal),
                    const SizedBox(width: 6),
                    _TagChip(label: m.tamano, color: DogGoColors.purple),
                  ],
                ),
                if (m.nota != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: DogGoColors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: DogGoColors.orange.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Text('⚠️', style: TextStyle(fontSize: 11)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Notas: ${m.nota}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: DogGoColors.orange,
                              fontWeight: FontWeight.w600,
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
        ],
      ),
    );
  }

  Widget _buildAddMascotaCard() {
    return GestureDetector(
      onTap: () {},
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: DogGoColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: DogGoColors.teal.withOpacity(0.3),
            width: 2,
            style: BorderStyle.solid,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: DogGoColors.tealLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_rounded,
                color: DogGoColors.teal,
                size: 28,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Añadir mascota',
              style: TextStyle(
                color: DogGoColors.teal,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── STATS ROW ──
  Widget _buildStatsRow() {
    return FadeTransition(
      opacity: _cardsFade,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1ABC9C), Color(0xFF16A085)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: DogGoColors.teal.withOpacity(0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: const [
            _StatItem(value: '6', label: 'Mascotas\nregistradas', emoji: '🐕'),
            _StatDivider(),
            _StatItem(value: '3', label: 'Paseos\ncompletados', emoji: '✅'),
            _StatDivider(),
            _StatItem(value: 'Hikari', label: 'Último\npaseo', emoji: '📅'),
            _StatDivider(),
            _StatItem(value: '—', label: 'Sin paseos\nactivos', emoji: '⏳'),
          ],
        ),
      ),
    );
  }

  // ── PRÓXIMOS PASEOS ──
  Widget _buildPaseos() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _paseos.length,
      itemBuilder: (context, i) => _buildPaseoCard(_paseos[i], i),
    );
  }

  Widget _buildPaseoCard(_Paseo p, int index) {
    final isConfirmado = p.estado == 'Confirmado';
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + index * 150),
      curve: Curves.easeOut,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: child,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: DogGoColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  p.perro,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: DogGoColors.dark,
                  ),
                ),
                _StatusBadge(label: p.estado, isConfirmado: isConfirmado),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Paseador: ${p.paseador}',
              style: const TextStyle(color: DogGoColors.grey, fontSize: 13),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _InfoChip(icon: '📅', label: p.fecha),
                const SizedBox(width: 10),
                _InfoChip(icon: '⏱️', label: p.duracion),
                const SizedBox(width: 10),
                _InfoChip(icon: '💰', label: p.precio),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: DogGoColors.teal,
                      side: const BorderSide(
                        color: DogGoColors.teal,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text(
                      'Detalles',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DogGoColors.teal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Chat',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── ACCESOS RÁPIDOS ──
  Widget _buildAccesosRapidos() {
    final items = [
      _AccesoItem(
        'Mis perros',
        'Administra tus mascotas',
        '🐕',
        DogGoColors.purple,
      ),
      _AccesoItem(
        'Paseadores',
        'Busca paseadores disponibles',
        '👟',
        DogGoColors.teal,
      ),
      _AccesoItem('Mensajes', 'Chats con paseadores', '💬', DogGoColors.green),
      _AccesoItem(
        'Configuración',
        'Preferencias y seguridad',
        '⚙️',
        DogGoColors.grey,
      ),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '⚡ Accesos rápidos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: DogGoColors.dark,
            ),
          ),
          const SizedBox(height: 12),
          ...items.map((item) => _buildAccesoRow(item)),
        ],
      ),
    );
  }

  Widget _buildAccesoRow(_AccesoItem item) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: DogGoColors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(item.emoji, style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.titulo,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: DogGoColors.dark,
                    ),
                  ),
                  Text(
                    item.subtitulo,
                    style: const TextStyle(
                      fontSize: 12,
                      color: DogGoColors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: DogGoColors.greyLight,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  // ── CONSEJOS ──
  Widget _buildConsejos() {
    return SizedBox(
      height: 170,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _consejos.length,
        itemBuilder: (context, i) {
          final c = _consejos[i];
          final colors = [
            DogGoColors.teal,
            DogGoColors.purple,
            DogGoColors.green,
            DogGoColors.orange,
            DogGoColors.red,
            DogGoColors.tealDark,
          ];
          return GestureDetector(
            onTap: () {},
            child: Container(
              width: 160,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: DogGoColors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colors[i % colors.length].withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      c.categoria,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: colors[i % colors.length],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(c.emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(height: 8),
                  Text(
                    c.titulo,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: DogGoColors.dark,
                      height: 1.3,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Text(
                    c.tiempo,
                    style: const TextStyle(
                      fontSize: 10,
                      color: DogGoColors.grey,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── PRODUCTOS ──
  Widget _buildProductos() {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _productos.length,
        itemBuilder: (context, i) {
          final p = _productos[i];
          return GestureDetector(
            onTap: () {},
            child: Container(
              width: 155,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: DogGoColors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.emoji, style: const TextStyle(fontSize: 32)),
                  const SizedBox(height: 8),
                  _TagChip(label: p.categoria, color: DogGoColors.teal),
                  const SizedBox(height: 6),
                  Text(
                    p.nombre,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: DogGoColors.dark,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    p.descripcion,
                    style: const TextStyle(
                      fontSize: 10,
                      color: DogGoColors.grey,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      const Text('🛒', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      const Text(
                        'Ver en Amazon',
                        style: TextStyle(
                          fontSize: 10,
                          color: DogGoColors.teal,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── LUGARES ──
  Widget _buildLugares() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.6,
      ),
      itemCount: _lugares.length,
      itemBuilder: (context, i) {
        final l = _lugares[i];
        return GestureDetector(
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DogGoColors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: l.color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        l.emoji,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {},
                      child: const Text(
                        'Ver mapa',
                        style: TextStyle(
                          fontSize: 9,
                          color: DogGoColors.teal,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  l.nombre,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: DogGoColors.dark,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Row(
                  children: [
                    _TagChip(label: l.tipo, color: l.color, small: true),
                    const SizedBox(width: 4),
                    _TagChip(
                      label: l.subtipo,
                      color: DogGoColors.grey,
                      small: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── CURIOSIDADES ──
  Widget _buildCuriosidades() {
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _curiosidades.length,
        itemBuilder: (context, i) {
          final c = _curiosidades[i];
          return GestureDetector(
            onTap: () {},
            child: Container(
              width: 130,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: DogGoColors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(c.emoji, style: const TextStyle(fontSize: 24)),
                  const SizedBox(height: 4),
                  Text(
                    c.raza,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: DogGoColors.dark,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${c.peso} · ${c.tamano}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: DogGoColors.grey,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── CTA FINAL ──
  Widget _buildCTAFinal() {
    final services = [
      _CTAItem('Ver mis paseos', 'Activos, historial y seguimiento', '🐕'),
      _CTAItem('Buscar paseador', 'Encuentra el paseador perfecto', '🔍'),
      _CTAItem('Mis perros', 'Administra perfiles y datos', '🐾'),
      _CTAItem('Mi perfil', 'Configura tu foto, dirección y más', '👤'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: DogGoColors.teal.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              children: [
                Text(
                  '🚀 ¡TODO LISTO PARA TI!',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: DogGoColors.teal,
                    letterSpacing: 1,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Prueba nuestros servicios hoy',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: DogGoColors.dark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.0,
            ),
            itemCount: services.length,
            itemBuilder: (context, i) {
              final s = services[i];
              return GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: DogGoColors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(s.emoji, style: const TextStyle(fontSize: 20)),
                      const SizedBox(height: 4),
                      Text(
                        s.titulo,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: DogGoColors.dark,
                        ),
                      ),
                      Text(
                        s.subtitulo,
                        style: const TextStyle(
                          fontSize: 9,
                          color: DogGoColors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  WIDGETS HELPER
// ─────────────────────────────────────────────
class _BannerButton extends StatelessWidget {
  final String label;
  final bool isPrimary;
  final VoidCallback onTap;
  const _BannerButton({
    required this.label,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isPrimary ? Colors.white : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
          border: isPrimary
              ? null
              : Border.all(color: Colors.white.withOpacity(0.5)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isPrimary ? DogGoColors.teal : Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final String emoji;
  const _StatItem({
    required this.value,
    required this.label,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 9,
            height: 1.3,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      color: Colors.white.withOpacity(0.2),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool small;
  const _TagChip({
    required this.label,
    required this.color,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 6 : 8,
        vertical: small ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: small ? 9 : 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final bool isConfirmado;
  const _StatusBadge({required this.label, required this.isConfirmado});

  @override
  Widget build(BuildContext context) {
    final color = isConfirmado ? DogGoColors.green : DogGoColors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: DogGoColors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  MODELS
// ─────────────────────────────────────────────
class _Mascota {
  final String nombre, raza, edad, tamano, emoji;
  final String? nota;
  const _Mascota({
    required this.nombre,
    required this.raza,
    required this.edad,
    required this.tamano,
    required this.emoji,
    this.nota,
  });
}

class _Paseo {
  final String perro, paseador, fecha, duracion, precio, estado;
  const _Paseo({
    required this.perro,
    required this.paseador,
    required this.fecha,
    required this.duracion,
    required this.precio,
    required this.estado,
  });
}

class _Consejo {
  final String titulo, categoria, emoji, tiempo;
  const _Consejo({
    required this.titulo,
    required this.categoria,
    required this.emoji,
    required this.tiempo,
  });
}

class _Producto {
  final String nombre, descripcion, categoria, emoji;
  const _Producto({
    required this.nombre,
    required this.descripcion,
    required this.categoria,
    required this.emoji,
  });
}

class _Lugar {
  final String nombre, tipo, subtipo, emoji;
  final Color color;
  const _Lugar({
    required this.nombre,
    required this.tipo,
    required this.subtipo,
    required this.emoji,
    required this.color,
  });
}

class _Curiosidad {
  final String raza, peso, tamano, emoji;
  const _Curiosidad({
    required this.raza,
    required this.peso,
    required this.tamano,
    required this.emoji,
  });
}

class _AccesoItem {
  final String titulo, subtitulo, emoji;
  final Color color;
  const _AccesoItem(this.titulo, this.subtitulo, this.emoji, this.color);
}

class _CTAItem {
  final String titulo, subtitulo, emoji;
  const _CTAItem(this.titulo, this.subtitulo, this.emoji);
}

// ─────────────────────────────────────────────
//  PLACEHOLDER PARA OTRAS PANTALLAS
// ─────────────────────────────────────────────
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  const _PlaceholderScreen({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DogGoColors.cream,
      appBar: AppBar(
        backgroundColor: color,
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 60, color: color),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: DogGoColors.dark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Esta pantalla la está\ndesarrollando otro integrante',
              textAlign: TextAlign.center,
              style: const TextStyle(color: DogGoColors.grey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
