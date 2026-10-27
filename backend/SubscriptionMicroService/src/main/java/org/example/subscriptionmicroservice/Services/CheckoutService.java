package org.example.subscriptionmicroservice.Services;

import org.example.subscriptionmicroservice.Entities.Payment;
import org.example.subscriptionmicroservice.Entities.PromoCode;
import org.example.subscriptionmicroservice.Entities.SubscriptionPlan;
import org.example.subscriptionmicroservice.Entities.UserSubscription;
import org.example.subscriptionmicroservice.Repositories.PaymentRepository;
import org.example.subscriptionmicroservice.Repositories.UserSubscriptionRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

/**
 * Server-side checkout: the price (with a promo code) is computed here, the Flouci payment is
 * created and verified here, and only then is the plan activated. Apps can't subscribe without
 * paying, reuse a payment, or pay for one plan and get another.
 *
 * Without Flouci credentials the service runs in test mode: payments are simulated ("TEST_" ids)
 * and nothing is charged. Test ids are refused as soon as real credentials are configured.
 */
@Service
public class CheckoutService {

    private static final String FLOUCI_API_URL = "https://developers.flouci.com/api";

    @Value("${flouci.app.token:YOUR_FLOUCI_APP_TOKEN}")
    private String appToken;

    @Value("${flouci.app.secret:YOUR_FLOUCI_APP_SECRET}")
    private String appSecret;

    @Autowired private SubscriptionService subscriptionService;
    @Autowired private PromoCodeService promoCodeService;
    @Autowired private UserSubscriptionRepository subscriptionRepository;
    @Autowired private PaymentRepository paymentRepository;

    private final RestTemplate restTemplate = new RestTemplate();

    public record Quote(SubscriptionPlan plan, double price, double discount, double total, PromoCode promoCode) {}

    public boolean isTestMode() {
        return appToken == null || appToken.isBlank() || appToken.startsWith("YOUR_");
    }

