package org.example.subscriptionmicroservice;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.example.subscriptionmicroservice.Entities.PlanType;
import org.example.subscriptionmicroservice.Entities.SubscriptionPlan;
import org.example.subscriptionmicroservice.Entities.SubscriptionStatus;
import org.example.subscriptionmicroservice.Repositories.SubscriptionPlanRepository;
import org.example.subscriptionmicroservice.Repositories.UserSubscriptionRepository;
import org.example.subscriptionmicroservice.ai.AiUnavailableException;
import org.example.subscriptionmicroservice.ai.GeminiClient;
import org.example.subscriptionmicroservice.ai.PlanAdvisor;
import org.example.subscriptionmicroservice.ai.PlanAdvisor.Activity;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.Mockito.*;

/** The plan advisor, with a fake Gemini (no network). */
class PlanAdvisorTest {

    private final SubscriptionPlanRepository plans = mock(SubscriptionPlanRepository.class);
    private final UserSubscriptionRepository subscriptions = mock(UserSubscriptionRepository.class);
    private String lastPrompt;

    @BeforeEach
    void setUp() {
        SubscriptionPlan base = new SubscriptionPlan();
        base.setId(1L);
        base.setName("Base");
        base.setType(PlanType.BASE);
        base.setPrice(9.99);
        base.setDuration("monthly");
        base.setBenefits("Up to 10 proposals per month");
        SubscriptionPlan premium = new SubscriptionPlan();
        premium.setId(2L);
        premium.setName("Premium");
        premium.setType(PlanType.PREMIUM);
        premium.setPrice(24.99);
        premium.setDuration("monthly");
        premium.setBenefits("Unlimited proposals,AI CV generator");
        when(plans.findAll()).thenReturn(List.of(base, premium));
        when(subscriptions.findByUserIdAndStatusOrderByEndDateDesc(anyLong(), any(SubscriptionStatus.class)))
                .thenReturn(List.of());
    }

    private PlanAdvisor answering(String json) {
        return new PlanAdvisor(plans, subscriptions, new GeminiClient("test-key", "test-model") {
            @Override
            public JsonNode generateJson(String prompt) {
                lastPrompt = prompt;
                try {
                    return new ObjectMapper().readTree(json);
                } catch (Exception e) {
                    throw new IllegalStateException(e);
                }
            }
        });
    }

    private static Activity busy() {
        return new Activity(14, 3, 2, 5, 840.0, 12, 2, 4);
    }

    @Test
    void recommendsARealPlanFromTheActivity() {
        var advice = answering("""
                {"planId": 2, "headline": "Premium pays for itself.", "reasons": ["14 proposals", "a", "b", "c"],
                 "worthIt": "$24.99 is 3% of the $840 you earned."}""").advise(7L, busy());

        assertEquals(2L, advice.planId());
        assertEquals("Premium", advice.planName());
        assertEquals(3, advice.reasons().size());
        assertTrue(lastPrompt.contains("id 2: Premium, $24.99 monthly") && lastPrompt.contains("Proposals sent (all time): 14"));
        assertTrue(lastPrompt.contains("Earned in the last 30 days: $840.00") && lastPrompt.contains("Current plan: none (free)"));
    }

    @Test
    void anInventedPlanBecomesStayFree() {
        var advice = answering("{\"planId\": 99, \"headline\": \"Gold!\", \"reasons\": []}").advise(7L, null);
        assertNull(advice.planId());
        assertTrue(lastPrompt.contains("Proposals sent (all time): unknown"));
    }

    @Test
    void staysFreeWhenThatIsHonest() {
        var advice = answering("{\"planId\": null, \"headline\": \"Stay free for now.\", \"reasons\": [\"1 proposal\"]}")
                .advise(7L, new Activity(1, 0, 0, 0, 0.0, 2, 0, 0));
        assertNull(advice.planId());
        assertEquals("Stay free for now.", advice.headline());
    }

    @Test
    void emptyAnswerOrNoPlans() {
        assertThrows(AiUnavailableException.class, () -> answering("{\"headline\": \"\"}").advise(7L, busy()));
        when(plans.findAll()).thenReturn(List.of());
        assertThrows(IllegalStateException.class, () -> answering("{}").advise(7L, busy()));
    }
}
