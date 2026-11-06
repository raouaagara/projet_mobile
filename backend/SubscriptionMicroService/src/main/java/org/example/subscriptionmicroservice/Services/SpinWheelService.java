package org.example.subscriptionmicroservice.Services;

import org.example.subscriptionmicroservice.Entities.PromoCode;
import org.example.subscriptionmicroservice.Entities.SpinWheelAttempt;
import org.example.subscriptionmicroservice.Repositories.SpinWheelAttemptRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Random;

@Service
public class SpinWheelService {

    @Autowired
    private SpinWheelAttemptRepository spinWheelAttemptRepository;

    @Autowired
    private PromoCodeService promoCodeService;

    private static final int[] POSSIBLE_DISCOUNTS = {5, 10, 15, 20, 25};
    private static final int SPIN_COOLDOWN_DAYS = 30; // Once per month

    // Check if user can spin
    public boolean canUserSpin(Long userId) {
        LocalDateTime oneMonthAgo = LocalDateTime.now().minusDays(SPIN_COOLDOWN_DAYS);
        return !spinWheelAttemptRepository.existsByUserIdAndAttemptDateAfter(userId, oneMonthAgo);
    }

    // Get days until next spin
    public Integer getDaysUntilNextSpin(Long userId) {
        var lastAttempt = spinWheelAttemptRepository.findFirstByUserIdOrderByAttemptDateDesc(userId);
        
        if (lastAttempt.isEmpty()) {
            return 0; // Can spin now
        }
        
        LocalDateTime nextSpinDate = lastAttempt.get().getAttemptDate().plusDays(SPIN_COOLDOWN_DAYS);
        LocalDateTime now = LocalDateTime.now();
        
        if (now.isAfter(nextSpinDate)) {
            return 0; // Can spin now
        }
        
        long daysUntil = java.time.Duration.between(now, nextSpinDate).toDays();
        return (int) daysUntil;
    }

    // Spin the wheel
    public SpinWheelAttempt spinWheel(Long userId) {
        if (!canUserSpin(userId)) {
            throw new RuntimeException("You can only spin once per month. Please wait.");
        }

        // Generate random discount
        Random random = new Random();
        int discountWon = POSSIBLE_DISCOUNTS[random.nextInt(POSSIBLE_DISCOUNTS.length)];

        // Generate promo code
        PromoCode promoCode = promoCodeService.generatePromoCode(
            userId,
            PromoCode.PromoCodeType.SPIN_WHEEL,
            PromoCode.DiscountType.PERCENTAGE,
            (double) discountWon,
            "Spin the Wheel Winner - " + discountWon + "% off!"
        );

        // Record attempt
        SpinWheelAttempt attempt = new SpinWheelAttempt();
        attempt.setUserId(userId);
        attempt.setAttemptDate(LocalDateTime.now());
        attempt.setDiscountWon(discountWon);
        attempt.setPromoCode(promoCode);

        return spinWheelAttemptRepository.save(attempt);
    }

    // Get user's spin history
    public List<SpinWheelAttempt> getUserSpinHistory(Long userId) {
        return spinWheelAttemptRepository.findByUserId(userId);
    }

    // Get last spin attempt
    public SpinWheelAttempt getLastSpinAttempt(Long userId) {
        return spinWheelAttemptRepository.findFirstByUserIdOrderByAttemptDateDesc(userId).orElse(null);
    }
}
