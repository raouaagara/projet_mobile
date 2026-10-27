package org.example.subscriptionmicroservice.Repositories;

import org.example.subscriptionmicroservice.Entities.UserReward;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface UserRewardRepository extends JpaRepository<UserReward, Long> {
    List<UserReward> findByUserId(Long userId);
    
    List<UserReward> findByUserIdAndNotificationSentFalse(Long userId);
    
    List<UserReward> findByUserIdAndPopupShownFalse(Long userId);
    
    boolean existsByUserIdAndRewardType(Long userId, String rewardType);
}
