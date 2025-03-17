import 'package:flutter/material.dart';
import 'borrow_items_screen.dart';
 import 'lend_items_screen.dart';
// import 'return_item.dart';
import 'transfer_item_screen.dart';
import 'design/colors.dart';

typedef OnItemSelected = void Function(Widget selectedScreen);

class ItemsPopup {
  static void show(BuildContext context, int empId, int currentDptId, OnItemSelected onSelect) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text("Please Select Transaction"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              _buildButton(context, "Borrow Item", () {
                onSelect(BorrowItemsScreen(empId: empId, currentDptId: currentDptId));
              }),
               _buildButton(context, "Lend Item", () {
                 onSelect(LendingItemsScreen(empId: empId, currentDptId: currentDptId));
               }),
              // _buildButton(context, "Return Item", () {
              //   onSelect(ReturnItemScreen(empId: empId, currentDptId: currentDptId));
              // }),
               _buildButton(context, "Transfer Item", () {
                 onSelect(TransferItemsScreen(empId: empId, currentDptId: currentDptId));
               }),
              _buildButton(context, "Close", () {
                Navigator.of(context).pop();
              }, isCloseButton: true),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildButton(BuildContext context, String text, VoidCallback onPressed, {bool isCloseButton = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isCloseButton ? const Color.fromARGB(255, 235, 234, 234) : AppColors.primaryColor,
          foregroundColor: isCloseButton ? AppColors.primaryColor : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          minimumSize: const Size(double.infinity, 50),
        ),
        onPressed: () {
          if (isCloseButton) {
            Navigator.of(context).pop(); 
          } else {
            Navigator.of(context).pop();
            onPressed(); 
          }
        },
        child: Text(text),
      ),
    );
  }
}
