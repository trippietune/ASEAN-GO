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
    );
  }
}
