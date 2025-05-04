import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'main.dart';
import 'server_config.dart';
import 'app_settings.dart';

class GalleryScreen extends StatelessWidget {
  final List<int> images;
  final int aid;

  const GalleryScreen({super.key, required this.images, required this.aid});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final highContrast = settings.highContrast;
    final bigText = settings.bigText;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = highContrast
        ? (isDark ? AppColors.colorBgDarkHigh : AppColors.colorBgHigh)
        : (isDark ? AppColors.colorBgDark : AppColors.colorBg);
    final textColor = highContrast
        ? (isDark ? AppColors.colorTextDarkHigh : AppColors.colorTextHigh)
        : (isDark ? AppColors.colorTextDark : AppColors.colorText);
    final String? jwtToken = globalToken;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        elevation: 0,
        title: Text(
          'Gallery',
          style: TextStyle(
            fontSize: bigText ? 22 : 18,
            fontWeight: bigText ? FontWeight.bold : FontWeight.normal,
            color: textColor,
            fontFamily: 'Helvetica',
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final crossCount = constraints.maxWidth > 600 ? 2 : 1;
          return GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
            itemCount: images.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossCount,
              crossAxisSpacing: 32,
              mainAxisSpacing: 32,
            ),
            itemBuilder: (context, index) {
              final imageUrl =
                  'http://$serverIp:$serverPort/accommodations/$aid/image/${images[index]}';
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black54 : Colors.black26,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    headers: jwtToken != null ? {'Authorization': 'Bearer $jwtToken'} : {},
                    errorBuilder: (context, error, stackTrace) => const Placeholder(),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
