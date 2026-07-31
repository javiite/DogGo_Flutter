import 'package:flutter/material.dart';

import '../shared/widgets/doggo_empty_view.dart';
import '../shared/widgets/doggo_error_view.dart';
import '../shared/widgets/doggo_loading_view.dart';
import '../theme/doggo_radius.dart';
import '../theme/doggo_spacing.dart';
import '../theme/doggo_theme.dart';
import 'detalle_perro_screen.dart';
import 'editar_perro_screen.dart';
import 'pets/models/pet.dart';
import 'pets/pets_controller.dart';
import 'pets/pets_state.dart';
import 'registrar_perro_screen.dart';

class MisPerrosScreen extends StatefulWidget {
  const MisPerrosScreen({super.key});

  @override
  State<MisPerrosScreen> createState() =>
      _MisPerrosScreenState();
}

class _MisPerrosScreenState
    extends State<MisPerrosScreen> {
  late final PetsController _controller;
  final TextEditingController _searchController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = PetsController()..initialize();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
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
              const SizedBox(width: DogGoSpacing.compactGap),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }

  Future<void> _openRegister() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => const RegistrarPerroScreen(),
      ),
    );

    if (!mounted) return;

    if (created == true) {
      await _controller.refresh();
    }
  }

  Future<void> _openDetails(Pet pet) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => DetallePerroScreen(
          perro: pet.rawData,
        ),
      ),
    );

    if (!mounted) return;

    if (updated == true) {
      await _controller.refresh();
    }
  }

  Future<void> _openEdit(Pet pet) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => EditarPerroScreen(
          perro: pet.rawData,
        ),
      ),
    );

    if (!mounted) return;

    if (updated == true) {
      await _controller.refresh();
    }
  }

  Future<void> _confirmDelete(Pet pet) async {
    if (!pet.hasValidId) {
      _showMessage(
        'No se encontró el identificador de la mascota.',
        error: true,
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar mascota'),
          content: Text(
            '¿Seguro que quieres eliminar a ${pet.name}? '
            'Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: DogGoTheme.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              icon: const Icon(
                Icons.delete_outline_rounded,
              ),
              label: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final deleted = await _controller.deletePet(pet);

    if (!mounted) return;

    if (deleted) {
      _showMessage(
        _controller.lastMessage ??
            '${pet.name} se eliminó correctamente.',
      );
    } else {
      _showMessage(
        _controller.state.error ??
            'No se pudo eliminar a ${pet.name}.',
        error: true,
      );
    }
  }

  void _clearSearch() {
    _searchController.clear();
    _controller.clearSearch();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final state = _controller.state;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Mis mascotas'),
            actions: [
              IconButton(
                tooltip: 'Actualizar mascotas',
                onPressed:
                    state.loading ? null : _controller.refresh,
                icon: const Icon(Icons.refresh_rounded),
              ),
              const SizedBox(width: DogGoSpacing.sm),
            ],
          ),
          floatingActionButton: state.loading
              ? null
              : FloatingActionButton.extended(
                  onPressed: _openRegister,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Agregar'),
                ),
          body: _buildBody(state),
        );
      },
    );
  }

  Widget _buildBody(PetsState state) {
    if (state.loading && state.pets.isEmpty) {
      return const DogGoLoadingView(
        message: 'Cargando tus mascotas...',
      );
    }

    if (state.error != null && state.pets.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(
            DogGoSpacing.screenHorizontal,
          ),
          child: DogGoErrorView(
            title: 'No pudimos cargar tus mascotas',
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
              child: _PetsHeader(
                totalPets: state.totalPets,
              ),
            ),
          ),
          if (state.hasPets)
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
                  textInputAction: TextInputAction.search,
                  onChanged: _controller.search,
                  decoration: InputDecoration(
                    hintText:
                        'Buscar por nombre, raza o tamaño',
                    prefixIcon:
                        const Icon(Icons.search_rounded),
                    suffixIcon:
                        state.searchQuery.isNotEmpty
                            ? IconButton(
                                tooltip: 'Limpiar búsqueda',
                                onPressed: _clearSearch,
                                icon: const Icon(
                                  Icons.close_rounded,
                                ),
                              )
                            : null,
                  ),
                ),
              ),
            ),
          if (state.error != null && state.pets.isNotEmpty)
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
                padding: const EdgeInsets.all(
                  DogGoSpacing.screenHorizontal,
                ),
                child: Center(
                  child: DogGoEmptyView(
                    title: 'Aún no tienes mascotas',
                    message:
                        'Agrega tu primera mascota para preparar sus datos antes de solicitar un paseo.',
                    icon: Icons.pets_outlined,
                    actionText: 'Agregar mascota',
                    onAction: _openRegister,
                  ),
                ),
              ),
            )
          else if (state.filteredPets.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.all(
                  DogGoSpacing.screenHorizontal,
                ),
                child: Center(
                  child: DogGoEmptyView(
                    title: 'Sin resultados',
                    message:
                        'No encontramos mascotas que coincidan con “${state.searchQuery}”.',
                    icon: Icons.search_off_rounded,
                    actionText: 'Limpiar búsqueda',
                    onAction: _clearSearch,
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                DogGoSpacing.screenHorizontal,
                DogGoSpacing.md,
                DogGoSpacing.screenHorizontal,
                110,
              ),
              sliver: SliverList.separated(
                itemCount: state.filteredPets.length,
                separatorBuilder: (_, __) {
                  return const SizedBox(
                    height: DogGoSpacing.md,
                  );
                },
                itemBuilder: (context, index) {
                  final pet = state.filteredPets[index];

                  return _PetCard(
                    pet: pet,
                    photoUrl: state.photoUrlFor(pet),
                    deleting: state.isPetDeleting(pet),
                    onTap: () => _openDetails(pet),
                    onEdit: () => _openEdit(pet),
                    onDelete: () => _confirmDelete(pet),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _PetsHeader extends StatelessWidget {
  final int totalPets;

  const _PetsHeader({
    required this.totalPets,
  });

  @override
  Widget build(BuildContext context) {
    final text = totalPets == 1
        ? '1 mascota registrada'
        : '$totalPets mascotas registradas';

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
          color: DogGoTheme.teal.withValues(alpha: 0.13),
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
              Icons.pets_rounded,
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
                  'Tu familia DogGo',
                  style: DogGoTheme.title(size: 20),
                ),
                const SizedBox(height: DogGoSpacing.xs),
                Text(
                  text,
                  style: DogGoTheme.subtitle(
                    size: 13,
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

class _PetCard extends StatelessWidget {
  final Pet pet;
  final String? photoUrl;
  final bool deleting;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PetCard({
    required this.pet,
    required this.photoUrl,
    required this.deleting,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label:
          '${pet.name}, ${pet.breed}, ${pet.ageLabel}',
      child: Container(
        clipBehavior: Clip.antiAlias,
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
        child: InkWell(
          onTap: deleting ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.all(
              DogGoSpacing.cardPadding,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: 'pet-photo-${pet.id}',
                  child: _PetPhoto(
                    pet: pet,
                    photoUrl: photoUrl,
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
                              pet.name,
                              maxLines: 1,
                              overflow:
                                  TextOverflow.ellipsis,
                              style: DogGoTheme.title(
                                size: 19,
                              ),
                            ),
                          ),
                          PopupMenuButton<String>(
                            enabled: !deleting,
                            tooltip: 'Opciones',
                            onSelected: (value) {
                              if (value == 'edit') {
                                onEdit();
                              } else if (value ==
                                  'delete') {
                                onDelete();
                              }
                            },
                            itemBuilder: (_) {
                              return const [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: ListTile(
                                    contentPadding:
                                        EdgeInsets.zero,
                                    leading: Icon(
                                      Icons.edit_outlined,
                                    ),
                                    title: Text('Editar'),
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: ListTile(
                                    contentPadding:
                                        EdgeInsets.zero,
                                    leading: Icon(
                                      Icons
                                          .delete_outline_rounded,
                                      color: DogGoTheme.red,
                                    ),
                                    title: Text(
                                      'Eliminar',
                                      style: TextStyle(
                                        color: DogGoTheme.red,
                                      ),
                                    ),
                                  ),
                                ),
                              ];
                            },
                          ),
                        ],
                      ),
                      Text(
                        pet.breed,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: DogGoTheme.subtitle(
                          size: 13,
                        ),
                      ),
                      const SizedBox(
                        height: DogGoSpacing.compactGap,
                      ),
                      Wrap(
                        spacing: DogGoSpacing.sm,
                        runSpacing: DogGoSpacing.sm,
                        children: [
                          _PetAttribute(
                            icon: Icons.cake_outlined,
                            text: pet.ageLabel,
                          ),
                          _PetAttribute(
                            icon:
                                Icons.straighten_rounded,
                            text: pet.size,
                          ),
                        ],
                      ),
                      if (pet.notes.isNotEmpty) ...[
                        const SizedBox(
                          height:
                              DogGoSpacing.compactGap,
                        ),
                        Text(
                          pet.notes,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: DogGoTheme.caption(
                            size: 11.5,
                          ),
                        ),
                      ],
                      const SizedBox(
                        height: DogGoSpacing.compactGap,
                      ),
                      Row(
                        children: [
                          Text(
                            'Ver perfil',
                            style: DogGoTheme.body(
                              size: 12.5,
                              color: DogGoTheme.teal,
                              weight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 3),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: DogGoTheme.teal,
                            size: 17,
                          ),
                          if (deleting) ...[
                            const Spacer(),
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PetPhoto extends StatelessWidget {
  final Pet pet;
  final String? photoUrl;

  const _PetPhoto({
    required this.pet,
    required this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 94,
      height: 112,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: DogGoTheme.tealLight,
        borderRadius: BorderRadius.circular(
          DogGoRadius.medium,
        ),
      ),
      child: photoUrl == null
          ? _PetPlaceholder(
              initials: pet.initials,
            )
          : Image.network(
              photoUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return _PetPlaceholder(
                  initials: pet.initials,
                );
              },
            ),
    );
  }
}

class _PetPlaceholder extends StatelessWidget {
  final String initials;

  const _PetPlaceholder({
    required this.initials,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: DogGoTheme.title(
          size: 24,
          color: DogGoTheme.teal,
        ),
      ),
    );
  }
}

class _PetAttribute extends StatelessWidget {
  final IconData icon;
  final String text;

  const _PetAttribute({
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
            size: 15,
            color: DogGoTheme.teal,
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