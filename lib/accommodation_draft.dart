import 'dart:typed_data';
import 'package:hive/hive.dart';

part 'accommodation_draft.g.dart';

@HiveType(typeId: 0)
class AccommodationDraft extends HiveObject {
  @HiveField(0)
  int? remoteId;
  @HiveField(1)
  String name;
  @HiveField(2)
  String address;
  @HiveField(3)
  int guests;
  @HiveField(4)
  double price;
  @HiveField(5)
  String iban;
  @HiveField(6)
  String description;
  @HiveField(7)
  List<Uint8List> images;
  @HiveField(8)
  DateTime createdAt;

  AccommodationDraft({
    required this.remoteId,
    required this.name,
    required this.address,
    required this.guests,
    required this.price,
    required this.iban,
    required this.description,
    required this.images,
  }) : createdAt = DateTime.now();
}