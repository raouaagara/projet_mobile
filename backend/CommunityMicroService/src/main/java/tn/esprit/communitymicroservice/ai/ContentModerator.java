package tn.esprit.communitymicroservice.ai;

import com.fasterxml.jackson.databind.JsonNode;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ResponseStatusException;

import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Optional;
import java.util.Set;

/**
 * Checks posts and comments before they are published (Gemini): harassment, hate, sexual content,
 * threats, scams (paying outside Workify, asking for card details) and spam. Fails open: without a
 * key, or if Gemini is slow or down, the text is published.
 */
@Component
public class ContentModerator {

    private static final Set<String> BLOCKED = Set.of("harassment", "hate", "sexual", "violence", "scam", "spam");
    private static final int MIN_LENGTH = 12;
    private static final int MAX_TEXT = 3000;
    private static final int CACHE_SIZE = 1000;

    private final GeminiClient gemini;

    /** Same text, same answer: an edit that changes nothing costs no second call. */
    private final Map<String, Optional<String>> cache = Collections.synchronizedMap(
            new LinkedHashMap<>(16, 0.75f, true) {
                @Override
                protected boolean removeEldestEntry(Map.Entry<String, Optional<String>> eldest) {
                    return size() > CACHE_SIZE;
                }
            });

    public ContentModerator(GeminiClient gemini) {
        this.gemini = gemini;
    }

    /** Throws 422 with the reason, in the author's language, when [text] must not be published. */
    public void requireAllowed(String text) {
        reasonToBlock(text).ifPresent(reason -> {
            throw new ResponseStatusException(HttpStatus.UNPROCESSABLE_ENTITY, reason);
        });
    }

    /** Why [text] must not be published, or empty. */
    public Optional<String> reasonToBlock(String text) {
        if (text == null || !gemini.isConfigured()) return Optional.empty();
        String t = text.strip();
        if (t.length() < MIN_LENGTH) return Optional.empty();
        if (t.length() > MAX_TEXT) t = t.substring(0, MAX_TEXT);
        Optional<String> cached = cache.get(t);
        if (cached != null) return cached;
        try {
            Optional<String> verdict = ask(t);
            cache.put(t, verdict);
            return verdict;
        } catch (Exception e) {
            System.err.println("⚠️ [COMMUNITY-MODERATION] skipped: " + e.getMessage());
            return Optional.empty();
        }
    }

    private Optional<String> ask(String text) {
        JsonNode json = gemini.generateJson("""
                You moderate the community space of Workify, a freelance marketplace (groups, clubs, posts, comments).
                Texts can be in any language (often French, English or Tunisian Arabic).
                Block only what is clearly one of these:
                - harassment: insults or humiliation aimed at a person
                - hate: hate against a group or a person's identity
                - sexual: sexual content
                - violence: threats of harm
                - scam: asking to pay or be paid outside Workify, crypto or "investment" schemes, asking for card
                  numbers, passwords or codes
                - spam: repeated advertising, link farms, the same promotion pasted again and again
                Allow everything else: opinions, criticism, job tips, sharing a portfolio, events, questions.

                Return JSON: {"category": "none|harassment|hate|sexual|violence|scam|spam",
                              "reason": "one short sentence to the author, in their language, saying why it was not published"}

                Text: %s
                """.formatted(text));
        String category = json.path("category").asText("none").strip().toLowerCase();
        if (!BLOCKED.contains(category)) return Optional.empty();
        String reason = json.path("reason").asText("").strip();
        return Optional.of(reason.isEmpty() ? "This breaks the community rules. Keep it respectful and on Workify." : reason);
    }
}
