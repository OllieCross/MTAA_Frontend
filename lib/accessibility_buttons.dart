import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_settings.dart';

class AccessibilityButtons extends StatelessWidget {
  const AccessibilityButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();

    final isBigText = settings.textScaleFactor > 1.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () {
              if (isBigText) {
                settings.setSmallText();
              } else {
                settings.setBigText();
              }
            },
            child: Text(isBigText ? 'Text MALÝ' : 'Text VEĽKÝ'),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: settings.toggleContrast,
            child: Text(
              settings.highContrast ? 'Kontrast Normálny' : 'Kontrast Vysoký',
            ),
          ),
        ],
      ),
    );
  }
}
