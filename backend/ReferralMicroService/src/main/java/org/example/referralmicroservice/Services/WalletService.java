package org.example.referralmicroservice.Services;

import org.example.referralmicroservice.Entities.RewardTransaction;
import org.example.referralmicroservice.Entities.UserWallet;
import org.example.referralmicroservice.Repositories.RewardTransactionRepository;
import org.example.referralmicroservice.Repositories.UserWalletRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class WalletService {

    @Autowired
    private UserWalletRepository walletRepository;

    @Autowired
    private RewardTransactionRepository transactionRepository;

    // Reward amounts by tier
    private static final Map<UserWallet.TierLevel, Double> TIER_REWARDS = new HashMap<>() {{
        put(UserWallet.TierLevel.BRONZE, 25.0);    // 10 certs
        put(UserWallet.TierLevel.SILVER, 50.0);    // 20 certs
        put(UserWallet.TierLevel.GOLD, 100.0);     // 30 certs
        put(UserWallet.TierLevel.PLATINUM, 200.0); // 50 certs
        put(UserWallet.TierLevel.DIAMOND, 500.0);  // 100 certs
    }};

    // Get or create wallet for user
    public UserWallet getOrCreateWallet(Long userId) {
        return walletRepository.findByUserId(userId)
                .orElseGet(() -> {
                    UserWallet wallet = new UserWallet();
                    wallet.setUserId(userId);
                    return walletRepository.save(wallet);
                });
    }

    // Get wallet by user ID
    public UserWallet getWallet(Long userId) {
        return walletRepository.findByUserId(userId)
                .orElseThrow(() -> new RuntimeException("Wallet not found for user: " + userId));
    }

    // Check and award rewards for certification
    @Transactional
    public RewardTransaction checkAndAwardRewards(Long userId, Integer score) {
        UserWallet wallet = getOrCreateWallet(userId);
        
        // Check if score qualifies for reward
        if (score < 70) {
            return null; // No reward for scores below 70%
        }

        // Get previous tier
        UserWallet.TierLevel previousTier = wallet.getCurrentTier();
        
        // Increment certifications
        wallet.incrementCertifications();
        
        // Get new tier
        UserWallet.TierLevel newTier = wallet.getCurrentTier();
        
        // Check if tier changed (milestone reached)
        if (newTier != previousTier && newTier != UserWallet.TierLevel.NONE) {
            // Check if reward already given for this tier
            if (!transactionRepository.existsByUserIdAndTier(userId, newTier)) {
                // Calculate reward based on score quality
                Double baseReward = TIER_REWARDS.get(newTier);
                Double actualReward = calculateRewardByScore(baseReward, score);
                
                // Award the reward
                wallet.addEarnings(actualReward);
                walletRepository.save(wallet);
                
                // Create transaction record
                RewardTransaction transaction = new RewardTransaction(
                    userId,
                    actualReward,
                    RewardTransaction.RewardType.TIER_BONUS,
                    wallet.getCertificationsCount(),
                    newTier,
                    String.format("Reached %s tier with %d certifications! Score: %d%%", 
                                newTier, wallet.getCertificationsCount(), score)
                );
                
                return transactionRepository.save(transaction);
            }
        }
        
        // Save wallet even if no reward (to update certification count)
        walletRepository.save(wallet);
        return null;
    }

    // Calculate reward based on score quality
    private Double calculateRewardByScore(Double baseReward, Integer score) {
        if (score >= 90) {
            return baseReward; // Full reward for excellent (90-100%)
        } else if (score >= 80) {
            return baseReward * 0.8; // 80% reward for good (80-89%)
        } else if (score >= 70) {
            return baseReward * 0.5; // 50% reward for average (70-79%)
        }
        return 0.0; // No reward below 70%
    }

    // Get user's transaction history
    public List<RewardTransaction> getTransactionHistory(Long userId) {
        return transactionRepository.findByUserIdOrderByCreatedAtDesc(userId);
    }

    // Get wallet statistics
    public Map<String, Object> getWalletStats(Long userId) {
        UserWallet wallet = getWallet(userId);
        
        Map<String, Object> stats = new HashMap<>();
        stats.put("balance", wallet.getBalance());
        stats.put("totalEarned", wallet.getTotalEarned());
        stats.put("totalDonated", wallet.getTotalDonated());
        stats.put("totalReceived", wallet.getTotalReceived());
        stats.put("certificationsCount", wallet.getCertificationsCount());
        stats.put("currentTier", wallet.getCurrentTier());
        stats.put("nextTier", getNextTier(wallet.getCurrentTier()));
        stats.put("certificationsToNextTier", getCertificationsToNextTier(wallet.getCertificationsCount()));
        stats.put("nextTierReward", getNextTierReward(wallet.getCurrentTier()));
        
        return stats;
    }

    // Helper: Get next tier
    private UserWallet.TierLevel getNextTier(UserWallet.TierLevel currentTier) {
        switch (currentTier) {
            case NONE: return UserWallet.TierLevel.BRONZE;
            case BRONZE: return UserWallet.TierLevel.SILVER;
            case SILVER: return UserWallet.TierLevel.GOLD;
            case GOLD: return UserWallet.TierLevel.PLATINUM;
            case PLATINUM: return UserWallet.TierLevel.DIAMOND;
            case DIAMOND: return null; // Max tier
            default: return UserWallet.TierLevel.BRONZE;
        }
    }

    // Helper: Get certifications needed for next tier
    private Integer getCertificationsToNextTier(Integer currentCount) {
        if (currentCount < 10) return 10 - currentCount;
        if (currentCount < 20) return 20 - currentCount;
        if (currentCount < 30) return 30 - currentCount;
        if (currentCount < 50) return 50 - currentCount;
        if (currentCount < 100) return 100 - currentCount;
        return 0; // Max tier reached
    }

    // Helper: Get next tier reward amount
    private Double getNextTierReward(UserWallet.TierLevel currentTier) {
        UserWallet.TierLevel nextTier = getNextTier(currentTier);
        return nextTier != null ? TIER_REWARDS.get(nextTier) : 0.0;
    }

    // Get leaderboards
    public List<UserWallet> getTopEarners() {
        return walletRepository.findTop10ByOrderByTotalEarnedDesc();
    }

    public List<UserWallet> getTopDonors() {
        return walletRepository.findTop10ByOrderByTotalDonatedDesc();
    }

    public List<UserWallet> getTopLearners() {
        return walletRepository.findTop10ByOrderByCertificationsCountDesc();
    }

    // Get platform statistics
    public Map<String, Object> getPlatformStats() {
        Map<String, Object> stats = new HashMap<>();
        stats.put("totalEarned", walletRepository.getTotalEarnedPlatform());
        stats.put("totalDonated", walletRepository.getTotalDonatedPlatform());
        stats.put("totalBalance", walletRepository.getTotalBalancePlatform());
        stats.put("activeDonors", walletRepository.getActiveDonorsCount());
        stats.put("totalUsers", walletRepository.count());
        
        return stats;
    }

    // Award referral bonus to referrer
    @Transactional
    public RewardTransaction awardReferralBonus(Long referrerUserId, Long referredUserId) {
        UserWallet wallet = getOrCreateWallet(referrerUserId);
        
        // Award $1.00 for each successful referral
        Double referralReward = 1.0;
        
        wallet.addEarnings(referralReward);
        walletRepository.save(wallet);
        
        // Create transaction record
        RewardTransaction transaction = new RewardTransaction(
            referrerUserId,
            referralReward,
            RewardTransaction.RewardType.REFERRAL_BONUS,
            wallet.getCertificationsCount(),
            wallet.getCurrentTier(),
            String.format("Referral bonus for User #%d subscribing", referredUserId)
        );
        
        return transactionRepository.save(transaction);
    }
}
