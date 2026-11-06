package org.example.referralmicroservice.Services;

import org.example.referralmicroservice.Entities.Donation;
import org.example.referralmicroservice.Entities.UserWallet;
import org.example.referralmicroservice.Repositories.DonationRepository;
import org.example.referralmicroservice.Repositories.UserWalletRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class DonationService {

    @Autowired
    private DonationRepository donationRepository;

    @Autowired
    private UserWalletRepository walletRepository;

    // Donation limits
    private static final Double MAX_DONATION_AMOUNT = 50.0;
    private static final Double DAILY_DONATION_LIMIT = 200.0;
    private static final Integer COOLDOWN_HOURS = 24;

    // Send donation
    @Transactional
    public Donation sendDonation(Long donorId, Long recipientId, Double amount, 
                                 String message, Boolean isAnonymous) {
        // Validation
        validateDonation(donorId, recipientId, amount);

        // Get wallets
        UserWallet donorWallet = walletRepository.findByUserId(donorId)
                .orElseThrow(() -> new RuntimeException("Donor wallet not found"));
        UserWallet recipientWallet = walletRepository.findByUserId(recipientId)
                .orElseGet(() -> {
                    UserWallet wallet = new UserWallet();
                    wallet.setUserId(recipientId);
                    return walletRepository.save(wallet);
                });

        // Check balance
        if (donorWallet.getBalance() < amount) {
            throw new RuntimeException("Insufficient balance. Available: $" + donorWallet.getBalance());
        }

        // Check cooldown (24 hours between donations to same person)
        LocalDateTime cooldownTime = LocalDateTime.now().minusHours(COOLDOWN_HOURS);
        List<Donation> recentDonations = donationRepository
                .findByDonorIdAndRecipientIdAndCreatedAtAfter(donorId, recipientId, cooldownTime);
        
        if (!recentDonations.isEmpty()) {
            throw new RuntimeException("Please wait 24 hours before donating to the same person again");
        }

        // Check daily limit
        LocalDateTime todayStart = LocalDateTime.now().withHour(0).withMinute(0).withSecond(0);
        List<Donation> todayDonations = donationRepository
                .findByCreatedAtBetween(todayStart, LocalDateTime.now())
                .stream()
                .filter(d -> d.getDonorId().equals(donorId) && d.getStatus() == Donation.DonationStatus.COMPLETED)
                .toList();
        
        Double todayTotal = todayDonations.stream()
                .mapToDouble(Donation::getAmount)
                .sum();
        
        if (todayTotal + amount > DAILY_DONATION_LIMIT) {
            throw new RuntimeException("Daily donation limit exceeded. Limit: $" + DAILY_DONATION_LIMIT);
        }

        // Create donation
        Donation donation = new Donation(donorId, recipientId, amount, message, isAnonymous);
        
        // Process transaction
        donorWallet.deductBalance(amount);
        donorWallet.addDonation(amount);
        recipientWallet.addReceived(amount);
        
        // Save changes
        walletRepository.save(donorWallet);
        walletRepository.save(recipientWallet);
        
        donation.complete();
        return donationRepository.save(donation);
    }

    // Validate donation
    private void validateDonation(Long donorId, Long recipientId, Double amount) {
        if (donorId.equals(recipientId)) {
            throw new RuntimeException("Cannot donate to yourself");
        }
        
        if (amount <= 0) {
            throw new RuntimeException("Donation amount must be positive");
        }
        
        if (amount > MAX_DONATION_AMOUNT) {
            throw new RuntimeException("Maximum donation amount is $" + MAX_DONATION_AMOUNT);
        }
    }

    // Get donations sent by user
    public List<Donation> getDonationsSent(Long userId) {
        return donationRepository.findByDonorIdOrderByCreatedAtDesc(userId);
    }

    // Get donations received by user
    public List<Donation> getDonationsReceived(Long userId) {
        return donationRepository.findByRecipientIdOrderByCreatedAtDesc(userId);
    }

    // Get donation by ID
    public Donation getDonation(Long id) {
        return donationRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Donation not found"));
    }

    // Send thank you message
    @Transactional
    public void sendThankYou(Long donationId) {
        Donation donation = getDonation(donationId);
        donation.sendThankYou();
        donationRepository.save(donation);
    }

    // Get pending thank yous for user
    public List<Donation> getPendingThankYous(Long userId) {
        return donationRepository.findByRecipientIdAndThankYouSentFalseAndStatus(
                userId, Donation.DonationStatus.COMPLETED);
    }

    // Get donation statistics for user
    public Map<String, Object> getUserDonationStats(Long userId) {
        Map<String, Object> stats = new HashMap<>();
        
        Double totalDonated = donationRepository.getTotalDonatedByUser(userId);
        Double totalReceived = donationRepository.getTotalReceivedByUser(userId);
        Long donationCount = donationRepository.countDonationsByUser(userId);
        Long peopleHelped = donationRepository.countUniqueRecipientsHelped(userId);
        
        stats.put("totalDonated", totalDonated != null ? totalDonated : 0.0);
        stats.put("totalReceived", totalReceived != null ? totalReceived : 0.0);
        stats.put("donationCount", donationCount);
        stats.put("peopleHelped", peopleHelped);
        stats.put("averageDonation", donationCount > 0 ? totalDonated / donationCount : 0.0);
        
        return stats;
    }

    // Get platform donation statistics
    public Map<String, Object> getPlatformDonationStats() {
        Map<String, Object> stats = new HashMap<>();
        
        Double totalDonations = donationRepository.getTotalPlatformDonations();
        Long donationCount = donationRepository.getTotalDonationCount();
        Double averageDonation = donationRepository.getAverageDonationAmount();
        
        stats.put("totalDonations", totalDonations != null ? totalDonations : 0.0);
        stats.put("donationCount", donationCount);
        stats.put("averageDonation", averageDonation != null ? averageDonation : 0.0);
        
        return stats;
    }

    // Refund donation (admin only, within 24 hours)
    @Transactional
    public void refundDonation(Long donationId) {
        Donation donation = getDonation(donationId);
        
        // Check if within refund window
        if (donation.getCreatedAt().plusHours(24).isBefore(LocalDateTime.now())) {
            throw new RuntimeException("Refund window expired (24 hours)");
        }
        
        if (donation.getStatus() != Donation.DonationStatus.COMPLETED) {
            throw new RuntimeException("Can only refund completed donations");
        }
        
        // Get wallets
        UserWallet donorWallet = walletRepository.findByUserId(donation.getDonorId())
                .orElseThrow(() -> new RuntimeException("Donor wallet not found"));
        UserWallet recipientWallet = walletRepository.findByUserId(donation.getRecipientId())
                .orElseThrow(() -> new RuntimeException("Recipient wallet not found"));
        
        // Reverse transaction
        donorWallet.addBalance(donation.getAmount());
        donorWallet.setTotalDonated(donorWallet.getTotalDonated() - donation.getAmount());
        recipientWallet.deductBalance(donation.getAmount());
        recipientWallet.setTotalReceived(recipientWallet.getTotalReceived() - donation.getAmount());
        
        // Save changes
        walletRepository.save(donorWallet);
        walletRepository.save(recipientWallet);
        
        donation.refund();
        donationRepository.save(donation);
    }
}
