import 'package:flutter/material.dart';

import '../../../theme/doggo_radius.dart';
import '../../../theme/doggo_theme.dart';
import '../models/pet_photo.dart';
import '../pet_detail_controller.dart';
import '../pet_detail_state.dart';

enum _PhotoAction {
  makePrimary,
  delete,
}

class PetGallerySection
    extends StatelessWidget {
  final PetDetailState state;
  final PetDetailController controller;

  const PetGallerySection({
    super.key,
    required this.state,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final pet = state.pet;

    if (pet == null) {
      return const SizedBox.shrink();
    }

    final photos = state.photos;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: DogGoTheme.tealLight,
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.photo_library_rounded,
                  color: DogGoTheme.teal,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Galería de ${pet.name}',
                      style: DogGoTheme.title(
                        size: 17,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      photos.isEmpty
                          ? 'Agrega sus mejores fotografías'
                          : '${photos.length} de 8 fotografías',
                      style: DogGoTheme.subtitle(
                        size: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (state.galleryBusy)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                  ),
                )
              else
                IconButton(
                  tooltip: 'Agregar fotografías',
                  onPressed: state.canAddPhoto
                      ? () => _addPhoto(context)
                      : null,
                  icon: const Icon(
                    Icons.add_photo_alternate_rounded,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 15),
          if (photos.isEmpty)
            _EmptyGallery(
              enabled: state.canAddPhoto,
              onAdd: () => _addPhoto(context),
            )
          else
            SizedBox(
              height: 136,
              child: ListView.separated(
                scrollDirection:
                    Axis.horizontal,
                itemCount: photos.length +
                    (state.canAddPhoto ? 1 : 0),
                separatorBuilder: (_, __) =>
                    const SizedBox(width: 10),
                itemBuilder: (_, index) {
                  if (index == photos.length) {
                    return _AddPhotoTile(
                      onTap: () =>
                          _addPhoto(context),
                    );
                  }

                  final photo = photos[index];

                  return _PhotoTile(
                    photo: photo,
                    imageUrl: photo.publicUrl(
                      state.baseUrl,
                    ),
                    loading:
                        state.galleryBusy &&
                            state.actingPhotoId ==
                                photo.id,
                    onTap: () => _openViewer(
                      context,
                      photos,
                      index,
                    ),
                    onOptions: () =>
                        _openPhotoOptions(
                      context,
                      photo,
                    ),
                  );
                },
              ),
            ),
          if (photos.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: DogGoTheme.muted,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'La foto marcada como portada aparecerá en Home, Agenda y paseos.',
                    style: DogGoTheme.subtitle(
                      size: 9.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _addPhoto(
    BuildContext context,
  ) async {
    final result =
        await controller.addPhoto();

    if (result == null ||
        !context.mounted) {
      return;
    }

    _showResult(context, result);
  }

  Future<void> _openPhotoOptions(
    BuildContext context,
    PetPhoto photo,
  ) async {
    if (state.galleryBusy ||
        !photo.hasValidId) {
      return;
    }

    final action =
        await showModalBottomSheet<_PhotoAction>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              0,
              16,
              18,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!photo.isPrimary)
                  ListTile(
                    leading: const Icon(
                      Icons.star_rounded,
                      color: DogGoTheme.orange,
                    ),
                    title: const Text(
                      'Usar como portada',
                    ),
                    subtitle: const Text(
                      'Aparecerá como foto principal.',
                    ),
                    onTap: () => Navigator.pop(
                      sheetContext,
                      _PhotoAction.makePrimary,
                    ),
                  ),
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: DogGoTheme.red,
                  ),
                  title: const Text(
                    'Eliminar fotografía',
                  ),
                  subtitle: Text(
                    photo.isPrimary
                        ? 'Otra foto se convertirá en portada.'
                        : 'Se eliminará de la galería.',
                  ),
                  onTap: () => Navigator.pop(
                    sheetContext,
                    _PhotoAction.delete,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (action == null ||
        !context.mounted) {
      return;
    }

    await Future<void>.delayed(
      const Duration(milliseconds: 250),
    );

    if (!context.mounted) {
      return;
    }

    if (action ==
        _PhotoAction.makePrimary) {
      final result =
          await controller.makePrimary(photo);

      if (context.mounted) {
        _showResult(context, result);
      }

      return;
    }

    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Eliminar fotografía',
          ),
          content: const Text(
            'Esta acción quitará la fotografía definitivamente.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                dialogContext,
                false,
              ),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(
                dialogContext,
                true,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    DogGoTheme.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true ||
        !context.mounted) {
      return;
    }

    final result =
        await controller.deletePhoto(photo);

    if (context.mounted) {
      _showResult(context, result);
    }
  }

  void _openViewer(
    BuildContext context,
    List<PetPhoto> photos,
    int initialIndex,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => _GalleryViewer(
          photos: photos,
          baseUrl: state.baseUrl,
          initialIndex: initialIndex,
          petName:
              state.pet?.name ?? 'Mascota',
        ),
      ),
    );
  }

  void _showResult(
    BuildContext context,
    PetGalleryResult result,
  ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.success
            ? DogGoTheme.teal
            : DogGoTheme.ink,
      ),
    );
  }
}

