import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'bottom_navbar.dart';
import 'main.dart';
import 'accommondation_detail.dart';
import 'server_config.dart';
import 'package:provider/provider.dart';
import 'app_settings.dart';
import 'dart:async';
import 'offline_sync_repository.dart';

class SyncToast extends StatefulWidget {
  const SyncToast({super.key, required this.child, this.onSynced});
  final Widget child;
  final VoidCallback? onSynced;   // optional refresh hook

  @override
  State<SyncToast> createState() => _SyncToastState();
}

class _SyncToastState extends State<SyncToast> {
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _sub = OfflineSyncRepository.instance.uploadSuccess.listen((draft) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${draft.name}" synced successfully!'),
          duration: const Duration(seconds: 2),
        ),
      );
      widget.onSynced?.call();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

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
    final imageUrl = 'http://$serverIp:$serverPort/accommodations/$aid/image/1';
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      height: 180,
      width: double.infinity,
      headers: jwtToken != null ? {'Authorization': 'Bearer $jwtToken'} : {},
      errorBuilder: (_, __, ___) => const SizedBox(height: 180, child: Placeholder()),
    );
  }

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
    final boxColor = highContrast
        ? (isDark ? const Color.fromARGB(255, 30, 30, 30) : AppColors.colorBgHigh)
        : (isDark ? Colors.grey[800]! : Colors.grey[200]!);

    final headerStyle = TextStyle(
      fontSize: bigText ? 24 : 20,
      fontWeight: bigText ? FontWeight.bold : FontWeight.normal,
      color: textColor,
      fontFamily: 'Helvetica',
    );
    final captionStyle = TextStyle(
      fontSize: bigText ? 18 : 16,
      fontWeight: bigText ? FontWeight.bold : FontWeight.normal,
      color: textColor,
      fontFamily: 'Helvetica',
    );
    final itemTitleStyle = TextStyle(
      fontSize: bigText ? 18 : 16,
      fontWeight: bigText ? FontWeight.bold : FontWeight.normal,
      color: textColor,
      fontFamily: 'Helvetica',
    );
    final priceStyle = TextStyle(
      fontSize: bigText ? 16 : 14,
      fontWeight: bigText ? FontWeight.bold : FontWeight.normal,
      color: textColor,
      fontFamily: 'Helvetica',
    );

    final heartColor = highContrast
        ? (isDark ? AppColors.color1High : AppColors.color1High)
        : AppColors.color1;

    return Scaffold(
      backgroundColor: backgroundColor,
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
      body: SafeArea(
        child: likedAccommodations.isEmpty
            ? Center(
                child: Text(
                  "No liked accommodations found.",
                  style: captionStyle,
                ),
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 600) {
                    return Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.favorite_border, size: bigText ? 56 : 48, color: textColor),
                              const SizedBox(height: 8),
                              Text(
                                "Your likes",
                                style: headerStyle,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: likedAccommodations.map((item) {
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
                                    color: boxColor,
                                    margin: const EdgeInsets.only(bottom: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        ClipRRect(
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                                          child: _buildImage(item['aid']),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      item['location'],
                                                      style: itemTitleStyle,
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: Icon(Icons.favorite, color: heartColor),
                                                    onPressed: () => _toggleLike(item['aid']),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${item['price_per_night']} € / Night',
                                                style: priceStyle,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    );
                  } else {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(Icons.favorite_border, size: bigText ? 56 : 48, color: textColor),
                          const SizedBox(height: 8),
                          Text(
                            "Your likes",
                            style: headerStyle,
                          ),
                          const SizedBox(height: 24),
                          Column(
                            children: likedAccommodations.map((item) {
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
                                  color: boxColor,
                                  margin: const EdgeInsets.only(bottom: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                                        child: _buildImage(item['aid']),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    item['location'],
                                                    style: itemTitleStyle,
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: Icon(Icons.favorite, color: heartColor),
                                                  onPressed: () => _toggleLike(item['aid']),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${item['price_per_night']} € / Night',
                                              style: priceStyle,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
      ),
    );
  }
}