    /** Price of [planId] for [userId], with [code] applied. Throws 400/404 with a readable reason. */
    public Quote quote(Long userId, Long planId, String code) {
        SubscriptionPlan plan;
        try {
            plan = subscriptionService.getPlanById(planId);
        } catch (RuntimeException e) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "This plan doesn't exist.");
        }
        double price = plan.getPrice();
        if (code == null || code.isBlank()) {
            return new Quote(plan, price, 0, round(price), null);
        }
        PromoCode promo = promoCodeService.getCodeByString(code.trim())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.BAD_REQUEST, "This promo code doesn't exist."));
        if (!promo.getUserId().equals(userId)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "This promo code belongs to another account.");
        }
        if (!promo.canBeUsed()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "This promo code was already used or has expired.");
        }
        int subscriptionsSoFar = subscriptionRepository.findByUserId(userId).size();
        if (subscriptionsSoFar < promo.getMinSubscriptionCount()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "This promo code works from your next subscription on.");
        }
        double discount = round(promoCodeService.calculateDiscount(promo, price));
        return new Quote(plan, price, discount, round(price - discount), promo);
    }

    /** Creates the payment. Returns {free: true} when nothing is due (100% promo). */
    public Map<String, Object> start(Long userId, Long planId, String code, String successUrl, String failUrl) {
        Quote quote = quote(userId, planId, code);
        Map<String, Object> result = new HashMap<>();
        result.put("total", quote.total());
        result.put("testMode", isTestMode());
        if (quote.total() <= 0) {
            result.put("free", true);
            return result;
        }
        String success = successUrl == null || successUrl.isBlank() ? "https://catchopp.app/payment/success" : successUrl;
        if (isTestMode()) {
            String paymentId = "TEST_" + UUID.randomUUID();
            result.put("paymentId", paymentId);
            result.put("link", success + (success.contains("?") ? "&" : "?") + "payment_id=" + paymentId);
            return result;
        }

        Map<String, Object> body = new HashMap<>();
        body.put("app_token", appToken);
        body.put("app_secret", appSecret);
        body.put("amount", (int) Math.round(quote.total() * 1000)); // millimes
        body.put("accept_card", "true");
        body.put("session_timeout_secs", 1200);
        body.put("success_link", success);
        body.put("fail_link", failUrl == null ? "" : failUrl);
        body.put("developer_tracking_id", "SUB_" + userId + "_" + planId + "_" + System.currentTimeMillis());
        try {
            Map<?, ?> response = restTemplate.exchange(FLOUCI_API_URL + "/generate_payment", HttpMethod.POST,
                    new HttpEntity<>(body, flouciHeaders()), Map.class).getBody();
            Map<?, ?> flouci = response == null ? null : (Map<?, ?>) response.get("result");
            if (flouci == null || flouci.get("payment_id") == null) {
                throw new IllegalStateException("no payment id");
            }
            result.put("paymentId", flouci.get("payment_id"));
            result.put("link", flouci.get("link"));
            return result;
        } catch (RuntimeException e) {
            throw new ResponseStatusException(HttpStatus.BAD_GATEWAY, "The payment service is unavailable. Try again later.");
        }
    }

    /**
     * Verifies the payment, then activates the plan: renews it if it's the current one,
     * otherwise replaces the current subscription. Records the payment and uses the promo code.
     */
    @Transactional
    public Map<String, Object> confirm(Long userId, Long planId, String code, String paymentId, String email) {
        Quote quote = quote(userId, planId, code);
        String method;
        if (quote.total() > 0) {
            if (paymentId == null || paymentId.isBlank()) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "The payment is missing.");
            }
            if (paymentRepository.existsByTransactionRef(paymentId)) {
                throw new ResponseStatusException(HttpStatus.CONFLICT, "This payment was already used.");
            }
            if (isTestMode()) {
                if (!paymentId.startsWith("TEST_")) {
                    throw new ResponseStatusException(HttpStatus.PAYMENT_REQUIRED, "The payment was not completed.");
                }
                method = "flouci-test";
            } else {
                verifyWithFlouci(paymentId, quote.total());
                method = "flouci";
            }
        } else {
            method = quote.promoCode() != null ? "promo-code" : "free";
        }

        UserSubscription active = subscriptionService.getActiveSubscription(userId);
        boolean renewed = active != null && active.getPlan().getId().equals(planId);
        UserSubscription subscription;
        if (renewed) {
            LocalDate today = LocalDate.now();
            LocalDate from = active.getEndDate() != null && active.getEndDate().isAfter(today) ? active.getEndDate() : today;
            active.setEndDate(from.plusMonths(1));
            subscription = subscriptionRepository.save(active);
        } else {
            subscription = subscriptionService.subscribe(userId, planId, email); // replaces the current plan
        }

        Payment payment = new Payment();
        payment.setUserSubscription(subscription);
        payment.setAmount(quote.total());
        payment.setPaymentMethod(method);
        payment.setStatus("PAID");
        payment.setPaidAt(LocalDateTime.now());
        payment.setInvoiceRef("INV-" + System.currentTimeMillis());
        payment.setTransactionRef(quote.total() > 0 ? paymentId : null);
        paymentRepository.save(payment);

        if (quote.promoCode() != null) {
            promoCodeService.applyPromoCode(quote.promoCode().getCode(), subscription.getId());
        }

        Map<String, Object> result = new HashMap<>();
        result.put("subscription", subscription);
        result.put("payment", payment);
        result.put("renewed", renewed);
        result.put("total", quote.total());
        return result;
    }

    private void verifyWithFlouci(String paymentId, double total) {
        Map<?, ?> flouci;
        try {
            Map<?, ?> response = restTemplate.exchange(FLOUCI_API_URL + "/verify_payment/" + paymentId, HttpMethod.GET,
                    new HttpEntity<>(flouciHeaders()), Map.class).getBody();
            flouci = response == null ? null : (Map<?, ?>) response.get("result");
        } catch (RuntimeException e) {
            throw new ResponseStatusException(HttpStatus.BAD_GATEWAY, "The payment could not be verified. Try again later.");
        }
        boolean paid = flouci != null && "SUCCESS".equalsIgnoreCase(String.valueOf(flouci.get("status")));
        double paidMillimes = flouci != null && flouci.get("amount") instanceof Number n ? n.doubleValue() : 0;
        if (!paid || paidMillimes + 0.5 < total * 1000) {
            throw new ResponseStatusException(HttpStatus.PAYMENT_REQUIRED, "The payment was not completed.");
        }
    }

    private HttpHeaders flouciHeaders() {
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.set("apppublic", appToken);
        headers.set("appsecret", appSecret);
        return headers;
    }

    private static double round(double amount) {
        return Math.round(amount * 100) / 100.0;
    }
}
