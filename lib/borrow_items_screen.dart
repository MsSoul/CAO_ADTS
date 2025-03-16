import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../services/borrow_transaction_api.dart';
import 'dart:convert';
import 'borrow_transaction.dart';
import '../design/colors.dart';
import 'items_transaction_table.dart';

class BorrowItemsScreen extends StatefulWidget {
  final int currentDptId;
  final int empId;

  const BorrowItemsScreen({
    super.key,
    required this.currentDptId,
    required this.empId,
  });

  @override
  State<BorrowItemsScreen> createState() => _BorrowItemsScreenState();
}

class _BorrowItemsScreenState extends State<BorrowItemsScreen> {
  late BorrowTransactionApi _allItemsApi;
  final TextEditingController _searchController = TextEditingController();
  final Logger log = Logger();

  List<Map<String, dynamic>> allItems = [];
  List<Map<String, dynamic>> filteredItems = [];
  bool isLoading = true;
  bool hasError = false;

  late int empId;
  late int currentDptId;

  @override
  void initState() {
    super.initState();
    currentDptId = widget.currentDptId;
    empId = widget.empId;
    log.i("💡 Current Department ID: $currentDptId");
    _allItemsApi = BorrowTransactionApi();

    _loadAllItems();
  }

  Future<void> _loadAllItems() async {
    try {
      final items = await _allItemsApi.fetchAllItems(currentDptId, empId);

      if (items.isEmpty) {
        log.w("⚠ No borrowable items found for Department ID: $currentDptId");
      } else {
        log.i(
            "🔍 Full API Response (${items.length} items): ${jsonEncode(items)}");
      }

      setState(() {
        allItems = items.map((item) {
          log.i(
              "📦 DistributedItemId: ${item['distributedItemId']}, ItemId: ${item['itemId']}, Name: ${item['name'] ?? 'N/A'}");

          return {
            'distributedItemId': item['distributedItemId'] ?? 0,
            'itemId': item['itemId'] ?? 0,
            ...item
          };
        }).toList();

        filteredItems = List.from(allItems);
        isLoading = false;
        hasError = false;
      });
    } catch (e, stackTrace) {
      log.e("❌ Error fetching borrowable items",
          error: e, stackTrace: stackTrace);
      setState(() {
        isLoading = false;
        hasError = true;
      });
    }
  }

  void _searchItems(String query) {
    setState(() {
      filteredItems = allItems
          .where((item) =>
              item['name'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _onBorrowPressed(Map<String, dynamic> item) async {
    String borrowerName = await _allItemsApi.fetchUserName(empId);
    int distributedItemId = item['distributedItemId'];
    int itemId = item['itemId'];

    log.i(
        "🛠 Opening BorrowTransaction: DistributedItemId=$distributedItemId, ItemId=$itemId");

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => BorrowTransaction(
          empId: empId,
          currentDptId: currentDptId,
          distributedItemId: distributedItemId,
          itemId: itemId,
          itemName: item['name'],
          description: item['description'],
          availableQuantity: item['quantity'],
          ownerId: item['accountable_emp'],
          owner: item['accountable_name'] ?? 'Unknown',
          borrower: borrowerName,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text(
          'Select Items to Borrow',
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
                      // Search Box
                      SizedBox(
                        height: 45,
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search Items to Borrow',
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
                      // Items Table
                      Expanded(
                        child: ItemsTransactionTable(
                          items: filteredItems,
                          selectedFilter: "Borrowed",
                          actionLabel: "Borrow",
                          onActionPressed: _onBorrowPressed,
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
