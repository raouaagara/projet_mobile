// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'availability_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AvailabilityProfile _$AvailabilityProfileFromJson(Map<String, dynamic> json) => AvailabilityProfile(
  id: (_readId(json, 'id') as num).toInt(),
  userId: (json['userId'] as num).toInt(),
  timezone: json['timezone'] as String? ?? 'UTC',
  timezoneOffsetMinutes: (json['timezoneOffsetMinutes'] as num?)?.toInt(),
  status:
      $enumDecodeNullable(_$AvailabilityStatusEnumMap, json['status'], unknownValue: AvailabilityStatus.unknown) ??
      AvailabilityStatus.offline,
  customStatusMessage: json['customStatusMessage'] as String?,
  lastSeenAt: _parseInstant(json['lastSeenAt']),
);

Map<String, dynamic> _$AvailabilityProfileToJson(AvailabilityProfile instance) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'timezone': instance.timezone,
  'timezoneOffsetMinutes': ?instance.timezoneOffsetMinutes,
  'status': _$AvailabilityStatusEnumMap[instance.status]!,
  'customStatusMessage': ?instance.customStatusMessage,
};

const _$AvailabilityStatusEnumMap = {
  AvailabilityStatus.online: 'ONLINE',
  AvailabilityStatus.available: 'AVAILABLE',
  AvailabilityStatus.availableTomorrow: 'AVAILABLE_TOMORROW',
  AvailabilityStatus.doNotDisturb: 'DO_NOT_DISTURB',
  AvailabilityStatus.offline: 'OFFLINE',
  AvailabilityStatus.custom: 'CUSTOM',
  AvailabilityStatus.unknown: 'UNKNOWN',
};

AvailabilitySlot _$AvailabilitySlotFromJson(Map<String, dynamic> json) => AvailabilitySlot(
  id: (json['id'] as num?)?.toInt(),
  dayOfWeek: $enumDecode(_$WeekdayEnumMap, json['dayOfWeek']),
  startTime: _hhmm(json['startTime']),
  endTime: _hhmm(json['endTime']),
);

Map<String, dynamic> _$AvailabilitySlotToJson(AvailabilitySlot instance) => <String, dynamic>{
  'id': ?instance.id,
  'dayOfWeek': _$WeekdayEnumMap[instance.dayOfWeek]!,
  'startTime': instance.startTime,
  'endTime': instance.endTime,
};

const _$WeekdayEnumMap = {
  Weekday.monday: 'MONDAY',
  Weekday.tuesday: 'TUESDAY',
  Weekday.wednesday: 'WEDNESDAY',
  Weekday.thursday: 'THURSDAY',
  Weekday.friday: 'FRIDAY',
  Weekday.saturday: 'SATURDAY',
  Weekday.sunday: 'SUNDAY',
};
