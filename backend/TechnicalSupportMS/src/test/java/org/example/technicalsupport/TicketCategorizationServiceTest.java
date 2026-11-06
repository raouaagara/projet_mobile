package org.example.technicalsupport;

import org.example.technicalsupport.entity.TicketCategory;
import org.example.technicalsupport.entity.TicketPriority;
import org.example.technicalsupport.service.TicketCategorizationService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class TicketCategorizationServiceTest {

    private TicketCategorizationService service;

    @BeforeEach
    void setUp() { service = new TicketCategorizationService(); }

    @Test
    void categorize_shouldDetectPaymentIssue() {
        assertEquals(TicketCategory.PAYMENT_ISSUE, service.categorize("Payment problem", "I didn't receive my payment"));
    }

    @Test
    void categorize_shouldDetectTechnicalIssue() {
        assertEquals(TicketCategory.TECHNICAL_ISSUE, service.categorize("App error", "The app crashes on login"));
    }

    @Test
    void categorize_shouldDetectAccountIssue() {
        assertEquals(TicketCategory.ACCOUNT_ISSUE, service.categorize("Login problem", "I can't login to my account"));
    }

    @Test
    void categorize_shouldDetectFraud() {
        assertEquals(TicketCategory.FRAUD_REPORT, service.categorize("Fraud", "Someone is scamming users"));
    }

    @Test
    void categorize_shouldDetectBugReport() {
        assertEquals(TicketCategory.BUG_REPORT, service.categorize("Bug", "There is a glitch in the UI"));
    }

    @Test
    void categorize_shouldDetectContractDispute() {
        assertEquals(TicketCategory.CONTRACT_DISPUTE, service.categorize("Contract issue", "The client refuses to honor the contract"));
    }

    @Test
    void categorize_shouldReturnOther_whenNoMatch() {
        assertEquals(TicketCategory.OTHER, service.categorize("Hello", "Just saying hi"));
    }

    @Test
    void detectPriority_shouldReturnCritical_forSecurityKeywords() {
        assertEquals(TicketPriority.CRITICAL, service.detectPriority("Hacked", "My account was hacked"));
    }

    @Test
    void detectPriority_shouldReturnHigh_forUrgentKeywords() {
        assertEquals(TicketPriority.HIGH, service.detectPriority("Urgent issue", "I need help asap"));
    }

    @Test
    void detectPriority_shouldReturnMedium_byDefault() {
        assertEquals(TicketPriority.MEDIUM, service.detectPriority("Question", "I have a question"));
    }

    @Test
    void getDepartment_shouldRoutePaymentToFinance() {
        assertEquals("Finance Department", service.getDepartment(TicketCategory.PAYMENT_ISSUE));
    }

    @Test
    void getDepartment_shouldRouteFraudToSecurity() {
        assertEquals("Security Team", service.getDepartment(TicketCategory.FRAUD_REPORT));
    }

    @Test
    void getDepartment_shouldRouteTechnicalToTechTeam() {
        assertEquals("Technical Team", service.getDepartment(TicketCategory.TECHNICAL_ISSUE));
    }

    @Test
    void getDepartment_shouldRouteBugToDevelopment() {
        assertEquals("Development Team", service.getDepartment(TicketCategory.BUG_REPORT));
    }
}
