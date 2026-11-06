import 'package:json_annotation/json_annotation.dart';

import '../../../../core/utils/json_utils.dart';

part 'review.g.dart';

/// A rating left after a contract (MS_CompetenceAndReview `Review`).
/// `clientId` / `freelancerId` are strings on the backend.
@JsonSerializable(includeIfNull: false)
class Review {
  const Review({
    this.id,
    required this.description,
    required this.rating,
    this.projectId,
    this.clientId,
    this.freelancerId,
    this.reviewerRole,
    this.createdAt,
  });

  final int? id;
  @JsonKey(defaultValue: '')
  final String description;
  @JsonKey(defaultValue: 0)
  final int rating;
  final int? projectId;
  @JsonKey(fromJson: _idToString)
  final String? clientId;
  @JsonKey(fromJson: _idToString)
  final String? freelancerId;

  /// `CLIENT` when a client reviews a freelancer, `FREELANCER` for the opposite.
  final String? reviewerRole;
  @JsonKey(fromJson: parseApiDate, includeToJson: false)
  final DateTime? createdAt;

  /// Id of the person who wrote the review.
  int? get authorId => int.tryParse(
      (reviewerRole == 'FREELANCER' ? freelancerId : clientId) ?? '');

  factory Review.fromJson(Map<String, dynamic> json) => _$ReviewFromJson(json);
  Map<String, dynamic> toJson() => _$ReviewToJson(this);
}

String? _idToString(Object? value) => value?.toString();

double averageRating(List<Review> reviews) => reviews.isEmpty
    ? 0
    : reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;
