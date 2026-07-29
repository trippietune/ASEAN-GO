class RiskPin {
  const RiskPin({
    required this.id,
    required this.name,
    required this.category,
    required this.country,
    required this.lat,
    required this.lng,
    required this.isScamAlert,
    required this.safetyScore,
    required this.distanceMeters,
    required this.reportCount,
    this.city,
    this.scamAlertMessage,
  });

  final String id;
  final String name;
  final String category;
  final String country;
  final String? city;
  final double lat;
  final double lng;
  final bool isScamAlert;
  final int safetyScore;
  final double distanceMeters;
  final int reportCount;
  final String? scamAlertMessage;

  factory RiskPin.fromJson(Map<String, dynamic> json) {
    return RiskPin(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      country: json['country'] as String,
      city: json['city'] as String?,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      isScamAlert: json['is_scam_alert'] as bool,
      safetyScore: json['safety_score'] as int,
      distanceMeters: (json['distance_meters'] as num).toDouble(),
      reportCount: json['report_count'] as int,
      scamAlertMessage: json['scam_alert_message'] as String?,
    );
  }
}
