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
      errorBuilder:
          (_, __, ___) => const SizedBox(height: 200, child: Placeholder()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final highContrast = settings.highContrast;
    final bigText = settings.bigText;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor =
        highContrast
            ? (isDark ? AppColors.colorBgDarkHigh : AppColors.colorBgHigh)
            : (isDark ? AppColors.colorBgDark : AppColors.colorBg);
    final textColor =
        highContrast
            ? (isDark ? AppColors.colorTextDarkHigh : AppColors.colorTextHigh)
            : (isDark ? AppColors.colorTextDark : AppColors.colorText);
    final cardColor =
        highContrast
            ? (isDark ? AppColors.colorBgDarkHigh : AppColors.colorBgHigh)
            : (isDark ? Colors.grey[800]! : Colors.grey[200]!);

    final headerStyle = TextStyle(
      fontSize: bigText ? 18 : 16,
      fontWeight: bigText ? FontWeight.bold : FontWeight.normal,
      color: textColor,
      fontFamily: 'Helvetica',
    );
    final subHeaderStyle = TextStyle(
      fontSize: bigText ? 16 : 14,
      fontWeight: bigText ? FontWeight.bold : FontWeight.normal,
      color: textColor.withOpacity(0.7),
      fontFamily: 'Helvetica',
    );
    final itemTitleStyle = TextStyle(
      fontSize: bigText ? 18 : 16,
      fontWeight: bigText ? FontWeight.bold : FontWeight.normal,
      color: textColor,
      fontFamily: 'Helvetica',
    );
    final itemPriceStyle = TextStyle(
      fontSize: bigText ? 16 : 14,
      fontWeight: bigText ? FontWeight.bold : FontWeight.normal,
      color: textColor,
      fontFamily: 'Helvetica',
    );

    final dateRange =
        '${widget.dateFrom.day}.${widget.dateFrom.month}. - ${widget.dateTo.day}.${widget.dateTo.month}.';
    final headerText =
        '${widget.location[0].toUpperCase()}${widget.location.substring(1)}, ${widget.guests} Guest${widget.guests > 1 ? 's' : ''}';

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('Results', style: headerStyle),
        backgroundColor: backgroundColor,
        foregroundColor: backgroundColor,
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
                  Text(headerText, style: headerStyle),
                  const SizedBox(height: 4),
                  Text(dateRange, style: subHeaderStyle),
                ],
              ),
            ),
          ),
          Expanded(
            child:
                results.isEmpty
                    ? Center(
                      child: Text('No results found', style: itemPriceStyle),
                    )
                    : LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth > 600) {
                          return GridView.builder(
                            padding: const EdgeInsets.all(12),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 16,
                                  crossAxisSpacing: 16,
                                  childAspectRatio: 0.75,
                                ),
                            itemCount: results.length,
                            itemBuilder: (context, index) {
                              final item = results[index];
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => AccommodationDetailScreen(
                                            aid: item['aid'],
                                          ),
                                    ),
                                  );
                                },
                                child: Card(
                                  color: cardColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius:
                                            const BorderRadius.vertical(
                                              top: Radius.circular(10),
                                            ),
                                        child: _buildImage(item['aid']),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item['location'],
                                              style: itemTitleStyle,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${item['price_per_night']} € / Night',
                                              style: itemPriceStyle,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        } else {
                          return ListView.builder(
                            itemCount: results.length,
                            padding: const EdgeInsets.all(12),
                            itemBuilder: (context, index) {
                              final item = results[index];
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => AccommodationDetailScreen(
                                            aid: item['aid'],
                                          ),
                                    ),
                                  );
                                },
                                child: Card(
                                  color: cardColor,
                                  margin: const EdgeInsets.only(bottom: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius:
                                            const BorderRadius.vertical(
                                              top: Radius.circular(10),
                                            ),
                                        child: _buildImage(item['aid']),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item['location'],
                                              style: itemTitleStyle,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${item['price_per_night']} € / Night',
                                              style: itemPriceStyle,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        }
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
