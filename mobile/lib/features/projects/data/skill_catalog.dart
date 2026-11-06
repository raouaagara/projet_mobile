import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_provider.dart';

/// A skill from the catalog, for a project's "required skills".
/// (Read-only here; module 1 manages the catalog on profiles.)
class CatalogSkill {
  const CatalogSkill({required this.id, required this.name, this.category});

  final int id;
  final String name;
  final String? category;

  factory CatalogSkill.fromJson(Map<String, dynamic> json) => CatalogSkill(
    id: (json['id'] as num).toInt(),
    name: json['nom'] as String? ?? '',
    category: json['categorie'] as String?,
  );
}

/// id → skill, sorted by name.
final skillCatalogProvider = FutureProvider<Map<int, CatalogSkill>>((ref) async {
  final Dio dio = ref.watch(dioProvider);
  try {
    final res = await dio.get<List<dynamic>>('/Competance/GetAllCompetance');
    final skills = res.data!.map((e) => CatalogSkill.fromJson(e as Map<String, dynamic>)).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return {for (final skill in skills) skill.id: skill};
  } catch (e) {
    throw ApiException.from(e);
  }
});
