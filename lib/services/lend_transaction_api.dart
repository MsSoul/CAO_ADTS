//filname:lib/service/lend_transaction_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

class LendTransactionApi {
  final String baseUrl;
  final Logger logger = Logger();

  LendTransactionApi(this.baseUrl);

  Future<List<Map<String, dynamic>>> fetchBorrowers(String currentDptId,
      String query, String searchType, String empId) async {
    try {
      Map<String, String> queryParams = {
        'current_dpt_id': currentDptId,
        'search_type': searchType,
        'emp_id': empId,
      };

      if (query.isNotEmpty) {
        queryParams['query'] = query;
      }

      final uri = Uri.parse('$baseUrl/api/lendTransaction/borrowers')
          .replace(queryParameters: queryParams);

      logger.i("🔍 Fetching from URL: $uri");

      final response = await http.get(uri);

      logger.i("📥 API Response: ${response.body}");

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        logger.i("👀 Borrower API Response: ${json.encode(decodedResponse)}");

        if (decodedResponse is List) {
          return List<Map<String, dynamic>>.from(decodedResponse);
        }
      }

      logger
          .e("🚨 Backend Response: ${response.statusCode} - ${response.body}");
      return []; // Return an empty list instead of throwing an error
    } catch (e) {
      logger.e("⛔ Error fetching borrowers: $e");
      return []; // Return an empty list in case of an error
    }
  }

  // Submit Lending Transaction
  Future<Map<String, dynamic>> submitLendingTransaction({
    required int empId,
    required int itemId,
    required int quantity,
    required int borrowerId,
    required int currentDptId,
  }) async {
    try {
      final requestBody = {
        'emp_id': empId,
        'itemId': itemId,
        'quantity': quantity,
        'borrowerId': borrowerId,
        'currentDptId': currentDptId,
      };

      // 🔍 Log the request before sending it
      logger.i("📤 Sending Lending Transaction Request: $requestBody");

      final response = await http.post(
        Uri.parse('$baseUrl/api/lendTransaction/lend_transaction'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      // 🔍 Log the raw response
      logger.i("📥 Response Status: ${response.statusCode}");
      logger.i("📥 Response Body: ${response.body}");

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        logger.e("❌ Failed to submit transaction: ${response.body}");
        throw Exception('Failed to submit transaction: ${response.body}');
      }
    } catch (e) {
      logger.e("⛔ Error submitting transaction: $e");
      rethrow;
    }
  }
}
