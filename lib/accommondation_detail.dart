import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'main.dart';
import 'gallery.dart';
import 'reserve_formular.dart';

class AccommodationDetailScreen extends StatefulWidget {
  final int aid;

  const AccommodationDetailScreen({super.key, required this.aid});

  @override
  State<AccommodationDetailScreen> createState() => _AccommodationDetailScreenState();
}

class _AccommodationDetailScreenState extends State<AccommodationDetailScreen> {
  Map<String, dynamic>? data;
  String? jwtToken = globalToken;

  @override
  void initState() {
    super.initState();
    fetchAccommodationDetail();
  }

  Future<void> fetchAccommodationDetail() async {
    final response = await http.get(
      Uri.parse('http://localhost:5000/accommodation/${widget.aid}'),
      headers: {
        'Content-Type': 'application/json',
        if (jwtToken != null) 'Authorization': 'Bearer $jwtToken',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        data = jsonDecode(response.body)['accommodation'];
      });
    } else {
      print('Error: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (data == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final imagesBase64 = data!['images_base64'] as List;
    final List<Image> images = imagesBase64.map((b64) {
      try {
        final cleaned = b64.replaceAll(RegExp(r'\s+'), '');
        return Image.memory(base64Decode(cleaned), fit: BoxFit.cover);
      } catch (e) {
        print("Base64 decode error: $e");
        return const Image(image: AssetImage('assets/images/placeholder.jpg'));
      }
    }).toList();

    return Scaffold(
      appBar: AppBar(title: Text(data!['name'])),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gallery collage + button
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                height: 200,
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: images.isNotEmpty ? images[0] : const Placeholder(),
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          Expanded(
                            child: images.length > 1 ? images[1] : const Placeholder(),
                          ),
                          const SizedBox(height: 2),
                          Expanded(
                            child: Stack(
                              children: [
                                images.length > 2 ? images[2] : const Placeholder(),
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
                                          builder: (_) => GalleryScreen(images: imagesBase64.cast<String>()),
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
            Text('Rating: X ${data!['average_rating']}'),
            Text('Owner: ${data!['owner_email']}'),
            const SizedBox(height: 20), // <- tu je ten správne umiestnený SizedBox
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
