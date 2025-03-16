import 'package:flutter/material.dart';
import '../design/colors.dart';
import 'package:intl/intl.dart';

class DashboardTable extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final String selectedFilter; // Added parameter

  const DashboardTable({
    super.key,
    required this.items,
    required this.selectedFilter, // Required in constructor
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        border: TableBorder.all(color: AppColors.primaryColor, width: 1.5),
        dataRowMinHeight: 40,
        dataRowMaxHeight: 40,
        headingRowColor:
            WidgetStateColor.resolveWith((states) => AppColors.primaryColor),
        columns: const [
          DataColumn(label: Center(child: Text('Name', style: _headerStyle))),
          DataColumn(
              label: Center(child: Text('Description', style: _headerStyle))),
          DataColumn(
              label: Center(
                  child: Text('Available Quantity', style: _headerStyle))),
          DataColumn(
              label: Center(
                  child: Text('Original Quantity', style: _headerStyle))),
          DataColumn(label: Center(child: Text('PAR No', style: _headerStyle))),
          DataColumn(
              label: Center(child: Text('PIS No.', style: _headerStyle))),
          DataColumn(
              label: Center(child: Text('Prop No.', style: _headerStyle))),
          DataColumn(
              label: Center(child: Text('Serial No.', style: _headerStyle))),
          DataColumn(label: Center(child: Text('MR No.', style: _headerStyle))),
          DataColumn(
              label: Center(child: Text('Unit Value', style: _headerStyle))),
          DataColumn(
              label: Center(child: Text('Total Value', style: _headerStyle))),
          DataColumn(
              label: Center(
                  child:
                      Text('Remarks', style: _headerStyle))), // Remarks updated
        ],
                rows: items.map((item) {
          String remarks = item['remarks']?.toString() ?? '';

          if (selectedFilter == "Borrowed" && item['owner_name'] != null) {
            String owner = item['owner_name'].toString();
            String borrowedDate = "N/A";

            if (item['createdAt'] != null) {
              try {
                DateTime parsedDate = DateTime.parse(item['createdAt']);
                borrowedDate = DateFormat("yyyy-MM-dd").format(parsedDate);
              } catch (e) {
                borrowedDate = "Invalid Date"; // Handle parsing errors
              }
            }

            remarks = "Owned By: $owner \nBorrowed Date: $borrowedDate";
          }

          final currencyFormat = NumberFormat("#,##0.00", "en_US");

          return DataRow(cells: [
            DataCell(Text(item['name']?.toString() ?? 'N/A')),
            DataCell(Text(item['description']?.toString() ?? 'N/A')),
            DataCell(Text(item['quantity']?.toString() ?? 'N/A')),
            DataCell(Text(item['ORIGINAL_QUANTITY']?.toString() ?? 'N/A')),
            DataCell(Text(item['PAR_NO']?.toString() ?? 'N/A')),
            DataCell(Text(item['PIS_NO']?.toString() ?? 'N/A')),
            DataCell(Text(item['PROP_NO']?.toString() ?? 'N/A')),
            DataCell(Text(item['SERIAL_NO']?.toString() ?? 'N/A')),
            DataCell(Text(item['MR_NO']?.toString() ?? 'N/A')),
            DataCell(
                Text('₱ ${currencyFormat.format(item['unit_value'] ?? 0.0)}')),
            DataCell(
                Text('₱ ${currencyFormat.format(item['total_value'] ?? 0.0)}')),
            DataCell(
                Text(remarks)), // Updated to display only owner name and formatted date
          ]);
        }).toList(),

      ),
    );
  }

  // Define a TextStyle for column headers
  static const TextStyle _headerStyle = TextStyle(
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
}
