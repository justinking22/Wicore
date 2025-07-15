import 'package:Wicore/screens/home_screen.dart';
import 'package:Wicore/screens/qr_acanner_screen.dart';
import 'package:Wicore/screens/records_screen.dart';
import 'package:Wicore/screens/settings_screen.dart';
import 'package:Wicore/styles/colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({Key? key}) : super(key: key);

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [HomeScreen(), RecordsScreen(), SettingsScreen()],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dividing line
          Container(height: 1, color: CustomColors.lightGray),
          Container(
            color: Colors.white,
            child: SafeArea(
              child: SizedBox(
                height: 70,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(
                      'assets/icons/home_icon.png',
                      'assets/icons/home_selected.png',
                      '홈',
                      0,
                    ),
                    _buildNavItem(
                      'assets/icons/records_icon.png',
                      'assets/icons/records_selected.png',
                      '기록',
                      1,
                    ),
                    _buildNavItem(
                      'assets/icons/settings_icon.png',
                      'assets/icons/settings_selected.png',
                      '설정',
                      2,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    String unselectedIconPath,
    String selectedIconPath,
    String label,
    int index,
  ) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              isSelected ? selectedIconPath : unselectedIconPath,
              width: 28,
              height: 28,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? Colors.black : const Color(0xFF9E9E9E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
