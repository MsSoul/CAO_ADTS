//filename:lib/services/borrow_transaction_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
//import 'package:ibs/design/borrowing_widgets.dart';
import 'package:logger/logger.dart';
//import 'package:flutter/material.dart';
import 'config.dart';

class BorrowTransactionApi {
  final String baseUrl = Config.baseUrl;
  final Logger logger = Logger();

  BorrowTransactionApi();

  /// Fetch items based on current department ID, excluding a specific employee ID
  Future<List<Map<String, dynamic>>> fetchAllItems(
      int currentDptId, int empId) async {
    final url =
        Uri.parse('$baseUrl/api/borrowTransaction/$currentDptId/$empId');
    logger.i("🔍 Fetching items from: $url ");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        logger.i("🔍 Raw API Response: $data"); // Log the full response

        if (data.containsKey("items")) {
          List<Map<String, dynamic>> items =
              List<Map<String, dynamic>>.from(data["items"]);

          // Log each item before mapping
          for (var item in items) {
            logger.i("🔍 Before Mapping: $item");
          }

          // Ensure correct field names
          List<Map<String, dynamic>> mappedItems = items.map((item) {
            return {
              'distributedItemId': item['id'], // Verify if 'ID' exists
              'itemId': item['ITEM_ID'], // Verify if 'ITEM_ID' exists
              ...item,
            };
          }).toList();

          // Log after mapping
          for (var item in mappedItems) {
            logger.i("📦 After Mapping: $item");
          }

          return mappedItems;
        } else {
          logger.w("⚠ Unexpected response format (No 'items' key): $data");
          return [];
        }
      } else {
        logger.w("⚠ Failed to fetch items. Status: ${response.statusCode}");
        return [];
      }
    } catch (e, stackTrace) {
      logger.e("❌ Error fetching items", error: e, stackTrace: stackTrace);
      return [];
    }
  }

  Future<bool> processBorrowTransaction(
      {required int borrowerId,
      required int ownerId,
      required int itemId,
      required int quantity,
      required int currentDptId,
      required int distributedItemId}) async {
    final url = Uri.parse('$baseUrl/api/borrowTransaction/borrow');
    logger.i("🔄 Processing borrow transaction: $url");

    try {
      final requestBody = json.encode({
        'borrower_emp_id': borrowerId,
        'owner_emp_id': ownerId,
        'itemId': itemId,
        'quantity': quantity,
        'DPT_ID': currentDptId,
        'distributed_item_id': distributedItemId,
      });

      logger.i("Request Body: $requestBody");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: requestBody,
      );

      return response.statusCode == 201;
    } catch (e, stackTrace) {
      logger.e("❌ Error processing borrow transaction",
          error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Fetch employee name based on employee ID
  Future<String> fetchUserName(int empId) async {
    final url = Uri.parse('$baseUrl/api/borrowTransaction/$empId');
    logger.i("🔍 Fetching user name: $url");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data.containsKey("userName")) {
          String userName = data["userName"];

          // Capitalize the first letter of each word
          String formattedName = userName.split(' ').map((word) {
            return word.isNotEmpty
                ? word[0].toUpperCase() + word.substring(1).toLowerCase()
                : '';
          }).join(' ');

          logger.i("👤 User Name: $formattedName");
          return formattedName;
        } else {
          logger.w("⚠ User data does not contain 'userName' key: $data");
          return "Unknown";
        }
      } else {
        logger.w("⚠ Failed to fetch user name. Status: ${response.statusCode}");
        return "Unknown";
      }
    } catch (e, stackTrace) {
      logger.e("❌ Error fetching user name", error: e, stackTrace: stackTrace);
      return "Unknown";
    }
  }
}
