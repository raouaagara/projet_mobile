// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cv_extraction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CvExtraction _$CvExtractionFromJson(Map<String, dynamic> json) => CvExtraction(
  language: json['language'] as String? ?? 'unknown',
  semanticEnabled: json['semanticEnabled'] as bool? ?? false,
  skills:
      (json['skills'] as List<dynamic>?)
          ?.map((e) => CvSkillMatch.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  otherSkills:
      (json['otherSkills'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
);

CvSkillMatch _$CvSkillMatchFromJson(Map<String, dynamic> json) => CvSkillMatch(
  id: (json['id'] as num?)?.toInt(),
  name: json['name'] as String? ?? '',
  confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
  method: json['method'] as String? ?? 'exact',
  evidence: json['evidence'] as String? ?? '',
);
