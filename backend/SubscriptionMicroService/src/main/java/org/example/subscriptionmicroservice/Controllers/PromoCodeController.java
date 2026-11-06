package org.example.subscriptionmicroservice.Controllers;

import org.example.subscriptionmicroservice.Entities.PromoCode;
import org.example.subscriptionmicroservice.Services.PromoCodeService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/promo-codes")
@CrossOrigin(origins = "http://localhost")
public class PromoCodeController {

    @Autowired
    private PromoCodeService promoCodeService;

    // Get all user's promo codes
    @GetMapping("/user/{userId}")
    public ResponseEntity<List<PromoCode>> getUserPromoCodes(@PathVariable Long userId) {
        List<PromoCode> codes = promoCodeService.getAllUserCodes(userId);
        return ResponseEntity.ok(codes);
    }

    // Get available (unused, not expired) codes
    @GetMapping("/available/{userId}")
    public ResponseEntity<List<PromoCode>> getAvailableCodes(@PathVariable Long userId) {
        List<PromoCode> codes = promoCodeService.getAvailableCodes(userId);
        return ResponseEntity.ok(codes);
    }

    // Validate promo code
    @PostMapping("/validate")
    public ResponseEntity<Map<String, Object>> validateCode(
            @RequestParam String code,
            @RequestParam Long userId,
            @RequestParam Integer subscriptionCount) {
        
        boolean isValid = promoCodeService.validatePromoCode(code, userId, subscriptionCount);
        Map<String, Object> response = new HashMap<>();
        response.put("valid", isValid);
        
        if (isValid) {
            var promoCode = promoCodeService.getCodeByString(code).orElse(null);
            if (promoCode != null) {
                response.put("code", promoCode);
                response.put("message", "Promo code is valid!");
            }
        } else {
            response.put("message", "Invalid or expired promo code");
        }
        
        return ResponseEntity.ok(response);
    }

    // Calculate discount
    @PostMapping("/calculate-discount")
    public ResponseEntity<Map<String, Object>> calculateDiscount(
            @RequestParam String code,
            @RequestParam Double originalPrice) {
        
        var promoCodeOpt = promoCodeService.getCodeByString(code);
        Map<String, Object> response = new HashMap<>();
        
        if (promoCodeOpt.isEmpty()) {
            response.put("error", "Code not found");
            return ResponseEntity.badRequest().body(response);
        }
        
        PromoCode promoCode = promoCodeOpt.get();
        Double discount = promoCodeService.calculateDiscount(promoCode, originalPrice);
        Double finalPrice = originalPrice - discount;
        
        response.put("originalPrice", originalPrice);
        response.put("discount", discount);
        response.put("finalPrice", finalPrice);
        response.put("discountPercentage", (discount / originalPrice) * 100);
        
        return ResponseEntity.ok(response);
    }

    // Apply promo code to subscription
    @PostMapping("/apply")
    public ResponseEntity<Map<String, Object>> applyPromoCode(
            @RequestParam String code,
            @RequestParam Long subscriptionId) {
        
        try {
            PromoCode appliedCode = promoCodeService.applyPromoCode(code, subscriptionId);
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Promo code applied successfully!");
            response.put("code", appliedCode);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", e.getMessage());
            return ResponseEntity.badRequest().body(response);
        }
    }

    // Check eligibility
    @GetMapping("/check-eligibility")
    public ResponseEntity<Map<String, Object>> checkEligibility(
            @RequestParam Long userId,
            @RequestParam Integer subscriptionCount) {
        
        Map<String, Object> response = new HashMap<>();
        boolean canUsePromoCode = subscriptionCount > 1;
        
        response.put("eligible", canUsePromoCode);
        response.put("subscriptionCount", subscriptionCount);
        response.put("message", canUsePromoCode 
            ? "You can use promo codes!" 
            : "Promo codes can be used starting from your second subscription.");
        
        return ResponseEntity.ok(response);
    }

    // Get code details
    @GetMapping("/details/{code}")
    public ResponseEntity<PromoCode> getCodeDetails(@PathVariable String code) {
        var promoCode = promoCodeService.getCodeByString(code);
        return promoCode.map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.notFound().build());
    }


    // ========== ADMIN ENDPOINTS ==========

    // Get all promo codes (admin)
    @GetMapping("/admin/all")
    public ResponseEntity<List<PromoCode>> getAllPromoCodes() {
        System.out.println("=== GET ALL PROMO CODES REQUEST ===");
        List<PromoCode> codes = promoCodeService.getAllPromoCodes();
        System.out.println("Found " + codes.size() + " promo codes");
        return ResponseEntity.ok(codes);
    }

    // Create promo code manually (admin)
    @PostMapping("/admin/create")
    public ResponseEntity<PromoCode> createPromoCode(@RequestBody PromoCode promoCode) {
        System.out.println("=== CREATE PROMO CODE REQUEST ===");
        System.out.println("Code: " + promoCode.getCode());
        System.out.println("Type: " + promoCode.getType());
        System.out.println("Discount Type: " + promoCode.getDiscountType());
        System.out.println("Discount Value: " + promoCode.getDiscountValue());
        System.out.println("User ID: " + promoCode.getUserId());
        System.out.println("Expires At: " + promoCode.getExpiresAt());
        
        try {
            PromoCode created = promoCodeService.createPromoCodeManual(promoCode);
            System.out.println("Promo code created successfully with ID: " + created.getId());
            return ResponseEntity.ok(created);
        } catch (Exception e) {
            System.err.println("Error creating promo code: " + e.getMessage());
            e.printStackTrace();
            throw e;
        }
    }

    // Update promo code (admin)
    @PutMapping("/admin/{id}")
    public ResponseEntity<PromoCode> updatePromoCode(@PathVariable Long id, @RequestBody PromoCode promoCode) {
        PromoCode updated = promoCodeService.updatePromoCode(id, promoCode);
        return ResponseEntity.ok(updated);
    }

    // Delete promo code (admin)
    @DeleteMapping("/admin/{id}")
    public ResponseEntity<Map<String, Object>> deletePromoCode(@PathVariable Long id) {
        promoCodeService.deletePromoCode(id);
        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("message", "Promo code deleted successfully");
        return ResponseEntity.ok(response);
    }

    // Toggle promo code active status (admin)
    @PutMapping("/admin/{id}/toggle")
    public ResponseEntity<PromoCode> togglePromoCodeStatus(@PathVariable Long id) {
        PromoCode updated = promoCodeService.togglePromoCodeStatus(id);
        return ResponseEntity.ok(updated);
    }

}

