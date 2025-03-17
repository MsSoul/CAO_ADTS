import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../services/items_api.dart';
import '../design/colors.dart';
import 'transfer_transaction.dart';
import 'items_transaction_table.dart';

class TransferItemsScreen extends StatefulWidget {
  final int currentDptId;
  final int empId;

  const TransferItemsScreen({
    super.key,
    required this.currentDptId,
    required this.empId,
  });

  @override
  State<TransferItemsScreen> createState() => _TransferItemsScreenState();
}

class _TransferItemsScreenState extends State<TransferItemsScreen> {
  final ItemsApi _itemsApi = ItemsApi();
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
    log.i("Current Department ID: $currentDptId");
    _loadItems();
  }

  Future<void> _loadItems() async {
    try {
      int? fetchedEmpId = await _itemsApi.getEmpId();

      if (fetchedEmpId != null && fetchedEmpId > 0) {
        empId = fetchedEmpId;
        final items = await _itemsApi.fetchItems(empId);

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
          .where((item) =>
              item['name'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _onTransferPressed(Map<String, dynamic> item) {
    int itemId = item['ITEM_ID'];

    log.i("🔄 Opening TransferTransaction: itemId=$itemId");

    showDialog(
      context: context,
      builder: (context) => TransferTransactionDialog(
        empId: widget.empId,
        itemId: itemId,
        itemName: item['ITEM_NAME'],
        description: item['DESCRIPTION'],
        currentDptId: widget.currentDptId,
        availableQuantity: item['quantity'],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Select Items to Transfer',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: AppColors.primaryColor,
          ),
        ),
      ),
      body: Padding(
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
                    labelText: 'Search Items to Transfer',
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
                            icon: const Icon(Icons.clear,
                                color: AppColors.primaryColor),
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
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                  ),
                  onChanged: (value) => _searchItems(value),
                ),
              ),
            ),
            const SizedBox(height: 5),
            Expanded(
              child: ItemsTransactionTable(
                items: filteredItems,
                selectedFilter: "Transfer",
                onActionPressed: _onTransferPressed,
                actionLabel: "Transfer",
              ),
            ),
          ],
        ),
      ),
    );
  }
}
