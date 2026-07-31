import 'package:flutter/material.dart';

import '../../../theme/doggo_radius.dart';
import '../../../theme/doggo_spacing.dart';
import '../../../theme/doggo_theme.dart';
import '../../crear_paseo_screen.dart';
import '../../detalle_paseador_screen.dart';
import '../../walkers/models/walker.dart';
import '../../walkers/walkers_controller.dart';
import '../../walkers/walkers_state.dart';

class HomeWalkersTab extends StatefulWidget {
  const HomeWalkersTab({super.key});

  @override
  State<HomeWalkersTab> createState() =>
      _HomeWalkersTabState();
}

class _HomeWalkersTabState
    extends State<HomeWalkersTab> {
  late final WalkersController _controller;

  final TextEditingController _searchController =
      TextEditingController();

  @override
  void initState() {
    super.initState();

    _controller = WalkersController()
      ..initialize();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _clearFilters() {
    _searchController.clear();
    _controller.clearFilters();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  Future<void> _openDetail(Walker walker) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => DetallePaseadorScreen(
          paseador: walker.toNavigationMap(),
        ),
      ),
    );

    if (mounted) {
      await _controller.refresh();
    }
  }

  Future<void> _requestWalk(Walker walker) async {
    if (!walker.available) return;

    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => CrearPaseoScreen(
          paseador: walker.toNavigationMap(),
        ),
      ),
    );

    if (!mounted || created != true) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Paseo solicitado correctamente.',
        ),
      ),
    );

    await _controller.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final state = _controller.state;

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            DogGoSpacing.screenHorizontal,
            DogGoSpacing.lg,
            DogGoSpacing.screenHorizontal,
            120,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(state),
              const SizedBox(height: DogGoSpacing.md),
              _buildSearch(state),
              const SizedBox(height: DogGoSpacing.md),
              _buildFilters(state),
              const SizedBox(height: DogGoSpacing.lg),
              _buildResults(state),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(WalkersState state) {
    return Container(
      padding: const EdgeInsets.all(
        DogGoSpacing.cardPadding,
      ),
      decoration: BoxDecoration(
        color: DogGoTheme.tealLight,
        borderRadius: BorderRadius.circular(
          DogGoRadius.large,
        ),
        border: Border.all(
          color: DogGoTheme.teal.withValues(
            alpha: 0.13,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: DogGoTheme.card,
              borderRadius: BorderRadius.circular(
                DogGoRadius.medium,
              ),
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
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Encuentra un paseador',
                  style: DogGoTheme.title(size: 20),
                ),
                const SizedBox(height: DogGoSpacing.xs),
                Text(
                  state.loading
                      ? 'Buscando paseadores...'
                      : '${state.availableWalkers} disponibles de ${state.totalWalkers}',
                  style: DogGoTheme.subtitle(
                    size: 12.5,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Actualizar',
            onPressed:
                state.loading ? null : _controller.refresh,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch(WalkersState state) {
    return TextField(
      controller: _searchController,
      textInputAction: TextInputAction.search,
      onChanged: _controller.search,
      decoration: InputDecoration(
        hintText: 'Buscar por nombre o zona',
        prefixIcon: const Icon(
          Icons.search_rounded,
        ),
        suffixIcon: state.searchQuery.isNotEmpty
            ? IconButton(
                tooltip: 'Limpiar búsqueda',
                onPressed: () {
                  _searchController.clear();
                  _controller.search('');
                },
                icon: const Icon(
                  Icons.close_rounded,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildFilters(WalkersState state) {
    return Container(
      padding: const EdgeInsets.all(
        DogGoSpacing.cardPadding,
      ),
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(
          DogGoRadius.large,
        ),
        border: Border.all(
          color: DogGoTheme.border,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.tune_rounded,
                color: DogGoTheme.teal,
              ),
              const SizedBox(
                width: DogGoSpacing.compactGap,
              ),
              Expanded(
                child: Text(
                  'Filtrar resultados',
                  style: DogGoTheme.title(
                    size: 16,
                  ),
                ),
              ),
              if (state.hasActiveFilters)
                TextButton(
                  onPressed: _clearFilters,
                  child: const Text('Limpiar'),
                ),
            ],
          ),
          const SizedBox(height: DogGoSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: state.availableZones.contains(
              state.selectedZone,
            )
                ? state.selectedZone
                : WalkersState.allZones,
            decoration: const InputDecoration(
              labelText: 'Zona',
              prefixIcon: Icon(
                Icons.location_on_outlined,
              ),
            ),
            items: state.availableZones.map(
              (zone) {
                return DropdownMenuItem<String>(
                  value: zone,
                  child: Text(
                    zone,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ).toList(growable: false),
            onChanged: _controller.selectZone,
          ),
          const SizedBox(
            height: DogGoSpacing.fieldGap,
          ),
          DropdownButtonFormField<WalkerSort>(
            initialValue: state.sort,
            decoration: const InputDecoration(
              labelText: 'Ordenar por',
              prefixIcon: Icon(
                Icons.sort_rounded,
              ),
            ),
            items: WalkerSort.values.map(
              (sort) {
                return DropdownMenuItem<WalkerSort>(
                  value: sort,
                  child: Text(sort.label),
                );
              },
            ).toList(growable: false),
            onChanged: _controller.setSort,
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: state.onlyAvailable,
            onChanged: _controller.setOnlyAvailable,
            secondary: const Icon(
              Icons.event_available_outlined,
              color: DogGoTheme.green,
            ),
            title: Text(
              'Solo disponibles',
              style: DogGoTheme.body(
                weight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(WalkersState state) {
    if (state.loading && state.walkers.isEmpty) {
      return const SizedBox(
        height: 260,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (state.error != null &&
        state.walkers.isEmpty) {
      return _MessageCard(
        icon: Icons.error_outline_rounded,
        title: 'No pudimos cargar los paseadores',
        message: state.error!,
        color: DogGoTheme.red,
        background: DogGoTheme.redLight,
        actionText: 'Reintentar',
        onAction: _controller.refresh,
      );
    }

    final walkers = state.filteredWalkers;

    if (walkers.isEmpty) {
      return _MessageCard(
        icon: Icons.search_off_rounded,
        title: 'Sin coincidencias',
        message:
            'No encontramos paseadores con los filtros seleccionados.',
        color: DogGoTheme.teal,
        background: DogGoTheme.tealLight,
        actionText: 'Limpiar filtros',
        onAction: _clearFilters,
      );
    }

    return Column(
      children: [
        for (var index = 0;
            index < walkers.length;
            index++) ...[
          _EmbeddedWalkerCard(
            walker: walkers[index],
            photoUrl:
                state.photoUrlFor(walkers[index]),
            onView: () {
              _openDetail(walkers[index]);
            },
            onRequest: () {
              _requestWalk(walkers[index]);
            },
          ),
          if (index < walkers.length - 1)
            const SizedBox(
              height: DogGoSpacing.md,
            ),
        ],
      ],
    );
  }
}

class _EmbeddedWalkerCard extends StatelessWidget {
  final Walker walker;
  final String? photoUrl;
  final VoidCallback onView;
  final VoidCallback onRequest;

  const _EmbeddedWalkerCard({
    required this.walker,
    required this.photoUrl,
    required this.onView,
    required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(
        DogGoSpacing.cardPadding,
      ),
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(
          DogGoRadius.large,
        ),
        border: Border.all(
          color: DogGoTheme.border,
        ),
        boxShadow: DogGoTheme.softShadow(),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: 76,
                height: 76,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: DogGoTheme.tealLight,
                  borderRadius: BorderRadius.circular(
                    DogGoRadius.medium,
                  ),
                ),
                child: photoUrl == null
                    ? Center(
                        child: Text(
                          walker.initials,
                          style: DogGoTheme.title(
                            size: 20,
                            color: DogGoTheme.teal,
                          ),
                        ),
                      )
                    : Image.network(
                        photoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) {
                          return Center(
                            child: Text(
                              walker.initials,
                              style: DogGoTheme.title(
                                size: 20,
                                color: DogGoTheme.teal,
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(width: DogGoSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            walker.name,
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style: DogGoTheme.title(
                              size: 18,
                            ),
                          ),
                        ),
                        if (walker.verified)
                          const Icon(
                            Icons.verified_rounded,
                            color: DogGoTheme.teal,
                            size: 19,
                          ),
                      ],
                    ),
                    const SizedBox(
                      height: DogGoSpacing.xs,
                    ),
                    Text(
                      walker.serviceZone,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DogGoTheme.subtitle(
                        size: 12,
                      ),
                    ),
                    const SizedBox(
                      height:
                          DogGoSpacing.compactGap,
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.circle,
                          size: 9,
                          color: walker.available
                              ? DogGoTheme.green
                              : DogGoTheme.red,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          walker.available
                              ? 'Disponible'
                              : 'No disponible',
                          style: DogGoTheme.caption(
                            color: walker.available
                                ? DogGoTheme.green
                                : DogGoTheme.red,
                            weight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.star_rounded,
                          color: DogGoTheme.orange,
                          size: 17,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          walker.ratingLabel,
                          style: DogGoTheme.body(
                            size: 12,
                            weight: FontWeight.w800,
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
          Row(
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
              Flexible(
                child: Text(
                  walker.experienceLabel,
                  textAlign: TextAlign.end,
                  style: DogGoTheme.caption(
                    size: 10.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DogGoSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onView,
                  child: const Text('Ver perfil'),
                ),
              ),
              const SizedBox(
                width: DogGoSpacing.compactGap,
              ),
              Expanded(
                child: ElevatedButton(
                  onPressed:
                      walker.available ? onRequest : null,
                  child: const Text('Solicitar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Color color;
  final Color background;
  final String actionText;
  final VoidCallback onAction;

  const _MessageCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
    required this.background,
    required this.actionText,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DogGoSpacing.lg),
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(
          DogGoRadius.large,
        ),
        border: Border.all(
          color: DogGoTheme.border,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(
                DogGoRadius.medium,
              ),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(height: DogGoSpacing.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: DogGoTheme.title(size: 18),
          ),
          const SizedBox(height: DogGoSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: DogGoTheme.subtitle(
              size: 12.5,
            ),
          ),
          const SizedBox(height: DogGoSpacing.md),
          OutlinedButton(
            onPressed: onAction,
            child: Text(actionText),
          ),
        ],
      ),
    );
  }
}