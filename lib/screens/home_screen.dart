import 'package:flutter/material.dart';

import '../services/session_service.dart';
import '../theme/doggo_theme.dart';
import 'chat_paseo_screen.dart';
import 'configuracion_screen.dart';
import 'detalle_paseo_screen.dart';
import 'home/home_controller.dart';
import 'home/home_state.dart';
import 'home/models/home_activity_item.dart';
import 'home/models/home_pet.dart';
import 'home/models/home_walk.dart';
import 'home/models/home_walk_status.dart';
import 'home/sections/home_activity_section.dart';
import 'home/sections/home_agenda_section.dart';
import 'home/sections/home_explore_section.dart';
import 'home/sections/home_explore_tab.dart';
import 'home/sections/home_header_section.dart';
import 'home/sections/home_pets_section.dart';
import 'home/sections/home_shortcuts_section.dart';
import 'home/sections/home_summary_section.dart';
import 'home/sections/home_walk_section.dart';
import 'home/sections/home_walker_panel_section.dart';
import 'home/sections/home_walkers_tab.dart';
import 'home/widgets/home_bottom_navigation.dart';
import 'home/widgets/home_top_bar.dart';
import 'login_screen.dart';
import 'mapa_paseo_screen.dart';
import 'mis_perros_screen.dart';
import 'mis_paseos_screen.dart';
import 'notificaciones_screen.dart';
import 'perfil_screen.dart';
import 'routes/saved_routes_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
  });

  @override
  State<HomeScreen> createState() {
    return _HomeScreenState();
  }
}

