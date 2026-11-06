package org.example.mscommunication;

import org.example.mscommunication.ai.AiModerator;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import java.text.Normalizer;
import java.util.List;
import java.util.Optional;
import java.util.regex.Pattern;

/**
 * Server-side chat moderation, so no client needs an API key. Two passes:
 * 1. a word list (English and French), instant: threats, insults aimed at someone, hate, sexual
 *    harassment; normal words like "I hate this bug" or "kill the process" pass;
 * 2. the AI ({@link AiModerator}), by meaning, for what passed the list (veiled threats, insults
 *    without bad words, payment off Workify).
 */
@Component
public class MessageModerator {

    public record Verdict(String category, String reason) {}

    private record Rule(String category, String reason, Pattern pattern) {}

    private static Pattern p(String regex) {
        return Pattern.compile(regex, Pattern.CASE_INSENSITIVE | Pattern.UNICODE_CASE);
    }

    private static final List<Rule> RULES = List.of(
            new Rule("violence", "Threats are not allowed.",
                    p("\\b(kill|murder|hurt|beat|stab|shoot)\\s+(you|u|ya|yourself|him|her|them)\\b")),
            new Rule("violence", "Threats are not allowed.",
                    p("\\b(je vais|j ?vais|on va)\\s+(te|vous)\\s+(tuer|frapper|buter|defoncer|egorger)\\b")),
            new Rule("violence", "Threats are not allowed.",
                    p("\\b(go die|kys|kill yourself|tue[- ]toi|va mourir|creve)\\b")),
            new Rule("hate", "Hateful messages are not allowed.",
                    p("\\bhate\\s+(you|u|people like you|your kind)\\b|\\bje (te|vous) (deteste|hais)\\b")),
            new Rule("harassment", "Insults are not allowed. Keep it professional.",
                    p("\\b(you( re| are)|u r|ur)\\s+(an?\\s+|so\\s+|such an?\\s+)?(idiot|stupid|moron|dumb|loser|useless|retard(ed)?)\\b")),
            new Rule("harassment", "Insults are not allowed. Keep it professional.",
                    p("\\b(fuck (you|u|off)|f\\*+k (you|u)|stfu|shut up bitch|bitch|bastard|asshole|motherfucker)\\b")),
            new Rule("harassment", "Insults are not allowed. Keep it professional.",
                    p("\\b(connard|connasse|salope|salaud|encule|pute|fils de pute|ta gueule|ferme ta gueule|nique ta|abruti|batard|debile)\\b")),
            new Rule("sexual", "Sexual messages are not allowed.",
                    p("\\b(send (me )?nudes?|nude pics?|sexy pics?|envoie (moi )?des nudes?)\\b"))
    );

    /** Null in unit tests: the word list alone. */
    @Autowired(required = false)
    private AiModerator ai;

    public MessageModerator() {}

    MessageModerator(AiModerator ai) {
        this.ai = ai;
    }

    /** Why [text] must not be sent, or empty if it's fine. */
    public Optional<Verdict> check(String text) {
        if (text == null || text.isBlank()) return Optional.empty();
        String normalized = normalize(text);
        for (Rule rule : RULES) {
            if (rule.pattern().matcher(normalized).find()) {
                return Optional.of(new Verdict(rule.category(), rule.reason()));
            }
        }
        return ai == null ? Optional.empty() : ai.check(text);
    }

    /** Lower case, accents removed ("crève" → "creve"), apostrophes as spaces. */
    static String normalize(String text) {
        String noAccents = Normalizer.normalize(text, Normalizer.Form.NFD).replaceAll("\\p{M}", "");
        return noAccents.toLowerCase().replace('’', '\'').replace("'", " ");
    }
}
