import 'package:flutter/material.dart';

/// Workify's building blocks, shared by every module so the screens look alike:
/// colored round icons, stat tiles, white section cards, menu rows and pills.

/// Accent colors for icons (categories, menu rows, stat tiles).
abstract final class AppAccent {
  static const green = Color(0xFF3F9A2E);
  static const blue = Color(0xFF2F6BE6);
  static const orange = Color(0xFFF08A00);
  static const red = Color(0xFFE5484D);
  static const purple = Color(0xFF7A5AF8);
  static const cyan = Color(0xFF0FA3C8);
  static const pink = Color(0xFFE0418F);
  static const amber = Color(0xFFE9A300);
  static const grey = Color(0xFF7A8577);
}

/// An icon in a round bubble: tinted (soft background, colored icon) or [solid] (colored, white icon).
class IconBubble extends StatelessWidget {
  const IconBubble({super.key, required this.icon, required this.color, this.size = 44, this.solid = false});

  final IconData icon;
  final Color color;
  final double size;
  final bool solid;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: solid ? color : color.withValues(alpha: dark ? 0.24 : 0.12),
      ),
      child: Icon(icon, size: size * 0.5, color: solid ? Colors.white : color),
    );
  }
}

/// A number with its label under a colored icon, like a dashboard tile.
class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.icon, required this.color, required this.value, required this.label});

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconBubble(icon: icon, color: color, size: 38, solid: true),
            const SizedBox(height: 10),
            // Long values ("Intermediate") shrink to fit rather than being cut.
            SizedBox(
              height: 30,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value, style: theme.textTheme.titleLarge, maxLines: 1),
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

/// A white rounded card with a title and an optional action ("Edit", "View all").
class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.title, required this.child, this.action, this.icon});

  final String title;
  final Widget child;
  final Widget? action;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 6, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 48,
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  ?action,
                ],
              ),
            ),
            Padding(padding: const EdgeInsets.only(right: 10), child: child),
          ],
        ),
      ),
    );
  }
}

/// A row with a colored round icon, a title, an optional subtitle and a chevron, like a settings menu.
class MenuTile extends StatelessWidget {
  const MenuTile({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: IconBubble(icon: icon, color: color, size: 40),
      title: Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
      subtitle: subtitle == null
          ? null
          : Text(subtitle!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      trailing: trailing ?? (onTap == null ? null : Icon(Icons.chevron_right, color: theme.colorScheme.outline)),
      onTap: onTap,
    );
  }
}

/// A small rounded label, light green by default ("Freelancer", a skill, a status).
class PillTag extends StatelessWidget {
  const PillTag(this.label, {super.key, this.icon, this.color});

  final String label;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = color ?? theme.colorScheme.primary;
    final dark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: base.withValues(alpha: dark ? 0.22 : 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 15, color: base), const SizedBox(width: 5)],
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(color: base, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// A form field with its label above it, like in the design.
class LabeledField extends StatelessWidget {
  const LabeledField({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

/// Steps of a flow as bars ("1 of 2"), the done ones in green.
class StepProgress extends StatelessWidget {
  const StepProgress({super.key, required this.step, required this.total});

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        for (var i = 1; i <= total; i++) ...[
          if (i > 1) const SizedBox(width: 6),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 6,
              decoration: BoxDecoration(
                color: i <= step ? colors.primary : colors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ],
        const SizedBox(width: 10),
        Text('Step $step of $total', style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}

/// Tabs as a grey capsule with the selected one in green, like "Active · Pending · Completed".
/// Needs a [DefaultTabController] (or a [controller]) above it.
class PillTabBar extends StatelessWidget {
  const PillTabBar({super.key, required this.tabs, this.controller});

  final List<String> tabs;
  final TabController? controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: colors.surfaceContainerHigh, borderRadius: BorderRadius.circular(26)),
      child: TabBar(
        controller: controller,
        tabs: [for (final tab in tabs) Tab(text: tab, height: 38)],
        indicator: BoxDecoration(color: colors.primary, borderRadius: BorderRadius.circular(22)),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: colors.onPrimary,
        unselectedLabelColor: colors.onSurfaceVariant,
        splashBorderRadius: BorderRadius.circular(22),
        labelStyle: theme.textTheme.labelLarge?.copyWith(fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle: theme.textTheme.labelLarge?.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// A tinted box with an icon and a short explanation ("The money stays in escrow...").
class InfoBanner extends StatelessWidget {
  const InfoBanner(this.text, {super.key, this.icon = Icons.info_outline, this.color});

  final String text;
  final IconData icon;

  /// Green by default.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = color ?? theme.colorScheme.primary;
    final dark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: base.withValues(alpha: dark ? 0.20 : 0.09),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: base),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// Rounded filters in a row that scrolls sideways (or wraps); the selected one is green,
/// like "Active · Pending · Completed".
class FilterPills<T> extends StatelessWidget {
  const FilterPills({
    super.key,
    required this.values,
    required this.selected,
    required this.label,
    required this.onSelected,
    this.icon,
    this.wrap = false,
  });

  final List<T> values;

  /// Null when none is selected (e.g. an amount typed by hand).
  final T? selected;
  final String Function(T value) label;
  final ValueChanged<T> onSelected;

  /// An optional icon before the label.
  final IconData? Function(T value)? icon;

  /// Wraps on several lines instead of scrolling sideways.
  final bool wrap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    Widget pill(T value) {
      final on = value == selected;
      final foreground = on ? colors.onPrimary : colors.onSurfaceVariant;
      final iconData = icon?.call(value);
      return Material(
        color: on ? colors.primary : colors.surface,
        shape: StadiumBorder(side: BorderSide(color: on ? colors.primary : colors.outlineVariant)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => onSelected(value),
          child: Padding(
            padding: EdgeInsets.fromLTRB(iconData == null ? 16 : 12, 9, 16, 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (iconData != null) ...[Icon(iconData, size: 16, color: foreground), const SizedBox(width: 6)],
                Text(
                  label(value),
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: foreground,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (wrap) return Wrap(spacing: 8, runSpacing: 8, children: [for (final value in values) pill(value)]);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [for (final value in values) Padding(padding: const EdgeInsets.only(right: 8), child: pill(value))],
      ),
    );
  }
}

/// A rounded search box, white with a light border.
class SearchField extends StatelessWidget {
  const SearchField({super.key, required this.hintText, required this.onChanged, this.autofocus = false});

  final String hintText;
  final ValueChanged<String> onChanged;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(28),
      borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
    );
    return TextField(
      autofocus: autofocus,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search),
        isDense: true,
        border: border,
        enabledBorder: border,
      ),
    );
  }
}

/// Purple outlined "… with AI" button, with a spinner while the AI writes.
class AiButton extends StatelessWidget {
  const AiButton({super.key, required this.label, required this.busy, required this.onPressed});

  final String label;
  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppAccent.purple,
        side: BorderSide(color: AppAccent.purple.withValues(alpha: 0.4)),
      ),
      onPressed: busy ? null : onPressed,
      icon: busy
          ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.auto_awesome, size: 18),
      label: Text(busy ? 'Writing…' : label),
    );
  }
}
