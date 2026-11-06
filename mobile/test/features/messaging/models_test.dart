import 'package:catchopp_mobile/features/messaging/data/models/availability_models.dart';
import 'package:catchopp_mobile/features/messaging/data/models/chat_models.dart';
import 'package:catchopp_mobile/features/messaging/data/models/support_models.dart';
import 'package:catchopp_mobile/features/messaging/data/time_zones.dart';
import 'package:catchopp_mobile/features/messaging/presentation/format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatMessage', () {
    test('reads the backend JSON and the attachment marker', () {
      final m = ChatMessage.fromJson(const {
        'id': 2,
        'conversationId': 1,
        'senderId': 2,
        'recipientId': 1,
        'content': 'Here is the logo [FILE:http://localhost:8085/uploads/1790429201698_tiny_test.png]',
        'timestamp': '2026-09-26T14:26:41.698',
        'reactions': null,
        'seen': false,
      });
      expect(m.text, 'Here is the logo');
      expect(m.attachmentUrl, 'http://localhost:8085/uploads/1790429201698_tiny_test.png');
      expect(m.isImage, isTrue);
      expect(m.attachmentName, 'tiny_test.png');
      expect(m.seen, isFalse);
      expect(m.timestamp, DateTime(2026, 9, 26, 14, 26, 41, 698));
    });

    test('old attachment links (port 8086) go through the gateway', () {
      final m = ChatMessage(conversationId: 1, senderId: 1, recipientId: 2, content: ' [FILE:http://localhost:8086/uploads/1_cv.pdf]');
      expect(m.attachmentUrl, 'http://localhost:8085/uploads/1_cv.pdf');
      expect(m.isImage, isFalse);
      expect(m.text, isEmpty);
      expect(gatewayUrl('https://cdn.example.com/a.png'), 'https://cdn.example.com/a.png');
    });

    test('reactions: JSON object, double-encoded, or junk', () {
      ChatMessage withReactions(String? raw) =>
          ChatMessage(conversationId: 1, senderId: 1, recipientId: 2, content: 'x', reactionsJson: raw);
      expect(withReactions('{"👍": 2, "❤️": 1}').reactions, {'👍': 2, '❤️': 1});
      expect(withReactions(r'"{\"👍\": 3}"').reactions, {'👍': 3});
      expect(withReactions('{"😂": 0}').reactions, isEmpty);
      expect(withReactions('not json').reactions, isEmpty);
      expect(withReactions(null).reactions, isEmpty);
    });

    test('only what the server needs is sent', () {
      final json = const ChatMessage(conversationId: 1, senderId: 2, recipientId: 7, content: 'Hi').toJson();
      expect(json, {'conversationId': 1, 'senderId': 2, 'recipientId': 7, 'content': 'Hi'});
    });
  });

  test('ConversationSummary preview', () {
    final summary = ConversationSummary.fromJson(const {
      'id': 1,
      'participant1Id': 2,
      'participant2Id': 1,
      'otherUserId': 1,
      'lastMessage': ' [FILE:http://localhost:8085/uploads/17904_brief.pdf]',
      'lastSenderId': 2,
      'lastMessageTime': '2026-09-26T14:26:41',
      'unreadCount': 3,
    });
    expect(summary.preview, '📎 brief.pdf');
    expect(summary.unreadCount, 3);
    expect(const ConversationSummary(id: 2, otherUserId: 3).preview, 'No message yet');
  });

  test('Ticket and reply', () {
    final ticket = Ticket.fromJson(const {
      'id': 1,
      'userId': 1,
      'title': 'Payment not received',
      'description': 'The client approved my work.',
      'status': 'PENDING_USER',
      'priority': 'MEDIUM',
      'category': 'PAYMENT_ISSUE',
      'department': 'Finance Department',
      'escalated': false,
      'slaDeadline': '2026-09-28T14:26:54.859584',
      'aiSummary': '',
    });
    expect(ticket.status, TicketStatus.pendingUser);
    expect(ticket.category, TicketCategory.paymentIssue);
    expect(ticket.slaDeadline!.day, 28);
    expect(Ticket.fromJson(const {'id': 2, 'status': 'NEW'}).status, TicketStatus.unknown);

    final reply = TicketReply.fromJson(const {'id': 1, 'message': 'We are on it', 'staff': true, 'responderName': 'Amira'});
    expect(reply.staff, isTrue);
    expect(TicketReply.fromJson(const {'id': 2, 'message': 'ok', 'isStaff': true}).staff, isTrue);
    expect(TicketReply.fromJson(const {'id': 3, 'message': 'ok'}).staff, isFalse);
  });

  group('availability', () {
    test('profile and world-view entry', () {
      final profile = AvailabilityProfile.fromJson(const {
        'id': 1,
        'userId': 1,
        'timezone': 'Africa/Tunis',
        'timezoneOffsetMinutes': 60,
        'status': 'AVAILABLE',
        'customStatusMessage': '',
        'lastSeenAt': '2026-09-26T13:27:04.389760Z',
      });
      expect(profile.status, AvailabilityStatus.available);
      expect(profile.lastSeenAt, DateTime.utc(2026, 9, 26, 13, 27, 4, 389, 760));
      expect(profile.statusText, 'Available');

      final entry = AvailabilityProfile.fromJson(const {
        'profileId': 4,
        'userId': 9,
        'timezone': 'Somewhere/Unknown',
        'timezoneOffsetMinutes': -180,
        'status': 'CUSTOM',
        'customStatusMessage': 'Back on Monday',
        'lastSeenAt': '',
      });
      expect(entry.id, 4);
      expect(entry.lastSeenAt, isNull);
      expect(entry.statusText, 'Back on Monday');
      expect(entry.utcOffset, const Duration(hours: -3)); // unknown zone: saved offset
      expect(entry.localTime(DateTime.utc(2026, 1, 1, 12)).hour, 9);
    });

    test('slots use HH:mm', () {
      final slot = AvailabilitySlot.fromJson(const {'id': 1, 'dayOfWeek': 'MONDAY', 'startTime': '09:00:00', 'endTime': '17:30:00'});
      expect(slot.label, '09:00 – 17:30');
      expect(minutesOf(slot.endTime), 17 * 60 + 30);
      expect(slot.toJson(), {'id': 1, 'dayOfWeek': 'MONDAY', 'startTime': '09:00', 'endTime': '17:30'});
      expect(Weekday.of(DateTime(2026, 9, 26)), Weekday.saturday);
    });
  });

  test('time zones follow summer time', () {
    Duration offset(String zone, DateTime utc) => TimeZones.offsetOf(zone, utc)!;
    final summer = DateTime.utc(2026, 7, 1, 12);
    final winter = DateTime.utc(2026, 1, 15, 12);
    expect(offset('Africa/Tunis', summer), const Duration(hours: 1));
    expect(offset('Africa/Tunis', winter), const Duration(hours: 1));
    expect(offset('Europe/Paris', summer), const Duration(hours: 2));
    expect(offset('Europe/Paris', winter), const Duration(hours: 1));
    expect(offset('America/New_York', summer), const Duration(hours: -4));
    expect(offset('America/New_York', winter), const Duration(hours: -5));
    expect(offset('Australia/Sydney', summer), const Duration(hours: 10));
    expect(offset('Australia/Sydney', winter), const Duration(hours: 11));
    // Paris switches on the last Sunday of October (Oct 25, 2026).
    expect(offset('Europe/Paris', DateTime.utc(2026, 10, 24, 12)), const Duration(hours: 2));
    expect(offset('Europe/Paris', DateTime.utc(2026, 10, 26, 12)), const Duration(hours: 1));
    expect(TimeZones.offsetOf('Mars/Olympus', summer), isNull);
    expect(TimeZones.formatOffset(const Duration(hours: 1)), 'UTC+1');
    expect(TimeZones.formatOffset(const Duration(hours: -5)), 'UTC−5');
    expect(TimeZones.formatOffset(const Duration(hours: 5, minutes: 30)), 'UTC+5:30');
  });

  test('chat time labels', () {
    final now = DateTime(2026, 9, 26, 18);
    expect(listTime(DateTime(2026, 9, 26, 9, 5), now: now), '09:05');
    expect(listTime(DateTime(2026, 9, 25, 9, 5), now: now), 'Yesterday');
    expect(listTime(DateTime(2026, 9, 22), now: now), 'Tue');
    expect(listTime(DateTime(2026, 8, 2), now: now), 'Aug 2');
    expect(dayLabel(DateTime(2026, 9, 21), now: now), 'Monday, Sep 21');
  });
}
