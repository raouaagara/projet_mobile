import 'package:json_annotation/json_annotation.dart';

part 'cv_analysis.g.dart';

/// Result of `/SkillTests/ai/cv/analyze-*`, written by Gemini. Without an AI key the backend
/// answers 503 with a message saying so.
@JsonSerializable(createToJson: false)
class CvAnalysis {
  const CvAnalysis({
    required this.improvedCv,
    this.summary = '',
    this.suggestions = const [],
    this.missingSkills = const [],
    this.strengthAreas = const [],
  });

  @JsonKey(name: 'improvedCV', defaultValue: '')
  final String improvedCv;
  @JsonKey(defaultValue: '')
  final String summary;
  @JsonKey(defaultValue: [])
  final List<String> suggestions;
  @JsonKey(defaultValue: [])
  final List<String> missingSkills;
  @JsonKey(defaultValue: [])
  final List<String> strengthAreas;

  factory CvAnalysis.fromJson(Map<String, dynamic> json) => _$CvAnalysisFromJson(json);
}

/// Target domains offered by the web app.
const cvTargetDomains = [
  'Software Development',
  'Web Development',
  'Mobile Development',
  'Data Science',
  'Machine Learning / AI',
  'DevOps / Cloud Engineering',
  'Cybersecurity',
  'UI/UX Design',
  'Graphic Design',
  'Digital Marketing',
  'Content Writing',
  'Project Management',
  'Business Analysis',
];
