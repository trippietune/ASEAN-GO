enum RiskSeverity { caution, warning, danger }

extension RiskSeverityX on RiskSeverity {
  String get apiValue => name;

  String get label {
    switch (this) {
      case RiskSeverity.caution:
        return 'ระวังนิดหน่อย';
      case RiskSeverity.warning:
        return 'ควรระวัง';
      case RiskSeverity.danger:
        return 'อันตราย';
    }
  }

  static RiskSeverity fromApi(String value) {
    return RiskSeverity.values.firstWhere((s) => s.apiValue == value, orElse: () => RiskSeverity.caution);
  }
}

class RiskReport {
  const RiskReport({
    required this.id,
    required this.pinId,
    required this.reportedBy,
    required this.reporterDisplayName,
    required this.severity,
    required this.description,
    required this.createdAt,
    this.photoUrls = const [],
  });

  final String id;
  final String pinId;
  final String reportedBy;
  final String reporterDisplayName;
  final RiskSeverity severity;
  final String description;
  final DateTime createdAt;
  final List<String> photoUrls;

  factory RiskReport.fromJson(Map<String, dynamic> json) {
    return RiskReport(
      id: json['id'] as String,
      pinId: json['pin_id'] as String,
      reportedBy: json['reported_by'] as String,
      reporterDisplayName: json['reporter_display_name'] as String,
      severity: RiskSeverityX.fromApi(json['severity'] as String),
      description: json['description'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      photoUrls: (json['photo_urls'] as List<dynamic>?)?.cast<String>() ?? const [],
    );
  }
}
