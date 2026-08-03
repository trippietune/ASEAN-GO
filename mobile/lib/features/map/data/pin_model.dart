class VerifiedPin {
  const VerifiedPin({
    required this.id,
    required this.name,
    required this.category,
    required this.country,
    required this.lat,
    required this.lng,
    required this.isVerified,
    required this.isScamAlert,
    required this.safetyScore,
    required this.averageRating,
    required this.reviewCount,
    this.reportCount = 0,
    this.description,
    this.city,
    this.scamAlertMessage,
    this.photoUrls = const [],
    this.isCheckpoint = false,
    this.isRecommended = false,
    this.hasActiveQuest = false,
    this.isFavorited = false,
  });

  final String id;
  final String name;
  final String category;
  final String country;
  final String? city;
  final double lat;
  final double lng;
  final bool isVerified;
  final bool isScamAlert;
  final int safetyScore;
  final double averageRating;
  final int reviewCount;
  final int reportCount;
  final String? description;
  final String? scamAlertMessage;
  final List<String> photoUrls;
  final bool isCheckpoint;
  final bool isRecommended;
  final bool hasActiveQuest;
  final bool isFavorited;

  factory VerifiedPin.fromJson(Map<String, dynamic> json) {
    return VerifiedPin(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      country: json['country'] as String,
      city: json['city'] as String?,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      isVerified: json['is_verified'] as bool,
      isScamAlert: json['is_scam_alert'] as bool,
      safetyScore: json['safety_score'] as int,
      averageRating: (json['average_rating'] as num).toDouble(),
      reviewCount: json['review_count'] as int,
      reportCount: json['report_count'] as int? ?? 0,
      description: json['description'] as String?,
      scamAlertMessage: json['scam_alert_message'] as String?,
      photoUrls: (json['photo_urls'] as List<dynamic>?)?.cast<String>() ?? const [],
      isCheckpoint: json['is_checkpoint'] as bool? ?? false,
      isRecommended: json['is_recommended'] as bool? ?? false,
      hasActiveQuest: json['has_active_quest'] as bool? ?? false,
      isFavorited: json['is_favorited'] as bool? ?? false,
    );
  }

  VerifiedPin copyWith({bool? isFavorited}) {
    return VerifiedPin(
      id: id,
      name: name,
      category: category,
      country: country,
      city: city,
      lat: lat,
      lng: lng,
      isVerified: isVerified,
      isScamAlert: isScamAlert,
      safetyScore: safetyScore,
      averageRating: averageRating,
      reviewCount: reviewCount,
      reportCount: reportCount,
      description: description,
      scamAlertMessage: scamAlertMessage,
      photoUrls: photoUrls,
      isCheckpoint: isCheckpoint,
      isRecommended: isRecommended,
      hasActiveQuest: hasActiveQuest,
      isFavorited: isFavorited ?? this.isFavorited,
    );
  }
}
