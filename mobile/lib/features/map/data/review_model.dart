class Review {
  const Review({
    required this.id,
    required this.pinId,
    required this.userId,
    required this.userDisplayName,
    required this.rating,
    required this.photoUrls,
    required this.createdAt,
    required this.updatedAt,
    this.userAvatarUrl,
    this.comment,
  });

  final String id;
  final String pinId;
  final String userId;
  final String userDisplayName;
  final String? userAvatarUrl;
  final int rating;
  final String? comment;
  final List<String> photoUrls;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as String,
      pinId: json['pin_id'] as String,
      userId: json['user_id'] as String,
      userDisplayName: json['user_display_name'] as String,
      userAvatarUrl: json['user_avatar_url'] as String?,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      photoUrls: (json['photo_urls'] as List).cast<String>(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
