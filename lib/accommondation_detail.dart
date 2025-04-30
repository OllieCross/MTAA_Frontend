import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'main.dart';
import 'gallery.dart';
import 'reserve_formular.dart';
import 'server_config.dart';
import 'dart:convert';

typedef Json = Map<String, dynamic>;

class AccommodationDetailScreen extends StatefulWidget {
  final int aid;

  const AccommodationDetailScreen({super.key, required this.aid});

  @override
  State<AccommodationDetailScreen> createState() => _AccommodationDetailScreenState();
}

class _AccommodationDetailScreenState extends State<AccommodationDetailScreen> {
  Json? data;
  List<int> imageIndices = [];
  String? jwtToken = globalToken;

  @override
  void initState() {
    super.initState();
    fetchAccommodationDetail();
  }

  Future<void> fetchAccommodationDetail() async {
    try {
      final response = await http.get(
        Uri.parse('http://$serverIp:$serverPort/accommodation/${widget.aid}'),
        headers: {
          'Content-Type': 'application/json',
          if (jwtToken != null) 'Authorization': 'Bearer $jwtToken',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (!mounted) return;
          setState(() {
            data = Map<String, dynamic>.from(decoded['accommodation']);
            imageIndices = [1, 2, 3]; // hardcoded na 3 obrázky
          });
      } else {
        print('Server error: ${response.body}');
      }
    } catch (e) {
      print('Network error: $e');
    }
  }

  Image buildImage(int index) {
    return Image.network(
      'http://$serverIp:$serverPort/accommodations/${widget.aid}/image/$index',
      fit: BoxFit.cover,
      headers: jwtToken != null ? {'Authorization': 'Bearer $jwtToken'} : {},
      errorBuilder: (context, error, stackTrace) =>
          const Center(child: Icon(Icons.broken_image)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    if (data == null) {
      return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(data!['name'])),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                height: 200,
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: imageIndices.isNotEmpty
                          ? buildImage(imageIndices[0])
                          : const Placeholder(),
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          Expanded(
                            child: imageIndices.length > 1
                                ? buildImage(imageIndices[1])
                                : const Placeholder(),
                          ),
                          const SizedBox(height: 2),
                          Expanded(
                            child: Stack(
                              children: [
                                imageIndices.length > 2
                                    ? buildImage(imageIndices[2])
                                    : const Placeholder(),
                                Positioned(
                                  bottom: 8,
                                  left: 8,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    icon: const Icon(Icons.photo_library),
                                    label: const Text("Gallery"),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => GalleryScreen(aid: widget.aid, images: imageIndices),
                                        ),
                                      );
                                    },
                                  ),
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(data!['location'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('${data!['price_per_night']} € / night'),
            const SizedBox(height: 10),
            Text('Max guests: ${data!['max_guests']}'),
            const SizedBox(height: 10),
            if (data!['description'] != null)
              Text(data!['description'], textAlign: TextAlign.justify),
            const Divider(height: 30),
            Text('Owner: ${data!['owner_email']}'),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReserveFormularScreen(accommodation: data!),
                    ),
                  );
                },
                child: const Text(
                  "Make a Reservation",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}