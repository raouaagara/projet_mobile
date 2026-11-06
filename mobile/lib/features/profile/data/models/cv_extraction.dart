import 'package:json_annotation/json_annotation.dart';

part 'cv_extraction.g.dart';

/// Result of `POST /Competance/ParseCV/details`: the catalog skills found in a CV
/// by the AI service (backend/SkillExtractorAI), with the text that proves each one.
@JsonSerializable(createToJson: false)
class CvExtraction {
  const CvExtraction({
    this.language = 'unknown',
    this.semanticEnabled = false,
    this.skills = const [],
    this.otherSkills = const [],
  });

  /// `fr`, `en` or `unknown` (keyword fallback when the AI service is down).
  @JsonKey(defaultValue: 'unknown')
  final String language;
  @JsonKey(defaultValue: false)
  final bool semanticEnabled;
  @JsonKey(defaultValue: [])
  final List<CvSkillMatch> skills;

  /// Skills recognised in the CV that are not in the catalog.
  @JsonKey(defaultValue: [])
  final List<String> otherSkills;

  factory CvExtraction.fromJson(Map<String, dynamic> json) => _$CvExtractionFromJson(json);
}

@JsonSerializable(createToJson: false)
class CvSkillMatch {
  const CvSkillMatch({
    this.id,
    required this.name,
    this.confidence = 0,
    this.method = 'exact',
    this.evidence = '',
  });

  final int? id;
  @JsonKey(defaultValue: '')
  final String name;
  @JsonKey(defaultValue: 0)
  final double confidence;

  /// exact | alias | semantic (found by the AI model) | keyword (fallback)
  @JsonKey(defaultValue: 'exact')
  final String method;
  @JsonKey(defaultValue: '')
  final String evidence;

  bool get foundByAi => method == 'semantic';

  factory CvSkillMatch.fromJson(Map<String, dynamic> json) => _$CvSkillMatchFromJson(json);
}
