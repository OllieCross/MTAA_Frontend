import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'main.dart';
import 'accommondation_detail.dart';
import 'server_config.dart';
import 'app_settings.dart';

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
    final settings = context.watch<AppSettings>();
    final highContrast = settings.highContrast;
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    final backgroundColor = highContrast
        ? (isDark ? Colors.black : Colors.white)
        : (isDark ? const Color(0xFF121212) : Colors.grey[300]);

    final textColor = highContrast
        ? (isDark ? Colors.white : Colors.black)
        : (isDark ? Colors.white70 : Colors.black87);

    final cardColor = highContrast
        ? (isDark ? Colors.grey[900] : Colors.white)
        : (isDark ? Colors.grey[800] : Colors.grey[200]);

    final dateRange =
        '${widget.dateFrom.day}.${widget.dateFrom.month}. - ${widget.dateTo.day}.${widget.dateTo.month}.';
    final header =
        '${widget.location[0].toUpperCase()}${widget.location.substring(1)}, ${widget.guests} Guest${widget.guests > 1 ? 's' : ''}';

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Results'),
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(header, style: TextStyle(fontSize: 16, color: textColor)),
                  const SizedBox(height: 4),
                  Text(dateRange, style: TextStyle(color: textColor.withOpacity(0.7))),
                ],
              ),
            ),
          ),
          Expanded(
            child: results.isEmpty
                ? Center(child: Text('No results found', style: TextStyle(color: textColor)))
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
                          color: cardColor,
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
                                    Text(item['location'], style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textColor)),
                                    const SizedBox(height: 4),
                                    Text('${item['price_per_night']} € / Night', style: TextStyle(fontSize: 14, color: textColor)),
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
