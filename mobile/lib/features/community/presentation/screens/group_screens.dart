import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../shared/widgets/async_value_view.dart';
import '../../../../shared/widgets/ui_kit.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../community_paths.dart';
import '../../data/community_repository.dart';
import '../../data/models/community_models.dart';
import '../community_providers.dart';
import '../widgets/community_widgets.dart';

// ── Group ──────────────────────────────────────────────────────────

class GroupScreen extends ConsumerWidget {
  const GroupScreen({super.key, required this.groupId});

  final int groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = ref.watch(groupProvider(groupId));
    if (group.value case final loaded?) return _Group(group: loaded);
    return Scaffold(
      appBar: AppBar(),
      body: AsyncValueView(
        value: group,
        onRetry: () => ref.invalidate(groupProvider(groupId)),
        data: (_) => const SizedBox(),
      ),
    );
  }
}

class _Group extends ConsumerStatefulWidget {
  const _Group({required this.group});

  final CommunityGroup group;

  @override
  ConsumerState<_Group> createState() => _GroupState();
}

class _GroupState extends ConsumerState<_Group> {
  bool _busy = false;

  CommunityGroup get _group => widget.group;

  Future<void> _run(Future<void> Function() action, String done) async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      messenger.showSnackBar(SnackBar(content: Text(done)));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _leave(GroupMembership membership) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Leave ${_group.name}?'),
        content: Text(_group.isPublic ? 'You can join again later.' : 'An admin will have to add you back.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Stay')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (ok == true) await _run(() => ref.read(myMembershipsProvider.notifier).leave(membership), 'You left the group.');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final memberships = ref.watch(myMembershipsProvider);
    final membership = memberships.value?.where((m) => m.group?.id == _group.id).firstOrNull;
    final isMember = membership != null;
    final canSee = isMember || _group.isPublic;
    final memberCount = ref.watch(groupMembersProvider(_group.id)).value?.length;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(title: Text(_group.name)),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GroupBadge(name: _group.name, size: 50),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                PillTag(
                                  '${_group.type.label} group',
                                  icon: _group.isPublic ? Icons.public : Icons.lock_outline,
                                  color: _group.isPublic ? AppAccent.blue : AppAccent.orange,
                                ),
                                if (memberCount != null)
                                  PillTag(
                                    '$memberCount member${memberCount == 1 ? '' : 's'}',
                                    icon: Icons.people_outline,
                                    color: AppAccent.purple,
                                  ),
                                if (isMember)
                                  PillTag(
                                    'You are ${membership.role.label.toLowerCase()}',
                                    icon: Icons.verified_user_outlined,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if ((_group.description ?? '').isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          _group.description!,
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                      if (isMember || _group.isPublic) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: isMember
                              ? OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                                  onPressed: _busy ? null : () => _leave(membership),
                                  icon: const Icon(Icons.logout, size: 18),
                                  label: const Text('Leave'),
                                )
                              : FilledButton.icon(
                                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                                  onPressed: _busy
                                      ? null
                                      : () => _run(
                                          () => ref.read(myMembershipsProvider.notifier).join(_group.id),
                                          'Welcome to ${_group.name}!',
                                        ),
                                  icon: const Icon(Icons.group_add_outlined, size: 18),
                                  label: const Text('Join'),
                                ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            if (!canSee)
              const Expanded(
                child: EmptyView(
                  icon: Icons.lock_outline,
                  message: 'This group is private.\nAsk one of its admins to add you.',
                ),
              )
            else ...[
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: PillTabBar(tabs: ['Posts', 'Events', 'Members']),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _GroupPosts(group: _group, isMember: isMember),
                    _GroupEvents(group: _group, isMember: isMember),
                    _GroupMembers(group: _group, myRole: membership?.role),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GroupPosts extends ConsumerWidget {
  const _GroupPosts({required this.group, required this.isMember});

  final CommunityGroup group;
  final bool isMember;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (groupId: group.id, clubId: null);
    final feed = ref.watch(feedProvider(key));
    final me = ref.watch(authControllerProvider).value?.userId;
    final controller = ref.read(feedProvider(key).notifier);
    return RefreshIndicator(
      onRefresh: () => ref.refresh(feedProvider(key).future),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          if (isMember)
            Composer(
              hint: 'Write to ${group.name}…',
              where: group.name,
              onPublish: (content, announcement) => controller.publish(content, announcement: announcement),
            )
          else
            const InfoBanner('Join the group to post and comment.', icon: Icons.forum_outlined),
          const SizedBox(height: 8),
          ...feed.when(
            loading: () => [
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
            error: (e, _) => [
              ErrorView(message: ApiException.from(e).message, onRetry: () => ref.invalidate(feedProvider(key))),
            ],
            data: (posts) => posts.isEmpty
                ? [
                    const Padding(
                      padding: EdgeInsets.only(top: 48),
                      child: EmptyView(message: 'No post yet.'),
                    ),
                  ]
                : [
                    for (final post in posts)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: PostCard(
                          post: post,
                          onReact: (reaction) => controller.react(post, reaction),
                          onDelete: post.authorId == me ? () => controller.delete(post) : null,
                        ),
                      ),
                  ],
          ),
        ],
      ),
    );
  }
}

class _GroupEvents extends ConsumerWidget {
  const _GroupEvents({required this.group, required this.isMember});

