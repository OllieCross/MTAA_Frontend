import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import 'main.dart';
import 'my_accommodations.dart';
import 'bottom_navbar.dart';
import 'server_config.dart';
import 'accessibility_buttons.dart';
import 'app_settings.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<dynamic> reservations = [];

  @override
  void initState() {
    super.initState();
    _loadReservations();
  }

  Future<void> _loadReservations() async {
    final url = Uri.parse('http://$serverIp:$serverPort/my-reservations');
    final token = globalToken;
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
        reservations = data['reservations'];
      });
    }
  }

  Future<void> _deleteReservation(int rid) async {
    final url = Uri.parse('http://$serverIp:$serverPort/delete-reservation/$rid');
    final token = globalToken;

    final response = await http.delete(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      if (!mounted) return;
      setState(() {
        reservations.removeWhere((r) => r['rid'] == rid);
      });
    }
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
    final boxColor = highContrast
        ? (isDark ? Colors.grey[900] : Colors.white)
        : (isDark ? Colors.grey[800] : Colors.grey[200]);
    final iconColor = textColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      bottomNavigationBar: const BottomNavBar(currentIndex: 2),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 24),
                Text(
                  "Your Reservations",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                const AccessibilityButtons(),
                const SizedBox(height: 16),
                Expanded(
                  child: reservations.isEmpty
                      ? Center(
                          child: Text("No reservations yet.",
                              style: TextStyle(color: textColor)))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: reservations.length,
                          itemBuilder: (context, index) {
                            final res = reservations[index];
                            final location = "${res['city']}, ${res['country']}";

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: boxColor,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: isDark
                                        ? Colors.black26
                                        : Colors.black12,
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              height: 50,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    location,
                                    style: TextStyle(
                                        fontSize: 16, color: textColor),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete_outline,
                                        color: iconColor),
                                    onPressed: () =>
                                        _deleteReservation(res['rid']),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MyAccommodationsScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      "My Accommodations",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
