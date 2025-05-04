import 'package:flutter/material.dart';

class AppColors {
  AppColors._();
  static const Color color1 = Color.fromARGB(255, 239, 83, 80);
  static const Color color1Dark = Color.fromARGB(255, 239, 83, 80);
  static const Color color1High = Color.fromARGB(255, 255, 0, 0);
  static const Color color1DarkHigh = Color.fromARGB(255, 255, 0, 0);

  static const Color colorText = Color.fromARGB(255, 15, 15, 15);
  static const Color colorTextDark = Color.fromARGB(255, 240, 240, 240);
  static const Color colorTextHigh = Colors.black;
  static const Color colorTextDarkHigh = Colors.white;

  static const Color colorTextField = Color.fromARGB(255, 15, 15, 15);
  static const Color colorTextFieldDark = Color.fromARGB(255, 240, 240, 240);
  static const Color colorTextFieldHigh = Colors.black;
  static const Color colorTextFieldDarkHigh = Colors.white;

  static const Color colorBg             = Color.fromARGB(255, 240, 240, 240); // Normal
  static const Color colorBgDark         = Color.fromARGB(255,  18,  18,  18); // Dark Mode
  static const Color colorBgHigh         = Colors.white;                       // Normal High-Contrast
  static const Color colorBgDarkHigh     = Colors.black;                       // Dark Mode High-Contrast

  static const Color colorInputBg        = Color.fromARGB(255, 255, 255, 255); // Normal
  static const Color colorInputBgDark    = Color.fromARGB(255,  30,  30,  30); // Dark Mode
  static const Color colorInputBgHigh    = Color.fromARGB(255, 230, 230, 230); // Normal High-Contrast
  static const Color colorInputBgDarkHigh= Color.fromARGB(255,  40,  40,  40); // Dark Mode High-Contrast

  static const Color colorHint           = Color.fromARGB(255, 153, 153, 153); // 50% black
  static const Color colorHintDark       = Color.fromARGB(255, 153, 153, 153); // 60% white
  static const Color colorHintHigh       = Color.fromARGB(255, 0, 0, 0); // 87% black
  static const Color colorHintDarkHigh   = Color.fromARGB(222, 255, 255, 255);

  static const Color colorButtonText     = Color.fromARGB(255, 240, 240, 240);
  static const Color colorButtonTextDark = Color.fromARGB(255, 240, 240, 240);
  static const Color colorButtonTextHigh = Color.fromARGB(255, 255, 255, 255);
  static const Color colorButtonTextDarkHigh = Color.fromARGB(255, 255, 255, 255);
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
