import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/app_user.dart';
import '../../../core/models/user_role.dart';
import '../../../core/network/api_exception.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/availability_repository.dart';
import '../data/chat_repository.dart';
import '../data/chat_socket.dart';
import '../data/models/availability_models.dart';
import '../data/models/chat_models.dart';
import '../data/models/support_models.dart';
import '../data/support_repository.dart';
import '../data/time_zones.dart';

// ── Real-time connection ───────────────────────────────────────────

/// The chat socket of the logged-in user (null when logged out). Replaced at login/logout.
final chatSocketProvider = Provider<ChatSocket?>((ref) {
  final userId = ref.watch(authControllerProvider.select((auth) => auth.value?.userId));
  if (userId == null) return null;
  final socket = StompChatSocket(userId);
  ref.onDispose(socket.dispose);
  return socket;
});

final socketStatusProvider = NotifierProvider<SocketStatusNotifier, SocketStatus>(SocketStatusNotifier.new);

class SocketStatusNotifier extends Notifier<SocketStatus> {
  @override
  SocketStatus build() {
    final socket = ref.watch(chatSocketProvider);
    if (socket == null) return SocketStatus.disconnected;
    void update() => state = socket.status.value;
    socket.status.addListener(update);
    ref.onDispose(() => socket.status.removeListener(update));
    return socket.status.value;
  }
}

/// Listens to the socket's events for as long as the provider lives.
void _listenToChat(Ref ref, void Function(ChatEvent event) onEvent) {
  final socket = ref.watch(chatSocketProvider);
  final subscription = socket?.events.listen(onEvent);
  ref.onDispose(() => subscription?.cancel());
}

/// The conversation on screen, so its new messages don't count as unread.
final openConversationProvider = NotifierProvider<OpenConversation, int?>(OpenConversation.new);

class OpenConversation extends Notifier<int?> {
  @override
  int? build() => null;

  void set(int? conversationId) => state = conversationId;

  /// Leaving [conversationId]: forget it, unless another one was opened meanwhile.
  void clear(int conversationId) {
    if (ref.mounted && state == conversationId) state = null;
  }
}

// ── Conversations ──────────────────────────────────────────────────

/// The user's conversations, newest first, kept up to date by the socket.
final conversationsProvider = AsyncNotifierProvider<ConversationsController, List<ConversationSummary>>(
  ConversationsController.new,
);

class ConversationsController extends AsyncNotifier<List<ConversationSummary>> {
  @override
  Future<List<ConversationSummary>> build() async {
    final userId = ref.watch(authControllerProvider.select((auth) => auth.value?.userId));
    if (userId == null) return [];
    _listenToChat(ref, (event) => _onEvent(event, userId));
    return ref.watch(chatRepositoryProvider).fetchConversations(userId);
  }

  void _onEvent(ChatEvent event, int userId) {
    final conversations = state.value;
    if (conversations == null || event is! MessageReceived) return;
    final message = event.message;
    final index = conversations.indexWhere((c) => c.id == message.conversationId);
    if (index == -1) {
      ref.invalidateSelf(); // a new conversation: load it
      return;
    }
    final isOpen = ref.read(openConversationProvider) == message.conversationId;
    final unreadForMe = message.recipientId == userId && !isOpen;
    final current = conversations[index];
    final updated = current.copyWith(
      lastMessage: message.content,
      lastSenderId: message.senderId,
      lastMessageTime: message.timestamp ?? DateTime.now(),
      unreadCount: current.unreadCount + (unreadForMe ? 1 : 0),
    );
    state = AsyncData([updated, ...conversations.where((c) => c.id != message.conversationId)]);
  }

  void markReadLocally(int conversationId) {
    final conversations = state.value;
    if (conversations == null) return;
    state = AsyncData([for (final c in conversations) c.id == conversationId ? c.copyWith(unreadCount: 0) : c]);
  }
}

final unreadMessagesProvider = Provider<int>(
  (ref) => ref.watch(conversationsProvider).value?.fold<int>(0, (sum, c) => sum + c.unreadCount) ?? 0,
);

// ── One conversation ───────────────────────────────────────────────

/// Messages of a conversation, oldest first, kept up to date by the socket.
final conversationProvider = AsyncNotifierProvider.autoDispose.family<ConversationController, List<ChatMessage>, int>(
  ConversationController.new,
);

class ConversationController extends AsyncNotifier<List<ChatMessage>> {
  ConversationController(this.conversationId);

