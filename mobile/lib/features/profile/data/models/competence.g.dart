// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'competence.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Competence _$CompetenceFromJson(Map<String, dynamic> json) => Competence(
  id: (json['id'] as num).toInt(),
  name: json['nom'] as String? ?? '',
  description: json['description'] as String?,
  category: json['categorie'] as String?,
  level: json['niveau'] as String?,
);
