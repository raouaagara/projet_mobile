package org.example.referralmicroservice;

import org.example.referralmicroservice.Entities.Referral;
import org.example.referralmicroservice.Services.ReferralGuard;
import org.example.referralmicroservice.ai.GeminiClient;
import org.example.referralmicroservice.ai.InviteWriter;
import org.example.referralmicroservice.ai.InviteWriter.InviteRequest;
import org.junit.jupiter.api.Test;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

/** The invite writer (fake Gemini) and the referral fraud check. */
class ReferralAiTest {

    private String lastPrompt;

    private InviteWriter answering(String text) {
        return new InviteWriter(new GeminiClient("test-key", "test-model") {
            @Override
            public String generate(String prompt) {
                lastPrompt = prompt;
                return text;
            }
        });
    }

    @Test
    void inviteKeepsTheCodeAndTheChannel() {
        String message = answering("Hey! Join me on Workify, use CATCH-7-AB12CD 🙂")
                .write(new InviteRequest("CATCH-7-AB12CD", "Sara", "FREELANCER", "Flutter", "linkedin", "French", "I love it"));

        assertEquals("Hey! Join me on Workify, use CATCH-7-AB12CD 🙂", message);
        assertTrue(lastPrompt.contains("a LinkedIn post") && lastPrompt.contains("in French"));
        assertTrue(lastPrompt.contains("Sara") && lastPrompt.contains("Flutter") && lastPrompt.contains("I love it"));
    }

    @Test
    void inviteAddsTheCodeIfTheAiForgotIt() {
        String message = answering("Join me on Workify!")
                .write(new InviteRequest("CATCH-7-AB12CD", "Sara", "FREELANCER", null, null, null, null));
        assertTrue(message.endsWith("CATCH-7-AB12CD"));
        assertTrue(lastPrompt.contains("a WhatsApp message"));
        assertThrows(IllegalArgumentException.class,
                () -> answering("x").write(new InviteRequest(" ", "Sara", null, null, null, null, null)));
    }

    private static Referral referral(long referredUserId, LocalDateTime at) {
        Referral r = new Referral();
        r.setReferredUserId(referredUserId);
        r.setReferredAt(at);
        return r;
    }

    private final ReferralGuard guard = new ReferralGuard();
    private final LocalDateTime now = LocalDateTime.of(2026, 11, 4, 12, 0);

    @Test
    void normalReferralsPass() {
        var check = guard.check(List.of(referral(40, now.minusDays(3)), referral(88, now.minusHours(5))), 120L, now);
        assertFalse(check.suspicious());
    }

    @Test
    void aBurstInOneHourIsHeld() {
        var previous = List.of(referral(10, now.minusMinutes(50)), referral(20, now.minusMinutes(30)),
                referral(30, now.minusMinutes(5)));
        var check = guard.check(previous, 99L, now);
        assertTrue(check.suspicious());
        assertEquals(List.of("4 sign-ups with this code in one hour"), check.reasons());
    }

    @Test
    void accountsInARowAreHeld() {
        var check = guard.check(List.of(referral(51, now.minusHours(6)), referral(52, now.minusHours(3))), 53L, now);
        assertTrue(check.suspicious());
        assertTrue(check.reasons().get(0).contains("one after the other"));
    }

    @Test
    void tooManyInADayIsHeld() {
        List<Referral> previous = new ArrayList<>();
        for (int i = 0; i < 10; i++) previous.add(referral(100 + i * 7L, now.minusHours(2 + i)));
        assertTrue(guard.check(previous, 500L, now).suspicious());
    }
}
