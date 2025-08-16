import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: theme.colorScheme.primary,
                    child: const Icon(
                      CupertinoIcons.person_fill,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'John Doe',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'john.doe@example.com',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),

            // Stats Row
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatColumn(context, '156', 'Total Bottles'),
                  Container(
                    height: 40,
                    width: 1,
                    color: theme.dividerColor,
                  ),
                  _buildStatColumn(context, '€39.00', 'Total Earned'),
                  Container(
                    height: 40,
                    width: 1,
                    color: theme.dividerColor,
                  ),
                  _buildStatColumn(context, '12', 'Stores'),
                ],
              ),
            ),

            const Divider(height: AppSpacing.xl),

            // Settings List
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account Settings',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildSettingItem(
                    context,
                    icon: CupertinoIcons.person,
                    title: 'Edit Profile',
                    onTap: () {},
                  ),
                  _buildSettingItem(
                    context,
                    icon: CupertinoIcons.bell,
                    title: 'Notifications',
                    onTap: () {},
                  ),
                  _buildSettingItem(
                    context,
                    icon: CupertinoIcons.lock,
                    title: 'Privacy',
                    onTap: () {},
                  ),
                  _buildSettingItem(
                    context,
                    icon: CupertinoIcons.globe,
                    title: 'Language',
                    subtitle: 'English',
                    onTap: () {},
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Support',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildSettingItem(
                    context,
                    icon: CupertinoIcons.question_circle,
                    title: 'Help & FAQ',
                    onTap: () {},
                  ),
                  _buildSettingItem(
                    context,
                    icon: CupertinoIcons.star,
                    title: 'Rate App',
                    onTap: () {},
                  ),
                  _buildSettingItem(
                    context,
                    icon: CupertinoIcons.share,
                    title: 'Share App',
                    onTap: () {},
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(CupertinoIcons.square_arrow_left),
                      label: const Text('Sign Out'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(BuildContext context, String value, String label) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.sm),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
      ),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(
        CupertinoIcons.chevron_right,
        size: 16,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 0,
        vertical: AppSpacing.xs,
      ),
    );
  }
}
