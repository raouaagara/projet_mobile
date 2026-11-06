import 'package:flutter/material.dart';

/// Temporary screen shown until a module owner builds the real one.
/// Delete its usages from your module as you implement screens.
class ModulePlaceholder extends StatelessWidget {
  const ModulePlaceholder({
    super.key,
    required this.title,
    required this.module,
    required this.description,
    this.showAppBar = true,
  });

  final String title;
  final String module;
  final String description;

  /// False for bottom-tab roots, which get their app bar from the module.
  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title), automaticallyImplyLeading: showAppBar),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.construction_outlined, size: 56, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(title, style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Chip(label: Text(module)),
              const SizedBox(height: 12),
              Text(description, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
