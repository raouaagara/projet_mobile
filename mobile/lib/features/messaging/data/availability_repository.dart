import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_provider.dart';
import 'models/availability_models.dart';

final availabilityRepositoryProvider = Provider((ref) => AvailabilityRepository(ref.watch(dioProvider)));

/// Freelancer availability (`/Referral/availability/**`). Every method throws [ApiException] on failure.
class AvailabilityRepository {
  AvailabilityRepository(this._dio);

  final Dio _dio;
  static const _base = '/Referral/availability';

  Future<T> _call<T>(Future<T> Function() request) async {
    try {
      return await request();
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  /// The user's profile, created with [timezone] the first time.
  Future<AvailabilityProfile> fetchOrCreate(int userId, String timezone) => _call(() async {
    final res = await _dio.get<Map<String, dynamic>>(
      '$_base/profile/$userId/or-create',
      queryParameters: {'timezone': timezone},
    );
    return AvailabilityProfile.fromJson(res.data!);
  });

  Future<AvailabilityProfile> update(AvailabilityProfile profile) => _call(() async {
    final res = await _dio.put<Map<String, dynamic>>('$_base/profiles/${profile.id}', data: profile.toJson());
    return AvailabilityProfile.fromJson(res.data!);
  });

  /// "Last seen" = now. Fails if the user has no profile (not a freelancer): callers ignore it.
  Future<void> heartbeat(int userId) => _call(() => _dio.put<void>('$_base/profiles/heartbeat/$userId'));

  Future<List<AvailabilitySlot>> fetchSlots(int profileId) => _call(() async {
    final res = await _dio.get<List<dynamic>>('$_base/profiles/$profileId/slots');
    return _slots(res.data);
  });

  Future<List<AvailabilitySlot>> fetchSlotsOfUser(int userId) => _call(() async {
    final res = await _dio.get<List<dynamic>>('$_base/users/$userId/slots');
    return _slots(res.data);
  });

  Future<AvailabilitySlot> addSlot(int profileId, AvailabilitySlot slot) => _call(() async {
    final res = await _dio.post<Map<String, dynamic>>('$_base/profiles/$profileId/slots', data: slot.toJson());
    return AvailabilitySlot.fromJson(res.data!);
  });

  Future<void> deleteSlot(int slotId) => _call(() => _dio.delete<void>('$_base/slots/$slotId'));

  /// Every freelancer's zone and status (for the client's world clock).
  Future<List<AvailabilityProfile>> fetchWorldView() => _call(() async {
    final res = await _dio.get<List<dynamic>>('$_base/world-view');
    return res.data!.map((e) => AvailabilityProfile.fromJson(e as Map<String, dynamic>)).toList();
  });

  List<AvailabilitySlot> _slots(List<dynamic>? data) =>
      data!.map((e) => AvailabilitySlot.fromJson(e as Map<String, dynamic>)).toList()..sort(
        (a, b) => a.dayOfWeek.index != b.dayOfWeek.index
            ? a.dayOfWeek.index.compareTo(b.dayOfWeek.index)
            : a.startTime.compareTo(b.startTime),
      );
}
