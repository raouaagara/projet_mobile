package org.example.subscriptionmicroservice.Controllers;

import org.example.subscriptionmicroservice.Entities.Payment;
import org.example.subscriptionmicroservice.Entities.SubscriptionPlan;
import org.example.subscriptionmicroservice.Entities.UserSubscription;
import org.example.subscriptionmicroservice.Services.SubscriptionService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/Subscription")
@CrossOrigin(origins = "*")
public class SubscriptionController {

    @Autowired
    private SubscriptionService service;

    @GetMapping("/plans")
    public List<SubscriptionPlan> getAllPlans() {
        return service.getAllPlans();
    }

    @GetMapping("/plans/{id}")
    public SubscriptionPlan getPlanById(@PathVariable Long id) {
        return service.getPlanById(id);
    }

    @PostMapping("/admin/plans")
    public SubscriptionPlan createPlan(@RequestBody SubscriptionPlan plan) {
        return service.createPlan(plan);
    }

    @PutMapping("/admin/plans/{id}")
    public SubscriptionPlan updatePlan(@PathVariable Long id, @RequestBody SubscriptionPlan plan) {
        return service.updatePlan(id, plan);
    }

    @DeleteMapping("/admin/plans/{id}")
    public void deletePlan(@PathVariable Long id) {
        service.deletePlan(id);
    }

    @PostMapping("/subscribe")
    public UserSubscription subscribe(@RequestParam Long userId, 
                                      @RequestParam Long planId,
                                      @RequestParam(required = false) String email) {
        return service.subscribe(userId, planId, email);
    }

    @GetMapping("/user/{userId}/subscriptions")
    public List<UserSubscription> getUserSubscriptions(@PathVariable Long userId) {
        return service.getUserSubscriptions(userId);
    }

    @GetMapping("/user/{userId}/active")
    public ResponseEntity<UserSubscription> getActiveSubscription(@PathVariable Long userId) {
        UserSubscription sub = service.getActiveSubscription(userId);
        return sub != null ? ResponseEntity.ok(sub) : ResponseEntity.noContent().build();
    }

    @PutMapping("/{subscriptionId}/renew")
    public UserSubscription renewSubscription(@PathVariable Long subscriptionId) {
        return service.renewSubscription(subscriptionId);
    }

    @PostMapping("/{subscriptionId}/payment")
    public Payment recordPayment(@PathVariable Long subscriptionId,
                                 @RequestParam Double amount,
                                 @RequestParam(required = false) String paymentMethod) {
        return service.recordPayment(subscriptionId, amount,
                paymentMethod != null ? paymentMethod : "card");
    }

    @GetMapping("/{subscriptionId}/payments")
    public List<Payment> getPayments(@PathVariable Long subscriptionId) {
        return service.getPaymentsBySubscription(subscriptionId);
    }

    @GetMapping("/admin/subscriptions")
    public List<UserSubscription> getAllSubscriptions() {
        return service.getAllSubscriptions();
    }

    @GetMapping("/admin/subscriptions/{id}")
    public UserSubscription getSubscriptionById(@PathVariable Long id) {
        return service.getSubscriptionById(id);
    }

    @PutMapping("/admin/subscriptions/{id}")
    public UserSubscription updateSubscription(@PathVariable Long id, @RequestBody UserSubscription sub) {
        return service.updateSubscription(id, sub);
    }

    @DeleteMapping("/admin/subscriptions/{id}")
    public void deleteSubscription(@PathVariable Long id) {
        service.deleteSubscription(id);
    }

    @GetMapping("/admin/payments/{id}")
    public Payment getPaymentById(@PathVariable Long id) {
        return service.getPaymentById(id);
    }

    @PutMapping("/admin/payments/{id}")
    public Payment updatePayment(@PathVariable Long id, @RequestBody Payment payment) {
        return service.updatePayment(id, payment);
    }

    @DeleteMapping("/admin/payments/{id}")
    public void deletePayment(@PathVariable Long id) {
        service.deletePayment(id);
    }
    
    // Test endpoint to verify email is working
    @GetMapping("/test-email")
    public ResponseEntity<String> testEmailGet(@RequestParam String email) {
        try {
            System.out.println("🧪 Testing email to: " + email);
            // Get first plan
            List<SubscriptionPlan> plans = service.getAllPlans();
            if (plans.isEmpty()) {
                return ResponseEntity.status(400).body("❌ No subscription plans found. Create a plan first.");
            }
            
            SubscriptionPlan plan = plans.get(0);
            
            // Try to send email by creating a subscription
            UserSubscription sub = service.subscribe(1L, plan.getId(), email);
            
            return ResponseEntity.ok("✅ Test email sent to: " + email + ". Check your inbox and spam folder! Subscription ID: " + sub.getId());
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(500).body("❌ Failed: " + e.getMessage() + ". Check backend console for details.");
        }
    }
    
    @GetMapping("/email-config")
    public ResponseEntity<String> checkEmailConfig() {
        return ResponseEntity.ok(
            "Email Configuration:\n" +
            "- Mail enabled: " + (service != null) + "\n" +
            "- Check application.properties for:\n" +
            "  spring.mail.host=smtp.gmail.com\n" +
            "  spring.mail.port=587\n" +
            "  spring.mail.username=ayoub.somrani00@gmail.com\n" +
            "  spring.mail.password=[CONFIGURED]\n" +
            "\nIf email doesn't work:\n" +
            "1. Generate new Gmail App Password: https://myaccount.google.com/apppasswords\n" +
            "2. Update spring.mail.password in application.properties\n" +
            "3. Restart service"
        );
    }
    
    @PostMapping("/test-email")
    public ResponseEntity<String> testEmail(@RequestParam String email) {
        try {
            System.out.println("🧪 Testing email to: " + email);
            // Create a dummy subscription for testing
            SubscriptionPlan plan = service.getAllPlans().get(0);
            UserSubscription testSub = new UserSubscription();
            testSub.setId(999L);
            testSub.setUserId(1L);
            testSub.setPlan(plan);
            testSub.setStatus(org.example.subscriptionmicroservice.Entities.SubscriptionStatus.ACTIVE);
            testSub.setStartDate(java.time.LocalDate.now());
            testSub.setEndDate(java.time.LocalDate.now().plusMonths(1));
            testSub.setAutoRenew(true);
            
            // Try to send email
            service.subscribe(1L, plan.getId(), email);
            
            return ResponseEntity.ok("✅ Test email sent to: " + email + ". Check your inbox!");
        } catch (Exception e) {
            return ResponseEntity.status(500).body("❌ Failed to send email: " + e.getMessage());
        }
    }
}
