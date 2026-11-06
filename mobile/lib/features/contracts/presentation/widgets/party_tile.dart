import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/user_avatar.dart';
import '../../contract_paths.dart';
import '../contract_providers.dart';
import 'module_link.dart';

/// Client or freelancer of a contract; opens their public profile.
class PartyTile extends ConsumerWidget {
  const PartyTile({super.key, required this.userId, required this.role, this.fallbackName, this.trailing});

  final int userId;

  /// "Client" or "Freelancer".
  final String role;
  final String? fallbackName;
  final Widget? trailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(contractUserProvider(userId));
    final name = user.value?.fullName ?? fallbackName ?? (user.isLoading ? '…' : 'User #$userId');
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: UserAvatar(user: user.value, radius: 22),
      title: Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(role),
      trailing: trailing ?? Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.outline),
      onTap: () => openModuleLink(
        context,
        LinkedPaths.profile(userId),
        comingSoon: 'Public profiles arrive with module 1 (profile).',
      ),
    );
  }
}
