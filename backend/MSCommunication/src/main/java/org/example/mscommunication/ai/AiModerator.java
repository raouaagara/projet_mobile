package org.example.mscommunication.ai;

import com.fasterxml.jackson.databind.JsonNode;
import org.example.mscommunication.MessageModerator.Verdict;
import org.springframework.stereotype.Component;

import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Optional;
import java.util.Set;

/**
 * Second pass of chat moderation, by meaning (Gemini): what the word list can't see — insults without
 * bad words, veiled threats, harassment, and attempts to take payment or contact off Workify (the
 * usual freelance scam). Fails open: without a key, or if Gemini is slow or down, the message passes
 * (the word list already ran).
 */
@Component
public class AiModerator {

    private static final Set<String> BLOCKED = Set.of("harassment", "hate", "sexual", "violence", "scam");
    private static final int MIN_LENGTH = 12;
    private static final int MAX_TEXT = 1500;
    private static final int CACHE_SIZE = 1000;

    private final GeminiClient gemini;

    /** Same text, same verdict: retries and edits don't cost a second call. */
    private final Map<String, Optional<Verdict>> cache = Collections.synchronizedMap(
            new LinkedHashMap<>(16, 0.75f, true) {
                @Override
                protected boolean removeEldestEntry(Map.Entry<String, Optional<Verdict>> eldest) {
                    return size() > CACHE_SIZE;
                }
            });

    public AiModerator(GeminiClient gemini) {
        this.gemini = gemini;
    }

    public Optional<Verdict> check(String text) {
        if (text == null || !gemini.isConfigured()) return Optional.empty();
        String t = text.strip();
        if (t.length() < MIN_LENGTH) return Optional.empty(); // "ok", "thanks!", emojis
        if (t.length() > MAX_TEXT) t = t.substring(0, MAX_TEXT);
        Optional<Verdict> cached = cache.get(t);
        if (cached != null) return cached;

        Optional<Verdict> verdict;
        try {
            verdict = ask(t);
        } catch (Exception e) {
            System.err.println("⚠️ [AI-MODERATION] skipped: " + e.getMessage());
            return Optional.empty(); // not cached: try again next time
        }
        cache.put(t, verdict);
        return verdict;
    }

    private Optional<Verdict> ask(String text) {
        String prompt = """
                You moderate private messages between a client and a freelancer on Workify, a freelance marketplace.
                Messages can be in any language (often French, English or Tunisian Arabic).
                Block only what is clearly one of these:
                - harassment: insults or humiliation aimed at the other person (even without swear words)
                - hate: hate against a group or a person's identity
                - sexual: sexual content or advances
                - violence: threats of harm, even veiled ("you'll regret it, I know where you live")
                - scam: asking to pay or be paid outside Workify (bank transfer, cash, crypto, "to avoid the fees"),
                  or asking for card numbers, passwords or codes
                Allow everything else: complaints, firm disagreement, swearing at a bug or a situation, deadlines,
                prices, sharing a work email or a portfolio link.

                Return JSON: {"category": "none|harassment|hate|sexual|violence|scam",
                              "reason": "one short sentence to the sender, in their language, saying why it was not sent"}

                Message: %s
                """.formatted(text);
        JsonNode json = gemini.generateJson(prompt);
        String category = json.path("category").asText("none").trim().toLowerCase();
        if (!BLOCKED.contains(category)) return Optional.empty();
        String reason = json.path("reason").asText("").trim();
        if (reason.isEmpty()) {
            reason = "scam".equals(category)
                    ? "Keep payments on Workify: they are protected by escrow."
                    : "This message breaks the community rules. Keep it professional.";
        }
        return Optional.of(new Verdict(category, reason));
    }
}
