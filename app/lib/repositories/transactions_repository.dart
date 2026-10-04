import '../models/transaction.dart';
import '../services/api_client.dart';

class TransactionsRepository {
  final ApiClient apiClient;

  TransactionsRepository({required this.apiClient});

  Future<TransactionListResponse> getTransactions({
    int skip = 0,
    int limit = 50,
    String? category,
    String? type,
    String? search,
    DateTime? startDate,
    DateTime? endDate,
    String sort = 'date_desc',
  }) async {
    final queryParams = <String, dynamic>{
      'skip': skip,
      'limit': limit,
      'sort': sort,
    };
    if (category != null && category.isNotEmpty && category != 'All') {
      queryParams['category'] = category;
    }
    if (type != null && type.isNotEmpty && type != 'All') {
      queryParams['type'] = type.toLowerCase();
    }
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }
    if (startDate != null) {
      queryParams['start_date'] = startDate.toIso8601String();
    }
    if (endDate != null) {
      queryParams['end_date'] = endDate.toIso8601String();
    }

    final response = await apiClient.get(
      '/transactions',
      queryParameters: queryParams,
    );

    return TransactionListResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<TransactionModel> getTransaction(String id) async {
    final response = await apiClient.get('/transactions/$id');
    return TransactionModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<TransactionModel> createTransaction({
    required String type,
    required double amount,
    required String description,
    required String category,
    required DateTime date,
    required String paymentMethod,
    String? accountId,
  }) async {
    final data = <String, dynamic>{
      'type': type.toLowerCase(),
      'amount': amount,
      'description': description.trim(),
      'category': category.trim(),
      'date': date.toIso8601String(),
      'payment_method': paymentMethod.trim(),
    };
    if (accountId != null) data['account_id'] = accountId;

    final response = await apiClient.post(
      '/transactions',
      data: data,
    );
    return TransactionModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<TransactionModel> updateTransaction(
    String id, {
    String? type,
    double? amount,
    String? description,
    String? category,
    DateTime? date,
    String? paymentMethod,
  }) async {
    final data = <String, dynamic>{};
    if (type != null) data['type'] = type.toLowerCase();
    if (amount != null) data['amount'] = amount;
    if (description != null) data['description'] = description.trim();
    if (category != null) data['category'] = category.trim();
    if (date != null) data['date'] = date.toIso8601String();
    if (paymentMethod != null) data['payment_method'] = paymentMethod.trim();

    final response = await apiClient.put(
      '/transactions/$id',
      data: data,
    );
    return TransactionModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteTransaction(String id) async {
    await apiClient.delete('/transactions/$id');
  }
}
