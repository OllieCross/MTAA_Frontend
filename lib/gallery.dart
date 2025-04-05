import 'dart:convert';
import 'package:flutter/material.dart';

class GalleryScreen extends StatelessWidget {
  final List<String> images;

  const GalleryScreen({super.key, required this.images});

  @override
  Widget build(BuildContext context) {
    final decodedImages = images.map((b64) {
      try {
        final cleaned = b64.replaceAll(RegExp(r'\s+'), '');
        return Image.memory(base64Decode(cleaned), fit: BoxFit.cover);
      } catch (e) {
        return const Placeholder();
      }
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Gallery')),
      body: GridView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: decodedImages.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemBuilder: (context, index) => decodedImages[index],
      ),
    );
  }
}
