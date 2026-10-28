package org.example.subscriptionmicroservice.Controllers;

import org.example.subscriptionmicroservice.Entities.SpinWheelAttempt;
import org.example.subscriptionmicroservice.Entities.UserReward;
import org.example.subscriptionmicroservice.Services.RewardService;
import org.example.subscriptionmicroservice.Services.SpinWheelService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/rewards")
@CrossOrigin(origins = "http://localhost")
public class RewardController {

    @Autowired
    private RewardService rewardService;

    @Autowired
    private SpinWheelService spinWheelService;

    // Get user's rewards
    @GetMapping("/user/{userId}")
    public ResponseEntity<List<UserReward>> getUserRewards(@PathVariable Long userId) {
        List<UserReward> rewards = rewardService.getUserRewards(userId);
        return ResponseEntity.ok(rewards);
    }

    // Get pending notifications
    @GetMapping("/notifications/{userId}")
    public ResponseEntity<List<UserReward>> getPendingNotifications(@PathVariable Long userId) {
        List<UserReward> rewards = rewardService.getPendingNotifications(userId);
        return ResponseEntity.ok(rewards);
    }

    // Get pending popups
    @GetMapping("/popups/{userId}")
    public ResponseEntity<List<UserReward>> getPendingPopups(@PathVariable Long userId) {
        List<UserReward> rewards = rewardService.getPendingPopups(userId);
        return ResponseEntity.ok(rewards);
    }

    // Mark notification as sent
    @PostMapping("/notifications/{rewardId}/mark-sent")
    public ResponseEntity<Map<String, String>> markNotificationSent(@PathVariable Long rewardId) {
        rewardService.markNotificationSent(rewardId);
        Map<String, String> response = new HashMap<>();
        response.put("message", "Notification marked as sent");
        return ResponseEntity.ok(response);
    }

    // Mark popup as shown
    @PostMapping("/popups/{rewardId}/mark-shown")
    public ResponseEntity<Map<String, String>> markPopupShown(@PathVariable Long rewardId) {
        rewardService.markPopupShown(rewardId);
        Map<String, String> response = new HashMap<>();
        response.put("message", "Popup marked as shown");
        return ResponseEntity.ok(response);
    }

    // Award student discount
    @PostMapping("/student/{userId}")
    public ResponseEntity<Map<String, Object>> awardStudentDiscount(
            @PathVariable Long userId,
            @RequestParam String email) {
        
        try {
            UserReward reward = rewardService.awardStudentDiscount(userId, email);
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("reward", reward);
            response.put("message", "Student discount awarded!");
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", e.getMessage());
            return ResponseEntity.badRequest().body(response);
        }
    }

    // Spin the wheel
    @PostMapping("/spin-wheel/{userId}")
    public ResponseEntity<Map<String, Object>> spinWheel(@PathVariable Long userId) {
        try {
            SpinWheelAttempt attempt = spinWheelService.spinWheel(userId);
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("discountWon", attempt.getDiscountWon());
            response.put("promoCode", attempt.getPromoCode());
            response.put("message", "Congratulations! You won " + attempt.getDiscountWon() + "% off!");
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", e.getMessage());
            return ResponseEntity.badRequest().body(response);
        }
    }

    // Check if user can spin
    @GetMapping("/spin-wheel/can-spin/{userId}")
    public ResponseEntity<Map<String, Object>> canUserSpin(@PathVariable Long userId) {
        boolean canSpin = spinWheelService.canUserSpin(userId);
        Integer daysUntilNext = spinWheelService.getDaysUntilNextSpin(userId);
        
        Map<String, Object> response = new HashMap<>();
        response.put("canSpin", canSpin);
        response.put("daysUntilNextSpin", daysUntilNext);
        response.put("message", canSpin 
            ? "You can spin the wheel!" 
            : "Next spin available in " + daysUntilNext + " days");
        
        return ResponseEntity.ok(response);
    }

    // Get spin history
    @GetMapping("/spin-wheel/history/{userId}")
    public ResponseEntity<List<SpinWheelAttempt>> getSpinHistory(@PathVariable Long userId) {
        List<SpinWheelAttempt> history = spinWheelService.getUserSpinHistory(userId);
        return ResponseEntity.ok(history);
    }

    // Award certification reward (called when user passes skill test)
    @PostMapping("/certification/{userId}")
    public ResponseEntity<Map<String, Object>> awardCertification(@PathVariable Long userId) {
        UserReward reward = rewardService.awardCertification(userId);
        Map<String, Object> response = new HashMap<>();
        
        if (reward != null) {
            response.put("success", true);
            response.put("reward", reward);
            response.put("message", "Certification reward earned!");
        } else {
            response.put("success", false);
            response.put("message", "Reward already claimed");
        }
        
        return ResponseEntity.ok(response);
    }

    // Award referral milestone (called when user reaches 5 referrals)
    @PostMapping("/referral-5/{userId}")
    public ResponseEntity<Map<String, Object>> awardReferral5(@PathVariable Long userId) {
        UserReward reward = rewardService.awardReferral5(userId);
        Map<String, Object> response = new HashMap<>();
        
        if (reward != null) {
            response.put("success", true);
            response.put("reward", reward);
            response.put("message", "5 Referrals milestone reward earned!");
        } else {
            response.put("success", false);
            response.put("message", "Reward already claimed");
        }
        
        return ResponseEntity.ok(response);
    }
}

