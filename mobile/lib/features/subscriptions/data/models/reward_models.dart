import 'package:json_annotation/json_annotation.dart';

import '../../../../core/utils/json_utils.dart';

part 'reward_models.g.dart';

@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum DiscountType { percentage, fixedAmount, freeMonth, unknown }

/// A discount code won or earned by the user (spin wheel, loyalty, referral...).
@JsonSerializable(createToJson: false)
class PromoCode {
  const PromoCode({
    required this.id,
    required this.code,
    this.type,
    this.discountType = DiscountType.unknown,
    this.discountValue = 0,
    this.description,
    this.earnedAt,
    this.expiresAt,
    this.usedAt,
    this.isActive = true,
    this.minSubscriptionCount = 0,
  });

  final int id;
  @JsonKey(defaultValue: '')
  final String code;

  /// SPIN_WHEEL, LOYALTY_3MONTH, STUDENT...
  final String? type;
  @JsonKey(unknownEnumValue: DiscountType.unknown)
  final DiscountType discountType;
  @JsonKey(defaultValue: 0)
  final double discountValue;
  final String? description;
  @JsonKey(fromJson: parseApiDate)
  final DateTime? earnedAt;
  @JsonKey(fromJson: parseApiDate)
  final DateTime? expiresAt;
  @JsonKey(fromJson: parseApiDate)
  final DateTime? usedAt;
  @JsonKey(defaultValue: true)
  final bool isActive;
  @JsonKey(defaultValue: 0)
  final int minSubscriptionCount;

  bool get isUsed => usedAt != null;
  bool isExpired([DateTime? now]) => expiresAt != null && expiresAt!.isBefore(now ?? DateTime.now());
  bool get isUsable => isActive && !isUsed && !isExpired();

  /// "25% off", "$5 off", "1 month free".
  String get label => switch (discountType) {
    DiscountType.percentage => '${_number(discountValue)}% off',
    DiscountType.fixedAmount => '\$${_number(discountValue)} off',
    DiscountType.freeMonth => '1 month free',
    DiscountType.unknown => 'Discount',
  };

  factory PromoCode.fromJson(Map<String, dynamic> json) => _$PromoCodeFromJson(json);
}

String _number(double value) => value == value.roundToDouble() ? value.toInt().toString() : value.toStringAsFixed(2);

@JsonSerializable(createToJson: false)
class SpinStatus {
  const SpinStatus({required this.canSpin, this.daysUntilNextSpin = 0});

  @JsonKey(defaultValue: false)
  final bool canSpin;
  @JsonKey(defaultValue: 0)
  final int daysUntilNextSpin;

  factory SpinStatus.fromJson(Map<String, dynamic> json) => _$SpinStatusFromJson(json);
}

/// A spin: the discount won and its promo code.
@JsonSerializable(createToJson: false)
class SpinAttempt {
  const SpinAttempt({required this.discountWon, this.id, this.attemptDate, this.promoCode});

  final int? id;
  @JsonKey(defaultValue: 0)
  final int discountWon;
  @JsonKey(fromJson: parseApiDate)
  final DateTime? attemptDate;
  final PromoCode? promoCode;

  factory SpinAttempt.fromJson(Map<String, dynamic> json) => _$SpinAttemptFromJson(json);
}

/// The percentages on the wheel (SpinWheelService.POSSIBLE_DISCOUNTS).
const wheelDiscounts = [5, 10, 15, 20, 25];
