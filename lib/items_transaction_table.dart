import 'package:flutter/material.dart';
import '../design/colors.dart';
import 'package:intl/intl.dart';

class ItemsTransactionTable extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final String selectedFilter;
  final void Function(Map<String, dynamic>) onActionPressed;
  final String actionLabel;
  final bool Function(Map<String, dynamic>)? isActionDisabled;

  const ItemsTransactionTable({
    super.key,
    required this.items,
    required this.selectedFilter,
    required this.onActionPressed,
    required this.actionLabel,
    this.isActionDisabled,
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
    final currencyFormat = NumberFormat("#,##0.00", "en_US");

    // ✅ Sort the entire items list before pagination
    List<Map<String, dynamic>> sortedItems = [...widget.items];
    sortedItems.sort((a, b) {
      final qtyA = int.tryParse(a['quantity']?.toString() ?? '0') ?? 0;
      final qtyB = int.tryParse(b['quantity']?.toString() ?? '0') ?? 0;
      return qtyB.compareTo(qtyA); // descending
    });

    int startIndex = currentPage * rowsPerPage;
    int endIndex = (startIndex + rowsPerPage) > sortedItems.length
        ? sortedItems.length
        : (startIndex + rowsPerPage);

    List<Map<String, dynamic>> paginatedItems =
        sortedItems.sublist(startIndex, endIndex);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back,
                      color: AppColors.primaryColor),
                  onPressed: currentPage > 0
                      ? () => _changePage(currentPage - 1)
                      : null,
                ),
                Text("Page ${currentPage + 1} of $totalPages"),
                IconButton(
                  icon: const Icon(Icons.arrow_forward,
                      color: AppColors.primaryColor),
                  onPressed: currentPage < totalPages - 1
                      ? () => _changePage(currentPage + 1)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 5),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: DataTable(
                    border: TableBorder.all(
                        color: AppColors.primaryColor, width: 1.5),
                    dataRowMinHeight: 40,
                    dataRowMaxHeight: 40,
                    headingRowColor: WidgetStateColor.resolveWith(
                        (states) => AppColors.primaryColor),
                    columns: [
                      const DataColumn(
                          label: Center(
                              child: Text('Action', style: _headerStyle))),
                      if (widget.selectedFilter == "Borrowed")
                        const DataColumn(
                            label: Center(
                                child:
                                    Text('Owner Name', style: _headerStyle))),
                      const DataColumn(
                          label:
                              Center(child: Text('Name', style: _headerStyle))),
                      const DataColumn(
                          label: Center(
                              child: Text('Description', style: _headerStyle))),
                      const DataColumn(
                          label: Center(
                              child:
                                  Text('Available Qty', style: _headerStyle))),
                      const DataColumn(
                          label: Center(
                              child:
                                  Text('Original Qty', style: _headerStyle))),
                      const DataColumn(
                          label: Center(
                              child: Text('PAR No', style: _headerStyle))),
                      const DataColumn(
                          label: Center(
                              child: Text('PIS No.', style: _headerStyle))),
                      const DataColumn(
                          label: Center(
                              child: Text('Prop No.', style: _headerStyle))),
                      const DataColumn(
                          label: Center(
                              child: Text('Serial No.', style: _headerStyle))),
                      const DataColumn(
                          label: Center(
                              child: Text('MR No.', style: _headerStyle))),
                      const DataColumn(
                          label: Center(
                              child: Text('Unit Value', style: _headerStyle))),
                      const DataColumn(
                          label: Center(
                              child: Text('Total Value', style: _headerStyle))),
                      const DataColumn(
                          label: Center(
                              child: Text('Remarks', style: _headerStyle))),
                    ],
                    rows: paginatedItems.map((item) {
                      final remarks = item['remarks']?.toString() ?? '';
                      final isDisabled = widget.isActionDisabled != null &&
                          widget.isActionDisabled!(item);

                      final ownerName = item['owner_name'] ??
                          item['accountable_name'] ??
                          "EMP ID: ${item['OWNER_EMP_ID'] ?? 'N/A'}";

                      return DataRow(cells: [
                        DataCell(
                          SizedBox(
                            width: 100,
                            height: 35,
                            child: ElevatedButton(
                              onPressed: isDisabled
                                  ? null
                                  : () => widget.onActionPressed(item),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDisabled
                                    ? Colors.grey
                                    : AppColors.primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  isDisabled ? "Requested" : widget.actionLabel,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (widget.selectedFilter == "Borrowed")
                          DataCell(Text(ownerName)),
                        DataCell(Text(item['ITEM_NAME']?.toString() ?? 'N/A')),
                        DataCell(
                            Text(item['DESCRIPTION']?.toString() ?? 'N/A')),
                        DataCell(Text(item['quantity']?.toString() ?? 'N/A')),
                        DataCell(Text(
                            item['ORIGINAL_QUANTITY']?.toString() ?? 'N/A')),
                        DataCell(Text(item['PAR_NO']?.toString() ?? 'N/A')),
                        DataCell(Text(item['PIS_NO']?.toString() ?? 'N/A')),
                        DataCell(Text(item['PROP_NO']?.toString() ?? 'N/A')),
                        DataCell(Text(item['SERIAL_NO']?.toString() ?? 'N/A')),
                        DataCell(Text(item['MR_NO']?.toString() ?? 'N/A')),
                        DataCell(Text(
                            '₱ ${currencyFormat.format(double.tryParse(item['unit_value'].toString()) ?? 0.0)}')),
                        DataCell(Text(
                            '₱ ${currencyFormat.format(double.tryParse(item['total_value'].toString()) ?? 0.0)}')),
                        DataCell(
                          Container(
                            width: 250,
                            height: 40,
                            padding: const EdgeInsets.all(4),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: Text(remarks),
                            ),
                          ),
                        )
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
