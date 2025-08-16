import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../l10n/app_localizations.dart';
import '../features/settings/settings_screen.dart';
import '../features/bottles/bottles_screen.dart';
import '../features/analytics/analytics_screen.dart';
import '../features/profile/profile_screen.dart';

class MenuDrawer extends ConsumerWidget {
  const MenuDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + AppSpacing.lg,
              bottom: AppSpacing.lg,
              left: AppSpacing.md,
              right: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              gradient: isDarkMode
                  ? AppColors.darkGradient
                  : AppColors.primaryGradient,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(AppSpacing.md),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.md),
                    child: Image.asset(
                      'assets/pfandler_logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'Pfandler',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Bottle Return Manager',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              children: [
                _buildSectionTitle(context, l10n?.translate('navigation') ?? 'Navigation'),
                _buildMenuItem(
                  context: context,
                  icon: CupertinoIcons.map,
                  title: l10n?.map ?? 'Map',
                  subtitle: l10n?.translate('findReturnLocations') ?? 'Find return locations',
                  onTap: () {
                    Navigator.pop(context);
                    // Already on home/map screen
                  },
                ),
                _buildMenuItem(
                  context: context,
                  icon: CupertinoIcons.cube_box,
                  title: l10n?.bottles ?? 'My Bottles',
                  subtitle: l10n?.translate('viewScannedBottles') ?? 'View scanned bottles',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BottlesScreen(),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  context: context,
                  icon: CupertinoIcons.chart_bar,
                  title: l10n?.analytics ?? 'Analytics',
                  subtitle: l10n?.translate('viewStatistics') ?? 'View your statistics',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AnalyticsScreen(),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  context: context,
                  icon: CupertinoIcons.person,
                  title: l10n?.profile ?? 'Profile',
                  subtitle: l10n?.translate('manageAccount') ?? 'Manage your account',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileScreen(),
                      ),
                    );
                  },
                ),
                const Divider(height: AppSpacing.xl),
                _buildSectionTitle(context, l10n?.translate('general') ?? 'General'),
                _buildMenuItem(
                  context: context,
                  icon: CupertinoIcons.settings,
                  title: l10n?.settings ?? 'Settings',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                ),
                const Divider(height: AppSpacing.xl),
                _buildSectionTitle(context, l10n?.translate('support') ?? 'Support'),
                _buildMenuItem(
                  context: context,
                  icon: CupertinoIcons.envelope,
                  title: l10n?.translate('contactSupport') ?? 'Contact Support',
                  onTap: () {
                    Navigator.pop(context);
                    _openSupportEmail(context);
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Future<void> _openSupportEmail(BuildContext context) async {
    const supportEmail = 'support@pfandler.app';
    const subject = 'Pfandler App Support Request';
    const body = '''
Hello Pfandler Support Team,

I need assistance with:

Please provide details about your issue here.

---
App Version: 1.0.0
Device: [Auto-generated]
''';

    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: supportEmail,
      query: Uri.encodeQueryComponent('subject=$subject&body=$body'),
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        // Fallback - show dialog with email details
        if (context.mounted) {
          _showEmailFallbackDialog(context, supportEmail, subject);
        }
      }
    } catch (e) {
      // Show error dialog
      if (context.mounted) {
        _showEmailErrorDialog(context, supportEmail);
      }
    }
  }

  void _showEmailFallbackDialog(BuildContext context, String email, String subject) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Contact Support'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Please send an email to:'),
              const SizedBox(height: AppSpacing.sm),
              SelectableText(
                email,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Subject: $subject'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showEmailErrorDialog(BuildContext context, String email) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Email Error'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Unable to open email client. Please manually send an email to:'),
              const SizedBox(height: AppSpacing.sm),
              SelectableText(
                email,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
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

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(AppSpacing.xs),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.xs),
        ),
        child: Icon(
          icon,
          color: theme.colorScheme.primary,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyMedium,
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
              ),
            )
          : null,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
    );
  }
}
