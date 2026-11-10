import 'package:catchopp_mobile/core/models/app_user.dart';
import 'package:catchopp_mobile/core/models/user_role.dart';
import 'package:catchopp_mobile/features/profile/data/leaderboard.dart';
import 'package:catchopp_mobile/features/profile/data/models/competence.dart';
import 'package:catchopp_mobile/features/profile/data/models/review.dart';
import 'package:catchopp_mobile/features/profile/data/models/skill_test.dart';
import 'package:catchopp_mobile/features/profile/profile_paths.dart';
import 'package:flutter_test/flutter_test.dart';

AppUser user(int id, UserRole role) =>
    AppUser(id: id, firstName: 'U$id', lastName: '', email: '$id@mail.com', role: role);

Review review(String freelancerId, int rating, {String role = 'CLIENT'}) => Review(
      description: 'Great work',
      rating: rating,
      clientId: '1',
      freelancerId: freelancerId,
      reviewerRole: role,
    );

void main() {
  group('Review', () {
    test('parses string or numeric ids and finds the author', () {
      final r = Review.fromJson({
        'id': 3,
        'description': 'Solid',
        'rating': 4,
        'clientId': 12,
        'freelancerId': '7',
        'reviewerRole': 'CLIENT',
        'createdAt': '2026-05-01T09:00:00',
      });
      expect(r.clientId, '12');
      expect(r.authorId, 12);
      expect(r.createdAt, DateTime(2026, 5, 1, 9));
    });

    test('does not send id, createdAt or null fields', () {
      final json = review('7', 5).toJson();
      expect(json.containsKey('id'), isFalse);
      expect(json.containsKey('createdAt'), isFalse);
      expect(json.containsKey('projectId'), isFalse);
      expect(json['freelancerId'], '7');
    });

    test('averageRating', () {
      expect(averageRating([]), 0);
      expect(averageRating([review('7', 5), review('7', 4)]), 4.5);
    });
  });

  test('Competence maps the French backend field names', () {
    final c = Competence.fromJson({'id': 1, 'nom': 'Flutter', 'categorie': 'Mobile', 'niveau': 'Expert'});
    expect(c.name, 'Flutter');
    expect(c.category, 'Mobile');
    expect(c.level, 'Expert');
  });

  test('TestQuestion.options skips empty options', () {
    final q = TestQuestion.fromJson({
      'id': 1,
      'questionText': 'UX?',
      'optionA': 'User Experience',
      'optionB': 'User Export',
      'optionC': ' ',
      'optionD': null,
    });
    expect(q.options, [('A', 'User Experience'), ('B', 'User Export')]);
  });

  group('buildLeaderboard', () {
    test('ranks freelancers by average rating, then review count', () {
      final users = [
        user(1, UserRole.client),
        user(7, UserRole.freelancer),
        user(8, UserRole.freelancer),
        user(9, UserRole.freelancer),
      ];
      final reviews = [
        review('7', 4), review('7', 4), // 4.0 average, 2 reviews
        review('8', 5), // 5.0 average
        review('9', 4), // 4.0 average, 1 review
        review('9', 1, role: 'FREELANCER'), // written BY the freelancer: ignored
      ];

      final ranking = buildLeaderboard(users, reviews);

      expect(ranking.map((e) => e.user.id), [8, 7, 9]);
      expect(ranking.first.averageRating, 5);
      expect(ranking[2].reviewCount, 1);
    });

    test('ignores clients and unreviewed freelancers', () {
      expect(buildLeaderboard([user(1, UserRole.client), user(7, UserRole.freelancer)], []), isEmpty);
    });
  });

  test('ProfilePaths.review builds the query string', () {
    expect(ProfilePaths.review(userId: 7), '/profile/review?userId=7');
    expect(ProfilePaths.review(userId: 7, projectId: 3), '/profile/review?userId=7&projectId=3');
  });
}
