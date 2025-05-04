import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'main_screen_accommodations.dart';
import 'liked.dart';
import 'profile.dart';
import 'app_settings.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;

  const BottomNavBar({super.key, required this.currentIndex});

  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) return;

    Widget nextScreen;
    switch (index) {
      case 0:
        nextScreen = const MainScreenAccommodations();
        break;
      case 1:
        nextScreen = const LikedScreen();
        break;
      case 2:
        nextScreen = const ProfileScreen();
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => nextScreen,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final highContrast = settings.highContrast;
    final bigText = settings.bigText;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor =
        highContrast
            ? (isDark ? AppColors.colorBgDarkHigh : AppColors.colorBgHigh)
            : (isDark ? AppColors.colorBgDark : AppColors.colorBg);
    final selectedColor =
        highContrast
            ? (isDark ? AppColors.color1DarkHigh : AppColors.color1High)
            : (isDark ? AppColors.color1Dark : AppColors.color1);
    final unselectedColor =
        highContrast
            ? (isDark ? AppColors.colorTextDarkHigh : AppColors.colorTextHigh)
            : (isDark ? AppColors.colorTextDark : AppColors.colorText);
    final borderColor =
        highContrast
            ? (isDark ? AppColors.colorHintDarkHigh : AppColors.colorHintHigh)
            : (isDark ? AppColors.colorHintDark : AppColors.colorHint);

    final bottomInset = MediaQuery.of(context).padding.bottom;
    final iconOffset = bottomInset / 2;
    final iconSize = bigText ? 32.0 : 24.0;

    Widget _navIcon(String asset, Color color) {
      return Padding(
        padding: EdgeInsets.only(top: iconOffset),
        child: ImageIcon(AssetImage(asset), color: color, size: iconSize),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(width: 1.0, color: borderColor)),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (i) => _onTap(context, i),
        backgroundColor: backgroundColor,
        selectedItemColor: selectedColor,
        unselectedItemColor: unselectedColor,
        iconSize: iconSize,
        selectedLabelStyle: TextStyle(fontSize: bigText ? 14 : 12),
        unselectedLabelStyle: TextStyle(fontSize: bigText ? 14 : 12),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: [
          BottomNavigationBarItem(
            icon: _navIcon('assets/lupa.png', unselectedColor),
            activeIcon: _navIcon('assets/lupa.png', selectedColor),
            label: 'search',
          ),
          BottomNavigationBarItem(
            icon: _navIcon('assets/heart.png', unselectedColor),
            activeIcon: _navIcon('assets/heart.png', selectedColor),
            label: 'liked',
          ),
          BottomNavigationBarItem(
            icon: _navIcon('assets/user.png', unselectedColor),
            activeIcon: _navIcon('assets/user.png', selectedColor),
            label: 'profile',
          ),
        ],
      ),
    );
  }
}
