import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'bottom_navbar.dart';
import 'main.dart';
import 'accommondation_detail.dart';

class LikedScreen extends StatefulWidget {
  const LikedScreen({super.key});

  @override
  State<LikedScreen> createState() => _LikedScreenState();
}

class _LikedScreenState extends State<LikedScreen> {
  List<dynamic> likedAccommodations = [];

  @override
  void initState() {
    super.initState();
    _loadLiked();
  }

  Future<void> _loadLiked() async {
    final token = globalToken;
    final url = Uri.parse('http://127.0.0.1:5000/liked-accommodations');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          likedAccommodations = data['liked_accommodations'];
        });
      } else {
        print('Failed to fetch liked accommodations: ${response.body}');
      }
    } catch (e) {
      print('Error fetching liked accommodations: $e');
    }
  }

  Future<void> _toggleLike(int aid) async {
    final token = globalToken;
    final response = await http.post(
      Uri.parse('http://127.0.0.1:5000/like_dislike'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'aid': aid}),
    );

    if (response.statusCode == 200) {
      final message = jsonDecode(response.body)['message'];
      if (message == 'Unliked accommodation') {
        setState(() {
          likedAccommodations.removeWhere((item) => item['aid'] == aid);
        });
      }
    } else {
      print('Like toggle error: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
      body: SafeArea(
        child: likedAccommodations.isEmpty
            ? const Center(child: Text("No liked accommodations found."))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.favorite_border, size: 48),
                    const SizedBox(height: 8),
                    const Center(
                      child: Text(
                        "Your likes",
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: likedAccommodations.length,
                      itemBuilder: (context, index) {
                        final item = likedAccommodations[index];
                        final imageBase64 = item['image_base64'];
                        final image = imageBase64 != null
                            ? Image.memory(
                                base64Decode(imageBase64.replaceAll(RegExp(r'\s+'), '')),
                                fit: BoxFit.cover,
                                height: 180,
                                width: double.infinity,
                              )
                            : const SizedBox(height: 180, child: Placeholder());

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AccommodationDetailScreen(aid: item['aid']),
                              ),
                            );
                          },
                          child: Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                                      child: image,
                                    ),
                                    Positioned(
                                      top: 10,
                                      right: 10,
                                      child: IconButton(
                                        icon: const Icon(Icons.favorite, color: Colors.red),
                                        onPressed: () => _toggleLike(item['aid']),
                                      ),
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item['location'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                                      const SizedBox(height: 4),
                                      Text('${item['price_per_night']} € / Night', style: const TextStyle(fontSize: 14)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
