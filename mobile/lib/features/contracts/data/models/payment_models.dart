import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../../../core/utils/json_utils.dart';

part 'payment_models.g.dart';

// Models of paiementMS (`/api/payments/**`, `/api/disputes/**`). Amounts are USD.

@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum WalletType { client, freelancer, escrow, unknown }

@JsonSerializable(createToJson: false)
class Wallet {
  const Wallet({required this.id, required this.userId, required this.balance, this.walletType, this.currency = 'USD'});

  final int id;
  final int userId;
  @JsonKey(defaultValue: 0)
  final double balance;
  @JsonKey(unknownEnumValue: WalletType.unknown)
  final WalletType? walletType;
  final String currency;

  factory Wallet.fromJson(Map<String, dynamic> json) => _$WalletFromJson(json);
}

@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum EscrowStatus {
  pending('Waiting for funds', Icons.hourglass_empty),
  locked('Held in escrow', Icons.lock_outline),
  partialPaid('Partly paid', Icons.timelapse),
  released('Paid to the freelancer', Icons.check_circle_outline),
  refunded('Refunded to the client', Icons.undo),
  disputed('In dispute', Icons.gavel),
  cancelled('Cancelled', Icons.block),
  unknown('Unknown', Icons.help_outline);

  const EscrowStatus(this.label, this.icon);

  final String label;
  final IconData icon;

  bool get isClosed => this == released || this == refunded || this == cancelled;
}

/// Money of a contract, held by the platform between the signature and the end of the job.
@JsonSerializable(createToJson: false)
class Escrow {
  const Escrow({
    required this.id,
    required this.contractId,
    required this.totalAmount,
    this.releasedAmount = 0,
    this.status = EscrowStatus.pending,
    this.lockedAt,
    this.releasedAt,
    this.clientUserId,
    this.freelancerUserId,
  });

  final int id;
  final int contractId;
  @JsonKey(defaultValue: 0)
  final double totalAmount;
  final double releasedAmount;
  @JsonKey(unknownEnumValue: EscrowStatus.unknown)
  final EscrowStatus status;
  @JsonKey(fromJson: parseApiDate)
  final DateTime? lockedAt;
  @JsonKey(fromJson: parseApiDate)
  final DateTime? releasedAt;
  @JsonKey(readValue: _readClientUserId)
  final int? clientUserId;
  @JsonKey(readValue: _readFreelancerUserId)
  final int? freelancerUserId;

  double get remainingAmount => totalAmount - releasedAmount;

  factory Escrow.fromJson(Map<String, dynamic> json) => _$EscrowFromJson(json);
}

@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum TransactionType {
  topUp('Money added', Icons.add_card),
  escrowLock('Locked in escrow', Icons.lock_outline),
  taskPayout('Payment', Icons.payments_outlined),
  refund('Refund', Icons.undo),
  withdrawal('Withdrawal', Icons.account_balance_outlined),
  unknown('Transaction', Icons.swap_horiz);

  const TransactionType(this.label, this.icon);

  final String label;
  final IconData icon;
}

@JsonSerializable(createToJson: false)
class WalletTransaction {
  const WalletTransaction({
    required this.id,
    required this.type,
    required this.amount,
    this.description,
    this.createdAt,
    this.referenceId,
    this.fromUserId,
    this.toUserId,
  });

  final int id;
  @JsonKey(unknownEnumValue: TransactionType.unknown)
  final TransactionType type;
  @JsonKey(defaultValue: 0)
  final double amount;
  final String? description;
  @JsonKey(fromJson: parseApiDate)
  final DateTime? createdAt;

  /// Contract id for escrow locks and payouts.
  final int? referenceId;
  @JsonKey(readValue: _readFromUserId)
  final int? fromUserId;
  @JsonKey(readValue: _readToUserId)
  final int? toUserId;

  /// Money coming into [userId]'s wallet (vs. going out).
  bool isIncomingFor(int userId) => toUserId == userId;

  factory WalletTransaction.fromJson(Map<String, dynamic> json) => _$WalletTransactionFromJson(json);
}

@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum DisputeStatus {
  open('Open'),
  inReview('Under review'),
  resolvedClient('Resolved: refunded to the client'),
  resolvedFreelancer('Resolved: paid to the freelancer'),
  resolvedSplit('Resolved: split'),
  unknown('Unknown');

  const DisputeStatus(this.label);

  final String label;

  bool get isOpen => this == open || this == inReview;
}

@JsonSerializable(createToJson: false)
class Dispute {
  const Dispute({
    required this.id,
    required this.contractId,
    required this.reason,
    this.raisedByUserId,
    this.againstUserId,
    this.status = DisputeStatus.open,
    this.createdAt,
    this.resolvedAt,
  });

  final int id;
  final int contractId;
  @JsonKey(defaultValue: '')
  final String reason;
  final int? raisedByUserId;
  final int? againstUserId;
  @JsonKey(unknownEnumValue: DisputeStatus.unknown)
  final DisputeStatus status;
  @JsonKey(fromJson: parseApiDate)
  final DateTime? createdAt;
  @JsonKey(fromJson: parseApiDate)
  final DateTime? resolvedAt;

  factory Dispute.fromJson(Map<String, dynamic> json) => _$DisputeFromJson(json);
}

Object? _userIdOf(Object? wallet) => wallet is Map ? wallet['userId'] : null;
Object? _readClientUserId(Map<dynamic, dynamic> json, String key) => _userIdOf(json['clientWallet']);
Object? _readFreelancerUserId(Map<dynamic, dynamic> json, String key) => _userIdOf(json['freelancerWallet']);
Object? _readFromUserId(Map<dynamic, dynamic> json, String key) => _userIdOf(json['fromWallet']);
Object? _readToUserId(Map<dynamic, dynamic> json, String key) => _userIdOf(json['toWallet']);
