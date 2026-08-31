import 'package:flutter/material.dart';

import '../../services/app_preferences_service.dart';
import '../../shared/widgets/doggo_empty_view.dart';
import '../../shared/widgets/doggo_error_view.dart';
import '../../shared/widgets/doggo_loading_view.dart';
import '../../shared/widgets/doggo_network_image.dart';
import '../../shared/widgets/doggo_screen_scaffold.dart';
import '../../shared/widgets/doggo_search_field.dart';
import '../../shared/widgets/doggo_status_chip.dart';
import '../../theme/doggo_radius.dart';
import '../../theme/doggo_spacing.dart';
import '../../theme/doggo_theme.dart';
import '../crear_paseo_screen.dart';
import '../detalle_paseador_screen.dart';
import 'models/walker.dart';
import 'walkers_controller.dart';
import 'walkers_state.dart';

class WalkersScreen extends StatefulWidget {
  final int? initialPetId;

  const WalkersScreen({super.key, this.initialPetId});

  @override
  State<WalkersScreen> createState() => _WalkersScreenState();
}

class _WalkersScreenState extends State<WalkersScreen> {
  late final WalkersController _controller;

  final TextEditingController _searchController = TextEditingController();
  Set<int> _favoriteIds = {};
  List<int> _recentIds = const [];
  bool _onlyFavorites = false;

  @override
  void initState() {
    super.initState();

    _controller = WalkersController()..initialize();
    _loadLocalWalkerPreferences();
  }

  Future<void> _loadLocalWalkerPreferences() async {
    final favorites = await AppPreferencesService.favoriteWalkerIds();
    final recent = await AppPreferencesService.recentWalkerIds();
    if (!mounted) return;
    setState(() {
      _favoriteIds = favorites;
      _recentIds = recent;
    });
  }

  Future<void> _toggleFavorite(Walker walker) async {
    final favorite = await AppPreferencesService.toggleFavoriteWalker(
      walker.id,
    );
    if (!mounted) return;
    setState(() {
      favorite ? _favoriteIds.add(walker.id) : _favoriteIds.remove(walker.id);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool error = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: error ? DogGoTheme.red : DogGoTheme.ink,
          content: Row(
            children: [
              Icon(
                error
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_outline_rounded,
                color: Colors.white,
              ),
              const SizedBox(width: DogGoSpacing.compactGap),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }

  void _clearSearch() {
    _searchController.clear();
    _controller.search('');
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _clearFilters() {
    _searchController.clear();
    _controller.clearFilters();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  Future<void> _openDetail(Walker walker) async {
    await AppPreferencesService.rememberWalker(walker.id);
    if (!mounted) return;
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => DetallePaseadorScreen(
          paseador: walker.toNavigationMap(),
          initialPetId: widget.initialPetId,
        ),
      ),
    );

    if (mounted) {
      await _loadLocalWalkerPreferences();
      await _controller.refresh();
    }
  }

  Future<void> _requestWalk(Walker walker) async {
    if (!walker.available) {
      _showMessage(
        '${walker.name} no está disponible en este momento.',
        error: true,
      );
      return;
    }
    await AppPreferencesService.rememberWalker(walker.id);
    if (!mounted) return;

    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => CrearPaseoScreen(
          paseador: walker.toNavigationMap(),
          initialPetId: widget.initialPetId,
        ),
      ),
    );

    if (!mounted) return;

    if (created == true) {
      _showMessage('Paseo solicitado correctamente.');

      await _controller.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final state = _controller.state;

        return DogGoScreenScaffold(
          title: 'Paseadores',
          actions: [
            IconButton(
              tooltip: 'Actualizar paseadores',
              onPressed: state.loading ? null : _controller.refresh,
              icon: const Icon(Icons.refresh_rounded),
            ),
            const SizedBox(width: DogGoSpacing.sm),
          ],
          body: _buildBody(state),
        );
      },
    );
  }

  Widget _buildBody(WalkersState state) {
    if (state.loading && state.walkers.isEmpty) {
      return const DogGoLoadingView(message: 'Buscando paseadores...');
    }

    if (state.error != null && state.walkers.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(DogGoSpacing.screenHorizontal),
          child: DogGoErrorView(
            title: 'No pudimos cargar los paseadores',
            message: state.error!,
            onRetry: _controller.refresh,
          ),
        ),
      );
    }

