class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.xp,
    required this.level,
    required this.isPremium,
    required this.coinBalance,
    this.avatarUrl,
    this.xpToNextLevel,
  });

  final String id;
  final String email;
  final String displayName;
  final int xp;
  final int level;
  final bool isPremium;
  final int coinBalance;
  final String? avatarUrl;
  final int? xpToNextLevel;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String,
      xp: json['xp'] as int,
      level: json['level'] as int,
      isPremium: json['is_premium'] as bool,
      coinBalance: json['coin_balance'] as int,
      avatarUrl: json['avatar_url'] as String?,
      xpToNextLevel: json['xpToNextLevel'] as int?,
    );
  }

  AppUser copyWith({int? xp, int? level, int? coinBalance}) {
    return AppUser(
      id: id,
      email: email,
      displayName: displayName,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      isPremium: isPremium,
      coinBalance: coinBalance ?? this.coinBalance,
      avatarUrl: avatarUrl,
      xpToNextLevel: xp != null ? 100 - (xp % 100) : xpToNextLevel,
    );
  }
}
