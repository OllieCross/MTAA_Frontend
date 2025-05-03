import 'package:flutter/material.dart';
import 'main.dart';
import 'app_settings.dart';

class ReigsterSuccesful extends StatelessWidget {
  const ReigsterSuccesful({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.colorBgDark : AppColors.colorBg,
      appBar: AppBar(
        title: const Text(
          'Registration Successful',
          style: TextStyle(
            fontSize: 24,
            fontFamily: 'Helvetica',
            fontWeight: FontWeight.normal,
          ),
        ), backgroundColor: isDark ? AppColors.colorBgDark : AppColors.colorBg,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 80,
              color:
                  isDark
                      ? AppColors.colorTextDarkHigh
                      : AppColors.colorTextHigh,
            ),
            const SizedBox(height: 20),
            Text(
              'You have registered successfully!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.normal,
                fontFamily: 'Helvetica',
                color:
                    isDark
                        ? AppColors.colorTextDarkHigh
                        : AppColors.colorTextHigh,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => LoginScreen()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(300, 50),
                elevation: 6,
                shadowColor: const Color.fromARGB(165, 0, 0, 0),
                backgroundColor:
                    isDark ? AppColors.color1Dark : AppColors.color1,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              child: Text(
                'Continue',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.normal,
                  fontFamily: 'Helvetica',
                  color: AppColors.colorTextDarkHigh,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
