import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'main.dart';
import 'my_accommodations.dart';
import 'bottom_navbar.dart';
import 'server_config.dart';
import 'app_settings.dart';
import 'accessibility_buttons.dart';
import 'dart:async';
import 'offline_sync_repository.dart';

class SyncToast extends StatefulWidget {
  const SyncToast({super.key, required this.child, this.onSynced});
  final Widget child;
  final VoidCallback? onSynced;   // optional refresh hook

  @override
  State<SyncToast> createState() => _SyncToastState();
}

class _SyncToastState extends State<SyncToast> {
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _sub = OfflineSyncRepository.instance.uploadSuccess.listen((draft) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${draft.name}" synced successfully!'),
          duration: const Duration(seconds: 2),
        ),
      );
      widget.onSynced?.call();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

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
    final url = Uri.parse(
      'http://$serverIp:$serverPort/delete-reservation/$rid',
    );
    final token = globalToken;

    final response = await http.delete(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      await notificationsPlugin.cancel(rid);
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

    final backgroundColor =
        highContrast
            ? (isDark ? Colors.black : Colors.white)
            : (isDark ? const Color(0xFF121212) : Colors.grey[300]);
    final textColor =
        highContrast
            ? (isDark ? Colors.white : Colors.black)
            : (isDark ? Colors.white70 : Colors.black87);
    final boxColor =
        highContrast
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
                    fontFamily: 'Helvetica',
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                const AccessibilityButtons(),
                const SizedBox(height: 16),
                Expanded(
                  child:
                      reservations.isEmpty
                          ? Center(
                            child: Text(
                              "No reservations yet.",
                              style: TextStyle(
                                color: textColor,
                                fontSize: settings.bigText ? 20 : 16,
                                fontWeight:
                                    settings.bigText
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                fontFamily: 'Helvetica',
                              ),
                            ),
                          )
                          : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: reservations.length,
                            itemBuilder: (context, index) {
                              final res = reservations[index];
                              final location =
                                  "${res['city']}, ${res['country']}";
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: boxColor,
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          isDark
                                              ? Colors.black26
                                              : Colors.black12,
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
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
                                        fontSize: 16,
                                        color: textColor,
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete_outline,
                                        color: iconColor,
                                      ),
                                      onPressed:
                                          () => _deleteReservation(res['rid']),
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
                      backgroundColor:
                          highContrast
                              ? (isDark
                                  ? AppColors.color1DarkHigh
                                  : AppColors.color1High)
                              : (isDark
                                  ? AppColors.color1Dark
                                  : AppColors.color1),
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
                    child: Text(
                      "My Accommodations",
                      style: TextStyle(
                        color:
                            highContrast
                                ? AppColors.colorTextDark
                                : AppColors.colorTextFieldDarkHigh,
                        fontSize: settings.bigText ? 20 : 16,
                        fontWeight:
                            settings.bigText
                                ? FontWeight.bold
                                : FontWeight.normal,
                        fontFamily: 'Helvetica',
                      ),
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
