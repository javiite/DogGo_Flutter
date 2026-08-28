class WalkerTrust {
  final double score;
  final bool verified;
  final int completedWalks;
  final int recurringClients;
  final int experienceYears;
  final List<String> badges;

  const WalkerTrust({
    required this.score,
    required this.verified,
    required this.completedWalks,
    required this.recurringClients,
    required this.experienceYears,
    required this.badges,
  });

  factory WalkerTrust.fromMap(Map<String, dynamic> map) {
    final rawBadges = map['insignias'];
    return WalkerTrust(
      score: _decimal(map['score']) ?? 0,
      verified: map['verificado'] == true,
      completedWalks: _integer(map['finalizados']) ?? 0,
      recurringClients: _integer(map['clientesRecurrentes']) ?? 0,
      experienceYears: _integer(map['experienciaAnios']) ?? 0,
      badges: rawBadges is List
          ? rawBadges
                .map((item) => item?.toString().trim() ?? '')
                .where((item) => item.isNotEmpty)
                .toList(growable: false)
          : const [],
    );
  }

  String get scoreLabel => score.toStringAsFixed(0);

  String get levelLabel {
    if (score >= 90) return 'Confianza sobresaliente';
    if (score >= 75) return 'Confianza alta';
    if (score >= 55) return 'Confianza en crecimiento';
    return 'Construyendo reputación';
  }

  static int? _integer(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse('$value');
  }

  static double? _decimal(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value');
  }
}
