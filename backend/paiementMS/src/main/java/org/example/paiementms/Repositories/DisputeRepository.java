package org.example.paiementms.Repositories;

import org.example.paiementms.Entities.Dispute;
import org.example.paiementms.Entities.DisputeStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface DisputeRepository extends JpaRepository<Dispute, Long> {
    List<Dispute> findByContractId(Long contractId);
    List<Dispute> findByRaisedByUserId(Long userId);
    List<Dispute> findByAgainstUserId(Long userId);
    List<Dispute> findByRaisedByUserIdOrAgainstUserIdOrderByCreatedAtDesc(Long raisedBy, Long against);
    List<Dispute> findByStatus(DisputeStatus status);
}
