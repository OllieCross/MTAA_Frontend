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
        nextScreen = MainScreenAccommodations();
        break;
      case 1:
        nextScreen = LikedScreen();
        break;
      case 2:
        nextScreen = ProfileScreen();
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
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) => _onTap(context, index),
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.grey,
      backgroundColor: Colors.white,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      items: const [
        BottomNavigationBarItem(
          icon: ImageIcon(AssetImage('assets/lupa.png')), // lupa.png
          label: 'search',
        ),
        BottomNavigationBarItem(
          icon: ImageIcon(AssetImage('assets/heart.png')), // srdce
          label: 'liked',
        ),
        BottomNavigationBarItem(
          icon: ImageIcon(AssetImage('assets/user.png')), // profil
          label: 'profile',
        ),
      ],
    );
  }
}
