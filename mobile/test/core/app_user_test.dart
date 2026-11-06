import 'package:catchopp_mobile/core/models/app_user.dart';
import 'package:catchopp_mobile/core/models/user_role.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses a GET /users/{id} response', () {
    final user = AppUser.fromJson({
      'id': 7,
      'firstName': 'Amna',
      'lastName': 'Ben Ali',
      'email': 'amna@mail.com',
      'role': 'CLIENT',
      'bio': null,
      'competenceIds': [1, 3],
      'createdAt': '2026-03-01T10:15:30',
    });

    expect(user.fullName, 'Amna Ben Ali');
    expect(user.initials, 'AB');
    expect(user.role, UserRole.client);
    expect(user.competenceIds, [1, 3]);
    expect(user.createdAt, DateTime(2026, 3, 1, 10, 15, 30));
  });

  test('tolerates missing fields and unknown roles', () {
    final user = AppUser.fromJson({'id': 1, 'role': 'SUPERVISOR', 'competenceIds': null});

    expect(user.role, UserRole.unknown);
    expect(user.firstName, '');
    expect(user.competenceIds, isEmpty);
  });
}
