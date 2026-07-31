import 'models/pet.dart';

class PetsState {
  final bool loading;
  final String? error;
  final String? baseUrl;
  final List<Pet> pets;
  final int? deletingPetId;
  final String searchQuery;

  const PetsState({
    this.loading = true,
    this.error,
    this.baseUrl,
    this.pets = const [],
    this.deletingPetId,
    this.searchQuery = '',
  });

  bool get isEmpty => !loading && pets.isEmpty;

  bool get hasPets => pets.isNotEmpty;

  int get totalPets => pets.length;

  bool get isDeleting => deletingPetId != null;

  List<Pet> get filteredPets {
    final query = searchQuery.trim().toLowerCase();

    if (query.isEmpty) {
      return pets;
    }

    return pets.where((pet) {
      return pet.name.toLowerCase().contains(query) ||
          pet.breed.toLowerCase().contains(query) ||
          pet.size.toLowerCase().contains(query) ||
          pet.notes.toLowerCase().contains(query);
    }).toList(growable: false);
  }

  bool isPetDeleting(Pet pet) {
    return deletingPetId == pet.id;
  }

  String? photoUrlFor(Pet pet) {
    return pet.publicPhotoUrl(baseUrl);
  }

  PetsState copyWith({
    bool? loading,
    String? error,
    bool clearError = false,
    String? baseUrl,
    List<Pet>? pets,
    int? deletingPetId,
    bool clearDeletingPet = false,
    String? searchQuery,
  }) {
    return PetsState(
      loading: loading ?? this.loading,
      error: clearError ? null : error ?? this.error,
      baseUrl: baseUrl ?? this.baseUrl,
      pets: pets ?? this.pets,
      deletingPetId: clearDeletingPet
          ? null
          : deletingPetId ?? this.deletingPetId,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}