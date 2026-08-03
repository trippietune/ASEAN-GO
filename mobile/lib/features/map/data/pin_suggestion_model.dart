class PinSuggestion {
  const PinSuggestion({required this.id, required this.status});

  final String id;
  final String status;

  factory PinSuggestion.fromJson(Map<String, dynamic> json) {
    return PinSuggestion(
      id: json['id'] as String,
      status: json['status'] as String,
    );
  }
}
