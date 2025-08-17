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
          _buildSectionHeader(context, l10n?.translate('appearance') ?? 'Appearance'),
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
                  subtitle: Text(_getThemeModeText(context, themeMode)),
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
          _buildSectionHeader(context, l10n?.translate('dataPrivacy') ?? 'Data & Privacy'),
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
              subtitle: Text(l10n?.translate('exportDescription') ?? 'Export as CSV or JSON'),
              trailing: const Icon(CupertinoIcons.chevron_right),
              onTap: () => _showExportDialog(context),
            ),
          ),
          
          // Scanner Settings Section
          _buildSectionHeader(context, l10n?.translate('scanner') ?? 'Scanner'),
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
                  title: Text(l10n?.translate('autoScan') ?? 'Auto-Scan'),
                  subtitle: Text(l10n?.translate('autoScanDescription') ?? 'Automatically scan when camera opens'),
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
                  title: Text(l10n?.translate('scanSound') ?? 'Scan Sound'),
                  subtitle: Text(l10n?.translate('scanSoundDescription') ?? 'Play sound on successful scan'),
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
                  title: Text(l10n?.translate('vibration') ?? 'Vibration'),
                  subtitle: Text(l10n?.translate('vibrationDescription') ?? 'Vibrate on successful scan'),
                  value: true,
                  onChanged: (value) {},
                ),
              ],
            ),
          ),
          
          // About Section
          _buildSectionHeader(context, l10n?.translate('about') ?? 'About'),
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

  String _getThemeModeText(BuildContext context, ThemeMode mode) {
    final l10n = AppLocalizations.of(context);
    switch (mode) {
      case ThemeMode.light:
        return l10n?.translate('light') ?? 'Light';
      case ThemeMode.dark:
        return l10n?.translate('dark') ?? 'Dark';
      case ThemeMode.system:
        return l10n?.translate('system') ?? 'System';
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
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom,
        ),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.lg),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                l10n?.translate('chooseTheme') ?? 'Choose Theme',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Theme options
            RadioListTile<ThemeMode>(
              title: Text(
                l10n?.translate('light') ?? 'Light',
                style: theme.textTheme.bodyLarge,
              ),
              value: ThemeMode.light,
              groupValue: currentMode,
              activeColor: theme.colorScheme.primary,
              onChanged: (value) {
                if (value != null) {
                  themeModeNotifier.setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: Text(
                l10n?.translate('dark') ?? 'Dark',
                style: theme.textTheme.bodyLarge,
              ),
              value: ThemeMode.dark,
              groupValue: currentMode,
              activeColor: theme.colorScheme.primary,
              onChanged: (value) {
                if (value != null) {
                  themeModeNotifier.setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: Text(
                l10n?.translate('system') ?? 'System',
                style: theme.textTheme.bodyLarge,
              ),
              value: ThemeMode.system,
              groupValue: currentMode,
              activeColor: theme.colorScheme.primary,
              onChanged: (value) {
                if (value != null) {
                  themeModeNotifier.setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
            const SizedBox(height: AppSpacing.md),
            // Cancel button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  ),
                  child: Text(
                    l10n?.cancel ?? 'Cancel',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
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
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom,
        ),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.lg),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                l10n?.translate('selectLanguage') ?? 'Select Language',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
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
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom,
        ),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.lg),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                l10n?.translate('exportData') ?? 'Export Data',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                l10n?.translate('chooseExportFormat') ?? 'Choose export format:',
                style: theme.textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // Export as CSV button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: SizedBox(
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
                                  if (result.filePath != null) {
                                    await exportService.shareExport(result.filePath!);
                                  }
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
            ),
            const SizedBox(height: AppSpacing.sm),
            // Export as JSON button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: SizedBox(
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
                                  if (result.filePath != null) {
                                    await exportService.shareExport(result.filePath!);
                                  }
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
            ),
            const SizedBox(height: AppSpacing.md),
            // Cancel button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  ),
                  child: Text(
                    l10n?.cancel ?? 'Cancel',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}