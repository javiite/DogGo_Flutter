import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../shared/widgets/doggo_error_view.dart';
import '../shared/widgets/doggo_loading_view.dart';
import '../theme/doggo_theme.dart';
import 'pets/models/pet.dart';
import 'registrar_perro_screen.dart';
import 'seleccionar_ubicacion_screen.dart';
import 'walks/walk_request_controller.dart';
import 'walks/walk_request_state.dart';
import 'walks/models/walk_route_selection.dart';
import 'walks/widgets/walk_route_card.dart';

class CrearPaseoScreen extends StatefulWidget {
  final Map<String, dynamic> paseador;

  const CrearPaseoScreen({
    super.key,
    required this.paseador,
  });

  @override
  State<CrearPaseoScreen> createState() =>
      _CrearPaseoScreenState();
}

class _CrearPaseoScreenState
    extends State<CrearPaseoScreen> {
  late final WalkRequestController _controller;

  final TextEditingController _notesController =
      TextEditingController();

  WalkRouteSelection? _routeSelection;    

  @override
  void initState() {
    super.initState();

    _controller = WalkRequestController(
      walkerData: widget.paseador,
    );

    _controller.initialize();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _selectSchedule() async {
    final now = DateTime.now();
    final current =
        _controller.state.scheduledAt;

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: DateTime(
        now.year,
        now.month,
        now.day,
      ),
      lastDate: now.add(
        const Duration(days: 180),
      ),
      helpText: 'Selecciona el día del paseo',
      cancelText: 'Cancelar',
      confirmText: 'Continuar',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context)
                .colorScheme
                .copyWith(
                  primary: DogGoTheme.teal,
                ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    final initialDateTime = current ??
        now.add(const Duration(hours: 1));

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        initialDateTime,
      ),
      helpText: 'Selecciona la hora',
      cancelText: 'Cancelar',
      confirmText: 'Guardar',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context)
                .colorScheme
                .copyWith(
                  primary: DogGoTheme.teal,
                ),
          ),
          child: child!,
        );
      },
    );

    if (selectedTime == null) {
      return;
    }

    final result = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    if (!result.isAfter(DateTime.now())) {
      _showMessage(
        'Selecciona una fecha y hora futuras.',
      );
      return;
    }

    _controller.setSchedule(result);
  }

  Future<void> _openMap() async {
    final current =
        _controller.state.pickupLocation;

    final result =
        await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => SeleccionarUbicacionScreen(
          ubicacionInicial: current == null
              ? null
              : LatLng(
                  current.latitude,
                  current.longitude,
                ),
          textoInicial: current?.displayAddress,
        ),
      ),
    );

    if (result == null) {
      return;
    }

    final error =
        _controller.applyMapResult(result);

    if (error != null) {
      _showMessage(error);
    }
  }

  Future<void> _useCurrentLocation() async {
    final error =
        await _controller.useCurrentLocation();

    if (!mounted) {
      return;
    }

    if (error != null) {
      _showMessage(error);
      return;
    }

    _showMessage(
      'Ubicación actual seleccionada.',
      success: true,
    );
  }

  void _useDefaultLocation() {
    final error =
        _controller.useDefaultLocation();

    if (error != null) {
      _showMessage(error);
      return;
    }

    _showMessage(
      'Domicilio predeterminado seleccionado.',
      success: true,
    );
  }

  void _togglePet(int petId) {
    final error =
        _controller.togglePet(petId);

    if (error != null) {
      _showMessage(error);
    }
  }

  Future<void> _registerPet() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const RegistrarPerroScreen(),
      ),
    );

    if (!mounted) {
      return;
    }

    await _controller.initialize();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final result = await _controller.submit(
      notes: _notesController.text,
      routeSelection: _routeSelection,
    );

    if (!mounted) {
      return;
    }

    _showMessage(
      result.message,
      success: result.success,
    );

    if (result.success) {
      Navigator.pop(context, true);
    }
  }

  void _showMessage(
    String message, {
    bool success = false,
  }) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: success
              ? DogGoTheme.teal
              : DogGoTheme.ink,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final state = _controller.state;

        return Scaffold(
          backgroundColor: DogGoTheme.cream,
          appBar: AppBar(
            backgroundColor: DogGoTheme.card,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              onPressed: () =>
                  Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_back_rounded,
              ),
            ),
            title: Text(
              'Solicitar paseo',
              style: DogGoTheme.title(size: 20),
            ),
          ),
          bottomNavigationBar:
              state.loading || state.error != null
                  ? null
                  : _SubmitBar(
                      state: state,
                      onSubmit: _submit,
                    ),
          body: SafeArea(
            top: false,
            child: _buildBody(state),
          ),
        );
      },
    );
  }

  Widget _buildBody(WalkRequestState state) {
    if (state.loading) {
      return const DogGoLoadingView(
        message:
            'Preparando tu solicitud...',
      );
    }

    if (state.error != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: DogGoErrorView(
          message: state.error!,
          onRetry: _controller.initialize,
        ),
      );
    }

    return RefreshIndicator(
      color: DogGoTheme.teal,
      onRefresh: _controller.refresh,
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          20,
          18,
          20,
          130,
        ),
        children: [
          _WalkerHero(state: state),
          const SizedBox(height: 26),

          _SectionHeader(
            title: '¿Quiénes salen?',
            subtitle:
                'Selecciona de 1 a 5 mascotas',
            trailing:
                '${state.selectedPetCount}/'
                '${WalkRequestState.maxSelectedPets}',
          ),
          const SizedBox(height: 12),

          if (state.pets.isEmpty)
            _NoPetsCard(
              onRegister: _registerPet,
            )
          else ...[
            _PetSelector(
              state: state,
              onSelected: _togglePet,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _registerPet,
              icon: const Icon(
                Icons.add_rounded,
              ),
              label: const Text(
                'Registrar otra mascota',
              ),
            ),
          ],

          const SizedBox(height: 28),
          const _SectionHeader(
            title: 'Duración',
            subtitle:
                'Elige cuánto durará el paseo',
          ),
          const SizedBox(height: 12),

          _DurationSelector(
            state: state,
            onSelected:
                _controller.selectDuration,
          ),

          const SizedBox(height: 28),
          const _SectionHeader(
            title: 'Fecha y hora',
            subtitle:
                'Programa el momento del paseo',
          ),
          const SizedBox(height: 12),

          _ActionCard(
            icon: Icons.calendar_month_rounded,
            title: state.scheduledAt == null
                ? 'Seleccionar horario'
                : state.scheduleLabel,
            subtitle: state.scheduledAt == null
                ? 'Elige una fecha futura'
                : 'Toca para modificarlo',
            color: DogGoTheme.purple,
            background:
                DogGoTheme.purpleLight,
            onTap: _selectSchedule,
          ),

          const SizedBox(height: 28),
          const _SectionHeader(
            title: 'Punto de recogida',
            subtitle:
                '¿Dónde recogerán a tus mascotas?',
          ),
          const SizedBox(height: 12),

          _LocationCard(
            state: state,
            onDefault: _useDefaultLocation,
            onCurrent: _useCurrentLocation,
            onMap: _openMap,
          ),

          const SizedBox(height: 28),
          const _SectionHeader(
            title: 'Recorrido',
            subtitle:
                'Define por dónde será el paseo',
          ),
          const SizedBox(height: 12),

            WalkRouteCard(
              pickupLocation: state.pickupLocation,
              selection: _routeSelection,
              onChanged: (selection) {
                setState(() {
                  _routeSelection = selection;
                });
              },
            ),

            const SizedBox(height: 28),
            const _SectionHeader(
              title: 'Indicaciones',
            subtitle:
                'Información útil para el paseador',
          ),
          const SizedBox(height: 12),

          _NotesField(
            controller: _notesController,
          ),

          const SizedBox(height: 28),
          _PriceSummary(state: state),
        ],
      ),
    );
  }
}

