import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/user_role.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_provider.dart';
import 'models/review.dart';

final reviewRepositoryProvider =
    Provider((ref) => ReviewRepository(ref.watch(dioProvider)));

/// Reviews written *about* a user, newest first:
///   ref.watch(reviewsAboutProvider((userId: 7, role: UserRole.freelancer)))
final reviewsAboutProvider =
    FutureProvider.family<List<Review>, ({int userId, UserRole role})>((ref, key) {
  return ref.watch(reviewRepositoryProvider).fetchAbout(key.userId, key.role);
});

final allReviewsProvider = FutureProvider<List<Review>>(
    (ref) => ref.watch(reviewRepositoryProvider).fetchAll());

/// Review endpoints (`/Review/**`).
class ReviewRepository {
  ReviewRepository(this._dio);

  final Dio _dio;

  Future<List<Review>> fetchAbout(int userId, UserRole role) async {
    // A freelancer is reviewed by clients; a client is reviewed by freelancers.
    final isFreelancer = role == UserRole.freelancer;
    final path = isFreelancer
        ? '/Review/GetReviewsByFreelancer/$userId'
        : '/Review/GetReviewsByClient/$userId';
    try {
      final res = await _dio.get<List<dynamic>>(path);
      final reviews = res.data!.map((e) => Review.fromJson(e as Map<String, dynamic>));
      return reviews
          .where((r) => isFreelancer ? r.reviewerRole != 'FREELANCER' : r.reviewerRole == 'FREELANCER')
          .toList()
        ..sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<List<Review>> fetchAll() async {
    try {
      final res = await _dio.get<List<dynamic>>('/Review/GetAllReview');
      return res.data!.map((e) => Review.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<Review> add(Review review) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>('/Review/AjouterReview', data: review.toJson());
      return Review.fromJson(res.data!);
    } on DioException catch (e) {
      // AI moderation rejection: {"error": "...", "reason": "..."}
      final data = e.response?.data;
      if (data is Map && data['reason'] is String) {
        throw ApiException('${data['error'] ?? 'Review rejected.'}\n${data['reason']}',
            statusCode: e.response?.statusCode);
      }
      throw ApiException.from(e);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  /// AI rewrite of a review draft (grammar, tone). Returns the original on failure server-side.
  Future<String> enhance(String text, int rating) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/Review/enhance',
        data: {'text': text, 'rating': rating},
      );
      return res.data!['enhancedText'] as String? ?? text;
    } catch (e) {
      throw ApiException.from(e);
    }
  }
}
