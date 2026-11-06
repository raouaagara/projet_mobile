import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/router/app_paths.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../project_providers.dart';
import 'module_link.dart';
import 'notification_bell.dart';

/// Top of the home tab: my avatar, "Hi Sara", my role, and the notification bell.
class HomeHeader extends ConsumerWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final session = ref.watch(authControllerProvider).value;
    final user = session == null ? null : ref.watch(projectUserProvider(session.userId)).value;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: 'My profile',
            child: GestureDetector(
              onTap: () => openModuleLink(context, AppPaths.profile, comingSoon: 'Profiles arrive with module 1.'),
              child: UserAvatar(user: user, radius: 24),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user == null ? 'Welcome back' : 'Hi, ${user.firstName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  session?.isClient ?? false ? "I'm a client" : "I'm a freelancer",
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const NotificationBell(),
        ],
      ),
    );
  }
}

/// Light green banner with a title (one word highlighted), a button and an illustration.
class PromoBanner extends StatelessWidget {
  const PromoBanner({
    super.key,
    required this.title,
    required this.highlight,
    required this.action,
    required this.onPressed,
    required this.image,
  });

  final String title;

  /// Last words of the title, in green.
  final String highlight;
  final String action;
  final VoidCallback onPressed;

  /// An SVG illustration from the assets.
  final String image;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      height: 148,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: colors.primaryContainer, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Expanded(
            flex: 11,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 4, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: '$title '),
                        TextSpan(
                          text: highlight,
                          style: TextStyle(color: colors.primary),
                        ),
                      ],
                    ),
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, height: 1.2),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: onPressed,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 38),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      textStyle: theme.textTheme.labelLarge?.copyWith(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    child: Text(action),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 9,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 12, 10, 8),
              child: SvgPicture.asset(image, fit: BoxFit.contain, excludeFromSemantics: true),
            ),
          ),
        ],
      ),
    );
  }
}