class _WalkerHero extends StatelessWidget {
  final WalkRequestState state;

  const _WalkerHero({
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final walker = state.walker;
    final photoUrl = state.walkerPhotoUrl;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DogGoTheme.teal,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: DogGoTheme.teal.withValues(
              alpha: .16,
            ),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: .14,
              ),
              borderRadius:
                  BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withValues(
                  alpha: .20,
                ),
              ),
            ),
            child: photoUrl != null &&
                    photoUrl.trim().isNotEmpty
                ? Image.network(
                    photoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      return _Initials(
                        text: walker.initials,
                        color: Colors.white,
                      );
                    },
                  )
                : _Initials(
                    text: walker.initials,
                    color: Colors.white,
                  ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'TU PASEADOR',
                  style: DogGoTheme.label(
                    size: 10,
                    color: Colors.white.withValues(
                      alpha: .72,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  walker.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: DogGoTheme.title(
                    size: 21,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  children: [
                    _HeroData(
                      icon: Icons.star_rounded,
                      text: walker.rating > 0
                          ? walker.rating
                              .toStringAsFixed(1)
                          : 'Nuevo',
                    ),
                    _HeroData(
                      icon:
                          Icons.location_on_outlined,
                      text: walker.serviceZone,
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

class _HeroData extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HeroData({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: DogGoTheme.orange,
          size: 16,
        ),
        const SizedBox(width: 4),
        ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: 150),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: DogGoTheme.caption(
              size: 10.5,
              color: Colors.white,
              weight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? trailing;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: DogGoTheme.title(size: 22),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style:
                    DogGoTheme.subtitle(size: 12),
              ),
            ],
          ),
        ),
        if (trailing != null)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: DogGoTheme.tealLight,
              borderRadius:
                  BorderRadius.circular(20),
            ),
            child: Text(
              trailing!,
              style: DogGoTheme.label(
                size: 11,
                color: DogGoTheme.teal,
              ),
            ),
          ),
      ],
    );
  }
}

