import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/async_value_view.dart';
import '../../../../shared/widgets/ui_kit.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../data/availability_repository.dart';
import '../../data/models/chat_models.dart';
import '../../messaging_paths.dart';
import '../format.dart';
import '../messaging_providers.dart';
import '../widgets/common.dart';

/// Third tab: conversations, newest first, with unread counts. Updated live by the socket.
class ConversationsScreen extends ConsumerStatefulWidget {
  const ConversationsScreen({super.key});

  @override
  ConsumerState<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends ConsumerState<ConversationsScreen> {
  String _query = '';

  @override
  void initState() {
    super.initState();
    // Freelancers: "last seen" for the clients' world clock (no profile yet → ignored).
    final session = ref.read(authControllerProvider).value;
    if (session != null && session.isFreelancer) {
      unawaited(ref.read(availabilityRepositoryProvider).heartbeat(session.userId).catchError((_) {}));
    }
  }

  @override
  Widget build(BuildContext context) {
    final conversations = ref.watch(conversationsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      floatingActionButton: FloatingActionButton(
        tooltip: 'New message',
        onPressed: () => context.push(MessagingPaths.compose),
        shape: const CircleBorder(),
        child: const Icon(Icons.edit_outlined),
      ),
      body: Column(
        children: [
          const ConnectionBanner(),
          Expanded(
            child: AsyncValueView(
              value: conversations,
              onRetry: () => ref.invalidate(conversationsProvider),
              data: (conversations) => RefreshIndicator(
                onRefresh: () => ref.refresh(conversationsProvider.future),
                child: conversations.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 120),
                          EmptyView(
                            icon: Icons.forum_outlined,
                            message: 'No conversation yet.\nTap the pen to write to a client or a freelancer.',
                          ),
                        ],
                      )
                    : _list(conversations),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _list(List<ConversationSummary> conversations) {
    final shown = _query.isEmpty
        ? conversations
        : conversations.where((c) {
            final name = ref.watch(chatUserProvider(c.otherUserId)).value?.fullName.toLowerCase() ?? '';
            return name.contains(_query) || c.preview.toLowerCase().contains(_query);
          }).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        SearchField(
          hintText: 'Search a name or a message',
          onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
        ),
        const SizedBox(height: 14),
        if (shown.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 48),
            child: EmptyView(icon: Icons.search_off, message: 'No conversation matches.'),
          )
        else
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (final (i, conversation) in shown.indexed) ...[
                  if (i > 0) const Divider(height: 1, indent: 82),
                  _ConversationTile(conversation: conversation),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _ConversationTile extends ConsumerWidget {
  const _ConversationTile({required this.conversation});

  final ConversationSummary conversation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final me = ref.watch(authControllerProvider).value?.userId;
    final user = ref.watch(chatUserProvider(conversation.otherUserId));
    final unread = conversation.unreadCount;
    final fromMe = conversation.lastSenderId == me && conversation.lastMessage != null;
    return ListTile(
      contentPadding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      leading: UserAvatar(user: user.value, radius: 26),
      title: Text(
        user.value?.fullName ?? (user.isLoading ? '…' : 'User #${conversation.otherUserId}'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleSmall?.copyWith(fontWeight: unread > 0 ? FontWeight.w800 : FontWeight.w600),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          '${fromMe ? 'You: ' : ''}${conversation.preview}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.normal,
            color: unread > 0 ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            listTime(conversation.lastMessageTime),
            style: theme.textTheme.labelSmall?.copyWith(
              color: unread > 0 ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
              fontWeight: unread > 0 ? FontWeight.w700 : null,
            ),
          ),
          const SizedBox(height: 6),
          if (unread > 0)
            Container(
              constraints: const BoxConstraints(minWidth: 22),
              height: 22,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(11)),
              child: Center(
                widthFactor: 1,
                child: Text(
                  unread > 99 ? '99+' : '$unread',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            )
          else
            const SizedBox(height: 22),
        ],
      ),
      onTap: () => context.push(MessagingPaths.conversation(conversation.id, otherUserId: conversation.otherUserId)),
    );
  }
}
