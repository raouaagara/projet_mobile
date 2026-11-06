package org.example.subscriptionmicroservice.Services;

import org.example.subscriptionmicroservice.Entities.PromoCode;
import org.example.subscriptionmicroservice.Entities.UserReward;
import org.example.subscriptionmicroservice.Repositories.UserRewardRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Service
public class RewardService {

    @Autowired
    private UserRewardRepository userRewardRepository;

    @Autowired
    private PromoCodeService promoCodeService;

    @Autowired
    private EmailService emailService;

    // Award loyalty reward (3 months)
    public UserReward awardLoyalty3Month(Long userId) {
        if (userRewardRepository.existsByUserIdAndRewardType(userId, "LOYALTY_3MONTH")) {
            return null; // Already awarded
        }

        PromoCode promoCode = promoCodeService.generatePromoCode(
            userId,
            PromoCode.PromoCodeType.LOYALTY_3MONTH,
            PromoCode.DiscountType.PERCENTAGE,
            15.0,
            "3-Month Loyalty Reward - 15% off your next subscription!"
        );

        return createReward(userId, "LOYALTY_3MONTH", promoCode);
    }

    // Award loyalty reward (6 months)
    public UserReward awardLoyalty6Month(Long userId) {
        if (userRewardRepository.existsByUserIdAndRewardType(userId, "LOYALTY_6MONTH")) {
            return null;
        }

        PromoCode promoCode = promoCodeService.generatePromoCode(
            userId,
            PromoCode.PromoCodeType.LOYALTY_6MONTH,
            PromoCode.DiscountType.PERCENTAGE,
            20.0,
            "6-Month Loyalty Reward - 20% off your next subscription!"
        );

        return createReward(userId, "LOYALTY_6MONTH", promoCode);
    }

    // Award annual upgrade reward
    public UserReward awardAnnualUpgrade(Long userId) {
        if (userRewardRepository.existsByUserIdAndRewardType(userId, "ANNUAL_UPGRADE")) {
            return null;
        }

        PromoCode promoCode = promoCodeService.generatePromoCode(
            userId,
            PromoCode.PromoCodeType.ANNUAL_UPGRADE,
            PromoCode.DiscountType.PERCENTAGE,
            30.0,
            "Annual Plan Upgrade - 30% off!"
        );

        return createReward(userId, "ANNUAL_UPGRADE", promoCode);
    }

    // Award referral milestone (5 referrals)
    public UserReward awardReferral5(Long userId) {
        if (userRewardRepository.existsByUserIdAndRewardType(userId, "REFERRAL_5")) {
            return null;
        }

        PromoCode promoCode = promoCodeService.generatePromoCode(
            userId,
            PromoCode.PromoCodeType.REFERRAL_5,
            PromoCode.DiscountType.FREE_MONTH,
            100.0,
            "5 Referrals Milestone - 1 Month FREE!"
        );

        return createReward(userId, "REFERRAL_5", promoCode);
    }

    // Award certification reward
    public UserReward awardCertification(Long userId) {
        if (userRewardRepository.existsByUserIdAndRewardType(userId, "CERTIFICATION")) {
            return null;
        }

        PromoCode promoCode = promoCodeService.generatePromoCode(
            userId,
            PromoCode.PromoCodeType.CERTIFICATION,
            PromoCode.DiscountType.PERCENTAGE,
            20.0,
            "Certification Achievement - 20% off!"
        );

        return createReward(userId, "CERTIFICATION", promoCode);
    }

    // Award top 10 leaderboard
    public UserReward awardTop10Leaderboard(Long userId) {
        PromoCode promoCode = promoCodeService.generatePromoCode(
            userId,
            PromoCode.PromoCodeType.TOP10_LEADERBOARD,
            PromoCode.DiscountType.PERCENTAGE,
            35.0,
            "Top 10 Leaderboard - Exclusive 35% off!"
        );

        return createReward(userId, "TOP10_LEADERBOARD", promoCode);
    }

    // Award monthly challenge
    public UserReward awardMonthlyChallenge(Long userId) {
        PromoCode promoCode = promoCodeService.generatePromoCode(
            userId,
            PromoCode.PromoCodeType.MONTHLY_CHALLENGE,
            PromoCode.DiscountType.PERCENTAGE,
            25.0,
            "Monthly Challenge Complete - 25% off!"
        );

        return createReward(userId, "MONTHLY_CHALLENGE", promoCode);
    }

    // Award student discount
    public UserReward awardStudentDiscount(Long userId, String email) {
        if (!email.toLowerCase().endsWith(".edu")) {
            throw new RuntimeException("Not a valid .edu email");
        }

        if (userRewardRepository.existsByUserIdAndRewardType(userId, "STUDENT")) {
            return null;
        }

        PromoCode promoCode = promoCodeService.generatePromoCode(
            userId,
            PromoCode.PromoCodeType.STUDENT,
            PromoCode.DiscountType.PERCENTAGE,
            20.0,
            "Student Discount - 20% off!"
        );

        return createReward(userId, "STUDENT", promoCode);
    }

    // Create reward record
    private UserReward createReward(Long userId, String rewardType, PromoCode promoCode) {
        UserReward reward = new UserReward();
        reward.setUserId(userId);
        reward.setRewardType(rewardType);
        reward.setEarnedAt(LocalDateTime.now());
        reward.setNotificationSent(false);
        reward.setPopupShown(false);
        reward.setPromoCode(promoCode);
        
        UserReward savedReward = userRewardRepository.save(reward);
        
        // Send email notification (optional - can be disabled)
        // TODO: Get user email from User microservice
        String userEmail = "user" + userId + "@example.com"; // Placeholder
        try {
            emailService.sendPromoCodeEarned(
                userEmail,
                "User",
                promoCode.getCode(),
                rewardType,
                promoCode.getDiscountValue().intValue()
            );
        } catch (Exception e) {
            System.err.println("Failed to send promo code email: " + e.getMessage());
            // Don't fail the reward if email fails
        }
        
        return savedReward;
    }

    // Get user's rewards
    public List<UserReward> getUserRewards(Long userId) {
        return userRewardRepository.findByUserId(userId);
    }

    // Get pending notifications
    public List<UserReward> getPendingNotifications(Long userId) {
        return userRewardRepository.findByUserIdAndNotificationSentFalse(userId);
    }

    // Get pending popups
    public List<UserReward> getPendingPopups(Long userId) {
        return userRewardRepository.findByUserIdAndPopupShownFalse(userId);
    }

    // Mark notification as sent
    public void markNotificationSent(Long rewardId) {
        UserReward reward = userRewardRepository.findById(rewardId).orElse(null);
        if (reward != null) {
            reward.setNotificationSent(true);
            userRewardRepository.save(reward);
        }
    }

    // Mark popup as shown
    public void markPopupShown(Long rewardId) {
        UserReward reward = userRewardRepository.findById(rewardId).orElse(null);
        if (reward != null) {
            reward.setPopupShown(true);
            userRewardRepository.save(reward);
        }
    }
}
