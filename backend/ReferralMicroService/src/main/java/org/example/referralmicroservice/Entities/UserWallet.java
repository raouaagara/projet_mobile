package org.example.referralmicroservice.Entities;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "user_wallets")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class UserWallet {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private Long userId;

    @Column(nullable = false)
    private Double balance = 0.0;

    @Column(nullable = false)
    private Double totalEarned = 0.0;

    @Column(nullable = false)
    private Double totalDonated = 0.0;

    @Column(nullable = false)
    private Double totalReceived = 0.0;

    @Column(nullable = false)
    private Integer certificationsCount = 0;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private TierLevel currentTier = TierLevel.NONE;

    @Column(nullable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(nullable = false)
    private LocalDateTime updatedAt = LocalDateTime.now();

    public enum TierLevel {
        NONE,       // 0-9 certifications
        BRONZE,     // 10-19 certifications
        SILVER,     // 20-29 certifications
        GOLD,       // 30-49 certifications
        PLATINUM,   // 50-99 certifications
        DIAMOND     // 100+ certifications
    }

    // Helper methods
    public void addBalance(Double amount) {
        this.balance += amount;
        this.updatedAt = LocalDateTime.now();
    }

    public void deductBalance(Double amount) {
        if (this.balance >= amount) {
            this.balance -= amount;
            this.updatedAt = LocalDateTime.now();
        } else {
            throw new RuntimeException("Insufficient balance");
        }
    }

    public void addEarnings(Double amount) {
        this.totalEarned += amount;
        this.balance += amount;
        this.updatedAt = LocalDateTime.now();
    }

    public void addDonation(Double amount) {
        this.totalDonated += amount;
        this.updatedAt = LocalDateTime.now();
    }

    public void addReceived(Double amount) {
        this.totalReceived += amount;
        this.balance += amount;
        this.updatedAt = LocalDateTime.now();
    }

    public void updateTier() {
        if (certificationsCount >= 100) {
            this.currentTier = TierLevel.DIAMOND;
        } else if (certificationsCount >= 50) {
            this.currentTier = TierLevel.PLATINUM;
        } else if (certificationsCount >= 30) {
            this.currentTier = TierLevel.GOLD;
        } else if (certificationsCount >= 20) {
            this.currentTier = TierLevel.SILVER;
        } else if (certificationsCount >= 10) {
            this.currentTier = TierLevel.BRONZE;
        } else {
            this.currentTier = TierLevel.NONE;
        }
        this.updatedAt = LocalDateTime.now();
    }

    public void incrementCertifications() {
        this.certificationsCount++;
        updateTier();
    }
}
