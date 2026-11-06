// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Wallet _$WalletFromJson(Map<String, dynamic> json) => Wallet(
  id: (json['id'] as num).toInt(),
  userId: (json['userId'] as num).toInt(),
  balance: (json['balance'] as num?)?.toDouble() ?? 0,
  walletType: $enumDecodeNullable(
    _$WalletTypeEnumMap,
    json['walletType'],
    unknownValue: WalletType.unknown,
  ),
  currency: json['currency'] as String? ?? 'USD',
);

const _$WalletTypeEnumMap = {
  WalletType.client: 'CLIENT',
  WalletType.freelancer: 'FREELANCER',
  WalletType.escrow: 'ESCROW',
  WalletType.unknown: 'UNKNOWN',
};

Escrow _$EscrowFromJson(Map<String, dynamic> json) => Escrow(
  id: (json['id'] as num).toInt(),
  contractId: (json['contractId'] as num).toInt(),
  totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
  releasedAmount: (json['releasedAmount'] as num?)?.toDouble() ?? 0,
  status:
      $enumDecodeNullable(
        _$EscrowStatusEnumMap,
        json['status'],
        unknownValue: EscrowStatus.unknown,
      ) ??
      EscrowStatus.pending,
  lockedAt: parseApiDate(json['lockedAt']),
  releasedAt: parseApiDate(json['releasedAt']),
  clientUserId: (_readClientUserId(json, 'clientUserId') as num?)?.toInt(),
  freelancerUserId: (_readFreelancerUserId(json, 'freelancerUserId') as num?)
      ?.toInt(),
);

const _$EscrowStatusEnumMap = {
  EscrowStatus.pending: 'PENDING',
  EscrowStatus.locked: 'LOCKED',
  EscrowStatus.partialPaid: 'PARTIAL_PAID',
  EscrowStatus.released: 'RELEASED',
  EscrowStatus.refunded: 'REFUNDED',
  EscrowStatus.disputed: 'DISPUTED',
  EscrowStatus.cancelled: 'CANCELLED',
  EscrowStatus.unknown: 'UNKNOWN',
};

WalletTransaction _$WalletTransactionFromJson(Map<String, dynamic> json) =>
    WalletTransaction(
      id: (json['id'] as num).toInt(),
      type: $enumDecode(
        _$TransactionTypeEnumMap,
        json['type'],
        unknownValue: TransactionType.unknown,
      ),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      description: json['description'] as String?,
      createdAt: parseApiDate(json['createdAt']),
      referenceId: (json['referenceId'] as num?)?.toInt(),
      fromUserId: (_readFromUserId(json, 'fromUserId') as num?)?.toInt(),
      toUserId: (_readToUserId(json, 'toUserId') as num?)?.toInt(),
    );

const _$TransactionTypeEnumMap = {
  TransactionType.topUp: 'TOP_UP',
  TransactionType.escrowLock: 'ESCROW_LOCK',
  TransactionType.taskPayout: 'TASK_PAYOUT',
  TransactionType.refund: 'REFUND',
  TransactionType.withdrawal: 'WITHDRAWAL',
  TransactionType.unknown: 'UNKNOWN',
};

Dispute _$DisputeFromJson(Map<String, dynamic> json) => Dispute(
  id: (json['id'] as num).toInt(),
  contractId: (json['contractId'] as num).toInt(),
  reason: json['reason'] as String? ?? '',
  raisedByUserId: (json['raisedByUserId'] as num?)?.toInt(),
  againstUserId: (json['againstUserId'] as num?)?.toInt(),
  status:
      $enumDecodeNullable(
        _$DisputeStatusEnumMap,
        json['status'],
        unknownValue: DisputeStatus.unknown,
      ) ??
      DisputeStatus.open,
  createdAt: parseApiDate(json['createdAt']),
  resolvedAt: parseApiDate(json['resolvedAt']),
);

const _$DisputeStatusEnumMap = {
  DisputeStatus.open: 'OPEN',
  DisputeStatus.inReview: 'IN_REVIEW',
  DisputeStatus.resolvedClient: 'RESOLVED_CLIENT',
  DisputeStatus.resolvedFreelancer: 'RESOLVED_FREELANCER',
  DisputeStatus.resolvedSplit: 'RESOLVED_SPLIT',
  DisputeStatus.unknown: 'UNKNOWN',
};
