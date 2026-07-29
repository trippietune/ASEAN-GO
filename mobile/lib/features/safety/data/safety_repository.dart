import '../../../core/api/api_client.dart';
import 'risk_pin_model.dart';
import 'risk_report_model.dart';

class EmergencyContact {
  const EmergencyContact({this.name, this.phone});

  final String? name;
  final String? phone;

  bool get isSet => name != null && phone != null;

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(name: json['name'] as String?, phone: json['phone'] as String?);
  }
}

class SosEvent {
  const SosEvent({required this.id, required this.status, required this.createdAt});

  final String id;
  final String status;
  final DateTime createdAt;

  factory SosEvent.fromJson(Map<String, dynamic> json) {
    return SosEvent(
      id: json['id'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse((json['createdAt'] ?? json['created_at']) as String),
    );
  }
}

class SafetyRepository {
  SafetyRepository(this._client);

  final ApiClient _client;

  Future<List<RiskPin>> fetchNearbyRisks({
    required double lat,
    required double lng,
    double radiusMeters = 1500,
  }) async {
    final response = await _client.dio.get('/pins/nearby-risks', queryParameters: {
      'lat': lat,
      'lng': lng,
      'radiusMeters': radiusMeters,
    });
    return (response.data as List)
        .map((e) => RiskPin.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<EmergencyContact> fetchEmergencyContact() async {
    final response = await _client.dio.get('/safety/emergency-contact');
    return EmergencyContact.fromJson(response.data as Map<String, dynamic>);
  }

  Future<EmergencyContact> updateEmergencyContact({required String name, required String phone}) async {
    final response = await _client.dio.put('/safety/emergency-contact', data: {
      'name': name,
      'phone': phone,
    });
    return EmergencyContact.fromJson(response.data as Map<String, dynamic>);
  }

  Future<SosEvent?> fetchActiveSos() async {
    final response = await _client.dio.get('/safety/sos/active');
    if (response.data == null) return null;
    return SosEvent.fromJson(response.data as Map<String, dynamic>);
  }

  Future<SosEvent> triggerSos({required double lat, required double lng}) async {
    final response = await _client.dio.post('/safety/sos', data: {'lat': lat, 'lng': lng});
    return SosEvent.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> resolveSos(String eventId) {
    return _client.dio.post('/safety/sos/$eventId/resolve');
  }

  Future<List<RiskReport>> fetchRiskReports(String pinId) async {
    final response = await _client.dio.get('/pins/$pinId/risk-reports');
    return (response.data as List)
        .map((e) => RiskReport.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<RiskReport> submitRiskReport(
    String pinId, {
    required RiskSeverity severity,
    required String description,
    List<String> photoUrls = const [],
  }) async {
    final response = await _client.dio.post('/pins/$pinId/risk-reports', data: {
      'severity': severity.apiValue,
      'description': description,
      'photoUrls': photoUrls,
    });
    return RiskReport.fromJson(response.data as Map<String, dynamic>);
  }
}
