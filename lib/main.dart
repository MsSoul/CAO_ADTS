import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'design/login_design.dart';
import 'otp_screen.dart';
import 'services/user_api.dart';
import 'services/notif_api.dart';
import 'update_user.dart';
import 'design/nav_bar.dart';
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
  final NotifApi _notifApi = NotifApi(baseUrl: Config.baseUrl);

  Future<void> _handleLogin() async {
    debugPrint("🔑 Login Attempt with ID: ${_usernameController.text}");
    String idNumber = _usernameController.text.trim();
    String password = _passwordController.text.trim();

    if (idNumber.isEmpty || password.isEmpty) {
      Fluttertoast.showToast(msg: "Please enter ID number and password");
      return;
    }

    Map<String, dynamic> response = await _userApi.login(idNumber, password);
    debugPrint("📥 Full Login response: $response");

    if (!mounted) return;

    if (response.containsKey("error")) {
      debugPrint("❌ Login error: ${response["error"]}");
      Fluttertoast.showToast(msg: response["error"]);
    } else {
      Fluttertoast.showToast(msg: response["msg"]);

      int? empId = response["emp_id"];
      int currentDptId = response["currentDptId"] ?? -1;
      String? firstLetter = response["firstLetter"]?.toString();

      SharedPreferences prefs = await SharedPreferences.getInstance();

      if (firstLetter != null && firstLetter.isNotEmpty) {
        await prefs.setString('firstLetter', firstLetter);
        debugPrint("✅ Stored First Letter: $firstLetter");
      }

      if (empId != null) {
        await prefs.setInt('empId', empId);
        debugPrint("✅ Stored empId: $empId");

        // Fetch unread notifications
        _fetchUnreadNotifications(empId);
      } else {
        debugPrint("⚠️ empId is null, cannot proceed!");
        Fluttertoast.showToast(msg: "Login failed: Employee ID missing");
        return;
      }

      await prefs.setInt('currentDptId', currentDptId);
      debugPrint("✅ Stored currentDptId: $currentDptId");

      if (!mounted) return;

      // Navigate based on redirect
      if (response["redirect"] == "update") {
        debugPrint("➡️ Redirecting to UpdateUserScreen...");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => UpdateUserScreen(empId: empId)),
        );
      } else {
        debugPrint("➡️ Redirecting to OtpScreen for verification...");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OtpScreen(
              empId: empId,
              currentDptId: currentDptId,
            ),
          ),
        );
      }
    }
  }

  Future<void> _fetchUnreadNotifications(int empId) async {
    try {
      List<Map<String, dynamic>> notifications =
          await _notifApi.fetchNotifications(empId);
      int unreadCount =
          notifications.where((notif) => notif['is_read'] == false).length;

      unreadNotifCount.value = unreadCount;
      debugPrint("📬 Unread Notifications: $unreadCount");
    } catch (e) {
      debugPrint("❗ Error fetching notifications: $e");
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
                    buildLogo(constraints.maxWidth),
                    const SizedBox(height: 20),

                    buildTextField(
                      'ID Number',
                      controller: _usernameController,
                    ),
                    const SizedBox(height: 10),

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

                    buildForgotPasswordButton(context),
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
