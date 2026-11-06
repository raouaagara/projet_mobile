import 'package:json_annotation/json_annotation.dart';

part 'competence.g.dart';

/// A skill from the admin-managed catalog (MS_CompetenceAndReview `Competance`).
/// Freelancers pick catalog ids, stored in `AppUser.competenceIds`.
@JsonSerializable(createToJson: false)
class Competence {
  const Competence({required this.id, required this.name, this.description, this.category, this.level});

  final int id;
  @JsonKey(name: 'nom', defaultValue: '')
  final String name;
  final String? description;
  @JsonKey(name: 'categorie')
  final String? category;
  @JsonKey(name: 'niveau')
  final String? level;

  factory Competence.fromJson(Map<String, dynamic> json) => _$CompetenceFromJson(json);
}