  final int conversationId;

  /// (message id, emoji) reacted by this user during this session, to toggle reactions.
  final _myReactions = <(int, String)>{};

  ChatRepository get _repository => ref.read(chatRepositoryProvider);

  /// The logged-in user, known once [build] has run.
  late int _userId;

  /// Messages the server refused, for the screen to show why.
  final rejections = StreamController<MessageRejected>.broadcast();

  @override
  Future<List<ChatMessage>> build() async {
    ref.onDispose(rejections.close);
    _listenToChat(ref, _onEvent);
    final session = ref.watch(authControllerProvider.future);
    final repository = ref.watch(chatRepositoryProvider);
    _userId = (await session)!.userId;
    return repository.fetchMessages(conversationId);
  }

  void _onEvent(ChatEvent event) {
    final messages = state.value;
    if (messages == null) return;
    switch (event) {
      case MessageReceived(:final message) when message.conversationId == conversationId:
        if (messages.any((m) => m.id == message.id)) return;
        state = AsyncData([...messages, message]);
        if (message.recipientId == _userId) markRead();
      case MessageUpdated(:final message) when message.conversationId == conversationId:
        state = AsyncData([for (final m in messages) m.id == message.id ? message : m]);
      case MessageDeleted(:final messageId, conversationId: final id) when id == conversationId:
        state = AsyncData(messages.where((m) => m.id != messageId).toList());
      case MessagesRead(conversationId: final id, :final readerId) when id == conversationId && readerId != _userId:
        state = AsyncData([for (final m in messages) m.senderId == _userId ? m.copyWith(seen: true) : m]);
      case MessageRejected() when event.conversationId == conversationId:
        if (!rejections.isClosed) rejections.add(event);
      default:
        break;
    }
  }

  /// Tells the server the user read the conversation (and the other person, through the socket).
  Future<void> markRead() async {
    final repository = _repository;
    final conversations = ref.read(conversationsProvider.notifier);
    try {
      await future; // the user id is known after the first load
      conversations.markReadLocally(conversationId);
      await repository.markRead(conversationId, _userId);
    } on ApiException catch (e) {
      debugPrint('markRead: ${e.message}');
    }
  }

  /// Throws [ApiException] if the message is refused or the chat is offline.
  /// The message appears when the server sends it back.
  Future<void> send(String text, {required int recipientId}) async {
    final socket = ref.read(chatSocketProvider);
    if (socket == null || socket.status.value != SocketStatus.connected) {
      throw const ApiException('Not connected to the chat. Reconnecting…');
    }
    final refusal = await _repository.moderate(text);
    if (refusal != null) throw ApiException(refusal);
    socket.send(
      ChatMessage(conversationId: conversationId, senderId: _userId, recipientId: recipientId, content: text),
    );
  }

  Future<void> sendFile({
    required List<int> bytes,
    required String fileName,
    required int recipientId,
    String caption = '',
  }) => _repository.upload(
    bytes: bytes,
    fileName: fileName,
    conversationId: conversationId,
    senderId: _userId,
    recipientId: recipientId,
    caption: caption,
  );

  Future<void> edit(ChatMessage message, String text) async {
    final updated = await _repository.edit(message.id!, text);
    _replace(updated);
  }

  Future<void> delete(ChatMessage message) async {
    await _repository.delete(message.id!);
    state = AsyncData([...?state.value?.where((m) => m.id != message.id)]);
  }

  /// Adds the user's [emoji], or removes it if they already reacted with it.
  Future<void> react(ChatMessage message, String emoji) async {
    final key = (message.id!, emoji);
    final reactions = {...message.reactions};
    if (_myReactions.remove(key)) {
      reactions[emoji] = (reactions[emoji] ?? 1) - 1;
      if (reactions[emoji]! <= 0) reactions.remove(emoji);
    } else {
      _myReactions.add(key);
      reactions[emoji] = (reactions[emoji] ?? 0) + 1;
    }
    _replace(await _repository.setReactions(message.id!, reactions));
  }

  void _replace(ChatMessage message) =>
      state = AsyncData([for (final m in state.value ?? <ChatMessage>[]) m.id == message.id ? message : m]);
}

// ── People ─────────────────────────────────────────────────────────

final chatUserProvider = FutureProvider.family<AppUser, int>(
  (ref, id) => ref.watch(authRepositoryProvider).fetchUser(id),
);

