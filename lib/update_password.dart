import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/user_api.dart';
import 'design/colors.dart';

class UpdatePasswordDialog extends StatefulWidget {
  const UpdatePasswordDialog({super.key});

  @override
  State<UpdatePasswordDialog> createState() => _UpdatePasswordDialogState();
}

class _UpdatePasswordDialogState extends State<UpdatePasswordDialog> {
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _confirmPasswordStarted = false;
  final UserApi _userApi = UserApi();

  String? get _confirmPasswordError {
    if (!_confirmPasswordStarted) return null;
    return _confirmPasswordController.text.trim() != _newPasswordController.text.trim()
        ? 'Passwords do not match'
        : null;
  }

  Future<void> _handleUpdatePassword() async {
  String currentPassword = _currentPasswordController.text.trim();
  String newPassword = _newPasswordController.text.trim();
  String confirmPassword = _confirmPasswordController.text.trim();

  if (currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
    Fluttertoast.showToast(msg: "Please fill in all fields.");
    return;
  }

  if (newPassword != confirmPassword) {
    Fluttertoast.showToast(msg: "New passwords do not match.");
    return;
  }

  setState(() {
    _isLoading = true;
  });

  try {
    final response = await _userApi.changePassword(currentPassword, newPassword);

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


  InputDecoration customInputDecoration(String label, bool obscure, VoidCallback toggle, {String? errorText}) {
    return InputDecoration(
      labelText: label,
      errorText: errorText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primaryColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      suffixIcon: IconButton(
        icon: Icon(
          obscure ? Icons.visibility_off : Icons.visibility,
          color: Colors.grey,
        ),
        onPressed: toggle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: const Text("Update Password"),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: _currentPasswordController,
              obscureText: _obscureCurrent,
              decoration: customInputDecoration(
                "Current Password",
                _obscureCurrent,
                () => setState(() => _obscureCurrent = !_obscureCurrent),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _newPasswordController,
              obscureText: _obscureNew,
              onChanged: (value) {
                if (_confirmPasswordStarted) {
                  setState(() {});
                }
              },
              decoration: customInputDecoration(
                "New Password",
                _obscureNew,
                () => setState(() => _obscureNew = !_obscureNew),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirm,
              onChanged: (value) {
                if (!_confirmPasswordStarted) {
                  setState(() {
                    _confirmPasswordStarted = true;
                  });
                } else {
                  setState(() {});
                }
              },
              decoration: customInputDecoration(
                "Confirm New Password",
                _obscureConfirm,
                () => setState(() => _obscureConfirm = !_obscureConfirm),
                errorText: _confirmPasswordError,
              ),
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            backgroundColor: Colors.grey[200],
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
                onPressed: _handleUpdatePassword,
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
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
