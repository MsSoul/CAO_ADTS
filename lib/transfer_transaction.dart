import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../services/transfer_transaction_api.dart';
import '../services/config.dart';
import '../design/transfer_widgets.dart';

class TransferTransactionDialog extends StatefulWidget {
  final int empId;
  final int itemId;
  final String itemName;
  final String description;
  final int currentDptId;
  final int availableQuantity;
  final int distributedItemId;

  const TransferTransactionDialog({
    super.key,
    required this.empId,
    required this.itemId,
    required this.itemName,
    required this.description,
    required this.currentDptId,
    required this.availableQuantity,
    required this.distributedItemId,
  });

  @override
  State<TransferTransactionDialog> createState() =>
      _TransferTransactionDialogState();
}

class _TransferTransactionDialogState extends State<TransferTransactionDialog> {
  final TextEditingController qtyController = TextEditingController();
  final TextEditingController receiverController = TextEditingController();
  final TransferTransactionApi transferApi =
      TransferTransactionApi(Config.baseUrl);
  final Logger logger = Logger();

  String searchType = "ID Number";
  bool isLoading = false;
  bool isConfirmEnabled = false;
  bool receiverSelected = false;

  List<Map<String, dynamic>> searchResults = [];
  int? selectedReceiverId;
  String? quantityError;

  @override
  void initState() {
    super.initState();
    qtyController.addListener(_validateQuantity);
  }

  void _validateQuantity() {
    String value = qtyController.text;
    int enteredQuantity = int.tryParse(value) ?? 0;

    setState(() {
      if (value.isEmpty) {
        quantityError = "Quantity cannot be empty.";
      } else if (enteredQuantity <= 0) {
        quantityError = "Quantity must be at least 1.";
      } else if (enteredQuantity > widget.availableQuantity) {
        quantityError =
            "Maximum available quantity is ${widget.availableQuantity}.";
      } else {
        quantityError = null;
      }

      isConfirmEnabled = selectedReceiverId != null && quantityError == null;
    });
  }

  Future<void> fetchReceiverDetails(String input) async {
    if (widget.currentDptId == -1) {
      logger.w("Invalid Department ID - Using Default ID");
      return;
    }

    setState(() => isLoading = true);

    try {
      final receiverData = await transferApi.fetchReceivers(
        widget.currentDptId.toString(),
        input,
        searchType,
        widget.empId.toString(),
      );

      setState(() {
        searchResults = receiverData;
        isLoading = false;
      });

      if (receiverData.isEmpty) {
        logger.w("No receivers found.");
      } else {
        logger.i("Fetched ${receiverData.length} receiver(s)");
      }
    } catch (e, stackTrace) {
      logger.e("Error fetching receiver details:",
          error: e, stackTrace: stackTrace);
      setState(() => isLoading = false);
    }
  }

  void _selectReceiver(Map<String, dynamic> receiver) {
  logger.i("Receiver Data: $receiver");

  setState(() {
    selectedReceiverId = receiver['receiverId']; // Use correct key
    receiverController.text = "${receiver['FIRSTNAME']} ${receiver['LASTNAME']}";
    receiverSelected = true;
    searchResults.clear(); // Hide results after selection
    isConfirmEnabled = qtyController.text.isNotEmpty && quantityError == null;

    logger.i("Receiver selected: ID = $selectedReceiverId, Name = ${receiverController.text}");
  });
}


  void _clearReceiverSelection() {
    setState(() {
      receiverController.clear();
      selectedReceiverId = null;
      receiverSelected = false;
      isConfirmEnabled = false;
    });
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
                    buildTransferDialogTitle(),
                    buildTransferInfoBox('Item Name:', widget.itemName),
                    buildTransferInfoBox('Description:', widget.description),
                    buildTransferTextField(
                      'Quantity:',
                      'Enter Quantity',
                      controller: qtyController,
                      errorText: quantityError,
                    ),
                    _buildReceiverField(),
                    buildTransferActionButtons(
                      context,
                      qtyController,
                      receiverController,
                      widget,
                      selectedReceiverId: selectedReceiverId,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReceiverField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildTransferInfoBox('Transfer To:', receiverController.text),
        if (!receiverSelected)
          Row(
            children: [
              buildDropdown(searchType, (newValue) {
                setState(() {
                  searchType = newValue!;
                  _clearReceiverSelection();
                });
              }),
              const SizedBox(width: 10),
              Expanded(
                child: buildReceiverSearchField(
                  receiverController: receiverController,
                  fetchReceiverDetails: fetchReceiverDetails,
                  clearResults: () => setState(() => searchResults.clear()),
                  receiverSelected: receiverSelected,
                  setReceiverSelected: (bool selected) {
                    setState(() {
                      receiverSelected = selected;
                    });
                  },
                ),
              ),
            ],
          ),
        if (!receiverSelected && isLoading) const CircularProgressIndicator(),
        if (!receiverSelected && searchResults.isNotEmpty)
          buildReceiverSearchResultsList(searchResults, _selectReceiver),
      ],
    );
  }
}
