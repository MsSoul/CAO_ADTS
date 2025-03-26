import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../design/colors.dart';
import 'services/user_api.dart';
import '../design/login_design.dart';
import 'otp_screen.dart';

class ForgetPasswordScreen extends StatefulWidget {
  const ForgetPasswordScreen({super.key});

  @override
  ForgetPasswordScreenState createState() => ForgetPasswordScreenState();
}

class ForgetPasswordScreenState extends State<ForgetPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _idNumberController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final UserApi _userApi = UserApi();
  bool _isVerifying = false;
  bool _isVerified = false;
  bool _isResetting = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  int? _empId;
  int? _currentDptId;

  Future<void> _verifyUser() async {
    final email = _emailController.text.trim();
    final idNumber = _idNumberController.text.trim();

    if (email.isEmpty || idNumber.isEmpty) {
      Fluttertoast.showToast(msg: "Please enter both Email and ID Number.");
      return;
    }

    setState(() => _isVerifying = true);
    final response = await _userApi.verifyEmailAndId(email, idNumber);
    setState(() => _isVerifying = false);

    if (!mounted) return;

    if (response.containsKey("error")) {
      Fluttertoast.showToast(msg: response["error"]);
      return;
    }

    final empId = response["emp_id"] ?? response["empId"];
    final currentDptId = response["current_dpt_id"] ?? response["currentDptId"];

    if (empId == null || currentDptId == null) {
      Fluttertoast.showToast(msg: "Verification failed. Missing data from server.");
      return;
    }

    Fluttertoast.showToast(msg: "OTP has been sent to your email!");

    final empIdInt = int.tryParse(empId.toString());
    final currentDptIdInt = int.tryParse(currentDptId.toString());

    if (empIdInt == null || currentDptIdInt == null) {
      Fluttertoast.showToast(msg: "Invalid data format. Please contact support.");
      return;
    }

    final otpSuccess = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => OtpScreen(empId: empIdInt, currentDptId: currentDptIdInt),
      ),
    );

    if (otpSuccess == true) {
      setState(() {
        _isVerified = true;
        _empId = empIdInt;
        _currentDptId = currentDptIdInt;
      });
      Fluttertoast.showToast(msg: "OTP verified! You can now reset your password.");
    } else {
      Fluttertoast.showToast(msg: "OTP verification failed or cancelled.");
    }
  }

  Future<void> _resetPassword() async {
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final email = _emailController.text.trim();

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      Fluttertoast.showToast(msg: "Please enter and confirm your new password.");
      return;
    }
    if (newPassword != confirmPassword) {
      Fluttertoast.showToast(msg: "Passwords do not match.");
      return;
    }

    setState(() => _isResetting = true);
    final response = await _userApi.resetPassword(email, newPassword);
    setState(() => _isResetting = false);

    if (!mounted) return;

    if (response.containsKey("error")) {
      Fluttertoast.showToast(msg: response["error"]);
    } else {
      Fluttertoast.showToast(msg: "Password reset successful! Please log in.");
      Navigator.pop(context);
    }
  }

  InputDecoration _inputDecoration(String label, {bool isPassword = false, VoidCallback? toggleVisibility, bool visible = false}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.primaryColor),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      suffixIcon: isPassword
          ? IconButton(
              icon: Icon(
                visible ? Icons.visibility : Icons.visibility_off,
                color: AppColors.primaryColor,
              ),
              onPressed: toggleVisibility,
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            buildLogo(screenWidth),
            const SizedBox(height: 20),
            const Text(
              "Reset Password",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Enter your Email and ID Number to verify your identity.",
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (!_isVerified) ...[
              TextField(
                controller: _emailController,
                decoration: _inputDecoration("Enter your email"),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _idNumberController,
                decoration: _inputDecoration("Enter your ID Number"),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              _isVerifying
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _verifyUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 45),
                      ),
                      child: const Text("Verify Identity"),
                    ),
            ],
            if (_isVerified) ...[
              const SizedBox(height: 20),
              TextField(
                controller: _newPasswordController,
                obscureText: !_isNewPasswordVisible,
                decoration: _inputDecoration(
                  "Enter New Password",
                  isPassword: true,
                  toggleVisibility: () {
                    setState(() {
                      _isNewPasswordVisible = !_isNewPasswordVisible;
                    });
                  },
                  visible: _isNewPasswordVisible,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _confirmPasswordController,
                obscureText: !_isConfirmPasswordVisible,
                decoration: _inputDecoration(
                  "Confirm New Password",
                  isPassword: true,
                  toggleVisibility: () {
                    setState(() {
                      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                    });
                  },
                  visible: _isConfirmPasswordVisible,
                ),
              ),
              const SizedBox(height: 20),
              _isResetting
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _resetPassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 45),
                      ),
                      child: const Text("Reset Password"),
                    ),
            ],
          ],
        ),
      ),
    );
  }
}
