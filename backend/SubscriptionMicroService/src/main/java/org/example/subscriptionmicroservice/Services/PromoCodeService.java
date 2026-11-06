package org.example.subscriptionmicroservice.Services;

import org.example.subscriptionmicroservice.Entities.PromoCode;
import org.example.subscriptionmicroservice.Repositories.PromoCodeRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.Random;

@Service
public class PromoCodeService {

    @Autowired
    private PromoCodeRepository promoCodeRepository;

    private static final int CODE_EXPIRY_DAYS = 30;
    private static final String CODE_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";

    // Generate unique promo code
    public PromoCode generatePromoCode(Long userId, PromoCode.PromoCodeType type, 
                                       PromoCode.DiscountType discountType, Double discountValue,
                                       String description) {
        
        // Check if user already has this type of code
        if (promoCodeRepository.existsByUserIdAndType(userId, type)) {
            return promoCodeRepository.findByUserIdAndType(userId, type).orElse(null);
        }

        PromoCode promoCode = new PromoCode();
        promoCode.setCode(generateUniqueCode(type));
        promoCode.setType(type);
        promoCode.setDiscountType(discountType);
        promoCode.setDiscountValue(discountValue);
        promoCode.setUserId(userId);
        promoCode.setEarnedAt(LocalDateTime.now());
        promoCode.setExpiresAt(LocalDateTime.now().plusDays(CODE_EXPIRY_DAYS));
        promoCode.setIsActive(true);
        promoCode.setMinSubscriptionCount(1); // Can use after first subscription
        promoCode.setDescription(description);

        return promoCodeRepository.save(promoCode);
    }

    // Generate unique code string
    private String generateUniqueCode(PromoCode.PromoCodeType type) {
        String prefix = getCodePrefix(type);
        String randomPart;
        String fullCode;
        
        do {
            randomPart = generateRandomString(6);
            fullCode = prefix + randomPart;
        } while (promoCodeRepository.findByCode(fullCode).isPresent());
        
        return fullCode;
    }

    private String getCodePrefix(PromoCode.PromoCodeType type) {
        switch (type) {
            case LOYALTY_3MONTH: return "LOYAL15";
            case LOYALTY_6MONTH: return "HALF20";
            case ANNUAL_UPGRADE: return "YEAR30";
            case REFERRAL_5: return "REF5";
            case CERTIFICATION: return "CERT20";
            case TOP10_LEADERBOARD: return "TOP10";
            case MONTHLY_CHALLENGE: return "CHAL25";
            case STUDENT: return "STU20";
            case SPIN_WHEEL: return "SPIN";
            default: return "PROMO";
        }
    }

    private String generateRandomString(int length) {
        Random random = new Random();
        StringBuilder sb = new StringBuilder(length);
        for (int i = 0; i < length; i++) {
            sb.append(CODE_CHARS.charAt(random.nextInt(CODE_CHARS.length())));
        }
        return sb.toString();
    }

    // Validate promo code
    public boolean validatePromoCode(String code, Long userId, Integer userSubscriptionCount) {
        Optional<PromoCode> promoCodeOpt = promoCodeRepository.findByCode(code);
        
        if (promoCodeOpt.isEmpty()) {
            return false;
        }
        
        PromoCode promoCode = promoCodeOpt.get();
        
        // Check if code belongs to user
        if (!promoCode.getUserId().equals(userId)) {
            return false;
        }
        
        // Check if user has enough subscriptions ("can use after N subscriptions": N is enough)
        if (userSubscriptionCount < promoCode.getMinSubscriptionCount()) {
            return false;
        }
        
        // Check if code can be used
        return promoCode.canBeUsed();
    }

    // Apply promo code
    public PromoCode applyPromoCode(String code, Long subscriptionId) {
        Optional<PromoCode> promoCodeOpt = promoCodeRepository.findByCode(code);
        
        if (promoCodeOpt.isEmpty()) {
            throw new RuntimeException("Promo code not found");
        }
        
        PromoCode promoCode = promoCodeOpt.get();
        
        if (!promoCode.canBeUsed()) {
            throw new RuntimeException("Promo code cannot be used");
        }
        
        promoCode.setUsedAt(LocalDateTime.now());
        promoCode.setUsedInSubscriptionId(subscriptionId);
        promoCode.setIsActive(false);
        
        return promoCodeRepository.save(promoCode);
    }

