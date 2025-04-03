import 'package:flutter/material.dart';
import 'colors.dart';
import 'package:logger/logger.dart';
import 'nav_bar.dart';

final logger = Logger();

Future<bool> showReturnConfirmationDialog({
  required BuildContext context,
  required String itemName,
  required String description,
  required int quantity,
  required String returnerName,
  required String ownerName,
  required int itemId,
  required int distributedItemId,
}) async {
  logger.i(
      "🔄 Return Confirmation Dialog - Item: $itemName | itemId: $itemId | owner: $ownerName | returner: $returnerName");

  return await showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            backgroundColor: Colors.white,
            title: const Text(
              'Confirm Return Request',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDialogText("Item", itemName),
                _buildDialogText("Description", description),
                _buildDialogText("Quantity", quantity.toString()),
                _buildDialogText("Owner Name", _capitalizeWords(ownerName)),
                _buildDialogText("Returner Name", returnerName),
              ],
            ),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Cancel Button
                  SizedBox(
                    width: 120,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Confirm Button
                  SizedBox(
                    width: 120,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Confirm'),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ) ??
      false; // Return false if the user dismisses the dialog
}

/// Helper function to create styled text for dialog
Widget _buildDialogText(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: RichText(
      text: TextSpan(
        style: const TextStyle(color: Colors.black, fontSize: 16),
        children: [
          TextSpan(
            text: "$label: ",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(text: value),
        ],
      ),
    ),
  );
}

String _capitalizeWords(String text) {
  return text
      .split(' ')
      .map((word) => word.isNotEmpty
          ? word[0].toUpperCase() + word.substring(1).toLowerCase()
          : '')
      .join(' ');
}

Future<void> showSuccessDialog({required BuildContext context}) async {
  if (!context.mounted) return;

  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 48),
            SizedBox(height: 10),
            Text(
              'Your return request has been successfully submitted!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop(); // Close success dialog
                }

                Future.delayed(const Duration(milliseconds: 100), () {
                  if (context.mounted) {
                    Navigator.maybePop(context); // Safe pop to avoid errors
                  }
                  // 🔄 Reload inbox notifications
                  unreadNotifCount.value++; // Triggers ValueNotifier to refresh UI
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('OK'),
            ),
          ),
        ],
      );
    },
  );
}


Widget buildTextField(
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

Widget buildReturnDialogTitle() {
  return const Center(
    child: Text(
      'Request Return Item',
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    ),
  );
}

Widget buildInfoBox(String label, String text) {
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
