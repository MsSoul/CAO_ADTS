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
        if (responseData is Map<String, dynamic> && responseData.containsKey("items")) {
          final items = List<Map<String, dynamic>>.from(responseData["items"]);
          log.i("✅ Retrieved ${items.length} items.");
          return items;
        }
      }
      throw Exception('❌ Failed to load items: ${response.reasonPhrase}');
    } catch (e) {
      log.e("❌ Error fetching items: $e");
      throw Exception('❌ Error fetching items. Please try again.');
    }
  }

Future<List<Map<String, dynamic>>> fetchBorrowedItems(int empId) async {
  log.i("🔄 Fetching borrowed items for empId: $empId");
  final url = Uri.parse('$baseUrl/api/items/borrowed/$empId');

  try {
    final response = await http.get(url);
    log.i("📩 Status Code: ${response.statusCode}");
    
    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData is Map<String, dynamic> && responseData.containsKey('borrowed_items')) {
        final borrowedItems = List<Map<String, dynamic>>.from(responseData['borrowed_items']);
        log.i("✅ Retrieved ${borrowedItems.length} borrowed items.");
        
        return borrowedItems.map((item) {
          String borrowedDate = "N/A";
          if (item["createdAt"] != null) {
            try {
              DateTime parsedDate = DateTime.parse(item["createdAt"]);
              borrowedDate = DateFormat("yyyy-MM-dd").format(parsedDate); // Format to YYYY-MM-DD
            } catch (e) {
              borrowedDate = "Invalid Date"; // Handle potential parsing errors
            }
          }

          return {
            "name": item["ITEM_NAME"],
            "description": item["DESCRIPTION"],
            "quantity": item["quantity"] ?? 0,
            "PAR_NO": item["PAR_NO"] ?? "N/A",
            "MR_NO": item["MR_NO"] ?? "N/A",
            "PIS_NO": item["PIS_NO"] ?? "N/A",
            "PROP_NO": item["PROP_NO"] ?? "N/A",
            "SERIAL_NO": item["SERIAL_NO"] ?? "N/A",
            "unit_value": double.tryParse(item["unit_value"].toString()) ?? 0.0, // Ensure it's a double
            "total_value": double.tryParse(item["total_value"].toString()) ?? 0.0, // Ensure it's a double
            "remarks": item["OWNER_NAME"] != null 
              ? "Owned By: ${item["OWNER_NAME"]} \nBorrowed Date: $borrowedDate"
              : "Owned Item",
          };
        }).toList();
      }
    }
    throw Exception('❌ Failed to load borrowed items: ${response.reasonPhrase}');
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
