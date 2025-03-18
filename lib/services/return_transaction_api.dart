import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'config.dart';

class ReturnTransactionApi {
  final String baseUrl = Config.baseUrl;
  final Logger logger = Logger();
Future<bool> processReturnTransaction({
  required int borrowerId,
  required int ownerId,
  required int itemId,
  required int quantity,
  required int currentDptId,
  required int distributedItemId,
}) async {
  final url = Uri.parse("$baseUrl/api/returnTransaction/return");
  final body = jsonEncode({
    "borrower_emp_id": borrowerId,
    "owner_emp_id": ownerId,
    "item_id": itemId,
    "quantity": quantity,
    "current_dpt_id": currentDptId,
    "distributed_item_id": distributedItemId,
  });

  try {
    logger.i("📤 Sending return request: $body");
    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
      },
      body: body,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final transactionId = data['transactionId'];
      logger.i("✅ Return transaction successful. Transaction ID: $transactionId");
      return true;
    } else {
      logger.e("❌ Failed to return item. Response: ${response.body}");
      return false;
    }
  } catch (e) {
    logger.e("❌ Exception while processing return transaction: $e");
    return false;
  }
}

}
