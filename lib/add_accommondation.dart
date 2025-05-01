import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'main.dart';
import 'server_config.dart';

class AddAccommodationScreen extends StatefulWidget {
  final Map<String, dynamic>? accommodation;

  const AddAccommodationScreen({super.key, this.accommodation});

  @override
  State<AddAccommodationScreen> createState() => _AddAccommodationScreenState();
}

class _AddAccommodationScreenState extends State<AddAccommodationScreen> {
  final nameController = TextEditingController();
  final addressController = TextEditingController();
  final guestsController = TextEditingController();
  final priceController = TextEditingController();
  final ibanController = TextEditingController();
  final descriptionController = TextEditingController();

  final List<XFile> selectedImages = [];
  final ImagePicker picker = ImagePicker();
  bool isUploading = false;

  @override
  void initState() {
    super.initState();
    final acc = widget.accommodation;
    if (acc != null) {
      nameController.text = acc['name'] ?? '';
    }
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await picker.pickMultiImage();
      if (images.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          selectedImages.addAll(images);
        });
      }
    } catch (e) {
      debugPrint("Image picker error: $e");
    }
  }

  Future<void> _submitAccommodation() async {
    final token = globalToken;
    if (token == null) return;

    if (selectedImages.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least 3 images.")),
      );
      return;
    }

    if (!mounted) return;
    setState(() => isUploading = true);

    final uri = Uri.parse('http://$serverIp:$serverPort/add-accommodation');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['name'] = nameController.text
      ..fields['address'] = addressController.text
      ..fields['guests'] = guestsController.text
      ..fields['price'] = priceController.text
      ..fields['iban'] = ibanController.text
      ..fields['description'] = descriptionController.text;

    for (var image in selectedImages) {
      request.files.add(await http.MultipartFile.fromPath('images', image.path));
    }

    final response = await request.send();
    setState(() => isUploading = false);

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Accommodation added successfully.")),
      );
      Navigator.pop(context);
    } else {
      final respStr = await response.stream.bytesToString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $respStr")),
      );
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    addressController.dispose();
    guestsController.dispose();
    priceController.dispose();
    ibanController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final isEdit = widget.accommodation != null;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? Colors.grey[900] : null,
        foregroundColor: isDark ? Colors.white : null,
        title: Text(isEdit ? "Edit Accommodation" : "Add Accommodation"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildField(label: "Name", controller: nameController, isDark: isDark),
            _buildField(label: "Address", controller: addressController, isDark: isDark),
            _buildField(label: "Nr. of Guests", controller: guestsController, keyboardType: TextInputType.number, isDark: isDark),
            _buildField(label: "Price per Night", controller: priceController, keyboardType: TextInputType.number, isDark: isDark),
            _buildField(label: "IBAN", controller: ibanController, isDark: isDark),
            _buildField(label: "Description", controller: descriptionController, maxLines: 4, isDark: isDark),
            const SizedBox(height: 16),
            _buildImagePicker(isDark),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isUploading ? null : _submitAccommodation,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
              ),
              child: isUploading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      isEdit ? "Save Changes" : "Add Accommodation",
                      style: const TextStyle(color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    bool isDark = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: TextStyle(color: isDark ? Colors.white : Colors.black),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
          filled: true,
          fillColor: isDark ? Colors.grey[800] : Colors.grey[200],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildImagePicker(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Photos (${selectedImages.length})", style: TextStyle(fontWeight: FontWeight.w500, color: isDark ? Colors.white : Colors.black)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickImages,
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[700] : Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.add_photo_alternate, size: 40, color: isDark ? Colors.white : Colors.black),
          ),
        ),
        const SizedBox(height: 8),
        if (selectedImages.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: selectedImages.map((image) {
              return Stack(
                alignment: Alignment.topRight,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(File(image.path), width: 80, height: 80, fit: BoxFit.cover),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedImages.remove(image);
                      });
                    },
                    child: const CircleAvatar(
                      radius: 10,
                      backgroundColor: Colors.black54,
                      child: Icon(Icons.close, size: 14, color: Colors.white),
                    ),
                  )
                ],
              );
            }).toList(),
          ),
      ],
    );
  }
}