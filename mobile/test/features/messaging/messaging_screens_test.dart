import 'package:catchopp_mobile/core/models/user_role.dart';
import 'package:catchopp_mobile/features/messaging/data/chat_socket.dart';
import 'package:catchopp_mobile/features/messaging/data/models/availability_models.dart';
import 'package:catchopp_mobile/features/messaging/data/models/chat_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  group('conversations', () {
    testWidgets('list with previews and unread counts, updated live', (tester) async {
      final chat = FakeChatRepository(
        conversations: [
          ConversationSummary(
            id: 1,
            otherUserId: sara,
            lastMessage: 'See you tomorrow',
            lastSenderId: me,
            lastMessageTime: DateTime.now(),
          ),
          ConversationSummary(
            id: 2,
            otherUserId: 9,
            lastMessage: ' [FILE:http://localhost:8085/uploads/17_brief.pdf]',
            lastSenderId: 9,
            lastMessageTime: DateTime.now().subtract(const Duration(days: 3)),
            unreadCount: 2,
          ),
        ],
      );
      final socket = await pumpMessagingApp(tester, chat: chat);

      expect(find.text('Sara B'), findsOneWidget);
      expect(find.text('You: See you tomorrow'), findsOneWidget);
      expect(find.text('📎 brief.pdf'), findsOneWidget);
      expect(find.text('2'), findsOneWidget); // unread badge

      // A new message from Sara arrives through the socket.
      socket.emit(MessageReceived(message(50, text: 'The APK is ready')));
      await tester.pumpAndSettle();
      expect(find.text('The APK is ready'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      final tiles = tester.widgetList<ListTile>(find.byType(ListTile)).toList();
      expect((tiles.first.title as Text).data, 'Sara B'); // moved to the top
    });
  });

  group('chat', () {
    Future<FakeChatSocket> openChat(WidgetTester tester, FakeChatRepository chat) =>
        pumpMessagingApp(tester, chat: chat, location: '/messages/1?with=$sara');

    testWidgets('shows the conversation, marks it read, sends through the socket', (tester) async {
      final chat = FakeChatRepository(
        messages: [
          message(1, text: 'Hi Karim, I sent the mockups', at: DateTime(2026, 9, 25, 9)),
          message(2, from: me, text: 'Great, thanks!', at: DateTime(2026, 9, 26, 10), seen: false),
        ],
      );
      final socket = await openChat(tester, chat);

      expect(find.text('Hi Karim, I sent the mockups'), findsOneWidget);
      expect(find.byIcon(Icons.done), findsOneWidget); // sent, not seen yet
      expect(chat.readConversations, [1]);

      await tester.enterText(find.byType(TextField), 'Can we talk at 3pm?');
      await tester.tap(find.byTooltip('Send'));
      await tester.pumpAndSettle();
      expect(socket.sent.single.content, 'Can we talk at 3pm?');
      expect(socket.sent.single.recipientId, sara);
      expect(find.widgetWithText(TextField, 'Can we talk at 3pm?'), findsNothing); // cleared

      // The server echoes it; Sara reads the conversation.
      socket.emit(MessageReceived(message(3, from: me, text: 'Can we talk at 3pm?', at: DateTime.now(), seen: false)));
      socket.emit(const MessagesRead(conversationId: 1, readerId: sara));
      await tester.pumpAndSettle();
      expect(find.text('Can we talk at 3pm?'), findsOneWidget);
      expect(find.byIcon(Icons.done), findsNothing);
      expect(find.byIcon(Icons.done_all), findsNWidgets(2)); // both read by Sara
    });

    testWidgets('AI suggests replies; picking one fills the box without sending', (tester) async {
      final chat = FakeChatRepository(messages: [message(1, text: 'Hi Karim, I sent the mockups')]);
      final socket = await openChat(tester, chat);

      await tester.tap(find.byTooltip('Suggest replies'));
      await tester.pumpAndSettle();
      expect(chat.suggestCalls, 1);
      expect(find.text('Can you send the source files?'), findsOneWidget);

      await tester.tap(find.text('Can you send the source files?'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, 'Can you send the source files?'), findsOneWidget);
      expect(find.text('Shall we talk at 3pm?'), findsNothing); // the chips are gone
      expect(socket.sent, isEmpty); // not sent until I tap Send

      await tester.tap(find.byTooltip('Send'));
      await tester.pumpAndSettle();
      expect(socket.sent.single.content, 'Can you send the source files?');
    });

    testWidgets('translates a message and catches up on the conversation', (tester) async {
      final chat = FakeChatRepository(messages: [
        message(1, text: 'Je vous ai envoyé les maquettes'),
        message(2, from: me, text: 'Merci'),
        message(3, text: 'Le paiement ensuite ?'),
      ]);
      await openChat(tester, chat);

      await tester.longPress(find.text('Je vous ai envoyé les maquettes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Translate'));
      await tester.pumpAndSettle();
      expect(chat.translatedTo, isNotNull); // the phone's language
      expect(find.text('I sent you the mockups (translated)'), findsOneWidget);
      expect(find.text('Je vous ai envoyé les maquettes'), findsOneWidget); // the original stays

      await tester.tap(find.byTooltip('Catch me up'));
      await tester.pumpAndSettle();
      expect(find.text('The mockups are done; the payment screen is next.'), findsOneWidget);
      expect(find.text(r'$500, delivered by Friday'), findsOneWidget);
      expect(find.text('For you'), findsOneWidget);
      expect(find.text('Build the payment screen'), findsOneWidget);
    });

    testWidgets('a refused message is not sent and the reason is shown', (tester) async {
      final chat = FakeChatRepository(messages: [message(1)], refusal: insult.message);
      final socket = await openChat(tester, chat);

      await tester.enterText(find.byType(TextField), 'you are an idiot');
      await tester.tap(find.byTooltip('Send'));
      await tester.pumpAndSettle();

      expect(socket.sent, isEmpty);
      expect(find.text(insult.message), findsOneWidget);
      expect(find.widgetWithText(TextField, 'you are an idiot'), findsOneWidget); // kept to fix it
    });

    testWidgets('a message the server refuses later comes back into the field', (tester) async {
      final chat = FakeChatRepository(messages: [message(1)]);
      final socket = await openChat(tester, chat);

      socket.emit(const MessageRejected(conversationId: 1, reason: 'Threats are not allowed.', content: 'or else'));
      await tester.pumpAndSettle();
      expect(find.text('Not sent: Threats are not allowed.'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'or else'), findsOneWidget);
    });

    testWidgets('edits and deletes from other devices show up live', (tester) async {
      final chat = FakeChatRepository(
        messages: [
          message(1, text: 'Draft v1'),
          message(2, text: 'Oops'),
        ],
      );
      final socket = await openChat(tester, chat);

      socket.emit(MessageUpdated(message(1, text: 'Draft v2')));
      socket.emit(const MessageDeleted(messageId: 2, conversationId: 1));
      await tester.pumpAndSettle();
      expect(find.text('Draft v2'), findsOneWidget);
      expect(find.text('Oops'), findsNothing);
    });
  });

  testWidgets('support assistant: answers, then writes the request when the team must act', (tester) async {
    final support = FakeSupportRepository();
    await pumpMessagingApp(tester, support: support, location: '/support');

    await tester.tap(find.text('Ask the assistant'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('How do I get paid for a contract?')); // a starter question
    await tester.pumpAndSettle();
    expect(find.text('Open the contract and tap Approve & pay.'), findsOneWidget);
    expect(find.text('Send it to the support team'), findsNothing);

    await tester.enterText(find.byType(TextField), 'The client approved but my wallet is empty');
    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();
    expect(support.questions.length, 2);
    await tester.tap(find.text('Send it to the support team'));
    await tester.pumpAndSettle();

    // The request form, already written by the assistant.
    expect(find.widgetWithText(TextFormField, 'Payment missing after approval'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'The client approved contract #1 but my wallet is empty.'), findsOneWidget);
  });

  testWidgets('support: send a request, then follow it', (tester) async {
    final support = FakeSupportRepository();
    await pumpMessagingApp(tester, support: support, location: '/support');

    expect(find.textContaining('No request yet'), findsOneWidget);
    await tester.tap(find.text('New request'));
    await tester.pumpAndSettle();

    await scrollAndTap(tester, find.text('Send'));
    await tester.scrollUntilVisible(
      find.text('At least 5 characters'),
      -300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('At least 5 characters'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'e.g. Payment not received'), 'Payment not received');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Steps, contract or project number, screenshots described…'),
      'The client approved contract #1 but my wallet is empty.',
    );
    await scrollAndTap(tester, find.text('Improve with AI'));
    expect(find.textContaining("isn't set up on the server"), findsOneWidget); // no key: the server says why
    tester.state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger)).hideCurrentSnackBar(); // it covers "Send"
    await tester.pumpAndSettle();

    await scrollAndTap(tester, find.text('Send'));

    expect(support.tickets.single.title, 'Payment not received');
    expect(find.text('Request #1'), findsOneWidget);
    expect(find.textContaining('The support team will answer here'), findsOneWidget);

    tester.state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger)).hideCurrentSnackBar();
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Add a message'), 'Contract #1, 1100 USD');
    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();
    expect(support.replies.single.message, 'Contract #1, 1100 USD');
    expect(find.text('Contract #1, 1100 USD'), findsOneWidget);
  });

  testWidgets('availability: status and working hours', (tester) async {
    final availability = FakeAvailabilityRepository();
    await pumpMessagingApp(
      tester,
      availability: availability,
      location: '/availability',
      userId: sara,
      role: UserRole.freelancer,
    );

    expect(find.textContaining('Tunis'), findsWidgets);
    await tester.tap(find.text('Do not disturb'));
    await tester.pumpAndSettle();
    expect(availability.saved!.status, AvailabilityStatus.doNotDisturb);

    await scrollAndTap(tester, find.text('Add')); // working hours, below the status and time zone
    await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Add')));
    await tester.pumpAndSettle();
    expect(availability.slots.map((s) => s.dayOfWeek), [
      Weekday.monday,
      Weekday.tuesday,
      Weekday.wednesday,
      Weekday.thursday,
      Weekday.friday,
    ]);
    expect(find.text('09:00 – 17:00'), findsNWidgets(5));
  });

  testWidgets("world clock: freelancers' local time and status", (tester) async {
    final availability = FakeAvailabilityRepository(
      world: [
        const AvailabilityProfile(
          id: 1,
          userId: sara,
          timezone: 'America/New_York',
          timezoneOffsetMinutes: -300,
          status: AvailabilityStatus.online,
        ),
      ],
    );
    await pumpMessagingApp(tester, availability: availability, location: '/world-clock');

    expect(find.text('Sara B'), findsOneWidget);
    expect(find.text('Online'), findsOneWidget);
    expect(find.textContaining('New York'), findsOneWidget);
    expect(find.byTooltip('Message'), findsOneWidget);
  });
}
