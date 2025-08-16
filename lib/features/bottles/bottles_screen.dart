import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../models/bottle.dart';
import '../../services/auth_service.dart';
import '../../services/sync_service.dart';

class BottlesScreen extends ConsumerWidget {
  const BottlesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.bottles ?? 'My Bottles'),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final authState = ref.watch(authProvider);
          
          if (!authState.isAuthenticated) {
            return Center(
              child: Text(l10n?.translate('signInToViewBottles') ?? 'Please sign in to view your bottles'),
            );
          }
          
          // Trigger sync when screen loads
          ref.listen(syncServiceProvider, (previous, current) {
            if (current.status == SyncStatus.error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${l10n?.translate('syncFailed') ?? 'Sync failed'}: ${current.error}'),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            }
          });
          
          // Watch both local bottles and sync status
          final bottlesAsync = ref.watch(bottlesProvider);
          final syncStatus = ref.watch(syncStatusProvider);
          
          return bottlesAsync.when(
            data: (bottles) {
              return RefreshIndicator(
                onRefresh: () async {
                  // Trigger manual sync
                  final syncService = ref.read(syncServiceProvider.notifier);
                  await syncService.performSync();
                  // Refresh the bottles data
                  ref.invalidate(bottlesProvider);
                },
                child: bottles.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.6,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  CupertinoIcons.cube_box,
                                  size: 64,
                                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  l10n?.translate('noBottlesYet') ?? 'No bottles scanned yet',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Theme.of(context).textTheme.bodyMedium?.color,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  l10n?.translate('startScanning') ?? 'Start scanning bottles to track your returns',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                if (syncStatus == SyncStatus.syncing) ...[
                                  const SizedBox(height: AppSpacing.lg),
                                  const CircularProgressIndicator(),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    'Syncing with server...',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
              
                  : Column(
                      children: [
                        // Sync status indicator
                        if (syncStatus == SyncStatus.syncing)
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            margin: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppSpacing.sm),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  'Syncing with server...',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        // Bottles list
                        Expanded(
                          child: ListView.builder(
                            padding: AppSpacing.pagePadding,
                            itemCount: bottles.length,
                            itemBuilder: (context, index) {
                              final bottle = bottles[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                                child: ListTile(
                                  leading: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(AppSpacing.xs),
                                    ),
                                    child: Icon(
                                      bottle.isReturned ? CupertinoIcons.checkmark_seal_fill : CupertinoIcons.cube_box,
                                      color: bottle.isReturned 
                                        ? Theme.of(context).colorScheme.secondary
                                        : Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  title: Text(bottle.brand.isNotEmpty ? bottle.brand : 'Unknown Brand'),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('${bottle.typeLabel} - €${bottle.depositAmount.toStringAsFixed(2)}'),
                                      if (bottle.isReturned)
                                        Text(
                                          'Returned on ${bottle.returnedAt?.day}/${bottle.returnedAt?.month}/${bottle.returnedAt?.year}',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Theme.of(context).colorScheme.secondary,
                                          ),
                                        ),
                                    ],
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '€${bottle.depositAmount.toStringAsFixed(2)}',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              color: bottle.isReturned
                                                ? Theme.of(context).colorScheme.secondary
                                                : Theme.of(context).colorScheme.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      if (!bottle.isReturned)
                                        Text(
                                          'Pending',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Theme.of(context).colorScheme.outline,
                                          ),
                                        ),
                                    ],
                                  ),
                                  onTap: () {
                                    _showBottleDetails(context, bottle);
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
              );
            },
            loading: () => Column(
              children: [
                const SizedBox(height: AppSpacing.xl),
                const CircularProgressIndicator(),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Loading bottles...',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.exclamationmark_triangle,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Error loading bottles',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    error.toString(),
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  void _showBottleDetails(BuildContext context, Bottle bottle) {
    final theme = Theme.of(context);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.lg),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppSpacing.md),
                          ),
                          child: Icon(
                            bottle.isReturned ? CupertinoIcons.checkmark_seal_fill : CupertinoIcons.cube_box,
                            color: bottle.isReturned 
                              ? theme.colorScheme.secondary
                              : theme.colorScheme.primary,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bottle.brand.isNotEmpty ? bottle.brand : 'Unknown Brand',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                bottle.typeLabel,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.textTheme.bodySmall?.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    
                    Text(
                      'Details',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    
                    _buildDetailRow('Barcode', bottle.barcode, theme),
                    _buildDetailRow('Volume', bottle.formattedVolume, theme),
                    _buildDetailRow('Deposit', bottle.formattedDeposit, theme),
                    _buildDetailRow('Scanned', 
                      '\${bottle.scannedAt.day}/\${bottle.scannedAt.month}/\${bottle.scannedAt.year}', theme),
                    
                    if (bottle.isReturned && bottle.returnedAt != null)
                      _buildDetailRow('Returned', 
                        '\${bottle.returnedAt!.day}/\${bottle.returnedAt!.month}/\${bottle.returnedAt!.year}', theme),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
