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
  final Logger logger = Logger();

  @override
  void initState() {
    super.initState();
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
                  buildInfoBox('Quantity:', widget.quantity.toString()),
                  buildReturnActionButton(context, widget),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildReturnActionButton(
    BuildContext context,
    ReturnTransaction widget,
  ) {
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
            bool confirm = await showReturnConfirmationDialog(
              context: context,
              itemName: widget.itemName,
              description: widget.description,
              quantity: widget.quantity,
              ownerName: widget.owner,
              itemId: widget.itemId,
              distributedItemId: widget.distributedItemId,
              returnerName: widget.borrower, // Add the missing argument
            );

            if (confirm) {
              bool success = await processReturnTransaction(
                borrowerId: widget.empId,
                ownerId: widget.ownerId,
                itemId: widget.itemId,
                quantity: widget.quantity,
                currentDptId: widget.currentDptId,
                distributedItemId: widget.distributedItemId,
                context: context,
              );

              if (context.mounted) {
                if (success) {
                  logger.i("itemId: \${widget.itemId}");
                  Navigator.pop(context); // Close return transaction dialog

                  // Show success dialog
                  await showSuccessDialog(context: context);
                } else {
                  logger.e("Failed to return item.");
                }
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

  // Process return transaction API call
  Future<bool> processReturnTransaction({
    required int borrowerId,
    required int ownerId,
    required int itemId,
    required int quantity,
    required int currentDptId,
    required int distributedItemId,
    required BuildContext context,
  }) async {
    logger.i("Returning quantity: \$quantity");

    bool success = await returnApi.processReturnTransaction(
      borrowerId: borrowerId,
      ownerId: ownerId,
      itemId: itemId,
      quantity: quantity,
      currentDptId: currentDptId,
      distributedItemId: distributedItemId,
    );

    logger.i("🔍 ReturnTransaction Data: "
        "ItemId=${widget.itemId}, ItemName=${widget.itemName}, "
        "Description=${widget.description}, Quantity=${widget.quantity}, "
        "Owner=${widget.owner}, Borrower=${widget.borrower}, "
        "DistributedItemId=${widget.distributedItemId}, ");

    return success;
  }
}
