import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_spacing.dart';
import '../l10n/app_localizations.dart';
import '../features/home/home_screen.dart';
import '../features/bottles/manual_entry_screen.dart';
import '../features/bottles/barcode_scanner_screen.dart';
import 'menu_drawer.dart';

class MainNavShell extends ConsumerWidget {
  const MainNavShell({super.key});

  static final GlobalKey<ScaffoldState> scaffoldKey =
      GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      key: scaffoldKey,
      drawer: const MenuDrawer(),
      body: const HomeScreen(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddBottleMenu(context),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(
          CupertinoIcons.plus_circle_fill,
          color: Colors.white,
        ),
        label: const Text(
          'Add Bottle',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        elevation: 6,
        extendedPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.xl),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  void _showAddBottleMenu(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.lg),
        ),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              l10n?.addBottle ?? 'Add Bottle',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Card(
              elevation: 0,
              color: theme.colorScheme.primary.withValues(alpha: 0.05),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.md),
                side: BorderSide(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppSpacing.sm),
                  ),
                  child: Icon(
                    CupertinoIcons.barcode_viewfinder,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
                title: Text(
                  l10n?.scanBarcode ?? 'Scan Barcode',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(l10n?.translate('quickScanCamera') ?? 'Quick scan using camera'),
                trailing: Icon(
                  CupertinoIcons.chevron_right,
                  color: theme.colorScheme.primary,
                  size: 16,
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BarcodeScannerScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Card(
              elevation: 0,
              color: theme.colorScheme.secondary.withValues(alpha: 0.05),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.md),
                side: BorderSide(
                  color: theme.colorScheme.secondary.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppSpacing.sm),
                  ),
                  child: Icon(
                    CupertinoIcons.pencil_circle_fill,
                    color: theme.colorScheme.secondary,
                    size: 24,
                  ),
                ),
                title: Text(
                  l10n?.manualEntry ?? 'Manual Entry',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(l10n?.translate('addBottleManually') ?? 'Add bottle details manually'),
                trailing: Icon(
                  CupertinoIcons.chevron_right,
                  color: theme.colorScheme.secondary,
                  size: 16,
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ManualEntryScreen(),
                    ),
                  );
                },
              ),
            ),
            SizedBox(
                height: MediaQuery.of(context).padding.bottom + AppSpacing.md),
          ],
        ),
      ),
    );
  }
}
