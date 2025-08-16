import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/bottle.dart';

final exportServiceProvider = Provider<ExportService>((ref) {
  return ExportService();
});

class ExportService {
  Future<ExportResult> exportToJson() async {
    try {
      // Prepare data
      final exportData = await _prepareExportData();
      
      // Convert to JSON
      final jsonString = jsonEncode(exportData);
      
      // Get the documents directory
      final directory = await getApplicationDocumentsDirectory();
      
      // Create filename with timestamp
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'pfandler_export_$timestamp.json';
      final filePath = '${directory.path}/$fileName';
      
      // Write to file
      final file = File(filePath);
      await file.writeAsString(jsonString);
      
      return ExportResult(
        success: true,
        filePath: filePath,
        fileName: fileName,
        exportedItems: exportData['bottles']?.length ?? 0,
      );
    } catch (e) {
      return ExportResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  Future<ExportResult> exportToCsv() async {
    try {
      // Prepare CSV data
      final csvString = await _prepareCsvData();
      
      // Get the documents directory
      final directory = await getApplicationDocumentsDirectory();
      
      // Create filename with timestamp
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'pfandler_export_$timestamp.csv';
      final filePath = '${directory.path}/$fileName';
      
      // Write to file
      final file = File(filePath);
      await file.writeAsString(csvString);
      
      return ExportResult(
        success: true,
        filePath: filePath,
        fileName: fileName,
      );
    } catch (e) {
      return ExportResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  Future<void> shareExport(String filePath) async {
    await Share.shareXFiles(
      [XFile(filePath)],
      subject: 'Pfandler Export',
      text: 'Exported data from Pfandler app',
    );
  }

  Future<Map<String, dynamic>> _prepareExportData() async {
    final data = <String, dynamic>{};
    
    // Add metadata
    data['metadata'] = {
      'app_version': '1.0.0',
      'export_date': DateTime.now().toIso8601String(),
      'device_info': {
        'platform': Platform.operatingSystem,
        'version': Platform.operatingSystemVersion,
      },
    };
    
    // Export bottles data
    if (await Hive.boxExists('bottles')) {
      final bottlesBox = await Hive.openBox<Bottle>('bottles');
      final bottles = bottlesBox.values.map((bottle) => {
        'id': bottle.id,
        'type': bottle.type.toString(),
        'brand': bottle.brand,
        'name': bottle.name,
        'volume': bottle.volume,
        'depositAmount': bottle.depositAmount,
        'barcode': bottle.barcode,
        'scannedAt': bottle.scannedAt.toIso8601String(),
        'returnedAt': bottle.returnedAt?.toIso8601String(),
        'isReturned': bottle.isReturned,
        'storeId': bottle.storeId,
        'notes': bottle.notes,
      }).toList();
      
      data['bottles'] = bottles;
      await bottlesBox.close();
    }
    
    // Export user preferences
    if (await Hive.boxExists('preferences')) {
      final prefsBox = await Hive.openBox('preferences');
      data['preferences'] = {
        'theme_mode': prefsBox.get('theme_mode', defaultValue: 'system'),
        'auto_scan': prefsBox.get('auto_scan', defaultValue: true),
        'scan_sound': prefsBox.get('scan_sound', defaultValue: true),
        'vibration': prefsBox.get('vibration', defaultValue: true),
        'currency': prefsBox.get('currency', defaultValue: 'EUR'),
        'language': prefsBox.get('language', defaultValue: 'en'),
      };
      await prefsBox.close();
    }
    
    // Export statistics
    if (await Hive.boxExists('statistics')) {
      final statsBox = await Hive.openBox('statistics');
      data['statistics'] = {
        'total_bottles': statsBox.get('total_bottles', defaultValue: 0),
        'total_value': statsBox.get('total_value', defaultValue: 0.0),
        'bottles_per_month': statsBox.get('bottles_per_month', defaultValue: {}),
        'favorite_stores': statsBox.get('favorite_stores', defaultValue: []),
        'deposit_types_count': statsBox.get('deposit_types_count', defaultValue: {}),
      };
      await statsBox.close();
    }
    
    // Export return history
    if (await Hive.boxExists('returns')) {
      final returnsBox = await Hive.openBox('returns');
      final returns = returnsBox.values.map((returnData) => {
        'id': returnData['id'],
        'date': returnData['date'],
        'store_id': returnData['store_id'],
        'store_name': returnData['store_name'],
        'bottle_count': returnData['bottle_count'],
        'total_value': returnData['total_value'],
        'receipt_image': returnData['receipt_image'],
      }).toList();
      
      data['returns'] = returns;
      await returnsBox.close();
    }
    
    return data;
  }

  Future<String> _prepareCsvData() async {
    final StringBuffer csv = StringBuffer();
    
    // Add CSV headers
    csv.writeln('Date,Type,Brand,Volume,Deposit Amount,Returned,Store,Notes');
    
    // Add bottle data
    if (await Hive.boxExists('bottles')) {
      final bottlesBox = await Hive.openBox<Bottle>('bottles');
      
      for (final bottle in bottlesBox.values) {
        final date = DateFormat('yyyy-MM-dd HH:mm').format(bottle.scannedAt);
        final returned = bottle.isReturned ? 'Yes' : 'No';
        final store = bottle.storeId ?? 'N/A';
        final notes = bottle.notes?.replaceAll(',', ';') ?? '';
        
        csv.writeln('$date,${bottle.type},${bottle.brand},${bottle.volume},${bottle.depositAmount},$returned,$store,$notes');
      }
      
      await bottlesBox.close();
    }
    
    return csv.toString();
  }

  Future<bool> importFromJson(String filePath) async {
    try {
      final file = File(filePath);
      final jsonString = await file.readAsString();
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      
      // Import bottles
      if (data.containsKey('bottles')) {
        final bottlesBox = await Hive.openBox<Bottle>('bottles');
        await bottlesBox.clear();
        
        final bottles = data['bottles'] as List;
        for (final bottleData in bottles) {
          final bottle = Bottle(
            id: bottleData['id'],
            type: _parseBottleType(bottleData['type']),
            brand: bottleData['brand'],
            name: bottleData['name'] ?? bottleData['brand'],
            volume: bottleData['volume'],
            depositAmount: bottleData['depositAmount'],
            barcode: bottleData['barcode'],
            scannedAt: DateTime.parse(bottleData['scannedAt']),
            returnedAt: bottleData['returnedAt'] != null 
              ? DateTime.parse(bottleData['returnedAt']) 
              : null,
            isReturned: bottleData['isReturned'],
            storeId: bottleData['storeId'],
            notes: bottleData['notes'],
          );
          await bottlesBox.add(bottle);
        }
        
        await bottlesBox.close();
      }
      
      // Import preferences
      if (data.containsKey('preferences')) {
        final prefsBox = await Hive.openBox('preferences');
        final prefs = data['preferences'] as Map<String, dynamic>;
        
        for (final entry in prefs.entries) {
          await prefsBox.put(entry.key, entry.value);
        }
        
        await prefsBox.close();
      }
      
      // Import statistics
      if (data.containsKey('statistics')) {
        final statsBox = await Hive.openBox('statistics');
        final stats = data['statistics'] as Map<String, dynamic>;
        
        for (final entry in stats.entries) {
          await statsBox.put(entry.key, entry.value);
        }
        
        await statsBox.close();
      }
      
      return true;
    } catch (e) {
      debugPrint('Import error: $e');
      return false;
    }
  }

  BottleType _parseBottleType(String typeString) {
    // Parse the bottle type from string representation
    final typeName = typeString.split('.').last;
    return BottleType.values.firstWhere(
      (type) => type.toString().split('.').last == typeName,
      orElse: () => BottleType.plastic,
    );
  }
}

class ExportResult {
  final bool success;
  final String? filePath;
  final String? fileName;
  final String? error;
  final int exportedItems;

  ExportResult({
    required this.success,
    this.filePath,
    this.fileName,
    this.error,
    this.exportedItems = 0,
  });
}