//filename:lib/services/user_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import 'config.dart';

class UserApi {
  final String baseUrl = Config.baseUrl;
  final Logger logger = Logger();

  // 🔹 Login Function (Fixed to store emp_id instead of id_number)
  Future<Map<String, dynamic>> login(String idNumber, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/users/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(
            {"id_number": idNumber.trim(), "password": password.trim()}),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        int? empId = responseData["emp_id"];
        String? idNumber = responseData["id_number"];
        String? firstName = responseData["first_name"];
        int? currentDptId = responseData["currentDptId"];
        String? token = responseData["token"];

        SharedPreferences prefs = await SharedPreferences.getInstance();
        if (empId != null) await prefs.setInt('emp_id', empId);
        if (idNumber != null) await prefs.setString('id_number', idNumber);
        if (firstName != null && firstName.isNotEmpty) {
          await prefs.setString(
              'firstLetter', firstName.substring(0, 1).toUpperCase());
        }
        if (currentDptId != null) {
          await prefs.setInt('currentDptId', currentDptId);
        }
        if (token != null) await prefs.setString('token', token);

        logger.i("Login successful: emp_id=$empId, currentDptId=$currentDptId");
        return responseData;
      } else {
        logger
            .w("Login failed: ${responseData["msg"] ?? "Invalid credentials"}");
        return {"error": responseData["msg"] ?? "Invalid credentials"};
      }
    } catch (e) {
      logger.e("Login error: $e");
      return {"error": "Failed to connect to the server."};
    }
  }

  // 🔹 Update User Function (Fixed to use emp_id)
  Future<Map<String, dynamic>> updateUser(
      int empId, String email, String password) async {
    try {
      logger.i("Sending Update Request: emp_id=$empId, email=$email");

      final response = await http.post(
        Uri.parse("$baseUrl/api/users/update"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "emp_id": empId,
          "email": email,
          "password": password,
        }),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (responseData.containsKey("success")) {
          logger.i("Update successful: ${responseData["success"]}");
          return {"success": responseData["success"]};
        }
        return {"error": "Unexpected response format."};
      }

      logger.w(
          "Update failed: ${responseData["error"] ?? "Invalid request data."}");
      return {"error": responseData["error"] ?? "Invalid request data."};
    } catch (e) {
      logger.e("Update error: $e");
      return {
        "error":
            "Failed to connect to the server. Please check your internet connection."
      };
    }
  }

  // 🔹 Get User Details Function
  Future<Map<String, dynamic>> getUserDetails() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      int? empId = prefs.getInt("emp_id");

      if (empId == null) {
        logger.w("Employee ID not found in preferences");
        return {"error": "Employee ID not found in preferences"};
      }

      final response = await http.get(Uri.parse("$baseUrl/api/users/$empId"));
      final Map<String, dynamic> userData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (userData.containsKey("currentDptId")) {
          await prefs.setInt('currentDptId', userData["currentDptId"]);
          logger.i(
              "User details fetched: currentDptId=${userData["currentDptId"]}");
        }
        return userData;
      } else {
        logger.w("Failed to fetch user details");
        return {"error": "Failed to fetch user details"};
      }
    } catch (e) {
      logger.e("Get user details error: $e");
      return {"error": "Network error"};
    }
  }

  Future<Map<String, dynamic>> verifyEmailAndId(
      String email, String idNumber) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/users/verify-email-id"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "id_number": idNumber}),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {"error": "An error occurred. Please try again."};
    }
  }

  Future<Map<String, dynamic>> resetPassword(
      String email, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/users/reset-password"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "new_password": newPassword}),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {"error": "An error occurred. Please try again."};
    }
  }

// 🔹 Change Password Function
Future<Map<String, dynamic>> changePassword(
    String currentPassword, String newPassword) async {
  try {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    int? empId = prefs.getInt("emp_id");

    if (empId == null) {
      logger.w("Employee ID not found in preferences");
      return {"error": "Employee ID not found. Please log in again."};
    }

    logger.i("Sending password change request for emp_id=$empId");

    final response = await http.post(
      Uri.parse("$baseUrl/api/users/change-password"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "emp_id": empId,
        "old_password": currentPassword.trim(), // ✅ FIXED HERE
        "new_password": newPassword.trim(),
      }),
    );

    final Map<String, dynamic> responseData = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      logger.i("Password change successful: ${responseData["success"]}");
      return {"success": responseData["success"] ?? "Password changed."};
    } else {
      logger.w("Password change failed: ${responseData["error"]}");
      return {"error": responseData["error"] ?? "Failed to change password."};
    }
  } catch (e) {
    logger.e("Change password error: $e");
    return {
      "error": "Network error. Please check your connection and try again."
    };
  }
}
// 🔹 Update Email Function
Future<Map<String, dynamic>> updateEmail(String newEmail) async {
  try {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    int? empId = prefs.getInt("emp_id");

    if (empId == null) {
      logger.w("Employee ID not found in preferences");
      return {"error": "Employee ID not found. Please log in again."};
    }

    logger.i("Sending email update request for emp_id=$empId");

    final response = await http.put(
      Uri.parse("$baseUrl/api/users/update-email"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "emp_id": empId,
        "new_email": newEmail.trim(),
      }),
    );

    final Map<String, dynamic> responseData = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      logger.i("Email update successful: ${responseData["success"]}");
      return {"success": responseData["success"] ?? "Email updated."};
    } else {
      logger.w("Email update failed: ${responseData["error"]}");
      return {"error": responseData["error"] ?? "Failed to update email."};
    }
  } catch (e) {
    logger.e("Update email error: $e");
    return {
      "error": "Network error. Please check your connection and try again."
    };
  }
}

}