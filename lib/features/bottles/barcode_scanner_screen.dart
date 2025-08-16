import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/bottle.dart';
import '../../services/sync_service.dart';

class BarcodeScannerScreen extends ConsumerStatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  ConsumerState<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends ConsumerState<BarcodeScannerScreen> {
  final _barcodeController = TextEditingController();
  bool _isProcessing = false;
  Map<String, dynamic>? _productInfo;
  
  @override
  void dispose() {
    _barcodeController.dispose();
    super.dispose();
  }

  Future<void> _lookupBarcode() async {
    final barcode = _barcodeController.text.trim();
    if (barcode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a barcode')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final syncService = ref.read(syncServiceProvider.notifier);
      final productData = await syncService.scanBarcode(barcode);
      
      if (productData != null) {
        setState(() => _productInfo = productData);
      } else {
        // If product not found, show manual entry with barcode pre-filled
        _showManualEntryDialog(barcode);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error looking up barcode: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _addBottle() async {
    if (_productInfo == null) return;

    setState(() => _isProcessing = true);

    try {
      final syncService = ref.read(syncServiceProvider.notifier);
      
      final bottle = Bottle(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        barcode: _barcodeController.text,
        name: _productInfo!['name'] ?? 'Unknown Product',
        brand: _productInfo!['brand'] ?? 'Unknown Brand',
        type: _parseBottleType(_productInfo!['containerType']),
        volume: (_productInfo!['volumeML'] ?? 500) / 1000.0,
        depositAmount: (_productInfo!['depositCents'] ?? 25) / 100.0,
        scannedAt: DateTime.now(),
        imageUrl: _productInfo!['imageUrl'],
        isReturned: false,
      );

      await syncService.addBottleLocally(bottle);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bottle added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add bottle: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showManualEntryDialog(String barcode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Product Not Found'),
        content: Text('No product found for barcode: $barcode\n\nWould you like to add it manually?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/manual-entry', arguments: barcode);
            },
            child: const Text('Add Manually'),
          ),
        ],
      ),
    );
  }

  BottleType _parseBottleType(String? type) {
    switch (type?.toLowerCase()) {
      case 'plastic':
        return BottleType.plastic;
      case 'glass':
        return BottleType.glass;
      case 'can':
      case 'aluminum':
        return BottleType.can;
      case 'crate':
        return BottleType.crate;
      default:
        return BottleType.plastic;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode'),
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Scanner placeholder
            Container(
              height: 250,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppSpacing.lg),
                border: Border.all(
                  color: theme.dividerColor,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.barcode_viewfinder,
                    size: 80,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Camera Scanner Coming Soon',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Enter barcode manually below',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppSpacing.xl),
            
            // Manual barcode entry
            Text(
              'Or Enter Barcode Manually',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _barcodeController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Barcode Number',
                      hintText: 'Enter barcode digits',
                      prefixIcon: const Icon(CupertinoIcons.barcode),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.md),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                ElevatedButton(
                  onPressed: _isProcessing ? null : _lookupBarcode,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.lg,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.md),
                    ),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(CupertinoIcons.search),
                ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.xl),
            
            // Product info (if found)
            if (_productInfo != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (_productInfo!['imageUrl'] != null)
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(AppSpacing.sm),
                                image: DecorationImage(
                                  image: NetworkImage(_productInfo!['imageUrl']),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            )
                          else
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(AppSpacing.sm),
                              ),
                              child: Icon(
                                CupertinoIcons.cube_box,
                                size: 40,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _productInfo!['name'] ?? 'Unknown Product',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xxs),
                                Text(
                                  _productInfo!['brand'] ?? 'Unknown Brand',
                                  style: theme.textTheme.bodyMedium,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.sm,
                                        vertical: AppSpacing.xxs,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.success.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(AppSpacing.xs),
                                      ),
                                      child: Text(
                                        '€${((_productInfo!['depositCents'] ?? 25) / 100.0).toStringAsFixed(2)}',
                                        style: TextStyle(
                                          color: AppColors.success,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.sm,
                                        vertical: AppSpacing.xxs,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(AppSpacing.xs),
                                      ),
                                      child: Text(
                                        '${(_productInfo!['volumeML'] ?? 500)}ml',
                                        style: TextStyle(
                                          color: theme.colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isProcessing ? null : _addBottle,
                          icon: const Icon(CupertinoIcons.plus_circle_fill),
                          label: const Text('Add to Collection'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSpacing.md),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: AppSpacing.xl),
            
            // Tips
            Card(
              color: theme.colorScheme.primary.withValues(alpha: 0.05),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.lightbulb,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Tips',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '• Barcode is usually found near the recycling symbol\n'
                      '• Clean the barcode for better scanning\n'
                      '• Most Austrian deposit bottles have 13-digit EAN codes',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}