import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'colors.dart';
import '../services/user_api.dart';
import '../update_password.dart';
import '../main.dart';
import '../update_email.dart';

// Logo Widget
Widget mainLogo(double size) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const SizedBox(width: 5),
      Image.asset(
        'assets/web-ibs.png',
        height: size * 0.3,
        width: size * 0.3,
      ),
    ],
  );
}

class MainDesign extends StatefulWidget implements PreferredSizeWidget {
  const MainDesign({super.key});

  @override
  MainDesignState createState() => MainDesignState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class MainDesignState extends State<MainDesign> {
  String firstLetter = "?";

  @override
  void initState() {
    super.initState();
    fetchFirstLetter();
  }

  Future<void> fetchFirstLetter() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedLetter = prefs.getString("firstLetter");

    if (storedLetter != null && storedLetter.isNotEmpty) {
      setState(() {
        firstLetter = storedLetter.toUpperCase();
      });
      return;
    }

    try {
      UserApi userApi = UserApi();
      Map<String, dynamic> userData = await userApi.getUserDetails();
      String fetchedName = userData['first_name'] ?? "";

      if (fetchedName.isNotEmpty) {
        String fetchedLetter = fetchedName[0].toUpperCase();
        await prefs.setString("firstLetter", fetchedLetter);
        setState(() {
          firstLetter = fetchedLetter;
        });
      }
    } catch (error) {
      debugPrint("Error fetching user details: $error");
    }
  }

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout Confirmation"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
  ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.grey[400],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    onPressed: () => Navigator.of(context).pop(false),
    child: const Text(
      "Cancel",
      style: TextStyle(color: Colors.black),
    ),
  ),
  ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primaryColor, // Your primary color
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    onPressed: () => Navigator.of(context).pop(true),
    child: const Text(
      "Logout",
      style: TextStyle(color: Colors.white),
    ),
  ),
],

      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(70),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.1),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                child: PopupMenuButton<String>(
                  color: Colors.white,
                  offset: const Offset(0, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  itemBuilder: (context) => [
                    PopupMenuItem<String>(
                      value: 'update_password',
                      child: Row(
                        children: [
                          const Icon(Icons.lock_reset,
                              color: AppColors.primaryColor),
                          const SizedBox(width: 8),
                          const Text("Update Password",
                              style: TextStyle(color: AppColors.primaryColor)),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'update_email',
                      child: Row(
                        children: [
                          const Icon(Icons.email_outlined,
                              color: AppColors.primaryColor),
                          const SizedBox(width: 8),
                          const Text("Update Email",
                              style: TextStyle(color: AppColors.primaryColor)),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem<String>(
                      value: 'logout',
                      child: Row(
                        children: [
                          const Icon(Icons.logout,
                              color: AppColors.primaryColor),
                          const SizedBox(width: 8),
                          const Text("Logout",
                              style: TextStyle(color: AppColors.primaryColor)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'update_password') {
                      showDialog(
                        context: context,
                        builder: (context) => const UpdatePasswordDialog(),
                      );
                    } else if (value == 'update_email') {
                      showDialog(
                        context: context,
                        builder: (context) => const UpdateEmailDialog(),
                      );
                    } else if (value == 'logout') {
                      _logout(context);
                    }
                  },
                  child: CircleAvatar(
                    radius: 25,
                    backgroundColor: AppColors.primaryColor,
                    child: Text(
                      firstLetter,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Image.asset(
                  'assets/adts_appbar.png',
                  height: 40,
                  fit: BoxFit.contain,
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
