package org.example.referralmicroservice.Repositories;

import org.example.referralmicroservice.Entities.Referral;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface ReferralRepository extends JpaRepository<Referral, Long> {
    List<Referral> findByReferrerUserId(Long referrerUserId);
    boolean existsByReferredUserId(Long referredUserId);
    Optional<Referral> findByReferralCode(String code);
}
