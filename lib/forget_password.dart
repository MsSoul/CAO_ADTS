import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../design/colors.dart';
import 'services/user_api.dart';
import '../design/login_design.dart'; // Import your logo widget

class ForgetPasswordScreen extends StatefulWidget {
  const ForgetPasswordScreen({super.key});

  @override
  ForgetPasswordScreenState createState() => ForgetPasswordScreenState();
}

class ForgetPasswordScreenState extends State<ForgetPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _idNumberController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final UserApi _userApi = UserApi();
  bool _isLoading = false;
  bool _isVerified = false; // Track if user is verified for password reset

  Future<void> _verifyUser() async {
    String email = _emailController.text.trim();
    String idNumber = _idNumberController.text.trim();

    if (email.isEmpty || idNumber.isEmpty) {
      Fluttertoast.showToast(msg: "Please enter your Email and ID Number.");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    Map<String, dynamic> response =
        await _userApi.verifyEmailAndId(email, idNumber);

    setState(() {
      _isLoading = false;
    });

    if (!mounted) return;

    if (response.containsKey("error")) {
      Fluttertoast.showToast(msg: response["error"]);
    } else {
      Fluttertoast.showToast(
          msg: "Identity verified. Please enter a new password.");
      setState(() {
        _isVerified = true;
      });
    }
  }

  Future<void> _resetPassword() async {
    String newPassword = _newPasswordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();
    String email = _emailController.text.trim();

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      Fluttertoast.showToast(msg: "Please enter a new password.");
      return;
    }
    if (newPassword != confirmPassword) {
      Fluttertoast.showToast(msg: "Passwords do not match.");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    Map<String, dynamic> response =
        await _userApi.resetPassword(email, newPassword);

    setState(() {
      _isLoading = false;
    });

    if (!mounted) return;

    if (response.containsKey("error")) {
      Fluttertoast.showToast(msg: response["error"]);
    } else {
      Fluttertoast.showToast(msg: "Password reset successful. Please login.");
      Navigator.pop(context);
    }
  }

  InputDecoration customInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.primaryColor),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primaryColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primaryColor, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primaryColor),
      ),
      contentPadding: const EdgeInsets.symmetric(
          vertical: 10, horizontal: 12), // Reduced height
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
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
                textAlign: TextAlign.left,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 10),

              // Hide email & ID fields after verification
              if (!_isVerified) ...[
                TextField(
                  controller: _emailController,
                  decoration: customInputDecoration("Enter your email"),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _idNumberController,
                  decoration: customInputDecoration("Enter your ID Number"),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),
              ],

              if (!_isVerified)
                _isLoading
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

              if (_isVerified) ...[
                const SizedBox(height: 20),
                TextField(
                  controller: _newPasswordController,
                  obscureText: true,
                  decoration: customInputDecoration("Enter New Password"),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: customInputDecoration("Confirm New Password"),
                ),
                const SizedBox(height: 20),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _resetPassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          foregroundColor: Colors.white,
                          minimumSize:
                              const Size(double.infinity, 45), // Smaller height
                        ),
                        child: const Text("Reset Password"),
                      ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
