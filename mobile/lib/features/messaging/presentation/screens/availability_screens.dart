import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/brand.dart';
import '../../../../shared/widgets/async_value_view.dart';
import '../../../../shared/widgets/ui_kit.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../../data/models/availability_models.dart';
import '../../data/time_zones.dart';
import '../../messaging_paths.dart';
import '../format.dart';
import '../messaging_providers.dart';
import '../widgets/common.dart';

String _clock(DateTime time) => '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

// ── Freelancer: my availability ────────────────────────────────────

class AvailabilityScreen extends ConsumerWidget {
  const AvailabilityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('My availability')),
      body: AsyncValueView(
        value: ref.watch(myAvailabilityProvider),
        onRetry: () => ref.invalidate(myAvailabilityProvider),
        data: (profile) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconBubble(icon: Icons.visibility_outlined, color: profile.status.color, size: 48, solid: true),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'What clients see',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          AvailabilityBadge(profile: profile),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _StatusSection(profile: profile),
            const SizedBox(height: 12),
            _TimeZoneSection(profile: profile),
            const SizedBox(height: 12),
            const _SlotsSection(),
          ],
        ),
      ),
    );
  }
}

Future<void> _save(BuildContext context, WidgetRef ref, AvailabilityProfile profile, String done) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await ref.read(myAvailabilityProvider.notifier).save(profile);
    messenger.showSnackBar(SnackBar(content: Text(done)));
  } on ApiException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.message)));
  }
}

class _StatusSection extends ConsumerStatefulWidget {
  const _StatusSection({required this.profile});

  final AvailabilityProfile profile;

  @override
  ConsumerState<_StatusSection> createState() => _StatusSectionState();
}

