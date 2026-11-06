package org.example.referralmicroservice.Controllers;

import org.example.referralmicroservice.Entities.RewardTransaction;
import org.example.referralmicroservice.Entities.UserWallet;
import org.example.referralmicroservice.Services.WalletService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/wallet")
@CrossOrigin(origins = "http://localhost")
public class WalletController {

    @Autowired
    private WalletService walletService;

    // Get wallet for user
    @GetMapping("/{userId}")
    public ResponseEntity<UserWallet> getWallet(@PathVariable Long userId) {
        try {
            UserWallet wallet = walletService.getWallet(userId);
            return ResponseEntity.ok(wallet);
        } catch (Exception e) {
            // Create wallet if doesn't exist
            UserWallet wallet = walletService.getOrCreateWallet(userId);
            return ResponseEntity.ok(wallet);
        }
    }

    // Check and award rewards for certification
    @PostMapping("/check-rewards/{userId}")
    public ResponseEntity<Map<String, Object>> checkRewards(
            @PathVariable Long userId,
            @RequestParam Integer score) {
        
        Map<String, Object> response = new HashMap<>();
        
        try {
            RewardTransaction transaction = walletService.checkAndAwardRewards(userId, score);
            
            if (transaction != null) {
                response.put("rewarded", true);
                response.put("transaction", transaction);
                response.put("message", "Congratulations! You earned $" + transaction.getAmount());
            } else {
                response.put("rewarded", false);
                response.put("message", "Keep learning! Reach the next milestone to earn rewards.");
            }
            
            // Include updated wallet stats
            response.put("wallet", walletService.getWalletStats(userId));
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            response.put("error", e.getMessage());
            return ResponseEntity.badRequest().body(response);
        }
    }

    // Get transaction history
    @GetMapping("/{userId}/transactions")
    public ResponseEntity<List<RewardTransaction>> getTransactions(@PathVariable Long userId) {
        List<RewardTransaction> transactions = walletService.getTransactionHistory(userId);
        return ResponseEntity.ok(transactions);
    }

    // Get wallet statistics
    @GetMapping("/{userId}/stats")
    public ResponseEntity<Map<String, Object>> getWalletStats(@PathVariable Long userId) {
        Map<String, Object> stats = walletService.getWalletStats(userId);
        return ResponseEntity.ok(stats);
    }

    // Get leaderboards
    @GetMapping("/leaderboards/earners")
    public ResponseEntity<List<UserWallet>> getTopEarners() {
        List<UserWallet> topEarners = walletService.getTopEarners();
        return ResponseEntity.ok(topEarners);
    }

    @GetMapping("/leaderboards/donors")
    public ResponseEntity<List<UserWallet>> getTopDonors() {
        List<UserWallet> topDonors = walletService.getTopDonors();
        return ResponseEntity.ok(topDonors);
    }

    @GetMapping("/leaderboards/learners")
    public ResponseEntity<List<UserWallet>> getTopLearners() {
        List<UserWallet> topLearners = walletService.getTopLearners();
        return ResponseEntity.ok(topLearners);
    }

    // Get platform statistics
    @GetMapping("/platform/stats")
    public ResponseEntity<Map<String, Object>> getPlatformStats() {
        Map<String, Object> stats = walletService.getPlatformStats();
        return ResponseEntity.ok(stats);
    }
}

