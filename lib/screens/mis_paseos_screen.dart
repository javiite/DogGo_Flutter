import 'package:flutter/material.dart';

import '../shared/widgets/doggo_empty_view.dart';
import '../shared/widgets/doggo_error_view.dart';
import '../shared/widgets/doggo_loading_view.dart';
import '../theme/doggo_radius.dart';
import '../theme/doggo_spacing.dart';
import '../theme/doggo_theme.dart';
import 'calendario_paseos_screen.dart';
import 'chat_paseo_screen.dart';
import 'detalle_paseo_screen.dart';
import 'home/models/home_walk.dart';
import 'home/models/home_walk_status.dart';
import 'mapa_paseo_screen.dart';
import 'walks/walks_controller.dart';
import 'walks/walks_state.dart';

class MisPaseosScreen extends StatefulWidget {
  final int? usuarioId;
  final String? rol;
  final String? filtroInicial;

  const MisPaseosScreen({
    super.key,
    this.usuarioId,
    this.rol,
    this.filtroInicial,
  });

  @override
  State<MisPaseosScreen> createState() =>
      _MisPaseosScreenState();
}

class _MisPaseosScreenState
    extends State<MisPaseosScreen> {
  late final WalksController _controller;

  final TextEditingController _searchController =
      TextEditingController();

  @override
  void initState() {
    super.initState();

    _controller = WalksController(
      initialRole: widget.rol,
    );

    final initialStatus = _statusFromFilter(
      widget.filtroInicial,
    );

    if (initialStatus != null) {
      _controller.selectStatus(initialStatus);
    }

    _controller.initialize();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  HomeWalkStatus? _statusFromFilter(
    String? value,
  ) {
    if (value == null ||
        value.trim().isEmpty ||
        value.toLowerCase() == 'todos') {
      return null;
    }

    final status =
        HomeWalkStatus.fromValue(value);

    if (status == HomeWalkStatus.none ||
        status == HomeWalkStatus.unknown) {
      return null;
    }

    return status;
  }

  void _showMessage(
    String message, {
    bool error = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor:
              error ? DogGoTheme.red : DogGoTheme.ink,
          content: Row(
            children: [
              Icon(
                error
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_outline_rounded,
                color: Colors.white,
              ),
              const SizedBox(
                width: DogGoSpacing.compactGap,
              ),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }

  void _clearFilters() {
    _searchController.clear();
    _controller.clearFilters();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  Future<void> _openCalendar() async {
    final state = _controller.state;

    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => CalendarioPaseosScreen(
          paseos: state.walks
              .map((walk) => walk.rawData)
              .toList(growable: false),
          rol: state.role,
        ),
      ),
    );

    if (mounted) {
      await _controller.refresh();
    }
  }

  Future<void> _openDetail(
    HomeWalk walk,
  ) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => DetallePaseoScreen(
          paseo: walk.rawData,
          rol: _controller.state.role,
          onPaseoActualizado:
              _controller.refresh,
        ),
      ),
    );

    if (mounted) {
      await _controller.refresh();
    }
  }

  Future<void> _openChat(
    HomeWalk walk,
  ) async {
    final id = walk.id;

    if (id == null) {
      _showMessage(
        'No se encontró el identificador del paseo.',
        error: true,
      );
      return;
    }

    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ChatPaseoScreen(
          paseoId: id,
          nombrePerro: walk.petName,
          nombreOtroUsuario:
              _otherUserName(walk),
        ),
      ),
    );
  }

  Future<void> _openMap(
    HomeWalk walk,
  ) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => MapaPaseoScreen(
          paseo: walk.rawData,
        ),
      ),
    );
  }

  String _otherUserName(HomeWalk walk) {
    if (_controller.state.isOwner) {
      return walk.walkerName;
    }

    final raw = walk.rawData;

    final directName = raw['nombreDuenio'] ??
        raw['NombreDuenio'] ??
        raw['nombreDueño'] ??
        raw['NombreDueño'];

    final directLastName =
        raw['apellidoDuenio'] ??
            raw['ApellidoDuenio'] ??
            raw['apellidoDueño'] ??
            raw['ApellidoDueño'];

    final pet = raw['perro'] ?? raw['Perro'];

    dynamic owner;

    if (pet is Map) {
      owner = pet['usuario'] ??
          pet['Usuario'] ??
          pet['duenio'] ??
          pet['Duenio'] ??
          pet['dueño'] ??
          pet['Dueño'];
    }

    dynamic nestedName;
    dynamic nestedLastName;

    if (owner is Map) {
      nestedName =
          owner['nombre'] ?? owner['Nombre'];

      nestedLastName =
          owner['apellido'] ?? owner['Apellido'];
    }

    final name =
        (directName ?? nestedName)?.toString().trim() ??
            '';

    final lastName =
        (directLastName ?? nestedLastName)
                ?.toString()
                .trim() ??
            '';

    final fullName = '$name $lastName'.trim();

    return fullName.isEmpty
        ? 'Dueño de ${walk.petName}'
        : fullName;
  }

  Future<void> _confirmCancel(
    HomeWalk walk,
  ) async {
    final reasonController =
        TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        String? validationError;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Cancelar paseo'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cuéntanos por qué necesitas cancelar el paseo de ${walk.petName}.',
                    style: DogGoTheme.subtitle(
                      size: 13,
                    ),
                  ),
                  const SizedBox(
                    height: DogGoSpacing.md,
                  ),
                  TextField(
                    controller: reasonController,
                    autofocus: true,
                    minLines: 3,
                    maxLines: 5,
                    maxLength: 300,
                    decoration: InputDecoration(
                      labelText:
                          'Motivo de cancelación',
                      hintText:
                          'Ejemplo: cambio de horario o emergencia',
                      errorText: validationError,
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Volver'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        DogGoTheme.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    final value =
                        reasonController.text.trim();

                    if (value.isEmpty) {
                      setDialogState(() {
                        validationError =
                            'Escribe el motivo.';
                      });
                      return;
                    }

                    Navigator.pop(
                      dialogContext,
                      value,
                    );
                  },
                  child:
                      const Text('Cancelar paseo'),
                ),
              ],
            );
          },
        );
      },
    );

    reasonController.dispose();

    if (reason == null || !mounted) return;

    final result = await _controller.cancel(
      walk,
      reason: reason,
    );

    _showMessage(
      result.message,
      error: !result.success,
    );
  }

  Future<void> _performAction(
    Future<WalkActionResult> action,
  ) async {
    final result = await action;

    if (!mounted) return;

    _showMessage(
      result.message,
      error: !result.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final state = _controller.state;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Mis paseos'),
            actions: [
              IconButton(
                tooltip: 'Abrir calendario',
                onPressed: state.loading
                    ? null
                    : _openCalendar,
                icon: const Icon(
                  Icons.calendar_month_outlined,
                ),
              ),
              IconButton(
                tooltip: 'Actualizar paseos',
                onPressed: state.loading
                    ? null
                    : _controller.refresh,
                icon: const Icon(
                  Icons.refresh_rounded,
                ),
              ),
              const SizedBox(
                width: DogGoSpacing.sm,
              ),
            ],
          ),
          body: _buildBody(state),
        );
      },
    );
  }

  Widget _buildBody(WalksState state) {
    if (state.loading && state.walks.isEmpty) {
      return const DogGoLoadingView(
        message: 'Cargando tus paseos...',
      );
    }

    if (state.error != null &&
        state.walks.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(
            DogGoSpacing.screenHorizontal,
          ),
          child: DogGoErrorView(
            title: 'No pudimos cargar tus paseos',
            message: state.error!,
            onRetry: _controller.refresh,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _controller.refresh,
      child: CustomScrollView(
        keyboardDismissBehavior:
            ScrollViewKeyboardDismissBehavior.onDrag,
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
            sliver: SliverToBoxAdapter(
              child: _WalksHeader(
                state: state,
              ),
            ),
          ),
          if (state.activeWalk != null)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                DogGoSpacing.screenHorizontal,
                DogGoSpacing.md,
                DogGoSpacing.screenHorizontal,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: _ActiveWalkBanner(
                  walk: state.activeWalk!,
                  onMap: () {
                    _openMap(state.activeWalk!);
                  },
                  onDetail: () {
                    _openDetail(
                      state.activeWalk!,
                    );
                  },
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
              child: TextField(
                controller: _searchController,
                textInputAction:
                    TextInputAction.search,
                onChanged: _controller.search,
                decoration: InputDecoration(
                  hintText:
                      'Buscar mascota, paseador o estado',
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                  ),
                  suffixIcon:
                      state.searchQuery.isNotEmpty
                          ? IconButton(
                              tooltip:
                                  'Limpiar búsqueda',
                              onPressed: () {
                                _searchController
                                    .clear();
                                _controller.search('');
                              },
                              icon: const Icon(
                                Icons.close_rounded,
                              ),
                            )
                          : null,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _StatusFilters(
              state: state,
              onSelected:
                  _controller.selectStatus,
            ),
          ),
          if (state.error != null &&
              state.walks.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                DogGoSpacing.screenHorizontal,
                0,
                DogGoSpacing.screenHorizontal,
                DogGoSpacing.md,
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
                padding: const EdgeInsets.all(
                  DogGoSpacing.screenHorizontal,
                ),
                child: Center(
                  child: DogGoEmptyView(
                    title: 'Aún no tienes paseos',
                    message: state.isWalker
                        ? 'Cuando recibas una solicitud aparecerá en esta pantalla.'
                        : 'Solicita un paseo con un paseador disponible para comenzar.',
                    icon: Icons.route_outlined,
                    actionText: 'Actualizar',
                    onAction: _controller.refresh,
                  ),
                ),
              ),
            )
          else if (state.filteredWalks.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.all(
                  DogGoSpacing.screenHorizontal,
                ),
                child: Center(
                  child: DogGoEmptyView(
                    title: 'Sin coincidencias',
                    message:
                        'No encontramos paseos con los filtros seleccionados.',
                    icon:
                        Icons.filter_alt_off_outlined,
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
                0,
                DogGoSpacing.screenHorizontal,
                DogGoSpacing.xxl,
              ),
              sliver: SliverList.separated(
                itemCount:
                    state.filteredWalks.length,
                separatorBuilder: (_, __) {
                  return const SizedBox(
                    height: DogGoSpacing.md,
                  );
                },
                itemBuilder: (context, index) {
                  final walk =
                      state.filteredWalks[index];

                  return _WalkCard(
                    walk: walk,
                    state: state,
                    otherUserName:
                        _otherUserName(walk),
                    onDetail: () {
                      _openDetail(walk);
                    },
                    onChat: () {
                      _openChat(walk);
                    },
                    onMap: () {
                      _openMap(walk);
                    },
                    onAccept: () {
                      _performAction(
                        _controller.accept(walk),
                      );
                    },
                    onReject: () {
                      _performAction(
                        _controller.reject(walk),
                      );
                    },
                    onStart: () {
                      _performAction(
                        _controller.start(walk),
                      );
                    },
                    onFinish: () {
                      _performAction(
                        _controller.finish(walk),
                      );
                    },
                    onCancel: () {
                      _confirmCancel(walk);
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _WalksHeader extends StatelessWidget {
  final WalksState state;

  const _WalksHeader({
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
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
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: DogGoTheme.card,
                  borderRadius: BorderRadius.circular(
                    DogGoRadius.medium,
                  ),
                ),
                child: const Icon(
                  Icons.route_outlined,
                  color: DogGoTheme.teal,
                  size: 27,
                ),
              ),
              const SizedBox(width: DogGoSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.isWalker
                          ? 'Panel de paseos'
                          : 'Tus paseos',
                      style: DogGoTheme.title(
                        size: 20,
                      ),
                    ),
                    const SizedBox(
                      height: DogGoSpacing.xs,
                    ),
                    Text(
                      state.isWalker
                          ? 'Administra solicitudes y servicios activos.'
                          : 'Consulta reservas y seguimiento de tus mascotas.',
                      style: DogGoTheme.subtitle(
                        size: 12.5,
                      ),
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
                child: _HeaderCount(
                  value: state
                      .countByStatus(
                        HomeWalkStatus.pending,
                      )
                      .toString(),
                  label: 'Pendientes',
                  color: DogGoTheme.orange,
                ),
              ),
              Expanded(
                child: _HeaderCount(
                  value: state
                      .countByStatus(
                        HomeWalkStatus.accepted,
                      )
                      .toString(),
                  label: 'Aceptados',
                  color: DogGoTheme.purple,
                ),
              ),
              Expanded(
                child: _HeaderCount(
                  value: state
                      .countByStatus(
                        HomeWalkStatus.inProgress,
                      )
                      .toString(),
                  label: 'En curso',
                  color: DogGoTheme.green,
                ),
              ),
              Expanded(
                child: _HeaderCount(
                  value: state
                      .countByStatus(
                        HomeWalkStatus.completed,
                      )
                      .toString(),
                  label: 'Finalizados',
                  color: DogGoTheme.teal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderCount extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _HeaderCount({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: DogGoTheme.title(
            size: 19,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: DogGoTheme.caption(
            size: 9,
          ),
        ),
      ],
    );
  }
}

class _StatusFilters extends StatelessWidget {
  final WalksState state;
  final ValueChanged<HomeWalkStatus?> onSelected;

  const _StatusFilters({
    required this.state,
    required this.onSelected,
  });

  static const statuses = [
    HomeWalkStatus.pending,
    HomeWalkStatus.accepted,
    HomeWalkStatus.inProgress,
    HomeWalkStatus.completed,
    HomeWalkStatus.cancelled,
    HomeWalkStatus.rejected,
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 68,
      child: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal:
              DogGoSpacing.screenHorizontal,
          vertical: DogGoSpacing.compactGap,
        ),
        scrollDirection: Axis.horizontal,
        children: [
          ChoiceChip(
            label: Text(
              'Todos (${state.walks.length})',
            ),
            selected:
                state.selectedStatus == null,
            onSelected: (_) {
              onSelected(null);
            },
          ),
          const SizedBox(width: DogGoSpacing.sm),
          for (final status in statuses) ...[
            ChoiceChip(
              label: Text(
                '${status.label} '
                '(${state.countByStatus(status)})',
              ),
              selected:
                  state.selectedStatus == status,
              onSelected: (_) {
                onSelected(status);
              },
            ),
            const SizedBox(
              width: DogGoSpacing.sm,
            ),
          ],
        ],
      ),
    );
  }
}

class _ActiveWalkBanner extends StatelessWidget {
  final HomeWalk walk;
  final VoidCallback onMap;
  final VoidCallback onDetail;

  const _ActiveWalkBanner({
    required this.walk,
    required this.onMap,
    required this.onDetail,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(
        DogGoSpacing.cardPadding,
      ),
      decoration: BoxDecoration(
        color: DogGoTheme.greenLight,
        borderRadius: BorderRadius.circular(
          DogGoRadius.large,
        ),
        border: Border.all(
          color: DogGoTheme.green.withValues(
            alpha: 0.2,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.directions_walk_rounded,
            color: DogGoTheme.green,
            size: 30,
          ),
          const SizedBox(width: DogGoSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Paseo en curso',
                  style: DogGoTheme.title(
                    size: 17,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  walk.petName,
                  style: DogGoTheme.subtitle(
                    size: 12.5,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Ver detalle',
            onPressed: onDetail,
            icon: const Icon(
              Icons.visibility_outlined,
            ),
          ),
          IconButton.filled(
            tooltip: 'Abrir mapa',
            onPressed: onMap,
            icon: const Icon(
              Icons.my_location_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

class _WalkCard extends StatelessWidget {
  final HomeWalk walk;
  final WalksState state;
  final String otherUserName;
  final VoidCallback onDetail;
  final VoidCallback onChat;
  final VoidCallback onMap;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onStart;
  final VoidCallback onFinish;
  final VoidCallback onCancel;

  const _WalkCard({
    required this.walk,
    required this.state,
    required this.otherUserName,
    required this.onDetail,
    required this.onChat,
    required this.onMap,
    required this.onAccept,
    required this.onReject,
    required this.onStart,
    required this.onFinish,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        _statusColor(walk.status);

    final running =
        state.isActionRunningFor(walk);

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
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              _WalkPhoto(
                imageUrl: walk.imageUrl,
                color: color,
              ),
              const SizedBox(width: DogGoSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      walk.petName,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: DogGoTheme.title(
                        size: 19,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      state.isWalker
                          ? otherUserName
                          : walk.walkerName,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: DogGoTheme.subtitle(
                        size: 12.5,
                      ),
                    ),
                    const SizedBox(
                      height:
                          DogGoSpacing.compactGap,
                    ),
                    _StatusLabel(
                      status: walk.status,
                      color: color,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: DogGoSpacing.md),
          Wrap(
            spacing: DogGoSpacing.sm,
            runSpacing: DogGoSpacing.sm,
            children: [
              _WalkAttribute(
                icon:
                    Icons.calendar_today_outlined,
                text: walk.formattedSchedule,
              ),
              _WalkAttribute(
                icon: Icons.timer_outlined,
                text:
                    '${walk.durationMinutes} min',
              ),
              _WalkAttribute(
                icon: Icons.payments_outlined,
                text: walk.price == null
                    ? 'Sin precio'
                    : '\$${walk.price!.toStringAsFixed(2)}',
              ),
            ],
          ),
          if (walk.pickupAddress.isNotEmpty) ...[
            const SizedBox(
              height: DogGoSpacing.compactGap,
            ),
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: DogGoTheme.teal,
                  size: 19,
                ),
                const SizedBox(
                  width: DogGoSpacing.sm,
                ),
                Expanded(
                  child: Text(
                    walk.pickupAddress,
                    maxLines: 2,
                    overflow:
                        TextOverflow.ellipsis,
                    style: DogGoTheme.subtitle(
                      size: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: DogGoSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      running ? null : onChat,
                  icon: const Icon(
                    Icons.chat_outlined,
                    size: 18,
                  ),
                  label: const Text('Chat'),
                ),
              ),
              const SizedBox(
                width: DogGoSpacing.compactGap,
              ),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed:
                      running ? null : onDetail,
                  icon: const Icon(
                    Icons.visibility_outlined,
                    size: 18,
                  ),
                  label: const Text('Detalle'),
                ),
              ),
              if (walk.status ==
                  HomeWalkStatus.inProgress) ...[
                const SizedBox(
                  width:
                      DogGoSpacing.compactGap,
                ),
                IconButton.filled(
                  tooltip: 'Abrir mapa',
                  onPressed:
                      running ? null : onMap,
                  icon: const Icon(
                    Icons.map_outlined,
                  ),
                ),
              ],
            ],
          ),
          if (_hasActions(state, walk)) ...[
            const SizedBox(height: DogGoSpacing.md),
            const Divider(),
            const SizedBox(height: DogGoSpacing.md),
            if (running)
              const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2.5,
                  ),
                ),
              )
            else
              Wrap(
                spacing: DogGoSpacing.sm,
                runSpacing: DogGoSpacing.sm,
                children: [
                  if (state.canAccept(walk))
                    _ActionButton(
                      label: 'Aceptar',
                      icon:
                          Icons.check_rounded,
                      color: DogGoTheme.green,
                      onPressed: onAccept,
                    ),
                  if (state.canReject(walk))
                    _ActionButton(
                      label: 'Rechazar',
                      icon:
                          Icons.close_rounded,
                      color: DogGoTheme.red,
                      onPressed: onReject,
                    ),
                  if (state.canStart(walk))
                    _ActionButton(
                      label: 'Iniciar',
                      icon: Icons
                          .directions_walk_rounded,
                      color: DogGoTheme.teal,
                      onPressed: onStart,
                    ),
                  if (state.canFinish(walk))
                    _ActionButton(
                      label: 'Finalizar',
                      icon: Icons.flag_outlined,
                      color: DogGoTheme.green,
                      onPressed: onFinish,
                    ),
                  if (state.canCancel(walk))
                    _ActionButton(
                      label: 'Cancelar',
                      icon: Icons
                          .cancel_outlined,
                      color: DogGoTheme.red,
                      onPressed: onCancel,
                    ),
                ],
              ),
          ],
        ],
      ),
    );
  }

  static bool _hasActions(
    WalksState state,
    HomeWalk walk,
  ) {
    return state.canAccept(walk) ||
        state.canReject(walk) ||
        state.canStart(walk) ||
        state.canFinish(walk) ||
        state.canCancel(walk);
  }

  static Color _statusColor(
    HomeWalkStatus status,
  ) {
    switch (status) {
      case HomeWalkStatus.pending:
        return DogGoTheme.orange;
      case HomeWalkStatus.accepted:
        return DogGoTheme.purple;
      case HomeWalkStatus.inProgress:
        return DogGoTheme.green;
      case HomeWalkStatus.completed:
        return DogGoTheme.teal;
      case HomeWalkStatus.cancelled:
      case HomeWalkStatus.rejected:
        return DogGoTheme.red;
      case HomeWalkStatus.none:
      case HomeWalkStatus.unknown:
        return DogGoTheme.muted;
    }
  }
}

class _WalkPhoto extends StatelessWidget {
  final String imageUrl;
  final Color color;

  const _WalkPhoto({
    required this.imageUrl,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 76,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(
          DogGoRadius.medium,
        ),
      ),
      child: imageUrl.isEmpty
          ? Icon(
              Icons.pets_rounded,
              color: color,
              size: 30,
            )
          : Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return Icon(
                  Icons.pets_rounded,
                  color: color,
                  size: 30,
                );
              },
            ),
    );
  }
}

class _StatusLabel extends StatelessWidget {
  final HomeWalkStatus status;
  final Color color;

  const _StatusLabel({
    required this.status,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(
          DogGoRadius.pill,
        ),
      ),
      child: Text(
        status.label,
        style: DogGoTheme.caption(
          size: 10,
          color: color,
          weight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _WalkAttribute extends StatelessWidget {
  final IconData icon;
  final String text;

  const _WalkAttribute({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: DogGoTheme.cream,
        borderRadius: BorderRadius.circular(
          DogGoRadius.pill,
        ),
        border: Border.all(
          color: DogGoTheme.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: DogGoTheme.teal,
            size: 15,
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: DogGoTheme.caption(
              size: 10.5,
              color: DogGoTheme.ink,
              weight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color),
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}