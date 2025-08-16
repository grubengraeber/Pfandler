import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pfandler/models/bottle.dart';
import 'dart:io';

void main() {
  late Directory tempDir;
  
  setUpAll(() async {
    // Initialize Hive for testing
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);
  });
  
  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });
  
  group('Bottle Model Tests', () {
    test('Bottle creation with all properties', () {
      final now = DateTime.now();
      final bottle = Bottle(
        id: 'bottle_123',
        barcode: '1234567890',
        name: 'Coca Cola',
        brand: 'Coca Cola Company',
        type: BottleType.plastic,
        volume: 0.5,
        depositAmount: 0.25,
        scannedAt: now,
        imageUrl: 'https://example.com/image.jpg',
        storeId: 'store_456',
        isReturned: false,
        returnedAt: null,
        notes: 'Test bottle',
      );

      expect(bottle.id, 'bottle_123');
      expect(bottle.barcode, '1234567890');
      expect(bottle.name, 'Coca Cola');
      expect(bottle.brand, 'Coca Cola Company');
      expect(bottle.type, BottleType.plastic);
      expect(bottle.volume, 0.5);
      expect(bottle.depositAmount, 0.25);
      expect(bottle.scannedAt, now);
      expect(bottle.imageUrl, 'https://example.com/image.jpg');
      expect(bottle.storeId, 'store_456');
      expect(bottle.isReturned, false);
      expect(bottle.returnedAt, isNull);
      expect(bottle.notes, 'Test bottle');
    });

    test('Bottle formatted volume returns correct string', () {
      final bottle = Bottle(
        id: '1',
        barcode: '123',
        name: 'Test',
        brand: 'Test Brand',
        type: BottleType.plastic,
        volume: 0.5,
        depositAmount: 0.25,
        scannedAt: DateTime.now(),
      );

      expect(bottle.formattedVolume, '0.5L');

      final bottle2 = Bottle(
        id: '2',
        barcode: '456',
        name: 'Test2',
        brand: 'Test Brand',
        type: BottleType.glass,
        volume: 0.33,
        depositAmount: 0.15,
        scannedAt: DateTime.now(),
      );

      expect(bottle2.formattedVolume, '0.33L');
    });

    test('Bottle formatted deposit returns correct string', () {
      final bottle = Bottle(
        id: '1',
        barcode: '123',
        name: 'Test',
        brand: 'Test Brand',
        type: BottleType.plastic,
        volume: 0.5,
        depositAmount: 0.25,
        scannedAt: DateTime.now(),
      );

      expect(bottle.formattedDeposit, '€0.25');

      final bottle2 = Bottle(
        id: '2',
        barcode: '456',
        name: 'Test2',
        brand: 'Test Brand',
        type: BottleType.can,
        volume: 0.33,
        depositAmount: 0.15,
        scannedAt: DateTime.now(),
      );

      expect(bottle2.formattedDeposit, '€0.15');
    });

    test('Bottle type label returns correct string', () {
      final plasticBottle = Bottle(
        id: '1',
        barcode: '123',
        name: 'Plastic',
        brand: 'Brand',
        type: BottleType.plastic,
        volume: 0.5,
        depositAmount: 0.25,
        scannedAt: DateTime.now(),
      );
      expect(plasticBottle.typeLabel, 'Plastic Bottle');

      final glassBottle = Bottle(
        id: '2',
        barcode: '456',
        name: 'Glass',
        brand: 'Brand',
        type: BottleType.glass,
        volume: 0.33,
        depositAmount: 0.15,
        scannedAt: DateTime.now(),
      );
      expect(glassBottle.typeLabel, 'Glass Bottle');

      final canBottle = Bottle(
        id: '3',
        barcode: '789',
        name: 'Can',
        brand: 'Brand',
        type: BottleType.can,
        volume: 0.33,
        depositAmount: 0.25,
        scannedAt: DateTime.now(),
      );
      expect(canBottle.typeLabel, 'Aluminum Can');

      final crateBottle = Bottle(
        id: '4',
        barcode: '012',
        name: 'Crate',
        brand: 'Brand',
        type: BottleType.crate,
        volume: 12.0,
        depositAmount: 3.0,
        scannedAt: DateTime.now(),
      );
      expect(crateBottle.typeLabel, 'Bottle Crate');
    });

    test('Bottle returned status', () {
      final now = DateTime.now();
      final unreturnedBottle = Bottle(
        id: '1',
        barcode: '123',
        name: 'Test',
        brand: 'Brand',
        type: BottleType.plastic,
        volume: 0.5,
        depositAmount: 0.25,
        scannedAt: now,
        isReturned: false,
      );

      expect(unreturnedBottle.isReturned, false);
      expect(unreturnedBottle.returnedAt, isNull);

      final returnedBottle = Bottle(
        id: '2',
        barcode: '456',
        name: 'Test',
        brand: 'Brand',
        type: BottleType.plastic,
        volume: 0.5,
        depositAmount: 0.25,
        scannedAt: now.subtract(const Duration(days: 1)),
        isReturned: true,
        returnedAt: now,
      );

      expect(returnedBottle.isReturned, true);
      expect(returnedBottle.returnedAt, now);
    });

    test('BottleType enum values', () {
      expect(BottleType.values.length, 4);
      expect(BottleType.values.contains(BottleType.plastic), true);
      expect(BottleType.values.contains(BottleType.glass), true);
      expect(BottleType.values.contains(BottleType.can), true);
      expect(BottleType.values.contains(BottleType.crate), true);
    });
  });
}