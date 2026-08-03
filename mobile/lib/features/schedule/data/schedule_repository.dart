import '../../../core/api/api_client.dart';
import 'schedule_model.dart';

class ScheduleRepository {
  ScheduleRepository(this._client);

  final ApiClient _client;

  String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Future<List<ScheduleItem>> fetchAll({DateTime? date}) async {
    final response = await _client.dio.get('/schedule', queryParameters: {
      // ignore: use_null_aware_elements
      if (date != null) 'date': _formatDate(date),
    });
    return (response.data as List)
        .map((e) => ScheduleItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Throws a [DioException] with status 409 if this pin is already
  /// scheduled for the given date, 404 if the pin doesn't exist, or 400 if
  /// [endTime] isn't after [startTime].
  Future<ScheduleItem> addItem({
    required String pinId,
    required DateTime scheduledDate,
    String? startTime,
    String? endTime,
    String? note,
  }) async {
    final response = await _client.dio.post('/schedule', data: {
      'pinId': pinId,
      'scheduledDate': _formatDate(scheduledDate),
      // ignore: use_null_aware_elements
      if (startTime != null) 'startTime': startTime,
      // ignore: use_null_aware_elements
      if (endTime != null) 'endTime': endTime,
      // ignore: use_null_aware_elements
      if (note != null && note.isNotEmpty) 'note': note,
    });
    return ScheduleItem.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> removeItem(String itemId) {
    return _client.dio.delete('/schedule/$itemId');
  }
}