  final CommunityGroup group;
  final bool isMember;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(authControllerProvider).value?.userId;
    return AsyncValueView(
      value: ref.watch(eventsProvider),
      onRetry: () => ref.invalidate(eventsProvider),
      data: (events) {
        final shown = events
            .where((e) => e.group?.id == group.id && (e.status == EventStatus.approved || e.creatorId == me))
            .toList();
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            if (isMember)
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                onPressed: () => context.push(CommunityPaths.newEvent(groupId: group.id)),
                icon: const Icon(Icons.add),
                label: const Text('Organize an event'),
              ),
            const SizedBox(height: 12),
            if (shown.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 48),
                child: EmptyView(message: 'No event yet.'),
              ),
            for (final event in shown) EventTile(event: event, mine: event.creatorId == me),
          ],
        );
      },
    );
  }
}

class _GroupMembers extends ConsumerWidget {
  const _GroupMembers({required this.group, required this.myRole});

  final CommunityGroup group;
  final MemberRole? myRole;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(authControllerProvider).value?.userId;
    final isAdmin = myRole == MemberRole.admin;
    return AsyncValueView(
      value: ref.watch(groupMembersProvider(group.id)),
      onRetry: () => ref.invalidate(groupMembersProvider(group.id)),
      data: (members) {
        final sorted = [...members]..sort((a, b) => a.role.index.compareTo(b.role.index));
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Card(
              child: Column(
                children: [
                  for (final (i, member) in sorted.indexed) ...[
                    if (i > 0) const Divider(height: 1, indent: 66),
                    ListTile(
                      title: Author(userId: member.userId),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (member.role != MemberRole.member)
                            PillTag(
                              member.role.label,
                              color: member.role == MemberRole.admin ? AppAccent.green : AppAccent.blue,
                            ),
                          if (isAdmin && member.userId != me)
                            IconButton(
                              tooltip: 'Remove from the group',
                              icon: const Icon(Icons.person_remove_outlined, color: AppAccent.red),
                              onPressed: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                try {
                                  await ref.read(communityRepositoryProvider).removeMembership(member.id);
                                  ref.invalidate(groupMembersProvider(group.id));
                                } on ApiException catch (e) {
                                  messenger.showSnackBar(SnackBar(content: Text(e.message)));
                                }
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Post & comments ────────────────────────────────────────────────

class PostScreen extends ConsumerStatefulWidget {
  const PostScreen({super.key, required this.postId});

  final int postId;

  @override
  ConsumerState<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends ConsumerState<PostScreen> {
  final _comment = TextEditingController();
  bool _sending = false;

  PostDetailController get _controller => ref.read(postDetailProvider(widget.postId).notifier);

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  void _snack(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  Future<void> _send() async {
    final text = _comment.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await _controller.comment(text);
      _comment.clear();
    } on ApiException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _edit(PostComment comment) async {
    final text = TextEditingController(text: comment.content);
    final updated = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit comment'),
        content: TextField(controller: text, autofocus: true, minLines: 1, maxLines: 5),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
            onPressed: () => Navigator.pop(context, text.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    text.dispose();
    if (updated == null || updated.isEmpty || updated == comment.content) return;
    try {
      await _controller.editComment(comment, updated);
    } on ApiException catch (e) {
      _snack(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(authControllerProvider).value?.userId;
    final detail = ref.watch(postDetailProvider(widget.postId));
    final memberships = ref.watch(myMembershipsProvider).value ?? const <GroupMembership>[];
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Post')),
      body: AsyncValueView(
        value: detail,
        onRetry: () => ref.invalidate(postDetailProvider(widget.postId)),
        data: (detail) {
          final (post, comments) = detail;
          // In a group, only members comment; club posts are open to everyone.
          final canComment = post.groupId == null || memberships.any((m) => m.group?.id == post.groupId);
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  children: [
                    PostCard(post: post, showPlace: true, onReact: _controller.react),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 16, 4, 6),
                      child: Text(
                        '${comments.length} comment${comments.length == 1 ? '' : 's'}',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    for (final comment in comments)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface,
                                  border: Border.all(color: theme.colorScheme.outlineVariant),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(6),
                                    topRight: Radius.circular(18),
                                    bottomLeft: Radius.circular(18),
                                    bottomRight: Radius.circular(18),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (comment.authorId != null)
                                      Author(userId: comment.authorId!, radius: 14, subtitle: ago(comment.createdAt)),
                                    const SizedBox(height: 6),
                                    Text(comment.content, style: const TextStyle(height: 1.4)),
                                  ],
                                ),
                              ),
                            ),
                            if (comment.authorId == me)
                              PopupMenuButton<String>(
                                onSelected: (action) async {
                                  if (action == 'edit') return _edit(comment);
                                  try {
                                    await _controller.deleteComment(comment);
                                  } on ApiException catch (e) {
                                    _snack(e.message);
                                  }
                                },
                                itemBuilder: (context) => const [
                                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                                ],
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              if (canComment)
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _comment,
                              minLines: 1,
                              maxLines: 4,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: InputDecoration(
                                hintText: 'Write a comment',
                                isDense: true,
                                filled: true,
                                fillColor: theme.colorScheme.surfaceContainerLow,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            tooltip: 'Send',
                            style: IconButton.styleFrom(minimumSize: const Size(46, 46)),
                            onPressed: _sending ? null : _send,
                            icon: const Icon(Icons.send),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                const SafeArea(
                  top: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: InfoBanner('Join the group to comment.', icon: Icons.forum_outlined),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
