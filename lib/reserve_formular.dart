import 'dart:io';
import 'package:flutter/cupertino.dart';
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
  final TextEditingController _phoneController = TextEditingController();

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
    final fillColor =
        highContrast
            ? (isDark
                ? AppColors.colorInputBgDarkHigh
                : AppColors.colorInputBgHigh)
            : (isDark ? AppColors.colorInputBgDark : AppColors.colorInputBg);

    final aid = widget.accommodation['aid'];
    final token = globalToken;

    final thumbnailImage = Image.network(
      'http://$serverIp:$serverPort/accommodations/$aid/image/1',
      width: 100,
      height: 100,
      fit: BoxFit.cover,
      headers: token != null ? {'Authorization': 'Bearer $token'} : {},
      errorBuilder:
          (_, __, ___) =>
              const Placeholder(fallbackWidth: 100, fallbackHeight: 100),
    );

    final fullImage = Image.network(
      'http://$serverIp:$serverPort/accommodations/$aid/image/1',
      width: double.infinity,
      height: 200,
      fit: BoxFit.cover,
      headers: token != null ? {'Authorization': 'Bearer $token'} : {},
      errorBuilder:
          (_, __, ___) => const Placeholder(
            fallbackWidth: double.infinity,
            fallbackHeight: 200,
          ),
    );

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
    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor:
          highContrast
              ? (isDark ? AppColors.color1DarkHigh : AppColors.color1High)
              : (isDark ? AppColors.color1Dark : AppColors.color1),
      padding: EdgeInsets.symmetric(
        horizontal: bigText ? 36 : 30,
        vertical: bigText ? 18 : 14,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 5,
    );
    final buttonTextStyle = TextStyle(
      color:
          highContrast
              ? (isDark
                  ? AppColors.colorButtonTextDarkHigh
                  : AppColors.colorButtonTextHigh)
              : (isDark
                  ? AppColors.colorButtonTextDark
                  : AppColors.colorButtonText),
      fontSize: bigText ? 18 : 16,
      fontWeight: bigText ? FontWeight.bold : FontWeight.normal,
      fontFamily: 'Helvetica',
    );

    Widget formColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildDatePicker(
                label: 'From',
                selectedDate: fromDate,
                onDateSelected: (d) => setState(() => fromDate = d),
                fillColor: fillColor,
                textColor: textColor,
                bigText: bigText,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDatePicker(
                label: 'To',
                selectedDate: toDate,
                onDateSelected: (d) => setState(() => toDate = d),
                fillColor: fillColor,
                textColor: textColor,
                bigText: bigText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTextField(
          label: 'Name',
          fillColor: fillColor,
          textColor: textColor,
          bigText: bigText,
        ),
        _buildTextField(
          label: 'Surname',
          fillColor: fillColor,
          textColor: textColor,
          bigText: bigText,
        ),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                label: 'Street',
                fillColor: fillColor,
                textColor: textColor,
                bigText: bigText,
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 80,
              child: _buildTextField(
                label: 'Nr.',
                fillColor: fillColor,
                textColor: textColor,
                bigText: bigText,
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
                bigText: bigText,
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 100,
              child: _buildTextField(
                label: 'Zip Code',
                fillColor: fillColor,
                textColor: textColor,
                bigText: bigText,
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: TextField(
            controller: _phoneController,
            keyboardType: TextInputType.text,
            style: TextStyle(
              color: textColor,
              fontSize: bigText ? 18 : 14,
              fontWeight: bigText ? FontWeight.bold : FontWeight.normal,
              fontFamily: 'Helvetica',
            ),
            decoration: InputDecoration(
              labelText: 'Phone number',
              labelStyle: TextStyle(
                color: textColor.withOpacity(0.8),
                fontSize: bigText ? 16 : 14,
                fontWeight: bigText ? FontWeight.bold : FontWeight.normal,
                fontFamily: 'Helvetica',
              ),
              filled: true,
              fillColor: fillColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        _buildTextField(
          label: 'Email address',
          keyboardType: TextInputType.emailAddress,
          fillColor: fillColor,
          textColor: textColor,
          bigText: bigText,
        ),
        const SizedBox(height: 16),
        Center(
          child: ElevatedButton(
            style: buttonStyle,
            onPressed: () => _confirmReservation(context),
            child: Text('Confirm Reservation', style: buttonTextStyle),
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('Your Reservation', style: titleStyle),
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 600) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: fullImage,
                        ),
                        const SizedBox(height: 16),
                        Text(widget.accommodation['name'], style: titleStyle),
                        const SizedBox(height: 8),
                        Text(
                          widget.accommodation['location'] ?? '',
                          style: bodyStyle,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${widget.accommodation['max_guests']} Guests',
                          style: bodyStyle,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(child: formColumn),
                ],
              );
            } else {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: thumbnailImage,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.accommodation['name'],
                              style: titleStyle,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.accommodation['location'] ?? '',
                              style: bodyStyle,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${widget.accommodation['max_guests']} Guests',
                              style: bodyStyle,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  formColumn,
                ],
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    TextInputType keyboardType = TextInputType.text,
    required Color fillColor,
    required Color textColor,
    required bool bigText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        keyboardType: keyboardType,
        style: TextStyle(
          color: textColor,
          fontSize: bigText ? 18 : 14,
          fontWeight: bigText ? FontWeight.bold : FontWeight.normal,
          fontFamily: 'Helvetica',
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: textColor.withOpacity(0.8),
            fontSize: bigText ? 16 : 14,
            fontWeight: bigText ? FontWeight.bold : FontWeight.normal,
            fontFamily: 'Helvetica',
          ),
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

  Widget _buildDatePicker({
    required String label,
    required DateTime? selectedDate,
    required ValueChanged<DateTime> onDateSelected,
    required Color fillColor,
    required Color textColor,
    required bool bigText,
  }) {
    return GestureDetector(
      onTap: () {
        final now = DateTime.now();
        if (label == 'To' && fromDate == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Please select the From date first.',
                style: TextStyle(
                  fontSize: bigText ? 16 : 14,
                  fontWeight: bigText ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
          return;
        }
        DateTime initialDate =
            selectedDate ?? (label == 'To' ? fromDate! : now);
        DateTime firstDate = label == 'To' ? fromDate! : now;
        final lastDate = now.add(const Duration(days: 365));
        _pickDate(
          context: context,
          initialDate: initialDate,
          firstDate: firstDate,
          lastDate: lastDate,
          onDateSelected: onDateSelected,
        );
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
              ? '${selectedDate.day}.${selectedDate.month}.${selectedDate.year}'
              : label,
          style: TextStyle(
            fontSize: bigText ? 16 : 14,
            color: textColor,
            fontWeight: bigText ? FontWeight.bold : FontWeight.normal,
            fontFamily: 'Helvetica',
          ),
        ),
      ),
    );
  }

  void _pickDate({
    required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
    required ValueChanged<DateTime> onDateSelected,
  }) {
    if (Platform.isIOS) {
      showCupertinoModalPopup(
        context: context,
        builder:
            (_) => Container(
              height: 260,
              color: CupertinoColors.systemBackground.resolveFrom(context),
              child: Column(
                children: [
                  Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text('Done'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  Expanded(
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.date,
                      initialDateTime: initialDate,
                      minimumDate: firstDate,
                      maximumDate: lastDate,
                      onDateTimeChanged: onDateSelected,
                    ),
                  ),
                ],
              ),
            ),
      );
    } else {
      showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: lastDate,
      ).then((picked) {
        if (picked != null) onDateSelected(picked);
      });
    }
  }

  Future<void> _confirmReservation(BuildContext context) async {
    if (fromDate == null || toDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both dates.')),
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
      ).showSnackBar(SnackBar(content: Text('Network error: $e')));
    }
  }
}
