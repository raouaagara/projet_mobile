// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cv_analysis.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CvAnalysis _$CvAnalysisFromJson(Map<String, dynamic> json) => CvAnalysis(
  improvedCv: json['improvedCV'] as String? ?? '',
  summary: json['summary'] as String? ?? '',
  suggestions:
      (json['suggestions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  missingSkills:
      (json['missingSkills'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  strengthAreas:
      (json['strengthAreas'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
);
