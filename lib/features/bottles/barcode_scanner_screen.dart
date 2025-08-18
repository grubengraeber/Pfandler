import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../models/bottle.dart';
import '../../services/sync_service.dart';

class BarcodeScannerScreen extends ConsumerStatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  ConsumerState<BarcodeScannerScreen> createState() =>
      _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends ConsumerState<BarcodeScannerScreen> {
  final _barcodeController = TextEditingController();
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );
  
  bool _isProcessing = false;
  bool _useCameraMode = true;
  Map<String, dynamic>? _productInfo;
  String? _lastScannedBarcode;

  @override
  void dispose() {
    _barcodeController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _processBarcode(String barcode) async {
    // Prevent processing the same barcode multiple times
    if (_lastScannedBarcode == barcode || _isProcessing) return;
    
    _lastScannedBarcode = barcode;
    _barcodeController.text = barcode;
    
    setState(() => _isProcessing = true);

    try {
      final syncService = ref.read(syncServiceProvider.notifier);
      final productData = await syncService.scanBarcode(barcode);

      if (productData != null) {
        setState(() {
          _productInfo = productData;
          _useCameraMode = false; // Switch to product view
        });
      } else {
        // If product not found, show manual entry with barcode pre-filled
        _showManualEntryDialog(barcode);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)?.translate('errorLookingUpBarcode') ?? 'Error looking up barcode'}: $e'),
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

  Future<void> _lookupBarcode() async {
    final barcode = _barcodeController.text.trim();
    if (barcode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)?.translate('pleaseEnterBarcode') ?? 'Please enter a barcode')),
      );
      return;
    }

    await _processBarcode(barcode);
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
          SnackBar(
            content: Text(AppLocalizations.of(context)?.translate('bottleAddedSuccess') ?? 'Bottle added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)?.translate('failedToAddBottle') ?? 'Failed to add bottle'}: $e'),
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
        title: Text(AppLocalizations.of(context)?.translate('productNotFound') ?? 'Product Not Found'),
        content: Text(
            '${AppLocalizations.of(context)?.translate('noProductFound') ?? 'No product found for barcode'}: $barcode\n\n${AppLocalizations.of(context)?.translate('wouldYouLikeToAddManually') ?? 'Would you like to add it manually?'}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context)
                  .pushNamed('/manual-entry', arguments: barcode);
            },
            child: Text(AppLocalizations.of(context)?.translate('addManually') ?? 'Add Manually'),
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

  void _resetScanner() {
    setState(() {
      _productInfo = null;
      _lastScannedBarcode = null;
      _useCameraMode = true;
      _barcodeController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.scanBarcode ?? 'Scan Barcode'),
        actions: [
          if (!_useCameraMode)
            IconButton(
              icon: const Icon(CupertinoIcons.camera),
              onPressed: _resetScanner,
              tooltip: l10n?.translate('scanAnother') ?? 'Scan Another',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Camera Scanner or Manual Entry Toggle
            Container(
              height: 350,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppSpacing.lg),
                border: Border.all(
                  color: theme.dividerColor,
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.lg - 2),
                child: _useCameraMode
                    ? Stack(
                        children: [
                          MobileScanner(
                            controller: _scannerController,
                            onDetect: (capture) {
                              final List<Barcode> barcodes = capture.barcodes;
                              for (final barcode in barcodes) {
                                if (barcode.rawValue != null) {
                                  _processBarcode(barcode.rawValue!);
                                  break;
                                }
                              }
                            },
                          ),
                          // Scanner overlay
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.5),
                                  Colors.transparent,
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.5),
                                ],
                                stops: const [0.0, 0.2, 0.8, 1.0],
                              ),
                            ),
                          ),
                          Center(
                            child: Container(
                              width: 250,
                              height: 250,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: theme.colorScheme.primary,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(AppSpacing.md),
                              ),
                            ),
                          ),
                          // Instructions
                          Positioned(
                            top: AppSpacing.lg,
                            left: 0,
                            right: 0,
                            child: Text(
                              l10n?.translate('alignBarcodeWithinFrame') ?? 'Align barcode within frame',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          // Processing indicator
                          if (_isProcessing)
                            Container(
                              color: Colors.black.withValues(alpha: 0.7),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          // Torch button
                          Positioned(
                            bottom: AppSpacing.lg,
                            right: AppSpacing.lg,
                            child: FloatingActionButton.small(
                              heroTag: 'torch_toggle_fab',
                              onPressed: () => _scannerController.toggleTorch(),
                              backgroundColor: theme.colorScheme.primary,
                              child: ValueListenableBuilder(
                                valueListenable: _scannerController,
                                builder: (context, state, child) {
                                  final torchState = state.torchState;
                                  return Icon(
                                    torchState == TorchState.on
                                        ? CupertinoIcons.bolt_fill
                                        : CupertinoIcons.bolt,
                                    color: Colors.white,
                                  );
                                },
                              ),
                            ),
                          ),
                          // Camera switch button
                          Positioned(
                            bottom: AppSpacing.lg,
                            left: AppSpacing.lg,
                            child: FloatingActionButton.small(
                              heroTag: 'camera_switch_fab',
                              onPressed: () => _scannerController.switchCamera(),
                              backgroundColor: theme.colorScheme.primary,
                              child: const Icon(
                                CupertinoIcons.camera_rotate,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            CupertinoIcons.checkmark_circle_fill,
                            size: 80,
                            color: AppColors.success,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            l10n?.translate('barcodeScanned') ?? 'Barcode Scanned',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            _barcodeController.text,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Manual barcode entry
            Text(
              l10n?.translate('orEnterBarcodeManually') ?? 'Or Enter Barcode Manually',
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
                      labelText: l10n?.translate('barcodeNumber') ?? 'Barcode Number',
                      hintText: l10n?.translate('enterBarcodeDigits') ?? 'Enter barcode digits',
                      prefixIcon: const Icon(CupertinoIcons.barcode),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.md),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _lookupBarcode,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.lg,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.md),
                    ),
                    foregroundColor: Colors.white,
                    backgroundColor: theme.colorScheme.primary,
                  ),
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          CupertinoIcons.search,
                          color: Colors.white,
                        ),
                  label: Text(
                    _isProcessing ? (l10n?.translate('searching') ?? 'Searching...') : (l10n?.translate('lookUp') ?? 'Look up'),
                    style: const TextStyle(color: Colors.white),
                  ),
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
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.sm),
                                image: DecorationImage(
                                  image:
                                      NetworkImage(_productInfo!['imageUrl']),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            )
                          else
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.1),
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.sm),
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
                                        color: AppColors.success
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(
                                            AppSpacing.xs),
                                      ),
                                      child: Text(
                                        '€${((_productInfo!['depositCents'] ?? 25) / 100.0).toStringAsFixed(2)}',
                                        style: const TextStyle(
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
                                        color: theme.colorScheme.primary
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(
                                            AppSpacing.xs),
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
                          label: Text(l10n?.translate('addToCollection') ?? 'Add to Collection'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.md),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.md),
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
                          l10n?.translate('tips') ?? 'Tips',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '• ${l10n?.translate('tipPointCamera') ?? 'Point camera at barcode and hold steady'}\n'
                      '• ${l10n?.translate('tipUseTorch') ?? 'Use torch button in low light conditions'}\n'
                      '• ${l10n?.translate('tipCleanBarcode') ?? 'Clean the barcode for better scanning'}\n'
                      '• ${l10n?.translate('tipAustrianBottles') ?? 'Most Austrian deposit bottles have 13-digit EAN codes'}',
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