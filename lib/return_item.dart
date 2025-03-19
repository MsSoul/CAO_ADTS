import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../services/items_api.dart';
import 'dart:convert';
import '../design/colors.dart';
import 'items_transaction_table.dart';
import 'return_transaction.dart';
import '../services/borrow_transaction_api.dart';

class ReturnItemsScreen extends StatefulWidget {
  final int empId;
  final int currentDptId;

  const ReturnItemsScreen(
      {super.key, required this.empId, required this.currentDptId});

  @override
  State<ReturnItemsScreen> createState() => _ReturnItemsScreenState();
}

class _ReturnItemsScreenState extends State<ReturnItemsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Logger log = Logger();

  List<Map<String, dynamic>> borrowedItems = [];
  List<Map<String, dynamic>> filteredItems = [];
  bool isLoading = true;
  bool hasError = false;
  late BorrowTransactionApi borrowTransactionApi;
  late int empId;

  @override
  void initState() {
    super.initState();
    empId = widget.empId;
    borrowTransactionApi = BorrowTransactionApi();
    log.i("💡 Employee ID: $empId");
    _loadBorrowedItems();
  }

  Future<void> _loadBorrowedItems() async {
    try {
      final response = await ItemsApi().fetchBorrowedItems(empId);
      final items = response['borrowedItems'] as List<Map<String, dynamic>>;
      final totalCount = response['totalCount'] ?? items.length;

      log.i("🔍 Raw API Response: ${jsonEncode(response)}");
      log.i("📊 Total Borrowed Items Count: $totalCount");

      setState(() {
        borrowedItems = items.map((item) {
          int distributedItemId =
              item['distributed_item_id'] ?? item['DISTRIBUTED_ITEM_ID'] ?? 0;
          int itemId = item['item_id'] ?? item['ITEM_ID'] ?? 0;
          bool hasReturnRequest = (item['pending_return_request'] == true) ||
              (item['return_request_status']?.toString().toLowerCase() ==
                  'pending') ||
              (item['hasReturnRequest'] == true);

          return {
            'distributed_item_id': distributedItemId,
            'ITEM_ID': itemId,
            'hasReturnRequest': hasReturnRequest,
            ...item,
          };
        }).toList();

        filteredItems = List.from(borrowedItems);
        isLoading = false;
        hasError = false;
      });

      log.i("✅ Borrowed items successfully loaded.");
    } catch (e, stackTrace) {
      log.e("❌ Error fetching borrowed items",
          error: e, stackTrace: stackTrace);
      setState(() {
        isLoading = false;
        hasError = true;
      });
    }
  }

  void _searchItems(String query) {
    setState(() {
      filteredItems = borrowedItems
          .where((item) =>
              item['ITEM_NAME'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  Future<void> _onReturnPressed(Map<String, dynamic> item) async {
    if (item['hasReturnRequest'] == true) return;

    String? fetchedName = await borrowTransactionApi.fetchUserName(empId);
    log.i("🔍 Borrower Name Fetched: $fetchedName");

    String borrowerName = fetchedName;
    int distributedItemId = item['distributed_item_id'] ?? 0;
    int itemId = item['ITEM_ID'] ?? 0;
    String itemName = item['ITEM_NAME'] ?? "Unnamed Item";
    String description = item['DESCRIPTION'] ?? "No description available";
    int borrowedQuantity = (item['quantity'] as int?) ?? 0;
    String ownerName = item['remarks']?.contains("Owned By:")
        ? item['remarks'].split("\n")[0].replaceFirst("Owned By: ", "")
        : "Unknown Owner";
    int ownerId = (item['owner_emp_id'] as int?) ?? 0;

    log.i(
        "🛠 Opening ReturnTransaction: ITEM_ID=$itemId, DistributedItemId=$distributedItemId");

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => ReturnTransaction(
          empId: empId,
          currentDptId: widget.currentDptId,
          distributedItemId: distributedItemId,
          itemId: itemId,
          itemName: itemName,
          description: description,
          ownerId: ownerId,
          owner: ownerName,
          borrower: borrowerName,
          borrowedQuantity: borrowedQuantity,
          quantity: borrowedQuantity,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Select Items to Return',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: AppColors.primaryColor,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : hasError
              ? const Center(
                  child: Text(
                    '⚠ Failed to load items. Please try again later.',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 45,
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search Items to Return',
                            hintStyle: const TextStyle(
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                            prefixIcon: const Icon(Icons.search,
                                color: AppColors.primaryColor),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 12),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: AppColors.primaryColor, width: 2),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: AppColors.primaryColor, width: 3),
                            ),
                          ),
                          onChanged: _searchItems,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: ItemsTransactionTable(
                          items: filteredItems,
                          selectedFilter: "Returned",
                          actionLabel: "Return",
                          onActionPressed: _onReturnPressed,
                          isActionDisabled: (item) =>
                              item["hasReturnRequest"] == true,
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
