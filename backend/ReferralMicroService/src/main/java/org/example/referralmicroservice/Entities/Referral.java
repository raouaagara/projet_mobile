package org.example.referralmicroservice.Entities;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "referrals")
@Data
public class Referral {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private Long referrerUserId;
    private Long referredUserId;  // null until someone signs up with this code
    @Column(name = "referral_code")
    private String referralCode;  // denormalized for lookup (matches ReferralCode.code)
    private String status = "PENDING";
    private LocalDateTime referredAt = LocalDateTime.now();

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "referral_code_id")
    @JsonIgnore
    private ReferralCode referralCodeRef;

    @OneToMany(mappedBy = "referral", cascade = CascadeType.ALL)
    @JsonIgnore
    private List<ReferralReward> rewards = new ArrayList<>();
}
