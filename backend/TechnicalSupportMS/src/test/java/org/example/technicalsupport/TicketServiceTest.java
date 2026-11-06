package org.example.technicalsupport;

import org.example.technicalsupport.entity.*;
import org.example.technicalsupport.repository.TicketRepository;
import org.example.technicalsupport.repository.TicketResponseRepository;
import org.example.technicalsupport.service.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.messaging.simp.SimpMessagingTemplate;

import java.time.LocalDateTime;
import java.util.*;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class TicketServiceTest {

    @Mock private TicketRepository ticketRepo;
    @Mock private TicketResponseRepository responseRepo;
    @Mock private TicketCategorizationService categorizationService;
    @Mock private TicketEnhancementService enhancementService;
    @Mock private TicketSummarizationService summarizationService;
    @Mock private TicketAiService ticketAi; // no analysis by default: the keyword rules decide
    @Mock private SimpMessagingTemplate messagingTemplate;

    @InjectMocks private TicketService ticketService;

    private Ticket sampleTicket;

    @BeforeEach
    void setUp() {
        sampleTicket = Ticket.builder()
            .id(1L).userId(10L)
            .title("Payment not received")
            .description("I completed the project but payment is pending")
            .status(TicketStatus.OPEN).priority(TicketPriority.HIGH)
            .category(TicketCategory.PAYMENT_ISSUE).department("Finance Department")
            .createdAt(LocalDateTime.now()).slaDeadline(LocalDateTime.now().plusHours(24))
            .build();
    }

    // ── CREATE ────────────────────────────────────────────────────────────────

    @Test
    void createTicket_shouldAutoCategorizAndSave() {
        Ticket input = Ticket.builder().userId(10L).title("Payment issue").description("not paid").build();
        when(categorizationService.categorize(any(), any())).thenReturn(TicketCategory.PAYMENT_ISSUE);
        when(categorizationService.detectPriority(any(), any())).thenReturn(TicketPriority.HIGH);
        when(categorizationService.getDepartment(any())).thenReturn("Finance Department");
        when(ticketRepo.save(any())).thenReturn(sampleTicket);

        Ticket result = ticketService.createTicket(input);

        assertNotNull(result);
        verify(ticketRepo).save(any());
        verify(messagingTemplate).convertAndSend(eq("/topic/support/admin"), (Object) any(Map.class));
    }

    @Test
    void createTicket_shouldSetStatusToOpen() {
        Ticket input = Ticket.builder().userId(10L).title("Bug").description("app crashes").build();
        when(categorizationService.categorize(any(), any())).thenReturn(TicketCategory.BUG_REPORT);
        when(categorizationService.detectPriority(any(), any())).thenReturn(TicketPriority.MEDIUM);
        when(categorizationService.getDepartment(any())).thenReturn("Development Team");
        when(ticketRepo.save(any(Ticket.class))).thenAnswer(inv -> inv.getArgument(0));

        Ticket result = ticketService.createTicket(input);

        assertEquals(TicketStatus.OPEN, result.getStatus());
        assertNotNull(result.getCreatedAt());
        assertNotNull(result.getSlaDeadline());
    }

    @Test
    void createTicket_usesTheAiAnalysisWhenAvailable() {
        Ticket input = Ticket.builder().userId(5L).title("Issue").description("something broken").build();
        when(ticketAi.analyze(eq("Issue"), eq("something broken"))).thenReturn(Optional.of(new TicketAiService.Analysis(
            TicketCategory.TECHNICAL_ISSUE, TicketPriority.MEDIUM,
            "System issue reported.", "Something is broken in the system.")));
        when(categorizationService.getDepartment(any())).thenReturn("Technical Team");
        when(ticketRepo.save(any(Ticket.class))).thenAnswer(inv -> inv.getArgument(0));

        Ticket result = ticketService.createTicket(input);

        assertEquals(TicketCategory.TECHNICAL_ISSUE, result.getCategory());
        assertEquals(TicketPriority.MEDIUM, result.getPriority());
        assertEquals("Something is broken in the system.", result.getEnhancedDescription());
        assertEquals("System issue reported.", result.getAiSummary());
        verify(categorizationService, never()).categorize(any(), any());
        verify(enhancementService, never()).enhance(any(), any());
    }

    @Test
    void createTicket_withoutAi_keepsTheTextAndUsesTheKeywordRules() {
        Ticket input = Ticket.builder().userId(5L).title("Issue").description("something broken").build();
        when(categorizationService.categorize(any(), any())).thenReturn(TicketCategory.TECHNICAL_ISSUE);
        when(categorizationService.detectPriority(any(), any())).thenReturn(TicketPriority.MEDIUM);
        when(categorizationService.getDepartment(any())).thenReturn("Technical Team");
        when(ticketRepo.save(any(Ticket.class))).thenAnswer(inv -> inv.getArgument(0));

        Ticket result = ticketService.createTicket(input);

        assertEquals(TicketCategory.TECHNICAL_ISSUE, result.getCategory());
        assertEquals("something broken", result.getEnhancedDescription());
        assertEquals("", result.getAiSummary());
    }

    // ── UPDATE ────────────────────────────────────────────────────────────────

    @Test
    void updateTicket_shouldChangeStatus() {
        when(ticketRepo.findById(1L)).thenReturn(Optional.of(sampleTicket));
        when(ticketRepo.save(any())).thenReturn(sampleTicket);

        Ticket result = ticketService.updateTicket(1L, Map.of("status", "IN_PROGRESS"));

        assertEquals(TicketStatus.IN_PROGRESS, result.getStatus());
    }

    @Test
    void updateTicket_shouldSetResolvedAt_whenStatusResolved() {
        when(ticketRepo.findById(1L)).thenReturn(Optional.of(sampleTicket));
        when(ticketRepo.save(any())).thenAnswer(inv -> inv.getArgument(0));

        Ticket result = ticketService.updateTicket(1L, Map.of("status", "RESOLVED"));

        assertEquals(TicketStatus.RESOLVED, result.getStatus());
        assertNotNull(result.getResolvedAt());
    }

    @Test
    void updateTicket_shouldThrow_whenNotFound() {
        when(ticketRepo.findById(99L)).thenReturn(Optional.empty());
        assertThrows(RuntimeException.class, () -> ticketService.updateTicket(99L, Map.of()));
    }

    @Test
    void updateTicket_shouldAssignStaff() {
        when(ticketRepo.findById(1L)).thenReturn(Optional.of(sampleTicket));
        when(ticketRepo.save(any())).thenAnswer(inv -> inv.getArgument(0));

        Ticket result = ticketService.updateTicket(1L, Map.of("assignedToId", 42, "assignedToName", "John"));

        assertEquals(42L, result.getAssignedToId());
        assertEquals("John", result.getAssignedToName());
    }

    // ── DELETE ────────────────────────────────────────────────────────────────

    @Test
    void deleteTicket_shouldCallRepository() {
        doNothing().when(ticketRepo).deleteById(1L);
        ticketService.deleteTicket(1L);
        verify(ticketRepo).deleteById(1L);
    }

    // ── ESCALATE ─────────────────────────────────────────────────────────────

    @Test
    void escalateTicket_shouldSetEscalatedAndNotify() {
        when(ticketRepo.findById(1L)).thenReturn(Optional.of(sampleTicket));
        when(ticketRepo.save(any())).thenAnswer(inv -> inv.getArgument(0));

        Ticket result = ticketService.escalateTicket(1L);

        assertTrue(result.isEscalated());
        assertEquals(TicketStatus.ESCALATED, result.getStatus());
        assertEquals(TicketPriority.HIGH, result.getPriority());
        verify(messagingTemplate, atLeastOnce()).convertAndSend(eq("/topic/support/admin"), (Object) any(Map.class));
    }

    @Test
    void escalateTicket_shouldThrow_whenNotFound() {
        when(ticketRepo.findById(99L)).thenReturn(Optional.empty());
        assertThrows(RuntimeException.class, () -> ticketService.escalateTicket(99L));
    }

    // ── RESPONSES ─────────────────────────────────────────────────────────────

    @Test
    void addResponse_shouldMoveTicketToInProgress_whenStaffReplies() {
        sampleTicket.setStatus(TicketStatus.OPEN);
        TicketResponse response = TicketResponse.builder()
            .responderId(99L).responderName("Support Agent").isStaff(true)
            .message("We are looking into this").build();

        when(ticketRepo.findById(1L)).thenReturn(Optional.of(sampleTicket));
        when(responseRepo.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(ticketRepo.save(any())).thenAnswer(inv -> inv.getArgument(0));

        ticketService.addResponse(1L, response);

        assertEquals(TicketStatus.IN_PROGRESS, sampleTicket.getStatus());
    }

    @Test
    void addResponse_shouldNotChangeStatus_whenUserReplies() {
        sampleTicket.setStatus(TicketStatus.OPEN);
        TicketResponse response = TicketResponse.builder()
            .responderId(10L).responderName("User").isStaff(false)
            .message("Any update?").build();

        when(ticketRepo.findById(1L)).thenReturn(Optional.of(sampleTicket));
        when(responseRepo.save(any())).thenAnswer(inv -> inv.getArgument(0));

        ticketService.addResponse(1L, response);

        assertEquals(TicketStatus.OPEN, sampleTicket.getStatus());
    }

    // ── AI ────────────────────────────────────────────────────────────────────

    @Test
    void regenerateSummary_shouldUpdateAndSave() {
        when(ticketRepo.findById(1L)).thenReturn(Optional.of(sampleTicket));
        when(summarizationService.summarize(any())).thenReturn("Payment pending after project completion.");
        when(ticketRepo.save(any())).thenAnswer(inv -> inv.getArgument(0));

        String result = ticketService.regenerateSummary(1L);

        assertEquals("Payment pending after project completion.", result);
        assertEquals("Payment pending after project completion.", sampleTicket.getAiSummary());
        verify(ticketRepo).save(sampleTicket);
    }

    @Test
    void regenerateEnhancement_shouldUpdateAndSave() {
        when(ticketRepo.findById(1L)).thenReturn(Optional.of(sampleTicket));
        when(enhancementService.enhance(any(), any())).thenReturn("The payment for the completed project has not been received.");
        when(ticketRepo.save(any())).thenAnswer(inv -> inv.getArgument(0));

        String result = ticketService.regenerateEnhancement(1L);

        assertEquals("The payment for the completed project has not been received.", result);
        verify(ticketRepo).save(sampleTicket);
    }

    // ── STATISTICS ────────────────────────────────────────────────────────────

    @Test
    void getStatistics_shouldReturnAllCounts() {
        when(ticketRepo.count()).thenReturn(10L);
        when(ticketRepo.countByStatus(TicketStatus.OPEN)).thenReturn(4L);
        when(ticketRepo.countByStatus(TicketStatus.IN_PROGRESS)).thenReturn(3L);
        when(ticketRepo.countByStatus(TicketStatus.RESOLVED)).thenReturn(2L);
        when(ticketRepo.countByStatus(TicketStatus.CLOSED)).thenReturn(1L);
        when(ticketRepo.countByEscalatedTrue()).thenReturn(1L);
        when(ticketRepo.countBySlaBreachedTrue()).thenReturn(0L);
        when(ticketRepo.countByPriority(TicketPriority.CRITICAL)).thenReturn(1L);
        when(ticketRepo.countByPriority(TicketPriority.HIGH)).thenReturn(2L);
        when(ticketRepo.countCreatedSince(any())).thenReturn(3L);

        Map<String, Object> stats = ticketService.getStatistics();

        assertEquals(10L, stats.get("total"));
        assertEquals(4L, stats.get("open"));
        assertEquals(1L, stats.get("escalated"));
        assertEquals(0L, stats.get("slaBreached"));
    }
}
