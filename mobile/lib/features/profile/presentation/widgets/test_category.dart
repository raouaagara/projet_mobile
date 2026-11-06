import 'package:flutter/material.dart';

import '../../../../shared/widgets/ui_kit.dart';

/// Words found in a category name → its icon and color. The first match wins.
const _rules = <({List<String> words, IconData icon, Color color})>[
  (words: ['programming'], icon: Icons.code, color: AppAccent.blue),
  (words: ['mobile', 'android', 'ios', 'flutter'], icon: Icons.phone_android, color: AppAccent.green),
  (
    words: ['web', 'front', 'html', 'css', 'javascript', 'react', 'angular'],
    icon: Icons.language,
    color: AppAccent.blue,
  ),
  (
    words: ['back', 'java', 'spring', 'api', 'server', 'database', 'sql'],
    icon: Icons.dns_outlined,
    color: AppAccent.purple,
  ),
  (words: ['design', 'ui', 'ux', 'graphic'], icon: Icons.brush_outlined, color: AppAccent.pink),
  (words: ['data', ' ai', 'ai ', 'machine', 'python', 'intelligence'], icon: Icons.insights, color: AppAccent.orange),
  (words: ['devops', 'cloud', 'docker'], icon: Icons.cloud_outlined, color: AppAccent.cyan),
  (words: ['security', 'cyber'], icon: Icons.shield_outlined, color: AppAccent.red),
  (words: ['soft'], icon: Icons.groups_outlined, color: AppAccent.purple),
  (words: ['marketing', 'business'], icon: Icons.campaign_outlined, color: AppAccent.orange),
  (words: ['quality'], icon: Icons.verified_outlined, color: AppAccent.green),
  (words: ['concept'], icon: Icons.lightbulb_outline, color: AppAccent.amber),
  (words: ['language', 'langue'], icon: Icons.translate, color: AppAccent.cyan),
];

/// Icon and color of a test or skill category (free text from the server), for its round icon.
(IconData, Color) categoryStyle(String? category, {IconData fallback = Icons.quiz_outlined}) {
  final name = (category ?? '').toLowerCase().trim();
  if (name == 'ai') return (Icons.auto_awesome, AppAccent.pink);
  for (final rule in _rules) {
    if (rule.words.any(name.contains)) return (rule.icon, rule.color);
  }
  return (fallback, AppAccent.amber);
}
