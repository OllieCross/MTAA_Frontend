import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'search_results_screen.dart';
import 'main.dart';
import 'bottom_navbar.dart';
import 'accommondation_detail.dart';
import 'server_config.dart';

class MainScreenAccommodations extends StatefulWidget {
  const MainScreenAccommodations({super.key});

  @override
  State<MainScreenAccommodations> createState() => _MainScreenAccommodationsState();
}

class _MainScreenAccommodationsState extends State<MainScreenAccommodations> {
  final TextEditingController locationController = TextEditingController();
  final TextEditingController guestController = TextEditingController();
  DateTime? dateFrom;
  DateTime? dateTo;

  List<dynamic> accommodations = [];
  String? jwtToken = globalToken;

  @override
  void initState() {
    super.initState();
    _loadInitialRecommendations();
  }

  Future<void> _loadInitialRecommendations() async {
    try {
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
      setState(() {
        accommodations = (data['results'] as List).map((item) {
          return {
            ...item,
            'is_liked': item['is_liked'] ?? false, // pridať ak backend vie
          };
        }).toList();
      });

      } else {
        print("Error: ${response.body}");
      }
    } catch (e) {
      print("Error fetching accommodations: $e");
    }
  }

  Future<void> toggleLike(int aid, int index) async {
  final response = await http.post(
    Uri.parse('http://127.0.0.1:5000/like_dislike'),
    headers: {
      'Content-Type': 'application/json',
      if (jwtToken != null) 'Authorization': 'Bearer $jwtToken',
    },
    body: jsonEncode({'aid': aid}),
  );

  if (response.statusCode == 200) {
    final message = jsonDecode(response.body)['message'];
    setState(() {
      accommodations[index]['is_liked'] = message == 'Liked accommodation';
    });
  } else {
    print('Like toggle error: ${response.body}');
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
              // LOCATION
              _buildInputField(
                controller: locationController,
                icon: Icons.location_on_outlined,
                hint: 'Location',
              ),

              // DATES
              _buildDateField(),

              // GUESTS
              _buildInputField(
                controller: guestController,
                icon: Icons.group_outlined,
                hint: 'Guests',
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  if (locationController.text.isNotEmpty &&
                      dateFrom != null &&
                      dateTo != null &&
                      guestController.text.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SearchResultsScreen(
                          location: locationController.text,
                          dateFrom: dateFrom!,
                          dateTo: dateTo!,
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

              // ACCOMMODATIONS LIST
              if (accommodations.isEmpty)
                const Text("No accommodations available.", style: TextStyle(fontSize: 16))
              else
                ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: accommodations.length,
                itemBuilder: (context, index) {
                  final item = accommodations[index];
                  final imageBase64 = item['image_base64'];
                  final isLiked = item['is_liked'] ?? false;

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
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          hintText: hint,
          filled: true,
          fillColor: Colors.grey[300],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        ),
      ),
    );
  }
Widget _buildDateField() {
  return Column(
    children: [
      Row(
        children: [
          Expanded(child: _buildDateTile(
            label: dateFrom == null ? 'from' : '${dateFrom!.day}.${dateFrom!.month}',
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now().subtract(const Duration(days: 1)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) setState(() => dateFrom = picked);
            },
          )),
          const SizedBox(width: 10),
          Expanded(child: _buildDateTile(
            label: dateTo == null ? 'to' : '${dateTo!.day}.${dateTo!.month}',
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: dateFrom ?? DateTime.now(),
                firstDate: dateFrom ?? DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) setState(() => dateTo = picked);
            },
          )),
        ],
      ),
      const SizedBox(height: 12), // Táto výšková medzera pridá priestor pred "Guests"
    ],
  );
}


  Widget _buildDateTile({required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 55,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(label),
      ),
    );
  }
}

