import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/brand.dart';
import '../../../../shared/widgets/workify_logo.dart';

export '../../../../shared/widgets/ui_kit.dart' show LabeledField;

/// Page of the login and sign-up screens: the [header] on top, the [content] centered below it, and the
/// [actions] at the bottom of the screen. It scrolls when the keyboard is open.
///
/// With a [title], the title sits in the upper middle of the free space (where it would be centered with the
/// content) and the [content] is centered between the title and the actions.
class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key, required this.header, this.title, required this.content, required this.actions});

  final Widget header;
  final Widget? title;
  final List<Widget> content;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  header,
                  // The free space is shared above and below the content, so it sits in the middle.
                  if (title != null) ...[
                    const Spacer(flex: 2),
                    Padding(padding: const EdgeInsets.fromLTRB(24, 0, 24, 16), child: title),
                  ],
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: content),
                  ),
                  const Spacer(),
                  Padding(
                    padding: EdgeInsets.fromLTRB(24, 24, 24, 12 + MediaQuery.paddingOf(context).bottom),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: actions),
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

/// Top of the login and sign-up pages: the logo and the name on a light panel with a curved bottom.
class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key, this.compact = false, this.onBack});

  /// Smaller, for the long sign-up form.
  final bool compact;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final top = MediaQuery.paddingOf(context).top;
    return ClipPath(
      clipper: const _CurvedBottom(),
      child: ColoredBox(
        color: colors.brightness == Brightness.light ? colors.surfaceContainer : colors.surfaceContainerHigh,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: compact ? 0 : MediaQuery.sizeOf(context).height * 0.40),
          child: Padding(
            padding: EdgeInsets.only(top: top + (compact ? 8 : 24), bottom: compact ? 36 : 48),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (onBack != null)
                  Positioned(
                    left: 4,
                    top: 0,
                    child: IconButton(icon: const Icon(Icons.arrow_back), tooltip: 'Back', onPressed: onBack),
                  ),
                Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: compact ? 8 : 0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        WorkifyLogo(size: compact ? 64 : 140),
                        SizedBox(height: compact ? 2 : 8),
                        // Slightly left, under the W rather than under the whole mark.
                        Transform.translate(
                          offset: Offset(compact ? -3 : -6, 0),
                          child: Text(
                            Brand.name,
                            style: (compact ? theme.textTheme.titleMedium : theme.textTheme.titleLarge)?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CurvedBottom extends CustomClipper<Path> {
  const _CurvedBottom();

  @override
  Path getClip(Size size) => Path()
    ..lineTo(0, size.height - 32)
    ..quadraticBezierTo(size.width / 2, size.height + 24, size.width, size.height - 32)
    ..lineTo(size.width, 0)
    ..close();

  @override
  bool shouldReclip(_CurvedBottom oldClipper) => false;
}

/// Page title under the header, with an optional line under it.
class AuthTitle extends StatelessWidget {
  const AuthTitle(this.title, {super.key, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(title, textAlign: TextAlign.center, style: theme.textTheme.headlineSmall),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}

/// "Already have an account? Log in" and the like.
class AuthSwitchLink extends StatelessWidget {
  const AuthSwitchLink({super.key, required this.question, required this.action, required this.onTap});

  final String question;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(question, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6)),
          child: Text(action),
        ),
      ],
    );
  }
}