class _StatusSectionState extends ConsumerState<_StatusSection> {
  late final _message = TextEditingController(text: widget.profile.customStatusMessage);

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    return SectionCard(
      title: 'Status',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final status in AvailabilityStatus.choices)
                ChoiceChip(
                  avatar: CircleAvatar(radius: 5, backgroundColor: status.color),
                  showCheckmark: false,
                  label: Text(status.label),
                  selected: profile.status == status,
                  onSelected: (_) => status == AvailabilityStatus.custom
                      ? _save(
                          context,
                          ref,
                          profile.copyWith(status: status, customStatusMessage: _message.text.trim()),
                          'Status: custom',
                        )
                      : _save(
                          context,
                          ref,
                          profile.copyWith(status: status, customStatusMessage: ''),
                          'Status: ${status.label}',
                        ),
                ),
            ],
          ),
          if (profile.status == AvailabilityStatus.custom) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _message,
              maxLength: 200,
              decoration: InputDecoration(
                hintText: 'Your message, e.g. Back on Monday',
                suffixIcon: IconButton(
                  tooltip: 'Save',
                  icon: const Icon(Icons.check),
                  onPressed: () =>
                      _save(context, ref, profile.copyWith(customStatusMessage: _message.text.trim()), 'Message saved'),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TimeZoneSection extends ConsumerWidget {
  const _TimeZoneSection({required this.profile});

  final AvailabilityProfile profile;

  Future<void> _change(BuildContext context, WidgetRef ref) async {
    final zone = await showModalBottomSheet<TimeZoneInfo>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const _TimeZonePicker(),
    );
    if (zone == null || !context.mounted) return;
    final offset = zone.offsetAt(DateTime.now().toUtc()).inMinutes;
    await _save(
      context,
      ref,
      profile.copyWith(timezone: zone.name, timezoneOffsetMinutes: offset),
      'Time zone: ${zone.city}',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zone = TimeZones.byName(profile.timezone);
    return SectionCard(
      title: 'Time zone',
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const IconBubble(icon: Icons.public, color: AppAccent.blue, size: 42),
        title: Text(
          zone == null ? profile.timezone : '${zone.city} (${zone.name})',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('${TimeZones.formatOffset(profile.utcOffset)} · ${_clock(profile.localTime())} now'),
        trailing: TextButton(onPressed: () => _change(context, ref), child: const Text('Change')),
      ),
    );
  }
}

class _TimeZonePicker extends StatefulWidget {
  const _TimeZonePicker();

  @override
  State<_TimeZonePicker> createState() => _TimeZonePickerState();
}

class _TimeZonePickerState extends State<_TimeZonePicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().toUtc();
    final device = TimeZones.guessForDevice();
    final zones = TimeZones.all
        .where((z) => _query.isEmpty || z.city.toLowerCase().contains(_query) || z.name.toLowerCase().contains(_query))
        .toList();
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.8,
        child: Column(
          children: [
            MenuTile(
              icon: Icons.my_location,
              color: AppAccent.green,
              title: "My phone's time zone",
              subtitle: device.city,
              onTap: () => Navigator.pop(context, device),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: SearchField(
                hintText: 'Search a city',
                onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  for (final zone in zones)
                    ListTile(
                      title: Text(zone.city),
                      subtitle: Text(zone.name),
                      trailing: Text(TimeZones.formatOffset(zone.offsetAt(now))),
                      onTap: () => Navigator.pop(context, zone),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlotsSection extends ConsumerWidget {
  const _SlotsSection();

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final slots = await showDialog<List<AvailabilitySlot>>(context: context, builder: (_) => const _SlotDialog());
    if (slots == null || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      for (final slot in slots) {
        await ref.read(mySlotsProvider.notifier).add(slot);
      }
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final slots = ref.watch(mySlotsProvider);
    return SectionCard(
      title: 'Working hours',
      action: TextButton.icon(
        onPressed: () => _add(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'In your time zone. Clients see them in theirs.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          slots.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text(ApiException.from(e).message),
            data: (slots) => slots.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('No working hours yet. Add when clients can reach you.'),
                  )
                : Column(
                    children: [
                      for (final day in Weekday.values)
                        if (slots.any((s) => s.dayOfWeek == day))
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 96,
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 9),
                                    child: Text(day.label, style: const TextStyle(fontWeight: FontWeight.w700)),
                                  ),
                                ),
                                Expanded(
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: [
                                      for (final slot in slots.where((s) => s.dayOfWeek == day))
                                        InputChip(
                                          label: Text(slot.label),
                                          labelStyle: theme.textTheme.labelLarge?.copyWith(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.08),
                                          side: BorderSide.none,
                                          deleteIconColor: theme.colorScheme.primary,
                                          onDeleted: () => ref.read(mySlotsProvider.notifier).remove(slot),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _SlotDialog extends StatefulWidget {
  const _SlotDialog();

  @override
  State<_SlotDialog> createState() => _SlotDialogState();
}

class _SlotDialogState extends State<_SlotDialog> {
  final Set<Weekday> _days = {Weekday.monday, Weekday.tuesday, Weekday.wednesday, Weekday.thursday, Weekday.friday};
  TimeOfDay _start = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 17, minute: 0);
  String? _error;

  String _fmt(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pick(bool start) async {
    final time = await showTimePicker(context: context, initialTime: start ? _start : _end);
    if (time != null) setState(() => start ? _start = time : _end = time);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Working hours'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final day in Weekday.values)
                FilterChip(
                  label: Text(day.short),
                  selected: _days.contains(day),
                  onSelected: (on) => setState(() => on ? _days.add(day) : _days.remove(day)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(onPressed: () => _pick(true), child: Text('From ${_fmt(_start)}')),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(onPressed: () => _pick(false), child: Text('To ${_fmt(_end)}')),
              ),
            ],
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
          onPressed: () {
            if (_days.isEmpty) return setState(() => _error = 'Pick at least one day');
            if (_end.hour * 60 + _end.minute <= _start.hour * 60 + _start.minute) {
              return setState(() => _error = 'The end must be after the start');
            }
            // The same hours on every picked day.
            Navigator.pop(context, [
              for (final day in Weekday.values)
                if (_days.contains(day)) AvailabilitySlot(dayOfWeek: day, startTime: _fmt(_start), endTime: _fmt(_end)),
            ]);
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

// ── Client: world clock ────────────────────────────────────────────

/// When freelancers are reachable: their status and local time, ticking.
class WorldClockScreen extends ConsumerStatefulWidget {
  const WorldClockScreen({super.key});

  @override
  ConsumerState<WorldClockScreen> createState() => _WorldClockScreenState();
}

class _WorldClockScreenState extends ConsumerState<WorldClockScreen> {
  Timer? _tick;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 30), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final myZone = TimeZones.guessForDevice();
    return Scaffold(
      appBar: AppBar(title: const Text('World clock')),
      body: AsyncValueView(
        value: ref.watch(worldViewProvider),
        onRetry: () => ref.invalidate(worldViewProvider),
        data: (profiles) {
          final shown = profiles.where((p) {
            if (_query.isEmpty) return true;
            final name = ref.watch(chatUserProvider(p.userId)).value?.fullName.toLowerCase() ?? '';
            return name.contains(_query) || p.timezone.toLowerCase().contains(_query);
          }).toList()..sort((a, b) => a.status.rank.compareTo(b.status.rank));
          return RefreshIndicator(
            onRefresh: () => ref.refresh(worldViewProvider.future),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                _MyClock(city: myZone.city),
                const SizedBox(height: 14),
                SearchField(
                  hintText: 'Search a freelancer or a zone',
                  onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                ),
                const SizedBox(height: 4),
                if (shown.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 64),
                    child: EmptyView(
                      message: 'No freelancer has shared their availability yet.',
                      icon: Icons.public_off,
                    ),
                  ),
                for (final profile in shown) _FreelancerClock(profile: profile),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// The user's own time on a green card.
class _MyClock extends StatelessWidget {
  const _MyClock({required this.city});

  final String city;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Brand.green, Brand.darkGreen],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your time',
                  style: text.titleSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  _clock(DateTime.now()),
                  style: text.displaySmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.place_outlined, size: 16, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(city, style: text.bodyMedium?.copyWith(color: Colors.white)),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.2)),
            child: const Icon(Icons.public, color: Colors.white, size: 34),
          ),
        ],
      ),
    );
  }
}

class _FreelancerClock extends ConsumerWidget {
  const _FreelancerClock({required this.profile});

  final AvailabilityProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(chatUserProvider(profile.userId)).value;
    final local = profile.localTime();
    final today = Weekday.of(local);
    final slots = ref.watch(slotsOfUserProvider(profile.userId)).value;
    final todaySlots = slots?.where((s) => s.dayOfWeek == today).toList();
    final nowMinutes = local.hour * 60 + local.minute;
    final working = todaySlots?.any((s) => minutesOf(s.startTime) <= nowMinutes && nowMinutes < minutesOf(s.endTime));

    final muted = theme.colorScheme.onSurfaceVariant;
    return Card(
      margin: const EdgeInsets.only(top: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                UserAvatar(user: user, radius: 26),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: profile.status.color,
                      shape: BoxShape.circle,
                      border: Border.all(color: theme.colorScheme.surface, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user?.fullName ?? '…',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        _clock(local),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  AvailabilityBadge(profile: profile, showLocalTime: false),
                  const SizedBox(height: 4),
                  Text(
                    [
                      TimeZones.byName(profile.timezone)?.city ?? profile.timezone,
                      if (todaySlots != null)
                        todaySlots.isEmpty
                            ? 'not working today'
                            : '${working == true ? 'working now' : 'today'} ${todaySlots.map((s) => s.label).join(', ')}',
                      if (profile.lastSeenAt != null) 'seen ${ago(profile.lastSeenAt!.toLocal())}',
                    ].join(' · '),
                    style: theme.textTheme.bodySmall?.copyWith(color: muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            IconButton.filledTonal(
              tooltip: 'Message',
              icon: const Icon(Icons.chat_bubble_outline, size: 20),
              onPressed: () => context.push(MessagingPaths.chatWith(profile.userId)),
            ),
          ],
        ),
      ),
    );
  }
}
