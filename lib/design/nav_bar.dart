//file name: lib/design/nav_bar.dart
import 'package:flutter/material.dart';
import 'colors.dart';
import 'package:badges/badges.dart' as badges;

ValueNotifier<int> unreadNotifCount = ValueNotifier<int>(0);

class BottomNavBar extends StatefulWidget {
  final Function(String) onMenuItemSelected;
  final int initialIndex;

  const BottomNavBar({super.key, required this.onMenuItemSelected, this.initialIndex = 1});

  @override
  BottomNavBarState createState() => BottomNavBarState();
}

class BottomNavBarState extends State<BottomNavBar> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex; 
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        widget.onMenuItemSelected('Notification');
        break;
      case 1:
        widget.onMenuItemSelected('Dashboard');
        break;
      case 2:
        widget.onMenuItemSelected('Items');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.primaryColor,
      unselectedItemColor: Colors.grey,
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      iconSize: 30,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
      items: [
        BottomNavigationBarItem(
          icon: _buildInboxIcon(),
          label: 'Inbox',
        ),
        _buildNavBarItem(
          icon: Icons.dashboard,
          label: 'Dashboard',
          index: 1,
        ),
        _buildNavBarItem(
          icon: Icons.inventory,
          label: 'Items',
          index: 2,
        ),
      ],
    );
  }

  /// ✅ Separate method for the Inbox icon to properly listen to changes
  Widget _buildInboxIcon() {
    return ValueListenableBuilder<int>(
      valueListenable: unreadNotifCount,
      builder: (context, count, child) {
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _selectedIndex == 0 ? AppColors.primaryColor : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: badges.Badge(
            badgeContent: count > 0
                ? Text(count.toString(), style: const TextStyle(color: Colors.white, fontSize: 12))
                : null,
            showBadge: count > 0,
            badgeStyle: const badges.BadgeStyle(
              badgeColor: Colors.red,
            ),
            child: Icon(
              Icons.mail_outline,
              color: _selectedIndex == 0 ? Colors.white : Colors.grey,
            ),
          ),
        );
      },
    );
  }

  BottomNavigationBarItem _buildNavBarItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _selectedIndex == index ? AppColors.primaryColor : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: _selectedIndex == index ? Colors.white : Colors.grey,
        ),
      ),
      label: label,
    );
  }
}
