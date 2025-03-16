import 'package:flutter/material.dart';
import '../design/colors.dart';
import 'package:intl/intl.dart';

class ItemsTransactionTable extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final String selectedFilter;
  final void Function(Map<String, dynamic>) onActionPressed;
  final String actionLabel;

  const ItemsTransactionTable({
    super.key,
    required this.items,
    required this.selectedFilter,
    required this.onActionPressed,
    required this.actionLabel,
  });

  @override
  State<ItemsTransactionTable> createState() => _ItemsTransactionTableState();
}

class _ItemsTransactionTableState extends State<ItemsTransactionTable> {
  int currentPage = 0;
  static const int rowsPerPage = 10;

  int get totalPages => (widget.items.length / rowsPerPage).ceil();

  void _changePage(int newPage) {
    setState(() {
      currentPage = newPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    int startIndex = currentPage * rowsPerPage;
    int endIndex = (startIndex + rowsPerPage) > widget.items.length
        ? widget.items.length
        : (startIndex + rowsPerPage);

    List<Map<String, dynamic>> paginatedItems =
        widget.items.sublist(startIndex, endIndex);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.primaryColor),
                  onPressed: currentPage > 0 ? () => _changePage(currentPage - 1) : null,
                ),
                Text("Page ${currentPage + 1} of $totalPages"),
                IconButton(
                  icon: const Icon(Icons.arrow_forward, color: AppColors.primaryColor),
                  onPressed: currentPage < totalPages - 1 ? () => _changePage(currentPage + 1) : null,
                ),
              ],
            ),
            const SizedBox(height: 5),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: DataTable(
                    border: TableBorder.all(color: AppColors.primaryColor, width: 1.5),
                    dataRowMinHeight: 40,
                    dataRowMaxHeight: 40,
                    headingRowColor:
                        WidgetStateColor.resolveWith((states) => AppColors.primaryColor),
                    columns: const [
                      DataColumn(label: Center(child: Text('Action', style: _headerStyle))),
                      DataColumn(label: Center(child: Text('Name', style: _headerStyle))),
                      DataColumn(label: Center(child: Text('Description', style: _headerStyle))),
                      DataColumn(label: Center(child: Text('Available Quantity', style: _headerStyle))),
                      DataColumn(label: Center(child: Text('Original Quantity', style: _headerStyle))),
                      DataColumn(label: Center(child: Text('PAR No', style: _headerStyle))),
                      DataColumn(label: Center(child: Text('PIS No.', style: _headerStyle))),
                      DataColumn(label: Center(child: Text('Prop No.', style: _headerStyle))),
                      DataColumn(label: Center(child: Text('Serial No.', style: _headerStyle))),
                      DataColumn(label: Center(child: Text('MR No.', style: _headerStyle))),
                      DataColumn(label: Center(child: Text('Unit Value', style: _headerStyle))),
                      DataColumn(label: Center(child: Text('Total Value', style: _headerStyle))),
                      DataColumn(label: Center(child: Text('Remarks', style: _headerStyle))),
                    ],
                    rows: paginatedItems.map((item) {
                      String remarks = item['remarks']?.toString() ?? '';

                      if (widget.selectedFilter == "Borrowed" && item['owner_name'] != null) {
                        String owner = item['owner_name'].toString();
                        String borrowedDate = "N/A";

                        if (item['createdAt'] != null) {
                          try {
                            DateTime parsedDate = DateTime.parse(item['createdAt']);
                            borrowedDate = DateFormat("yyyy-MM-dd").format(parsedDate);
                          } catch (e) {
                            borrowedDate = "Invalid Date";
                          }
                        }

                        remarks = "Owned By: $owner \nBorrowed Date: $borrowedDate";
                      }

                      final currencyFormat = NumberFormat("#,##0.00", "en_US");

                      return DataRow(cells: [
                        DataCell(
                          SizedBox(
                            height: 35,
                            child: ElevatedButton(
                              onPressed: () => widget.onActionPressed(item),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                              ),
                              child: Text(
                                widget.actionLabel,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        DataCell(Text(item['ITEM_NAME']?.toString() ?? 'N/A')),
                        DataCell(Text(item['DESCRIPTION']?.toString() ?? 'N/A')),
                        DataCell(Text(item['quantity']?.toString() ?? 'N/A')),
                        DataCell(Text(item['ORIGINAL_QUANTITY']?.toString() ?? 'N/A')),
                        DataCell(Text(item['PAR_NO']?.toString() ?? 'N/A')),
                        DataCell(Text(item['PIS_NO']?.toString() ?? 'N/A')),
                        DataCell(Text(item['PROP_NO']?.toString() ?? 'N/A')),
                        DataCell(Text(item['SERIAL_NO']?.toString() ?? 'N/A')),
                        DataCell(Text(item['MR_NO']?.toString() ?? 'N/A')),
                        DataCell(Text(
                            '₱ ${currencyFormat.format(double.tryParse(item['unit_value'].toString()) ?? 0.0)}')),
                        DataCell(Text(
                            '₱ ${currencyFormat.format(double.tryParse(item['total_value'].toString()) ?? 0.0)}')),
                        DataCell(Text(remarks)),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  static const TextStyle _headerStyle = TextStyle(
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
}
