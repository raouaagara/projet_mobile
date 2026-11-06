import 'package:json_annotation/json_annotation.dart';

import '../../../../core/utils/json_utils.dart';

part 'skill_test.g.dart';

@JsonSerializable(createToJson: false)
class SkillTest {
  const SkillTest({
    required this.id,
    required this.title,
    this.description,
    this.category,
    this.durationMinutes = 10,
    this.passScore = 70,
  });

  final int id;
  @JsonKey(defaultValue: '')
  final String title;
  final String? description;
  final String? category;
  @JsonKey(defaultValue: 10)
  final int durationMinutes;

  /// Percentage needed to pass.
  @JsonKey(defaultValue: 70)
  final int passScore;

  factory SkillTest.fromJson(Map<String, dynamic> json) => _$SkillTestFromJson(json);
}

/// The correct option is never sent to the app: scoring happens on the server.
@JsonSerializable(createToJson: false)
class TestQuestion {
  const TestQuestion({
    required this.id,
    required this.questionText,
    this.optionA,
    this.optionB,
    this.optionC,
    this.optionD,
  });

  final int id;
  @JsonKey(defaultValue: '')
  final String questionText;
  final String? optionA;
  final String? optionB;
  final String? optionC;
  final String? optionD;

  /// Non-empty options as (letter, text), e.g. ('A', 'User Experience').
  List<(String, String)> get options => [
        ('A', optionA),
        ('B', optionB),
        ('C', optionC),
        ('D', optionD),
      ]
          .where((o) => o.$2 != null && o.$2!.trim().isNotEmpty)
          .map((o) => (o.$1, o.$2!))
          .toList();

  factory TestQuestion.fromJson(Map<String, dynamic> json) => _$TestQuestionFromJson(json);
}

@JsonSerializable(createToJson: false)
class Certification {
  const Certification({
    required this.id,
    required this.testTitle,
    this.skillTestId,
    this.category,
    this.score = 0,
    this.passed = false,
    this.completedAt,
  });

  final int id;
  final int? skillTestId;
  @JsonKey(defaultValue: '')
  final String testTitle;
  final String? category;
  @JsonKey(defaultValue: 0)
  final int score;
  @JsonKey(defaultValue: false)
  final bool passed;
  @JsonKey(fromJson: parseApiDate)
  final DateTime? completedAt;

  factory Certification.fromJson(Map<String, dynamic> json) => _$CertificationFromJson(json);
}
