import '../../../core/api/api_client.dart';
import 'quest_model.dart';

class QuestCompletionResult {
  const QuestCompletionResult({
    required this.alreadyCompleted,
    required this.xpAwarded,
    required this.coinAwarded,
    required this.xp,
    required this.level,
    required this.coinBalance,
  });

  final bool alreadyCompleted;
  final int xpAwarded;
  final int coinAwarded;
  final int xp;
  final int level;
  final int coinBalance;

  factory QuestCompletionResult.fromJson(Map<String, dynamic> json) {
    return QuestCompletionResult(
      alreadyCompleted: json['alreadyCompleted'] as bool,
      xpAwarded: json['xpAwarded'] as int,
      coinAwarded: json['coinAwarded'] as int? ?? 0,
      xp: json['xp'] as int,
      level: json['level'] as int,
      coinBalance: json['coin_balance'] as int,
    );
  }
}

class QuestsRepository {
  QuestsRepository(this._client);

  final ApiClient _client;

  Future<List<Quest>> fetchDailyQuests() async {
    final response = await _client.dio.get('/quests/daily');
    return (response.data as List)
        .map((e) => Quest.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<QuestCompletionResult> completeQuest(String questId, {String? pinId}) async {
    final response = await _client.dio.post('/quests/complete', data: {
      'questId': questId,
      // ignore: use_null_aware_elements
      if (pinId != null) 'pinId': pinId,
    });
    return QuestCompletionResult.fromJson(response.data as Map<String, dynamic>);
  }
}
