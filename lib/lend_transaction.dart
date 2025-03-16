//filename; lib/lending_transaction.dart
import 'package:flutter/material.dart';
import 'design/colors.dart';
import 'services/lend_transaction_api.dart';
import '../services/config.dart';
import 'package:logger/logger.dart';
import 'design/lending_widgets.dart'; 

class LendingTransaction extends StatefulWidget {
  final int empId;
  final int itemId;
  final String itemName;
  final String description;
  final int currentDptId;
  final List<Map<String, dynamic>> initialTransactions;
  final int availableQuantity;


  const LendingTransaction({
    super.key,
    required this.empId,
    required this.itemId,
    required this.itemName,
    required this.description,
    required this.currentDptId,
    required this.initialTransactions,
    required this.availableQuantity,
  });

  @override
  LendingTransactionState createState() => LendingTransactionState();
}

class LendingTransactionState extends State<LendingTransaction> {
  final TextEditingController qtyController = TextEditingController();
  final TextEditingController borrowerController = TextEditingController();
  final LendTransactionApi borrowApi = LendTransactionApi(Config.baseUrl);
  final Logger logger = Logger();

  String searchType = "ID Number";
  bool isLoading = false;
  bool _borrowerSelected = false;

  bool isConfirmEnabled = false;
  List<Map<String, dynamic>> searchResults = [];
  int? selectedBorrowerId;
  String? quantityError;


 Future<void> fetchBorrowerDetails(String input) async {
  logger.i("Fetching borrower details for Department ID: ${widget.currentDptId}");

  if (widget.currentDptId == -1) {
    logger.w("Invalid Department ID - Using Default ID");
    return;
  }

  setState(() => isLoading = true);

  try {
    final borrowerData = await borrowApi.fetchBorrowers(
      widget.currentDptId.toString(),
      input,  // Send search input (name, ID number, etc.)
      searchType,
      widget.empId.toString()
    );

    setState(() {
      searchResults = borrowerData;
      isLoading = false;
    });

    if (borrowerData.isEmpty) {
      logger.w("No borrowers found.");
    } else {
      logger.i("Fetched ${borrowerData.length} borrower(s)");
    }
  } catch (e, stackTrace) {
    logger.e("Error fetching borrower details:", error: e, stackTrace: stackTrace);
    setState(() => isLoading = false);
  }
}


  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Dialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: constraints.maxWidth * 0.05,
            vertical: constraints.maxHeight * 0.05,
          ),
          backgroundColor: Colors.transparent,
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.9),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildDialogTitle(),
                    buildInfoBox('Item Name:', widget.itemName),
                    buildInfoBox('Description:', widget.description),
                    buildTextField('Quantity:', 'Enter Quantity', controller: qtyController, onChanged: _validateQuantity,errorText: quantityError,),
                    _buildBorrowerField(),
                    buildActionButtons(context, qtyController, borrowerController, widget, selectedBorrowerId: selectedBorrowerId),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

 void _validateQuantity(String value) {
    setState(() {
      if (value.isEmpty) {
        quantityError = "Quantity cannot be empty.";
        isConfirmEnabled = false;
      } else {
        int enteredQuantity = int.tryParse(value) ?? 0;
        if (enteredQuantity <= 0) {
          quantityError = "Quantity must be at least 1.";
          isConfirmEnabled = false;
        } else if (enteredQuantity > widget.availableQuantity) {
          quantityError = "Maximum available quantity is ${widget.availableQuantity}.";
          isConfirmEnabled = false;
        } else {
          quantityError = null; // Clear error if input is valid
          isConfirmEnabled = selectedBorrowerId != null; // Enable only if borrower is selected
        }
      }
    });
  }

Widget _buildBorrowerField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildInfoBox('Borrower:', borrowerController.text),
        if (!_borrowerSelected)
          Row(
            children: [
              _buildDropdown(),
              const SizedBox(width: 10),
              Expanded(child: _buildSearchField()),
            ],
          ),
        if (!_borrowerSelected && isLoading) const CircularProgressIndicator(),
        if (!_borrowerSelected && searchResults.isNotEmpty) _buildSearchResultsList(),
      ],
    );
  }


Widget _buildDropdown() {
  return SizedBox(
    width: 130, 
    height: 40,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), 
        child: DropdownButton<String>(
          value: searchType,
          isExpanded: true,
          onChanged: (String? newValue) {
            setState(() {
              searchType = newValue!;
              borrowerController.clear();
              searchResults = [];
               _borrowerSelected = false;
            });
          },
          items: ['ID Number', 'Name'].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 14)), // Smaller text
            );
          }).toList(),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white, size: 18), // Smaller icon
          dropdownColor: AppColors.primaryColor,
          underline: Container(),
        ),
      ),
    ),
  );
}
Widget _buildSearchField() {
  return TextField(
    controller: borrowerController,
    style: const TextStyle(color: AppColors.primaryColor),
    decoration: InputDecoration(
      labelStyle: const TextStyle(color: AppColors.primaryColor),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.primaryColor),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
      ),
      // Clear button appears when text is entered
      suffixIcon: borrowerController.text.isNotEmpty
          ? IconButton(
              icon: const Icon(Icons.clear, color: Colors.grey),
              onPressed: () {
                setState(() {
                  borrowerController.clear(); // Clear text
                  searchResults = []; // Hide results
                   _borrowerSelected = false;
                });
              },
            )
          : null,
    ),
    onChanged: (value) {
      if (value.isNotEmpty) {
        fetchBorrowerDetails(value);
      } else {
        setState(() => searchResults = []);
      }
    },
  );
}
Widget _buildSearchResultsList() {
  return Padding(
    padding: const EdgeInsets.only(left: 140),
    child: Positioned(
      right: 10,
      top: 50,
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(5),
        color: Colors.white,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 200),
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: searchResults.length > 5 ? 5 : searchResults.length,
            shrinkWrap: true,
            itemBuilder: (context, index) {
              final borrower = searchResults[index];

              int? borrowerId = borrower['borrowerId']; 
              int? idNumber = borrower['ID_NUMBER'] is int ? borrower['ID_NUMBER'] : null;
              String formattedName = _capitalizeName(
                '${borrower['FIRSTNAME'] ?? ''} '
                '${(borrower['MIDDLENAME'] ?? '').isNotEmpty ? borrower['MIDDLENAME'][0] + "." : ''} '
                '${borrower['LASTNAME'] ?? ''}'
              );

              return InkWell(
              onTap: () {
                setState(() {
                  borrowerController.text = formattedName;
                  selectedBorrowerId = borrowerId; 
                  searchResults = [];
                  _borrowerSelected = true;
                });

                logger.i("Selected Borrower: $formattedName (ID: $selectedBorrowerId)");
              },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  child: Row(
                    children: [
                      Text(
                        idNumber?.toString() ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          formattedName,
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    ),
  );
}
String _capitalizeName(String name) {
  return name.split(' ').map((word) {
    if (word.isEmpty) return '';
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  }).join(' ');
}
}
