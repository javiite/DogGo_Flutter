enum UserRole { owner, walker, admin, unknown }

extension UserRoleData on UserRole {
  String get label {
    return switch (this) {
      UserRole.owner => 'Dueño',
      UserRole.walker => 'Paseador',
      UserRole.admin => 'Administrador',
      UserRole.unknown => 'Sin rol',
    };
  }

  String get apiValue {
    return switch (this) {
      UserRole.owner => 'Duenio',
      UserRole.walker => 'Paseador',
      UserRole.admin => 'Administrador',
      UserRole.unknown => '',
    };
  }

  bool get isOwner => this == UserRole.owner;
  bool get isWalker => this == UserRole.walker;
  bool get isAdmin => this == UserRole.admin;
}

abstract final class UserRoleCodec {
  static UserRole parse(String? value) {
    final normalized = (value ?? '')
        .trim()
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ñ', 'n')
        .replaceAll(RegExp(r'[\s_\-]'), '');

    return switch (normalized) {
      'dueno' || 'duenio' || 'owner' || 'cliente' => UserRole.owner,
      'paseador' || 'walker' || 'dogwalker' => UserRole.walker,
      'admin' || 'administrador' || 'superadmin' => UserRole.admin,
      _ => UserRole.unknown,
    };
  }
}
