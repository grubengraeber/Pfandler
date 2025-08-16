import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_spacing.dart';
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
        icon: const Icon(CupertinoIcons.plus),
        label: const Text('Add Bottle'),
        elevation: 4,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  void _showAddBottleMenu(BuildContext context) {
    final theme = Theme.of(context);
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
              'Add Bottle',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                ),
                child: Icon(
                  CupertinoIcons.barcode_viewfinder,
                  color: theme.colorScheme.primary,
                ),
              ),
              title: const Text('Scan Barcode'),
              subtitle: const Text('Quick scan using camera'),
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
            const SizedBox(height: AppSpacing.sm),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                ),
                child: Icon(
                  CupertinoIcons.pencil,
                  color: theme.colorScheme.secondary,
                ),
              ),
              title: const Text('Manual Entry'),
              subtitle: const Text('Add bottle details manually'),
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
            SizedBox(
                height: MediaQuery.of(context).padding.bottom + AppSpacing.md),
          ],
        ),
      ),
    );
  }
}
