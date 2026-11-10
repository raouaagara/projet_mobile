import 'package:catchopp_mobile/features/profile/data/models/cv_analysis.dart';
import 'package:catchopp_mobile/features/profile/data/models/cv_extraction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses /Competance/ParseCV/details (AI service answer)', () {
    final result = CvExtraction.fromJson({
      'language': 'fr',
      'semanticEnabled': true,
      'skills': [
        {'id': 10, 'name': 'Machine Learning', 'confidence': 0.79, 'method': 'semantic',
         'evidence': 'Entraînement de modèles prédictifs'},
        {'id': 1, 'name': 'Flutter', 'confidence': 1, 'method': 'exact', 'evidence': 'Flutter'},
      ],
      'otherSkills': ['Android'],
    });

    expect(result.language, 'fr');
    expect(result.skills.first.foundByAi, isTrue);
    expect(result.skills.first.evidence, contains('prédictifs'));
    expect(result.skills.last.confidence, 1.0); // int in JSON → double
    expect(result.otherSkills, ['Android']);
  });

  test('keyword fallback answer (AI service down) is still readable', () {
    final result = CvExtraction.fromJson({
      'language': 'unknown',
      'semanticEnabled': false,
      'skills': [{'id': 1, 'name': 'Flutter', 'confidence': 0.7, 'method': 'keyword', 'evidence': 'flutter'}],
      'otherSkills': null,
    });
    expect(result.semanticEnabled, isFalse);
    expect(result.skills.single.foundByAi, isFalse);
    expect(result.otherSkills, isEmpty);
  });

  test('parses the AI CV assistant answer', () {
    final analysis = CvAnalysis.fromJson({
      'improvedCV': 'SUMMARY\nFlutter developer…',
      'summary': 'Strong mobile profile',
      'suggestions': ['Add metrics'],
      'missingSkills': ['Testing'],
      'strengthAreas': ['Flutter'],
    });
    expect(analysis.improvedCv, startsWith('SUMMARY'));
    expect(analysis.missingSkills, ['Testing']);
  });
}
