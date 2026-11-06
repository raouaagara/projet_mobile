package org.example.referralmicroservice.Controllers;

import org.example.referralmicroservice.Entities.Donation;
import org.example.referralmicroservice.Services.DonationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/donations")
@CrossOrigin(origins = "http://localhost")
public class DonationController {

    @Autowired
    private DonationService donationService;

    // Send donation
    @PostMapping("/send")
    public ResponseEntity<Map<String, Object>> sendDonation(
            @RequestParam Long donorId,
            @RequestParam Long recipientId,
            @RequestParam Double amount,
            @RequestParam(required = false) String message,
            @RequestParam(defaultValue = "false") Boolean isAnonymous) {
        
        Map<String, Object> response = new HashMap<>();
        
        try {
            Donation donation = donationService.sendDonation(
                    donorId, recipientId, amount, message, isAnonymous);
            
            response.put("success", true);
            response.put("donation", donation);
            response.put("message", "Donation sent successfully!");
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            response.put("success", false);
            response.put("error", e.getMessage());
            return ResponseEntity.badRequest().body(response);
        }
    }

    // Get donations sent by user
    @GetMapping("/sent/{userId}")
    public ResponseEntity<List<Donation>> getDonationsSent(@PathVariable Long userId) {
        List<Donation> donations = donationService.getDonationsSent(userId);
        return ResponseEntity.ok(donations);
    }

    // Get donations received by user
    @GetMapping("/received/{userId}")
    public ResponseEntity<List<Donation>> getDonationsReceived(@PathVariable Long userId) {
        List<Donation> donations = donationService.getDonationsReceived(userId);
        return ResponseEntity.ok(donations);
    }

    // Get donation by ID
    @GetMapping("/{id}")
    public ResponseEntity<Donation> getDonation(@PathVariable Long id) {
        try {
            Donation donation = donationService.getDonation(id);
            return ResponseEntity.ok(donation);
        } catch (Exception e) {
            return ResponseEntity.notFound().build();
        }
    }

    // Send thank you
    @PostMapping("/{id}/thank-you")
    public ResponseEntity<Map<String, String>> sendThankYou(@PathVariable Long id) {
        try {
            donationService.sendThankYou(id);
            Map<String, String> response = new HashMap<>();
            response.put("message", "Thank you sent!");
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, String> response = new HashMap<>();
            response.put("error", e.getMessage());
            return ResponseEntity.badRequest().body(response);
        }
    }

    // Get pending thank yous
    @GetMapping("/pending-thanks/{userId}")
    public ResponseEntity<List<Donation>> getPendingThankYous(@PathVariable Long userId) {
        List<Donation> donations = donationService.getPendingThankYous(userId);
        return ResponseEntity.ok(donations);
    }

    // Get user donation statistics
    @GetMapping("/stats/{userId}")
    public ResponseEntity<Map<String, Object>> getUserStats(@PathVariable Long userId) {
        Map<String, Object> stats = donationService.getUserDonationStats(userId);
        return ResponseEntity.ok(stats);
    }

    // Get platform donation statistics
    @GetMapping("/platform/stats")
    public ResponseEntity<Map<String, Object>> getPlatformStats() {
        Map<String, Object> stats = donationService.getPlatformDonationStats();
        return ResponseEntity.ok(stats);
    }

    // Refund donation (admin only)
    @PostMapping("/{id}/refund")
    public ResponseEntity<Map<String, String>> refundDonation(@PathVariable Long id) {
        try {
            donationService.refundDonation(id);
            Map<String, String> response = new HashMap<>();
            response.put("message", "Donation refunded successfully");
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, String> response = new HashMap<>();
            response.put("error", e.getMessage());
            return ResponseEntity.badRequest().body(response);
        }
    }
}

