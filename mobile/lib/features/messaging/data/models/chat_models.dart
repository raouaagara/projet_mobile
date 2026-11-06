import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

import '../../../../core/config/env.dart';
import '../../../../core/utils/json_utils.dart';

part 'chat_models.g.dart';

/// A chat message (MSCommunication `Message`).
///
/// Attachments are stored in [content] as `caption [FILE:url]`, like the web app does.
@JsonSerializable(includeIfNull: false)
class ChatMessage {
  const ChatMessage({
    this.id,
    required this.conversationId,
    required this.senderId,
    required this.recipientId,
    required this.content,
    this.timestamp,
    this.reactionsJson,
    this.seen,
  });

  final int? id;
  final int conversationId;
  final int senderId;
  final int recipientId;
  @JsonKey(defaultValue: '')
  final String content;
  @JsonKey(fromJson: parseApiDate, includeToJson: false)
  final DateTime? timestamp;

  /// JSON object as a string, e.g. `{"👍": 2}`.
  @JsonKey(name: 'reactions', includeToJson: false)
  final String? reactionsJson;

  /// Null for messages sent before read receipts existed: treated as read.
  @JsonKey(includeToJson: false)
  final bool? seen;

  static final _file = RegExp(r'\s*\[FILE:([^\]]+)\]\s*$');

  /// The text without the attachment marker.
  String get text => content.replaceFirst(_file, '').trim();

  /// Attachment link, rewritten to go through the gateway the app uses
  /// (older messages point at `localhost:8086`, which a phone can't reach).
  String? get attachmentUrl {
    final raw = _file.firstMatch(content)?.group(1);
    return raw == null ? null : gatewayUrl(raw);
  }

  bool get isImage =>
      attachmentUrl != null && RegExp(r'\.(png|jpe?g|gif|webp|heic)$', caseSensitive: false).hasMatch(attachmentUrl!);

  String get attachmentName {
    final url = attachmentUrl;
    if (url == null) return '';
    final name = Uri.parse(url).pathSegments.last;
    // Uploads are named "1790429201698_original.pdf".
    return name.replaceFirst(RegExp(r'^\d+_'), '');
  }

  /// emoji → count. Accepts a JSON object, or a JSON string that contains one.
  Map<String, int> get reactions {
    final raw = reactionsJson;
    if (raw == null || raw.trim().isEmpty) return const {};
    try {
      Object? decoded = jsonDecode(raw);
      if (decoded is String) decoded = jsonDecode(decoded);
      if (decoded is! Map) return const {};
      return {
        for (final entry in decoded.entries)
          if (entry.value is num && (entry.value as num) > 0) '${entry.key}': (entry.value as num).toInt(),
      };
    } on FormatException {
      return const {};
    }
  }

  ChatMessage copyWith({String? content, String? reactionsJson, bool? seen}) => ChatMessage(
    id: id,
    conversationId: conversationId,
    senderId: senderId,
    recipientId: recipientId,
    content: content ?? this.content,
    timestamp: timestamp,
    reactionsJson: reactionsJson ?? this.reactionsJson,
    seen: seen ?? this.seen,
  );

  factory ChatMessage.fromJson(Map<String, dynamic> json) => _$ChatMessageFromJson(json);
  Map<String, dynamic> toJson() => _$ChatMessageToJson(this);
}

/// Rewrites a backend link (`http://localhost:8085/...` or `:8086/...`) to the gateway the app uses.
String gatewayUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || !(uri.host == 'localhost' || uri.host == '127.0.0.1')) return url;
  final base = Uri.parse(Env.apiBaseUrl);
  return uri.replace(scheme: base.scheme, host: base.host, port: base.port).toString();
}

/// A row of the conversation list (`GET /chat/conversations/{userId}/summary`).
@JsonSerializable(createToJson: false)
class ConversationSummary {
  const ConversationSummary({
    required this.id,
    required this.otherUserId,
    this.lastMessage,
    this.lastSenderId,
    this.lastMessageTime,
    this.unreadCount = 0,
  });

  final int id;
  final int otherUserId;
  final String? lastMessage;
  final int? lastSenderId;
  @JsonKey(fromJson: parseApiDate)
  final DateTime? lastMessageTime;
  final int unreadCount;

  /// "📎 logo.png" for attachments, the text otherwise.
  String get preview {
    final last = lastMessage;
    if (last == null) return 'No message yet';
    final message = ChatMessage(conversationId: id, senderId: 0, recipientId: 0, content: last);
    if (message.attachmentUrl == null) return message.text;
    return message.text.isNotEmpty ? '📎 ${message.text}' : '📎 ${message.attachmentName}';
  }

  ConversationSummary copyWith({String? lastMessage, int? lastSenderId, DateTime? lastMessageTime, int? unreadCount}) =>
      ConversationSummary(
        id: id,
        otherUserId: otherUserId,
        lastMessage: lastMessage ?? this.lastMessage,
        lastSenderId: lastSenderId ?? this.lastSenderId,
        lastMessageTime: lastMessageTime ?? this.lastMessageTime,
        unreadCount: unreadCount ?? this.unreadCount,
      );

  factory ConversationSummary.fromJson(Map<String, dynamic> json) => _$ConversationSummaryFromJson(json);
}
