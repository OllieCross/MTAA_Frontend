import 'package:flutter/foundation.dart';

class AppSettings extends ChangeNotifier {
  double _textScaleFactor = 1.0;     // 1.0 = malý, 1.4 = veľký
  bool   _highContrast     = false;  // false = normálny, true = vysoký

  double get textScaleFactor => _textScaleFactor;
  bool   get highContrast     => _highContrast;

  void setSmallText()  => _updateTextScale(1.0);
  void setBigText()    => _updateTextScale(1.4);

  void toggleContrast() {
    _highContrast = !_highContrast;
    notifyListeners();
  }

  // ---------------- private ----------------
  void _updateTextScale(double value) {
    if (value == _textScaleFactor) return;
    _textScaleFactor = value;
    notifyListeners();
  }
}
