import 'dart:async';

import 'package:catchopp_mobile/core/models/app_user.dart';
import 'package:catchopp_mobile/core/models/user_role.dart';
import 'package:catchopp_mobile/core/network/api_exception.dart';
import 'package:catchopp_mobile/features/auth/domain/auth_session.dart';
import 'package:catchopp_mobile/features/auth/presentation/auth_controller.dart';
import 'package:catchopp_mobile/features/messaging/data/availability_repository.dart';
import 'package:catchopp_mobile/features/messaging/data/chat_repository.dart';
import 'package:catchopp_mobile/features/messaging/data/chat_socket.dart';
import 'package:catchopp_mobile/features/messaging/data/models/availability_models.dart';
import 'package:catchopp_mobile/features/messaging/data/models/chat_models.dart';
import 'package:catchopp_mobile/features/messaging/data/models/support_models.dart';
import 'package:catchopp_mobile/features/messaging/data/support_repository.dart';
import 'package:catchopp_mobile/features/messaging/messaging_routes.dart';
import 'package:catchopp_mobile/features/messaging/presentation/messaging_providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const me = 2; // a client
const sara = 7; // a freelancer

AppUser user(int id) => AppUser(
      id: id,
      firstName: id == sara ? 'Sara' : (id == me ? 'Karim' : 'User$id'),
      lastName: 'B',
      email: 'u$id@mail.com',
      role: id == sara ? UserRole.freelancer : UserRole.client,
    );

ChatMessage message(int id, {int from = sara, String text = 'Hello', DateTime? at, bool? seen}) => ChatMessage(
      id: id,
      conversationId: 1,
      senderId: from,
      recipientId: from == me ? sara : me,
      content: text,
      timestamp: at ?? DateTime(2026, 9, 26, 10, id),
      seen: seen,
    );

class FakeChatSocket implements ChatSocket {
  final _events = StreamController<ChatEvent>.broadcast();
  final _status = ValueNotifier(SocketStatus.connected);
  final sent = <ChatMessage>[];

  @override
  Stream<ChatEvent> get events => _events.stream;

  @override
  ValueListenable<SocketStatus> get status => _status;

  @override
  void send(ChatMessage message) => sent.add(message);

  void emit(ChatEvent event) => _events.add(event);

  @override
  void dispose() {}
}

class FakeChatRepository extends ChatRepository {
  FakeChatRepository({List<ConversationSummary>? conversations, List<ChatMessage>? messages, this.refusal})
      : conversations = conversations ?? [],
        messages = messages ?? [],
        super(Dio());

  final List<ConversationSummary> conversations;
  final List<ChatMessage> messages;
  String? refusal;
  final readConversations = <int>[];

  @override
  Future<List<ConversationSummary>> fetchConversations(int userId) async => [...conversations];

  @override
  Future<List<ChatMessage>> fetchMessages(int conversationId) async => [...messages];

  @override
  Future<String?> moderate(String text) async => refusal;

  int suggestCalls = 0;

  @override
  Future<List<String>> suggestReplies(int conversationId, int userId) async {
    suggestCalls++;
    return ['Thanks, I will check them today', 'Can you send the source files?', 'Shall we talk at 3pm?'];
  }

  @override
  Future<void> markRead(int conversationId, int userId) async => readConversations.add(conversationId);

  @override
  Future<int> openConversation(int me, int other) async => 1;

  String? translatedTo;

  @override
  Future<String> translate(int messageId, String language) async {
    translatedTo = language;
    return 'I sent you the mockups (translated)';
  }

  @override
  Future<ChatCatchUp> catchUp(int conversationId, int userId) async => const ChatCatchUp(
        summary: ['The mockups are done; the payment screen is next.'],
        decisions: [r'$500, delivered by Friday'],
        myTodos: ['Send feedback on the mockups'],
        theirTodos: ['Build the payment screen'],
      );

  @override
  Future<List<AppUser>> fetchUsers() async => [user(me), user(sara), user(9)];
}

class FakeSupportRepository extends SupportRepository {
  FakeSupportRepository() : super(Dio());

  final questions = <String>[];

  /// The assistant answers how-to questions, and hands money problems to the team.
  @override
  Future<AssistantAnswer> ask(String question, {List<AssistantTurn> history = const []}) async {
    questions.add(question);
    if (question.contains('wallet is empty')) {
      return const AssistantAnswer(
        answer: 'The team will check your payment.',
        needsTicket: true,
        ticketTitle: 'Payment missing after approval',
        ticketDescription: 'The client approved contract #1 but my wallet is empty.',
      );
    }
    return const AssistantAnswer(answer: 'Open the contract and tap Approve & pay.');
  }

  final tickets = <Ticket>[];
  final replies = <TicketReply>[];
  String enhanced = '';

  @override
  Future<List<Ticket>> fetchMine(int userId) async => [...tickets];

