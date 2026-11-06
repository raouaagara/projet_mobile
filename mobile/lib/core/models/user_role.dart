import 'package:json_annotation/json_annotation.dart';

/// Mirrors `Role` in UserMicroService.
enum UserRole {
  @JsonValue('CLIENT')
  client,
  @JsonValue('FREELANCER')
  freelancer,
  @JsonValue('ADMIN')
  admin,
  unknown;

  /// Value expected by the backend (`CLIENT`, `FREELANCER`, `ADMIN`).
  String get apiValue => name.toUpperCase();

  static UserRole fromApi(String? value) => switch (value?.toUpperCase()) {
        'CLIENT' => UserRole.client,
        'FREELANCER' => UserRole.freelancer,
        'ADMIN' => UserRole.admin,
        _ => UserRole.unknown,
      };
}
