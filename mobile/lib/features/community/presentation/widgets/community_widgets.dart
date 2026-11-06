import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../shared/widgets/ui_kit.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../../community_paths.dart';
import '../../data/community_repository.dart';
import '../../data/models/community_models.dart';
import '../community_providers.dart';

/// "5 min ago", "3 h ago", "Sep 20".
String ago(DateTime? time, {DateTime? now}) {
  if (time == null) return '';
  final diff = (now ?? DateTime.now()).difference(time);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min';
  if (diff.inHours < 24) return '${diff.inHours} h';
  if (diff.inDays < 7) return '${diff.inDays} d';
  return DateFormat.MMMd('en_US').format(time);
}

/// "Sat, Oct 10 · 18:00".
String eventTime(DateTime time) => DateFormat('EEE, MMM d · HH:mm', 'en_US').format(time);

/// A steady accent for a group or club, picked from its first letter (the one on its badge).
Color communityColor(String name) {
  const palette = [AppAccent.green, AppAccent.blue, AppAccent.purple, AppAccent.orange, AppAccent.pink, AppAccent.cyan];
  return palette[name.isEmpty ? 0 : name.toUpperCase().codeUnitAt(0) % palette.length];
}

/// The first letter of a group in a colored circle.
class GroupBadge extends StatelessWidget {
  const GroupBadge({super.key, required this.name, this.size = 46});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, color: communityColor(name)),
      child: Text(
        name.isEmpty ? '?' : name[0].toUpperCase(),
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: size * 0.42),
      ),
    );
  }
}

/// Opens a page of another module, or says it's not there yet (modules live on separate branches).
void openModuleLink(BuildContext context, String location, {required String comingSoon}) {
  if (GoRouter.of(context).configuration.findMatch(Uri.parse(location)).isError) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(comingSoon)));
    return;
  }
  context.push(location);
}

/// Avatar + name of a member; opens their profile.
class Author extends ConsumerWidget {
  const Author({super.key, required this.userId, this.subtitle, this.radius = 20});

