import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'main.dart';
import 'accommondation_detail.dart';
import 'server_config.dart';

class SearchResultsScreen extends StatefulWidget {
  final String location;
  final DateTime dateFrom;
  final DateTime dateTo;
  final int guests;

  const SearchResultsScreen({
    super.key,
    required this.location,
    required this.dateFrom,
    required this.dateTo,
    required this.guests,
  });

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  List<dynamic> results = [];

  @override
  void initState() {
    super.initState();
    _fetchSearchResults();
  }

  Future<void> _fetchSearchResults() async {
    final url = Uri.parse('http://$serverIp:$serverPort/search-accommodations');
    final token = globalToken;

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'location': widget.location,
        'from': widget.dateFrom.toIso8601String().split('T').first,
        'to': widget.dateTo.toIso8601String().split('T').first,
        'guests': widget.guests,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        results = data['results'];
      });
    } else {
      print("Search error: ${response.body}");
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateRange =
        '${widget.dateFrom.day}.${widget.dateFrom.month}. - ${widget.dateTo.day}.${widget.dateTo.month}.';
    final header =
        '${widget.location[0].toUpperCase()}${widget.location.substring(1)}, ${widget.guests} Guest${widget.guests > 1 ? 's' : ''}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Results'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(header, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(dateRange, style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
          Expanded(
            child: results.isEmpty
                ? const Center(child: Text('No results found'))
                : ListView.builder(
                    itemCount: results.length,
                    padding: const EdgeInsets.all(12),
                    itemBuilder: (context, index) {
                      final item = results[index];
                      final image = item['image_base64'] != null
                          ? Image.memory(
                              base64Decode(item['image_base64']
                                  .replaceAll(RegExp(r'\s+'), '')),
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
                              builder: (_) =>
                                  AccommodationDetailScreen(aid: item['aid']),
                            ),
                          );
                        },
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                                child: image,
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
          ),
        ],
      ),
    );
  }
}
