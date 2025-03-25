import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../design/colors.dart';
import '../design/login_design.dart'; 
import 'services/user_api.dart';
import 'home.dart';
import 'update_user.dart';

class OtpScreen extends StatefulWidget {
  final int empId;
  final int currentDptId;

  const OtpScreen({
    super.key,
    required this.empId,
    required this.currentDptId,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  final UserApi _userApi = UserApi();
  bool _isLoading = false;
  bool _isResending = false;

  Future<void> _verifyOtp() async {
    String otp = _otpController.text.trim();

    if (otp.isEmpty) {
      Fluttertoast.showToast(msg: "Please enter the OTP.");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    Map<String, dynamic> response =
        await _userApi.verifyOtp(widget.empId, otp);

    setState(() {
      _isLoading = false;
    });

    if (!mounted) return;

    if (response.containsKey("error")) {
      Fluttertoast.showToast(msg: response["error"]);
    } else {
      Fluttertoast.showToast(msg: response["msg"]);

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt('empId', widget.empId);
      await prefs.setInt('currentDptId', widget.currentDptId);

      if (response["redirect"] == "update") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  UpdateUserScreen(empId: widget.empId)),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => HomeScreen(
                  empId: widget.empId,
                  currentDptId: widget.currentDptId)),
        );
      }
    }
  }

  Future<void> _resendOtp() async {
    setState(() {
      _isResending = true;
    });

    Map<String, dynamic> response = await _userApi.resendOtp(widget.empId);

    setState(() {
      _isResending = false;
    });

    if (response.containsKey("error")) {
      Fluttertoast.showToast(msg: response["error"]);
    } else {
      Fluttertoast.showToast(msg: response["msg"] ?? "OTP resent successfully.");
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
      contentPadding:
          const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              buildLogo(screenWidth),
              const SizedBox(height: 20),
              const Text(
                "OTP Verification",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "Please enter the OTP sent to your registered email.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _otpController,
                decoration: customInputDecoration("Enter OTP"),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _verifyOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 45),
                      ),
                      child: const Text("Verify OTP"),
                    ),
              const SizedBox(height: 20),
              _isResending
                  ? const CircularProgressIndicator()
                  : TextButton(
                      onPressed: _resendOtp,
                      child: const Text(
                        "Resend OTP",
                        style: TextStyle(
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
