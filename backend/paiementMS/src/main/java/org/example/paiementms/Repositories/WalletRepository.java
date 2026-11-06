package org.example.paiementms.Repositories;

import org.example.paiementms.Entities.Wallet;
import org.example.paiementms.Entities.WalletType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface WalletRepository extends JpaRepository<Wallet, Long> {
    Optional<Wallet> findByUserId(Long userId);
    Optional<Wallet> findByUserIdAndWalletType(Long userId, WalletType type);
    Optional<Wallet> findByWalletType(WalletType type); // for the single ESCROW system wallet
    boolean existsByUserId(Long userId);



}
