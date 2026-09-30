package org.example.subscriptionmicroservice.Entities;

import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalDateTime;

@Entity
@Table(name = "user_rewards")
@Data
public class UserReward {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private Long userId;

    @Column(nullable = false)
    private String rewardType;

    @Column(nullable = false)
    private LocalDateTime earnedAt;

    @Column(nullable = false)
    private Boolean notificationSent = false;

    @Column(nullable = false)
    private Boolean popupShown = false;

    @OneToOne
    @JoinColumn(name = "promo_code_id")
    private PromoCode promoCode;

    private String metadata; // JSON for additional info
}
