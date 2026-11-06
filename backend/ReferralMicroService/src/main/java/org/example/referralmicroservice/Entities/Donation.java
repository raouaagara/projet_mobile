package org.example.referralmicroservice.Entities;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "donations")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Donation {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private Long donorId;

    @Column(nullable = false)
    private Long recipientId;

    @Column(nullable = false)
    private Double amount;

    @Column(length = 500)
    private String message;

    @Column(nullable = false)
    private Boolean isAnonymous = false;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private DonationStatus status = DonationStatus.PENDING;

    @Column(nullable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    private LocalDateTime completedAt;

    @Column(nullable = false)
    private Boolean thankYouSent = false;

    public enum DonationStatus {
        PENDING,    // Donation initiated
        COMPLETED,  // Successfully processed
        REFUNDED,   // Refunded to donor
        CANCELLED   // Cancelled before processing
    }

    // Helper methods
    public void complete() {
        this.status = DonationStatus.COMPLETED;
        this.completedAt = LocalDateTime.now();
    }

    public void refund() {
        this.status = DonationStatus.REFUNDED;
    }

    public void cancel() {
        this.status = DonationStatus.CANCELLED;
    }

    public void sendThankYou() {
        this.thankYouSent = true;
    }

    // Constructor for easy creation
    public Donation(Long donorId, Long recipientId, Double amount, String message, Boolean isAnonymous) {
        this.donorId = donorId;
        this.recipientId = recipientId;
        this.amount = amount;
        this.message = message;
        this.isAnonymous = isAnonymous;
        this.status = DonationStatus.PENDING;
        this.createdAt = LocalDateTime.now();
        this.thankYouSent = false;
    }
}
