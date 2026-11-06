package org.example.technicalsupport.service;

import org.example.technicalsupport.ai.GeminiClient;
import org.springframework.stereotype.Service;

/**
 * "Improve with AI" on a support request: Gemini rewrites it clearly, keeping every fact.
 * Without AI it throws AiUnavailableException, so the user sees why nothing changed.
 */
@Service
public class TicketEnhancementService {

    private final GeminiClient gemini;

    public TicketEnhancementService(GeminiClient gemini) {
        this.gemini = gemini;
    }

    public String enhance(String title, String description) {
        if (description == null || description.isBlank()) return description;
        return gemini.generate("""
                You help users of Workify, a freelancing platform, write support requests.
                Rewrite the request below so the support team understands it at once: clear, polite,
                complete sentences. Keep every fact (amounts, contract or project numbers, dates, names),
                never invent one, and write in the same language as the user.
                Answer with the rewritten request only: no title, no quotes, no comments.

                Title: %s
                Request: %s
                """.formatted(title == null ? "" : title, description));
    }
}
