import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'bottom_navbar.dart';
import 'app_settings.dart';

class SuccessfulAccommodationScreen extends StatelessWidget {
  SuccessfulAccommodationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final highContrast = settings.highContrast;
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    final backgroundColor =
        highContrast
            ? (isDark ? Colors.black : Colors.white)
            : (isDark ? const Color(0xFF121212) : Colors.grey[300]);

    final textColor =
        highContrast
            ? (isDark ? Colors.white : Colors.black)
            : (isDark ? Colors.white70 : Colors.black87);

    final iconColor =
        highContrast
            ? (isDark ? Colors.white : Colors.black)
            : (isDark ? Colors.white60 : Colors.black87);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        elevation: 0,
        title: Text("Accommodation Added",
          style: TextStyle(
            fontSize: 22,
            color: textColor,
            fontFamily: 'Helvetica',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 2),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.home, size: 80, color: iconColor),
              const SizedBox(height: 8),
              Icon(Icons.verified, size: 40, color: iconColor),
              const SizedBox(height: 20),
              Text(
                "Thank you for\nyour Accommodation!",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                "Your accommodation has been added, please check\nyour email for more information.",
                style: TextStyle(color: textColor.withOpacity(0.7)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
