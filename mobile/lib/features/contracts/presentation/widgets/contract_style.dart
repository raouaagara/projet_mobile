import 'package:flutter/material.dart';

import '../../../../shared/widgets/ui_kit.dart';
import '../../data/models/contract.dart';
import '../../data/models/payment_models.dart';

/// Accent of a contract status, for its pill and its round icon.
Color contractStatusColor(ContractStatus status) => switch (status) {
  ContractStatus.draft || ContractStatus.sent => AppAccent.amber,
  ContractStatus.active => AppAccent.blue,
  ContractStatus.completed => AppAccent.green,
  ContractStatus.rejected || ContractStatus.cancelled => AppAccent.red,
  ContractStatus.closed || ContractStatus.unknown => AppAccent.grey,
};

/// Accent of an escrow status.
Color escrowStatusColor(EscrowStatus status) => switch (status) {
  EscrowStatus.pending => AppAccent.amber,
  EscrowStatus.locked || EscrowStatus.partialPaid => AppAccent.blue,
  EscrowStatus.released => AppAccent.green,
  EscrowStatus.refunded => AppAccent.purple,
  EscrowStatus.disputed => AppAccent.red,
  EscrowStatus.cancelled || EscrowStatus.unknown => AppAccent.grey,
};
