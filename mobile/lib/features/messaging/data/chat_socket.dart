import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../../../core/config/env.dart';
import 'models/chat_models.dart';

/// Something that happened in the user's conversations, pushed by the server.
sealed class ChatEvent {
  const ChatEvent();
}

class MessageReceived extends ChatEvent {
  const MessageReceived(this.message);
  final ChatMessage message;
}

class MessageUpdated extends ChatEvent {
  const MessageUpdated(this.message);
  final ChatMessage message;
}

class MessageDeleted extends ChatEvent {
  const MessageDeleted({required this.messageId, required this.conversationId});
  final int messageId;
  final int conversationId;
}

/// The server refused a message the user sent (moderation).
class MessageRejected extends ChatEvent {
  const MessageRejected({required this.conversationId, required this.reason, required this.content});
  final int? conversationId;
  final String reason;
  final String content;
}

/// The other person opened the conversation: the user's messages are read.
class MessagesRead extends ChatEvent {
  const MessagesRead({required this.conversationId, required this.readerId});
  final int conversationId;
  final int readerId;
}

enum SocketStatus { connecting, connected, disconnected }

/// Real-time chat connection of the logged-in user. Tests use a fake.
abstract class ChatSocket {
  Stream<ChatEvent> get events;
  ValueListenable<SocketStatus> get status;

  /// Throws [StateError] when not connected.
  void send(ChatMessage message);
  void dispose();
}

/// STOMP over the SockJS WebSocket transport, through the gateway (`/ws`), like the web app:
/// sends to `/app/chat`, listens on `/user/{userId}/queue/{messages,updates,deletes,errors,reads}`.
/// Reconnects by itself every few seconds when the connection drops.
class StompChatSocket implements ChatSocket {
  StompChatSocket(this.userId) {
    _client = StompClient(
      config: StompConfig.sockJS(
        url: Env.chatSocketUrl,
        reconnectDelay: const Duration(seconds: 4),
        heartbeatIncoming: const Duration(seconds: 10),
        heartbeatOutgoing: const Duration(seconds: 10),
        onConnect: _onConnect,
        onWebSocketError: (_) => _status.value = SocketStatus.disconnected,
        onWebSocketDone: () => _status.value = SocketStatus.disconnected,
        onDisconnect: (_) => _status.value = SocketStatus.disconnected,
        onStompError: (frame) => debugPrint('STOMP error: ${frame.body}'),
      ),
    )..activate();
  }

  final int userId;
  late final StompClient _client;
  final _events = StreamController<ChatEvent>.broadcast();
  final _status = ValueNotifier(SocketStatus.connecting);

  @override
  Stream<ChatEvent> get events => _events.stream;

  @override
  ValueListenable<SocketStatus> get status => _status;

  void _onConnect(StompFrame _) {
    _status.value = SocketStatus.connected;
    void listen(String queue, ChatEvent? Function(Map<String, dynamic> body) toEvent) {
      _client.subscribe(
        destination: '/user/$userId/queue/$queue',
        callback: (frame) {
          final body = frame.body;
          if (body == null || _events.isClosed) return;
          try {
            final event = toEvent(jsonDecode(body) as Map<String, dynamic>);
            if (event != null) _events.add(event);
          } on Object catch (e) {
            debugPrint('Bad chat frame on $queue: $e');
          }
        },
      );
    }

    listen('messages', (json) => MessageReceived(ChatMessage.fromJson(json)));
    listen('updates', (json) => MessageUpdated(ChatMessage.fromJson(json)));
    listen(
      'deletes',
      (json) => MessageDeleted(
        messageId: (json['deletedId'] as num).toInt(),
        conversationId: (json['conversationId'] as num).toInt(),
      ),
    );
    listen(
      'errors',
      (json) => MessageRejected(
        conversationId: (json['conversationId'] as num?)?.toInt(),
        reason: json['reason'] as String? ?? 'Message not sent.',
        content: json['content'] as String? ?? '',
      ),
    );
    listen(
      'reads',
      (json) => MessagesRead(
        conversationId: (json['conversationId'] as num).toInt(),
        readerId: (json['readerId'] as num).toInt(),
      ),
    );
  }

  @override
  void send(ChatMessage message) {
    if (!_client.connected) throw StateError('Not connected');
    _client.send(
      destination: '/app/chat',
      headers: {'content-type': 'application/json'},
      body: jsonEncode(message.toJson()),
    );
  }

  @override
  void dispose() {
    _client.deactivate();
    _events.close();
    // [_status] is not disposed: listeners may still detach from it after this.
  }
}
