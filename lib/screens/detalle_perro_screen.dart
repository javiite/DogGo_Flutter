import 'package:flutter/material.dart';

import '../shared/widgets/doggo_error_view.dart';
import '../shared/widgets/doggo_loading_view.dart';
import '../shared/widgets/doggo_network_image.dart';
import '../shared/widgets/doggo_section_card.dart';
import '../shared/widgets/doggo_screen_scaffold.dart';
import '../shared/widgets/doggo_status_chip.dart';
import '../shared/widgets/doggo_sticky_action_bar.dart';
import '../theme/doggo_radius.dart';
import '../theme/doggo_spacing.dart';
import '../theme/doggo_theme.dart';
import 'editar_perro_screen.dart';
import 'pets/models/pet.dart';
import 'pets/pet_detail_controller.dart';
import 'pets/pet_detail_state.dart';
import 'pets/widgets/pet_gallery_section.dart';
import 'pets/widgets/pet_walk_center.dart';
import 'paseadores_screen.dart';
import 'detalle_paseo_screen.dart';
import 'walks/models/walk_detail.dart';
import 'onboarding/contextual_onboarding.dart';
import 'advanced/pet_wellness_screen.dart';

enum _PetDetailSection { summary, care, photos }

class DetallePerroScreen extends StatefulWidget {
  final Map<String, dynamic> perro;

  const DetallePerroScreen({super.key, required this.perro});

  @override
  State<DetallePerroScreen> createState() => _DetallePerroScreenState();
}

class _DetallePerroScreenState extends State<DetallePerroScreen> {
  late final PetDetailController _controller;

  bool _allowPop = false;
  _PetDetailSection _section = _PetDetailSection.summary;

  @override
  void initState() {
    super.initState();

    _controller = PetDetailController(initialData: widget.perro)..initialize();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showContextualOnboarding(
        context,
        contextKey: 'pets',
        title: 'Perfil de tu mascota',
        steps: const [
          OnboardingStep(
            Icons.dashboard_customize_rounded,
            'Centro rápido',
            'Consulta su próximo y último paseo sin salir del perfil.',
          ),
          OnboardingStep(
            Icons.health_and_safety_outlined,
            'Cuidados claros',
            'Completa conducta, seguridad y notas para ayudar al paseador.',
          ),
          OnboardingStep(
            Icons.photo_library_outlined,
            'Su historia en fotos',
            'Organiza la galería y elige una fotografía principal.',
          ),
        ],
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _close() {
    if (_allowPop || !mounted) return;

    setState(() {
      _allowPop = true;
    });

    Navigator.pop(context, _controller.state.changed);
  }

  Future<void> _openEdit(Pet pet) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => EditarPerroScreen(perro: pet.rawData),
      ),
    );

    if (!mounted) return;

