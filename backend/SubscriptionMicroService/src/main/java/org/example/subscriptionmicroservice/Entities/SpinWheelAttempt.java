package org.example.subscriptionmicroservice.Entities;

import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalDateTime;

@Entity
@Table(name = "spin_wheel_attempts")
@Data
public class SpinWheelAttempt {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private Long userId;

    @Column(nullable = false)
    private LocalDateTime attemptDate;

    @Column(nullable = false)
    private Integer discountWon;

    @OneToOne
    @JoinColumn(name = "promo_code_id")
    private PromoCode promoCode;
}
