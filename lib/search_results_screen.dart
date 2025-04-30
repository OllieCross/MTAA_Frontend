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
  String? jwtToken = globalToken;

  @override
  void initState() {
    super.initState();
    _fetchSearchResults();
  }

  Future<void> _fetchSearchResults() async {
    final url = Uri.parse('http://$serverIp:$serverPort/search-accommodations');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (jwtToken != null) 'Authorization': 'Bearer $jwtToken',
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
      if (!mounted) return;
      setState(() {
        results = data['results'];
      });
    } else {
      print("Search error: ${response.body}");
    }
  }

  Widget _buildImage(int aid) {
    final imageUrl = 'http://$serverIp:$serverPort/accommodations/$aid/image/1';
    return Image.network(
      imageUrl,
      width: double.infinity,
      height: 200,
      fit: BoxFit.cover,
      headers: jwtToken != null ? {'Authorization': 'Bearer $jwtToken'} : {},
      errorBuilder: (context, error, stackTrace) =>
          const SizedBox(height: 200, child: Placeholder()),
    );
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
                                child: _buildImage(item['aid']),
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