/// Everyone the user can start a conversation with: clients and freelancers, not admins, not themselves.
final contactableUsersProvider = FutureProvider.autoDispose<List<AppUser>>((ref) async {
  final me = ref.watch(authControllerProvider).value?.userId;
  final users = await ref.watch(chatRepositoryProvider).fetchUsers();
  return users.where((u) => u.id != me && (u.role == UserRole.client || u.role == UserRole.freelancer)).toList()
    ..sort((a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));
});

// ── Support ────────────────────────────────────────────────────────

final myTicketsProvider = FutureProvider<List<Ticket>>((ref) async {
  final session = await ref.watch(authControllerProvider.future);
  if (session == null) return [];
  return ref.watch(supportRepositoryProvider).fetchMine(session.userId);
});

final ticketProvider = FutureProvider.autoDispose.family<Ticket, int>(
  (ref, id) => ref.watch(supportRepositoryProvider).fetch(id),
);

final ticketRepliesProvider = FutureProvider.autoDispose.family<List<TicketReply>, int>(
  (ref, id) => ref.watch(supportRepositoryProvider).fetchReplies(id),
);

// ── Availability ───────────────────────────────────────────────────

/// The logged-in freelancer's availability, created (with the phone's time zone) the first time.
final myAvailabilityProvider = AsyncNotifierProvider.autoDispose<MyAvailabilityController, AvailabilityProfile>(
  MyAvailabilityController.new,
);

class MyAvailabilityController extends AsyncNotifier<AvailabilityProfile> {
  AvailabilityRepository get _repository => ref.read(availabilityRepositoryProvider);

  @override
  Future<AvailabilityProfile> build() async {
    final session = await ref.watch(authControllerProvider.future);
    final guess = TimeZones.guessForDevice();
    final repository = ref.watch(availabilityRepositoryProvider);
    var profile = await repository.fetchOrCreate(session!.userId, guess.name);
    if (profile.timezoneOffsetMinutes == null) {
      // New profile: save the offset too, for apps that don't know the zone name.
      profile = await repository.update(profile.copyWith(timezoneOffsetMinutes: profile.utcOffset.inMinutes));
    }
    unawaited(repository.heartbeat(session.userId).catchError((_) {}));
    return profile;
  }

  Future<void> save(AvailabilityProfile profile) async {
    state = AsyncData(await _repository.update(profile));
    ref.invalidate(worldViewProvider);
  }
}

final mySlotsProvider = AsyncNotifierProvider.autoDispose<MySlotsController, List<AvailabilitySlot>>(
  MySlotsController.new,
);

class MySlotsController extends AsyncNotifier<List<AvailabilitySlot>> {
  AvailabilityRepository get _repository => ref.read(availabilityRepositoryProvider);

  @override
  Future<List<AvailabilitySlot>> build() async {
    final profile = await ref.watch(myAvailabilityProvider.future);
    return ref.watch(availabilityRepositoryProvider).fetchSlots(profile.id);
  }

  Future<void> add(AvailabilitySlot slot) async {
    final profile = await ref.read(myAvailabilityProvider.future);
    final saved = await _repository.addSlot(profile.id, slot);
    final slots = [...?state.value, saved]
      ..sort(
        (a, b) => a.dayOfWeek.index != b.dayOfWeek.index
            ? a.dayOfWeek.index.compareTo(b.dayOfWeek.index)
            : a.startTime.compareTo(b.startTime),
      );
    state = AsyncData(slots);
  }

  Future<void> remove(AvailabilitySlot slot) async {
    await _repository.deleteSlot(slot.id!);
    state = AsyncData([...?state.value?.where((s) => s.id != slot.id)]);
  }
}

/// Every freelancer's availability (client's world clock, chat header).
final worldViewProvider = FutureProvider.autoDispose<List<AvailabilityProfile>>(
  (ref) => ref.watch(availabilityRepositoryProvider).fetchWorldView(),
);

/// A user's availability, if they set one (freelancers).
final availabilityOfProvider = Provider.autoDispose.family<AvailabilityProfile?, int>((ref, userId) {
  return ref.watch(worldViewProvider).value?.where((p) => p.userId == userId).firstOrNull;
});

final slotsOfUserProvider = FutureProvider.autoDispose.family<List<AvailabilitySlot>, int>(
  (ref, userId) => ref.watch(availabilityRepositoryProvider).fetchSlotsOfUser(userId),
);
