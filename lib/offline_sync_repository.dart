import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'connectivity_service.dart';
import 'accommodation_draft.dart';
import 'server_config.dart';
import 'main.dart';
import 'dart:async';

class OfflineSyncRepository {
  OfflineSyncRepository._() {
    ConnectivityService.instance.status$.listen((s) {
      if (s == NetworkStatus.online) _flushQueue();
    });
  }

  final _success = StreamController<AccommodationDraft>.broadcast();
  Stream<AccommodationDraft> get uploadSuccess => _success.stream;

  static final instance = OfflineSyncRepository._();
  static const _boxName = 'accommodationDrafts';

  bool _isFlushing = false;

  Future<void> addDraft(AccommodationDraft d) async {
    final box = await Hive.openBox<AccommodationDraft>(_boxName);
    await box.add(d);
  }

  Future<void> _flushQueue() async {
    if (_isFlushing) return;
    _isFlushing = true;
    try {
      final token = globalToken;
      if (token == null) return;
      final box = await Hive.openBox<AccommodationDraft>(_boxName);

      for (final draft in List<AccommodationDraft>.from(box.values)) {
        final ok = await _uploadDraft(draft, token);
        if (ok) {
          await draft.delete();
          _success.add(draft);
        }
      }
    } finally {
      _isFlushing = false;
    }
  }

  Future<bool> _uploadDraft(AccommodationDraft d, String token) async {
    final uri = Uri.parse('http://$serverIp:$serverPort/add-accommodation');
    final req = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields.addAll({
        'name': d.name,
        'address': d.address,
        'guests': d.guests.toString(),
        'price': d.price.toString(),
        'iban': d.iban,
        'description': d.description,
      });

    for (final bytes in d.images) {
      req.files.add(http.MultipartFile.fromBytes(
        'images',
        bytes,
        filename: '${DateTime.now().millisecondsSinceEpoch}.jpg',
        contentType: MediaType('image', 'jpeg'),
      ));
    }

    final resp = await req.send();
    return resp.statusCode == 201;
  }
}