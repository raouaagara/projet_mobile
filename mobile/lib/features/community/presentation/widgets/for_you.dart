import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../shared/widgets/ui_kit.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../profile/data/competence_repository.dart';
import '../../community_paths.dart';
import '../../data/community_repository.dart';

/// The AI's picks for me, once asked (null: not asked yet). Kept while the app runs.
final communityPicksProvider = NotifierProvider<CommunityPicksController, AsyncValue<List<CommunityPick>>?>(
  CommunityPicksController.new,
);

class CommunityPicksController extends Notifier<AsyncValue<List<CommunityPick>>?> {
  @override
  AsyncValue<List<CommunityPick>>? build() => null;

  /// Sends my role, skills (names, from module 1) and bio; the server knows the groups I'm already in.
  Future<void> find() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final me = await ref.read(currentUserProvider.future).timeout(const Duration(seconds: 8));
      if (me == null) throw const ApiException('Log in first.');
      final catalog = await ref
          .read(competenceCatalogProvider.future)
          .timeout(const Duration(seconds: 8))
          .catchError((_) => <Never>[]);
      return ref
          .read(communityRepositoryProvider)
          .recommend(
            userId: me.id,
            role: me.role.name.toUpperCase(),
            skills: [
              for (final c in catalog)
                if (me.competenceIds.contains(c.id)) c.name,
            ],
            bio: me.bio,
          );
    });
  }
}

/// "Picked for you": groups, clubs and events that fit my skills, with the AI's reason for each.
class ForYouCard extends ConsumerWidget {
  const ForYouCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final picks = ref.watch(communityPicksProvider);
    final list = picks?.value;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppAccent.purple.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppAccent.purple, size: 20),
              const SizedBox(width: 8),
              Text('Picked for you', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 2),
          if (list == null) ...[
            Text(
              'Groups, clubs and events that fit your skills.',
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
            const SizedBox(height: 12),
            AiButton(
              label: 'Show me',
              busy: picks?.isLoading ?? false,
              onPressed: () => ref.read(communityPicksProvider.notifier).find(),
            ),
            if (picks?.hasError ?? false)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  ApiException.from(picks!.error!).message,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                ),
              ),
          ] else if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Nothing fits you yet. Add skills to your profile, or start a group!',
                style: theme.textTheme.bodyMedium?.copyWith(color: muted),
              ),
            )
          else
            for (final pick in list) _PickRow(pick: pick),
        ],
      ),
    );
  }
}

class _PickRow extends StatelessWidget {
  const _PickRow({required this.pick});

  final CommunityPick pick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, label, path) = switch (pick.kind) {
      'CLUB' => (Icons.diversity_3_outlined, 'Club', CommunityPaths.club(pick.id)),
      'EVENT' => (Icons.event_outlined, 'Event', CommunityPaths.event(pick.id)),
      _ => (Icons.groups_outlined, 'Group', CommunityPaths.group(pick.id)),
    };
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => context.push(path),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconBubble(icon: icon, color: AppAccent.purple, size: 38),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pick.name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  Text(
                    pick.reason.isEmpty ? label : '$label. ${pick.reason}',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.35),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
