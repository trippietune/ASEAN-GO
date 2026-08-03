class ScheduleItem {
  const ScheduleItem({
    required this.id,
    required this.pinId,
    required this.pinName,
    required this.pinCategory,
    required this.scheduledDate,
    this.startTime,
    this.endTime,
    this.note,
    this.pinCity,
    this.pinCountry,
  });

  final String id;
  final String pinId;
  final String pinName;
  final String pinCategory;
  final DateTime scheduledDate;
  final String? startTime;
  final String? endTime;
  final String? note;
  final String? pinCity;
  final String? pinCountry;

  factory ScheduleItem.fromJson(Map<String, dynamic> json) {
    return ScheduleItem(
      id: json['id'] as String,
      pinId: json['pin_id'] as String,
      pinName: json['pin_name'] as String,
      pinCategory: json['pin_category'] as String,
      scheduledDate: DateTime.parse(json['scheduled_date'] as String),
      startTime: json['start_time'] as String?,
      endTime: json['end_time'] as String?,
      note: json['note'] as String?,
      pinCity: json['pin_city'] as String?,
      pinCountry: json['pin_country'] as String?,
    );
  }
}
