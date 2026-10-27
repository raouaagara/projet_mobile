package org.example.subscriptionmicroservice.Services;

import org.example.subscriptionmicroservice.Entities.*;
import org.example.subscriptionmicroservice.Repositories.PaymentRepository;
import org.example.subscriptionmicroservice.Repositories.SubscriptionPlanRepository;
import org.example.subscriptionmicroservice.Repositories.UserSubscriptionRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Service
public class SubscriptionService {

    @Autowired
    private SubscriptionPlanRepository planRepository;

    @Autowired
    private UserSubscriptionRepository userSubscriptionRepository;

    @Autowired
    private PaymentRepository paymentRepository;

    @Autowired
    private EmailService emailService;

    // --- Subscription Plans ---
    public List<SubscriptionPlan> getAllPlans() {
        return planRepository.findAll();
    }

    public SubscriptionPlan getPlanById(Long id) {
        return planRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Plan not found"));
    }

    public SubscriptionPlan createPlan(SubscriptionPlan plan) {
        return planRepository.save(plan);
    }

    public SubscriptionPlan updatePlan(Long id, SubscriptionPlan updates) {
        SubscriptionPlan existing = getPlanById(id);
        if (updates.getName() != null) existing.setName(updates.getName());
        if (updates.getType() != null) existing.setType(updates.getType());
        if (updates.getPrice() != null) existing.setPrice(updates.getPrice());
        if (updates.getDuration() != null) existing.setDuration(updates.getDuration());
        if (updates.getDescription() != null) existing.setDescription(updates.getDescription());
        if (updates.getBenefits() != null) existing.setBenefits(updates.getBenefits());
        if (updates.getHasAiCvAccess() != null) existing.setHasAiCvAccess(updates.getHasAiCvAccess());
        if (updates.getAiCvLimit() != null) existing.setAiCvLimit(updates.getAiCvLimit());
        return planRepository.save(existing);
    }

    public void deletePlan(Long id) {
        planRepository.deleteById(id);
    }

    // --- User Subscriptions ---
    public UserSubscription subscribe(Long userId, Long planId, String email) {
        System.out.println("📝 Creating subscription for userId: " + userId + ", planId: " + planId);
        System.out.println("📧 Email parameter received: " + (email != null ? email : "NULL"));
        
        SubscriptionPlan plan = getPlanById(planId);

        // One plan at a time: the new one replaces the current one (it used to stay ACTIVE too).
        for (UserSubscription previous : userSubscriptionRepository.findByUserIdAndStatusOrderByEndDateDesc(userId, SubscriptionStatus.ACTIVE)) {
            previous.setStatus(SubscriptionStatus.EXPIRED);
            previous.setEndDate(LocalDate.now());
            userSubscriptionRepository.save(previous);
        }

        UserSubscription subscription = new UserSubscription();
        subscription.setUserId(userId);
        subscription.setPlan(plan);
        subscription.setStatus(SubscriptionStatus.ACTIVE);
        subscription.setStartDate(LocalDate.now());
        subscription.setEndDate(LocalDate.now().plusMonths(1));
        subscription.setAutoRenew(true);
        
        UserSubscription savedSubscription = userSubscriptionRepository.save(subscription);
        System.out.println("✅ Subscription created with ID: " + savedSubscription.getId());
        
        // Send confirmation email if email provided
        if (email != null && !email.isEmpty()) {
            try {
                System.out.println("📧 Calling emailService.sendSubscriptionConfirmation()");
                emailService.sendSubscriptionConfirmation(email, savedSubscription);
            } catch (Exception e) {
                System.err.println("❌ Failed to send subscription email: " + e.getMessage());
                e.printStackTrace();
                // Don't fail the subscription if email fails
            }
        } else {
            System.out.println("⚠️ No email provided - skipping email notification");
        }
        
        return savedSubscription;
    }
    
    // Overloaded method for backward compatibility
    public UserSubscription subscribe(Long userId, Long planId) {
        return subscribe(userId, planId, null);
    }

    @Transactional(readOnly = true)
    public List<UserSubscription> getAllSubscriptions() {
        return userSubscriptionRepository.findAll();
    }

    public List<UserSubscription> getUserSubscriptions(Long userId) {
        return userSubscriptionRepository.findByUserId(userId);
    }

    public UserSubscription getActiveSubscription(Long userId) {
        var list = userSubscriptionRepository.findByUserIdAndStatusOrderByEndDateDesc(userId, SubscriptionStatus.ACTIVE);
        // A subscription past its end date is over, even if nobody updated its status yet.
        LocalDate today = LocalDate.now();
        for (UserSubscription sub : list) {
            if (sub.getEndDate() != null && sub.getEndDate().isBefore(today)) {
                sub.setStatus(SubscriptionStatus.EXPIRED);
                userSubscriptionRepository.save(sub);
            }
        }
        list = list.stream().filter(s -> s.getStatus() == SubscriptionStatus.ACTIVE).toList();
        return list.isEmpty() ? null : list.get(0);
    }

    public UserSubscription getSubscriptionById(Long id) {
        return userSubscriptionRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Subscription not found"));
    }

    public UserSubscription updateSubscription(Long id, UserSubscription updates) {
        UserSubscription existing = getSubscriptionById(id);
        if (updates.getStatus() != null) existing.setStatus(updates.getStatus());
        if (updates.getStartDate() != null) existing.setStartDate(updates.getStartDate());
        if (updates.getEndDate() != null) existing.setEndDate(updates.getEndDate());
        if (updates.getAutoRenew() != null) existing.setAutoRenew(updates.getAutoRenew());
        if (updates.getPlan() != null) existing.setPlan(updates.getPlan());
        return userSubscriptionRepository.save(existing);
    }

    public void deleteSubscription(Long id) {
        userSubscriptionRepository.deleteById(id);
    }

    public UserSubscription renewSubscription(Long subscriptionId) {
        UserSubscription sub = getSubscriptionById(subscriptionId);
        sub.setEndDate(sub.getEndDate().plusMonths(1));
        return userSubscriptionRepository.save(sub);
    }

    // --- Payments ---
    public Payment recordPayment(Long subscriptionId, Double amount, String paymentMethod) {
        UserSubscription sub = userSubscriptionRepository.findById(subscriptionId)
                .orElseThrow(() -> new RuntimeException("Subscription not found"));
        Payment payment = new Payment();
        payment.setUserSubscription(sub);
        payment.setAmount(amount);
        payment.setPaymentMethod(paymentMethod);
        payment.setStatus("PAID");
        payment.setPaidAt(LocalDateTime.now());
        payment.setInvoiceRef("INV-" + System.currentTimeMillis());
        return paymentRepository.save(payment);
    }

    public List<Payment> getPaymentsBySubscription(Long subscriptionId) {
        return paymentRepository.findByUserSubscription_Id(subscriptionId);
    }

    public Payment getPaymentById(Long id) {
        return paymentRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Payment not found"));
    }

    public Payment updatePayment(Long id, Payment updates) {
        Payment existing = getPaymentById(id);
        if (updates.getAmount() != null) existing.setAmount(updates.getAmount());
        if (updates.getPaymentMethod() != null) existing.setPaymentMethod(updates.getPaymentMethod());
        if (updates.getStatus() != null) existing.setStatus(updates.getStatus());
        return paymentRepository.save(existing);
    }

    public void deletePayment(Long id) {
        paymentRepository.deleteById(id);
    }
}
