import 'package:flutter/material.dart';
import 'main.dart'; // pre globalToken
import 'server_config.dart';

class GalleryScreen extends StatelessWidget {
  final List<int> images; // indexy obrázkov (napr. [1, 2, 3])
  final int aid;

  const GalleryScreen({super.key, required this.images, required this.aid});

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final String? jwtToken = globalToken;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(title: const Text('Gallery')),
      body: GridView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: images.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemBuilder: (context, index) {
          final imageUrl =
              'http://$serverIp:$serverPort/accommodations/$aid/image/${images[index]}';

          return Image.network(
            imageUrl,
            fit: BoxFit.cover,
            headers: jwtToken != null
                ? {'Authorization': 'Bearer $jwtToken'}
                : {},
            errorBuilder: (context, error, stackTrace) =>
                const Placeholder(),
          );
        },
      ),
    );
  }
}