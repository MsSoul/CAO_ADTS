import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';
import 'package:intl/intl.dart';

class ItemsApi {
  final String baseUrl = Config.baseUrl;
  final Logger log = Logger();

  // Retrieve Employee ID from SharedPreferences
  Future<int?> getEmpId() async {
    final prefs = await SharedPreferences.getInstance();
    int? empId = prefs.getInt('emp_id');

    if (empId == null) {
      log.w("⚠ No Employee ID found in SharedPreferences!");
    } else {
      log.i("✅ Found Employee ID: $empId");
    }
    return empId;
  }

  // Fetch items assigned to an employee (OWNED ITEMS)
  Future<List<Map<String, dynamic>>> fetchItems(int empId) async {
  log.i("🔄 Fetching items for empId: $empId");
  final url = Uri.parse('$baseUrl/api/items/$empId');

  try {
    final response = await http.get(url);
    log.i("📩 Status Code: ${response.statusCode}");

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      log.i("🛠 Full Response: $responseData");

      if (responseData is Map<String, dynamic> &&
          responseData.containsKey("owned_items")) {
        final items = List<Map<String, dynamic>>.from(responseData["owned_items"]);

        final mappedItems = items.map((item) {
          return {
            "DISTRIBUTED_ITEM_ID": item["DISTRIBUTED_ITEM_ID"] ?? 0,
            "ITEM_ID": item["ITEM_ID"] ?? 0,
            "OWNER_EMP_ID": item["OWNER_EMP_ID"] ?? 0,
            "quantity": item["quantity"] ?? 0,
            "ORIGINAL_QUANTITY": item["ORIGINAL_QUANTITY"] ?? 0,
            "remarks": item["remarks"] ?? "N/A",
            "PAR_NO": item["PAR_NO"] ?? "N/A",
            "MR_NO": item["MR_NO"] ?? "N/A",
            "PIS_NO": item["PIS_NO"] ?? "N/A",
            "PROP_NO": item["PROP_NO"] ?? "N/A",
            "SERIAL_NO": item["SERIAL_NO"] ?? "N/A",
            "unit_value": double.tryParse(item["unit_value"].toString()) ?? 0.0,
            "total_value": double.tryParse(item["total_value"].toString()) ?? 0.0,
            "ITEM_NAME": item["ITEM_NAME"] ?? "N/A",
            "DESCRIPTION": item["DESCRIPTION"] ?? "N/A",
          };
        }).toList();

        return mappedItems;
      }
      throw Exception('❌ Invalid response structure');
    }
    throw Exception('❌ Failed to load items: ${response.reasonPhrase}');
  } catch (e) {
    log.e("❌ Error fetching items: $e");
    throw Exception('❌ Error fetching items. Please try again.');
  }
}

Future<Map<String, dynamic>> fetchBorrowedItems(int empId) async {
  log.i("🔄 Fetching borrowed items for empId: $empId");
  final url = Uri.parse('$baseUrl/api/items/borrowed/$empId');

  try {
    final response = await http.get(url);
    log.i("📩 Status Code: ${response.statusCode}");

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData is Map<String, dynamic> &&
          responseData.containsKey('borrowed_items')) {
        final borrowedItems =
            List<Map<String, dynamic>>.from(responseData['borrowed_items']);
        final totalTransactions =
            responseData['total_borrowed_transactions'] ??
                borrowedItems.length;

        log.i("✅ Retrieved $totalTransactions borrowed items.");

        final mappedItems = borrowedItems.map((item) {
          String borrowedDate = "N/A";
          if (item["createdAt"] != null) {
            try {
              DateTime parsedDate = DateTime.parse(item["createdAt"]);
              borrowedDate = DateFormat("yyyy-MM-dd").format(parsedDate);
            } catch (e) {
              borrowedDate = "Invalid Date";
            }
          }

          bool hasReturnRequest = (item["status"] == 2 && item["remarks"] == 5);

          String remarksText = "";
          if (item["OWNER_NAME"] != null) {
            remarksText =
                "Owned By: ${item["OWNER_NAME"]}\nBorrowed Date: $borrowedDate";

            if (hasReturnRequest) {
              remarksText += "\n🚨 Return request: Pending approval";
            }
          } else {
            remarksText = "Owned Item";
          }

          return {
            "transaction_id": item["transactionId"] ?? 0,
            "distributed_item_id": item["distributed_item_id"] ?? 0,
            "item_id": item["item_id"] ?? 0,
            "owner_emp_id": item["owner_emp_id"] ?? 0,
            "ITEM_NAME": item["ITEM_NAME"],
            "DESCRIPTION": item["DESCRIPTION"],
            "quantity": item["quantity"] ?? 0,
            "PAR_NO": item["PAR_NO"] ?? "N/A",
            "MR_NO": item["MR_NO"] ?? "N/A",
            "PIS_NO": item["PIS_NO"] ?? "N/A",
            "PROP_NO": item["PROP_NO"] ?? "N/A",
            "SERIAL_NO": item["SERIAL_NO"] ?? "N/A",
            "unit_value": double.tryParse(item["unit_value"].toString()) ?? 0.0,
            "total_value": double.tryParse(item["total_value"].toString()) ?? 0.0,
            "hasReturnRequest": hasReturnRequest,
            "remarks": remarksText,
          };
        }).toList();

        return {
          "borrowedItems": mappedItems,
          "totalCount": totalTransactions,
        };
      }
    }
    throw Exception(
        '❌ Failed to load borrowed items: ${response.reasonPhrase}');
  } catch (e) {
    log.e("❌ Error fetching borrowed items: $e");
    throw Exception('❌ Error fetching borrowed items. Please try again.');
  }
}

  Future<void> debugSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    log.i("🔎 Stored emp_id: ${prefs.getInt('emp_id')}");
  }
}