    // Get user's available codes
    public List<PromoCode> getAvailableCodes(Long userId) {
        return promoCodeRepository.findByUserIdAndUsedAtIsNullAndExpiresAtAfter(userId, LocalDateTime.now());
    }

    // Get all user's codes
    public List<PromoCode> getAllUserCodes(Long userId) {
        return promoCodeRepository.findByUserId(userId);
    }

    // Get code by string
    public Optional<PromoCode> getCodeByString(String code) {
        return promoCodeRepository.findByCode(code);
    }

    // Calculate discount amount
    public Double calculateDiscount(PromoCode promoCode, Double originalPrice) {
        switch (promoCode.getDiscountType()) {
            case PERCENTAGE:
                return originalPrice * (promoCode.getDiscountValue() / 100.0);
            case FIXED_AMOUNT:
                return Math.min(promoCode.getDiscountValue(), originalPrice);
            case FREE_MONTH:
                return originalPrice; // Full price discount
            default:
                return 0.0;
        }
    }

    // Deactivate expired codes (scheduled task)
    public void deactivateExpiredCodes() {
        List<PromoCode> expiredCodes = promoCodeRepository.findByExpiresAtBeforeAndIsActiveTrue(LocalDateTime.now());
        for (PromoCode code : expiredCodes) {
            code.setIsActive(false);
            promoCodeRepository.save(code);
        }
    }

    // Check if user has specific code type
    public boolean hasCodeType(Long userId, PromoCode.PromoCodeType type) {
        return promoCodeRepository.existsByUserIdAndType(userId, type);
    }

    // ========== ADMIN METHODS ==========

    // Get all promo codes
    public List<PromoCode> getAllPromoCodes() {
        return promoCodeRepository.findAll();
    }

    // Create promo code manually (admin)
    public PromoCode createPromoCodeManual(PromoCode promoCode) {
        // Set defaults if not provided
        if (promoCode.getEarnedAt() == null) {
            promoCode.setEarnedAt(LocalDateTime.now());
        }
        if (promoCode.getExpiresAt() == null) {
            promoCode.setExpiresAt(LocalDateTime.now().plusDays(CODE_EXPIRY_DAYS));
        }
        if (promoCode.getIsActive() == null) {
            promoCode.setIsActive(true);
        }
        if (promoCode.getMinSubscriptionCount() == null) {
            promoCode.setMinSubscriptionCount(1);
        }
        
        // Ensure code is unique
        if (promoCodeRepository.findByCode(promoCode.getCode()).isPresent()) {
            throw new RuntimeException("Promo code already exists");
        }
        
        return promoCodeRepository.save(promoCode);
    }

    // Update promo code
    public PromoCode updatePromoCode(Long id, PromoCode updatedPromoCode) {
        PromoCode existing = promoCodeRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Promo code not found"));
        
        // Update fields
        if (updatedPromoCode.getCode() != null) {
            existing.setCode(updatedPromoCode.getCode());
        }
        if (updatedPromoCode.getType() != null) {
            existing.setType(updatedPromoCode.getType());
        }
        if (updatedPromoCode.getDiscountType() != null) {
            existing.setDiscountType(updatedPromoCode.getDiscountType());
        }
        if (updatedPromoCode.getDiscountValue() != null) {
            existing.setDiscountValue(updatedPromoCode.getDiscountValue());
        }
        if (updatedPromoCode.getExpiresAt() != null) {
            existing.setExpiresAt(updatedPromoCode.getExpiresAt());
        }
        if (updatedPromoCode.getIsActive() != null) {
            existing.setIsActive(updatedPromoCode.getIsActive());
        }
        if (updatedPromoCode.getDescription() != null) {
            existing.setDescription(updatedPromoCode.getDescription());
        }
        
        return promoCodeRepository.save(existing);
    }

    // Delete promo code
    public void deletePromoCode(Long id) {
        if (!promoCodeRepository.existsById(id)) {
            throw new RuntimeException("Promo code not found");
        }
        promoCodeRepository.deleteById(id);
    }

    // Toggle promo code status
    public PromoCode togglePromoCodeStatus(Long id) {
        PromoCode promoCode = promoCodeRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Promo code not found"));
        
        promoCode.setIsActive(!promoCode.getIsActive());
        return promoCodeRepository.save(promoCode);
    }

}
