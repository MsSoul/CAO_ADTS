import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'design/main_design.dart';
import 'design/nav_bar.dart';
import 'notification.dart';
import 'dashboard.dart';
import 'items.dart';
import 'main.dart';

class HomeScreen extends StatefulWidget {
  final int empId;
  final int currentDptId;

  const HomeScreen({super.key, required this.empId, required this.currentDptId});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  late int empId;
  late int currentDptId;
  late Widget _currentScreen;
  int _selectedIndex = 0; // ✅ Default to Inbox

  @override
  void initState() {
    super.initState();
    empId = widget.empId;
    currentDptId = widget.currentDptId;
    debugPrint("HomeScreen initialized with empId: $empId, currentDptId: $currentDptId");

    // ✅ Set default screen to Inbox (NotifScreen)
    _currentScreen = NotifScreen(empId: empId);
  }

  void _handleMenuSelection(String title) {
    setState(() {
      debugPrint("Selected Menu: $title");
      switch (title) {
        case 'Notification':
          _selectedIndex = 0;
          _currentScreen = NotifScreen(empId: empId);
          break;
        case 'Dashboard':
          _selectedIndex = 1;
          _currentScreen = DashboardScreen(empId: empId, currentDptId: currentDptId);
          break;
        case 'Items':
          _selectedIndex = 2;
          ItemsPopup.show(context, empId, currentDptId, (Widget selectedScreen) {
            setState(() {
              _currentScreen = selectedScreen;
            });
          });
          return;
      }
    });
  }

  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    debugPrint("User logged out, clearing SharedPreferences.");

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBar(
          automaticallyImplyLeading: false,
          title: const MainDesign(),
          toolbarHeight: kToolbarHeight,
          elevation: 0,
          backgroundColor: Colors.transparent,
          shape: const Border(
            bottom: BorderSide(
              color: Colors.black12,
              width: 1.0,
            ),
          ),
          titleSpacing: 0,
        ),
      ),
      body: _currentScreen,
      bottomNavigationBar: BottomNavBar(
        onMenuItemSelected: _handleMenuSelection,
        initialIndex: _selectedIndex, // ✅ Ensure correct tab is highlighted
      ),
    );
  }
}
