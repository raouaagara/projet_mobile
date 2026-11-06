import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/app_user.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_provider.dart';
import 'models/chat_models.dart';

/// "Catch me up": an AI summary of a conversation, from the reader's side.
class ChatCatchUp {
  const ChatCatchUp({
    required this.summary,
    this.decisions = const [],
    this.myTodos = const [],
    this.theirTodos = const [],
  });

  final List<String> summary;
  final List<String> decisions;
  final List<String> myTodos;
  final List<String> theirTodos;

  factory ChatCatchUp.fromJson(Map<String, dynamic> json) {
    List<String> strings(Object? v) => [for (final s in v as List<dynamic>? ?? []) s as String];
    final todos = (json['todos'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    return ChatCatchUp(
      summary: strings(json['summary']),
      decisions: strings(json['decisions']),
      myTodos: [
        for (final t in todos)
          if (t['who'] == 'me') t['what'] as String,
      ],
      theirTodos: [
        for (final t in todos)
          if (t['who'] != 'me') t['what'] as String,
      ],
    );
  }
}

final chatRepositoryProvider = Provider((ref) => ChatRepository(ref.watch(dioProvider)));

/// Chat REST endpoints (`/chat/**`). Sending text goes through the socket (see chat_socket.dart).
/// Every method throws [ApiException] on failure.
class ChatRepository {
  ChatRepository(this._dio);

  final Dio _dio;

  Future<T> _call<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (e) {
      // Moderation refusals: {"error": "...", "reason": "Insults are not allowed..."}
      final data = e.response?.data;
      if (data is Map && data['reason'] is String) {
        throw ApiException(data['reason'] as String, statusCode: e.response?.statusCode);
      }
      throw ApiException.from(e);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Conversations with last message and unread count, newest first.
  Future<List<ConversationSummary>> fetchConversations(int userId) => _call(() async {
    final res = await _dio.get<List<dynamic>>('/chat/conversations/$userId/summary');
    return res.data!.map((e) => ConversationSummary.fromJson(e as Map<String, dynamic>)).toList();
  });

  /// Oldest first.
  Future<List<ChatMessage>> fetchMessages(int conversationId) => _call(() async {
    final res = await _dio.get<List<dynamic>>('/chat/messages/$conversationId');
    return res.data!.map((e) => ChatMessage.fromJson(e as Map<String, dynamic>)).toList();
  });

  /// The conversation between two users (created the first time). Returns its id.
  Future<int> openConversation(int me, int other) => _call(() async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/chat/conversation/create',
      queryParameters: {'user1': me, 'user2': other},
    );
    return (res.data!['id'] as num).toInt();
  });

  /// Null when the text is fine, else why it would be refused.
  Future<String?> moderate(String text) => _call(() async {
    final res = await _dio.post<Map<String, dynamic>>('/chat/moderate', data: {'text': text});
    return res.data!['allowed'] == false ? res.data!['reason'] as String? ?? 'This message is not allowed.' : null;
  });

  /// Three short replies [userId] could send next in [conversationId], written by the AI.
  Future<List<String>> suggestReplies(int conversationId, int userId) => _call(() async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/chat/ai/replies',
      data: {'conversationId': conversationId, 'userId': userId},
    );
    return [for (final r in res.data!['replies'] as List<dynamic>? ?? []) r as String];
  });

  /// [messageId]'s text in [language] (e.g. "French"), by the AI.
  Future<String> translate(int messageId, String language) => _call(() async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/chat/ai/translate',
      data: {'messageId': messageId, 'language': language},
    );
    return res.data!['text'] as String? ?? '';
  });

  /// Where the conversation stands, what was decided, and who must do what (AI).
  Future<ChatCatchUp> catchUp(int conversationId, int userId) => _call(() async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/chat/ai/summary',
      data: {'conversationId': conversationId, 'userId': userId},
    );
    return ChatCatchUp.fromJson(res.data!);
  });

  Future<ChatMessage> edit(int messageId, String content) => _call(() async {
    final res = await _dio.put<Map<String, dynamic>>('/chat/messages/$messageId', data: {'content': content});
    return ChatMessage.fromJson(res.data!);
  });

  Future<void> delete(int messageId) => _call(() => _dio.delete<void>('/chat/messages/$messageId'));

  Future<ChatMessage> setReactions(int messageId, Map<String, int> reactions) => _call(() async {
    final res = await _dio.put<Map<String, dynamic>>(
      '/chat/messages/$messageId/reactions',
      data: jsonEncode(reactions),
    );
    return ChatMessage.fromJson(res.data!);
  });

  Future<void> markRead(int conversationId, int userId) =>
      _call(() => _dio.put<void>('/chat/conversations/$conversationId/read', queryParameters: {'userId': userId}));

  /// Sends a file (image or PDF, 10 MB max) as a message; it arrives through the socket like any message.
  Future<void> upload({
    required List<int> bytes,
    required String fileName,
    required int conversationId,
    required int senderId,
    required int recipientId,
    String caption = '',
  }) => _call(
    () => _dio.post<void>(
      '/chat/upload',
      data: FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: fileName),
        'conversationId': conversationId,
        'senderId': senderId,
        'recipientId': recipientId,
        'content': caption,
      }),
      options: Options(sendTimeout: const Duration(seconds: 60), receiveTimeout: const Duration(seconds: 60)),
    ),
  );

  /// Everyone, to start a new conversation (`GET /users/all`).
  Future<List<AppUser>> fetchUsers() => _call(() async {
    final res = await _dio.get<List<dynamic>>('/users/all');
    return res.data!.map((e) => AppUser.fromJson(e as Map<String, dynamic>)).toList();
  });
}
