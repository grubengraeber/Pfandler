import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../services/auth_service.dart';
import '../../services/sync_service.dart';
import '../auth/sign_in_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final currentUser = ref.watch(currentUserProvider);
    final bottlesAsync = ref.watch(bottlesProvider);
    final storesAsync = ref.watch(storesProvider);

    // Calculate statistics
    final totalBottles = bottlesAsync.when(
      data: (bottles) => bottles.length,
      loading: () => 0,
      error: (_, __) => 0,
    );
    
    final totalEarned = bottlesAsync.when(
      data: (bottles) => bottles
          .where((b) => b.isReturned)
          .fold<double>(0, (sum, bottle) => sum + bottle.depositAmount),
      loading: () => 0.0,
      error: (_, __) => 0.0,
    );
    
    final storeCount = storesAsync.when(
      data: (stores) => stores.length,
      loading: () => 0,
      error: (_, __) => 0,
    );

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
                    child: currentUser != null && currentUser.avatarUrl != null
                        ? ClipOval(
                            child: Image.network(
                              currentUser.avatarUrl!,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                CupertinoIcons.person_fill,
                                size: 50,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : const Icon(
                            CupertinoIcons.person_fill,
                            size: 50,
                            color: Colors.white,
                          ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    currentUser?.displayName ?? 
                    currentUser?.email.split('@').first ?? 
                    'Guest User',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    currentUser?.email ?? 'Not signed in',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),

            // Show sign in button if not authenticated
            if (!authState.isAuthenticated) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignInScreen(),
                        ),
                      );
                    },
                    icon: const Icon(CupertinoIcons.person_badge_plus),
                    label: const Text('Sign In to Sync Data'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            // Stats Row
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatColumn(
                    context, 
                    totalBottles.toString(), 
                    'Total Bottles'
                  ),
                  Container(
                    height: 40,
                    width: 1,
                    color: theme.dividerColor,
                  ),
                  _buildStatColumn(
                    context, 
                    '€${totalEarned.toStringAsFixed(2)}', 
                    'Total Earned'
                  ),
                  Container(
                    height: 40,
                    width: 1,
                    color: theme.dividerColor,
                  ),
                  _buildStatColumn(
                    context, 
                    storeCount.toString(), 
                    'Stores'
                  ),
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
                  if (authState.isAuthenticated) ...[
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
                      onTap: () {
                        // TODO: Implement edit profile
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Edit profile coming soon'),
                          ),
                        );
                      },
                    ),
                    _buildSettingItem(
                      context,
                      icon: CupertinoIcons.bell,
                      title: 'Notifications',
                      onTap: () {
                        // TODO: Implement notifications settings
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Notification settings coming soon'),
                          ),
                        );
                      },
                    ),
                    _buildSettingItem(
                      context,
                      icon: CupertinoIcons.lock,
                      title: 'Privacy',
                      onTap: () {
                        // TODO: Implement privacy settings
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Privacy settings coming soon'),
                          ),
                        );
                      },
                    ),
                  ],
                  _buildSettingItem(
                    context,
                    icon: CupertinoIcons.globe,
                    title: 'Language',
                    subtitle: 'English',
                    onTap: () {
                      // TODO: Implement language settings
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Language settings coming soon'),
                        ),
                      );
                    },
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
                    onTap: () {
                      // TODO: Implement help
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Help & FAQ coming soon'),
                        ),
                      );
                    },
                  ),
                  _buildSettingItem(
                    context,
                    icon: CupertinoIcons.star,
                    title: 'Rate App',
                    onTap: () {
                      // TODO: Implement rate app
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('App rating coming soon'),
                        ),
                      );
                    },
                  ),
                  _buildSettingItem(
                    context,
                    icon: CupertinoIcons.share,
                    title: 'Share App',
                    onTap: () {
                      // TODO: Implement share app
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Share functionality coming soon'),
                        ),
                      );
                    },
                  ),
                  if (authState.isAuthenticated) ...[
                    const SizedBox(height: AppSpacing.xl),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          // Show confirmation dialog
                          final shouldSignOut = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Sign Out'),
                              content: const Text(
                                'Are you sure you want to sign out? Your local data will be preserved.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.error,
                                  ),
                                  child: const Text('Sign Out'),
                                ),
                              ],
                            ),
                          );

                          if (shouldSignOut == true && context.mounted) {
                            await ref.read(authProvider.notifier).logout();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Signed out successfully'),
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(CupertinoIcons.square_arrow_left),
                        label: const Text('Sign Out'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                        ),
                      ),
                    ),
                  ],
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