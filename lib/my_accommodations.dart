import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import 'main.dart';
import 'add_accommondation.dart';
import 'server_config.dart';
import 'app_settings.dart';

class MyAccommodationsScreen extends StatefulWidget {
  const MyAccommodationsScreen({super.key});

  @override
  State<MyAccommodationsScreen> createState() => _MyAccommodationsScreenState();
}

class _MyAccommodationsScreenState extends State<MyAccommodationsScreen> {
  List<dynamic> myAccommodations = [];
  String? jwtToken = globalToken;

  @override
  void initState() {
    super.initState();
    _loadMyAccommodations();
  }

  Future<void> _loadMyAccommodations() async {
    final token = jwtToken;
    final url = Uri.parse('http://$serverIp:$serverPort/my-accommodations');

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
        myAccommodations = data['accommodations'];
      });
    }
  }

  Future<void> _deleteAccommodation(int aid) async {
    final token = jwtToken;

    final response = await http.delete(
      Uri.parse('http://$serverIp:$serverPort/delete-accommodation/$aid'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Accommodation deleted.")));
      _loadMyAccommodations();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: ${response.body}")));
    }
  }

  Widget _buildImage(int aid) {
    final imageUrl = 'http://$serverIp:$serverPort/accommodations/$aid/image/1';
    return Image.network(
      imageUrl,
      width: 100,
      height: 100,
      fit: BoxFit.cover,
      headers: jwtToken != null ? {'Authorization': 'Bearer $jwtToken'} : {},
      errorBuilder:
          (context, error, stackTrace) =>
              const SizedBox(width: 100, height: 100, child: Placeholder()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final highContrast = settings.highContrast;
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    final backgroundColor =
        highContrast
            ? (isDark ? Colors.black : Colors.white)
            : (isDark ? const Color(0xFF121212) : Colors.grey[300]);

    final textColor =
        highContrast
            ? (isDark ? Colors.white : Colors.black)
            : (isDark ? Colors.white70 : Colors.black87);

    final cardColor =
        highContrast
            ? (isDark ? Colors.grey[900] : Colors.white)
            : (isDark ? Colors.grey[800] : Colors.grey[200]);

    final iconColor = textColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text("My Accommodations"),
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child:
                myAccommodations.isEmpty
                    ? Center(
                      child: Text(
                        "No accommodations found.",
                        style: TextStyle(color: textColor),
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: myAccommodations.length,
                      itemBuilder: (context, index) {
                        final item = myAccommodations[index];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: isDark ? Colors.black26 : Colors.black12,
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: _buildImage(item['aid']),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['name'],
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "${item['city']}, ${item['country']}",
                                      style: TextStyle(color: textColor),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit, color: iconColor),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (_) => AddAccommodationScreen(
                                                accommodation: item,
                                              ),
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: iconColor),
                                    onPressed:
                                        () => _deleteAccommodation(item['aid']),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 14),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddAccommodationScreen(),
                  ),
                );
              },
              child: const Text(
                "Add Accommodation",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
