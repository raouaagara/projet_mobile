package org.example.paiementms.Repositories;

import org.example.paiementms.Entities.Transaction;
import org.example.paiementms.Entities.Wallet;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface TransactionRepository extends JpaRepository<Transaction, Long> {
    List<Transaction> findByFromWalletOrToWalletOrderByCreatedAtDesc(Wallet from, Wallet to);
    List<Transaction> findByReferenceIdOrderByCreatedAtDesc(Long referenceId);
    List<Transaction> findByToWalletOrFromWalletOrderByCreatedAtDesc(Wallet toWallet, Wallet fromWallet);
    List<Transaction> findByFromWalletUserIdOrToWalletUserId(Long userId, Long userId2);
}
