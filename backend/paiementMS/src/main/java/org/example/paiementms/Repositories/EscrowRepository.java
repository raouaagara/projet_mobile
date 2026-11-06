package org.example.paiementms.Repositories;

import org.example.paiementms.Entities.Escrow;
import org.example.paiementms.Entities.EscrowStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface EscrowRepository extends JpaRepository<Escrow, Long> {
    Optional<Escrow> findByContractId(Long contractId);
    List<Escrow> findByClientWalletUserIdOrderByCreatedAtDesc(Long clientUserId);
    List<Escrow> findByFreelancerWalletUserIdOrderByCreatedAtDesc(Long freelancerUserId);
    List<Escrow> findByStatus(EscrowStatus status);
    List<Escrow> findByClientWalletUserId(Long userId);
    List<Escrow> findByFreelancerWalletUserId(Long userId);
}
