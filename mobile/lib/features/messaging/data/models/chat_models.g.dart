// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatMessage _$ChatMessageFromJson(Map<String, dynamic> json) => ChatMessage(
  id: (json['id'] as num?)?.toInt(),
  conversationId: (json['conversationId'] as num).toInt(),
  senderId: (json['senderId'] as num).toInt(),
  recipientId: (json['recipientId'] as num).toInt(),
  content: json['content'] as String? ?? '',
  timestamp: parseApiDate(json['timestamp']),
  reactionsJson: json['reactions'] as String?,
  seen: json['seen'] as bool?,
);

Map<String, dynamic> _$ChatMessageToJson(ChatMessage instance) => <String, dynamic>{
  'id': ?instance.id,
  'conversationId': instance.conversationId,
  'senderId': instance.senderId,
  'recipientId': instance.recipientId,
  'content': instance.content,
};

ConversationSummary _$ConversationSummaryFromJson(Map<String, dynamic> json) => ConversationSummary(
  id: (json['id'] as num).toInt(),
  otherUserId: (json['otherUserId'] as num).toInt(),
  lastMessage: json['lastMessage'] as String?,
  lastSenderId: (json['lastSenderId'] as num?)?.toInt(),
  lastMessageTime: parseApiDate(json['lastMessageTime']),
  unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
);
