//filename:lib/design/main_design.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'colors.dart';
import '../main.dart';
import '../services/user_api.dart';

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
  String firstLetter = "?"; // Default display before fetching

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

    // If not stored, fetch from API
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
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0), 
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
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Image.asset(
                'assets/adts_appbar.png',
                height: 40,
                fit: BoxFit.contain,
              ),
            ),
            const Spacer(), 
            IconButton(
              onPressed: () {
                debugPrint("Logging out and returning to login screen...");
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              },
              icon: const Icon(
                Icons.exit_to_app,
                color: AppColors.primaryColor,
                size: 32,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

}