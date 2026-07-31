class SessionState {
  final bool loading;
  final bool authenticated;
  final int? userId;
  final String? token;
  final String name;
  final String email;
  final String role;
  final String? errorMessage;

  const SessionState({
    this.loading = true,
    this.authenticated = false,
    this.userId,
    this.token,
    this.name = 'Usuario',
    this.email = '',
    this.role = 'Sin rol',
    this.errorMessage,
  });

  bool get isOwner {
    final value = _normalize(role);

    return value == 'dueno' ||
        value == 'duenio' ||
        value == 'owner' ||
        value == 'cliente';
  }

  bool get isWalker {
    final value = _normalize(role);

    return value == 'paseador' ||
        value == 'walker' ||
        value == 'dogwalker';
  }

  bool get isAdmin {
    final value = _normalize(role);

    return value == 'admin' ||
        value == 'administrador';
  }

  SessionState copyWith({
    bool? loading,
    bool? authenticated,
    int? userId,
    bool clearUserId = false,
    String? token,
    bool clearToken = false,
    String? name,
    String? email,
    String? role,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SessionState(
      loading: loading ?? this.loading,
      authenticated:
          authenticated ?? this.authenticated,
      userId:
          clearUserId ? null : userId ?? this.userId,
      token: clearToken ? null : token ?? this.token,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      errorMessage: clearError
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }

  static String _normalize(String value) {
    return value
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
  }
}