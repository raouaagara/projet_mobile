package org.example.subscriptionmicroservice.ai;

import com.fasterxml.jackson.databind.JsonNode;
import org.example.subscriptionmicroservice.Entities.SubscriptionPlan;
import org.example.subscriptionmicroservice.Entities.SubscriptionStatus;
import org.example.subscriptionmicroservice.Entities.UserSubscription;
import org.example.subscriptionmicroservice.Repositories.SubscriptionPlanRepository;
import org.example.subscriptionmicroservice.Repositories.UserSubscriptionRepository;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

/**
 * "Which plan fits me?": Gemini reads the freelancer's real activity (sent by the app from modules 1–3)
 * and the plans in the database, and picks one — or none, when no plan would pay for itself.
 */
@Service
public class PlanAdvisor {

    /** What the freelancer did lately, as the app sees it. Null fields are unknown. */
    public record Activity(Integer proposalsSent, Integer acceptedProposals, Integer activeContracts,
                           Integer completedContracts, Double earnedLast30Days, Integer skills,
                           Integer certificates, Integer cvAssistantUses) {}

    /** {@code planId} null: stay on the free version for now. */
    public record Advice(Long planId, String planName, String headline, List<String> reasons, String worthIt) {}

    private final SubscriptionPlanRepository plans;
    private final UserSubscriptionRepository subscriptions;
    private final GeminiClient gemini;

    public PlanAdvisor(SubscriptionPlanRepository plans, UserSubscriptionRepository subscriptions, GeminiClient gemini) {
        this.plans = plans;
        this.subscriptions = subscriptions;
        this.gemini = gemini;
    }

    public Advice advise(Long userId, Activity activity) {
        List<SubscriptionPlan> all = plans.findAll();
        if (all.isEmpty()) throw new IllegalStateException("No plan to recommend yet.");
        String current = subscriptions.findByUserIdAndStatusOrderByEndDateDesc(userId, SubscriptionStatus.ACTIVE)
                .stream().findFirst().map(UserSubscription::getPlan).map(SubscriptionPlan::getName).orElse("none (free)");

        StringBuilder catalog = new StringBuilder();
        for (SubscriptionPlan p : all) {
            catalog.append("- id ").append(p.getId()).append(": ").append(p.getName())
                    .append(", ").append(money(p.getPrice())).append(" ").append(Objects.toString(p.getDuration(), ""))
                    .append(". ").append(Objects.toString(p.getDescription(), ""))
                    .append(" Benefits: ").append(Objects.toString(p.getBenefits(), "")).append('\n');
        }
        Activity a = activity == null ? new Activity(null, null, null, null, null, null, null, null) : activity;
        String prompt = """
                You advise a freelancer on Workify, a freelance marketplace, about which subscription plan fits them.
                Use ONLY the plans and the activity below. Be honest: if no plan would pay for itself, recommend
                staying free (planId null). Write in English, simply, as a friendly advisor.

                Return JSON:
                {"planId": <one of the ids below, or null>,
                 "headline": "one sentence, at most 90 characters",
                 "reasons": ["2 or 3 short reasons, each linked to a number from their activity"],
                 "worthIt": "one sentence comparing the price with what they earn or would use; no invented numbers"}

                PLANS
                %s
                Current plan: %s

                THEIR ACTIVITY
                Proposals sent (all time): %s
                Proposals accepted (all time): %s
                Contracts in progress: %s
                Contracts completed: %s
                Earned in the last 30 days: %s
                Skills on profile: %s
                Certificates: %s
                AI CV assistant uses: %s
                """.formatted(catalog, current, n(a.proposalsSent()), n(a.acceptedProposals()),
                n(a.activeContracts()), n(a.completedContracts()), money(a.earnedLast30Days()), n(a.skills()),
                n(a.certificates()), n(a.cvAssistantUses()));

        JsonNode json = gemini.generateJson(prompt);
        String headline = json.path("headline").asText("").strip();
        if (headline.isEmpty()) throw new AiUnavailableException("The AI gave an empty answer. Try again.");
        // Only a plan that really exists.
        Long id = json.path("planId").isNumber() ? json.path("planId").asLong() : null;
        SubscriptionPlan chosen = id == null ? null : all.stream().filter(p -> p.getId().equals(id)).findFirst().orElse(null);
        List<String> reasons = new ArrayList<>();
        for (JsonNode r : json.path("reasons")) {
            String s = r.asText("").strip();
            if (!s.isEmpty() && reasons.size() < 3) reasons.add(s);
        }
        return new Advice(chosen == null ? null : chosen.getId(), chosen == null ? null : chosen.getName(), headline,
                reasons, json.path("worthIt").asText("").strip());
    }

    private static String n(Integer value) {
        return value == null ? "unknown" : value.toString();
    }

    private static String money(Double amount) {
        if (amount == null) return "unknown";
        return String.format(java.util.Locale.ROOT, "$%.2f", amount);
    }
}