    if (updated == true) {
      await _controller.markChangedAndRefresh();
    }
  }

  Future<void> _requestWalk(Pet pet) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => PaseadoresScreen(initialPetId: pet.id),
      ),
    );
  }

  Future<void> _openWalk(WalkDetail walk) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => DetallePaseoScreen(
          paseoId: walk.id,
          paseo: walk.rawData,
          rol: 'Dueño',
        ),
      ),
    );
  }

  Future<void> _openWellness(Pet pet) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => PetWellnessScreen(initialPetId: pet.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final state = _controller.state;

        return PopScope(
          canPop: _allowPop,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) {
              _close();
            }
          },
          child: DogGoScreenScaffold(
            title: state.pet?.name ?? 'Mascota',
            automaticallyImplyLeading: false,
            leading: IconButton(
              tooltip: 'Volver',
              onPressed: _close,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            actions: [
              if (state.pet != null)
                IconButton(
                  tooltip: 'Salud, cuidados y logros',
                  onPressed: state.loading
                      ? null
                      : () => _openWellness(state.pet!),
                  icon: const Icon(Icons.health_and_safety_outlined),
                ),
              IconButton(
                tooltip: 'Actualizar información',
                onPressed: state.loading ? null : _controller.refresh,
                icon: const Icon(Icons.refresh_rounded),
              ),
              const SizedBox(width: DogGoSpacing.sm),
            ],
            body: _buildBody(state),
            bottomNavigationBar: state.pet == null || state.loading
                ? null
                : DogGoStickyActionBar(
                    primaryLabel: 'Buscar paseador',
                    primaryIcon: Icons.directions_walk_rounded,
                    onPrimary: () => _requestWalk(state.pet!),
                    secondaryLabel: 'Editar',
                    secondaryIcon: Icons.edit_outlined,
                    onSecondary: () => _openEdit(state.pet!),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildBody(PetDetailState state) {
    if (state.loading) {
      return const DogGoLoadingView(message: 'Cargando información...');
    }

    if (state.error != null) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(DogGoSpacing.screenHorizontal),
          child: DogGoErrorView(
            title: 'No pudimos cargar la mascota',
            message: state.error!,
            onRetry: _controller.refresh,
          ),
        ),
      );
    }

    final pet = state.pet;

    if (pet == null) {
      return DogGoErrorView(
        message: 'No encontramos información de esta mascota.',
        onRetry: _controller.refresh,
      );
    }

    return RefreshIndicator(
      onRefresh: _controller.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(
          DogGoSpacing.screenHorizontal,
          DogGoSpacing.md,
          DogGoSpacing.screenHorizontal,
          DogGoSpacing.lg,
        ),
        children: [
          _PetHero(
            pet: pet,
            photoUrl: state.photoUrl,
            onEdit: () => _openEdit(pet),
          ),
          const SizedBox(height: DogGoSpacing.md),
          _PetSectionSelector(
            selected: _section,
            onSelected: (section) {
              setState(() => _section = section);
            },
          ),
          const SizedBox(height: DogGoSpacing.md),
          ...switch (_section) {
            _PetDetailSection.summary => [
              PetWalkCenter(
                petId: pet.id,
                onOpenWalk: _openWalk,
                onRequestWalk: () => _requestWalk(pet),
              ),
              const SizedBox(height: DogGoSpacing.md),
              _buildProfileProgress(pet),
              const SizedBox(height: DogGoSpacing.md),
              _buildGeneralInformation(pet),
              const SizedBox(height: DogGoSpacing.md),
              _buildNotes(pet),
            ],
            _PetDetailSection.care => [
              _buildBehavior(pet),
              const SizedBox(height: DogGoSpacing.md),
              _buildSafety(pet),
            ],
            _PetDetailSection.photos => [
              PetGallerySection(state: state, controller: _controller),
            ],
          },
        ],
      ),
    );
  }

  Widget _buildProfileProgress(Pet pet) {
    final missing = pet.profileMissingItems;
    return DogGoSectionCard(
      title: pet.isProfileComplete ? 'Perfil listo' : 'Completa su perfil',
      subtitle: pet.isProfileComplete
          ? 'El paseador tendrá la información esencial antes de salir.'
          : 'Un perfil completo ayuda a preparar un paseo más seguro.',
      icon: pet.isProfileComplete
          ? Icons.verified_outlined
          : Icons.tips_and_updates_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(DogGoRadius.pill),
            child: LinearProgressIndicator(
              minHeight: 9,
              value: pet.profileCompletion / 100,
              backgroundColor: DogGoTheme.cream2,
              color: DogGoTheme.teal,
            ),
          ),
          const SizedBox(height: DogGoSpacing.compactGap),
          Text(
            pet.isProfileComplete
                ? 'Todos los datos esenciales están registrados.'
                : 'Falta: ${missing.take(3).join(', ')}${missing.length > 3 ? ' y ${missing.length - 3} más' : ''}.',
            style: DogGoTheme.body(size: 12.5, color: DogGoTheme.muted),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralInformation(Pet pet) {
    return DogGoSectionCard(
      title: 'Información general',
      subtitle: 'Datos principales de tu mascota.',
      icon: Icons.pets_outlined,
      iconColor: DogGoTheme.teal,
      iconBackground: DogGoTheme.tealLight,
      child: Column(
        children: [
          _InformationRow(
            icon: Icons.badge_outlined,
            title: 'Nombre',
            value: pet.name,
          ),
          _InformationRow(
            icon: Icons.category_outlined,
            title: 'Raza',
            value: pet.breed,
          ),
          _InformationRow(
            icon: Icons.cake_outlined,
            title: 'Edad',
            value: pet.ageLabel,
          ),
          _InformationRow(
            icon: Icons.straighten_rounded,
            title: 'Tamaño',
            value: pet.size,
          ),
          _InformationRow(
            icon: Icons.monitor_weight_outlined,
            title: 'Peso',
            value: pet.weight == null
                ? 'Sin registrar'
                : '${pet.weight!.toStringAsFixed(1)} kg',
          ),
          _InformationRow(
            icon: Icons.pets_outlined,
            title: 'Sexo',
            value: pet.sex ?? 'Sin registrar',
          ),
          _InformationRow(
            icon: Icons.health_and_safety_outlined,
            title: 'Esterilizado',
            value: _yesNo(pet.sterilized),
            last: true,
          ),
        ],
      ),
    );
  }

  Widget _buildBehavior(Pet pet) {
    return DogGoSectionCard(
      title: 'Personalidad y convivencia',
      subtitle: 'Lo que el paseador debe conocer antes de salir.',
      icon: Icons.psychology_alt_outlined,
      iconColor: DogGoTheme.teal,
      iconBackground: DogGoTheme.tealLight,
      child: Column(
        children: [
          _InformationRow(
            icon: Icons.sentiment_satisfied_alt_rounded,
            title: 'Temperamento',
            value: pet.temperament ?? 'Sin registrar',
          ),
          _InformationRow(
            icon: Icons.bolt_rounded,
            title: 'Energía',
            value: pet.energyLevel ?? 'Sin registrar',
          ),
          _InformationRow(
            icon: Icons.route_outlined,
            title: 'Con correa',
            value: pet.leashBehavior ?? 'Sin registrar',
          ),
          _InformationRow(
            icon: Icons.pets_outlined,
            title: 'Con perros',
            value: _yesNo(pet.socialWithDogs),
          ),
          _InformationRow(
            icon: Icons.person_outline_rounded,
            title: 'Con personas',
            value: _yesNo(pet.socialWithPeople),
          ),
          _InformationRow(
            icon: Icons.child_care_outlined,
            title: 'Con niños',
            value: _yesNo(pet.socialWithChildren),
            last: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSafety(Pet pet) {
    return DogGoSectionCard(
      title: 'Seguridad durante el paseo',
      subtitle: 'Precauciones e indicaciones importantes.',
      icon: Icons.shield_outlined,
      iconColor: DogGoTheme.orange,
      iconBackground: DogGoTheme.orangeLight,
      child: Column(
        children: [
          _InformationRow(
            icon: Icons.warning_amber_rounded,
            title: 'Reactivo',
            value: _yesNo(pet.reactive),
          ),
          _InformationRow(
            icon: Icons.directions_run_rounded,
            title: 'Riesgo de escape',
            value: _yesNo(pet.escapeRisk),
          ),
          _InformationRow(
            icon: Icons.flash_on_outlined,
            title: 'Miedos o detonantes',
            value: pet.fearsTriggers ?? 'Sin registrar',
          ),
          _InformationRow(
            icon: Icons.record_voice_over_outlined,
            title: 'Comandos conocidos',
            value: pet.knownCommands ?? 'Sin registrar',
            last: true,
          ),
        ],
      ),
    );
  }

  String _yesNo(bool? value) {
    if (value == null) return 'Sin registrar';
    return value ? 'Sí' : 'No';
  }

  Widget _buildNotes(Pet pet) {
    final hasNotes = pet.notes.trim().isNotEmpty;

    return DogGoSectionCard(
      title: 'Notas y cuidados',
      subtitle: 'Información importante para sus paseadores.',
      icon: Icons.notes_outlined,
      iconColor: DogGoTheme.orange,
      iconBackground: DogGoTheme.orangeLight,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(DogGoSpacing.md),
        decoration: BoxDecoration(
          color: hasNotes ? DogGoTheme.orangeLight : DogGoTheme.cream,
          borderRadius: BorderRadius.circular(DogGoRadius.medium),
        ),
        child: Text(
          hasNotes
              ? pet.notes
              : 'Todavía no agregaste notas para esta mascota.',
          style: DogGoTheme.body(
            size: 13.5,
            color: hasNotes ? DogGoTheme.ink : DogGoTheme.muted,
            weight: hasNotes ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _PetHero extends StatelessWidget {
  final Pet pet;
  final String? photoUrl;
  final VoidCallback onEdit;

  const _PetHero({
    required this.pet,
    required this.photoUrl,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(DogGoRadius.extraLarge),
        border: Border.all(color: DogGoTheme.border),
        boxShadow: DogGoTheme.elevatedShadow(),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 270,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Hero(
                  tag: 'pet-photo-${pet.id}',
                  child: _HeroPhoto(pet: pet, photoUrl: photoUrl),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Color(0xB3000000)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.42, 1],
                    ),
                  ),
                ),
                Positioned(
                  left: DogGoSpacing.cardPadding,
                  right: DogGoSpacing.cardPadding,
                  bottom: DogGoSpacing.cardPadding,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pet.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: DogGoTheme.title(
                                size: 29,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: DogGoSpacing.xs),
                            Text(
                              pet.shortDescription,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: DogGoTheme.subtitle(
                                size: 13.5,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                            const SizedBox(height: DogGoSpacing.sm),
                            DogGoStatusChip(
                              label: pet.profileStatusLabel,
                              icon: pet.isProfileComplete
                                  ? Icons.check_circle_outline_rounded
                                  : Icons.tips_and_updates_outlined,
                              tone: pet.isProfileComplete
                                  ? DogGoStatusTone.positive
                                  : DogGoStatusTone.attention,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: DogGoSpacing.compactGap),
                      IconButton.filled(
                        tooltip: 'Editar mascota',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: DogGoTheme.teal,
                        ),
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPhoto extends StatelessWidget {
  final Pet pet;
  final String? photoUrl;

  const _HeroPhoto({required this.pet, required this.photoUrl});

  @override
  Widget build(BuildContext context) {
    return DogGoNetworkImage(
      url: photoUrl,
      semanticLabel: 'Fotografía de ${pet.name}',
      fallback: _PetPlaceholder(initials: pet.initials),
    );
  }
}

class _PetPlaceholder extends StatelessWidget {
  final String initials;

  const _PetPlaceholder({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: DogGoTheme.tealLight,
      alignment: Alignment.center,
      child: Text(
        initials,
        style: DogGoTheme.display(size: 54, color: DogGoTheme.teal),
      ),
    );
  }
}

class _PetSectionSelector extends StatelessWidget {
  final _PetDetailSection selected;
  final ValueChanged<_PetDetailSection> onSelected;

  const _PetSectionSelector({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Secciones del perfil de mascota',
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SegmentedButton<_PetDetailSection>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(
              value: _PetDetailSection.summary,
              icon: Icon(Icons.badge_outlined),
              label: Text('Resumen'),
            ),
            ButtonSegment(
              value: _PetDetailSection.care,
              icon: Icon(Icons.health_and_safety_outlined),
              label: Text('Cuidados'),
            ),
            ButtonSegment(
              value: _PetDetailSection.photos,
              icon: Icon(Icons.photo_library_outlined),
              label: Text('Fotos'),
            ),
          ],
          selected: {selected},
          onSelectionChanged: (values) => onSelected(values.first),
        ),
      ),
    );
  }
}

class _InformationRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final bool last;

  const _InformationRow({
    required this.icon,
    required this.title,
    required this.value,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: 11, bottom: last ? 0 : 11),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: DogGoTheme.divider)),
      ),
      child: Row(
        children: [
          Icon(icon, color: DogGoTheme.teal, size: 20),
          const SizedBox(width: DogGoSpacing.compactGap),
          Expanded(
            child: Text(
              title,
              style: DogGoTheme.body(size: 13, color: DogGoTheme.muted),
            ),
          ),
          const SizedBox(width: DogGoSpacing.sm),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: DogGoTheme.body(size: 13.5, weight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