class _EmptyGallery extends StatelessWidget {
  final bool enabled;
  final VoidCallback onAdd;

  const _EmptyGallery({
    required this.enabled,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DogGoTheme.cream,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: enabled ? onAdd : null,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 25,
          ),
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(20),
            border: Border.all(
              color: DogGoTheme.border,
            ),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.add_photo_alternate_outlined,
                size: 38,
                color: DogGoTheme.teal,
              ),
              const SizedBox(height: 10),
              Text(
                'Agregar fotografías',
                style: DogGoTheme.title(
                  size: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Selecciona una o varias. Puedes guardar hasta 8.',
                style: DogGoTheme.subtitle(
                  size: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  final VoidCallback onTap;

  const _AddPhotoTile({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DogGoTheme.tealLight,
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        child: SizedBox(
          width: 103,
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.add_rounded,
                color: DogGoTheme.teal,
                size: 31,
              ),
              const SizedBox(height: 7),
              Text(
                'Agregar',
                style: DogGoTheme.caption(
                  size: 10,
                  color: DogGoTheme.teal,
                  weight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final PetPhoto photo;
  final String? imageUrl;
  final bool loading;
  final VoidCallback onTap;
  final VoidCallback onOptions;

  const _PhotoTile({
    required this.photo,
    required this.imageUrl,
    required this.loading,
    required this.onTap,
    required this.onOptions,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 119,
      child: Stack(
        children: [
          Positioned.fill(
            child: Material(
              color: DogGoTheme.tealLight,
              borderRadius:
                  BorderRadius.circular(19),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                child: imageUrl == null
                    ? const Icon(
                        Icons.pets_rounded,
                        color: DogGoTheme.teal,
                      )
                    : Image.network(
                        imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, __, ___) {
                          return const Icon(
                            Icons.pets_rounded,
                            color:
                                DogGoTheme.teal,
                          );
                        },
                      ),
              ),
            ),
          ),
          if (photo.isPrimary)
            Positioned(
              left: 7,
              top: 7,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: DogGoTheme.orange,
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star_rounded,
                      size: 12,
                      color: Colors.white,
                    ),
                    SizedBox(width: 3),
                    Text(
                      'Portada',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            right: 5,
            top: 5,
            child: IconButton.filled(
              tooltip: 'Opciones',
              onPressed: onOptions,
              style: IconButton.styleFrom(
                minimumSize: const Size(32, 32),
                maximumSize: const Size(32, 32),
                padding: EdgeInsets.zero,
                backgroundColor:
                    Colors.black.withValues(
                  alpha: .50,
                ),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(
                Icons.more_horiz_rounded,
                size: 19,
              ),
            ),
          ),
          if (loading)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(
                    alpha: .42,
                  ),
                  borderRadius:
                      BorderRadius.circular(19),
                ),
                alignment: Alignment.center,
                child:
                    const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.4,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GalleryViewer extends StatefulWidget {
  final List<PetPhoto> photos;
  final String? baseUrl;
  final int initialIndex;
  final String petName;

  const _GalleryViewer({
    required this.photos,
    required this.baseUrl,
    required this.initialIndex,
    required this.petName,
  });

  @override
  State<_GalleryViewer> createState() =>
      _GalleryViewerState();
}

class _GalleryViewerState
    extends State<_GalleryViewer> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();

    _currentIndex = widget.initialIndex;
    _pageController = PageController(
      initialPage: widget.initialIndex,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.petName),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(
                right: 18,
              ),
              child: Text(
                '${_currentIndex + 1}/'
                '${widget.photos.length}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.photos.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (_, index) {
          final photo = widget.photos[index];
          final url =
              photo.publicUrl(widget.baseUrl);

          if (url == null) {
            return const Center(
              child: Icon(
                Icons.pets_rounded,
                color: Colors.white54,
                size: 80,
              ),
            );
          }

          return InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: Center(
              child: Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) {
                  return const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white54,
                    size: 70,
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}