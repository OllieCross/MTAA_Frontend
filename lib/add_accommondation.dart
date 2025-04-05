import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'main.dart';

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
  final List<PlatformFile> selectedWebFiles = [];
  final ImagePicker picker = ImagePicker();

  bool isUploading = false;

  @override
  void initState() {
    super.initState();
    final acc = widget.accommodation;
    if (acc != null) {
      nameController.text = acc['name'] ?? '';
      // zatiaľ backend nevracia ďalšie údaje
    }
  }

  Future<void> _pickImages() async {
    if (kIsWeb) {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.image,
      );
      if (result != null) {
        setState(() {
          selectedWebFiles.addAll(result.files);
        });
      }
    } else {
      try {
        final List<XFile> images = await picker.pickMultiImage();
        if (images.isNotEmpty) {
          setState(() {
            selectedImages.addAll(images);
          });
        }
      } catch (e) {
        debugPrint("Image picker error: $e");
      }
    }
  }

  Future<void> _submitAccommodation() async {
    final token = globalToken;
    if (token == null) return;

    final totalImages = kIsWeb ? selectedWebFiles.length : selectedImages.length;
    if (totalImages < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least 3 images.")),
      );
      return;
    }

    setState(() => isUploading = true);

    final uri = Uri.parse('http://localhost:5000/add-accommodation');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['name'] = nameController.text
      ..fields['address'] = addressController.text
      ..fields['guests'] = guestsController.text
      ..fields['price'] = priceController.text
      ..fields['iban'] = ibanController.text
      ..fields['description'] = descriptionController.text;

    if (kIsWeb) {
      for (var file in selectedWebFiles) {
        request.files.add(http.MultipartFile.fromBytes(
          'images',
          file.bytes!,
          filename: file.name,
        ));
      }
    } else {
      for (var image in selectedImages) {
        request.files.add(await http.MultipartFile.fromPath('images', image.path));
      }
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
    final isEdit = widget.accommodation != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? "Edit Accommodation" : "Add Accommodation")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildField(label: "Name", controller: nameController),
            _buildField(label: "Address", controller: addressController),
            _buildField(label: "Nr. of Guests", controller: guestsController, keyboardType: TextInputType.number),
            _buildField(label: "Price per Night", controller: priceController, keyboardType: TextInputType.number),
            _buildField(label: "IBAN", controller: ibanController),
            _buildField(label: "Description", controller: descriptionController, maxLines: 4),
            const SizedBox(height: 16),
            _buildImagePicker(),
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
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey[200],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    final int imageCount = kIsWeb ? selectedWebFiles.length : selectedImages.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Photos ($imageCount)", style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickImages,
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.add_photo_alternate, size: 40),
          ),
        ),
        const SizedBox(height: 8),
        if (imageCount > 0)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: (kIsWeb ? selectedWebFiles : selectedImages).map((file) {
              final imageWidget = kIsWeb
                  ? Image.memory((file as PlatformFile).bytes!, width: 80, height: 80, fit: BoxFit.cover)
                  : Image.file(File((file as XFile).path), width: 80, height: 80, fit: BoxFit.cover);

              return Stack(
                alignment: Alignment.topRight,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: imageWidget,
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (kIsWeb) {
                          selectedWebFiles.remove(file);
                        } else {
                          selectedImages.remove(file);
                        }
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
