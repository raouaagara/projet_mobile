import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Conversation list time: "14:05", "Yesterday", "Mon", "Sep 20".
String listTime(DateTime? time, {DateTime? now}) {
  if (time == null) return '';
  final today = DateUtils.dateOnly(now ?? DateTime.now());
  final day = DateUtils.dateOnly(time);
  final days = today.difference(day).inDays;
  if (days <= 0) return DateFormat.Hm().format(time);
  if (days == 1) return 'Yesterday';
  if (days < 7) return DateFormat.E('en_US').format(time);
  return DateFormat.MMMd('en_US').format(time);
}

/// Day separator in a chat: "Today", "Yesterday", "Monday, Sep 21".
String dayLabel(DateTime time, {DateTime? now}) {
  final today = DateUtils.dateOnly(now ?? DateTime.now());
  final days = today.difference(DateUtils.dateOnly(time)).inDays;
  if (days == 0) return 'Today';
  if (days == 1) return 'Yesterday';
  return DateFormat('EEEE, MMM d', 'en_US').format(time);
}

String hourMinute(DateTime time) => DateFormat.Hm().format(time);

/// "Sep 26, 2026 · 14:05".
String dateTime(DateTime time) => DateFormat('MMM d, y · HH:mm', 'en_US').format(time);

/// "just now", "5 min ago", "3 h ago", "2 d ago".
String ago(DateTime? time, {DateTime? now}) {
  if (time == null) return '';
  final diff = (now ?? DateTime.now()).difference(time);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} h ago';
  return '${diff.inDays} d ago';
}
