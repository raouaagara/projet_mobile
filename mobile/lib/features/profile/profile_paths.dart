import '../../core/router/app_paths.dart';

/// Pages of module 1. Other modules may use these to link here:
///   context.push(ProfilePaths.user(freelancerId));
///   context.push(ProfilePaths.review(userId: freelancerId, projectId: contract.projectId));
abstract final class ProfilePaths {
  static const me = AppPaths.profile;
  static const edit = '${AppPaths.profile}/edit';
  static const skills = '${AppPaths.profile}/skills';
  static const onboarding = '${AppPaths.profile}/onboarding';
  static const leaderboard = '${AppPaths.profile}/leaderboard';
  static const cvAssistant = '${AppPaths.profile}/cv-assistant';

  /// Public profile of any user.
  static String user(int userId) => '${AppPaths.profile}/$userId';

  /// Review form about [userId] (a freelancer when you're a client, and vice versa).
  static String review({required int userId, int? projectId}) =>
      Uri(path: '${AppPaths.profile}/review', queryParameters: {
        'userId': '$userId',
        if (projectId != null) 'projectId': '$projectId',
      }).toString();

  static const skillTests = AppPaths.skillTests;
  static const testResult = '${AppPaths.skillTests}/result';
  static String test(int testId) => '${AppPaths.skillTests}/$testId';
  static String takeTest(int testId) => '${AppPaths.skillTests}/$testId/take';
}
