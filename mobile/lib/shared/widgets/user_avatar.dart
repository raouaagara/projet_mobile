import 'package:flutter/material.dart';

import '../../core/models/app_user.dart';
import '../../core/utils/image_utils.dart';

/// Profile picture with an initials fallback.
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.user, this.radius = 20});

  final AppUser? user;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final image = imageFromApi(user?.profilePictureUrl);
    return CircleAvatar(
      radius: radius,
      backgroundImage: image,
      child: image == null
          ? Text(user?.initials ?? '?', style: TextStyle(fontSize: radius * 0.8))
          : null,
    );
  }
}
