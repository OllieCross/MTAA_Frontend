import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'bottom_navbar.dart';
import 'main.dart';
import 'accommondation_detail.dart';
import 'server_config.dart';
import 'package:provider/provider.dart';
import 'app_settings.dart';

class LikedScreen extends StatefulWidget {
  const LikedScreen({super.key});

  @override
  State<LikedScreen> createState() => _LikedScreenState();
}

class _LikedScreenState extends State<LikedScreen> {
  List<dynamic> likedAccommodations = [];
  String? jwtToken = globalToken;

  @override
  void initState() {
    super.initState();
    _loadLiked();
  }

  Future<void> _loadLiked() async {
    final token = jwtToken;
    final url = Uri.parse('http://$serverIp:$serverPort/liked-accommodations');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (!mounted) return;
      setState(() {
        likedAccommodations = data['liked_accommodations'];
      });
    }
  }

  Future<void> _toggleLike(int aid) async {
    final token = jwtToken;
    final response = await http.post(
      Uri.parse('http://$serverIp:$serverPort/like_dislike'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'aid': aid}),
    );

    if (response.statusCode == 200) {
      final message = jsonDecode(response.body)['message'];
      if (message == 'Unliked accommodation') {
        if (!mounted) return;
        setState(() {
          likedAccommodations.removeWhere((item) => item['aid'] == aid);
        });
      }
    }
  }

  Widget _buildImage(int aid) {
    final imageUrl =
        'http://$serverIp:$serverPort/accommodations/$aid/image/1';
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      height: 180,
      width: double.infinity,
      headers: jwtToken != null ? {'Authorization': 'Bearer $jwtToken'} : {},
      errorBuilder: (context, error, stackTrace) =>
          const SizedBox(height: 180, child: Placeholder()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final highContrast = settings.highContrast;
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    final backgroundColor = highContrast
        ? (isDark ? Colors.black : Colors.white)
        : (isDark ? const Color(0xFF121212) : Colors.grey[300]);
    final textColor = highContrast
        ? (isDark ? const Color.fromARGB(255, 150, 150, 150) : Colors.black)
        : (isDark ? const Color.fromARGB(255, 150, 150, 150) : Colors.black87);
    final boxColor = highContrast
        ? (isDark ? Colors.grey[900] : Colors.white)
        : (isDark ? Colors.grey[800] : Colors.grey[200]);

    return Scaffold(
      backgroundColor: backgroundColor,
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
      body: SafeArea(
        child: likedAccommodations.isEmpty
            ? Center(
                child: Text(
                  "No liked accommodations found.",
                  style: TextStyle(color: textColor),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.favorite_border, size: 48, color: textColor),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        "Your likes",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: likedAccommodations.length,
                      itemBuilder: (context, index) {
                        final item = likedAccommodations[index];

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    AccommodationDetailScreen(aid: item['aid']),
                              ),
                            );
                          },
                          child: Card(
                            color: boxColor,
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(10)),
                                      child: _buildImage(item['aid']),
                                    ),
                                    Positioned(
                                      top: 10,
                                      right: 10,
                                      child: IconButton(
                                        icon: const Icon(Icons.favorite,
                                            color: Colors.red),
                                        onPressed: () =>
                                            _toggleLike(item['aid']),
                                      ),
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['location'],
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: textColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${item['price_per_night']} € / Night',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: textColor,
                                        ),
                                      ),
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
