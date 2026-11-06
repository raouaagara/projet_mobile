import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../project_paths.dart';
import '../project_providers.dart';

class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadNotificationsProvider);
    final colors = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: 'Notifications',
      style: IconButton.styleFrom(
        backgroundColor: colors.surface,
        side: BorderSide(color: colors.outlineVariant),
      ),
      onPressed: () => context.push(ProjectPaths.notifications),
      icon: Badge(
        isLabelVisible: unread > 0,
        label: Text(unread > 9 ? '9+' : '$unread'),
        child: Icon(unread > 0 ? Icons.notifications : Icons.notifications_none),
      ),
    );
  }
}
