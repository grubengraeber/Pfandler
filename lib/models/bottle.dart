import 'package:hive/hive.dart';

part 'bottle.g.dart';

@HiveType(typeId: 0)
class Bottle extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String barcode;

  @HiveField(2)
  String name;

  @HiveField(3)
  String brand;

  @HiveField(4)
  BottleType type;

  @HiveField(5)
  double volume; // in liters

  @HiveField(6)
  double depositAmount;

  @HiveField(7)
  DateTime scannedAt;

  @HiveField(8)
  String? imageUrl;

  @HiveField(9)
  String? storeId;

  @HiveField(10)
  bool isReturned;

  @HiveField(11)
  DateTime? returnedAt;

  @HiveField(12)
  String? notes;

  Bottle({
    required this.id,
    required this.barcode,
    required this.name,
    required this.brand,
    required this.type,
    required this.volume,
    required this.depositAmount,
    required this.scannedAt,
    this.imageUrl,
    this.storeId,
    this.isReturned = false,
    this.returnedAt,
    this.notes,
  });

  String get formattedVolume => '${volume}L';
  String get formattedDeposit => '€${depositAmount.toStringAsFixed(2)}';
  
  String get typeLabel {
    switch (type) {
      case BottleType.plastic:
        return 'Plastic Bottle';
      case BottleType.glass:
        return 'Glass Bottle';
      case BottleType.can:
        return 'Aluminum Can';
      case BottleType.crate:
        return 'Bottle Crate';
    }
  }
}

@HiveType(typeId: 1)
enum BottleType {
  @HiveField(0)
  plastic,
  
  @HiveField(1)
  glass,
  
  @HiveField(2)
  can,
  
  @HiveField(3)
  crate,
}