import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../../../core/utils/json_utils.dart';
import '../time_zones.dart';

part 'availability_models.g.dart';

@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum AvailabilityStatus {
  online('Online', Colors.green),
  available('Available', Colors.teal),
  availableTomorrow('Available tomorrow', Colors.orange),
  doNotDisturb('Do not disturb', Colors.red),
  offline('Offline', Colors.grey),
  custom('Custom', Colors.indigo),
  unknown('Unknown', Colors.grey);

  const AvailabilityStatus(this.label, this.color);

  final String label;
  final Color color;

  /// Statuses a freelancer can pick.
  static const choices = [online, available, availableTomorrow, doNotDisturb, offline, custom];

  /// For sorting: reachable people first.
  int get rank => switch (this) {
    online => 0,
    available => 1,
    custom => 2,
    availableTomorrow => 3,
    doNotDisturb => 4,
    _ => 5,
  };
}

/// A freelancer's availability (ReferralMicroService `AvailabilityProfile`,
/// also built from a `world-view` entry).
@JsonSerializable(includeIfNull: false)
class AvailabilityProfile {
  const AvailabilityProfile({
    required this.id,
    required this.userId,
    required this.timezone,
    this.timezoneOffsetMinutes,
    this.status = AvailabilityStatus.offline,
    this.customStatusMessage,
    this.lastSeenAt,
  });

  /// `id` in the profile, `profileId` in the world view.
  @JsonKey(readValue: _readId)
  final int id;
  final int userId;
  @JsonKey(defaultValue: 'UTC')
  final String timezone;
  final int? timezoneOffsetMinutes;
  @JsonKey(unknownEnumValue: AvailabilityStatus.unknown)
  final AvailabilityStatus status;
  final String? customStatusMessage;
  @JsonKey(fromJson: _parseInstant, includeToJson: false)
  final DateTime? lastSeenAt;

  /// Offset from UTC now: from the zone name when it's a known zone (follows summer time),
  /// else the saved offset.
  Duration get utcOffset =>
      TimeZones.offsetOf(timezone, DateTime.now().toUtc()) ?? Duration(minutes: timezoneOffsetMinutes ?? 0);

  /// What time it is for this person.
  DateTime localTime([DateTime? nowUtc]) => (nowUtc ?? DateTime.now().toUtc()).add(utcOffset);

  /// "Online", or the custom message.
  String get statusText => status == AvailabilityStatus.custom && (customStatusMessage ?? '').trim().isNotEmpty
      ? customStatusMessage!.trim()
      : status.label;

  AvailabilityProfile copyWith({
    String? timezone,
    int? timezoneOffsetMinutes,
    AvailabilityStatus? status,
    String? customStatusMessage,
  }) => AvailabilityProfile(
    id: id,
    userId: userId,
    timezone: timezone ?? this.timezone,
    timezoneOffsetMinutes: timezoneOffsetMinutes ?? this.timezoneOffsetMinutes,
    status: status ?? this.status,
    customStatusMessage: customStatusMessage ?? this.customStatusMessage,
    lastSeenAt: lastSeenAt,
  );

  factory AvailabilityProfile.fromJson(Map<String, dynamic> json) => _$AvailabilityProfileFromJson(json);
  Map<String, dynamic> toJson() => _$AvailabilityProfileToJson(this);
}

Object? _readId(Map<dynamic, dynamic> json, String key) => json['id'] ?? json['profileId'];

/// `Instant` as ISO with "Z" ("" when missing in the world view).
DateTime? _parseInstant(Object? value) =>
    value is String && value.isNotEmpty ? DateTime.tryParse(value)?.toUtc() : parseApiDate(value);

@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum Weekday {
  monday('Monday'),
  tuesday('Tuesday'),
  wednesday('Wednesday'),
  thursday('Thursday'),
  friday('Friday'),
  saturday('Saturday'),
  sunday('Sunday');

  const Weekday(this.label);

  final String label;

  String get short => label.substring(0, 3);

  /// `DateTime.weekday` (1 = Monday).
  static Weekday of(DateTime date) => values[date.weekday - 1];
}

/// A weekly working slot, e.g. Monday 09:00–17:00 (in the freelancer's time zone).
@JsonSerializable(includeIfNull: false)
class AvailabilitySlot {
  const AvailabilitySlot({this.id, required this.dayOfWeek, required this.startTime, required this.endTime});

  final int? id;
  final Weekday dayOfWeek;

  /// "09:00" (the backend sends "09:00:00").
  @JsonKey(fromJson: _hhmm)
  final String startTime;
  @JsonKey(fromJson: _hhmm)
  final String endTime;

  String get label => '$startTime – $endTime';

  factory AvailabilitySlot.fromJson(Map<String, dynamic> json) => _$AvailabilitySlotFromJson(json);
  Map<String, dynamic> toJson() => _$AvailabilitySlotToJson(this);
}

String _hhmm(Object? value) {
  final text = '$value';
  return text.length >= 5 ? text.substring(0, 5) : text;
}

/// "09:00" → minutes since midnight.
int minutesOf(String hhmm) {
  final parts = hhmm.split(':');
  return int.parse(parts[0]) * 60 + int.parse(parts[1]);
}
