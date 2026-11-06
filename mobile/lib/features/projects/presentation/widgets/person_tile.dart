import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/user_avatar.dart';
import '../../project_paths.dart';
import '../project_providers.dart';
import 'module_link.dart';

/// A client or freelancer (avatar + name) that opens their public profile.
class PersonTile extends ConsumerWidget {
  const PersonTile({super.key, required this.userId, this.subtitle, this.trailing, this.dense = false});

  final int userId;
  final String? subtitle;
  final Widget? trailing;
  final bool dense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loading = ref.watch(projectUserProvider(userId));
    final user = loading.value;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: dense,
      leading: UserAvatar(user: user, radius: dense ? 18 : 22),
      title: Text(
        user?.fullName ?? (loading.isLoading ? '…' : 'User #$userId'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: subtitle == null && user?.location == null ? null : Text(subtitle ?? user!.location!),
      trailing: trailing,
      onTap: () => openModuleLink(
        context,
        LinkedPaths.profile(userId),
        comingSoon: 'Public profiles arrive with module 1 (profile).',
      ),
    );
  }
}
