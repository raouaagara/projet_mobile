package org.example.technicalsupport.service;

import com.fasterxml.jackson.databind.JsonNode;
import org.example.technicalsupport.ai.AiUnavailableException;
import org.example.technicalsupport.ai.GeminiClient;
import org.example.technicalsupport.entity.TicketCategory;
import org.example.technicalsupport.entity.TicketPriority;
import org.springframework.stereotype.Service;

import java.util.Arrays;
import java.util.Optional;

/**
 * A new request read by Gemini in one call: its topic, its priority, a summary and a clearer version.
 * Empty when the AI isn't available: the keyword rules of {@link TicketCategorizationService} decide instead.
 */
@Service
public class TicketAiService {

    public record Analysis(TicketCategory category, TicketPriority priority, String summary, String improvedDescription) {}

    private final GeminiClient gemini;

    public TicketAiService(GeminiClient gemini) {
        this.gemini = gemini;
    }

    public Optional<Analysis> analyze(String title, String description) {
        if (description == null || description.isBlank() || !gemini.isConfigured()) return Optional.empty();
        try {
            JsonNode json = gemini.generateJson("""
                    You triage support requests for Workify, a freelancing platform (projects, proposals,
                    contracts with payments held in escrow, wallet, chat, subscriptions).
                    Read the request and answer with this JSON object only:
                    {
                      "category": one of %s,
                      "priority": one of %s,
                      "summary": "one sentence of at most 20 words, in English, for the support team",
                      "improvedDescription": "the request rewritten clearly and politely, in the user's language, keeping every fact and inventing none"
                    }
                    Priority: CRITICAL for fraud, a security problem or money lost; HIGH when payments or contracts
                    are blocked or the user can't work; MEDIUM for bugs and account problems; LOW for questions and ideas.

                    Title: %s
                    Request: %s
                    """.formatted(Arrays.toString(TicketCategory.values()), Arrays.toString(TicketPriority.values()),
                    title == null ? "" : title, description));
            return Optional.of(new Analysis(
                    parse(TicketCategory.class, json.path("category").asText("")),
                    parse(TicketPriority.class, json.path("priority").asText("")),
                    json.path("summary").asText(""),
                    json.path("improvedDescription").asText(description)));
        } catch (AiUnavailableException e) {
            return Optional.empty();
        }
    }

    private static <E extends Enum<E>> E parse(Class<E> type, String value) {
        try {
            return Enum.valueOf(type, value.trim().toUpperCase());
        } catch (IllegalArgumentException e) {
            return null; // unknown value: the keyword rules decide
        }
    }
}
