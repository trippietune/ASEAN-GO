import '../../../core/api/api_client.dart';
import 'quest_model.dart';

/// Minimal projection of an awarded achievement — just enough for a toast.
/// The full model (with unlock status for every achievement) lives in
/// features/achievements/data/achievement_model.dart.
class AwardedAchievement {
  const AwardedAchievement({required this.id, required this.title, this.iconUrl});

  final String id;
  final String title;
  final String? iconUrl;

  factory AwardedAchievement.fromJson(Map<String, dynamic> json) {
    return AwardedAchievement(
      id: json['id'] as String,
      title: json['title'] as String,
      iconUrl: json['icon_url'] as String?,
    );
  }
}

class QuestCompletionResult {
  const QuestCompletionResult({
    required this.alreadyCompleted,
    required this.xpAwarded,
    required this.coinAwarded,
    required this.xp,
    required this.level,
    required this.coinBalance,
    required this.leveledUp,
    required this.previousLevel,
    required this.skippedLevels,
    this.awardedAchievements = const [],
  });

  final bool alreadyCompleted;
  final int xpAwarded;
  final int coinAwarded;
  final int xp;
  final int level;
  final int coinBalance;
  final bool leveledUp;
  final int previousLevel;
  final int skippedLevels;
  final List<AwardedAchievement> awardedAchievements;

  factory QuestCompletionResult.fromJson(Map<String, dynamic> json) {
    return QuestCompletionResult(
      alreadyCompleted: json['alreadyCompleted'] as bool,
      xpAwarded: json['xpAwarded'] as int,
      coinAwarded: json['coinAwarded'] as int? ?? 0,
      xp: json['xp'] as int,
      level: json['level'] as int,
      coinBalance: json['coin_balance'] as int,
      leveledUp: json['leveledUp'] as bool? ?? false,
      previousLevel: json['previousLevel'] as int? ?? (json['level'] as int),
      skippedLevels: json['skippedLevels'] as int? ?? 0,
      awardedAchievements: (json['awardedAchievements'] as List<dynamic>?)
              ?.map((e) => AwardedAchievement.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

class QuestsRepository {
  QuestsRepository(this._client);

  final ApiClient _client;

  /// All quests of every type, with unlock state. [type] optionally filters
  /// to a single quest_type (used by fetchDailyQuests below).
  Future<List<Quest>> fetchQuests({String? type}) async {
    final response = await _client.dio.get(
      '/quests',
      queryParameters: type != null ? {'type': type} : null,
    );
    return (response.data as List)
        .map((e) => Quest.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Quest>> fetchDailyQuests() async {
    final response = await _client.dio.get('/quests/daily');
    return (response.data as List)
        .map((e) => Quest.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<QuestCompletionResult> completeQuest(
    String questId, {
    String? pinId,
  }) async {
    final response = await _client.dio.post(
      '/quests/complete',
      data: {
        'questId': questId,
        // ignore: use_null_aware_elements
        if (pinId != null) 'pinId': pinId,
      },
    );
    return QuestCompletionResult.fromJson(
      response.data as Map<String, dynamic>,
    );
  }
}
