package org.example.subscriptionmicroservice.Services;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

@Service
public class RewardScheduler {

    @Autowired
    private PromoCodeService promoCodeService;

    // Run every day at 2 AM to deactivate expired codes
    @Scheduled(cron = "0 0 2 * * *")
    public void deactivateExpiredCodes() {
        System.out.println("Running scheduled task: Deactivating expired promo codes...");
        promoCodeService.deactivateExpiredCodes();
        System.out.println("Expired promo codes deactivated successfully.");
    }

    // TODO: Add more scheduled tasks for:
    // - Checking loyalty milestones (3 months, 6 months)
    // - Checking referral milestones
    // - Sending reminder notifications for expiring codes
}
