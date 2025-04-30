import 'package:flutter/material.dart';
import 'main_screen_accommodations.dart';
import 'liked.dart';
import 'profile.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color selectedColor = isDark ? Colors.white : Colors.black;
    final Color unselectedColor = isDark ? Colors.white70 : Colors.grey;
    final Color bgColor = isDark ? Colors.black : Colors.white;

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) => _onTap(context, index),
      selectedItemColor: selectedColor,
      unselectedItemColor: unselectedColor,
      backgroundColor: bgColor,
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
