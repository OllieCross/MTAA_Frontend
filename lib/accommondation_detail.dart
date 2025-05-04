import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'main.dart';
import 'gallery.dart';
import 'reserve_formular.dart';
import 'server_config.dart';
import 'app_settings.dart';
import 'dart:convert';

typedef Json = Map<String, dynamic>;

class AccommodationDetailScreen extends StatefulWidget {
  final int aid;

  const AccommodationDetailScreen({super.key, required this.aid});

  @override
  State<AccommodationDetailScreen> createState() =>
      _AccommodationDetailScreenState();
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
        imageIndices = [1, 2, 3];
      });
    }
  }

  Image buildImage(int index) {
    return Image.network(
      'http://$serverIp:$serverPort/accommodations/${widget.aid}/image/$index',
      fit: BoxFit.cover,
      headers: jwtToken != null ? {'Authorization': 'Bearer $jwtToken'} : {},
      errorBuilder:
          (context, error, stackTrace) =>
              const Center(child: Icon(Icons.broken_image)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final highContrast = settings.highContrast;
    final bigText = settings.bigText;
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final isTablet = MediaQuery.of(context).size.width >= 600;

    if (data == null) {
      return Scaffold(
        backgroundColor:
            highContrast
                ? (isDark ? AppColors.colorBgDarkHigh : AppColors.colorBgHigh)
                : (isDark ? AppColors.colorBgDark : AppColors.colorBg),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    Widget infoSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          data!['location'],
          style: TextStyle(
            fontSize: bigText ? 24 : 18,
            fontWeight: bigText ? FontWeight.bold : FontWeight.normal,
            color:
                highContrast
                    ? (isDark
                        ? AppColors.colorTextDarkHigh
                        : AppColors.colorTextHigh)
                    : (isDark ? AppColors.colorTextDark : AppColors.colorText),
            fontFamily: 'Helvetica',
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${data!['price_per_night']} € / night',
          style: TextStyle(
            fontSize: bigText ? 20 : 16,
            fontWeight: bigText ? FontWeight.bold : FontWeight.normal,
            color:
                highContrast
                    ? (isDark
                        ? AppColors.colorTextDarkHigh
                        : AppColors.colorTextHigh)
                    : (isDark ? AppColors.colorTextDark : AppColors.colorText),
            fontFamily: 'Helvetica',
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Max guests: ${data!['max_guests']}',
          style: TextStyle(
            fontSize: bigText ? 20 : 16,
            fontWeight: bigText ? FontWeight.bold : FontWeight.normal,
            color:
                highContrast
                    ? (isDark
                        ? AppColors.colorTextDarkHigh
                        : AppColors.colorTextHigh)
                    : (isDark ? AppColors.colorTextDark : AppColors.colorText),
            fontFamily: 'Helvetica',
          ),
        ),
        const SizedBox(height: 10),
        if (data!['description'] != null)
          Text(
            data!['description'],
            textAlign: TextAlign.justify,
            style: TextStyle(
              fontSize: bigText ? 20 : 16,
              fontWeight: bigText ? FontWeight.bold : FontWeight.normal,
              color:
                  highContrast
                      ? (isDark
                          ? AppColors.colorTextDarkHigh
                          : AppColors.colorTextHigh)
                      : (isDark
                          ? AppColors.colorTextDark
                          : AppColors.colorText),
              fontFamily: 'Helvetica',
            ),
          ),
        const Divider(height: 30),
        Text(
          'Owner: ${data!['owner_email']}',
          style: TextStyle(
            fontSize: bigText ? 20 : 16,
            color:
                highContrast
                    ? (isDark
                        ? AppColors.colorTextDarkHigh
                        : AppColors.colorTextHigh)
                    : (isDark ? AppColors.colorTextDark : AppColors.colorText),
            fontFamily: 'Helvetica',
            fontWeight: bigText ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  highContrast
                      ? (isDark
                          ? AppColors.color1DarkHigh
                          : AppColors.color1High)
                      : (isDark ? AppColors.color1Dark : AppColors.color1),
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
            child: Text(
              "Make a Reservation",
              style: TextStyle(
                fontSize: bigText ? 20 : 16,
                color:
                    highContrast
                        ? AppColors.colorTextDarkHigh
                        : AppColors.colorTextDark,
                fontFamily: 'Helvetica',
                fontWeight: bigText ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ],
    );

    Widget imageSection = ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 200,
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child:
                  imageIndices.isNotEmpty
                      ? buildImage(imageIndices[0])
                      : const Placeholder(),
            ),
            const SizedBox(width: 2),
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  Expanded(
                    child:
                        imageIndices.length > 1
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
                          bottom: 6,
                          right: 10,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  highContrast
                                      ? (isDark
                                          ? AppColors.colorBgDarkHigh
                                          : AppColors.colorBgHigh)
                                      : (isDark
                                          ? AppColors.colorBgDark
                                          : AppColors.colorBg),
                              foregroundColor:
                                  highContrast
                                      ? (isDark
                                          ? AppColors.colorTextDarkHigh
                                          : AppColors.colorTextHigh)
                                      : (isDark
                                          ? AppColors.colorTextDark
                                          : AppColors.colorText),
                              padding: EdgeInsets.symmetric(
                                horizontal: bigText ? 12 : 8,
                                vertical: bigText ? 8 : 6,
                              ),
                              minimumSize: Size(
                                bigText ? 120 : 80,
                                bigText ? 40 : 30,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: Icon(
                              Icons.photo_library,
                              size: bigText ? 24 : 20,
                            ),
                            label: Text(
                              "Gallery",
                              style: TextStyle(
                                fontSize: bigText ? 16 : 14,
                                fontFamily: 'Helvetica',
                                fontWeight:
                                    bigText
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => GalleryScreen(
                                        aid: widget.aid,
                                        images: imageIndices,
                                      ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      backgroundColor:
          highContrast
              ? (isDark ? AppColors.colorBgDarkHigh : AppColors.colorBgHigh)
              : (isDark ? AppColors.colorBgDark : AppColors.colorBg),
      appBar: AppBar(
        backgroundColor:
            highContrast
                ? (isDark ? AppColors.colorBgDarkHigh : AppColors.colorBgHigh)
                : (isDark ? AppColors.colorBgDark : AppColors.colorBg),
        foregroundColor:
            highContrast
                ? (isDark
                    ? AppColors.colorTextDarkHigh
                    : AppColors.colorTextHigh)
                : (isDark ? AppColors.colorTextDark : AppColors.colorText),
        elevation: 0,
        title: Text(data!['name']),
        titleTextStyle: TextStyle(
          fontSize: bigText ? 24 : 20,
          fontWeight: bigText ? FontWeight.bold : FontWeight.normal,
          color:
              highContrast
                  ? (isDark
                      ? AppColors.colorTextDarkHigh
                      : AppColors.colorTextHigh)
                  : (isDark ? AppColors.colorTextDark : AppColors.colorText),
          fontFamily: 'Helvetica',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child:
            isTablet
                ? Center(
                  child: FractionallySizedBox(
                    widthFactor: 0.8,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: infoSection),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (var idx in imageIndices) ...[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: SizedBox(
                                    height: 200,
                                    child: buildImage(idx),
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      highContrast
                                          ? (isDark
                                              ? AppColors.colorBgDarkHigh
                                              : AppColors.colorBgHigh)
                                          : (isDark
                                              ? AppColors.colorBgDark
                                              : AppColors.colorBg),
                                  foregroundColor:
                                      highContrast
                                          ? (isDark
                                              ? AppColors.colorTextDarkHigh
                                              : AppColors.colorTextHigh)
                                          : (isDark
                                              ? AppColors.colorTextDark
                                              : AppColors.colorText),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: bigText ? 12 : 8,
                                    vertical: bigText ? 8 : 6,
                                  ),
                                  minimumSize: Size(
                                    bigText ? 120 : 80,
                                    bigText ? 40 : 30,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                icon: Icon(
                                  Icons.photo_library,
                                  size: bigText ? 24 : 20,
                                ),
                                label: Text(
                                  "Gallery",
                                  style: TextStyle(
                                    fontSize: bigText ? 16 : 14,
                                    fontFamily: 'Helvetica',
                                    fontWeight:
                                        bigText
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => GalleryScreen(
                                            aid: widget.aid,
                                            images: imageIndices,
                                          ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [imageSection, infoSection],
                ),
      ),
    );
  }
}
