package org.example.paiementms.Entities;


public enum EscrowStatus {
    PENDING,        // contract created, waiting for funding
    LOCKED,         // client money moved to escrow after signing
    PARTIAL_PAID,   // some tasks paid, remaining still locked
    RELEASED,       // all tasks paid, escrow fully released
    REFUNDED,       // dispute resolved, money back to client
    DISPUTED,       // in dispute
    CANCELLED       // contract cancelled before locking
}
