import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'search_results_screen.dart';
import 'main.dart';
import 'bottom_navbar.dart';
import 'accommondation_detail.dart';
import 'server_config.dart';
import 'package:geolocator/geolocator.dart';

class MainScreenAccommodations extends StatefulWidget {
  const MainScreenAccommodations({super.key});

  @override
  State<MainScreenAccommodations> createState() => _MainScreenAccommodationsState();
}

class _MainScreenAccommodationsState extends State<MainScreenAccommodations> {
  final TextEditingController locationController = TextEditingController();
  final TextEditingController guestController = TextEditingController();
  final ValueNotifier<DateTime?> dateFromNotifier = ValueNotifier(null);
  final ValueNotifier<DateTime?> dateToNotifier = ValueNotifier(null);

  List<dynamic> accommodations = [];
  String? jwtToken = globalToken;

  @override
  void initState() {
    super.initState();
    _loadInitialRecommendations();
  }

  Future<void> _loadInitialRecommendations() async {
      jwtToken = globalToken;
      final response = await http.get(
        Uri.parse('http://$serverIp:$serverPort/main-screen-accommodations'),
        headers: {
          'Content-Type': 'application/json',
          if (jwtToken != null) 'Authorization': 'Bearer $jwtToken',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final baseList = data['results'];
        if (!mounted) return;
        setState(() {
          accommodations = baseList.map((item) {
            return {
              ...item,
              'is_liked': item['is_liked'] ?? false,
            };
          }).toList();
        });
      }
  }

  Future<Uint8List?> fetchAccommodationImage(int aid) async {
      final response = await http.get(
        Uri.parse('http://$serverIp:$serverPort/accommodations/$aid/image/1'),
        headers: {
          if (jwtToken != null) 'Authorization': 'Bearer $jwtToken',
        },
      );
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        return null;
      }
    }

  Future<void> toggleLike(int aid, int index) async {
    final response = await http.post(
      Uri.parse('http://$serverIp:$serverPort/like_dislike'),
      headers: {
        'Content-Type': 'application/json',
        if (jwtToken != null) 'Authorization': 'Bearer $jwtToken',
      },
      body: jsonEncode({'aid': aid}),
    );
    if (response.statusCode == 200) {
      final message = jsonDecode(response.body)['message'];
      if (!mounted) return;
      setState(() {
        accommodations[index]['is_liked'] = message == 'Liked accommodation';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: locationController,
                        style: TextStyle(color: Theme.of(context).textTheme.bodyMedium!.color),
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.location_on_outlined, color: Theme.of(context).textTheme.bodyMedium!.color),
                          hintText: 'Location',
                          hintStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium!.color),
                          filled: true,
                          fillColor: isDark ? Colors.grey[800] : Colors.grey[300],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.my_location, color: Theme.of(context).textTheme.bodyMedium!.color),
                      tooltip: 'Použiť moju polohu',
                      onPressed: () async {
                          final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
                          final response = await http.post(
                            Uri.parse('http://$serverIp:$serverPort/get-address'),
                            headers: {
                              'Content-Type': 'application/json',
                              if (jwtToken != null) 'Authorization': 'Bearer $jwtToken',
                            },
                            body: jsonEncode({
                              'latitude': position.latitude,
                              'longitude': position.longitude,
                            }),
                          );
                          if (response.statusCode == 200) {
                            final data = jsonDecode(response.body);
                            final address = data['address'];
                            setState(() {
                              locationController.text = address;
                            });
                          }
                      },
                    )
                  ],
                ),
              ),
              _buildDateField(isDark),
              _buildInputField(
                controller: guestController,
                icon: Icons.group_outlined,
                hint: 'Guests',
                keyboardType: TextInputType.number,
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  if (locationController.text.isNotEmpty &&
                      dateFromNotifier.value != null &&
                      dateToNotifier.value != null &&
                      guestController.text.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SearchResultsScreen(
                          location: locationController.text,
                          dateFrom: dateFromNotifier.value!,
                          dateTo: dateToNotifier.value!,
                          guests: int.parse(guestController.text),
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text("Search", style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
              const SizedBox(height: 20),
              if (accommodations.isEmpty)
                Text("No accommodations available.", style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodyMedium!.color))
              else
                ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: accommodations.length,
                  itemBuilder: (context, index) {
                    final item = accommodations[index];
                    final isLiked = item['is_liked'] ?? false;

                    return FutureBuilder<Uint8List?>(
                      future: fetchAccommodationImage(item['aid']),
                      builder: (context, snapshot) {
                        Widget imageWidget;
                        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                          imageWidget = Image.memory(snapshot.data!, fit: BoxFit.cover, height: 180, width: double.infinity);
                        } else if (snapshot.connectionState == ConnectionState.waiting) {
                          imageWidget = const SizedBox(height: 180, child: Center(child: CircularProgressIndicator()));
                        } else {
                          imageWidget = const SizedBox(height: 180, child: Placeholder());
                        }

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
                                      child: imageWidget,
                                    ),
                                    Positioned(
                                      top: 10,
                                      right: 10,
                                      child: IconButton(
                                        icon: Icon(
                                          isLiked ? Icons.favorite : Icons.favorite_border,
                                          color: isLiked ? Colors.red : Colors.black,
                                        ),
                                        onPressed: () => toggleLike(item['aid'], index),
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
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(color: Theme.of(context).textTheme.bodyMedium!.color),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Theme.of(context).textTheme.bodyMedium!.color),
          hintText: hint,
          hintStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium!.color),
          filled: true,
          fillColor: isDark ? Colors.grey[800] : Colors.grey[300],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildDateField(bool isDark) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ValueListenableBuilder<DateTime?>(
                valueListenable: dateFromNotifier,
                builder: (context, dateFrom, _) => _buildDateTile(
                  label: dateFrom == null ? 'from' : '${dateFrom.day}.${dateFrom.month}',
                  isDark: isDark,
                  context: context,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now().subtract(const Duration(days: 1)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) dateFromNotifier.value = picked;
                  },
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ValueListenableBuilder<DateTime?>(
                valueListenable: dateToNotifier,
                builder: (context, dateTo, _) => _buildDateTile(
                  label: dateTo == null ? 'to' : '${dateTo.day}.${dateTo.month}',
                  isDark: isDark,
                  context: context,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: dateFromNotifier.value ?? DateTime.now(),
                      firstDate: dateFromNotifier.value ?? DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) dateToNotifier.value = picked;
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildDateTile({
    required String label,
    required VoidCallback onTap,
    required bool isDark,
    required BuildContext context,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 55,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800] : Colors.grey[300],
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(color: Theme.of(context).textTheme.bodyMedium!.color),
        ),
      ),
    );
  }
}
