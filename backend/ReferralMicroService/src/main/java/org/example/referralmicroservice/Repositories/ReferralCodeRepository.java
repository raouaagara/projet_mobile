package org.example.referralmicroservice.Repositories;

import org.example.referralmicroservice.Entities.ReferralCode;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface ReferralCodeRepository extends JpaRepository<ReferralCode, Long> {
    Optional<ReferralCode> findByUserId(Long userId);
    Optional<ReferralCode> findByCode(String code);
}
