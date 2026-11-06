// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reward_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PromoCode _$PromoCodeFromJson(Map<String, dynamic> json) => PromoCode(
  id: (json['id'] as num).toInt(),
  code: json['code'] as String? ?? '',
  type: json['type'] as String?,
  discountType:
      $enumDecodeNullable(_$DiscountTypeEnumMap, json['discountType'], unknownValue: DiscountType.unknown) ??
      DiscountType.unknown,
  discountValue: (json['discountValue'] as num?)?.toDouble() ?? 0,
  description: json['description'] as String?,
  earnedAt: parseApiDate(json['earnedAt']),
  expiresAt: parseApiDate(json['expiresAt']),
  usedAt: parseApiDate(json['usedAt']),
  isActive: json['isActive'] as bool? ?? true,
  minSubscriptionCount: (json['minSubscriptionCount'] as num?)?.toInt() ?? 0,
);

const _$DiscountTypeEnumMap = {
  DiscountType.percentage: 'PERCENTAGE',
  DiscountType.fixedAmount: 'FIXED_AMOUNT',
  DiscountType.freeMonth: 'FREE_MONTH',
  DiscountType.unknown: 'UNKNOWN',
};

SpinStatus _$SpinStatusFromJson(Map<String, dynamic> json) => SpinStatus(
  canSpin: json['canSpin'] as bool? ?? false,
  daysUntilNextSpin: (json['daysUntilNextSpin'] as num?)?.toInt() ?? 0,
);

SpinAttempt _$SpinAttemptFromJson(Map<String, dynamic> json) => SpinAttempt(
  discountWon: (json['discountWon'] as num?)?.toInt() ?? 0,
  id: (json['id'] as num?)?.toInt(),
  attemptDate: parseApiDate(json['attemptDate']),
  promoCode: json['promoCode'] == null ? null : PromoCode.fromJson(json['promoCode'] as Map<String, dynamic>),
);
