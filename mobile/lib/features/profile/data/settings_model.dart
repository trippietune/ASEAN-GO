class NotificationSettings {
  const NotificationSettings({
    required this.pushNotifications,
    required this.emailNotifications,
    required this.safetyAlerts,
    required this.questReminders,
    required this.promotions,
  });

  final bool pushNotifications;
  final bool emailNotifications;
  final bool safetyAlerts;
  final bool questReminders;
  final bool promotions;

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      pushNotifications: json['pushNotifications'] as bool,
      emailNotifications: json['emailNotifications'] as bool,
      safetyAlerts: json['safetyAlerts'] as bool,
      questReminders: json['questReminders'] as bool,
      promotions: json['promotions'] as bool,
    );
  }

  Map<String, dynamic> toJson() => {
        'pushNotifications': pushNotifications,
        'emailNotifications': emailNotifications,
        'safetyAlerts': safetyAlerts,
        'questReminders': questReminders,
        'promotions': promotions,
      };

  NotificationSettings copyWith({
    bool? pushNotifications,
    bool? emailNotifications,
    bool? safetyAlerts,
    bool? questReminders,
    bool? promotions,
  }) {
    return NotificationSettings(
      pushNotifications: pushNotifications ?? this.pushNotifications,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      safetyAlerts: safetyAlerts ?? this.safetyAlerts,
      questReminders: questReminders ?? this.questReminders,
      promotions: promotions ?? this.promotions,
    );
  }
}

class PrivacySettings {
  const PrivacySettings({
    required this.showProfileToOthers,
    required this.showCheckins,
    required this.showReviews,
    required this.allowDataCollection,
  });

  final bool showProfileToOthers;
  final bool showCheckins;
  final bool showReviews;
  final bool allowDataCollection;

  factory PrivacySettings.fromJson(Map<String, dynamic> json) {
    return PrivacySettings(
      showProfileToOthers: json['showProfileToOthers'] as bool,
      showCheckins: json['showCheckins'] as bool,
      showReviews: json['showReviews'] as bool,
      allowDataCollection: json['allowDataCollection'] as bool,
    );
  }

  Map<String, dynamic> toJson() => {
        'showProfileToOthers': showProfileToOthers,
        'showCheckins': showCheckins,
        'showReviews': showReviews,
        'allowDataCollection': allowDataCollection,
      };

  PrivacySettings copyWith({
    bool? showProfileToOthers,
    bool? showCheckins,
    bool? showReviews,
    bool? allowDataCollection,
  }) {
    return PrivacySettings(
      showProfileToOthers: showProfileToOthers ?? this.showProfileToOthers,
      showCheckins: showCheckins ?? this.showCheckins,
      showReviews: showReviews ?? this.showReviews,
      allowDataCollection: allowDataCollection ?? this.allowDataCollection,
    );
  }
}
