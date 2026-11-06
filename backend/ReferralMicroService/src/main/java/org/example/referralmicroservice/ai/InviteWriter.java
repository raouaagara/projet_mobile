package org.example.referralmicroservice.ai;

import org.springframework.stereotype.Service;

import java.util.Map;

/** A personal invite to Workify with the user's referral code, written by Gemini for one channel. */
@Service
public class InviteWriter {

    public record InviteRequest(String code, String firstName, String role, String skills, String channel,
                                String language, String note) {}

    private static final Map<String, String> CHANNELS = Map.of(
            "WHATSAPP", "a WhatsApp message to a friend: 2 to 4 short lines, warm and casual, one emoji at most",
            "LINKEDIN", "a LinkedIn post: 3 short paragraphs, professional, no hashtag walls (at most 3 hashtags)",
            "EMAIL", "an email: a subject line on the first line starting with \"Subject: \", then a short friendly body");

    private final GeminiClient gemini;

    public InviteWriter(GeminiClient gemini) {
        this.gemini = gemini;
    }

    public String write(InviteRequest req) {
        String code = req.code() == null ? "" : req.code().strip();
        if (code.isEmpty()) throw new IllegalArgumentException("Your referral code is missing.");
        String channel = req.channel() == null ? "WHATSAPP" : req.channel().strip().toUpperCase();
        String style = CHANNELS.getOrDefault(channel, CHANNELS.get("WHATSAPP"));
        boolean client = "CLIENT".equalsIgnoreCase(req.role());
        String prompt = """
                Write %s inviting someone to join Workify, a freelance marketplace where clients post jobs and
                freelancers apply (payments are held in escrow until the work is approved).
                Written by %s, a %s, in %s.
                - Include the referral code exactly as given: %s (they enter it after signing up).
                - Use ONLY these facts; never invent earnings, numbers, prizes or features.
                - Sound like a person, not an ad. Return only the message.
                Their skills (may be empty): %s
                Their own words to include (may be empty): %s
                """.formatted(style, text(req.firstName()), client ? "client who hires freelancers" : "freelancer",
                req.language() == null || req.language().isBlank() ? "English" : req.language().strip(),
                code, text(req.skills()), text(req.note()));
        String message = gemini.generate(prompt).strip();
        // The code is the point of the invite: never lose it.
        return message.contains(code) ? message : message + "\n\n" + code;
    }

    private static String text(String s) {
        return s == null || s.isBlank() ? "none" : s.strip();
    }
}
