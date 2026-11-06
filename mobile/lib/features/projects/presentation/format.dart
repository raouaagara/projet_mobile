import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// "Posted today", "Posted 3 days ago", "Posted Aug 2, 2026".
String postedLabel(DateTime? date, {DateTime? now}) {
  if (date == null) return '';
  final days = DateUtils.dateOnly(now ?? DateTime.now()).difference(DateUtils.dateOnly(date)).inDays;
  if (days <= 0) return 'Posted today';
  if (days == 1) return 'Posted yesterday';
  if (days < 30) return 'Posted $days days ago';
  return 'Posted ${formatDay(date)}';
}

/// "Oct 30, 2026".
String formatDay(DateTime date) => DateFormat.yMMMd('en_US').format(date);

/// "5 min ago", "3 h ago", "2 d ago", or the date.
String timeAgo(DateTime? time, {DateTime? now}) {
  if (time == null) return '';
  final diff = (now ?? DateTime.now()).difference(time);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} h ago';
  if (diff.inDays < 7) return '${diff.inDays} d ago';
  return formatDay(time);
}
