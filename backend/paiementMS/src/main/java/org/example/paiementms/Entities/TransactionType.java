package org.example.paiementms.Entities;

public enum TransactionType {
    TOP_UP,          // client adds money to wallet
    ESCROW_LOCK,     // client → escrow (contract signed)
    TASK_PAYOUT,     // escrow → freelancer (task completed)
    REFUND,          // escrow → client (dispute/cancel)
    WITHDRAWAL       // freelancer withdraws from wallet
}
