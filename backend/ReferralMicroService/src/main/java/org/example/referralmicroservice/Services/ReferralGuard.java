package org.example.referralmicroservice.Services;

import org.example.referralmicroservice.Entities.Referral;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

/**
 * Spots referral farming before the bonus is paid: a burst of sign-ups on one code, or accounts created
 * one after the other (ids in a row) all using the same code. A suspicious referral is kept, but held
 * for review: no bonus until an admin checks it.
 */
@Component
public class ReferralGuard {

    public record Check(boolean suspicious, List<String> reasons) {}

    static final int MAX_PER_HOUR = 3;
    static final int MAX_PER_DAY = 10;
    /** This many recent referred accounts with consecutive ids (counting the new one) looks scripted. */
    static final int CONSECUTIVE_IDS = 3;

    /** [previous]: the referrer's earlier referrals; [newUserId] joins now. */
    public Check check(List<Referral> previous, Long newUserId, LocalDateTime now) {
        List<String> reasons = new ArrayList<>();
        long lastHour = previous.stream().filter(r -> within(r, now, Duration.ofHours(1))).count();
        long lastDay = previous.stream().filter(r -> within(r, now, Duration.ofDays(1))).count();
        if (lastHour >= MAX_PER_HOUR) reasons.add((lastHour + 1) + " sign-ups with this code in one hour");
        else if (lastDay >= MAX_PER_DAY) reasons.add((lastDay + 1) + " sign-ups with this code in one day");

        List<Long> recentIds = previous.stream()
                .filter(r -> within(r, now, Duration.ofDays(1)) && r.getReferredUserId() != null)
                .map(Referral::getReferredUserId)
                .sorted()
                .toList();
        if (newUserId != null && run(recentIds, newUserId) >= CONSECUTIVE_IDS) {
            reasons.add("accounts created one after the other all used this code");
        }
        return new Check(!reasons.isEmpty(), reasons);
    }

    private static boolean within(Referral r, LocalDateTime now, Duration window) {
        return r.getReferredAt() != null && !r.getReferredAt().isBefore(now.minus(window));
    }

    /** Length of the run of consecutive ids ending at [id] (id, id-1, id-2... all present). */
    private static int run(List<Long> ids, long id) {
        int length = 1;
        while (ids.contains(id - length)) length++;
        return length;
    }
}
