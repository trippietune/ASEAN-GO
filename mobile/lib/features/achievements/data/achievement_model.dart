class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconUrl,
    required this.criteriaType,
    required this.countThreshold,
    required this.xpReward,
    required this.coinReward,
    required this.unlocked,
    this.unlockedAt,
  });

  final String id;
  final String title;
  final String? description;
  final String? iconUrl;
  final String criteriaType;
  final int? countThreshold;
  final int xpReward;
  final int coinReward;
  final bool unlocked;
  final DateTime? unlockedAt;

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      iconUrl: json['icon_url'] as String?,
      criteriaType: json['criteria_type'] as String,
      countThreshold: json['count_threshold'] as int?,
      xpReward: json['xp_reward'] as int,
      coinReward: json['coin_reward'] as int,
      unlocked: json['unlocked'] as bool,
      unlockedAt: json['unlocked_at'] != null
          ? DateTime.parse(json['unlocked_at'] as String)
          : null,
    );
  }
}
