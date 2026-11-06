import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/user_role.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../shared/widgets/async_value_view.dart';
import '../../../../shared/widgets/ui_kit.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../data/chat_repository.dart';
import '../../messaging_paths.dart';
import '../messaging_providers.dart';

/// Pick a client or freelancer to write to.
class ComposeScreen extends ConsumerStatefulWidget {
  const ComposeScreen({super.key});

  @override
  ConsumerState<ComposeScreen> createState() => _ComposeScreenState();
}

class _ComposeScreenState extends ConsumerState<ComposeScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final isClient = ref.watch(authControllerProvider).value?.isClient ?? false;
    return Scaffold(
      appBar: AppBar(title: const Text('New message')),
      body: AsyncValueView(
        value: ref.watch(contactableUsersProvider),
        onRetry: () => ref.invalidate(contactableUsersProvider),
        data: (users) {
          // Clients mostly write to freelancers and vice versa: show those first.
          final preferred = isClient ? UserRole.freelancer : UserRole.client;
          final shown =
              users
                  .where(
                    (u) =>
                        _query.isEmpty ||
                        u.fullName.toLowerCase().contains(_query) ||
                        (u.location ?? '').toLowerCase().contains(_query),
                  )
                  .toList()
                ..sort((a, b) => (a.role == preferred ? 0 : 1).compareTo(b.role == preferred ? 0 : 1));
          final theme = Theme.of(context);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              SearchField(
                autofocus: true,
                hintText: 'Search by name or city',
                onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              ),
              const SizedBox(height: 14),
              if (shown.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 64),
                  child: EmptyView(icon: Icons.person_search_outlined, message: 'Nobody found.'),
                )
              else
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (final (i, user) in shown.indexed) ...[
                        if (i > 0) const Divider(height: 1, indent: 76),
                        ListTile(
                          contentPadding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
                          leading: UserAvatar(user: user, radius: 24),
                          title: Text(
                            user.fullName,
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          subtitle: (user.location ?? '').isEmpty
                              ? null
                              : Row(
                                  children: [
                                    Icon(Icons.place_outlined, size: 14, color: theme.colorScheme.onSurfaceVariant),
                                    const SizedBox(width: 3),
                                    Flexible(child: Text(user.location!, maxLines: 1, overflow: TextOverflow.ellipsis)),
                                  ],
                                ),
                          trailing: user.role == UserRole.freelancer
                              ? const PillTag('Freelancer')
                              : const PillTag('Client', color: AppAccent.blue),
                          onTap: () => context.pushReplacement(MessagingPaths.chatWith(user.id)),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// `/messages/new/:userId`: finds or creates the conversation with the user, then opens it.
/// Other modules' "Message" buttons land here.
class StartChatScreen extends ConsumerStatefulWidget {
  const StartChatScreen({super.key, required this.userId});

  final int userId;

  @override
  ConsumerState<StartChatScreen> createState() => _StartChatScreenState();
}

class _StartChatScreenState extends ConsumerState<StartChatScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    setState(() => _error = null);
    final me = ref.read(authControllerProvider).value?.userId;
    if (me == null) return;
    if (me == widget.userId) {
      setState(() => _error = "You can't send a message to yourself.");
      return;
    }
    try {
      final conversationId = await ref.read(chatRepositoryProvider).openConversation(me, widget.userId);
      if (!mounted) return;
      context.pushReplacement(MessagingPaths.conversation(conversationId, otherUserId: widget.userId));
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: _error == null
          ? const Center(child: CircularProgressIndicator())
          : ErrorView(message: _error!, onRetry: _open),
    );
  }
}
