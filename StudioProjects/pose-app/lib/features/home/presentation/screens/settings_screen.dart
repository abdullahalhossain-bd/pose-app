import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../capture/presentation/widgets/capture_settings_section.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/theme/theme_mode_controller.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/providers/session_provider.dart';

/// Application settings screen.
///
/// Sections:
/// - Account: profile, sign out
/// - Appearance: theme mode (system / light / dark)
/// - About: version + flavor
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    final themeController = ref.watch(themeModeControllerProvider);
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: AppPageHeader(
                title: 'Settings',
                subtitle: 'Account, appearance, and about.',
              ),
            ),
            const SliverToBoxAdapter(child: AppGap.md()),
            _SettingsSection(
              title: 'Account',
              children: [
                AppCard.listTile(
                  icon: Icons.person_outline,
                  title: 'Profile',
                  subtitle: 'Update display name and photo',
                  onTap: () => context.push('/home/profile'),
                ),
                AppCard.listTile(
                  icon: Icons.lock_outline,
                  title: 'Privacy',
                  subtitle: 'Permissions and data',
                  onTap: () {},
                ),
              ],
            ),
            _SettingsSection(
              title: 'Smart Capture',
              children: const [
                CaptureSettingsSection(),
              ],
            ),
            _SettingsSection(
              title: 'Appearance',
              children: [
                AppCard(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.brightness_auto_outlined),
                        title: const Text('Theme'),
                        subtitle: Text(_themeLabel(themeController.mode)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showThemePicker(context, ref),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            _SettingsSection(
              title: 'About',
              children: [
                AppCard(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.info_outline),
                        title: const Text('Version'),
                        subtitle: Text('${config.version} (${config.env.label})'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.description_outlined),
                        title: const Text('Terms of service'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {},
                      ),
                      ListTile(
                        leading: const Icon(Icons.privacy_tip_outlined),
                        title: const Text('Privacy policy'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
              ],
            ),
            _SettingsSection(
              title: 'Session',
              children: [
                AppCard(
                  child: ListTile(
                    leading: Icon(
                      Icons.logout,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    title: Text(
                      'Sign out',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    onTap: () async {
                      final confirmed = await showAppConfirmDialog(
                        context: context,
                        title: 'Sign out?',
                        message: 'You\'ll need to sign in again to access '
                            'your library.',
                        confirmLabel: 'Sign out',
                        destructive: true,
                      );
                      if (confirmed == true) {
                        await ref.read(signOutUseCaseProvider)();
                        await ref.read(sessionProvider.notifier).signOut();
                      }
                    },
                  ),
                ),
              ],
            ),
            const SliverToBoxAdapter(child: AppGap.xxl()),
          ],
        ),
      ),
    );
  }

  void _showThemePicker(BuildContext context, WidgetRef ref) {
    showAppModalBottomSheet(
      context: context,
      builder: (_) => AppBottomSheet(
        title: 'Theme',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.brightness_auto),
              title: const Text('System'),
              onTap: () {
                ref.read(themeModeControllerProvider).set(ThemeMode.system);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.light_mode_outlined),
              title: const Text('Light'),
              onTap: () {
                ref.read(themeModeControllerProvider).set(ThemeMode.light);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode_outlined),
              title: const Text('Dark'),
              onTap: () {
                ref.read(themeModeControllerProvider).set(ThemeMode.dark);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  static String _themeLabel(ThemeMode m) => switch (m) {
    ThemeMode.system => 'System default',
    ThemeMode.light => 'Light',
    ThemeMode.dark => 'Dark',
  };
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                title.toUpperCase(),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Column(
              children: children
                  .expand((w) sync* {
                yield w;
                yield const AppGap.sm();
              })
                  .toList()
                ..removeLast(),
            ),
          ],
        ),
      ),
    );
  }
}