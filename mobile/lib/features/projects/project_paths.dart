import '../../core/router/app_paths.dart';

/// Pages of module 2. Other modules may use these to link here:
///   context.push(ProjectPaths.details(projectId));
abstract final class ProjectPaths {
  static const home = AppPaths.projects;
  static const create = '${AppPaths.projects}/new';
  static const notifications = '${AppPaths.projects}/notifications';

  static String details(int projectId) => '${AppPaths.projects}/$projectId';
  static String edit(int projectId) => '${AppPaths.projects}/$projectId/edit';

  /// Client: proposals received on a project.
  static String proposals(int projectId) => '${AppPaths.projects}/$projectId/proposals';

  /// Freelancer: send a proposal.
  static String propose(int projectId) => '${AppPaths.projects}/$projectId/propose';
}

/// Pages of other modules that this one opens (see docs/WORK_SPLIT.md, "Links between modules").
abstract final class LinkedPaths {
  /// Module 1 – public profile.
  static String profile(int userId) => '${AppPaths.profile}/$userId';

  /// Module 1 – my skills (the AI match score is based on them).
  static const skills = '${AppPaths.profile}/skills';

  /// Module 3 – contract creation from an accepted proposal.
  static String newContract(int proposalId) => '${AppPaths.contracts}/new/$proposalId';

  /// Module 4 – chat with a user.
  static String chatWith(int userId) => '${AppPaths.messages}/new/$userId';
}
