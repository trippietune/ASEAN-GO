import '../../../core/api/api_client.dart';

enum CoinPackage { small, medium, large, xl }

extension CoinPackagePricing on CoinPackage {
  String get apiId => name;

  int get coins => switch (this) {
        CoinPackage.small => 30,
        CoinPackage.medium => 150,
        CoinPackage.large => 500,
        CoinPackage.xl => 1200,
      };

  int get priceThb => switch (this) {
        CoinPackage.small => 30,
        CoinPackage.medium => 129,
        CoinPackage.large => 399,
        CoinPackage.xl => 699,
      };
}

class CoinPurchaseResult {
  const CoinPurchaseResult({required this.success, required this.status, required this.transactionId, this.newBalance});

  final bool success;
  final String status; // 'successful' | 'pending'
  final String transactionId;
  final int? newBalance;

  factory CoinPurchaseResult.fromJson(Map<String, dynamic> json) {
    return CoinPurchaseResult(
      success: json['success'] as bool,
      status: json['status'] as String,
      transactionId: json['transactionId'] as String,
      newBalance: json['newBalance'] as int?,
    );
  }
}

class CoinTransaction {
  const CoinTransaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.createdAt,
    this.referenceId,
  });

  final String id;
  final int amount;
  final String type;
  final String? referenceId;
  final DateTime createdAt;

  factory CoinTransaction.fromJson(Map<String, dynamic> json) {
    return CoinTransaction(
      id: json['id'] as String,
      amount: json['amount'] as int,
      type: json['type'] as String,
      referenceId: json['reference_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class CoinsRepository {
  CoinsRepository(this._client);

  final ApiClient _client;

  Future<int> fetchBalance() async {
    final response = await _client.dio.get('/coins/balance');
    return response.data['balance'] as int;
  }

  /// [omiseToken] comes from [OmiseTokenizationClient.createToken] — full
  /// card data is tokenized client-side against Omise directly and never
  /// passes through this server.
  Future<CoinPurchaseResult> purchaseCoins(CoinPackage package, {required String omiseToken}) async {
    final response = await _client.dio.post('/coins/purchase', data: {
      'packageId': package.apiId,
      'omiseToken': omiseToken,
    });
    return CoinPurchaseResult.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<CoinTransaction>> fetchTransactions() async {
    final response = await _client.dio.get('/coins/transactions');
    return (response.data as List)
        .map((e) => CoinTransaction.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