  @override
  Future<Ticket> fetch(int id) async => tickets.firstWhere((t) => t.id == id);

  @override
  Future<Ticket> create({
    required int userId,
    required String userName,
    required String userEmail,
    required String title,
    required String description,
    TicketCategory? category,
    TicketPriority? priority,
  }) async {
    final ticket = Ticket(
      id: tickets.length + 1,
      title: title,
      description: description,
      userId: userId,
      category: category ?? TicketCategory.paymentIssue,
      priority: TicketPriority.medium,
      createdAt: DateTime.now(),
      slaDeadline: DateTime.now().add(const Duration(hours: 48)),
    );
    tickets.add(ticket);
    return ticket;
  }

  @override
  Future<List<TicketReply>> fetchReplies(int ticketId) async => [...replies];

  @override
  Future<TicketReply> reply(int ticketId, {required int userId, required String userName, required String message}) async {
    final reply = TicketReply(id: replies.length + 1, message: message, responderId: userId, responderName: userName);
    replies.add(reply);
    return reply;
  }

  @override
  /// Like the server without GEMINI_API_KEY when [enhanced] is empty.
  Future<String> enhance({required String title, required String description}) async {
    if (enhanced.isEmpty) {
      throw const ApiException("AI isn't set up on the server yet (GEMINI_API_KEY is missing).", statusCode: 503);
    }
    return enhanced;
  }
}

class FakeAvailabilityRepository extends AvailabilityRepository {
  FakeAvailabilityRepository({List<AvailabilityProfile>? world, List<AvailabilitySlot>? slots})
      : world = world ?? [],
        slots = slots ?? [],
        super(Dio());

  final List<AvailabilityProfile> world;
  final List<AvailabilitySlot> slots;
  AvailabilityProfile? saved;

  @override
  Future<AvailabilityProfile> fetchOrCreate(int userId, String timezone) async =>
      saved ?? AvailabilityProfile(id: 1, userId: userId, timezone: 'Africa/Tunis', timezoneOffsetMinutes: 60);

  @override
  Future<AvailabilityProfile> update(AvailabilityProfile profile) async => saved = profile;

  @override
  Future<void> heartbeat(int userId) async {}

  @override
  Future<List<AvailabilitySlot>> fetchSlots(int profileId) async => [...slots];

  @override
  Future<List<AvailabilitySlot>> fetchSlotsOfUser(int userId) async => [...slots];

  @override
  Future<AvailabilitySlot> addSlot(int profileId, AvailabilitySlot slot) async {
    final saved = AvailabilitySlot(id: slots.length + 1, dayOfWeek: slot.dayOfWeek, startTime: slot.startTime, endTime: slot.endTime);
    slots.add(saved);
    return saved;
  }

  @override
  Future<void> deleteSlot(int slotId) async => slots.removeWhere((s) => s.id == slotId);

  @override
  Future<List<AvailabilityProfile>> fetchWorldView() async => [...world];
}

class _LoggedIn extends AuthController {
  _LoggedIn(this.userId, this.role);

  final int userId;
  final UserRole role;

  @override
  Future<AuthSession?> build() async =>
      AuthSession(token: 't', userId: userId, email: 'me@mail.com', role: role, expiresAt: DateTime(2100));
}

/// Module 4's pages with fakes. Returns the fake socket to push live events.
Future<FakeChatSocket> pumpMessagingApp(
  WidgetTester tester, {
  String location = '/messages',
  int userId = me,
  UserRole role = UserRole.client,
  FakeChatRepository? chat,
  FakeSupportRepository? support,
  FakeAvailabilityRepository? availability,
}) async {
  final socket = FakeChatSocket();
  final router = GoRouter(initialLocation: location, routes: [messagesTab, ...messagingRoutes]);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(() => _LoggedIn(userId, role)),
      currentUserProvider.overrideWith((ref) async => user(userId)),
      chatSocketProvider.overrideWith((ref) => socket),
      chatRepositoryProvider.overrideWithValue(chat ?? FakeChatRepository()),
      supportRepositoryProvider.overrideWithValue(support ?? FakeSupportRepository()),
      availabilityRepositoryProvider.overrideWithValue(availability ?? FakeAvailabilityRepository()),
      chatUserProvider.overrideWith((ref, id) async => user(id)),
    ],
    child: MaterialApp.router(routerConfig: router),
  ));
  await tester.pumpAndSettle();
  return socket;
}

/// A refusal like the backend's moderation.
const insult = ApiException('Insults are not allowed. Keep it professional.', statusCode: 422);

/// Scrolls the page until [finder] is on screen, then taps it.
Future<void> scrollAndTap(WidgetTester tester, Finder finder) async {
  FocusManager.instance.primaryFocus?.unfocus(); // a focused field scrolls itself back into view
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(finder, 300, scrollable: find.byType(Scrollable).first);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
