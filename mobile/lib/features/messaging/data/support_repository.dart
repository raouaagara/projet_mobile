import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_provider.dart';
import 'models/support_models.dart';

final supportRepositoryProvider = Provider((ref) => SupportRepository(ref.watch(dioProvider)));

/// One message in the help assistant conversation.
class AssistantTurn {
  const AssistantTurn({required this.fromUser, required this.text, this.failed = false});

  final bool fromUser;
  final String text;

  /// An error shown in the conversation, not sent back as history.
  final bool failed;

  Map<String, dynamic> toJson() => {'role': fromUser ? 'user' : 'assistant', 'text': text};
}

/// The assistant's answer; when [needsTicket], a request already written for the support team.
class AssistantAnswer {
  const AssistantAnswer({
    required this.answer,
    this.needsTicket = false,
    this.ticketTitle = '',
    this.ticketDescription = '',
  });

  final String answer;
  final bool needsTicket;
  final String ticketTitle;
  final String ticketDescription;

  factory AssistantAnswer.fromJson(Map<String, dynamic> json) => AssistantAnswer(
    answer: json['answer'] as String? ?? '',
    needsTicket: json['needsTicket'] as bool? ?? false,
    ticketTitle: json['ticketTitle'] as String? ?? '',
    ticketDescription: json['ticketDescription'] as String? ?? '',
  );
}

/// Support tickets (`/api/tickets/**`). Every method throws [ApiException] on failure.
class SupportRepository {
  SupportRepository(this._dio);

  final Dio _dio;

  Future<T> _call<T>(Future<T> Function() request) async {
    try {
      return await request();
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  /// The help assistant (AI, answers from the Workify help guide). [history]: the conversation so far.
  Future<AssistantAnswer> ask(String question, {List<AssistantTurn> history = const []}) => _call(() async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/tickets/assistant/ask',
      data: {
        'question': question,
        'history': [for (final t in history.where((t) => !t.failed)) t.toJson()],
      },
    );
    return AssistantAnswer.fromJson(res.data!);
  });

  /// Newest first.
  Future<List<Ticket>> fetchMine(int userId) => _call(() async {
    final res = await _dio.get<List<dynamic>>('/api/tickets/user/$userId');
    return res.data!.map((e) => Ticket.fromJson(e as Map<String, dynamic>)).toList()
      ..sort((a, b) => b.id.compareTo(a.id));
  });

  Future<Ticket> fetch(int id) => _call(() async {
    final res = await _dio.get<Map<String, dynamic>>('/api/tickets/$id');
    return Ticket.fromJson(res.data!);
  });

  /// Leave [category] / [priority] null to let the backend detect them.
  Future<Ticket> create({
    required int userId,
    required String userName,
    required String userEmail,
    required String title,
    required String description,
    TicketCategory? category,
    TicketPriority? priority,
  }) => _call(() async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/tickets/create',
      data: {
        'userId': userId,
        'userName': userName,
        'userEmail': userEmail,
        'title': title,
        'description': description,
        'category': ?category?.name.replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]}').toUpperCase(),
        'priority': ?priority?.name.toUpperCase(),
      },
    );
    return Ticket.fromJson(res.data!);
  });

  /// Oldest first.
  Future<List<TicketReply>> fetchReplies(int ticketId) => _call(() async {
    final res = await _dio.get<List<dynamic>>('/api/tickets/$ticketId/responses');
    return res.data!.map((e) => TicketReply.fromJson(e as Map<String, dynamic>)).toList()
      ..sort((a, b) => a.id.compareTo(b.id));
  });

  Future<TicketReply> reply(int ticketId, {required int userId, required String userName, required String message}) =>
      _call(() async {
        final res = await _dio.post<Map<String, dynamic>>(
          '/api/tickets/$ticketId/responses',
          data: {'responderId': userId, 'responderName': userName, 'staff': false, 'message': message},
        );
        return TicketReply.fromJson(res.data!);
      });

  Future<Ticket> escalate(int ticketId) => _call(() async {
    final res = await _dio.post<Map<String, dynamic>>('/api/tickets/escalate/$ticketId');
    return Ticket.fromJson(res.data!);
  });

  /// AI rewrite of a ticket description. Returns the same text when the server has no AI key.
  Future<String> enhance({required String title, required String description}) => _call(() async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/tickets/enhance-text',
      data: {'title': title, 'description': description},
      options: Options(receiveTimeout: const Duration(seconds: 45)),
    );
    return res.data!['enhanced'] as String? ?? description;
  });
}
