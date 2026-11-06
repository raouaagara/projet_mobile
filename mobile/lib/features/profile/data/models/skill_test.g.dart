// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'skill_test.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SkillTest _$SkillTestFromJson(Map<String, dynamic> json) => SkillTest(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String? ?? '',
  description: json['description'] as String?,
  category: json['category'] as String?,
  durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 10,
  passScore: (json['passScore'] as num?)?.toInt() ?? 70,
);

TestQuestion _$TestQuestionFromJson(Map<String, dynamic> json) => TestQuestion(
  id: (json['id'] as num).toInt(),
  questionText: json['questionText'] as String? ?? '',
  optionA: json['optionA'] as String?,
  optionB: json['optionB'] as String?,
  optionC: json['optionC'] as String?,
  optionD: json['optionD'] as String?,
);

Certification _$CertificationFromJson(Map<String, dynamic> json) =>
    Certification(
      id: (json['id'] as num).toInt(),
      testTitle: json['testTitle'] as String? ?? '',
      skillTestId: (json['skillTestId'] as num?)?.toInt(),
      category: json['category'] as String?,
      score: (json['score'] as num?)?.toInt() ?? 0,
      passed: json['passed'] as bool? ?? false,
      completedAt: parseApiDate(json['completedAt']),
    );
