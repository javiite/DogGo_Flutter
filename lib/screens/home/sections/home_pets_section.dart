import 'package:flutter/material.dart';

import '../../../shared/widgets/doggo_empty_view.dart';
import '../../../shared/widgets/doggo_error_view.dart';
import '../../../shared/widgets/doggo_skeleton_card.dart';
import '../../../theme/doggo_radius.dart';
import '../../../theme/doggo_spacing.dart';
import '../../../theme/doggo_theme.dart';
import '../widgets/home_section_title.dart';

class HomePetItem {
  final String name;
  final String breed;
  final String age;
  final String imageUrl;
  final VoidCallback onTap;

  const HomePetItem({
    required this.name,
    required this.breed,
    required this.age,
    required this.imageUrl,
    required this.onTap,
  });
}

class HomePetsSection extends StatelessWidget {
  final bool loading;
  final String? errorMessage;
  final List<HomePetItem> pets;
  final VoidCallback onSeeAll;
  final VoidCallback onAddPet;
  final VoidCallback onRetry;

  const HomePetsSection({
    super.key,
    required this.loading,
    required this.pets,
    required this.onSeeAll,
    required this.onAddPet,
    required this.onRetry,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DogGoSpacing.screenHorizontal,
        DogGoSpacing.sectionGap,
        DogGoSpacing.screenHorizontal,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeSectionTitle(
            title: 'Tus mascotas',
            actionText:
                pets.isEmpty ? 'Agregar' : 'Ver todas',
            onAction:
                pets.isEmpty ? onAddPet : onSeeAll,
          ),
          const SizedBox(height: DogGoSpacing.fieldGap),
          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (loading) {
      return const _PetsLoading();
    }

    if (errorMessage != null) {
      return DogGoErrorView(
        title: 'No pudimos cargar tus mascotas',
        message: errorMessage!,
        icon: Icons.pets_outlined,
        onRetry: onRetry,
        compact: true,
      );
    }

    if (pets.isEmpty) {
      return DogGoEmptyView(
        title: 'Agrega a tu primera mascota',
        message:
            'Sube su foto y completa sus datos para verla en tu inicio.',
        icon: Icons.add_a_photo_rounded,
        actionText: 'Agregar mascota',
        onAction: onAddPet,
        color: DogGoTheme.orange,
        background: DogGoTheme.orangeLight,
        compact: true,
      );
    }

    return SizedBox(
      height: 238,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: pets.length + 1,
        separatorBuilder: (context, index) {
          return const SizedBox(width: 13);
        },
        itemBuilder: (context, index) {
          if (index == pets.length) {
            return _AddPetCard(onTap: onAddPet);
          }

          return _PetCard(pet: pets[index]);
        },
      ),
    );
  }
}

class _PetsLoading extends StatelessWidget {
  const _PetsLoading();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 238,
      child: Row(
        children: [
          Expanded(
            child: DogGoSkeletonCard(height: 238),
          ),
          SizedBox(width: 13),
          Expanded(
            child: DogGoSkeletonCard(height: 238),
          ),
        ],
      ),
    );
  }
}

class _PetCard extends StatelessWidget {
  final HomePetItem pet;

  const _PetCard({
    required this.pet,
  });

  bool get _hasImage {
    return pet.imageUrl.startsWith('http://') ||
        pet.imageUrl.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 164,
      child: Semantics(
        button: true,
        label: 'Ver información de ${pet.name}',
        child: Material(
          color: DogGoTheme.card,
          borderRadius: BorderRadius.circular(
            DogGoRadius.large,
          ),
          child: InkWell(
            onTap: pet.onTap,
            borderRadius: BorderRadius.circular(
              DogGoRadius.large,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: DogGoTheme.card,
                borderRadius: BorderRadius.circular(
                  DogGoRadius.large,
                ),
                border: Border.all(
                  color: DogGoTheme.border,
                ),
                boxShadow: DogGoTheme.softShadow(
                  opacity: .025,
                  blur: 14,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 142,
                    width: double.infinity,
                    child: _hasImage
                        ? Image.network(
                            pet.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (
                              context,
                              error,
                              stackTrace,
                            ) {
                              return const _DogPlaceholder();
                            },
                          )
                        : const _DogPlaceholder(),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        12,
                        10,
                        12,
                        11,
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            pet.name,
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style: DogGoTheme.body(
                              size: 15,
                              color: DogGoTheme.ink,
                              weight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            pet.breed,
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style: DogGoTheme.subtitle(
                              size: 11.5,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: DogGoTheme.tealLight,
                              borderRadius:
                                  BorderRadius.circular(
                                DogGoRadius.pill,
                              ),
                            ),
                            child: Text(
                              pet.age,
                              maxLines: 1,
                              overflow:
                                  TextOverflow.ellipsis,
                              style: DogGoTheme.body(
                                size: 10.5,
                                color: DogGoTheme.teal,
                                weight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AddPetCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AddPetCard({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 138,
      child: Semantics(
        button: true,
        label: 'Agregar mascota',
        child: Material(
          color: DogGoTheme.card,
          borderRadius: BorderRadius.circular(
            DogGoRadius.large,
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(
              DogGoRadius.large,
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  DogGoRadius.large,
                ),
                border: Border.all(
                  color: DogGoTheme.border,
                ),
              ),
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(
                      color: DogGoTheme.tealLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: DogGoTheme.teal,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 13),
                  Text(
                    'Agregar\nmascota',
                    textAlign: TextAlign.center,
                    style: DogGoTheme.body(
                      size: 13,
                      color: DogGoTheme.ink,
                      weight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DogPlaceholder extends StatelessWidget {
  const _DogPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: DogGoTheme.tealLight,
      alignment: Alignment.center,
      child: const Icon(
        Icons.pets_rounded,
        color: DogGoTheme.teal,
        size: 48,
      ),
    );
  }
}