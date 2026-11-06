package org.example.referralmicroservice.Repositories;

import org.example.referralmicroservice.Entities.ReferralReward;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ReferralRewardRepository extends JpaRepository<ReferralReward, Long> {
    List<ReferralReward> findByUserId(Long userId);
    List<ReferralReward> findByReferral_Id(Long referralId);
}
