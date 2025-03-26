import 'package:flutter/material.dart';
import '../design/colors.dart';
import 'services/return_transaction_api.dart';
import 'package:logger/logger.dart';
import 'design/return_widgets.dart';

class ReturnTransaction extends StatefulWidget {
  final int empId;
  final int itemId;
  final String itemName;
  final String description;
  final int quantity;
  final String owner;
  final int ownerId;
  final int currentDptId;
  final String borrower;
  final int distributedItemId;
  final int borrowedQuantity;

  const ReturnTransaction({
    super.key,
    required this.empId,
    required this.currentDptId,
    required this.itemId,
    required this.itemName,
    required this.description,
    required this.quantity,
    required this.owner,
    required this.ownerId,
    required this.borrower,
    required this.distributedItemId,
    required this.borrowedQuantity,
  });

  @override
  ReturnTransactionState createState() => ReturnTransactionState();
}

class ReturnTransactionState extends State<ReturnTransaction> {
  final ReturnTransactionApi returnApi = ReturnTransactionApi();
  final TextEditingController quantityController = TextEditingController();
  final Logger logger = Logger();
  String? quantityError;

  @override
  void dispose() {
    quantityController.dispose();
    super.dispose();
  }

  void _validateQuantity(String value) {
    setState(() {
      if (value.isEmpty) {
        quantityError = "Quantity cannot be empty.";
      } else {
        int enteredQuantity = int.tryParse(value) ?? 0;
        if (enteredQuantity <= 0) {
          quantityError = "Quantity must be at least 1.";
        } else if (enteredQuantity > widget.borrowedQuantity) {
          quantityError =
              "Maximum borrowed quantity is ${widget.borrowedQuantity}.";
        } else {
          quantityError = null;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Dialog(
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
                  buildReturnDialogTitle(),
                  buildInfoBox('Item Name:', widget.itemName),
                  buildInfoBox('Description:', widget.description),
                  buildInfoBox(
                    'Owner:',
                    widget.owner
                        .split(' ')
                        .map((word) => word.isNotEmpty
                            ? word[0].toUpperCase() +
                                word.substring(1).toLowerCase()
                            : '')
                        .join(' '),
                  ),
                  buildInfoBox('Borrower:', widget.borrower),
                  const SizedBox(height: 10),
                  buildTextField(
                    'Quantity:',
                    'Enter quantity to return',
                    controller: quantityController,
                    errorText: quantityError,
                    onChanged: _validateQuantity,
                  ),
                  const SizedBox(height: 20),
                  buildReturnActionButton(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildReturnActionButton(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey[700],
            backgroundColor: Colors.grey[200],
          ),
          child: const Text("Cancel"),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: () async {
            int qty = int.tryParse(quantityController.text) ?? 0;

            if (qty <= 0 || qty > widget.borrowedQuantity) {
              setState(() {
                quantityError = (qty > widget.borrowedQuantity)
                    ? "Maximum borrowed quantity is ${widget.borrowedQuantity}."
                    : "Please enter a valid quantity.";
              });

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(quantityError ?? "Invalid quantity"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              return;
            }

            bool confirm = await showReturnConfirmationDialog(
              context: context,
              itemName: widget.itemName,
              description: widget.description,
              quantity: qty,
              ownerName: widget.owner,
              itemId: widget.itemId,
              distributedItemId: widget.distributedItemId,
              returnerName: widget.borrower,
            );

            if (confirm) {
              bool success = await processReturnTransaction(
                context: context,
                quantity: qty,
              );

              if (context.mounted && success) {
                logger.i("✅ Successfully returned itemId: ${widget.itemId}");
                await showSuccessDialog(context: context);
                if (context.mounted) {
                  Navigator.pop(context, true); // return true to parent
                }
              } else {
                logger.e("❌ Failed to return itemId: ${widget.itemId}");
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Failed to process return."),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            foregroundColor: Colors.white,
          ),
          child: const Text("Confirm"),
        ),
      ],
    );
  }

  Future<bool> processReturnTransaction({
    required BuildContext context,
    required int quantity,
  }) async {
    logger.i(
        "Processing return for itemId: ${widget.itemId} with quantity: $quantity");

    bool success = await returnApi.processReturnTransaction(
      borrowerId: widget.empId,
      ownerId: widget.ownerId,
      itemId: widget.itemId,
      quantity: quantity,
      currentDptId: widget.currentDptId,
      distributedItemId: widget.distributedItemId,
    );

    logger.i("🔎 ReturnTransaction Data: "
        "ItemId=${widget.itemId}, ItemName=${widget.itemName}, "
        "Description=${widget.description}, Quantity=$quantity, "
        "Owner=${widget.owner} (ID: ${widget.ownerId}), "
        "Borrower=${widget.borrower} (ID: ${widget.empId}), "
        "DistributedItemId=${widget.distributedItemId}");

    return success;
  }
}
