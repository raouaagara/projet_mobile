package org.example.subscriptionmicroservice.Controllers;

import org.example.subscriptionmicroservice.Services.CheckoutService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.HashMap;
import java.util.Map;

/**
 * Checkout used by the mobile app (quote → start → confirm). See {@link CheckoutService}.
 * Body fields: userId, planId, promoCode (optional); start also takes successUrl / failUrl,
 * confirm takes paymentId and email (optional, for the confirmation email).
 */
@RestController
@RequestMapping("/Subscription/checkout")
public class CheckoutController {

    @Autowired
    private CheckoutService checkoutService;

    @GetMapping("/mode")
    public Map<String, Object> mode() {
        return Map.of("testMode", checkoutService.isTestMode());
    }

    @PostMapping("/quote")
    public Map<String, Object> quote(@RequestBody Map<String, Object> body) {
        CheckoutService.Quote quote = checkoutService.quote(id(body, "userId"), id(body, "planId"), text(body, "promoCode"));
        Map<String, Object> result = new HashMap<>();
        result.put("planId", quote.plan().getId());
        result.put("planName", quote.plan().getName());
        result.put("price", quote.price());
        result.put("discount", quote.discount());
        result.put("total", quote.total());
        if (quote.promoCode() != null) {
            result.put("promoCode", quote.promoCode().getCode());
            result.put("promoDescription", quote.promoCode().getDescription());
        }
        return result;
    }

    @PostMapping("/start")
    public Map<String, Object> start(@RequestBody Map<String, Object> body) {
        return checkoutService.start(id(body, "userId"), id(body, "planId"), text(body, "promoCode"),
                text(body, "successUrl"), text(body, "failUrl"));
    }

    @PostMapping("/confirm")
    public Map<String, Object> confirm(@RequestBody Map<String, Object> body) {
        return checkoutService.confirm(id(body, "userId"), id(body, "planId"), text(body, "promoCode"),
                text(body, "paymentId"), text(body, "email"));
    }

    private static Long id(Map<String, Object> body, String key) {
        Object value = body.get(key);
        try {
            return Long.valueOf(String.valueOf(value));
        } catch (NumberFormatException e) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, key + " is required");
        }
    }

    private static String text(Map<String, Object> body, String key) {
        Object value = body.get(key);
        return value == null ? null : value.toString();
    }
}
