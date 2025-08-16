import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../models/bottle.dart';
import '../../services/sync_service.dart';

class ManualEntryScreen extends ConsumerStatefulWidget {
  const ManualEntryScreen({super.key});

  @override
  ConsumerState<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends ConsumerState<ManualEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _barcodeController = TextEditingController();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _volumeController = TextEditingController();
  final _notesController = TextEditingController();
  
  BottleType _selectedType = BottleType.plastic;
  double _depositAmount = 0.25;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _barcodeController.dispose();
    _nameController.dispose();
    _brandController.dispose();
    _volumeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitBottle() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final syncService = ref.read(syncServiceProvider.notifier);
      
      final bottle = Bottle(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        barcode: _barcodeController.text.isEmpty 
            ? 'MANUAL_${DateTime.now().millisecondsSinceEpoch}'
            : _barcodeController.text,
        name: _nameController.text,
        brand: _brandController.text,
        type: _selectedType,
        volume: double.tryParse(_volumeController.text) ?? 0.5,
        depositAmount: _depositAmount,
        scannedAt: DateTime.now(),
        isReturned: false,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
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
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manual Entry'),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submitBottle,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: AppSpacing.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Barcode (optional)
              TextFormField(
                controller: _barcodeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Barcode (Optional)',
                  hintText: 'Enter barcode number',
                  prefixIcon: const Icon(CupertinoIcons.barcode),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.md),
                  ),
                ),
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              // Product Name
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Product Name',
                  hintText: 'e.g., Coca Cola 0.5L',
                  prefixIcon: const Icon(CupertinoIcons.cube_box),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.md),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a product name';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              // Brand
              TextFormField(
                controller: _brandController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Brand',
                  hintText: 'e.g., Coca Cola',
                  prefixIcon: const Icon(CupertinoIcons.tag),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.md),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a brand';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              // Container Type
              Text(
                'Container Type',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                children: BottleType.values.map((type) {
                  return ChoiceChip(
                    label: Text(_getTypeLabel(type)),
                    selected: _selectedType == type,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedType = type;
                          _depositAmount = _getDefaultDeposit(type);
                        });
                      }
                    },
                  );
                }).toList(),
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              // Volume
              TextFormField(
                controller: _volumeController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Volume (Liters)',
                  hintText: 'e.g., 0.5',
                  prefixIcon: const Icon(CupertinoIcons.drop),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.md),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter volume';
                  }
                  final volume = double.tryParse(value);
                  if (volume == null || volume <= 0) {
                    return 'Please enter a valid volume';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              // Deposit Amount
              Text(
                'Deposit Amount',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                children: [0.09, 0.15, 0.25, 0.30].map((amount) {
                  return ChoiceChip(
                    label: Text('€${amount.toStringAsFixed(2)}'),
                    selected: _depositAmount == amount,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _depositAmount = amount);
                      }
                    },
                  );
                }).toList(),
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              // Notes (optional)
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'Any additional information',
                  prefixIcon: const Icon(CupertinoIcons.pencil),
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.md),
                  ),
                ),
              ),
              
              const SizedBox(height: AppSpacing.xl),
              
              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitBottle,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(CupertinoIcons.plus_circle_fill),
                  label: Text(_isSubmitting ? 'Adding...' : 'Add Bottle'),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.md),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  String _getTypeLabel(BottleType type) {
    switch (type) {
      case BottleType.plastic:
        return 'Plastic';
      case BottleType.glass:
        return 'Glass';
      case BottleType.can:
        return 'Can';
      case BottleType.crate:
        return 'Crate';
    }
  }

  double _getDefaultDeposit(BottleType type) {
    switch (type) {
      case BottleType.plastic:
        return 0.25;
      case BottleType.glass:
        return 0.09;
      case BottleType.can:
        return 0.25;
      case BottleType.crate:
        return 0.30;
    }
  }
}