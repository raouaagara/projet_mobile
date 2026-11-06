import 'package:json_annotation/json_annotation.dart';

import '../../../../core/utils/json_utils.dart';

part 'referral_models.g.dart';

/// Someone who joined with the user's code (ReferralMicroService `Referral`).
@JsonSerializable(createToJson: false)
class Referral {
  const Referral({required this.id, this.referredUserId, this.referralCode, this.status, this.referredAt});

  final int id;
  final int? referredUserId;
  final String? referralCode;
  final String? status;
  @JsonKey(fromJson: parseApiDate)
  final DateTime? referredAt;

  factory Referral.fromJson(Map<String, dynamic> json) => _$ReferralFromJson(json);
}

@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum RewardTier {
  none('No tier'),
  bronze('Bronze'),
  silver('Silver'),
  gold('Gold'),
  platinum('Platinum'),
  diamond('Diamond');

  const RewardTier(this.label);

  final String label;
}

/// Reward money earned on the platform (referrals, certification tiers); can be donated.
/// Not the same as module 3's payment wallet.
@JsonSerializable(createToJson: false)
class RewardWallet {
  const RewardWallet({
    required this.userId,
    this.balance = 0,
    this.totalEarned = 0,
    this.totalDonated = 0,
    this.totalReceived = 0,
    this.certificationsCount = 0,
    this.currentTier = RewardTier.none,
  });

  final int userId;
  @JsonKey(defaultValue: 0)
  final double balance;
  @JsonKey(defaultValue: 0)
  final double totalEarned;
  @JsonKey(defaultValue: 0)
  final double totalDonated;
  @JsonKey(defaultValue: 0)
  final double totalReceived;
  @JsonKey(defaultValue: 0)
  final int certificationsCount;
  @JsonKey(unknownEnumValue: RewardTier.none)
  final RewardTier currentTier;

  factory RewardWallet.fromJson(Map<String, dynamic> json) => _$RewardWalletFromJson(json);
}

@JsonSerializable(createToJson: false)
class RewardTransaction {
  const RewardTransaction({required this.id, required this.amount, this.type, this.description, this.createdAt});

  final int id;
  @JsonKey(defaultValue: 0)
  final double amount;

  /// REFERRAL_BONUS, TIER_BONUS, CERTIFICATION_REWARD...
  final String? type;
  final String? description;
  @JsonKey(fromJson: parseApiDate)
  final DateTime? createdAt;

  String get typeLabel => switch (type) {
    'REFERRAL_BONUS' => 'Referral bonus',
    'TIER_BONUS' => 'Tier bonus',
    'CERTIFICATION_REWARD' => 'Certification reward',
    'CHALLENGE_REWARD' => 'Challenge reward',
    'ADMIN_BONUS' => 'Bonus',
    _ => 'Reward',
  };

  factory RewardTransaction.fromJson(Map<String, dynamic> json) => _$RewardTransactionFromJson(json);
}

@JsonSerializable(createToJson: false)
class Donation {
  const Donation({
    required this.id,
    required this.donorId,
    required this.recipientId,
    required this.amount,
    this.message,
    this.isAnonymous = false,
    this.status,
    this.createdAt,
  });

  final int id;
  final int donorId;
  final int recipientId;
  @JsonKey(defaultValue: 0)
  final double amount;
  final String? message;
  @JsonKey(defaultValue: false)
  final bool isAnonymous;
  final String? status;
  @JsonKey(fromJson: parseApiDate)
  final DateTime? createdAt;

  factory Donation.fromJson(Map<String, dynamic> json) => _$DonationFromJson(json);
}
