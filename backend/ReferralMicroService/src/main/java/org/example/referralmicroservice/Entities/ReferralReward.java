package org.example.referralmicroservice.Entities;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import lombok.Data;

import java.time.LocalDateTime;

@Entity
@Table(name = "referral_rewards")
@Data
public class ReferralReward {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private Long userId;
    private String rewardType;
    private Double amount;
    private Boolean claimed = false;
    private LocalDateTime createdAt = LocalDateTime.now();

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "referral_id")
    @JsonIgnore
    private Referral referral;

    public Long getReferralId() {
        return referral != null ? referral.getId() : null;
    }
}
