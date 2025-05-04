import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'main.dart';
import 'server_config.dart';
import 'app_settings.dart';

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
        SnackBar(
          content: Text(
            "Please select at least 3 images.",
            style: TextStyle(
              color: _textColor,
              fontSize: _bigText ? 16 : 14,
              fontWeight: _bigText ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          backgroundColor: _backgroundColor,
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() => isUploading = true);

    final uri = Uri.parse('http://$serverIp:$serverPort/add-accommodation');
    final request =
        http.MultipartRequest('POST', uri)
          ..headers['Authorization'] = 'Bearer $globalToken'
          ..fields['name'] = nameController.text
          ..fields['address'] = addressController.text
          ..fields['guests'] = guestsController.text
          ..fields['price'] = priceController.text
          ..fields['iban'] = ibanController.text
          ..fields['description'] = descriptionController.text;

    for (var image in selectedImages) {
      request.files.add(
        await http.MultipartFile.fromPath('images', image.path),
      );
    }

    final response = await request.send();
    setState(() => isUploading = false);

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Accommodation added successfully.",
            style: TextStyle(
              color: _textColor,
              fontSize: _bigText ? 16 : 14,
              fontWeight: _bigText ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          backgroundColor: _backgroundColor,
        ),
      );
      Navigator.pop(context);
    } else {
      final respStr = await response.stream.bytesToString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Error: $respStr",
            style: TextStyle(
              color: _textColor,
              fontSize: _bigText ? 16 : 14,
              fontWeight: _bigText ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          backgroundColor: _backgroundColor,
        ),
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

  late final bool _bigText;
  late final bool _highContrast;
  late final bool _isDark;
  late final Color _backgroundColor;
  late final Color _textColor;
  late final Color _fillColor;

  void _initTheme(BuildContext context) {
    final settings = context.watch<AppSettings>();
    _bigText = settings.bigText;
    _highContrast = settings.highContrast;
    _isDark = Theme.of(context).brightness == Brightness.dark;
    _backgroundColor =
        _highContrast
            ? (_isDark ? AppColors.colorBgDarkHigh : AppColors.colorBgHigh)
            : (_isDark ? AppColors.colorBgDark : AppColors.colorBg);
    _textColor =
        _highContrast
            ? (_isDark ? AppColors.colorTextDarkHigh : AppColors.colorTextHigh)
            : (_isDark ? AppColors.colorTextDark : AppColors.colorText);
    _fillColor =
        _highContrast
            ? (_isDark
                ? AppColors.colorInputBgDarkHigh
                : AppColors.colorInputBgHigh)
            : (_isDark ? AppColors.colorInputBgDark : AppColors.colorInputBg);
  }

  @override
  Widget build(BuildContext context) {
    _initTheme(context);
    final isEdit = widget.accommodation != null;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        foregroundColor: _textColor,
        elevation: 0,
        title: Text(
          isEdit ? "Edit Accommodation" : "Add Accommodation",
          style: TextStyle(
            fontSize: _bigText ? 22 : 18,
            color: _textColor,
            fontFamily: 'Helvetica',
            fontWeight: _bigText ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 600) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildField(label: "Name", controller: nameController),
                  _buildField(label: "Address", controller: addressController),
                  _buildField(
                    label: "Nr. of Guests",
                    controller: guestsController,
                    keyboardType: TextInputType.number,
                  ),
                  _buildField(
                    label: "Price per Night",
                    controller: priceController,
                    keyboardType: TextInputType.number,
                  ),
                  _buildField(label: "IBAN", controller: ibanController),
                  _buildField(
                    label: "Description",
                    controller: descriptionController,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 16),
                  _buildImagePicker(),
                  const SizedBox(height: 20),
                  _buildSubmitButton(isEdit),
                ],
              ),
            );
          } else {
            return Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildField(label: "Name", controller: nameController),
                        _buildField(
                          label: "Address",
                          controller: addressController,
                        ),
                        _buildField(
                          label: "Nr. of Guests",
                          controller: guestsController,
                          keyboardType: TextInputType.number,
                        ),
                        _buildField(
                          label: "Price per Night",
                          controller: priceController,
                          keyboardType: TextInputType.number,
                        ),
                        _buildField(label: "IBAN", controller: ibanController),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildField(
                          label: "Description",
                          controller: descriptionController,
                          maxLines: 4,
                        ),
                        const SizedBox(height: 16),
                        _buildImagePicker(),
                        const SizedBox(height: 20),
                        _buildSubmitButton(isEdit),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }
        },
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
      child: Material(
        elevation: 2,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: TextStyle(
            color: _textColor,
            fontSize: _bigText ? 18 : 14,
            fontFamily: 'Helvetica',
            fontWeight: _bigText ? FontWeight.bold : FontWeight.normal,
          ),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(
              color: _textColor,
              fontSize: _bigText ? 16 : 14,
              fontFamily: 'Helvetica',
              fontWeight: _bigText ? FontWeight.bold : FontWeight.normal,
            ),
            filled: true,
            fillColor: _fillColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Photos (${selectedImages.length})",
          style: TextStyle(
            fontWeight: _bigText ? FontWeight.bold : FontWeight.normal,
            color: _textColor,
            fontSize: _bigText ? 16 : 14,
            fontFamily: 'Helvetica',
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickImages,
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: _fillColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.add_photo_alternate, size: 40, color: _textColor),
          ),
        ),
        const SizedBox(height: 8),
        if (selectedImages.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                selectedImages.map((image) {
                  return Stack(
                    alignment: Alignment.topRight,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(image.path),
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedImages.remove(image);
                          });
                        },
                        child: CircleAvatar(
                          radius: 10,
                          backgroundColor: _textColor.withOpacity(0.6),
                          child: Icon(
                            Icons.close,
                            size: 14,
                            color: _backgroundColor,
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
          ),
      ],
    );
  }

  Widget _buildSubmitButton(bool isEdit) {
    return ElevatedButton(
      onPressed: isUploading ? null : _submitAccommodation,
      style: ElevatedButton.styleFrom(
        backgroundColor:
            _highContrast
                ? (_isDark ? AppColors.color1DarkHigh : AppColors.color1High)
                : (_isDark ? AppColors.color1Dark : AppColors.color1),
        elevation: 2,
        padding: EdgeInsets.symmetric(
          horizontal: 30,
          vertical: _bigText ? 16 : 14,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child:
          isUploading
              ? SizedBox(
                width: _bigText ? 24 : 20,
                height: _bigText ? 24 : 20,
                child: CircularProgressIndicator(
                  color: _textColor,
                  strokeWidth: 2,
                ),
              )
              : Text(
                isEdit ? "Save Changes" : "Add Accommodation",
                style: TextStyle(
                  color:
                      _highContrast
                          ? (_isDark
                              ? AppColors.colorButtonTextDarkHigh
                              : AppColors.colorButtonTextHigh)
                          : (_isDark
                              ? AppColors.colorButtonTextDark
                              : AppColors.colorButtonText),
                  fontSize: _bigText ? 20 : 18,
                  fontFamily: 'Helvetica',
                  fontWeight: _bigText ? FontWeight.bold : FontWeight.normal,
                ),
              ),
    );
  }
}
