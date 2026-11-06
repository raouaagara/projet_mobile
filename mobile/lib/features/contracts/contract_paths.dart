import '../../core/router/app_paths.dart';

/// Pages of module 3. Other modules may use these to link here:
///   context.push(ContractPaths.create(proposalId));   // module 2, after accepting a proposal
///   context.push(ContractPaths.details(contractId));
abstract final class ContractPaths {
  static const home = AppPaths.contracts;
  static const wallet = AppPaths.wallet;
  static const disputes = '${AppPaths.contracts}/disputes';

  /// Client: create the contract of an accepted proposal.
  static String create(int proposalId) => '${AppPaths.contracts}/new/$proposalId';

  static String details(int contractId) => '${AppPaths.contracts}/$contractId';

  /// Freelancer: review and sign.
  static String sign(int contractId) => '${AppPaths.contracts}/$contractId/sign';
}

/// Pages of other modules that this one opens (see docs/WORK_SPLIT.md, "Links between modules").
abstract final class LinkedPaths {
  /// Module 1 – public profile.
  static String profile(int userId) => '${AppPaths.profile}/$userId';

  /// Module 1 – review form about [userId] after a contract.
  static String review({required int userId, int? projectId}) =>
      Uri(path: '${AppPaths.profile}/review', queryParameters: {
        'userId': '$userId',
        if (projectId != null) 'projectId': '$projectId',
      }).toString();

  /// Module 2 – project details.
  static String project(int projectId) => '${AppPaths.projects}/$projectId';

  /// Module 4 – chat with a user.
  static String chatWith(int userId) => '${AppPaths.messages}/new/$userId';
}
