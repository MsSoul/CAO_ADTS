// filename: lib/main.dart
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'design/login_design.dart';
import 'home.dart';
import 'services/user_api.dart';
import 'services/notif_api.dart';
import 'update_user.dart';
import 'design/nav_bar.dart'; // Import for unreadNotifCount
import 'services/config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool obscurePassword = true;
  final UserApi _userApi = UserApi();
  final NotifApi _notifApi = NotifApi(baseUrl: Config.baseUrl); // ✅ Fixed NotifApi initialization

  Future<void> _handleLogin() async {
    debugPrint("Login Attempt with ID: ${_usernameController.text}");
    String idNumber = _usernameController.text.trim();
    String password = _passwordController.text.trim();

    if (idNumber.isEmpty || password.isEmpty) {
      debugPrint("Login failed: Missing ID or password");
      Fluttertoast.showToast(msg: "Please enter ID number and password");
      return;
    }

    Map<String, dynamic> response = await _userApi.login(idNumber, password);
    debugPrint("Full Login response: $response");

    if (!mounted) return;

    if (response.containsKey("error")) {
      debugPrint("Login error: ${response["error"]}");
      Fluttertoast.showToast(msg: response["error"]);
    } else {
      Fluttertoast.showToast(msg: response["msg"]);

      int? empId = response["emp_id"]; // ✅ Extract emp_id
      int currentDptId = response["currentDptId"] ?? -1;
      String? firstName = response["firstLetter"]?.toString();

      SharedPreferences prefs = await SharedPreferences.getInstance();

      if (firstName != null && firstName.isNotEmpty) {
        await prefs.setString('firstLetter', firstName);
        debugPrint("Stored First Letter: $firstName");
      }

      if (empId != null) {
        await prefs.setInt('empId', empId);
        debugPrint("Stored empId: $empId");

        // ✅ Fetch unread notifications count IMMEDIATELY
        _fetchUnreadNotifications(empId);
      } else {
        debugPrint("Error: empId is null, cannot proceed!");
        Fluttertoast.showToast(msg: "Login failed: Employee ID missing");
        return;
      }

      await prefs.setInt('currentDptId', currentDptId);
      debugPrint("Stored currentDptId: $currentDptId");

      if (!mounted) return;

      if (response["redirect"] == "update") {
        debugPrint("Redirecting to UpdateUserScreen with Emp ID: $empId");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => UpdateUserScreen(empId: empId)),
        );
      } else {
        debugPrint("Redirecting to HomeScreen...");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen(empId: empId, currentDptId: currentDptId)), 
        );
      }
    }
  }

  // ✅ Fetch unread notifications count
  Future<void> _fetchUnreadNotifications(int empId) async {
    try {
      List<Map<String, dynamic>> notifications = await _notifApi.fetchNotifications(empId);
      int unreadCount = notifications.where((notif) => notif['is_read'] == false).length;

      // ✅ Update the ValueNotifier
      unreadNotifCount.value = unreadCount;
      debugPrint("📬 Unread Notifications: $unreadCount");
    } catch (e) {
      debugPrint("❌ Error fetching notifications: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo
                    buildLogo(constraints.maxWidth),
                    const SizedBox(height: 20),

                    // Username Field
                    buildTextField(
                      'ID Number',
                      controller: _usernameController,
                    ),
                    const SizedBox(height: 10),

                    // Password Field with Eye Icon
                    buildTextField(
                      'Password',
                      controller: _passwordController,
                      obscureText: obscurePassword,
                      onToggleVisibility: () {
                        setState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                    ),
                    const SizedBox(height: 10),

                    // Forgot Password Button
                    buildForgotPasswordButton(context),

                    // Login Button
                    buildLoginButton('Log In', _handleLogin),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
