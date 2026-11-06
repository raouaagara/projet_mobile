package org.example.technicalsupport.service;

import org.example.technicalsupport.entity.TicketCategory;
import org.example.technicalsupport.entity.TicketPriority;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;

@Service
public class TicketCategorizationService {

    // Keywords for AI-like rule-based categorization
    private static final Map<TicketCategory, String[]> CATEGORY_KEYWORDS = Map.of(
        TicketCategory.PAYMENT_ISSUE,    new String[]{"payment", "invoice", "refund", "charge", "billing", "wallet", "transaction", "money", "paid", "fee"},
        TicketCategory.TECHNICAL_ISSUE,  new String[]{"error", "bug", "crash", "not working", "broken", "loading", "slow", "fail", "issue", "problem", "technical"},
        TicketCategory.ACCOUNT_ISSUE,    new String[]{"login", "password", "account", "access", "locked", "email", "profile", "sign in", "register", "verification"},
        TicketCategory.CONTRACT_DISPUTE, new String[]{"contract", "dispute", "agreement", "freelancer", "client", "work", "project", "deadline", "deliverable"},
        TicketCategory.FRAUD_REPORT,     new String[]{"fraud", "scam", "fake", "stolen", "unauthorized", "suspicious", "hack", "phishing"},
        TicketCategory.BUG_REPORT,       new String[]{"bug", "glitch", "unexpected", "wrong", "incorrect", "display", "ui", "interface"},
        TicketCategory.FEATURE_REQUEST,  new String[]{"feature", "request", "suggestion", "improve", "add", "new", "would like", "wish"}
    );

    // Keywords that indicate HIGH or CRITICAL priority
    private static final String[] HIGH_PRIORITY_KEYWORDS = {
        "urgent", "asap", "immediately", "critical", "emergency", "blocked", "cannot work", "lost money", "fraud"
    };
    private static final String[] CRITICAL_PRIORITY_KEYWORDS = {
        "hacked", "stolen", "data breach", "security", "unauthorized access", "all data lost"
    };

    // Department routing based on category
    private static final Map<TicketCategory, String> DEPARTMENT_ROUTING = Map.of(
        TicketCategory.PAYMENT_ISSUE,    "Finance Department",
        TicketCategory.TECHNICAL_ISSUE,  "Technical Team",
        TicketCategory.ACCOUNT_ISSUE,    "Account Management",
        TicketCategory.CONTRACT_DISPUTE, "Legal & Disputes",
        TicketCategory.FRAUD_REPORT,     "Security Team",
        TicketCategory.BUG_REPORT,       "Development Team",
        TicketCategory.FEATURE_REQUEST,  "Product Team",
        TicketCategory.OTHER,            "General Support"
    );

    /**
     * The category with the most matching keywords (whole words). Ties go to the first
     * category in {@link #CATEGORY_ORDER}, so the same ticket always gets the same category
     * ({@code Map.of} has no fixed order, and "first keyword found wins" gave random results).
     */
    public TicketCategory categorize(String title, String description) {
        String text = ((title == null ? "" : title) + " " + (description == null ? "" : description)).toLowerCase();

        TicketCategory best = TicketCategory.OTHER;
        int bestScore = 0;
        for (TicketCategory category : CATEGORY_ORDER) {
            int score = 0;
            for (String keyword : CATEGORY_KEYWORDS.get(category)) {
                if (containsWord(text, keyword)) score++;
            }
            if (score > bestScore) {
                best = category;
                bestScore = score;
            }
        }
        return best;
    }

    private static final List<TicketCategory> CATEGORY_ORDER = List.of(
        TicketCategory.FRAUD_REPORT, TicketCategory.PAYMENT_ISSUE, TicketCategory.TECHNICAL_ISSUE,
        TicketCategory.BUG_REPORT, TicketCategory.ACCOUNT_ISSUE, TicketCategory.CONTRACT_DISPUTE,
        TicketCategory.FEATURE_REQUEST
    );

    /** "ui" must not match "build", nor "add" match "address". */
    private static boolean containsWord(String text, String keyword) {
        return java.util.regex.Pattern.compile("\\b" + java.util.regex.Pattern.quote(keyword) + "\\b").matcher(text).find();
    }

    public TicketPriority detectPriority(String title, String description) {
        String text = (title + " " + description).toLowerCase();

        for (String kw : CRITICAL_PRIORITY_KEYWORDS) {
            if (text.contains(kw)) return TicketPriority.CRITICAL;
        }
        for (String kw : HIGH_PRIORITY_KEYWORDS) {
            if (text.contains(kw)) return TicketPriority.HIGH;
        }
        return TicketPriority.MEDIUM;
    }

    public String getDepartment(TicketCategory category) {
        return DEPARTMENT_ROUTING.getOrDefault(category, "General Support");
    }
}
