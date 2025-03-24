import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../services/items_api.dart';
import '../design/colors.dart';
import 'items_transaction_table.dart'; // Import the new table
import 'lend_transaction.dart';

class LendingItemsScreen extends StatefulWidget {
  final int currentDptId;
  final int empId;
  
  const LendingItemsScreen({super.key, required this.currentDptId, required this.empId});

  @override
  State<LendingItemsScreen> createState() => _LendingItemsScreenState();
}

class _LendingItemsScreenState extends State<LendingItemsScreen> {
  final ItemsApi _itemsApi = ItemsApi();
  final TextEditingController _searchController = TextEditingController();
  final Logger log = Logger();

  List<Map<String, dynamic>> allItems = [];
  List<Map<String, dynamic>> filteredItems = [];
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    try {
      int? fetchedEmpId = await _itemsApi.getEmpId();
      if (fetchedEmpId != null && fetchedEmpId > 0) {
        final items = await _itemsApi.fetchItems(fetchedEmpId);

        setState(() {
          allItems = items.map((item) {
            return {
              ...item,
              'distributedItemId': item['distributedItemId'] ?? 0,
              'ITEM_ID': item['ITEM_ID'],
              'quantity': item['quantity'] as int? ?? 0,
            };
          }).toList();

          filteredItems = List.from(allItems);
          isLoading = false;
        });
      } else {
        log.w("⚠️ Invalid Employee ID, unable to fetch items.");
        setState(() {
          isLoading = false;
          hasError = true;
        });
      }
    } catch (e, stackTrace) {
      log.e("❌ Error fetching items: $e", error: e, stackTrace: stackTrace);
      setState(() {
        isLoading = false;
        hasError = true;
      });
    }
  }

  void _searchItems(String query) {
    setState(() {
      filteredItems = allItems
          .where((item) => item['name'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _openLendingTransaction(Map<String, dynamic> item) {
    int itemId = item['ITEM_ID'];

    log.i("🛠 Opening LendingTransaction: itemId=$itemId");

    showDialog(
      context: context,
      builder: (context) => LendingTransaction(
        empId: widget.empId,
        itemId: itemId,
        distributedItemId: item['distributedItemId'],
        itemName: item['ITEM_NAME'],
        description: item['DESCRIPTION'],
        currentDptId: widget.currentDptId,
        initialTransactions: [], // Adjust if necessary
        availableQuantity: item['quantity'],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Select Items to Lend',
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
                    'Failed to load items. Please try again later.',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search Bar
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: SizedBox(
                          height: 40,
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              labelText: 'Search Items to lend',
                              labelStyle: const TextStyle(
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              prefixIcon: _searchController.text.isEmpty
                                  ? const Icon(Icons.search, color: AppColors.primaryColor)
                                  : null,
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, color: AppColors.primaryColor),
                                      onPressed: () {
                                        setState(() {
                                          _searchController.clear();
                                          _searchItems('');
                                        });
                                      },
                                    )
                                  : null,
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                    color: AppColors.primaryColor, width: 2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                    color: AppColors.primaryColor, width: 2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 6, horizontal: 10),
                            ),
                            onChanged: (value) => _searchItems(value),
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),

                      // Items Transaction Table
                      Expanded(
                        child: ItemsTransactionTable(
                          items: filteredItems,
                          selectedFilter: "Available",
                          onActionPressed: _openLendingTransaction,
                          actionLabel: "Lend",
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
