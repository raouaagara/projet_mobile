import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_paths.dart';
import '../../../../shared/widgets/ui_kit.dart';

/// Shown instead of an AI feature when the user has no Premium/Enterprise plan.
class PremiumRequired extends StatelessWidget {
  const PremiumRequired({super.key, required this.feature});

  final String feature;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const IconBubble(icon: Icons.workspace_premium, color: AppAccent.amber, size: 76, solid: true),
                const SizedBox(height: 18),
                Text('Premium feature', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(
                  '$feature is included in the Premium and Enterprise plans.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.5),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => context.push(AppPaths.subscriptions),
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('See plans'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
