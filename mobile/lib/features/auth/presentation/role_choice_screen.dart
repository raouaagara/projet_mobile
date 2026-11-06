import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/user_role.dart';
import '../../../core/router/app_paths.dart';
import 'widgets/auth_widgets.dart';

/// First step of the sign-up: client or freelancer. The form comes next (`/register/details`).
class RoleChoiceScreen extends StatefulWidget {
  const RoleChoiceScreen({super.key});

  static String detailsPath(UserRole role) => '${AppPaths.register}/details?role=${role.name}';

  @override
  State<RoleChoiceScreen> createState() => _RoleChoiceScreenState();
}

class _RoleChoiceScreenState extends State<RoleChoiceScreen> {
  UserRole? _role;

  @override
  Widget build(BuildContext context) {
    final role = _role;
    return AuthLayout(
      header: const AuthHeader(),
      title: const AuthTitle('Join as a client or freelancer'),
      content: [
        _RoleCard(
          avatar: 'assets/avatars/client.svg',
          title: "I'm a client",
          subtitle: "I'm looking for help with a project",
          selected: role == UserRole.client,
          onTap: () => setState(() => _role = UserRole.client),
        ),
        const SizedBox(height: 20),
        _RoleCard(
          avatar: 'assets/avatars/freelancer.svg',
          title: "I'm a freelancer",
          subtitle: "I'm looking for work that fits my skills",
          selected: role == UserRole.freelancer,
          onTap: () => setState(() => _role = UserRole.freelancer),
        ),
      ],
      actions: [
        FilledButton(
          onPressed: role == null ? null : () => context.push(RoleChoiceScreen.detailsPath(role)),
          child: Text(switch (role) {
            UserRole.client => 'Join as a client',
            UserRole.freelancer => 'Join as a freelancer',
            _ => 'Create an account',
          }),
        ),
        const SizedBox(height: 8),
        AuthSwitchLink(
          question: 'Already have an account?',
          action: 'Log in',
          onTap: () => context.go(AppPaths.login),
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.avatar,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  /// unDraw avatar (undraw.co, free license), colored in Workify green on the site.
  final String avatar;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: selected ? colors.primary : colors.outlineVariant, width: selected ? 1.6 : 1),
    );
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: Material(
        color: selected ? colors.primaryContainer.withValues(alpha: 0.45) : colors.surface,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                SvgPicture.asset(avatar, width: 68, height: 68, excludeFromSemantics: true),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: selected
                      ? Icon(Icons.check_circle, key: const ValueKey(true), color: colors.primary)
                      : Icon(Icons.radio_button_unchecked, key: const ValueKey(false), color: colors.outline),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
