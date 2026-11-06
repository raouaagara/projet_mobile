package org.example.projectmicroservice.Repositories;

import org.example.projectmicroservice.Entities.Contract;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ContactRepository extends JpaRepository<Contract, Long> {
    List<Contract> findByClientId(Long clientId);
    List<Contract> findByFreelancerId(Long freelancerId);
    Optional<Contract> findByProposalId(Long proposalId);
}
