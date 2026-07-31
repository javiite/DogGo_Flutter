import 'models/pet.dart';

class PetDetailState {
  final bool loading;
  final String? error;
  final String? baseUrl;
  final Pet? pet;
  final bool changed;

  const PetDetailState({
    this.loading = true,
    this.error,
    this.baseUrl,
    this.pet,
    this.changed = false,
  });

  bool get hasPet => pet != null;

  String? get photoUrl {
    return pet?.publicPhotoUrl(baseUrl);
  }

  PetDetailState copyWith({
    bool? loading,
    String? error,
    bool clearError = false,
    String? baseUrl,
    Pet? pet,
    bool clearPet = false,
    bool? changed,
  }) {
    return PetDetailState(
      loading: loading ?? this.loading,
      error: clearError ? null : error ?? this.error,
      baseUrl: baseUrl ?? this.baseUrl,
      pet: clearPet ? null : pet ?? this.pet,
      changed: changed ?? this.changed,
    );
  }
}