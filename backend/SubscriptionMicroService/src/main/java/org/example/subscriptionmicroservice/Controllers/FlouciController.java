package org.example.subscriptionmicroservice.Controllers;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestTemplate;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/Subscription/flouci")
@CrossOrigin(origins = "http://localhost", allowedHeaders = "*", methods = {RequestMethod.GET, RequestMethod.POST, RequestMethod.PUT, RequestMethod.DELETE, RequestMethod.OPTIONS})
public class FlouciController {

    @Value("${flouci.app.token:YOUR_FLOUCI_APP_TOKEN}")
    private String appToken;

    @Value("${flouci.app.secret:YOUR_FLOUCI_APP_SECRET}")
    private String appSecret;

    private static final String FLOUCI_API_URL = "https://developers.flouci.com/api";

    private final RestTemplate restTemplate = new RestTemplate();

    /**
     * Initiate Flouci payment
     * POST /Subscription/flouci/initiate
     */
    @PostMapping("/initiate")
    public ResponseEntity<Map<String, Object>> initiatePayment(@RequestBody Map<String, Object> request) {
        try {
            // Validate configuration
            if (appToken == null || appToken.equals("YOUR_FLOUCI_APP_TOKEN")) {
                Map<String, Object> error = new HashMap<>();
                error.put("success", false);
                error.put("message", "Flouci is not configured. Please add your credentials to application.properties");
                return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE).body(error);
            }

            // Extract request parameters
            Double amount = request.get("amount") != null ? ((Number) request.get("amount")).doubleValue() : 0.0;
            String description = (String) request.getOrDefault("description", "Payment");
            String successUrl = (String) request.getOrDefault("successUrl", "");
            String failUrl = (String) request.getOrDefault("failUrl", "");
            String developerTrackingId = (String) request.getOrDefault("developerTrackingId", "SUB_" + System.currentTimeMillis());

            // Validate required fields
            if (amount <= 0) {
                Map<String, Object> error = new HashMap<>();
                error.put("success", false);
                error.put("message", "Invalid amount");
                return ResponseEntity.badRequest().body(error);
            }

            // Prepare Flouci API request
            Map<String, Object> flouciRequest = new HashMap<>();
            flouciRequest.put("app_token", appToken);
            flouciRequest.put("app_secret", appSecret);
            flouciRequest.put("amount", (int) (amount * 1000)); // Convert TND to millimes
            flouciRequest.put("accept_card", "true");
            flouciRequest.put("session_timeout_secs", 1200); // 20 minutes
            flouciRequest.put("success_link", successUrl);
            flouciRequest.put("fail_link", failUrl);
            flouciRequest.put("developer_tracking_id", developerTrackingId);

            // Set headers
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.set("apppublic", appToken);
            headers.set("appsecret", appSecret);

            HttpEntity<Map<String, Object>> entity = new HttpEntity<>(flouciRequest, headers);

            // Call Flouci API
            ResponseEntity<Map> response = restTemplate.exchange(
                    FLOUCI_API_URL + "/generate_payment",
                    HttpMethod.POST,
                    entity,
                    Map.class
            );

            return ResponseEntity.ok(response.getBody());

        } catch (Exception e) {
            System.err.println("Flouci payment initiation error: " + e.getMessage());
            e.printStackTrace();
            
            Map<String, Object> error = new HashMap<>();
            error.put("success", false);
            error.put("message", "Failed to initiate Flouci payment: " + e.getMessage());
            error.put("details", "Check backend logs for more information");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(error);
        }
    }

    /**
     * Verify Flouci payment
     * GET /Subscription/flouci/verify/{paymentId}
     */
    @GetMapping("/verify/{paymentId}")
    public ResponseEntity<Map<String, Object>> verifyPayment(@PathVariable String paymentId) {
        try {
            // Set headers
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.set("apppublic", appToken);

            HttpEntity<String> entity = new HttpEntity<>(headers);

            // Call Flouci API
            ResponseEntity<Map> response = restTemplate.exchange(
                    FLOUCI_API_URL + "/verify_payment/" + paymentId,
                    HttpMethod.GET,
                    entity,
                    Map.class
            );

            return ResponseEntity.ok(response.getBody());

        } catch (Exception e) {
            Map<String, Object> error = new HashMap<>();
            error.put("success", false);
            error.put("message", "Failed to verify Flouci payment: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(error);
        }
    }

    /**
     * Webhook endpoint for Flouci payment notifications
     * POST /Subscription/flouci/webhook
     */
    @PostMapping("/webhook")
    public ResponseEntity<String> handleWebhook(@RequestBody Map<String, Object> payload) {
        try {
            // Log the webhook payload
            System.out.println("Flouci Webhook received: " + payload);

            // Extract payment information
            String paymentId = (String) payload.get("payment_id");
            String status = (String) payload.get("status");
            
            // Process the payment status
            // You can update your database here based on the payment status
            
            return ResponseEntity.ok("Webhook processed successfully");

        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body("Webhook processing failed: " + e.getMessage());
        }
    }

    /**
     * Get Flouci configuration status
     * GET /Subscription/flouci/status
     */
    @GetMapping("/status")
    public ResponseEntity<Map<String, Object>> getStatus() {
        Map<String, Object> status = new HashMap<>();
        status.put("configured", !appToken.equals("YOUR_FLOUCI_APP_TOKEN"));
        status.put("apiUrl", FLOUCI_API_URL);
        status.put("testMode", appToken.equals("YOUR_FLOUCI_APP_TOKEN"));
        return ResponseEntity.ok(status);
    }

    /**
     * TEST MODE: Initiate mock payment (for testing without credentials)
     * POST /Subscription/flouci/test/initiate
     */
    @PostMapping("/test/initiate")
    public ResponseEntity<Map<String, Object>> testInitiatePayment(@RequestBody Map<String, Object> request) {
        Map<String, Object> response = new HashMap<>();
        Map<String, Object> result = new HashMap<>();
        
        String planId = request.get("planId") != null ? request.get("planId").toString() : "1";
        String testPaymentId = "TEST_" + System.currentTimeMillis();
        
        // Create mock payment link that redirects back to checkout with success
        String baseUrl = request.get("successUrl") != null ? 
            request.get("successUrl").toString().split("\\?")[0] : 
            "http://localhost/SubscriptionCheckout/" + planId;
            
        result.put("link", baseUrl + "?payment_id=" + testPaymentId + "&status=success");
        result.put("payment_id", testPaymentId);
        
        response.put("result", result);
        response.put("success", true);
        response.put("testMode", true);
        response.put("message", "TEST MODE: Using mock payment. Configure real Flouci credentials in application.properties");
        
        return ResponseEntity.ok(response);
    }

    /**
     * TEST MODE: Verify mock payment
     * GET /Subscription/flouci/test/verify/{paymentId}
     */
    @GetMapping("/test/verify/{paymentId}")
    public ResponseEntity<Map<String, Object>> testVerifyPayment(@PathVariable String paymentId) {
        System.out.println("TEST MODE: Verifying payment: " + paymentId);
        
        Map<String, Object> response = new HashMap<>();
        Map<String, Object> result = new HashMap<>();
        
        result.put("status", "SUCCESS");
        result.put("amount", 30000); // 30 TND in millimes
        result.put("transaction_id", "TEST_TXN_" + paymentId);
        
        response.put("result", result);
        response.put("success", true);
        response.put("testMode", true);
        
        System.out.println("TEST MODE: Returning success response");
        return ResponseEntity.ok(response);
    }
}