    final walkers =
        state.filteredWalkers
            .where(
              (walker) => !_onlyFavorites || _favoriteIds.contains(walker.id),
            )
            .toList()
          ..sort((left, right) {
            final favorite =
                (_favoriteIds.contains(right.id) ? 1 : 0) -
                (_favoriteIds.contains(left.id) ? 1 : 0);
            if (favorite != 0) return favorite;
            final leftRecent = _recentIds.indexOf(left.id);
            final rightRecent = _recentIds.indexOf(right.id);
            if (leftRecent < 0 && rightRecent < 0) return 0;
            if (leftRecent < 0) return 1;
            if (rightRecent < 0) return -1;
            return leftRecent.compareTo(rightRecent);
          });

    return RefreshIndicator(
      onRefresh: _controller.refresh,
      child: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              DogGoSpacing.screenHorizontal,
              DogGoSpacing.md,
              DogGoSpacing.screenHorizontal,
              0,
            ),
            sliver: SliverToBoxAdapter(child: _WalkersHeader(state: state)),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              DogGoSpacing.screenHorizontal,
              DogGoSpacing.sm,
              DogGoSpacing.screenHorizontal,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  FilterChip(
                    selected: _onlyFavorites,
                    avatar: const Icon(Icons.favorite_rounded, size: 17),
                    label: Text('Favoritos (${_favoriteIds.length})'),
                    onSelected: (value) =>
                        setState(() => _onlyFavorites = value),
                  ),
                  const SizedBox(width: 8),
                  if (_recentIds.isNotEmpty)
                    Text(
                      '${_recentIds.length} vistos recientemente',
                      style: DogGoTheme.caption(size: 10.5),
                    ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              DogGoSpacing.screenHorizontal,
              DogGoSpacing.md,
              DogGoSpacing.screenHorizontal,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: DogGoSearchField(
                controller: _searchController,
                onChanged: _controller.search,
                hintText: 'Buscar por nombre, zona o experiencia',
                hasValue: state.searchQuery.isNotEmpty,
                onClear: _clearSearch,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              DogGoSpacing.screenHorizontal,
              DogGoSpacing.md,
              DogGoSpacing.screenHorizontal,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: _FiltersCard(
                state: state,
                onZoneChanged: _controller.selectZone,
                onSortChanged: _controller.setSort,
                onAvailableChanged: _controller.setOnlyAvailable,
                onClear: _clearFilters,
              ),
            ),
          ),
          if (state.error != null && state.walkers.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                DogGoSpacing.screenHorizontal,
                DogGoSpacing.md,
                DogGoSpacing.screenHorizontal,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: DogGoErrorView(
                  message: state.error!,
                  onRetry: _controller.refresh,
                  compact: true,
                ),
              ),
            ),
          if (state.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.all(DogGoSpacing.screenHorizontal),
                child: Center(
                  child: DogGoEmptyView(
                    title: 'No hay paseadores',
                    message:
                        'Todavía no existen paseadores disponibles en DogGo.',
                    icon: Icons.person_search_outlined,
                    actionText: 'Actualizar',
                    onAction: _controller.refresh,
                  ),
                ),
              ),
            )
          else if (walkers.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.all(DogGoSpacing.screenHorizontal),
                child: Center(
                  child: DogGoEmptyView(
                    title: 'Sin coincidencias',
                    message:
                        'No encontramos paseadores con los filtros seleccionados.',
                    icon: Icons.filter_alt_off_outlined,
                    actionText: 'Limpiar filtros',
                    onAction: _clearFilters,
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                DogGoSpacing.screenHorizontal,
                DogGoSpacing.lg,
                DogGoSpacing.screenHorizontal,
                DogGoSpacing.xxl,
              ),
              sliver: SliverList.separated(
                itemCount: walkers.length,
                separatorBuilder: (_, _) {
                  return const SizedBox(height: DogGoSpacing.md);
                },
                itemBuilder: (context, index) {
                  final walker = walkers[index];

                  return _WalkerCard(
                    walker: walker,
                    photoUrl: state.photoUrlFor(walker),
                    onViewProfile: () {
                      _openDetail(walker);
                    },
                    onRequest: () {
                      _requestWalk(walker);
                    },
                    favorite: _favoriteIds.contains(walker.id),
                    recent: _recentIds.contains(walker.id),
                    onFavorite: () => _toggleFavorite(walker),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _WalkersHeader extends StatelessWidget {
  final WalkersState state;

  const _WalkersHeader({required this.state});

  @override
  Widget build(BuildContext context) {
    final rating = state.averageRating;

    return Container(
      padding: const EdgeInsets.all(DogGoSpacing.cardPadding),
      decoration: BoxDecoration(
        color: DogGoTheme.tealLight,
        borderRadius: BorderRadius.circular(DogGoRadius.large),
        border: Border.all(color: DogGoTheme.teal.withValues(alpha: 0.13)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: DogGoTheme.card,
                  borderRadius: BorderRadius.circular(DogGoRadius.medium),
                ),
                child: const Icon(
                  Icons.person_search_outlined,
                  color: DogGoTheme.teal,
                  size: 28,
                ),
              ),
              const SizedBox(width: DogGoSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Encuentra un paseador',
                      style: DogGoTheme.title(size: 20),
                    ),
                    const SizedBox(height: DogGoSpacing.xs),
                    Text(
                      'Compara disponibilidad, zona, tarifa y experiencia.',
                      style: DogGoTheme.subtitle(size: 12.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: DogGoSpacing.md),
          Row(
            children: [
              Expanded(
                child: _HeaderStat(
                  value: '${state.totalWalkers}',
                  label: 'Paseadores',
                ),
              ),
              const _HeaderDivider(),
              Expanded(
                child: _HeaderStat(
                  value: '${state.availableWalkers}',
                  label: 'Disponibles',
                ),
              ),
              const _HeaderDivider(),
              Expanded(
                child: _HeaderStat(
                  value: rating > 0 ? rating.toStringAsFixed(1) : '—',
                  label: 'Promedio',
                  icon: rating > 0 ? Icons.star_rounded : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final String value;
  final String label;
  final IconData? icon;

  const _HeaderStat({required this.value, required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 17, color: DogGoTheme.orange),
              const SizedBox(width: 3),
            ],
            Text(
              value,
              style: DogGoTheme.title(size: 18, color: DogGoTheme.teal),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: DogGoTheme.caption(size: 10),
        ),
      ],
    );
  }
}

class _HeaderDivider extends StatelessWidget {
  const _HeaderDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 34,
      color: DogGoTheme.teal.withValues(alpha: 0.15),
    );
  }
}

class _FiltersCard extends StatelessWidget {
  final WalkersState state;
  final ValueChanged<String?> onZoneChanged;
  final ValueChanged<WalkerSort?> onSortChanged;
  final ValueChanged<bool> onAvailableChanged;
  final VoidCallback onClear;

  const _FiltersCard({
    required this.state,
    required this.onZoneChanged,
    required this.onSortChanged,
    required this.onAvailableChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DogGoSpacing.cardPadding),
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(DogGoRadius.large),
        border: Border.all(color: DogGoTheme.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.tune_rounded, color: DogGoTheme.teal),
              const SizedBox(width: DogGoSpacing.compactGap),
              Expanded(
                child: Text('Filtros', style: DogGoTheme.title(size: 16)),
              ),
              if (state.hasActiveFilters)
                TextButton(onPressed: onClear, child: const Text('Limpiar')),
            ],
          ),
          const SizedBox(height: DogGoSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: state.availableZones.contains(state.selectedZone)
                ? state.selectedZone
                : WalkersState.allZones,
            decoration: const InputDecoration(
              labelText: 'Zona',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
            items: state.availableZones
                .map((zone) {
                  return DropdownMenuItem<String>(
                    value: zone,
                    child: Text(zone, overflow: TextOverflow.ellipsis),
                  );
                })
                .toList(growable: false),
            onChanged: onZoneChanged,
          ),
          const SizedBox(height: DogGoSpacing.fieldGap),
          DropdownButtonFormField<WalkerSort>(
            initialValue: state.sort,
            decoration: const InputDecoration(
              labelText: 'Ordenar por',
              prefixIcon: Icon(Icons.sort_rounded),
            ),
            items: WalkerSort.values
                .map((sort) {
                  return DropdownMenuItem<WalkerSort>(
                    value: sort,
                    child: Text(sort.label),
                  );
                })
                .toList(growable: false),
            onChanged: onSortChanged,
          ),
          const SizedBox(height: DogGoSpacing.sm),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: state.onlyAvailable,
            onChanged: onAvailableChanged,
            secondary: const Icon(
              Icons.event_available_outlined,
              color: DogGoTheme.green,
            ),
            title: Text(
              'Solo disponibles',
              style: DogGoTheme.body(weight: FontWeight.w800),
            ),
            subtitle: Text(
              'Ocultar paseadores ocupados.',
              style: DogGoTheme.subtitle(size: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _WalkerCard extends StatelessWidget {
  final Walker walker;
  final String? photoUrl;
  final VoidCallback onViewProfile;
  final VoidCallback onRequest;
  final bool favorite;
  final bool recent;
  final VoidCallback onFavorite;

  const _WalkerCard({
    required this.walker,
    required this.photoUrl,
    required this.onViewProfile,
    required this.onRequest,
    required this.favorite,
    required this.recent,
    required this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(DogGoRadius.large),
        border: Border.all(color: DogGoTheme.border),
        boxShadow: DogGoTheme.softShadow(),
      ),
      child: InkWell(
        onTap: onViewProfile,
        child: Padding(
          padding: const EdgeInsets.all(DogGoSpacing.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _WalkerPhoto(walker: walker, photoUrl: photoUrl),
                  const SizedBox(width: DogGoSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                walker.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: DogGoTheme.title(size: 18),
                              ),
                            ),
                            if (walker.verified)
                              const Padding(
                                padding: EdgeInsets.only(left: 5),
                                child: Icon(
                                  Icons.verified_rounded,
                                  color: DogGoTheme.teal,
                                  size: 19,
                                ),
                              ),
                            IconButton(
                              tooltip: favorite
                                  ? 'Quitar de favoritos'
                                  : 'Agregar a favoritos',
                              visualDensity: VisualDensity.compact,
                              onPressed: onFavorite,
                              icon: Icon(
                                favorite
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                color: favorite
                                    ? DogGoTheme.red
                                    : DogGoTheme.muted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: DogGoSpacing.xs),
                        _AvailabilityLabel(available: walker.available),
                        const SizedBox(height: DogGoSpacing.compactGap),
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: DogGoTheme.orange,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              walker.ratingLabel,
                              style: DogGoTheme.body(
                                size: 12.5,
                                weight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                '· ${walker.reviewCountLabel}',
                                overflow: TextOverflow.ellipsis,
                                style: DogGoTheme.caption(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DogGoSpacing.md),
              Text(
                walker.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: DogGoTheme.subtitle(size: 13),
              ),
              const SizedBox(height: DogGoSpacing.compactGap),
              Wrap(
                spacing: DogGoSpacing.sm,
                runSpacing: DogGoSpacing.sm,
                children: [
                  if (recent)
                    const _WalkerAttribute(
                      icon: Icons.history_rounded,
                      text: 'Visto recientemente',
                    ),
                  _WalkerAttribute(
                    icon: Icons.location_on_outlined,
                    text: walker.proximityLabel,
                  ),
                  _WalkerAttribute(
                    icon: Icons.workspace_premium_outlined,
                    text: walker.experienceLabel,
                  ),
                ],
              ),
              const SizedBox(height: DogGoSpacing.md),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: DogGoTheme.cream,
                  borderRadius: BorderRadius.circular(DogGoRadius.medium),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        walker.rateLabel,
                        style: DogGoTheme.body(
                          color: DogGoTheme.teal,
                          weight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      walker.completedWalksLabel,
                      style: DogGoTheme.caption(size: 10.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: DogGoSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onViewProfile,
                      child: const Text('Ver perfil'),
                    ),
                  ),
                  const SizedBox(width: DogGoSpacing.compactGap),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: walker.available ? onRequest : null,
                      child: Text(
                        walker.available ? 'Solicitar' : 'No disponible',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WalkerPhoto extends StatelessWidget {
  final Walker walker;
  final String? photoUrl;

  const _WalkerPhoto({required this.walker, required this.photoUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 82,
      height: 82,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: DogGoTheme.tealLight,
        borderRadius: BorderRadius.circular(DogGoRadius.medium),
      ),
      child: DogGoNetworkImage(
        url: photoUrl,
        semanticLabel: 'Fotografía de ${walker.name}',
        fallback: _WalkerPlaceholder(initials: walker.initials),
      ),
    );
  }
}

class _WalkerPlaceholder extends StatelessWidget {
  final String initials;

  const _WalkerPlaceholder({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: DogGoTheme.title(size: 21, color: DogGoTheme.teal),
      ),
    );
  }
}

class _AvailabilityLabel extends StatelessWidget {
  final bool available;

  const _AvailabilityLabel({required this.available});

  @override
  Widget build(BuildContext context) {
    return DogGoStatusChip(
      label: available ? 'Disponible' : 'No disponible',
      icon: available
          ? Icons.check_circle_outline_rounded
          : Icons.schedule_rounded,
      tone: available ? DogGoStatusTone.positive : DogGoStatusTone.attention,
    );
  }
}

class _WalkerAttribute extends StatelessWidget {
  final IconData icon;
  final String text;

  const _WalkerAttribute({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 250),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: DogGoTheme.purpleLight,
        borderRadius: BorderRadius.circular(DogGoRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: DogGoTheme.purple, size: 15),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: DogGoTheme.caption(
                size: 10.5,
                color: DogGoTheme.purple,
                weight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
