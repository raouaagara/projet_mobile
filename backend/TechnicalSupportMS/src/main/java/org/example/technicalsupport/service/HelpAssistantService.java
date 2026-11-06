package org.example.technicalsupport.service;

import com.fasterxml.jackson.databind.JsonNode;
import org.example.technicalsupport.ai.AiUnavailableException;
import org.example.technicalsupport.ai.GeminiClient;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.io.UncheckedIOException;
import java.nio.charset.StandardCharsets;
import java.util.List;

/**
 * The help assistant shown before a support request: answers from the Workify help guide
 * (resources/help/workify-help.md) only. When the guide doesn't cover it, or it needs the team
 * (money, a bug, an account), it says so and drafts the request for the user.
 */
@Service
public class HelpAssistantService {

    public record Turn(String role, String text) {}

    public record Answer(String answer, boolean needsTicket, String ticketTitle, String ticketDescription) {}

    private static final int MAX_QUESTION = 1000;
    private static final int MAX_TURNS = 8;

    private final GeminiClient gemini;
    private final String guide;

    public HelpAssistantService(GeminiClient gemini) {
        this.gemini = gemini;
        try {
            this.guide = new ClassPathResource("help/workify-help.md").getContentAsString(StandardCharsets.UTF_8);
        } catch (IOException e) {
            throw new UncheckedIOException("help/workify-help.md is missing", e);
        }
    }

    public Answer ask(String question, List<Turn> history) {
        String q = question == null ? "" : question.strip();
        if (q.length() < 3) throw new IllegalArgumentException("Ask a question first.");
        if (q.length() > MAX_QUESTION) q = q.substring(0, MAX_QUESTION);

        StringBuilder before = new StringBuilder();
        if (history != null) {
            for (Turn t : history.subList(Math.max(0, history.size() - MAX_TURNS), history.size())) {
                if (t.text() == null || t.text().isBlank()) continue;
                before.append("assistant".equalsIgnoreCase(t.role()) ? "Assistant: " : "User: ")
                        .append(t.text().strip()).append('\n');
            }
        }
        String prompt = """
                You are Workify's help assistant in the app. Answer the user's question using ONLY the help guide
                below, in the user's language, in 1 to 4 short sentences or steps. Name the exact buttons and menus.
                Never invent features, prices, delays or policies that aren't in the guide.

                Set needsTicket to true when the guide doesn't answer it, or when the support team must act:
                money missing or wrong, a payment or escrow problem, a bug or error, an account they can't access,
                fraud or abuse. Then say kindly that the team will handle it, and draft the request for them:
                ticketTitle (at most 60 characters) and ticketDescription (their problem in their words, with every
                fact they gave, inventing none). Otherwise needsTicket is false and the ticket fields are empty.

                Return JSON: {"answer": "...", "needsTicket": false, "ticketTitle": "", "ticketDescription": ""}

                HELP GUIDE
                %s

                CONVERSATION SO FAR
                %s
                User: %s
                """.formatted(guide, before.isEmpty() ? "(none)\n" : before, q);

        JsonNode json = gemini.generateJson(prompt);
        String answer = json.path("answer").asText("").strip();
        if (answer.isEmpty()) throw new AiUnavailableException("The assistant gave an empty answer. Try again.");
        boolean needsTicket = json.path("needsTicket").asBoolean(false);
        String title = json.path("ticketTitle").asText("").strip();
        String description = json.path("ticketDescription").asText("").strip();
        if (needsTicket) {
            if (title.isEmpty()) title = q.length() > 60 ? q.substring(0, 57) + "…" : q;
            if (description.length() < 20) description = q;
        }
        return new Answer(answer, needsTicket, needsTicket ? title : "", needsTicket ? description : "");
    }
}
