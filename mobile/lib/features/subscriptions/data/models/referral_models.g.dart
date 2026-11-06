// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'referral_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Referral _$ReferralFromJson(Map<String, dynamic> json) => Referral(
  id: (json['id'] as num).toInt(),
  referredUserId: (json['referredUserId'] as num?)?.toInt(),
  referralCode: json['referralCode'] as String?,
  status: json['status'] as String?,
  referredAt: parseApiDate(json['referredAt']),
);

RewardWallet _$RewardWalletFromJson(Map<String, dynamic> json) => RewardWallet(
  userId: (json['userId'] as num).toInt(),
  balance: (json['balance'] as num?)?.toDouble() ?? 0,
  totalEarned: (json['totalEarned'] as num?)?.toDouble() ?? 0,
  totalDonated: (json['totalDonated'] as num?)?.toDouble() ?? 0,
  totalReceived: (json['totalReceived'] as num?)?.toDouble() ?? 0,
  certificationsCount: (json['certificationsCount'] as num?)?.toInt() ?? 0,
  currentTier:
      $enumDecodeNullable(_$RewardTierEnumMap, json['currentTier'], unknownValue: RewardTier.none) ?? RewardTier.none,
);

const _$RewardTierEnumMap = {
  RewardTier.none: 'NONE',
  RewardTier.bronze: 'BRONZE',
  RewardTier.silver: 'SILVER',
  RewardTier.gold: 'GOLD',
  RewardTier.platinum: 'PLATINUM',
  RewardTier.diamond: 'DIAMOND',
};

RewardTransaction _$RewardTransactionFromJson(Map<String, dynamic> json) => RewardTransaction(
  id: (json['id'] as num).toInt(),
  amount: (json['amount'] as num?)?.toDouble() ?? 0,
  type: json['type'] as String?,
  description: json['description'] as String?,
  createdAt: parseApiDate(json['createdAt']),
);

Donation _$DonationFromJson(Map<String, dynamic> json) => Donation(
  id: (json['id'] as num).toInt(),
  donorId: (json['donorId'] as num).toInt(),
  recipientId: (json['recipientId'] as num).toInt(),
  amount: (json['amount'] as num?)?.toDouble() ?? 0,
  message: json['message'] as String?,
  isAnonymous: json['isAnonymous'] as bool? ?? false,
  status: json['status'] as String?,
  createdAt: parseApiDate(json['createdAt']),
);
