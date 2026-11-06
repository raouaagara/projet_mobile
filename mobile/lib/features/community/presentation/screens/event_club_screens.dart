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

// ── Event ──────────────────────────────────────────────────────────

class EventScreen extends ConsumerWidget {
  const EventScreen({super.key, required this.eventId});

  final int eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final me = ref.watch(authControllerProvider).value?.userId;
    return Scaffold(
      appBar: AppBar(title: const Text('Event')),
      body: AsyncValueView(
        value: ref.watch(eventProvider(eventId)),
        onRetry: () => ref.invalidate(eventProvider(eventId)),
        data: (event) {
          final rejected = event.status == EventStatus.rejected;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              if (event.status != EventStatus.approved) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: (rejected ? AppAccent.red : AppAccent.amber).withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      IconBubble(
                        icon: rejected ? Icons.block : Icons.hourglass_empty,
                        color: rejected ? AppAccent.red : AppAccent.amber,
                        size: 40,
                        solid: true,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(event.status.label, style: const TextStyle(fontWeight: FontWeight.w700)),
                            Text(
                              rejected
                                  ? 'An admin did not approve this event.'
                                  : 'Others will see it once an admin approves it.',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      DateBlock(date: event.startDate, size: 62),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          event.title,
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SectionCard(
                title: 'When & where',
                child: Column(
                  children: [
                    if (event.startDate != null)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const IconBubble(icon: Icons.schedule, color: AppAccent.blue, size: 42),
                        title: Text(eventTime(event.startDate!), style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: event.endDate == null ? null : Text('until ${eventTime(event.endDate!)}'),
                      ),
                    if ((event.location ?? '').isNotEmpty)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const IconBubble(icon: Icons.place_outlined, color: AppAccent.red, size: 42),
                        title: Text(event.location!, style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    if (event.hostName != null)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: IconBubble(
                          icon: event.group != null ? Icons.groups_outlined : Icons.interests_outlined,
                          color: AppAccent.purple,
                          size: 42,
                        ),
                        title: Text(event.hostName!, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(event.group != null ? 'Group' : 'Club'),
                        trailing: Icon(Icons.chevron_right, color: theme.colorScheme.outline),
                        onTap: () => context.push(
                          event.group != null
                              ? CommunityPaths.group(event.group!.id)
                              : CommunityPaths.club(event.club!.id),
                        ),
                      ),
                  ],
                ),
              ),
              if (event.creatorId != null) ...[
                const SizedBox(height: 12),
                SectionCard(
                  title: 'Organizer',
                  child: Author(
                    userId: event.creatorId!,
                    subtitle: event.creatorId == me ? 'Organized by you' : 'Organizer',
                  ),
                ),
              ],
              if ((event.description ?? '').isNotEmpty) ...[
                const SizedBox(height: 12),
                SectionCard(
                  title: 'About',
                  child: SelectableText(event.description!, style: const TextStyle(height: 1.5)),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class NewEventScreen extends ConsumerStatefulWidget {
  const NewEventScreen({super.key, this.groupId, this.clubId});

  final int? groupId;
  final int? clubId;

  @override
  ConsumerState<NewEventScreen> createState() => _NewEventScreenState();
}

class _NewEventScreenState extends ConsumerState<NewEventScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _location = TextEditingController();
  late int? _groupId = widget.groupId;
  late int? _clubId = widget.clubId;
  DateTime? _start;
  DateTime? _end;
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDateTime(DateTime? initial) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initial ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 730)),
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial ?? DateTime(0, 1, 1, 18)),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _create() async {
    final valid = _form.currentState!.validate();
    String? error;
    if (_groupId == null && _clubId == null) error = 'Pick the group or club hosting it';
    if (_start == null || _end == null) error ??= 'Pick when it starts and ends';
    if (_start != null && _end != null && !_end!.isAfter(_start!)) error ??= 'It must end after it starts';
    setState(() => _error = error);
    if (!valid || error != null) return;

    setState(() => _saving = true);
    try {
      final event = await ref
          .read(communityRepositoryProvider)
          .createEvent(
            creatorId: ref.read(authControllerProvider).value!.userId,
            title: _title.text.trim(),
            description: _description.text.trim(),
            location: _location.text.trim(),
            start: _start!,
            end: _end!,
            groupId: _groupId,
            clubId: _clubId,
          );
      ref.invalidate(eventsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Event created. Others will see it once an admin approves it.')));
      context.pushReplacement(CommunityPaths.event(event.id));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(authControllerProvider).value?.userId;
    final myGroups = [
      for (final m in ref.watch(myMembershipsProvider).value ?? const <GroupMembership>[])
        if (m.group != null) m.group!,
    ];
    final myClubs = (ref.watch(clubsProvider).value ?? const <Club>[]).where((c) => c.creatorId == me).toList();
    final hosts = <(String, int?, int?)>[
      for (final g in myGroups) ('${g.name} (group)', g.id, null),
      for (final c in myClubs) ('${c.name} (club)', null, c.id),
    ];
    final selected = hosts.where((h) => h.$2 == _groupId && h.$3 == _clubId).firstOrNull;

    final theme = Theme.of(context);
    Widget dateButton(String empty, DateTime? value, VoidCallback onPressed) => OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
        foregroundColor: theme.colorScheme.onSurface,
      ),
      onPressed: onPressed,
      icon: Icon(Icons.event_outlined, color: theme.colorScheme.primary, size: 20),
      label: Text(value == null ? empty : eventTime(value), maxLines: 1, overflow: TextOverflow.ellipsis),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('New event')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            SectionCard(
              title: 'Hosted by',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<(String, int?, int?)>(
                    initialValue: selected,
                    decoration: const InputDecoration(hintText: 'Pick a group or a club'),
                    items: [for (final h in hosts) DropdownMenuItem(value: h, child: Text(h.$1))],
                    onChanged: (h) => setState(() {
                      _groupId = h?.$2;
                      _clubId = h?.$3;
                    }),
                  ),
                  if (hosts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text('Join a group or create a club first.'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SectionCard(
              title: 'The event',
              child: Column(
                children: [
                  LabeledField(
                    label: 'Title',
                    child: TextFormField(
                      controller: _title,
                      maxLength: 100,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(hintText: 'e.g. Flutter meetup'),
                      validator: (v) => (v ?? '').trim().length < 3 ? 'At least 3 characters' : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  LabeledField(
                    label: 'Place or link',
                    child: TextFormField(
                      controller: _location,
                      decoration: const InputDecoration(hintText: 'e.g. ESPRIT, Ariana — or a Meet link'),
                      validator: (v) => (v ?? '').trim().isEmpty ? 'Where does it happen?' : null,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SectionCard(
              title: 'When',
              child: Column(
                children: [
                  dateButton('Starts…', _start, () async {
                    final start = await _pickDateTime(_start);
                    if (start != null) setState(() => _start = start);
                  }),
                  const SizedBox(height: 10),
                  dateButton('Ends…', _end, () async {
                    final end = await _pickDateTime(_end ?? _start?.add(const Duration(hours: 2)));
                    if (end != null) setState(() => _end = end);
                  }),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SectionCard(
              title: 'Description',
              child: TextFormField(
                controller: _description,
                minLines: 3,
                maxLines: 8,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(hintText: 'What will happen, who it is for…'),
              ),
            ),
            const SizedBox(height: 12),
            const InfoBanner(
              'An admin checks events before they are shown to everyone.',
              icon: Icons.verified_outlined,
            ),
          ],
        ),
      ),
      // The error sits right above the button, so it is seen whatever the scroll.
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _error!,
                    style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.w600),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: FilledButton(onPressed: _saving ? null : _create, child: const Text('Create the event')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Club ───────────────────────────────────────────────────────────

class ClubScreen extends ConsumerWidget {
  const ClubScreen({super.key, required this.clubId});

  final int clubId;

  Future<void> _togglePause(BuildContext context, WidgetRef ref, Club club) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(communityRepositoryProvider).setClubPaused(club.id, paused: !club.isPaused);
      ref.invalidate(clubProvider(club.id));
      ref.invalidate(clubsProvider);
      messenger.showSnackBar(
        SnackBar(content: Text(club.isPaused ? 'The club is active again.' : 'The club is paused.')),
      );
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final me = ref.watch(authControllerProvider).value?.userId;
    final club = ref.watch(clubProvider(clubId));
    final key = (groupId: null, clubId: clubId);

    return Scaffold(
      appBar: AppBar(
        title: Text(club.value?.name ?? 'Club'),
        actions: [
          if (club.value case final c? when c.creatorId == me)
            PopupMenuButton<String>(
              onSelected: (action) => switch (action) {
                'edit' => context.push(CommunityPaths.editClub(c.id)),
                'event' => context.push(CommunityPaths.newEvent(clubId: c.id)),
                _ => _togglePause(context, ref, c),
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit the club')),
                const PopupMenuItem(value: 'event', child: Text('Organize an event')),
                PopupMenuItem(value: 'pause', child: Text(c.isPaused ? 'Reactivate' : 'Pause the club')),
              ],
            ),
        ],
      ),
      body: AsyncValueView(
        value: club,
        onRetry: () => ref.invalidate(clubProvider(clubId)),
        data: (club) {
          final owner = club.creatorId == me;
          final feed = ref.watch(feedProvider(key));
          final controller = ref.read(feedProvider(key).notifier);
          final events = (ref.watch(eventsProvider).value ?? const <CommunityEvent>[])
              .where(
                (e) => e.club?.id == club.id && (e.status == EventStatus.approved || e.creatorId == me) && !e.isPast(),
              )
              .toList();
          return RefreshIndicator(
            onRefresh: () =>
                Future.wait([ref.refresh(clubProvider(clubId).future), ref.refresh(feedProvider(key).future)]),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                if (club.isPaused) ...[
                  const InfoBanner('This club is paused', icon: Icons.pause_circle_outline, color: AppAccent.amber),
                  const SizedBox(height: 12),
                ],
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconBubble(
                              icon: Icons.interests_outlined,
                              color: communityColor(club.name),
                              size: 52,
                              solid: true,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                club.name,
                                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                        if ((club.description ?? '').isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            club.description!,
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                        if (club.interests.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Wrap(spacing: 6, runSpacing: 6, children: [for (final i in club.interests) PillTag('#$i')]),
                        ],
                        if (club.creatorId != null) ...[
                          const Divider(height: 24),
                          Author(userId: club.creatorId!, subtitle: owner ? 'You run this club' : 'Runs this club'),
                        ],
                      ],
                    ),
                  ),
                ),
                if (events.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 16, 4, 10),
                    child: Text(
                      'Upcoming events',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  for (final event in events) EventTile(event: event, mine: event.creatorId == me),
                ],
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 16, 4, 10),
                  child: Text('Posts', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                ),
                if (owner) ...[
                  Composer(
                    hint: 'Share news with the club…',
                    where: club.name,
                    canAnnounce: true,
                    onPublish: (content, announcement) => controller.publish(content, announcement: announcement),
                  ),
                  const SizedBox(height: 10),
                ],
                ...feed.when(
                  loading: () => [
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ],
                  error: (e, _) => [Text(ApiException.from(e).message)],
                  data: (posts) => posts.isEmpty
                      ? [
                          const Padding(
                            padding: EdgeInsets.only(top: 24),
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
        },
      ),
    );
  }
}

/// Create a club, or edit it when [clubId] is set (its creator only).
class ClubFormScreen extends ConsumerStatefulWidget {
  const ClubFormScreen({super.key, this.clubId});

  final int? clubId;

  @override
  ConsumerState<ClubFormScreen> createState() => _ClubFormScreenState();
}

class _ClubFormScreenState extends ConsumerState<ClubFormScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _interests = TextEditingController();
  Club? _existing;
  bool _loaded = false;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _interests.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final interests = _interests.text
        .split(',')
        .map((i) => i.trim().toLowerCase())
        .where((i) => i.isNotEmpty)
        .join(',');
    try {
      final club = await ref
          .read(communityRepositoryProvider)
          .saveClub(
            Club(
              id: _existing?.id ?? 0,
              name: _name.text.trim(),
              description: _description.text.trim(),
              interestsText: interests,
              creatorId: _existing?.creatorId ?? ref.read(authControllerProvider).value!.userId,
              status: _existing?.status ?? 'ACTIVE',
            ),
          );
      ref.invalidate(clubsProvider);
      ref.invalidate(clubProvider(club.id));
      if (!mounted) return;
      _existing == null ? context.pushReplacement(CommunityPaths.club(club.id)) : context.pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.clubId != null && !_loaded) {
      final club = ref.watch(clubProvider(widget.clubId!));
      if (club.value case final c?) {
        _existing = c;
        _name.text = c.name;
        _description.text = c.description ?? '';
        _interests.text = c.interests.join(', ');
        _loaded = true;
      } else {
        return Scaffold(
          appBar: AppBar(title: const Text('Edit the club')),
          body: AsyncValueView(value: club, data: (_) => const SizedBox()),
        );
      }
    }
    return Scaffold(
      appBar: AppBar(title: Text(_existing == null ? 'New club' : 'Edit the club')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            SectionCard(
              title: 'The club',
              child: Column(
                children: [
                  LabeledField(
                    label: 'Name',
                    child: TextFormField(
                      controller: _name,
                      maxLength: 80,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(hintText: 'e.g. UI/UX Design Club'),
                      validator: (v) => (v ?? '').trim().length < 3 ? 'At least 3 characters' : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  LabeledField(
                    label: 'Description',
                    child: TextFormField(
                      controller: _description,
                      minLines: 3,
                      maxLines: 6,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(hintText: 'What the club does, who can join…'),
                      validator: (v) => (v ?? '').trim().length < 10 ? 'At least 10 characters' : null,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SectionCard(
              title: 'Interests',
              child: TextFormField(
                controller: _interests,
                decoration: const InputDecoration(
                  hintText: 'design, figma, ux',
                  prefixIcon: Icon(Icons.tag),
                  helperText: 'Separated by commas: people find the club with them.',
                ),
                validator: (v) => (v ?? '').trim().isEmpty ? 'Add at least one interest' : null,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_existing == null ? 'Create the club' : 'Save'),
          ),
        ),
      ),
    );
  }
}
