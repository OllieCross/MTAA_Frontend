import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'main.dart';
import 'confirmation.dart';
import 'server_config.dart';
import 'app_settings.dart';
import 'dart:convert';

class ReserveFormularScreen extends StatefulWidget {
  final Map<String, dynamic> accommodation;

  const ReserveFormularScreen({super.key, required this.accommodation});

  @override
  State<ReserveFormularScreen> createState() => _ReserveFormularScreenState();
}

class _ReserveFormularScreenState extends State<ReserveFormularScreen> {
  DateTime? fromDate;
  DateTime? toDate;

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
            : (isDark ? Colors.white60 : Colors.black87);

    final fillColor = isDark ? Colors.grey[800]! : Colors.grey[200]!;

    final aid = widget.accommodation['aid'];
    final token = globalToken;

    final imageUrl = 'http://$serverIp:$serverPort/accommodations/$aid/image/1';
    final imageWidget = Image.network(
      imageUrl,
      width: 100,
      height: 100,
      fit: BoxFit.cover,
      headers: token != null ? {'Authorization': 'Bearer $token'} : {},
      errorBuilder:
          (context, error, stackTrace) =>
              const Placeholder(fallbackWidth: 100, fallbackHeight: 100),
    );

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text("Your Reservation"),
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: imageWidget,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.accommodation['name'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.accommodation['location'] ?? '',
                        style: TextStyle(color: textColor),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${widget.accommodation['max_guests']} Guests",
                        style: TextStyle(color: textColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildDatePicker(
                    "From",
                    fromDate,
                    (picked) => setState(() => fromDate = picked),
                    fillColor,
                    textColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDatePicker(
                    "To",
                    toDate,
                    (picked) => setState(() => toDate = picked),
                    fillColor,
                    textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildTextField(
              label: 'Name',
              fillColor: fillColor,
              textColor: textColor,
            ),
            _buildTextField(
              label: 'Surname',
              fillColor: fillColor,
              textColor: textColor,
            ),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    label: 'Street',
                    fillColor: fillColor,
                    textColor: textColor,
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 80,
                  child: _buildTextField(
                    label: 'Nr.',
                    fillColor: fillColor,
                    textColor: textColor,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    label: 'City',
                    fillColor: fillColor,
                    textColor: textColor,
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 100,
                  child: _buildTextField(
                    label: 'Zip Code',
                    fillColor: fillColor,
                    textColor: textColor,
                  ),
                ),
              ],
            ),
            _buildTextField(
              label: 'Phone number',
              keyboardType: TextInputType.phone,
              fillColor: fillColor,
              textColor: textColor,
            ),
            _buildTextField(
              label: 'Email address',
              keyboardType: TextInputType.emailAddress,
              fillColor: fillColor,
              textColor: textColor,
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                ),
                onPressed: () => _confirmReservation(context),
                child: const Text(
                  "Confirm Reservation",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required Color fillColor,
    required Color textColor,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        keyboardType: keyboardType,
        style: TextStyle(color: textColor),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: textColor.withOpacity(0.8)),
          filled: true,
          fillColor: fillColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker(
    String label,
    DateTime? selectedDate,
    Function(DateTime) onPicked,
    Color fillColor,
    Color textColor,
  ) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) onPicked(picked);
      },
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          selectedDate != null
              ? "${selectedDate.day}.${selectedDate.month}.${selectedDate.year}"
              : label,
          style: TextStyle(fontSize: 16, color: textColor),
        ),
      ),
    );
  }

  Future<void> _confirmReservation(BuildContext context) async {
    if (fromDate == null || toDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select both dates.")),
      );
      return;
    }

    final token = globalToken;
    final url = Uri.parse('http://$serverIp:$serverPort/make-reservation');
    final aid = widget.accommodation['aid'];

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'aid': aid,
          'from': fromDate!.toIso8601String().split('T')[0],
          'to': toDate!.toIso8601String().split('T')[0],
        }),
      );

      if (response.statusCode == 201) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ConfirmationScreen()),
        );
      } else {
        final decoded = jsonDecode(response.body);
        final message = decoded['message'] ?? 'Reservation failed';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Network error: $e")));
    }
  }
}
