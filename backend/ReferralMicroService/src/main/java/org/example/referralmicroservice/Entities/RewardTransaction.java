package org.example.referralmicroservice.Entities;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "reward_transactions")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class RewardTransaction {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private Long userId;

    @Column(nullable = false)
    private Double amount;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private RewardType type;

    @Column(nullable = false)
    private Integer certificationsCount;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private UserWallet.TierLevel tier;

    @Column(length = 500)
    private String description;

    @Column(nullable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    public enum RewardType {
        CERTIFICATION_REWARD,   // Regular certification reward
        TIER_BONUS,            // Bonus for reaching new tier
        REFERRAL_BONUS,        // Bonus from referral program
        ADMIN_BONUS,           // Manual bonus from admin
        CHALLENGE_REWARD       // Reward from completing challenge
    }

    // Constructor for easy creation
    public RewardTransaction(Long userId, Double amount, RewardType type, 
                           Integer certificationsCount, UserWallet.TierLevel tier, String description) {
        this.userId = userId;
        this.amount = amount;
        this.type = type;
        this.certificationsCount = certificationsCount;
        this.tier = tier;
        this.description = description;
        this.createdAt = LocalDateTime.now();
    }
}
