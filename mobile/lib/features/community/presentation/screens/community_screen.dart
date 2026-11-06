import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../widgets/for_you.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../shared/widgets/async_value_view.dart';
import '../../../../shared/widgets/ui_kit.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../community_paths.dart';
import '../../data/models/community_models.dart';
import '../community_providers.dart';
import '../widgets/community_widgets.dart';

/// Fourth tab: groups, events and clubs.
class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(title: const Text('Community')),
        body: const Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: PillTabBar(tabs: ['Groups', 'Events', 'Clubs']),
            ),
            Expanded(child: TabBarView(children: [_GroupsTab(), _EventsTab(), _ClubsTab()])),
          ],
        ),
      ),
    );
  }
}

/// A section title inside a list ("My groups", "Discover").
class _ListTitle extends StatelessWidget {
  const _ListTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
    );
  }
}

// ── Groups ─────────────────────────────────────────────────────────

class _GroupsTab extends ConsumerWidget {
  const _GroupsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberships = ref.watch(myMembershipsProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'new-group',
        shape: const StadiumBorder(),
        onPressed: () => context.push(CommunityPaths.newGroup),
        icon: const Icon(Icons.group_add_outlined),
        label: const Text('New group'),
      ),
      body: AsyncValueView(
        value: ref.watch(groupsProvider),
        onRetry: () => ref.invalidate(groupsProvider),
        data: (groups) {
          final mine = memberships.value ?? const <GroupMembership>[];
          final myIds = {for (final m in mine) m.group?.id};
          final joined = groups.where((g) => myIds.contains(g.id)).toList();
          final others = groups.where((g) => !myIds.contains(g.id)).toList();
          return RefreshIndicator(
            onRefresh: () =>
                Future.wait([ref.refresh(groupsProvider.future), ref.refresh(myMembershipsProvider.future)]),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
                const ForYouCard(),
                if (groups.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: EmptyView(icon: Icons.groups_outlined, message: 'No group yet. Start the first one!'),
                  ),
                if (joined.isNotEmpty) ...[
                  const _ListTitle('My groups'),
                  for (final group in joined)
                    _GroupTile(group: group, role: mine.firstWhere((m) => m.group?.id == group.id).role),
                  const SizedBox(height: 8),
                ],
                if (others.isNotEmpty) ...[
                  const _ListTitle('Discover'),
                  for (final group in others) _GroupTile(group: group),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _GroupTile extends StatelessWidget {
  const _GroupTile({required this.group, this.role});

  final CommunityGroup group;
  final MemberRole? role;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(CommunityPaths.group(group.id)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GroupBadge(name: group.name),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(group.name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    if ((group.description ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          group.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        PillTag(
                          group.type.label,
                          icon: group.isPublic ? Icons.public : Icons.lock_outline,
                          color: group.isPublic ? AppAccent.blue : AppAccent.orange,
                        ),
                        if (role != null) PillTag(role!.label, icon: Icons.verified_user_outlined),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: theme.colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Events ─────────────────────────────────────────────────────────

class _EventsTab extends ConsumerWidget {
  const _EventsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(authControllerProvider).value?.userId;
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'new-event',
        shape: const StadiumBorder(),
        onPressed: () => context.push(CommunityPaths.newEvent()),
        icon: const Icon(Icons.event_outlined),
        label: const Text('New event'),
      ),
      body: AsyncValueView(
        value: ref.watch(eventsProvider),
        onRetry: () => ref.invalidate(eventsProvider),
        data: (events) {
          final upcoming = events.where((e) => e.status == EventStatus.approved && !e.isPast()).toList();
          final mineWaiting = events.where((e) => e.creatorId == me && e.status != EventStatus.approved).toList();
          return RefreshIndicator(
            onRefresh: () => ref.refresh(eventsProvider.future),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
                if (mineWaiting.isNotEmpty) ...[
                  const _ListTitle('My events waiting for approval'),
                  for (final event in mineWaiting) EventTile(event: event, mine: true),
                  const SizedBox(height: 8),
                ],
                const _ListTitle('Upcoming'),
                if (upcoming.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: EmptyView(icon: Icons.event_busy_outlined, message: 'No upcoming event.'),
                  ),
                for (final event in upcoming) EventTile(event: event, mine: event.creatorId == me),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Clubs ──────────────────────────────────────────────────────────

class _ClubsTab extends ConsumerStatefulWidget {
  const _ClubsTab();

  @override
  ConsumerState<_ClubsTab> createState() => _ClubsTabState();
}

class _ClubsTabState extends ConsumerState<_ClubsTab> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(authControllerProvider).value?.userId;
    final theme = Theme.of(context);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'new-club',
        shape: const StadiumBorder(),
        onPressed: () => context.push(CommunityPaths.newClub),
        icon: const Icon(Icons.add),
        label: const Text('New club'),
      ),
      body: AsyncValueView(
        value: ref.watch(clubsProvider),
        onRetry: () => ref.invalidate(clubsProvider),
        data: (clubs) {
          // Paused clubs are only visible to their creator.
          final shown = clubs.where((c) {
            if (c.isPaused && c.creatorId != me) return false;
            if (_query.isEmpty) return true;
            return c.name.toLowerCase().contains(_query) || c.interests.any((i) => i.toLowerCase().contains(_query));
          }).toList();
          final interests = {for (final c in clubs) ...c.interests}.toList()..sort();
          return RefreshIndicator(
            onRefresh: () => ref.refresh(clubsProvider.future),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
                SearchField(
                  hintText: 'Search by name or interest',
                  onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                ),
                if (interests.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  FilterPills(
                    values: interests.take(12).toList(),
                    selected: interests.where((i) => i.toLowerCase() == _query).firstOrNull,
                    label: (interest) => interest,
                    onSelected: (interest) =>
                        setState(() => _query = _query == interest.toLowerCase() ? '' : interest.toLowerCase()),
                  ),
                ],
                const SizedBox(height: 14),
                if (shown.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: EmptyView(icon: Icons.interests_outlined, message: 'No club found.'),
                  ),
                for (final club in shown)
                  Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => context.push(CommunityPaths.club(club.id)),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            IconBubble(icon: Icons.interests_outlined, color: communityColor(club.name), size: 46),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    club.name,
                                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  if (club.interests.isNotEmpty)
                                    Text(
                                      club.interests.map((i) => '#$i').join('  '),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
                                    ),
                                  if (club.isPaused || club.creatorId == me) ...[
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 6,
                                      children: [
                                        if (club.isPaused)
                                          const PillTag('Paused', icon: Icons.pause, color: AppAccent.amber),
                                        if (club.creatorId == me) const PillTag('Your club', icon: Icons.star_outline),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, color: theme.colorScheme.outline),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── New group ──────────────────────────────────────────────────────

class NewGroupScreen extends ConsumerStatefulWidget {
  const NewGroupScreen({super.key});

  @override
  ConsumerState<NewGroupScreen> createState() => _NewGroupScreenState();
}

class _NewGroupScreenState extends ConsumerState<NewGroupScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  GroupType _type = GroupType.public;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final group = await ref
          .read(myMembershipsProvider.notifier)
          .create(name: _name.text.trim(), description: _description.text.trim(), type: _type);
      if (mounted) context.pushReplacement(CommunityPaths.group(group.id));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New group')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            SectionCard(
              title: 'The group',
              child: Column(
                children: [
                  LabeledField(
                    label: 'Name',
                    child: TextFormField(
                      controller: _name,
                      maxLength: 80,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(hintText: 'e.g. Flutter developers Tunisia'),
                      validator: (v) => (v ?? '').trim().length < 3 ? 'At least 3 characters' : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  LabeledField(
                    label: 'What is it about?',
                    child: TextFormField(
                      controller: _description,
                      minLines: 3,
                      maxLines: 6,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(hintText: 'Topics, who it is for, the rules…'),
                      validator: (v) => (v ?? '').trim().length < 10 ? 'At least 10 characters' : null,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SectionCard(
              title: 'Who can join',
              child: Column(
                children: [
                  _TypeOption(
                    icon: Icons.public,
                    color: AppAccent.blue,
                    title: 'Public',
                    subtitle: 'Anyone can join and post.',
                    selected: _type == GroupType.public,
                    onTap: () => setState(() => _type = GroupType.public),
                  ),
                  const SizedBox(height: 10),
                  _TypeOption(
                    icon: Icons.lock_outline,
                    color: AppAccent.orange,
                    title: 'Private',
                    subtitle: 'Only people an admin adds can see the posts and write.',
                    selected: _type == GroupType.private,
                    onTap: () => setState(() => _type = GroupType.private),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton(onPressed: _saving ? null : _create, child: const Text('Create the group')),
        ),
      ),
    );
  }
}

/// A choice card with a round icon; green border when selected.
class _TypeOption extends StatelessWidget {
  const _TypeOption({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Material(
      color: selected ? colors.primary.withValues(alpha: 0.06) : colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: selected ? colors.primary : colors.outlineVariant, width: selected ? 2 : 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              IconBubble(icon: icon, color: color, size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? colors.primary : colors.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
