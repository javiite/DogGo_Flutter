import 'package:flutter/material.dart';

import '../../../services/perros_service.dart';
import '../../../theme/doggo_theme.dart';
import '../../pets/models/pet.dart';

class EditWalkPetsSheet extends StatefulWidget {
  final Set<int> initialSelectedIds;
  final String? baseUrl;

  const EditWalkPetsSheet({
    super.key,
    required this.initialSelectedIds,
    required this.baseUrl,
  });

  @override
  State<EditWalkPetsSheet> createState() =>
      _EditWalkPetsSheetState();
}

class _EditWalkPetsSheetState
    extends State<EditWalkPetsSheet> {
  bool _loading = true;
  String? _error;
  List<Pet> _pets = const [];
  late final Set<int> _selectedIds;

  @override
  void initState() {
    super.initState();

    _selectedIds = Set<int>.from(
      widget.initialSelectedIds,
    );

    _loadPets();
  }

  Future<void> _loadPets() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response =
          await PerrosService.obtenerMisPerros();

      if (!mounted) {
        return;
      }

      if (response['success'] != true) {
        throw Exception(
          response['message'] ??
              'No se pudieron cargar tus mascotas.',
        );
      }

      final pets = Pet.listFrom(
        response['data'],
      ).where((pet) => pet.hasValidId).toList();

      pets.sort(
        (first, second) => first.name
            .toLowerCase()
            .compareTo(
              second.name.toLowerCase(),
            ),
      );

      setState(() {
        _pets = pets;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _error = error
            .toString()
            .replaceFirst('Exception: ', '')
            .trim();
      });
    }
  }

  void _togglePet(
    int petId,
    bool selected,
  ) {
    if (selected && _selectedIds.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Puedes seleccionar hasta 5 mascotas.',
          ),
        ),
      );
      return;
    }

    if (!selected && _selectedIds.length == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'El paseo debe incluir por lo menos una mascota.',
          ),
        ),
      );
      return;
    }

    setState(() {
      if (selected) {
        _selectedIds.add(petId);
      } else {
        _selectedIds.remove(petId);
      }
    });
  }

  void _save() {
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Selecciona por lo menos una mascota.',
          ),
        ),
      );
      return;
    }

    Navigator.pop<List<int>>(
      context,
      _selectedIds.toList(growable: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAF9),
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(30),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 11),
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: DogGoTheme.border,
                borderRadius:
                    BorderRadius.circular(20),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                22,
                19,
                14,
                14,
              ),
              child: Row(
                children: [
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: DogGoTheme.tealLight,
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.pets_rounded,
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
                          'Editar mascotas',
                          style: DogGoTheme.title(
                            size: 20,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_selectedIds.length} de 5 seleccionadas',
                          style: DogGoTheme.subtitle(
                            size: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar',
                    onPressed: () =>
                        Navigator.pop(context),
                    icon: const Icon(
                      Icons.close_rounded,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _buildContent(),
            ),
            if (!_loading &&
                _error == null &&
                _pets.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  18,
                ),
                child: ElevatedButton.icon(
                  onPressed: _selectedIds.isEmpty
                      ? null
                      : _save,
                  icon: const Icon(
                    Icons.check_rounded,
                  ),
                  label: Text(
                    _selectedIds.length == 1
                        ? 'Guardar 1 mascota'
                        : 'Guardar ${_selectedIds.length} mascotas',
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize:
                        const Size.fromHeight(54),
                    backgroundColor:
                        DogGoTheme.teal,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 45,
                color: DogGoTheme.muted,
              ),
              const SizedBox(height: 14),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: DogGoTheme.subtitle(
                  size: 12,
                ),
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: _loadPets,
                icon: const Icon(
                  Icons.refresh_rounded,
                ),
                label: const Text(
                  'Intentar de nuevo',
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_pets.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Text(
            'Todavía no tienes mascotas registradas.',
            textAlign: TextAlign.center,
            style: DogGoTheme.subtitle(
              size: 12,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        20,
        16,
        20,
        12,
      ),
      itemCount: _pets.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: 10),
      itemBuilder: (_, index) {
        final pet = _pets[index];
        final selected =
            _selectedIds.contains(pet.id);

        return Material(
          color: selected
              ? DogGoTheme.tealLight
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: () => _togglePet(
              pet.id,
              !selected,
            ),
            borderRadius:
                BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(20),
                border: Border.all(
                  color: selected
                      ? DogGoTheme.teal
                          .withValues(alpha: .45)
                      : DogGoTheme.border,
                ),
              ),
              child: Row(
                children: [
                  _PetPhoto(
                    pet: pet,
                    baseUrl: widget.baseUrl,
                  ),
                  const SizedBox(width: 12),
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
                            size: 15,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          pet.shortDescription,
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style: DogGoTheme.subtitle(
                            size: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Checkbox(
                    value: selected,
                    activeColor: DogGoTheme.teal,
                    onChanged: (value) =>
                        _togglePet(
                      pet.id,
                      value == true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PetPhoto extends StatelessWidget {
  final Pet pet;
  final String? baseUrl;

  const _PetPhoto({
    required this.pet,
    required this.baseUrl,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl =
        pet.publicPhotoUrl(baseUrl);

    final placeholder = Container(
      color: DogGoTheme.tealLight,
      alignment: Alignment.center,
      child: const Icon(
        Icons.pets_rounded,
        color: DogGoTheme.teal,
      ),
    );

    return Container(
      width: 55,
      height: 55,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(17),
      ),
      child: imageUrl == null ||
              imageUrl.trim().isEmpty
          ? placeholder
          : Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return placeholder;
              },
            ),
    );
  }
}