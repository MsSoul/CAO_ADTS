import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

class TransferTransactionApi {
  final String baseUrl;
  final Logger logger = Logger();

  TransferTransactionApi(this.baseUrl);

  /// Fetch employees based on department ID and search input (ID Number or Name)
  Future<List<Map<String, dynamic>>> fetchEmployees(String departmentId,
      String query, String searchType, String empId) async {
    final url = Uri.parse(
        '$baseUrl/employees/search?departmentId=$departmentId&query=$query&searchType=$searchType&empId=$empId');

    logger.i("Fetching employees: $url");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        logger.w(
            "Failed to fetch employees. Status Code: ${response.statusCode}");
        return [];
      }
    } catch (e, stackTrace) {
      logger.e("Error fetching employees", error: e, stackTrace: stackTrace);
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchReceivers(String currentDptId,
      String query, String searchType, String empId) async {
    try {
      // Validate required parameters before making the request
      if (currentDptId.isEmpty || empId.isEmpty) {
        logger.e(
            "⚠️ Missing required parameters: currentDptId=$currentDptId, empId=$empId");
        return [];
      }

      // Prepare query parameters
      Map<String, String> queryParams = {
        'current_dpt_id': currentDptId,
        'search_type': searchType,
        'emp_id': empId,
      };

      if (query.isNotEmpty) {
        queryParams['query'] = query;
      }

      // Construct URL with parameters
      final uri = Uri.parse('$baseUrl/api/transferTransaction/receivers')
          .replace(queryParameters: queryParams);

      logger.i("🔍 Fetching receivers from URL: $uri");

      // Send GET request
      final response = await http.get(uri);

      logger.i("📥 API Receiver Response: ${response.body}");

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        logger.i("👀 Receiver API Response: ${json.encode(decodedResponse)}");

        if (decodedResponse is List) {
          return List<Map<String, dynamic>>.from(decodedResponse);
        }
      }

      logger.e(
          "🚨 Backend Receiver Response: ${response.statusCode} - ${response.body}");
      return [];
    } catch (e) {
      logger.e("⛔ Error fetching receivers: $e");
      return [];
    }
  }

  /// Process transfer transaction
  /* Future<bool> transferItem({
    required int senderEmpId,
    required int receiverEmpId,
    required int itemId,
    required int quantity,
  }) async {
    final url = Uri.parse('$baseUrl/transfer');

    final Map<String, dynamic> requestBody = {
      "senderEmpId": senderEmpId,
      "receiverEmpId": receiverEmpId,
      "itemId": itemId,
      "quantity": quantity,
    };

    logger.i("Initiating transfer: $requestBody");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        logger.i("Transfer successful");
        return true;
      } else {
        logger.w("Transfer failed. Status Code: ${response.statusCode}, Response: ${response.body}");
        return false;
      }
    } catch (e, stackTrace) {
      logger.e("Error processing transfer", error: e, stackTrace: stackTrace);
      return false;
    }
  }*/

  /// Submits a transfer transaction
  Future<Map<String, dynamic>> submitTransferTransaction({
    required int empId,
    required int itemId,
    required int quantity,
    required int receiverId,
    required int currentDptId,
    required int distributedItemId,
  }) async {
    final url =
        Uri.parse('$baseUrl/api/transferTransaction/transfer_Transaction');
    final Map<String, dynamic> requestBody = {
      "emp_id": empId, // ✅ Matches Backend
      "receiverId": receiverId, // ✅ Matches Backend
      "itemId": itemId,
      "quantity": quantity,
      "currentDptId": currentDptId,
      "distributedItemId":distributedItemId,
    };

    logger.i("📤 Sending transfer transaction request: $requestBody");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode(requestBody),
      );

      logger.i(
          "📥 API Response: Status Code: ${response.statusCode}, Body: ${response.body}");

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decodedResponse = json.decode(response.body);
        bool isSuccess = decodedResponse['success'] ?? false;
        return {
          "success": isSuccess,
          "message": decodedResponse['message'] ?? "Transfer completed!",
        };
      } else {
        return {
          "success": false,
          "message": "Transfer failed: ${response.body}",
        };
      }
    } catch (e, stackTrace) {
      logger.e("🔥 Error processing transfer transaction",
          error: e, stackTrace: stackTrace);
      return {
        "success": false,
        "message": "Network error: ${e.toString()}",
      };
    }
  }
}
