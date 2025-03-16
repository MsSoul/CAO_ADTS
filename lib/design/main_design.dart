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
  return AppBar(
    title: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Image.asset(
        'assets/adts_appbar.png',
        height: 40, // Adjust height as needed
        fit: BoxFit.contain,
      ),
    ),
    backgroundColor: Colors.white,
    iconTheme: const IconThemeData(color: Colors.black),
    elevation: 0,
    leading: Padding(
      padding: const EdgeInsets.only(left: 16.0),
      child: CircleAvatar(
        radius: 30,
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
    actions: [
      IconButton(
        onPressed: () {
          debugPrint("Logging out and returning to login screen...");
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false, // Removes all previous routes
          );
        },
        icon: const Icon(
          Icons.exit_to_app,
          color: AppColors.primaryColor,
          size: 32,
        ),
      ),
    ],
    flexibleSpace: Container(
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.1),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
    ),
  );
}

}
