package org.example.subscriptionmicroservice.Entities;

import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalDateTime;

@Entity
@Table(name = "promo_codes")
@Data
public class PromoCode {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(unique = true, nullable = false)
    private String code;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private PromoCodeType type;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private DiscountType discountType;

    @Column(nullable = false)
    private Double discountValue;

    @Column(nullable = false)
    private Long userId;

    @Column(nullable = false)
    private LocalDateTime earnedAt;

    @Column(nullable = false)
    private LocalDateTime expiresAt;

    private LocalDateTime usedAt;

    private Long usedInSubscriptionId;

    @Column(nullable = false)
    private Boolean isActive = true;

    @Column(nullable = false)
    private Integer minSubscriptionCount = 1; // Can use after this many subscriptions

    private String description;

    public enum PromoCodeType {
        LOYALTY_3MONTH,
        LOYALTY_6MONTH,
        ANNUAL_UPGRADE,
        REFERRAL_5,
        CERTIFICATION,
        TOP10_LEADERBOARD,
        MONTHLY_CHALLENGE,
        STUDENT,
        SPIN_WHEEL,
        SPECIAL
    }

    public enum DiscountType {
        PERCENTAGE,
        FIXED_AMOUNT,
        FREE_MONTH
    }

    public boolean isExpired() {
        return LocalDateTime.now().isAfter(expiresAt);
    }

    public boolean isUsed() {
        return usedAt != null;
    }

    public boolean canBeUsed() {
        return isActive && !isExpired() && !isUsed();
    }
}
