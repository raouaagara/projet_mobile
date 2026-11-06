package org.example.technicalsupport.service;

import org.example.technicalsupport.ai.AiUnavailableException;
import org.example.technicalsupport.ai.GeminiClient;
import org.springframework.stereotype.Service;

/** One-sentence summary of a request for the support team, by Gemini. Empty when the AI isn't available. */
@Service
public class TicketSummarizationService {

    private final GeminiClient gemini;

    public TicketSummarizationService(GeminiClient gemini) {
        this.gemini = gemini;
    }

    public String summarize(String description) {
        if (description == null || description.isBlank() || !gemini.isConfigured()) return "";
        try {
            return gemini.generate("""
                    Summarize this support request from a user of Workify (a freelancing platform)
                    in one short sentence of at most 20 words, in English, for the support team.
                    Answer with the sentence only.

                    Request: %s
                    """.formatted(description));
        } catch (AiUnavailableException e) {
            return "";
        }
    }
}
