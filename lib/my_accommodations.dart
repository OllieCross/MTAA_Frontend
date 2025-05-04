import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'bottom_navbar.dart';
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

  Widget _buildImage(int aid, Color textColor) {
    final imageUrl = 'http://$serverIp:$serverPort/accommodations/$aid/image/1';
    return Image.network(
      imageUrl,
      width: 100,
      height: 100,
      fit: BoxFit.cover,
      headers: jwtToken != null ? {'Authorization': 'Bearer $jwtToken'} : {},
      errorBuilder:
          (_, __, ___) =>
              const SizedBox(width: 100, height: 100, child: Placeholder()),
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
            ? (isDark
                ? const Color.fromARGB(255, 29, 29, 29)
                : AppColors.colorBgHigh)
            : (isDark ? Colors.grey[800]! : Colors.grey[200]!);

    final titleStyle = TextStyle(
      fontSize: bigText ? 22 : 18,
      fontWeight: bigText ? FontWeight.bold : FontWeight.normal,
      color: textColor,
      fontFamily: 'Helvetica',
    );
    final bodyStyle = TextStyle(
      fontSize: bigText ? 16 : 14,
      fontWeight: bigText ? FontWeight.bold : FontWeight.normal,
      color: textColor,
      fontFamily: 'Helvetica',
    );

    return Scaffold(
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text("My Accommodations", style: titleStyle),
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
                      child: Text("No accommodations found.", style: bodyStyle),
                    )
                    : LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth > 600) {
                          return GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 3,
                                  mainAxisSpacing: 16,
                                  crossAxisSpacing: 16,
                                ),
                            itemCount: myAccommodations.length,
                            itemBuilder: (context, index) {
                              final item = myAccommodations[index];
                              return Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          isDark
                                              ? Colors.black26
                                              : Colors.black12,
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: _buildImage(
                                        item['aid'],
                                        textColor,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item['name'],
                                            style: TextStyle(
                                              fontSize: bigText ? 18 : 16,
                                              fontWeight:
                                                  bigText
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                              color: textColor,
                                              fontFamily: 'Helvetica',
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "${item['city']}, ${item['country']}",
                                            style: bodyStyle,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            Icons.edit,
                                            color: textColor,
                                          ),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (_) =>
                                                        AddAccommodationScreen(
                                                          accommodation: item,
                                                        ),
                                              ),
                                            );
                                          },
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.delete,
                                            color: textColor,
                                          ),
                                          onPressed:
                                              () => _deleteAccommodation(
                                                item['aid'],
                                              ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        } else {
                          return ListView.builder(
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
                                      color:
                                          isDark
                                              ? Colors.black26
                                              : Colors.black12,
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: _buildImage(
                                        item['aid'],
                                        textColor,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item['name'],
                                            style: TextStyle(
                                              fontSize: bigText ? 18 : 16,
                                              fontWeight:
                                                  bigText
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                              color: textColor,
                                              fontFamily: 'Helvetica',
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "${item['city']}, ${item['country']}",
                                            style: bodyStyle,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            Icons.edit,
                                            color: textColor,
                                          ),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (_) =>
                                                        AddAccommodationScreen(
                                                          accommodation: item,
                                                        ),
                                              ),
                                            );
                                          },
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.delete,
                                            color: textColor,
                                          ),
                                          onPressed:
                                              () => _deleteAccommodation(
                                                item['aid'],
                                              ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        }
                      },
                    ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    highContrast
                        ? (isDark
                            ? AppColors.color1DarkHigh
                            : AppColors.color1High)
                        : (isDark ? AppColors.color1 : AppColors.color1),
                padding: EdgeInsets.symmetric(vertical: bigText ? 16 : 14),
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
              child: Text(
                "Add Accommodation",
                style: TextStyle(
                  color:
                      highContrast
                          ? (isDark
                              ? AppColors.colorButtonTextDarkHigh
                              : AppColors.colorButtonTextHigh)
                          : (isDark
                              ? AppColors.colorButtonTextDark
                              : AppColors.colorButtonText),
                  fontWeight: bigText ? FontWeight.bold : FontWeight.normal,
                  fontSize: bigText ? 18 : 16,
                  fontFamily: 'Helvetica',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
