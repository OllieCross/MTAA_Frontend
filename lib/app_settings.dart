import 'package:flutter/material.dart';

class AppColors {
  AppColors._();
  static const Color color1 = Colors.red;
  static const Color color1Dark = Colors.red;
  static const Color color1High = Color.fromARGB(255, 255, 0, 0);
  static const Color color1DarkHigh = Color.fromARGB(255, 255, 0, 0);

  static const Color colorBg = Color.fromARGB(255, 233, 233, 233);
  static const Color colorBgDark = Color.fromARGB(255, 17, 17, 17);
  static const Color colorBgHigh = Colors.white;
  static const Color colorBgDarkHigh = Colors.black;

  static const Color colorText = Color.fromARGB(255, 15, 15, 15);
  static const Color colorTextDark = Color.fromARGB(255, 240, 240, 240);
  static const Color colorTextHigh = Colors.black;
  static const Color colorTextDarkHigh = Colors.white;
}

class AppSettings extends ChangeNotifier {
  bool _bigText = false;
  bool _highContrast = false;

  bool get bigText => _bigText;
  bool get highContrast => _highContrast;

  void toggleContrast() {
    _highContrast = !_highContrast;
    notifyListeners();
  }

  void toggleText() {
    _bigText = !_bigText;
    notifyListeners();
  }
}
