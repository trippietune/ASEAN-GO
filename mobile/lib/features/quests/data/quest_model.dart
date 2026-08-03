enum QuestStatus { notStarted, inProgress, completed, claimed }

QuestStatus _parseStatus(String value) {
  switch (value) {
    case 'in_progress':
      return QuestStatus.inProgress;
    case 'completed':
      return QuestStatus.completed;
    case 'claimed':
      return QuestStatus.claimed;
    default:
      return QuestStatus.notStarted;
  }
}

/// A single unmet-or-met unlock condition on a locked quest. [description]
/// is a pre-formatted string from the backend so the client doesn't need to
/// duplicate per-type requirement copy.
class QuestUnlockRequirement {
  const QuestUnlockRequirement({
    required this.type,
    required this.description,
    required this.satisfied,
  });

  final String type;
  final String description;
  final bool satisfied;

  factory QuestUnlockRequirement.fromJson(Map<String, dynamic> json) {
    return QuestUnlockRequirement(
      type: json['type'] as String,
      description: json['description'] as String,
      satisfied: json['satisfied'] as bool,
    );
  }
}

class Quest {
  const Quest({
    required this.id,
    required this.title,
    required this.description,
    required this.questType,
    required this.xpReward,
    required this.coinReward,
    required this.status,
    this.pinId,
    this.country,
    this.category,
    this.chapterId,
    this.chapterOrder,
    this.locked = false,
    this.unlockRequirements = const [],
  });

  final String id;
  final String title;
  final String? description;
  final String questType;
  final int xpReward;
  final int coinReward;
  final QuestStatus status;
  final String? pinId;
  final String? country;
  final String? category;
  final String? chapterId;
  final int? chapterOrder;
  final bool locked;
  final List<QuestUnlockRequirement> unlockRequirements;

  bool get isCompleted => status == QuestStatus.completed || status == QuestStatus.claimed;

  factory Quest.fromJson(Map<String, dynamic> json) {
    return Quest(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      questType: json['quest_type'] as String,
      xpReward: json['xp_reward'] as int,
      coinReward: json['coin_reward'] as int,
      status: _parseStatus(json['status'] as String),
      pinId: json['pin_id'] as String?,
      country: json['country'] as String?,
      category: json['category'] as String?,
      chapterId: json['chapter_id'] as String?,
      chapterOrder: json['chapter_order'] as int?,
      // Defaults preserve backward compatibility with any cached/older
      // response shape that predates the unlock system.
      locked: json['locked'] as bool? ?? false,
      unlockRequirements: (json['unlockRequirements'] as List<dynamic>?)
              ?.map((e) => QuestUnlockRequirement.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Quest copyWith({QuestStatus? status}) {
    return Quest(
      id: id,
      title: title,
      description: description,
      questType: questType,
      xpReward: xpReward,
      coinReward: coinReward,
      status: status ?? this.status,
      pinId: pinId,
      country: country,
      category: category,
      chapterId: chapterId,
      chapterOrder: chapterOrder,
      locked: locked,
      unlockRequirements: unlockRequirements,
    );
  }
}
