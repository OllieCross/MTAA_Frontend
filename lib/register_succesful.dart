import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'main.dart';
import 'app_settings.dart';

class RegisterSuccesful extends StatelessWidget {
  const RegisterSuccesful({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = context.watch<AppSettings>();
    final highContrast = settings.highContrast;
    final bigText = settings.bigText;

    final bgColor =
        highContrast
            ? (isDark ? AppColors.colorBgDarkHigh : AppColors.colorBgHigh)
            : (isDark ? AppColors.colorBgDark : AppColors.colorBg);
    final textColor =
        highContrast
            ? (isDark ? AppColors.colorTextDarkHigh : AppColors.colorTextHigh)
            : (isDark ? AppColors.colorTextDark : AppColors.colorText);
    final buttonBg =
        highContrast
            ? (isDark ? AppColors.color1DarkHigh : AppColors.color1High)
            : (isDark ? AppColors.color1Dark : AppColors.color1);
    final buttonTextColor =
        highContrast
            ? (isDark
                ? AppColors.colorButtonTextDarkHigh
                : AppColors.colorButtonTextHigh)
            : (isDark
                ? AppColors.colorButtonTextDark
                : AppColors.colorButtonText);
    final headingSize = bigText ? 30.0 : 24.0;
    final bodySize = bigText ? 20.0 : 18.0;
    final iconSize = bigText ? 100.0 : 80.0;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: Text(
          'Registration Successful',
          style: TextStyle(
            fontSize: headingSize,
            fontFamily: 'Helvetica',
            fontWeight: FontWeight.normal,
            color: textColor,
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 600) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: iconSize,
                    color: textColor,
                  ),
                  SizedBox(height: bigText ? 24 : 20),
                  Text(
                    'You have registered successfully!',
                    style: TextStyle(
                      fontSize: bodySize,
                      fontWeight: FontWeight.normal,
                      fontFamily: 'Helvetica',
                      color: textColor,
                    ),
                  ),
                  SizedBox(height: bigText ? 24 : 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(bigText ? 320 : 300, bigText ? 56 : 50),
                      elevation: 6,
                      shadowColor: const Color.fromARGB(165, 0, 0, 0),
                      backgroundColor: buttonBg,
                      padding: EdgeInsets.symmetric(
                        horizontal: bigText ? 24 : 20,
                        vertical: bigText ? 14 : 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: bodySize,
                        fontFamily: 'Helvetica',
                        fontWeight: FontWeight.normal,
                        color: buttonTextColor,
                      ),
                    ),
                  ),
                ],
              ),
            );
          } else {
            return Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Text(
                        'Registration Successful',
                        style: TextStyle(
                          fontSize: headingSize,
                          fontFamily: 'Helvetica',
                          fontWeight:
                              bigText ? FontWeight.bold : FontWeight.normal,
                          color: textColor,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: iconSize,
                          color: textColor,
                        ),
                        SizedBox(height: bigText ? 24 : 20),
                        Text(
                          'You have registered successfully!',
                          style: TextStyle(
                            fontSize: bodySize,
                            fontWeight:
                                bigText ? FontWeight.bold : FontWeight.normal,
                            fontFamily: 'Helvetica',
                            color: textColor,
                          ),
                        ),
                        SizedBox(height: bigText ? 24 : 20),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                              (route) => false,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(
                              bigText ? 320 : 300,
                              bigText ? 56 : 50,
                            ),
                            elevation: 6,
                            shadowColor: const Color.fromARGB(165, 0, 0, 0),
                            backgroundColor: buttonBg,
                            padding: EdgeInsets.symmetric(
                              horizontal: bigText ? 24 : 20,
                              vertical: bigText ? 14 : 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Continue',
                            style: TextStyle(
                              fontSize: bodySize,
                              fontFamily: 'Helvetica',
                              fontWeight:
                                  bigText ? FontWeight.bold : FontWeight.normal,
                              color: buttonTextColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
