import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'main.dart';
import 'add_accommondation.dart';
import 'server_config.dart';

class MyAccommodationsScreen extends StatefulWidget {
  const MyAccommodationsScreen({super.key});

  @override
  State<MyAccommodationsScreen> createState() => _MyAccommodationsScreenState();
}

class _MyAccommodationsScreenState extends State<MyAccommodationsScreen> {
  List<dynamic> myAccommodations = [];

  @override
  void initState() {
    super.initState();
    _loadMyAccommodations();
  }

  Future<void> _loadMyAccommodations() async {
    final token = globalToken;
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
      setState(() {
        myAccommodations = data['accommodations'];
      });
    } else {
      print("Fetch error: ${response.body}");
    }
  }

  Future<void> _deleteAccommodation(int aid) async {
    final token = globalToken;

    final response = await http.delete(
      Uri.parse('http://$serverIp:$serverPort/delete-accommodation/$aid'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Accommodation deleted.")),
      );
      _loadMyAccommodations();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${response.body}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Accommodations")),
      body: Column(
        children: [
          Expanded(
            child: myAccommodations.isEmpty
                ? const Center(child: Text("No accommodations found."))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: myAccommodations.length,
                    itemBuilder: (context, index) {
                      final item = myAccommodations[index];
                      final image = item['image_base64'] != null
                          ? Image.memory(
                              base64Decode(item['image_base64']
                                  .replaceAll(RegExp(r'\s+'), '')),
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            )
                          : const SizedBox(
                              width: 80,
                              height: 80,
                              child: Placeholder(),
                            );

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: image,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item['name'],
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${item['city']}, ${item['country']}",
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AddAccommodationScreen(
                                          accommodation: item,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () =>
                                      _deleteAccommodation(item['aid']),
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
                    borderRadius: BorderRadius.circular(12)),
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
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
