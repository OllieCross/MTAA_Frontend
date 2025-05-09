import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http_parser/http_parser.dart';
import 'main.dart';
import 'server_config.dart';
import 'app_settings.dart';
import 'dart:typed_data';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'offline_sync_repository.dart';
import 'accommodation_draft.dart';

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
    if (acc != null && acc['aid'] != null) {
      _fetchAccommodationDetails(acc['aid']);
    }
  }

  Future<void> _fetchAccommodationDetails(int aid) async {
    final token = globalToken;
    if (token == null) return;

    final url = Uri.parse('http://$serverIp:$serverPort/accommodation/$aid');
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final acc = data['accommodation'];

      setState(() {
        nameController.text = acc['name'] ?? '';
        addressController.text = acc['location'] ?? '';
        guestsController.text = acc['max_guests']?.toString() ?? '';
        priceController.text = acc['price_per_night']?.toString() ?? '';
        ibanController.text = acc['iban'] ?? '';
        descriptionController.text = acc['description'] ?? '';
      });
    } else {
      debugPrint('Failed to fetch accommodation details');
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

  Future<List<int>?> _convertAndResizeImage(XFile xfile) async {
    try {
      final bytes = await xfile.readAsBytes();
      img.Image? original;

      try {
        original = img.decodeImage(bytes);
      } catch (_) {
        original = null;
      }

      if (original == null) {
        final compressed = await FlutterImageCompress.compressWithFile(
          xfile.path,
          quality: 85,
          format: CompressFormat.jpeg,
          minWidth: 1024,
          minHeight: 1024,
        );
        return compressed;
      }

      final w = original.width;
      final h = original.height;
      final shorter = w < h ? w : h;
      if (shorter > 1024) {
        final scale = 1024 / shorter;
        final newW = (w * scale).round();
        final newH = (h * scale).round();
        original = img.copyResize(
          original,
          width: newW,
          height: newH,
          interpolation: img.Interpolation.average,
        );
      }

      // Encode as JPEG (quality 85 gives a good balance).
      return img.encodeJpg(original, quality: 85);
    } catch (e) {
      debugPrint('Image processing error: $e');
      return null;
    }
  }

Future<void> _submitAccommodation() async {
  if (!mounted) return;

  if (selectedImages.length < 3) {
    ScaffoldMessenger.of(context).showSnackBar(
      _buildSnackBar("Please select at least 3 images."),
    );
    return;
  }

  setState(() => isUploading = true);

  final List<Uint8List> imageBytes = [];
  for (final imgX in selectedImages) {
    final processed = await _convertAndResizeImage(imgX);
    if (processed != null) imageBytes.add(Uint8List.fromList(processed));
  }

  final token = globalToken;
  final conn   = await Connectivity().checkConnectivity();
  final online = !(conn.length == 1 && conn.first == ConnectivityResult.none);

  bool uploaded = false;
  if (token != null && online) {
    uploaded = await _tryUploadOnline(token, imageBytes);
  }

  if (!uploaded) {
    await OfflineSyncRepository.instance.addDraft(
      AccommodationDraft(
        remoteId: widget.accommodation?['aid'],
        name: nameController.text,
        address: addressController.text,
        guests: int.tryParse(guestsController.text) ?? 0,
        price: double.tryParse(priceController.text) ?? 0.0,
        iban: ibanController.text,
        description: descriptionController.text,
        images: imageBytes,
      ),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        _buildSnackBar("Saved locally - will sync when you're back online."),
      );
      Navigator.pop(context);
    }
  }

  setState(() => isUploading = false);
}

Future<bool> _tryUploadOnline(String token, List<Uint8List> images) async {
  final uri = Uri.parse('http://$serverIp:$serverPort/add-accommodation');
  final req = http.MultipartRequest('POST', uri)
    ..headers['Authorization'] = 'Bearer $token'
    ..fields['name']        = nameController.text
    ..fields['address']     = addressController.text
    ..fields['guests']      = guestsController.text
    ..fields['price']       = priceController.text
    ..fields['iban']        = ibanController.text
    ..fields['description'] = descriptionController.text;

  for (final bytes in images) {
    req.files.add(http.MultipartFile.fromBytes(
      'images',
      bytes,
      filename: '${DateTime.now().millisecondsSinceEpoch}.jpg',
      contentType: MediaType('image', 'jpeg'),
    ));
  }

  final resp = await req.send();
  if (resp.statusCode == 201) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        _buildSnackBar("Accommodation added successfully."),
      );
      Navigator.pop(context);
    }
    return true;
  } else {
    // (Optional) read error body for diagnostics
    final err = await resp.stream.bytesToString();
    debugPrint('Upload failed: $err');
    return false;
  }
}

  SnackBar _buildSnackBar(String message) => SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: _textColor,
            fontSize: _bigText ? 16 : 14,
            fontWeight: _bigText ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        backgroundColor: _backgroundColor,
      );

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

  late bool _bigText;
  late bool _highContrast;
  late bool _isDark;
  late Color _backgroundColor;
  late Color _textColor;
  late Color _fillColor;

  void _initTheme(BuildContext context) {
    final settings = context.watch<AppSettings>();
    _bigText = settings.bigText;
    _highContrast = settings.highContrast;
    _isDark = Theme.of(context).brightness == Brightness.dark;
    _backgroundColor = _highContrast
        ? (_isDark ? AppColors.colorBgDarkHigh : AppColors.colorBgHigh)
        : (_isDark ? AppColors.colorBgDark : AppColors.colorBg);
    _textColor = _highContrast
        ? (_isDark ? AppColors.colorTextDarkHigh : AppColors.colorTextHigh)
        : (_isDark ? AppColors.colorTextDark : AppColors.colorText);
    _fillColor = _highContrast
        ? (_isDark ? AppColors.colorInputBgDarkHigh : AppColors.colorInputBgHigh)
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
            children: selectedImages.map((image) {
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
        backgroundColor: _highContrast
            ? (_isDark ? AppColors.color1DarkHigh : AppColors.color1High)
            : (_isDark ? AppColors.color1Dark : AppColors.color1),
        elevation: 2,
        padding: EdgeInsets.symmetric(
          horizontal: 30,
          vertical: _bigText ? 16 : 14,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: isUploading
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
                color: _highContrast
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