class _PetSelector extends StatelessWidget {
  final WalkRequestState state;
  final ValueChanged<int> onSelected;

  const _PetSelector({
    required this.state,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: state.pets.map((pet) {
        final selected =
            state.isPetSelected(pet.id);

        return Padding(
          padding: const EdgeInsets.only(
            bottom: 10,
          ),
          child: _PetCard(
            pet: pet,
            photoUrl: state.petPhotoUrl(pet),
            selected: selected,
            onTap: () => onSelected(pet.id),
          ),
        );
      }).toList(),
    );
  }
}

class _PetCard extends StatelessWidget {
  final Pet pet;
  final String? photoUrl;
  final bool selected;
  final VoidCallback onTap;

  const _PetCard({
    required this.pet,
    required this.photoUrl,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label:
          '${pet.name}, ${selected ? "seleccionado" : "no seleccionado"}',
      child: Material(
        color: selected
            ? DogGoTheme.tealLight
            : DogGoTheme.card,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius:
              BorderRadius.circular(22),
          child: AnimatedContainer(
            duration:
                const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(22),
              border: Border.all(
                color: selected
                    ? DogGoTheme.teal
                    : DogGoTheme.border,
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: DogGoTheme.card,
                    borderRadius:
                        BorderRadius.circular(18),
                  ),
                  child: photoUrl != null &&
                          photoUrl!.trim().isNotEmpty
                      ? Image.network(
                          photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) {
                            return _Initials(
                              text: pet.initials,
                              color: DogGoTheme.teal,
                            );
                          },
                        )
                      : _Initials(
                          text: pet.initials,
                          color: DogGoTheme.teal,
                        ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        pet.name,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: DogGoTheme.title(
                          size: 17,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pet.shortDescription,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: DogGoTheme.subtitle(
                          size: 11,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        pet.size,
                        style: DogGoTheme.caption(
                          size: 10,
                          color: DogGoTheme.teal,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                AnimatedContainer(
                  duration:
                      const Duration(milliseconds: 180),
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: selected
                        ? DogGoTheme.teal
                        : DogGoTheme.card,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected
                          ? DogGoTheme.teal
                          : DogGoTheme.border,
                      width: 2,
                    ),
                  ),
                  child: selected
                      ? const Icon(
                          Icons.check_rounded,
                          size: 19,
                          color: Colors.white,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NoPetsCard extends StatelessWidget {
  final VoidCallback onRegister;

  const _NoPetsCard({
    required this.onRegister,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: DogGoTheme.border,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.pets_outlined,
            color: DogGoTheme.teal,
            size: 40,
          ),
          const SizedBox(height: 10),
          Text(
            'No tienes mascotas registradas',
            textAlign: TextAlign.center,
            style: DogGoTheme.title(size: 17),
          ),
          const SizedBox(height: 6),
          Text(
            'Registra una mascota antes de solicitar el paseo.',
            textAlign: TextAlign.center,
            style: DogGoTheme.subtitle(size: 12),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onRegister,
            icon: const Icon(
              Icons.add_rounded,
            ),
            label: const Text(
              'Registrar mascota',
            ),
          ),
        ],
      ),
    );
  }
}

class _DurationSelector extends StatelessWidget {
  final WalkRequestState state;
  final ValueChanged<int> onSelected;

  const _DurationSelector({
    required this.state,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.1,
      children:
          WalkRequestState.allowedDurations.map(
        (minutes) {
          final selected =
              minutes == state.durationMinutes;

          final base =
              state.hourlyRate * (minutes / 60);

          return Material(
            color: selected
                ? DogGoTheme.teal
                : DogGoTheme.card,
            borderRadius:
                BorderRadius.circular(18),
            child: InkWell(
              onTap: () => onSelected(minutes),
              borderRadius:
                  BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(18),
                  border: Border.all(
                    color: selected
                        ? DogGoTheme.teal
                        : DogGoTheme.border,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.directions_walk_rounded,
                      color: selected
                          ? Colors.white
                          : DogGoTheme.teal,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            _durationLabel(minutes),
                            style: DogGoTheme.body(
                              size: 12,
                              color: selected
                                  ? Colors.white
                                  : DogGoTheme.ink,
                              weight:
                                  FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '\$${base.toStringAsFixed(2)} base',
                            style: DogGoTheme.caption(
                              size: 9.5,
                              color: selected
                                  ? Colors.white
                                      .withValues(
                                        alpha: .75,
                                      )
                                  : DogGoTheme.muted,
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
        },
      ).toList(),
    );
  }

  String _durationLabel(int minutes) {
    switch (minutes) {
      case 60:
        return '1 hora';
      case 90:
        return '1.5 horas';
      default:
        return '$minutes min';
    }
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.background,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DogGoTheme.card,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(20),
            border: Border.all(
              color: DogGoTheme.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius:
                      BorderRadius.circular(15),
                ),
                child: Icon(
                  icon,
                  color: color,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style:
                          DogGoTheme.title(size: 15),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: DogGoTheme.subtitle(
                        size: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: DogGoTheme.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  final WalkRequestState state;
  final VoidCallback onDefault;
  final VoidCallback onCurrent;
  final VoidCallback onMap;

  const _LocationCard({
    required this.state,
    required this.onDefault,
    required this.onCurrent,
    required this.onMap,
  });

  @override
  Widget build(BuildContext context) {
    final location = state.pickupLocation;

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: location == null
              ? DogGoTheme.border
              : DogGoTheme.teal,
          width: location == null ? 1 : 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: DogGoTheme.tealLight,
                  borderRadius:
                      BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: DogGoTheme.teal,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      location == null
                          ? 'Sin ubicación seleccionada'
                          : location.displayAddress,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          DogGoTheme.title(size: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      location == null
                          ? 'Elige una opción'
                          : 'Punto de recogida seleccionado',
                      style: DogGoTheme.subtitle(
                        size: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (location != null)
                const Icon(
                  Icons.check_circle_rounded,
                  color: DogGoTheme.teal,
                ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              if (state.hasDefaultLocation) ...[
                Expanded(
                  child: _LocationButton(
                    icon: Icons.home_rounded,
                    label: 'Domicilio',
                    onTap: onDefault,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: _LocationButton(
                  icon: state.loadingLocation
                      ? Icons.hourglass_top_rounded
                      : Icons.my_location_rounded,
                  label: state.loadingLocation
                      ? 'Buscando'
                      : 'Mi GPS',
                  onTap: state.loadingLocation
                      ? null
                      : onCurrent,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _LocationButton(
                  icon: Icons.map_outlined,
                  label: 'Mapa',
                  onTap: onMap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LocationButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _LocationButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: 6,
          vertical: 12,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotesField extends StatelessWidget {
  final TextEditingController controller;

  const _NotesField({
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: 4,
      maxLength: 300,
      textCapitalization:
          TextCapitalization.sentences,
      decoration: InputDecoration(
        hintText:
            'Ej. Choco necesita caminar despacio y lleva su correa azul.',
        prefixIcon: const Padding(
          padding: EdgeInsets.only(
            left: 12,
            right: 8,
            bottom: 70,
          ),
          child: Icon(
            Icons.notes_rounded,
            color: DogGoTheme.teal,
          ),
        ),
        filled: true,
        fillColor: DogGoTheme.card,
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(20),
          borderSide: const BorderSide(
            color: DogGoTheme.border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(20),
          borderSide: const BorderSide(
            color: DogGoTheme.border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(20),
          borderSide: const BorderSide(
            color: DogGoTheme.teal,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

class _PriceSummary extends StatelessWidget {
  final WalkRequestState state;

  const _PriceSummary({
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DogGoTheme.orangeLight,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: DogGoTheme.orange.withValues(
            alpha: .24,
          ),
        ),
      ),
      child: Column(
        children: [
          _PriceRow(
            label:
                'Tarifa base · ${state.durationLabel}',
            value:
                '\$${state.basePrice.toStringAsFixed(2)}',
          ),
          if (state.selectedPetCount > 1) ...[
            const SizedBox(height: 10),
            _PriceRow(
              label:
                  '${state.selectedPetCount - 1} '
                  '${state.selectedPetCount == 2 ? "mascota adicional" : "mascotas adicionales"} · 50%',
              value:
                  '\$${state.additionalPetsPrice.toStringAsFixed(2)}',
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(
              vertical: 14,
            ),
            child: Divider(
              height: 1,
              color: DogGoTheme.orange,
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total estimado',
                      style:
                          DogGoTheme.title(size: 17),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      state.pricingExplanation,
                      style: DogGoTheme.caption(
                        size: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '\$${state.estimatedTotal.toStringAsFixed(2)}',
                style: DogGoTheme.title(
                  size: 24,
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

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;

  const _PriceRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: DogGoTheme.body(
              size: 11.5,
              color: DogGoTheme.ink,
            ),
          ),
        ),
        Text(
          value,
          style: DogGoTheme.body(
            size: 12,
            weight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _SubmitBar extends StatelessWidget {
  final WalkRequestState state;
  final VoidCallback onSubmit;

  const _SubmitBar({
    required this.state,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final count = state.selectedPetCount;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          20,
          13,
          20,
          14,
        ),
        decoration: BoxDecoration(
          color: DogGoTheme.card,
          border: const Border(
            top: BorderSide(
              color: DogGoTheme.border,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: .05,
              ),
              blurRadius: 18,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: FilledButton(
          onPressed: state.canSubmit
              ? onSubmit
              : null,
          style: FilledButton.styleFrom(
            minimumSize:
                const Size.fromHeight(56),
            backgroundColor: DogGoTheme.teal,
            disabledBackgroundColor:
                DogGoTheme.disabled,
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(18),
            ),
          ),
          child: state.saving
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.pets_rounded,
                    ),
                    const SizedBox(width: 9),
                    Flexible(
                      child: Text(
                        count <= 1
                            ? 'Solicitar paseo'
                            : 'Solicitar para $count mascotas',
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '\$${state.estimatedTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  final String text;
  final Color color;

  const _Initials({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        style: DogGoTheme.title(
          size: 19,
          color: color,
        ),
      ),
    );
  }
}