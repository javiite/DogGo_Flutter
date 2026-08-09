import 'models/pet.dart';
import 'models/pet_photo.dart';

class PetDetailState {
  final bool loading;
  final bool galleryBusy;
  final int? actingPhotoId;
  final String? error;
  final String? baseUrl;
  final Pet? pet;
  final bool changed;

  const PetDetailState({
    this.loading = true,
    this.galleryBusy = false,
    this.actingPhotoId,
    this.error,
    this.baseUrl,
    this.pet,
    this.changed = false,
  });

  bool get hasPet => pet != null;

  bool get canAddPhoto {
    return !loading &&
        !galleryBusy &&
        pet?.canAddPhoto == true;
  }

  String? get photoUrl {
    return pet?.publicPhotoUrl(baseUrl);
  }

  List<PetPhoto> get photos {
    return pet?.photos ?? const [];
  }

  List<String> get photoUrls {
    return pet?.publicPhotoUrls(baseUrl) ??
        const [];
  }

  PetDetailState copyWith({
    bool? loading,
    bool? galleryBusy,
    int? actingPhotoId,
    bool clearActingPhoto = false,
    String? error,
    bool clearError = false,
    String? baseUrl,
    Pet? pet,
    bool clearPet = false,
    bool? changed,
  }) {
    return PetDetailState(
      loading: loading ?? this.loading,
      galleryBusy:
          galleryBusy ?? this.galleryBusy,
      actingPhotoId: clearActingPhoto
          ? null
          : actingPhotoId ??
              this.actingPhotoId,
      error: clearError
          ? null
          : error ?? this.error,
      baseUrl: baseUrl ?? this.baseUrl,
      pet: clearPet
          ? null
          : pet ?? this.pet,
      changed: changed ?? this.changed,
    );
  }
}