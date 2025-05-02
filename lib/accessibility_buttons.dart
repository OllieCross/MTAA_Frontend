import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'app_settings.dart';

class AccessibilityButtons extends StatelessWidget {
  const AccessibilityButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Text size toggle
          Column(
            children: [
              const Icon(CupertinoIcons.textformat_size, size: 24),
              const SizedBox(height: 8),
              CupertinoSwitch(
                value: settings.bigText,
                onChanged: (_) => settings.toggleText(),
              ),
            ],
          ),

          // Contrast toggle
          Column(
            children: [
              const Icon(CupertinoIcons.circle_lefthalf_fill, size: 24),
              const SizedBox(height: 8),
              CupertinoSwitch(
                value: settings.highContrast,
                onChanged: (_) => settings.toggleContrast(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
