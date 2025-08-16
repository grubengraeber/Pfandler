import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../services/export_service.dart';
import '../../services/locale_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.settings ?? 'Settings'),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.arrow_left),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        children: [
          // Appearance Section
          _buildSectionHeader(context, 'Appearance'),
          Card(
            margin: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.xs),
                    ),
                    child: Icon(
                      CupertinoIcons.paintbrush,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  title: Text(l10n?.translate('theme') ?? 'Theme'),
                  subtitle: Text(_getThemeModeText(themeMode)),
                  trailing: const Icon(CupertinoIcons.chevron_right),
                  onTap: () => _showThemeDialog(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.xs),
                    ),
                    child: Icon(
                      CupertinoIcons.globe,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  title: Text(l10n?.translate('languageSettings') ?? 'Language'),
                  subtitle: Text(_getLanguageText(ref.watch(localeServiceProvider))),
                  trailing: const Icon(CupertinoIcons.chevron_right),
                  onTap: () => _showLanguageDialog(context, ref),
                ),
              ],
            ),
          ),
          
          // Data & Privacy Section
          _buildSectionHeader(context, 'Data & Privacy'),
          Card(
            margin: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.xs),
                ),
                child: Icon(
                  CupertinoIcons.doc_text,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              title: Text(l10n?.translate('export') ?? 'Export Data'),
              subtitle: const Text('Export as CSV or JSON'),
              trailing: const Icon(CupertinoIcons.chevron_right),
              onTap: () => _showExportDialog(context),
            ),
          ),
          
          // Scanner Settings Section
          _buildSectionHeader(context, 'Scanner'),
          Card(
            margin: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: Container(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.xs),
                    ),
                    child: Icon(
                      CupertinoIcons.camera,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  title: const Text('Auto-Scan'),
                  subtitle: const Text('Automatically scan when camera opens'),
                  value: true,
                  onChanged: (value) {},
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: Container(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.xs),
                    ),
                    child: Icon(
                      CupertinoIcons.speaker_2,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  title: const Text('Scan Sound'),
                  subtitle: const Text('Play sound on successful scan'),
                  value: true,
                  onChanged: (value) {},
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: Container(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.xs),
                    ),
                    child: Icon(
                      CupertinoIcons.device_phone_portrait,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  title: const Text('Vibration'),
                  subtitle: const Text('Vibrate on successful scan'),
                  value: true,
                  onChanged: (value) {},
                ),
              ],
            ),
          ),
          
          // About Section
          _buildSectionHeader(context, 'About'),
          Card(
            margin: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.xs),
                    ),
                    child: Icon(
                      CupertinoIcons.info,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  title: Text(l10n?.translate('version') ?? 'Version'),
                  subtitle: const Text('1.0.0 (Build 2024.1)'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.xs),
                    ),
                    child: Icon(
                      CupertinoIcons.doc_text,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  title: Text(l10n?.translate('termsOfService') ?? 'Terms of Service'),
                  trailing: const Icon(CupertinoIcons.chevron_right),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.xs),
                    ),
                    child: Icon(
                      CupertinoIcons.lock,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  title: Text(l10n?.translate('privacyPolicy') ?? 'Privacy Policy'),
                  trailing: const Icon(CupertinoIcons.chevron_right),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.xs),
                    ),
                    child: Icon(
                      CupertinoIcons.star,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  title: Text(l10n?.translate('rateApp') ?? 'Rate App'),
                  subtitle: const Text('Help us improve'),
                  trailing: const Icon(CupertinoIcons.chevron_right),
                  onTap: () {},
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          letterSpacing: 1.2,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _getThemeModeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  String _getLanguageText(Locale locale) {
    switch (locale.languageCode) {
      case 'en':
        return '🇬🇧  English';
      case 'de':
        return '🇦🇹  Deutsch';
      default:
        return '🇬🇧  English';
    }
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref) {
    final themeModeNotifier = ref.read(themeModeProvider.notifier);
    final currentMode = ref.read(themeModeProvider);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('Light'),
              value: ThemeMode.light,
              groupValue: currentMode,
              onChanged: (value) {
                if (value != null) {
                  themeModeNotifier.setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Dark'),
              value: ThemeMode.dark,
              groupValue: currentMode,
              onChanged: (value) {
                if (value != null) {
                  themeModeNotifier.setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('System'),
              value: ThemeMode.system,
              groupValue: currentMode,
              onChanged: (value) {
                if (value != null) {
                  themeModeNotifier.setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, WidgetRef ref) {
    final localeService = ref.read(localeServiceProvider.notifier);
    final currentLocale = ref.read(localeServiceProvider);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                l10n?.translate('selectLanguage') ?? 'Select Language',
                style: theme.textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: currentLocale.languageCode == 'en' 
                      ? theme.colorScheme.primary.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('🇬🇧', style: TextStyle(fontSize: 24)),
              ),
              title: const Text('English'),
              subtitle: const Text('United Kingdom'),
              trailing: currentLocale.languageCode == 'en'
                  ? Icon(CupertinoIcons.checkmark_circle_fill, 
                         color: theme.colorScheme.primary)
                  : null,
              onTap: () {
                localeService.setLocale(const Locale('en'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: currentLocale.languageCode == 'de' 
                      ? theme.colorScheme.primary.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('🇦🇹', style: TextStyle(fontSize: 24)),
              ),
              title: const Text('Deutsch'),
              subtitle: const Text('Österreich'),
              trailing: currentLocale.languageCode == 'de'
                  ? Icon(CupertinoIcons.checkmark_circle_fill, 
                         color: theme.colorScheme.primary)
                  : null,
              onTap: () {
                localeService.setLocale(const Locale('de'));
                Navigator.pop(context);
              },
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + AppSpacing.md),
          ],
        ),
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    final exportService = ExportService();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choose export format:'),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  
                  // Show loading indicator
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                  
                  final result = await exportService.exportToCsv();
                  
                  // Hide loading indicator
                  if (context.mounted) {
                    Navigator.pop(context);
                    
                    if (result.success) {
                      // Show success and offer to share
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Export Successful'),
                          content: Text('Data exported to ${result.fileName}'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'),
                            ),
                            ElevatedButton.icon(
                              onPressed: () async {
                                Navigator.pop(context);
                                await exportService.shareExport(result.filePath!);
                              },
                              icon: const Icon(CupertinoIcons.share),
                              label: const Text('Share'),
                            ),
                          ],
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Export failed: ${result.error}')),
                      );
                    }
                  }
                },
                icon: const Icon(CupertinoIcons.doc_text),
                label: const Text('Export as CSV'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  
                  // Show loading indicator
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                  
                  final result = await exportService.exportToJson();
                  
                  // Hide loading indicator
                  if (context.mounted) {
                    Navigator.pop(context);
                    
                    if (result.success) {
                      // Show success and offer to share
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Export Successful'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Exported ${result.exportedItems} items'),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                result.fileName!,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'),
                            ),
                            ElevatedButton.icon(
                              onPressed: () async {
                                Navigator.pop(context);
                                await exportService.shareExport(result.filePath!);
                              },
                              icon: const Icon(CupertinoIcons.share),
                              label: const Text('Share'),
                            ),
                          ],
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Export failed: ${result.error}')),
                      );
                    }
                  }
                },
                icon: const Icon(CupertinoIcons.doc_richtext),
                label: const Text('Export as JSON'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}