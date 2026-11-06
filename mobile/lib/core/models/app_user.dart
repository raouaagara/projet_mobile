import 'package:json_annotation/json_annotation.dart';

import '../utils/json_utils.dart';
import 'user_role.dart';

part 'app_user.g.dart';

/// A user as returned by UserMicroService (`GET /users/{id}`).
///
/// Shared by every module (names in contracts, chat, reviews...).
/// This file is also the reference example for writing models:
/// after editing it, run `dart run build_runner build`.
@JsonSerializable()
class AppUser {
  const AppUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    this.location,
    this.bio,
    this.profilePictureUrl,
    this.coverPictureUrl,
    this.linkedinUrl,
    this.website,
    this.cvFileName,
    this.competenceIds = const [],
    this.createdAt,
  });

  final int id;
  @JsonKey(defaultValue: '')
  final String firstName;
  @JsonKey(defaultValue: '')
  final String lastName;
  @JsonKey(defaultValue: '')
  final String email;
  @JsonKey(unknownEnumValue: UserRole.unknown)
  final UserRole role;
  final String? location;
  final String? bio;

  /// Base64 data URI or http URL — display it with `imageFromApi()`.
  final String? profilePictureUrl;
  final String? coverPictureUrl;
  final String? linkedinUrl;
  final String? website;
  final String? cvFileName;
  @JsonKey(defaultValue: [])
  final List<int> competenceIds;
  @JsonKey(fromJson: parseApiDate, includeToJson: false)
  final DateTime? createdAt;

  String get fullName => '$firstName $lastName'.trim();

  String get initials {
    final first = firstName.isNotEmpty ? firstName[0] : '';
    final last = lastName.isNotEmpty ? lastName[0] : '';
    final value = '$first$last'.toUpperCase();
    return value.isEmpty ? '?' : value;
  }

  factory AppUser.fromJson(Map<String, dynamic> json) =>
      _$AppUserFromJson(json);

  Map<String, dynamic> toJson() => _$AppUserToJson(this);
}
