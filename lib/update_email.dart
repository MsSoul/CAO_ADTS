import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/user_api.dart';
import 'design/colors.dart';

class UpdateEmailDialog extends StatefulWidget {
  const UpdateEmailDialog({super.key});

  @override
  State<UpdateEmailDialog> createState() => _UpdateEmailDialogState();
}

class _UpdateEmailDialogState extends State<UpdateEmailDialog> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  final UserApi _userApi = UserApi();

  Future<void> _handleUpdateEmail() async {
  String email = _emailController.text.trim();

  // Basic empty check
  if (email.isEmpty) {
    Fluttertoast.showToast(msg: "Email cannot be empty.");
    return;
  }

  // Email format validation using regex
  final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
  if (!emailRegex.hasMatch(email)) {
    Fluttertoast.showToast(msg: "Please enter a valid email address.");
    return;
  }
/*
  // Optional: If you want to block certain domains
  if (email.endsWith("@example.com")) {
    Fluttertoast.showToast(msg: "Emails from example.com are not allowed.");
    return;
  }*/

  setState(() {
    _isLoading = true;
  });

  try {
    final response = await _userApi.updateEmail(email);

    if (response.containsKey("success")) {
      Fluttertoast.showToast(msg: response["success"]);
      Navigator.pop(context);
    } else if (response.containsKey("error")) {
      Fluttertoast.showToast(msg: response["error"]);
    } else {
      Fluttertoast.showToast(msg: "Unexpected error occurred.");
    }
  } catch (error) {
    Fluttertoast.showToast(msg: "Error: $error");
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}


  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Update Email"),
      content: TextField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(
          labelText: "New Email Address",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primaryColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primaryColor, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        ),
      ),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            backgroundColor: Colors.grey[400],
          ),
          onPressed: () => Navigator.pop(context),
          child: const Text(
            "Cancel",
            style: TextStyle(color: Colors.black),
          ),
        ),
        _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  backgroundColor: AppColors.primaryColor,
                ),
                onPressed: _handleUpdateEmail,
                child: const Text(
                  "Update",
                  style: TextStyle(color: Colors.white),
                ),
              ),
      ],
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}
