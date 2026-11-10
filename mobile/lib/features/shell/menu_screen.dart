import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_paths.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/user_avatar.dart';
import '../auth/presentation/auth_controller.dart';

/// Entry points to every module that has no bottom tab.
class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).value;
    final user = ref.watch(currentUserProvider).value;
    final isFreelancer = session?.isFreelancer ?? false;
    final brightness = Theme.of(context).brightness;

    Widget entry(IconData icon, String title, String path) => ListTile(
          leading: Icon(icon),
          title: Text(title),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push(path),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Menu')),
      body: ListView(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: UserAvatar(user: user, radius: 28),
            title: Text(user?.fullName ?? session?.email ?? ''),
            subtitle: Text(isFreelancer ? 'Freelancer' : 'Client'),
          ),
          const Divider(),
          if (isFreelancer) ...[
            entry(Icons.event_available_outlined, 'My availability', AppPaths.availability),
          ] else
            entry(Icons.public, 'World clock', AppPaths.worldClock),
          entry(Icons.support_agent_outlined, 'Help & support', AppPaths.support),
          const Divider(),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('Dark mode'),
            value: brightness == Brightness.dark,
            onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(brightness),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Log out'),
            onTap: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
    );
  }
}
