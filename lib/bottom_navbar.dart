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
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    final backgroundColor = highContrast
        ? (isDark ? Colors.black : Colors.white)
        : (isDark ? const Color(0xFF121212) : Colors.grey[300]);

    final selectedColor = highContrast
        ? (isDark ? Colors.white : Colors.black)
        : (isDark ? Colors.white : Colors.black);

    final unselectedColor = highContrast
        ? (isDark ? Colors.grey[500]! : Colors.grey[700]!)
        : (isDark ? Colors.white70 : Colors.grey);

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) => _onTap(context, index),
      selectedItemColor: selectedColor,
      unselectedItemColor: unselectedColor,
      backgroundColor: backgroundColor,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      items: [
        BottomNavigationBarItem(
          icon: ImageIcon(
            const AssetImage('assets/lupa.png'),
            color: currentIndex == 0 ? selectedColor : unselectedColor,
          ),
          label: 'search',
        ),
        BottomNavigationBarItem(
          icon: ImageIcon(
            const AssetImage('assets/heart.png'),
            color: currentIndex == 1 ? selectedColor : unselectedColor,
          ),
          label: 'liked',
        ),
        BottomNavigationBarItem(
          icon: ImageIcon(
            const AssetImage('assets/user.png'),
            color: currentIndex == 2 ? selectedColor : unselectedColor,
          ),
          label: 'profile',
        ),
      ],
    );
  }
}
