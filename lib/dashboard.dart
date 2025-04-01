import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../design/colors.dart';
import '../services/items_api.dart';
import 'dashboard_table.dart';

final Logger log = Logger();

class DashboardScreen extends StatefulWidget {
  final int empId;
  final int currentDptId;

  const DashboardScreen(
      {super.key, required this.empId, required this.currentDptId});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _borrowedItems = [];
  List<Map<String, dynamic>> _filteredItems = [];
  bool _isLoading = true;
  String _errorMessage = "";
  final ItemsApi _itemsApi = ItemsApi();
  int _currentPage = 0;
  int _totalBorrowedCount = 0;
  final int _itemsPerPage = 10;
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = "All";

  @override
  void initState() {
    super.initState();
    _loadItems();
    _searchController.addListener(_filterItems);
  }

  void _filterItems() {
    setState(() {
      _applyFilter();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    log.i("Fetching items for emp_id: ${widget.empId}");
    try {
      final items = await _itemsApi.fetchItems(widget.empId);

      final borrowedResponse = await _itemsApi.fetchBorrowedItems(widget.empId);
      final borrowedItems =
          borrowedResponse['borrowedItems'] as List<Map<String, dynamic>>;
      final totalBorrowedCount =
          borrowedResponse['totalCount'] ?? borrowedItems.length;

      log.i("📦 Items Response: $items");
      log.i("📦 Borrowed Items Count: $totalBorrowedCount");
      log.i("📦 Borrowed Items: $borrowedItems");

      if (mounted) {
        setState(() {
          _items = items;
          _borrowedItems = borrowedItems;
          _totalBorrowedCount = totalBorrowedCount;
          _applyFilter(); // Re-apply any filters after loading data
          _isLoading = false;
        });
      }
    } catch (e, stacktrace) {
      log.e("❌ Error loading items: $e", error: e, stackTrace: stacktrace);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Error fetching items. Please check your connection.";
        });
      }
    }
  }

  void _applyFilter() {
    log.i("Applying filter: $_selectedFilter");
    log.i("Search Query: ${_searchController.text}");
    log.i(
        "Total Items Before Filter: ${_items.length + _borrowedItems.length}");

    String searchQuery = _searchController.text.toLowerCase();
    List<Map<String, dynamic>> filtered = [];

    if (_selectedFilter == "All") {
      filtered = [..._items, ..._borrowedItems];
    } else if (_selectedFilter == "Owned") {
      filtered = _items;
    } else if (_selectedFilter == "Borrowed") {
      filtered = _borrowedItems;
    }

    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((item) {
        String itemName = item['ITEM_NAME']?.toString().toLowerCase() ?? '';
        String itemCode = item['code']?.toString().toLowerCase() ?? '';
        return itemName.contains(searchQuery) || itemCode.contains(searchQuery);
      }).toList();
    }

    log.i("Filtered Items Count: ${filtered.length}");

    setState(() {
      _filteredItems = filtered;
      _currentPage = 0;
    });
  }

  List<Map<String, dynamic>> get _paginatedItems {
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    return _filteredItems.sublist(
        startIndex, endIndex.clamp(0, _filteredItems.length));
  }

  void _nextPage() {
    if ((_currentPage + 1) * _itemsPerPage < _filteredItems.length) {
      setState(() => _currentPage++);
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      setState(() => _currentPage--);
    }
  }

  @override
  Widget build(BuildContext context) {
    int totalPages = (_filteredItems.length / _itemsPerPage).ceil();

    return Scaffold(
      
      appBar: AppBar(
        
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          
          children: [
            const SizedBox(height: 5),
            const Text(
              'Dashboard',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: AppColors.primaryColor),
            ),
            const SizedBox(height: 5),
            SizedBox(
              height: 50,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search Items',
                  prefixIcon: const Icon(Icons.search,
                      size: 18, color: AppColors.primaryColor),
                  contentPadding:
                      const EdgeInsets.symmetric( vertical: 5, horizontal: 8),
                  filled: true,
                  fillColor: Colors.white,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                        color: AppColors.primaryColor, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                        color: AppColors.primaryColor, width: 2),
                  ),
                ),
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        toolbarHeight: 100,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadItems();
        },
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage.isNotEmpty
                ? Center(
                    child: Text(
                      '⚠ $_errorMessage',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor),
                    ),
                  )
                : Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: DropdownButtonHideUnderline(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: AppColors.primaryColor, width: 1),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                child: DropdownButton<String>(
                                  value: _selectedFilter,
                                  items: [
                                    "All (${_items.length + _borrowedItems.length})",
                                    "Owned (${_items.length})",
                                    "Borrowed ($_totalBorrowedCount)"
                                  ].map((filterWithCount) {
                                    // Extract filter keyword (All, Owned, Borrowed) from the string
                                    String filterKeyword =
                                        filterWithCount.split(' ').first;
                                    return DropdownMenuItem(
                                      value: filterKeyword,
                                      child: Text(filterWithCount,
                                          style: const TextStyle(
                                              color: Colors.black)),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedFilter = value!;
                                      _applyFilter();
                                    });
                                  },
                                  dropdownColor: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                  icon: const Icon(Icons.arrow_back),
                                  onPressed:
                                      _currentPage > 0 ? _previousPage : null),
                              Text("Page ${_currentPage + 1} of $totalPages"),
                              IconButton(
                                icon: const Icon(Icons.arrow_forward),
                                onPressed: (_currentPage + 1) * _itemsPerPage <
                                        _filteredItems.length
                                    ? _nextPage
                                    : null,
                              ),
                            ],
                          ),
                        ],
                      ),
                      Expanded(
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: DashboardTable(
                                  items: _paginatedItems,
                                  selectedFilter: _selectedFilter),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
