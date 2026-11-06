import '../../core/router/app_paths.dart';

/// Pages of module 4. Other modules may use these to link here:
///   context.push(MessagingPaths.chatWith(userId));   // "Message" buttons
abstract final class MessagingPaths {
  static const home = AppPaths.messages;

  /// Pick someone to write to.
  static const compose = '${AppPaths.messages}/compose';

  /// Opens (or creates) the conversation with [userId].
  static String chatWith(int userId) => '${AppPaths.messages}/new/$userId';

  static String conversation(int conversationId, {required int otherUserId}) =>
      '${AppPaths.messages}/$conversationId?with=$otherUserId';

  static const support = AppPaths.support;
  static const newTicket = '${AppPaths.support}/new';

  /// The AI help assistant, before a request.
  static const assistant = '${AppPaths.support}/assistant';
  static String ticket(int ticketId) => '${AppPaths.support}/$ticketId';

  static const availability = AppPaths.availability;
  static const worldClock = AppPaths.worldClock;
}

/// Pages of other modules that this one opens.
abstract final class LinkedPaths {
  /// Module 1 – public profile.
  static String profile(int userId) => '${AppPaths.profile}/$userId';
}
