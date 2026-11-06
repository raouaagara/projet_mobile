import '../../core/router/app_paths.dart';

/// Pages of module 6.
abstract final class CommunityPaths {
  static const home = AppPaths.community;

  static const newGroup = '${AppPaths.community}/groups/new';
  static String group(int id) => '${AppPaths.community}/groups/$id';

  static String post(int id) => '${AppPaths.community}/posts/$id';

  static String event(int id) => '${AppPaths.community}/events/$id';
  static String newEvent({int? groupId, int? clubId}) => Uri(
    path: '${AppPaths.community}/events/new',
    queryParameters: {'groupId': ?groupId?.toString(), 'clubId': ?clubId?.toString()},
  ).toString();

  static const newClub = '${AppPaths.community}/clubs/new';
  static String club(int id) => '${AppPaths.community}/clubs/$id';
  static String editClub(int id) => '${AppPaths.community}/clubs/$id/edit';
}

/// Pages of other modules that this one opens.
abstract final class LinkedPaths {
  /// Module 1 – public profile.
  static String profile(int userId) => '${AppPaths.profile}/$userId';
}
