package org.example.referralmicroservice.Repositories;

import org.example.referralmicroservice.Entities.RewardTransaction;
import org.example.referralmicroservice.Entities.UserWallet;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface RewardTransactionRepository extends JpaRepository<RewardTransaction, Long> {

    // Find all transactions for a user
    List<RewardTransaction> findByUserIdOrderByCreatedAtDesc(Long userId);

    // Find transactions by type
    List<RewardTransaction> findByUserIdAndType(Long userId, RewardTransaction.RewardType type);

    // Find transactions by tier
    List<RewardTransaction> findByUserIdAndTier(Long userId, UserWallet.TierLevel tier);

    // Check if user has received reward for specific tier
    boolean existsByUserIdAndTier(Long userId, UserWallet.TierLevel tier);

    // Find recent transactions
    List<RewardTransaction> findByCreatedAtAfterOrderByCreatedAtDesc(LocalDateTime date);

    // Get total rewards by type
    @Query("SELECT SUM(r.amount) FROM RewardTransaction r WHERE r.type = :type")
    Double getTotalRewardsByType(RewardTransaction.RewardType type);

    // Get user's total rewards
    @Query("SELECT SUM(r.amount) FROM RewardTransaction r WHERE r.userId = :userId")
    Double getUserTotalRewards(Long userId);

    // Count rewards by tier
    @Query("SELECT COUNT(r) FROM RewardTransaction r WHERE r.tier = :tier")
    Long countRewardsByTier(UserWallet.TierLevel tier);
}
