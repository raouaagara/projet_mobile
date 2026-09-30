package org.example.subscriptionmicroservice.Entities;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity

@Data
@NoArgsConstructor
@AllArgsConstructor
public class Payment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_subscription_id", nullable = false)
    @JsonIgnore
    private UserSubscription userSubscription;

    @Column(nullable = false)
    private Double amount;

    private String paymentMethod; // card, paypal, etc.

    private String status = "PAID"; // PAID, PENDING, FAILED

    private LocalDateTime paidAt = LocalDateTime.now();

    private String invoiceRef; // for invoice download

    /** Payment id at the payment provider (Flouci), so a payment can't be used twice. */
    @Column(unique = true)
    private String transactionRef;
}
