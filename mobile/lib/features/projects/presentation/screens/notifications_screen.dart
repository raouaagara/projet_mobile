import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/async_value_view.dart';
import '../../../../shared/widgets/ui_kit.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../data/models/project_notification.dart';
import '../../project_paths.dart';
import '../format.dart';
import '../project_providers.dart';

/// New proposals (client) and answers to my proposals (freelancer).
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadNotificationsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: () => ref.read(notificationsProvider.notifier).markAllRead(),
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: AsyncValueView(
        value: ref.watch(notificationsProvider),
        onRetry: () => ref.invalidate(notificationsProvider),
        data: (notifications) => RefreshIndicator(
          onRefresh: () => ref.refresh(notificationsProvider.future),
          child: notifications.isEmpty
              ? ListView(
                  children: const [
                    SizedBox(height: 120),
                    EmptyView(message: 'No notification yet.', icon: Icons.notifications_none),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: notifications.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => _NotificationTile(notification: notifications[i]),
                ),
        ),
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.notification});

  final ProjectNotification notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final message = notification.message.toLowerCase();
    final (icon, color) = message.contains('accepted')
        ? (Icons.check_circle_outline, AppAccent.green)
        : message.contains('declined') || message.contains('rejected')
        ? (Icons.cancel_outlined, AppAccent.red)
        : (Icons.mark_email_unread_outlined, AppAccent.blue);

    return Card(
      color: notification.read ? null : colors.primaryContainer.withValues(alpha: 0.45),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
        leading: IconBubble(icon: icon, color: color, size: 44),
        title: Text(
          notification.message,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: notification.read ? FontWeight.w400 : FontWeight.w700,
          ),
        ),
        subtitle: Text(timeAgo(notification.createdAt)),
        trailing: notification.read ? null : Icon(Icons.circle, size: 10, color: colors.primary),
        onTap: () {
          ref.read(notificationsProvider.notifier).markRead(notification).ignore();
          final projectId = notification.projectId;
          if (projectId == null) return;
          // A client is told about new proposals: open them directly.
          final isClient = ref.read(authControllerProvider).value?.isClient ?? false;
          context.push(isClient ? ProjectPaths.proposals(projectId) : ProjectPaths.details(projectId));
        },
      ),
    );
  }
}
