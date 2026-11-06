import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/async_value_view.dart';
import '../../../../shared/widgets/ui_kit.dart';
import '../../data/models/project.dart';
import '../../data/models/project_enums.dart';
import '../../project_paths.dart';
import '../project_providers.dart';
import '../widgets/category_style.dart';
import '../widgets/home_widgets.dart';
import '../widgets/project_card.dart';
import '../widgets/status_chips.dart';

/// Client home: my projects by status, and the button to post one.
class ClientProjectsScreen extends ConsumerStatefulWidget {
  const ClientProjectsScreen({super.key});

  @override
  ConsumerState<ClientProjectsScreen> createState() => _ClientProjectsScreenState();
}

class _ClientProjectsScreenState extends ConsumerState<ClientProjectsScreen> {
  ProjectStatus? _status;

  Future<void> _refresh() =>
      Future.wait([ref.refresh(projectsControllerProvider.future), ref.refresh(notificationsProvider.future)]);

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(myProjectsProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        tooltip: 'Post a project',
        onPressed: () => context.push(ProjectPaths.create),
        shape: const CircleBorder(),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const HomeHeader(),
            Expanded(
              child: AsyncValueView(
                value: projects,
                onRetry: () => ref.invalidate(projectsControllerProvider),
                data: (projects) => RefreshIndicator(onRefresh: _refresh, child: _list(projects)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _list(List<Project> projects) {
    final theme = Theme.of(context);
    final shown = _status == null ? projects : projects.where((p) => p.status == _status).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        PromoBanner(
          title: 'Get matched with',
          highlight: 'freelancers',
          action: 'Post a project',
          image: 'assets/onboarding/work_safely.svg',
          onPressed: () => context.push(ProjectPaths.create),
        ),
        const SizedBox(height: 20),
        Text('My projects', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        if (projects.isEmpty)
          const _NoProjects()
        else ...[
          Row(
            children: [
              for (final status in ProjectStatus.choices) ...[
                Expanded(
                  child: _StatusCount(
                    status: status,
                    count: projects.where((p) => p.status == status).length,
                    selected: _status == status,
                    onTap: () => setState(() => _status = _status == status ? null : status),
                  ),
                ),
                if (status != ProjectStatus.choices.last) const SizedBox(width: 10),
              ],
            ],
          ),
          const SizedBox(height: 16),
          if (shown.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 32),
              child: EmptyView(message: 'No ${_status!.label.toLowerCase()} project.', icon: _status!.icon),
            ),
          for (final project in shown)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ProjectCard(
                project: project,
                trailing: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ProjectStatusChip(status: project.status),
                ),
                onTap: () => context.push(ProjectPaths.details(project.id!)),
              ),
            ),
        ],
      ],
    );
  }
}

/// A count per status that also filters the list.
class _StatusCount extends StatelessWidget {
  const _StatusCount({required this.status, required this.count, required this.selected, required this.onTap});

  final ProjectStatus status;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final color = statusColor(status);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: selected ? color : colors.outlineVariant, width: selected ? 1.6 : 1),
    );
    return Semantics(
      selected: selected,
      child: Material(
        color: selected ? color.withValues(alpha: 0.08) : colors.surface,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconBubble(icon: status.icon, color: color, size: 36, solid: true),
                const SizedBox(height: 8),
                Text('$count', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                Text(
                  status.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NoProjects extends StatelessWidget {
  const _NoProjects();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
        child: Column(
          children: [
            const IconBubble(icon: Icons.rocket_launch_outlined, color: AppAccent.green, size: 76),
            const SizedBox(height: 16),
            Text(
              'Post your first project',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Describe what you need and your budget. Freelancers will send you proposals.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
