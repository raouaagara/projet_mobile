package org.example.subscriptionmicroservice.Config;

import org.example.subscriptionmicroservice.Entities.PlanType;
import org.example.subscriptionmicroservice.Entities.SubscriptionPlan;
import org.example.subscriptionmicroservice.Entities.SubscriptionStatus;
import org.example.subscriptionmicroservice.Entities.UserSubscription;
import org.example.subscriptionmicroservice.Repositories.SubscriptionPlanRepository;
import org.example.subscriptionmicroservice.Repositories.UserSubscriptionRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import java.time.LocalDate;
import java.util.List;

@Component
public class DataInitializer implements CommandLineRunner {

    @Autowired
    private SubscriptionPlanRepository planRepository;

    @Autowired
    private UserSubscriptionRepository userSubscriptionRepository;

    @Override
    public void run(String... args) {
        if (planRepository.count() == 0) {
            // Base Plan
            SubscriptionPlan base = new SubscriptionPlan();
            base.setName("Base");
            base.setType(PlanType.BASE);
            base.setPrice(9.99);
            base.setDuration("monthly");
            base.setDescription("Perfect for freelancers getting started.");
            base.setBenefits("Up to 10 proposals per month,Basic profile visibility,Access to job feed,Email support");
            base.setHasAiCvAccess(false);
            planRepository.save(base);

            // Premium Plan
            SubscriptionPlan premium = new SubscriptionPlan();
            premium.setName("Premium");
            premium.setType(PlanType.PREMIUM);
            premium.setPrice(24.99);
            premium.setDuration("monthly");
            premium.setDescription("Our most popular plan with AI CV generator.");
            premium.setBenefits("Unlimited proposals,Featured visibility,AI CV generator,Priority support,Analytics");
            premium.setHasAiCvAccess(true);
            premium.setAiCvLimit(10);
            planRepository.save(premium);

            // Enterprise Plan
            SubscriptionPlan enterprise = new SubscriptionPlan();
            enterprise.setName("Enterprise");
            enterprise.setType(PlanType.ENTERPRISE);
            enterprise.setPrice(49.99);
            enterprise.setDuration("monthly");
            enterprise.setDescription("For teams with unlimited AI CV access.");
            enterprise.setBenefits("Everything in Premium,AI CV unlimited,Group subscription,Dedicated support");
            enterprise.setHasAiCvAccess(true);
            enterprise.setAiCvLimit(null); // unlimited
            planRepository.save(enterprise);
        }

        // Seed test subscriptions (userId 1,2,3 from UserMicroService)
        if (userSubscriptionRepository.count() == 0) {
            List<SubscriptionPlan> plans = planRepository.findAll();
            if (plans.size() >= 3) {
                for (int i = 0; i < 3; i++) {
                    UserSubscription sub = new UserSubscription();
                    sub.setUserId((long) (i + 1));
                    sub.setPlan(plans.get(Math.min(i, plans.size() - 1)));
                    sub.setStatus(SubscriptionStatus.ACTIVE);
                    sub.setStartDate(LocalDate.now().minusMonths(1));
                    sub.setEndDate(LocalDate.now().plusMonths(1));
                    sub.setAutoRenew(true);
                    userSubscriptionRepository.save(sub);
                }
            }
        }
    }
}
