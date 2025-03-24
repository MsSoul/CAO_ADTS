import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../services/transfer_transaction_api.dart';
import '../services/config.dart';
import '../design/colors.dart';

//int? selectedReceiverId;

final Logger logger = Logger();
final TransferTransactionApi transferApi =
    TransferTransactionApi(Config.baseUrl);

Widget buildReceiverSearchField({
  required TextEditingController receiverController,
  required Function(String) fetchReceiverDetails,
  required VoidCallback clearResults,
  required bool receiverSelected,
  required Function(bool) setReceiverSelected,
}) {
  return TextField(
    controller: receiverController,
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
      suffixIcon: receiverController.text.isNotEmpty
          ? IconButton(
              icon: const Icon(Icons.clear, color: Colors.grey),
              onPressed: () {
                receiverController.clear(); // Clear text
                clearResults(); // Hide search results
                setReceiverSelected(false); // Reset selection state
              },
            )
          : null,
    ),
    onChanged: (value) {
      if (value.isNotEmpty) {
        fetchReceiverDetails(value);
      } else {
        clearResults();
      }
    },
  );
}

Widget buildTransferActionButtons(
  BuildContext context,
  TextEditingController qtyController,
  TextEditingController receiverController,
  dynamic widget, {
  required int? selectedReceiverId,
}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      ElevatedButton(
        onPressed: () {
          logger.i("🚫 Transfer canceled by user.");
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        },
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.grey[700],
          backgroundColor: Colors.grey[200],
        ),
        child: const Text('Cancel'),
      ),
      const SizedBox(width: 10),
      ElevatedButton(
        onPressed: () async {
          logger.i("📌 Transfer button clicked!");

          int? quantity = int.tryParse(qtyController.text);
          if (quantity == null ||
              quantity <= 0 ||
              quantity > widget.availableQuantity) {
            logger.w(
                "❌ Invalid quantity: $quantity (Available: ${widget.availableQuantity})");
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please enter a valid quantity.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }

          if (selectedReceiverId == null ||
              receiverController.text.trim().isEmpty) {
            logger.w(
                "❌ Receiver not selected. selectedReceiverId: $selectedReceiverId");
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please select a receiver.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }

          bool confirm = await showDialog<bool>(
                context: context,
                builder: (BuildContext dialogContext) {
                  return AlertDialog(
                    backgroundColor: Colors.white,
                    title: const Text('Confirm Transfer'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildDialogText("Item", widget.itemName),
                        buildDialogText("Description", widget.description),
                        buildDialogText("Quantity", quantity.toString()),
                        buildDialogText(
                            "Receiver Name", receiverController.text),
                      ],
                    ),
                    actions: [
                      ElevatedButton(
                        onPressed: () {
                          logger.i("🚫 Transfer confirmation canceled.");
                          Navigator.of(dialogContext).pop(false);
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.grey[700],
                          backgroundColor: Colors.grey[200],
                        ),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          logger.i("✅ Transfer confirmed.");
                          Navigator.of(dialogContext).pop(true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Confirm'),
                      ),
                    ],
                  );
                },
              ) ??
              false;

          if (!context.mounted || !confirm) {
            logger.w("⚠️ Transfer was not confirmed.");
            return;
          }

          try {
            logger.i("📤 Sending transfer transaction...");
            final response = await transferApi.submitTransferTransaction(
              empId: widget.empId,
              itemId: widget.itemId,
              quantity: quantity,
              receiverId: selectedReceiverId,
              currentDptId: widget.currentDptId,
              distributedItemId: widget.distributedItemId,
            );

            logger.i("🛠️ API Response: $response");
            //print("API Response: $response"); // Log the entire response

            if (!context.mounted) return;

            bool success = true;
            String message = "Something went wrong. Please try again later.";

            success = response.containsKey('success')
                ? response['success'].toString().toLowerCase() == 'true' ||
                    response['message']
                        .toString()
                        .toLowerCase()
                        .contains("success")
                : response['message']
                    .toString()
                    .toLowerCase()
                    .contains("success");
            message = response['message'] ?? message;

            //print("Success: $success, Message: $message"); // Log success and message

            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext dialogContext) {
                return AlertDialog(
                  backgroundColor: Colors.white,
                  title: Center(
                    child: Text(
                      success
                          ? '🎉 Transfer Successful!'
                          : '❌ Transfer Failed!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: success ? AppColors.primaryColor : Colors.red,
                      ),
                    ),
                  ),
                  content: Text(message),
                  actions: [
                    ElevatedButton(
                      onPressed: () {
                        logger.i("🎉 Success/Error dialog closed.");
                        Navigator.of(dialogContext).pop();
                        if (success) Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            success ? AppColors.primaryColor : Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('OK'),
                    ),
                  ],
                );
              },
            );
          } catch (e) {
            logger.e("🔥 Error submitting transfer: $e");
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content:
                      Text('Something went wrong. Please try again later.'),
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
        child: const Text('Transfer'),
      ),
    ],
  );
}

/// Helper function to format dialog text
Widget buildDialogText(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );
}

Widget buildTransferTextField(
  String label,
  String hint, {
  TextEditingController? controller,
  Function(String)? onChanged,
  String? errorText,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),

      // Show Error Message Below Label
      if (errorText != null)
        Padding(
          padding: const EdgeInsets.only(
              top: 2, bottom: 3), // Space between label & error
          child: Text(
            errorText,
            style: const TextStyle(
                color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),

      // Text Field
      SizedBox(
        height: 40,
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
            filled: true,
            fillColor: Colors.white,
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide:
                  const BorderSide(color: AppColors.primaryColor, width: 1),
            ),
          ),
        ),
      ),
      const SizedBox(height: 3), // Consistent spacing
    ],
  );
}

Widget buildDropdown(String searchType, Function(String?) onChanged) {
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
          onChanged: onChanged,
          items: ['ID Number', 'Receiver Name'].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 14)), // Match design
            );
          }).toList(),
          icon: const Icon(Icons.arrow_drop_down,
              color: Colors.white, size: 18), // Match design
          dropdownColor: AppColors.primaryColor,
          underline: Container(),
        ),
      ),
    ),
  );
}

Widget buildReceiverSearchResultsList(List<Map<String, dynamic>> searchResults,
    Function(Map<String, dynamic>) onSelect) {
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
              final receiver = searchResults[index];

              int? idNumber =
                  receiver['ID_NUMBER'] is int ? receiver['ID_NUMBER'] : null;
              String formattedName = capitalizeName(
                  '${receiver['FIRSTNAME'] ?? ''} '
                  '${(receiver['MIDDLENAME'] ?? '').isNotEmpty ? receiver['MIDDLENAME'][0] + "." : ''} '
                  '${receiver['LASTNAME'] ?? ''}');

              return InkWell(
                onTap: () => onSelect(receiver),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  child: Row(
                    children: [
                      Text(
                        idNumber?.toString() ?? '',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12),
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

String capitalizeName(String name) {
  return name.split(' ').map((word) {
    if (word.isEmpty) return '';
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  }).join(' ');
}

Widget buildTransferDialogTitle() {
  return const Center(
    child: Text(
      'Request Transfer Item',
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    ),
  );
}

Widget buildTransferInfoBox(String label, String text) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      Container(
        height: 40,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 238, 247, 255),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.primaryColor, width: 1),
        ),
        child: Text(text, style: const TextStyle(fontSize: 14)),
      ),
      const SizedBox(height: 3),
    ],
  );
}
