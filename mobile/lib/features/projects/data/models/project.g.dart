// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Project _$ProjectFromJson(Map<String, dynamic> json) => Project(
  id: (json['id'] as num?)?.toInt(),
  title: json['title'] as String? ?? '',
  description: json['description'] as String? ?? '',
  image: json['image'] as String?,
  experienceLevel: json['ExperienceLevel'] as String?,
  budget: (json['budget'] as num?)?.toDouble() ?? 0,
  postedAt: parseApiDate(json['postedAt']),
  status:
      $enumDecodeNullable(_$ProjectStatusEnumMap, json['status'], unknownValue: ProjectStatus.unknown) ??
      ProjectStatus.open,
  category: $enumDecodeNullable(_$ProjectCategoryEnumMap, json['category'], unknownValue: ProjectCategory.other),
  jobType: $enumDecodeNullable(_$JobTypeEnumMap, json['jobType'], unknownValue: JsonKey.nullForUndefinedEnumValue),
  clientId: (json['clientId'] as num?)?.toInt(),
  likes: (json['likes'] as num?)?.toInt() ?? 0,
  loves: (json['loves'] as num?)?.toInt() ?? 0,
  hahas: (json['hahas'] as num?)?.toInt() ?? 0,
  supports: (json['supports'] as num?)?.toInt() ?? 0,
  requiredCompetenceIds:
      (json['requiredCompetenceIds'] as List<dynamic>?)?.map((e) => (e as num).toInt()).toList() ?? const [],
);

Map<String, dynamic> _$ProjectToJson(Project instance) => <String, dynamic>{
  'id': ?instance.id,
  'title': instance.title,
  'description': instance.description,
  'image': ?instance.image,
  'ExperienceLevel': ?instance.experienceLevel,
  'budget': instance.budget,
  'postedAt': ?formatApiDate(instance.postedAt),
  'status': _$ProjectStatusEnumMap[instance.status]!,
  'category': ?_$ProjectCategoryEnumMap[instance.category],
  'jobType': ?_$JobTypeEnumMap[instance.jobType],
  'clientId': ?instance.clientId,
  'requiredCompetenceIds': instance.requiredCompetenceIds,
};

const _$ProjectStatusEnumMap = {
  ProjectStatus.open: 'OPEN',
  ProjectStatus.active: 'ACTIVE',
  ProjectStatus.closed: 'CLOSED',
  ProjectStatus.unknown: 'UNKNOWN',
};

const _$ProjectCategoryEnumMap = {
  ProjectCategory.webDevelopment: 'WEB_DEVELOPMENT',
  ProjectCategory.mobileDevelopment: 'MOBILE_DEVELOPMENT',
  ProjectCategory.uiUxDesign: 'UI_UX_DESIGN',
  ProjectCategory.digitalMarketing: 'DIGITAL_MARKETING',
  ProjectCategory.dataScienceAi: 'DATA_SCIENCE_AI',
  ProjectCategory.writingTranslation: 'WRITING_TRANSLATION',
  ProjectCategory.videoAnimation: 'VIDEO_ANIMATION',
  ProjectCategory.customerSupport: 'CUSTOMER_SUPPORT',
  ProjectCategory.financeAccounting: 'FINANCE_ACCOUNTING',
  ProjectCategory.other: 'OTHER',
};

const _$JobTypeEnumMap = {JobType.fixedPrice: 'FIXED_PRICE', JobType.hourly: 'HOURLY'};