  final int userId;
  final String? subtitle;
  final double radius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(communityUserProvider(userId));
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => openModuleLink(
        context,
        LinkedPaths.profile(userId),
        comingSoon: 'Public profiles arrive with module 1 (profile).',
      ),
      child: Row(
        children: [
          UserAvatar(user: user.value, radius: radius),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.value?.fullName ?? (user.isLoading ? '…' : 'Member #$userId'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tap: like (or remove your reaction). Long press: pick another reaction.
class ReactionButton extends StatelessWidget {
  const ReactionButton({super.key, required this.post, required this.onReact});

  final FeedPost post;
  final Future<void> Function(ReactionKind reaction) onReact;

  Future<void> _react(BuildContext context, ReactionKind reaction) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await onReact(reaction);
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _pick(BuildContext context) async {
    final reaction = await showModalBottomSheet<ReactionKind>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (final kind in ReactionKind.values)
                IconButton(
                  tooltip: kind.apiName.toLowerCase(),
                  onPressed: () => Navigator.pop(context, kind),
                  icon: Text(kind.emoji, style: const TextStyle(fontSize: 28)),
                ),
            ],
          ),
        ),
      ),
    );
    if (reaction != null && context.mounted) await _react(context, reaction);
  }

  @override
  Widget build(BuildContext context) {
    final mine = post.userReaction;
    final colors = Theme.of(context).colorScheme;
    final color = mine == null ? colors.onSurfaceVariant : colors.primary;
    return Material(
      color: mine == null ? Colors.transparent : colors.primary.withValues(alpha: 0.10),
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _react(context, mine ?? ReactionKind.like),
        onLongPress: () => _pick(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              mine == null
                  ? Icon(Icons.thumb_up_outlined, size: 18, color: color)
                  : Text(mine.emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                mine == null ? 'React' : 'Reacted',
                style: TextStyle(color: color, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A post in a feed: author, place, text, reactions and comment count.
class PostCard extends StatelessWidget {
  const PostCard({super.key, required this.post, required this.onReact, this.showPlace = false, this.onDelete});

  final FeedPost post;
  final Future<void> Function(ReactionKind reaction) onReact;
  final bool showPlace;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final used = post.reactionCounts.keys.toList()
      ..sort((a, b) => post.reactionCounts[b]!.compareTo(post.reactionCounts[a]!));
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(CommunityPaths.post(post.id)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 6, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (post.authorId != null)
                    Expanded(
                      child: Author(
                        userId: post.authorId!,
                        subtitle: [
                          ago(post.createdAt),
                          if (showPlace && post.placeName != null) post.placeName!,
                        ].join(' · '),
                      ),
                    ),
                  if (post.isAnnouncement)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: PillTag('Announcement', icon: Icons.campaign_outlined, color: AppAccent.orange),
                    ),
                  if (onDelete != null)
                    PopupMenuButton<String>(
                      onSelected: (_) => onDelete!(),
                      itemBuilder: (context) => const [PopupMenuItem(value: 'delete', child: Text('Delete'))],
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(post.content, style: theme.textTheme.bodyLarge?.copyWith(height: 1.4)),
              ),
              const Padding(padding: EdgeInsets.fromLTRB(0, 10, 8, 4), child: Divider(height: 1)),
              Row(
                children: [
                  ReactionButton(post: post, onReact: onReact),
                  const Spacer(),
                  if (post.totalReactions > 0)
                    Text(
                      '${used.take(3).map((r) => r.emoji).join()} ${post.totalReactions}',
                      style: theme.textTheme.labelMedium,
                    ),
                  const SizedBox(width: 12),
                  Icon(Icons.mode_comment_outlined, size: 16, color: colors.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text('${post.commentsCount}', style: theme.textTheme.labelMedium),
                  const SizedBox(width: 10),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Write a post in a group or a club; "Write with AI" turns what is typed into a clear post.
class Composer extends ConsumerStatefulWidget {
  const Composer({
    super.key,
    required this.onPublish,
    this.canAnnounce = false,
    this.hint = 'Share something…',
    this.where,
  });

  final Future<void> Function(String content, bool announcement) onPublish;
  final bool canAnnounce;
  final String hint;

  /// The group or club name, for the AI.
  final String? where;

  @override
  ConsumerState<Composer> createState() => _ComposerState();
}

class _ComposerState extends ConsumerState<Composer> {
  final _text = TextEditingController();
  bool _announcement = false;
  bool _sending = false;
  bool _writing = false;

  Future<void> _write() async {
    final notes = _text.text.trim();
    final messenger = ScaffoldMessenger.of(context);
    if (notes.length < 5) {
      messenger.showSnackBar(const SnackBar(content: Text('Write a few words first: the AI turns them into a post.')));
      return;
    }
    setState(() => _writing = true);
    try {
      final text = await ref.read(communityRepositoryProvider).draftPost(notes, where: widget.where);
      if (!mounted) return;
      _text.text = text;
      messenger.showSnackBar(
        SnackBar(
          content: const Text('The AI wrote your post. Change anything before posting.'),
          action: SnackBarAction(label: 'Undo', onPressed: () => _text.text = notes),
        ),
      );
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _writing = false);
    }
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    final content = _text.text.trim();
    if (content.isEmpty) return;
    setState(() => _sending = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.onPublish(content, _announcement);
      _text.clear();
      if (mounted) setState(() => _announcement = false);
      FocusManager.instance.primaryFocus?.unfocus();
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 10, 10),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Icon(Icons.edit_note, color: colors.primary),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _text,
                    minLines: 1,
                    maxLines: 6,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: widget.hint,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                if (widget.canAnnounce)
                  FilterChip(
                    avatar: const Icon(Icons.campaign_outlined, size: 16),
                    label: const Text('Announcement'),
                    selected: _announcement,
                    onSelected: (v) => setState(() => _announcement = v),
                  ),
                const Spacer(),
                AiButton(label: 'Write with AI', busy: _writing, onPressed: _sending ? null : _write),
                const SizedBox(width: 8),
                FilledButton.icon(
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 42)),
                  onPressed: _sending || _writing ? null : _publish,
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text('Post'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A date block: month over day, green.
class DateBlock extends StatelessWidget {
  const DateBlock({super.key, required this.date, this.size = 54});

  final DateTime? date;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(14)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            date == null ? '—' : DateFormat.MMM('en_US').format(date!).toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          Text(
            date == null ? '' : '${date!.day}',
            style: theme.textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w800, height: 1.1),
          ),
        ],
      ),
    );
  }
}

/// An event in a list: date block, title, host and place.
class EventTile extends StatelessWidget {
  const EventTile({super.key, required this.event, this.mine = false});

  final CommunityEvent event;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final start = event.startDate;
    final waiting = mine && event.status != EventStatus.approved;
    Widget fact(IconData icon, String text) => Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          Icon(icon, size: 14, color: muted),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
          ),
        ],
      ),
    );
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(CommunityPaths.event(event.id)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DateBlock(date: start),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (start != null) fact(Icons.schedule, DateFormat.Hm().format(start)),
                    if ((event.location ?? '').isNotEmpty) fact(Icons.place_outlined, event.location!),
                    if (event.hostName != null)
                      fact(event.group != null ? Icons.groups_outlined : Icons.interests_outlined, event.hostName!),
                  ],
                ),
              ),
              if (waiting)
                Tooltip(
                  message: event.status.label,
                  child: IconBubble(
                    icon: event.status == EventStatus.rejected ? Icons.block : Icons.hourglass_empty,
                    color: event.status == EventStatus.rejected ? AppAccent.red : AppAccent.amber,
                    size: 34,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