class _HomeScreenState
    extends State<HomeScreen> {
  late final HomeController _controller;

  int _navigationIndex = 0;

  HomeState get _state {
    return _controller.state;
  }

  @override
  void initState() {
    super.initState();

    _controller = HomeController();
    _controller.addListener(
      _onControllerChanged,
    );
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.removeListener(
      _onControllerChanged,
    );
    _controller.dispose();

    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _open(
    Widget screen,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => screen,
      ),
    );

    if (mounted) {
      await _controller.refresh();
    }
  }

  Future<void>
      _openNotifications() async {
    await _open(
      const NotificacionesScreen(),
    );

    if (mounted) {
      await _controller.loadNotifications(
        silent: true,
      );
    }
  }

  Future<void> _openWalkDetails(
    HomeWalk walk,
  ) async {
    final id = walk.id;

    if (id == null || id <= 0) {
      _showMessage(
        'No se encontró el identificador del paseo.',
        success: false,
      );
      return;
    }

    await _open(
      DetallePaseoScreen(
        paseoId: id,
        paseo: walk.rawData,
        rol: _state.role,
      ),
    );
  }

  Future<void> _openWalkMap(
    HomeWalk walk,
  ) async {
    final id = walk.id;

    if (id == null || id <= 0) {
      _showMessage(
        'No se encontró el identificador del paseo.',
        success: false,
      );
      return;
    }

    await _open(
      MapaPaseoScreen(
        paseo: walk.rawData,
      ),
    );
  }

  Future<void> _openWalkChat(
    HomeWalk walk,
  ) async {
    final id = walk.id;

    if (id == null || id <= 0) {
      _showMessage(
        'No se encontró el identificador del paseo.',
        success: false,
      );
      return;
    }

    await _open(
      ChatPaseoScreen(
        paseoId: id,
        nombrePerro: walk.petName,
        nombreOtroUsuario:
            _state.isWalker
                ? 'Dueño de ${walk.petName}'
                : walk.walkerName,
      ),
    );
  }

  Future<void> _openActivity(
    HomeActivityItem activity,
  ) async {
    if (activity.id != null &&
        !activity.read) {
      await _controller
          .markNotificationAsRead(
        activity.id!,
      );
    }

    if (!mounted) {
      return;
    }

    final referenceId =
        activity.referenceId;

    if (activity.type ==
            HomeActivityType.newMessage &&
        referenceId != null &&
        referenceId > 0) {
      await _open(
        ChatPaseoScreen(
          paseoId: referenceId,
          nombrePerro: 'Mascota',
          nombreOtroUsuario:
              'Conversación del paseo',
        ),
      );

      return;
    }

    if (referenceId != null &&
        referenceId > 0) {
      await _open(
        DetallePaseoScreen(
          paseoId: referenceId,
          rol: _state.role,
        ),
      );

      return;
    }

    await _open(
      const MisPaseosScreen(),
    );
  }

  Future<void> _closeSession() async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor:
              DogGoTheme.card,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(24),
          ),
          icon: const Icon(
            Icons.logout_rounded,
            color: DogGoTheme.red,
            size: 38,
          ),
          title: Text(
            'Cerrar sesión',
            textAlign: TextAlign.center,
            style: DogGoTheme.title(
              size: 22,
            ),
          ),
          content: Text(
            '¿Seguro que quieres salir de tu cuenta?',
            textAlign: TextAlign.center,
            style: DogGoTheme.subtitle(
              size: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Cancelar',
              ),
            ),
            FilledButton(
              style:
                  FilledButton.styleFrom(
                backgroundColor:
                    DogGoTheme.red,
                foregroundColor:
                    Colors.white,
              ),
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'Salir',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await SessionService.cerrarSesion();

    if (!mounted) {
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute<void>(
        builder: (_) =>
            const LoginScreen(),
      ),
      (_) => false,
    );
  }

  void _showMenu() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor:
          Colors.transparent,
      builder: (sheetContext) {
        final screenHeight =
            MediaQuery.sizeOf(
          sheetContext,
        ).height;

        return Container(
          constraints: BoxConstraints(
            maxHeight:
                screenHeight * 0.86,
          ),
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: DogGoTheme.card,
            borderRadius:
                BorderRadius.circular(26),
            boxShadow:
                DogGoTheme.softShadow(),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color:
                      DogGoTheme.border,
                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 18,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Menú',
                        style:
                            DogGoTheme.title(
                          size: 20,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Cerrar menú',
                      onPressed: () {
                        Navigator.pop(
                          sheetContext,
                        );
                      },
                      icon: const Icon(
                        Icons.close_rounded,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  physics:
                      const BouncingScrollPhysics(),
                  padding:
                      const EdgeInsets.fromLTRB(
                    18,
                    8,
                    18,
                    18,
                  ),
                  children: [
                    _HomeMenuItem(
                      icon: Icons
                          .notifications_outlined,
                      title:
                          'Notificaciones',
                      onTap: () {
                        Navigator.pop(
                          sheetContext,
                        );
                        _openNotifications();
                      },
                    ),
                    _HomeMenuItem(
                      icon: Icons
                          .person_outline_rounded,
                      title: 'Mi perfil',
                      onTap: () {
                        Navigator.pop(
                          sheetContext,
                        );
                        _open(
                          const PerfilScreen(),
                        );
                      },
                    ),
                    _HomeMenuItem(
                      icon: Icons
                          .settings_rounded,
                      title:
                          'Configuración',
                      onTap: () {
                        Navigator.pop(
                          sheetContext,
                        );
                        _open(
                          const ConfiguracionScreen(),
                        );
                      },
                    ),
                    _HomeMenuItem(
                      icon:
                          Icons.route_rounded,
                      title: 'Mis paseos',
                      onTap: () {
                        Navigator.pop(
                          sheetContext,
                        );
                        _open(
                          const MisPaseosScreen(),
                        );
                      },
                    ),
                    if (_state.isOwner ||
                        _state.isAdmin)
                      _HomeMenuItem(
                        icon:
                            Icons.pets_rounded,
                        title:
                            'Mis mascotas',
                        onTap: () {
                          Navigator.pop(
                            sheetContext,
                          );
                          _open(
                            const MisPerrosScreen(),
                          );
                        },
                      ),
                    const Divider(
                      height: 18,
                    ),
                    if (_state.isOwner ||
                        _state.isAdmin)
                      _HomeMenuItem(
                        icon:
                            Icons.alt_route_rounded,
                        title:
                            'Mis rutas',
                        onTap: () {
                          Navigator.pop(
                            sheetContext,
                          );
                          _open(
                            SavedRoutesScreen(),
                          );
                        },
                      ),
                    _HomeMenuItem(
                      icon:
                          Icons.logout_rounded,
                      title:
                          'Cerrar sesión',
                      danger: true,
                      onTap: () {
                        Navigator.pop(
                          sheetContext,
                        );
                        _closeSession();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _setNavigationIndex(
    int index,
  ) {
    if (_navigationIndex == index) {
      return;
    }

    setState(() {
      _navigationIndex = index;
    });
  }

  void _handleThirdNavigation() {
    _setNavigationIndex(2);
  }

  void _openWalkersTab() {
    _setNavigationIndex(2);
  }

  void _showMessage(
    String message, {
    bool success = true,
  }) {
    if (!mounted) {
      return;
    }

    final messenger =
        ScaffoldMessenger.of(context);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior:
              SnackBarBehavior.floating,
          backgroundColor: success
              ? DogGoTheme.teal
              : DogGoTheme.red,
          content: Row(
            children: [
              Icon(
                success
                    ? Icons
                        .check_circle_rounded
                    : Icons.error_rounded,
                color: Colors.white,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(message),
              ),
            ],
          ),
        ),
      );
  }

  String get _walkerPanelKey {
    final values = _state.walks.map(
      (walk) {
        return '${walk.id}-${walk.status.name}';
      },
    ).join('|');

    return 'walker-panel-$values';
  }

  @override
  Widget build(BuildContext context) {
    if (_state.initialLoading) {
      return const Scaffold(
        backgroundColor:
            DogGoTheme.cream,
        body: Center(
          child:
              CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
          DogGoTheme.cream,
      extendBody: true,
      bottomNavigationBar:
          HomeBottomNavigation(
        currentIndex: _navigationIndex,
        thirdLabel: _state.isWalker
            ? 'Panel'
            : 'Paseadores',
        thirdIcon: _state.isWalker
            ? Icons
                .dashboard_customize_rounded
            : Icons.person_search_rounded,
        fourthLabel: 'Explorar',
        fourthIcon: Icons.explore_rounded,
        onHome: () {
          _setNavigationIndex(0);
        },
        onAgenda: () {
          _setNavigationIndex(1);
        },
        onThird:
            _handleThirdNavigation,
        onFourth: () {
          _setNavigationIndex(3);
        },
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh:
              _controller.refresh,
          child: CustomScrollView(
            key:
                ValueKey(_navigationIndex),
            keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior
                    .onDrag,
            physics:
                const AlwaysScrollableScrollPhysics(
              parent:
                  BouncingScrollPhysics(),
            ),
            slivers: [
              SliverAppBar(
                pinned: true,
                automaticallyImplyLeading:
                    false,
                backgroundColor:
                    DogGoTheme.card,
                elevation: 0,
                surfaceTintColor:
                    Colors.transparent,
                toolbarHeight: 78,
                titleSpacing: 0,
                title: HomeTopBar(
                  role: _state.role,
                  isWalker:
                      _state.isWalker,
                  unreadNotifications:
                      _state
                          .unreadNotifications,
                  onNotificationsTap:
                      _openNotifications,
                  onMenuTap: _showMenu,
                ),
              ),
              SliverToBoxAdapter(
                child: AnimatedSwitcher(
                  duration:
                      const Duration(
                    milliseconds: 280,
                  ),
                  switchInCurve:
                      Curves.easeOutCubic,
                  switchOutCurve:
                      Curves.easeInCubic,
                  child: KeyedSubtree(
                    key: ValueKey(
                      _navigationIndex,
                    ),
                    child:
                        _buildSelectedContent(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedContent() {
    switch (_navigationIndex) {
      case 1:
        return HomeAgendaSection(
          loading:
              _state.walksLoading,
          errorMessage:
              _state.walksError,
          walks:
              _state.upcomingWalks,
          onWalkTap:
              _openWalkDetails,
          onSeeAll: () {
            _open(
              const MisPaseosScreen(),
            );
          },
          onRetry:
              _controller.loadWalks,
        );

      case 2:
        if (_state.isWalker) {
          return HomeWalkerPanelSection(
            key:
                ValueKey(_walkerPanelKey),
            available: false,
            loading:
                _state.walksLoading,
            walks: _state.walks,
            onAvailabilityChanged:
                (_) {},
            onWalkTap:
                _openWalkDetails,
            onWalkDetails:
                _openWalkDetails,
            onWalkMap: _openWalkMap,
            onWalkChat: _openWalkChat,
            onProfileTap: () {
              _open(
                const PerfilScreen(),
              );
            },
            onWalksTap: () {
              _open(
                const MisPaseosScreen(),
              );
            },
          );
        }

        return const HomeWalkersTab();

      case 3:
        return HomeExploreTab(
          onWalkers:
              _openWalkersTab,
          onPets: () {
            _open(
              const MisPerrosScreen(),
            );
          },
          onWalks: () {
            _open(
              const MisPaseosScreen(),
            );
          },
          onProfile: () {
            _open(
              const PerfilScreen(),
            );
          },
        );

      case 0:
      default:
        return _buildHomeOverview();
    }
  }

  Widget _buildHomeOverview() {
    final priorityWalk =
        _state.priorityWalk;

    return Padding(
      padding: const EdgeInsets.only(
        bottom: 120,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          HomeHeaderSection(
            userName: _state.userName,
            role: _state.role,
            petCount:
                _state.pets.length,
            upcomingWalkCount:
                _state
                    .upcomingWalks.length,
            isWalker: _state.isWalker,
          ),
          _buildWalkSection(
            priorityWalk,
          ),
          if (_state.isOwner ||
              _state.isAdmin)
            HomePetsSection(
              loading:
                  _state.petsLoading,
              errorMessage:
                  _state.petsError,
              pets: _state.pets
                  .take(6)
                  .map(_petItem)
                  .toList(
                    growable: false,
                  ),
              onSeeAll: () {
                _open(
                  const MisPerrosScreen(),
                );
              },
              onAddPet: () {
                _open(
                  const MisPerrosScreen(),
                );
              },
              onRetry:
                  _controller.loadPets,
            ),
          HomeShortcutsSection(
            isWalker: _state.isWalker,
            onPetsOrProfile: () {
              if (_state.isWalker) {
                _open(
                  const PerfilScreen(),
                );
              } else {
                _open(
                  const MisPerrosScreen(),
                );
              }
            },
            onAgenda: () {
              _setNavigationIndex(1);
            },
            onWalks: () {
              _open(
                const MisPaseosScreen(),
              );
            },
            onExplore: () {
              _setNavigationIndex(3);
            },
          ),
          HomeActivitySection(
            loading: _state
                .notificationsLoading,
            activities:
                _state.recentActivities,
            onSeeAll:
                _openNotifications,
            onActivityTap:
                _openActivity,
          ),
          HomeSummarySection(
            loading:
                _state.walksLoading,
            summary:
                _state.weeklySummary,
          ),
          HomeExploreSection(
            onWalkers:
                _openWalkersTab,
            onGuides: () {
              _setNavigationIndex(3);
            },
            onPlaces: () {
              _setNavigationIndex(3);
            },
            onExploreAll: () {
              _setNavigationIndex(3);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWalkSection(
    HomeWalk? walk,
  ) {
    if (walk == null) {
      final firstPet =
          _state.pets.isEmpty
              ? null
              : _state.pets.first;

      final petName =
          firstPet?.name ??
              'tu mascota';

      return HomeWalkSection(
        loading:
            _state.walksLoading,
        errorMessage:
            _state.walksError,
        eyebrow:
            HomeWalkStatus.none.eyebrow,
        title: _state.isWalker
            ? 'Revisa tu panel operativo'
            : 'Solicita un paseo para $petName',
        subtitle: _state.isWalker
            ? 'Administra tu disponibilidad, solicitudes y próximos servicios.'
            : 'Encuentra un paseador disponible y agenda en minutos.',
        statusText:
            HomeWalkStatus.none.label,
        statusColor:
            DogGoTheme.green,
        imageUrl:
            firstPet?.imageUrl ?? '',
        primaryLabel: _state.isWalker
            ? 'Abrir panel'
            : 'Solicitar paseo',
        secondaryLabel: _state.isWalker
            ? 'Mi perfil'
            : 'Ver paseadores',
        onPrimary: () {
          if (_state.isWalker) {
            _setNavigationIndex(2);
          } else {
            _openWalkersTab();
          }
        },
        onSecondary: () {
          if (_state.isWalker) {
            _open(
              const PerfilScreen(),
            );
          } else {
            _openWalkersTab();
          }
        },
        onRetry:
            _controller.loadWalks,
      );
    }

    return HomeWalkSection(
      loading: _state.walksLoading,
      errorMessage:
          _state.walksError,
      eyebrow: walk.status.eyebrow,
      title:
          'Paseo para ${walk.petName}',
      subtitle:
          '${walk.formattedSchedule} · ${_walkSubtitle(walk)}',
      statusText: walk.status.label,
      statusColor:
          _walkStatusColor(
        walk.status,
      ),
      imageUrl: walk.imageUrl,
      imageUrls: walk.petImageUrls,
      petCount: walk.petCount,
      primaryLabel: walk.isInProgress
          ? 'Ver recorrido'
          : 'Ver detalles',
      secondaryLabel: walk.isInProgress
          ? 'Abrir chat'
          : _state.isWalker
              ? 'Abrir panel'
              : 'Mis paseos',
      onPrimary: () {
        if (walk.isInProgress) {
          _openWalkMap(walk);
        } else {
          _openWalkDetails(walk);
        }
      },
      onSecondary: () {
        if (walk.isInProgress) {
          _openWalkChat(walk);
        } else if (_state.isWalker) {
          _setNavigationIndex(2);
        } else {
          _open(
            const MisPaseosScreen(),
          );
        }
      },
      onRetry:
          _controller.loadWalks,
    );
  }

  String _walkSubtitle(
    HomeWalk walk,
  ) {
    if (_state.isWalker) {
      if (walk.pickupAddress
          .isNotEmpty) {
        return walk.pickupAddress;
      }

      return 'Servicio asignado';
    }

    return 'Con ${walk.walkerName}';
  }

  HomePetItem _petItem(
    HomePet pet,
  ) {
    return HomePetItem(
      name: pet.name,
      breed: pet.breed,
      age: pet.ageLabel,
      imageUrl: pet.imageUrl,
      onTap: () {
        _open(
          const MisPerrosScreen(),
        );
      },
    );
  }

  Color _walkStatusColor(
    HomeWalkStatus status,
  ) {
    switch (status) {
      case HomeWalkStatus.pending:
        return DogGoTheme.orange;

      case HomeWalkStatus.accepted:
      case HomeWalkStatus.inProgress:
        return DogGoTheme.teal;

      case HomeWalkStatus.completed:
        return DogGoTheme.green;

      case HomeWalkStatus.cancelled:
      case HomeWalkStatus.rejected:
        return DogGoTheme.red;

      case HomeWalkStatus.none:
      case HomeWalkStatus.unknown:
        return DogGoTheme.muted;
    }
  }
}

class _HomeMenuItem
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool danger;

  const _HomeMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger
        ? DogGoTheme.red
        : DogGoTheme.ink;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(16),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(
            vertical: 12,
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: danger
                      ? DogGoTheme.redLight
                      : DogGoTheme.tealLight,
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
                child: Icon(
                  icon,
                  color: danger
                      ? DogGoTheme.red
                      : DogGoTheme.teal,
                  size: 21,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  title,
                  style: DogGoTheme.body(
                    size: 14,
                    color: color,
                    weight:
                        FontWeight.w800,
                  ),
                ),
              ),
              Icon(
                Icons
                    .chevron_right_rounded,
                color: danger
                    ? DogGoTheme.red
                    : DogGoTheme.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}