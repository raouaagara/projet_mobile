package org.example.technicalsupport.service;

import org.example.technicalsupport.entity.*;
import org.example.technicalsupport.repository.TicketRepository;
import org.example.technicalsupport.repository.TicketResponseRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.*;

@Service
public class TicketService {

    @Autowired private TicketRepository ticketRepo;
    @Autowired private TicketResponseRepository responseRepo;
    @Autowired private TicketCategorizationService categorizationService;
    @Autowired private TicketEnhancementService enhancementService;
    @Autowired private TicketSummarizationService summarizationService;
    @Autowired private TicketAiService ticketAi;
    @Autowired private SimpMessagingTemplate messagingTemplate;

    @Value("${support.sla.low:72}")     private int slaLow;
    @Value("${support.sla.medium:48}")  private int slaMedium;
    @Value("${support.sla.high:24}")    private int slaHigh;
    @Value("${support.sla.critical:4}") private int slaCritical;

    public Ticket createTicket(Ticket ticket) {
        // Gemini reads the request in one call; without AI the keyword rules decide.
        var ai = ticketAi.analyze(ticket.getTitle(), ticket.getDescription());
        if (ticket.getCategory() == null)
            ticket.setCategory(ai.map(TicketAiService.Analysis::category)
                .orElseGet(() -> categorizationService.categorize(ticket.getTitle(), ticket.getDescription())));
        if (ticket.getPriority() == null)
            ticket.setPriority(ai.map(TicketAiService.Analysis::priority)
                .orElseGet(() -> categorizationService.detectPriority(ticket.getTitle(), ticket.getDescription())));
        ticket.setDepartment(categorizationService.getDepartment(ticket.getCategory()));
        ticket.setStatus(TicketStatus.OPEN);
        ticket.setCreatedAt(LocalDateTime.now());
        ticket.setEscalated(false);
        ticket.setSlaBreached(false);
        ticket.setSlaDeadline(computeSlaDeadline(ticket.getPriority()));
        ticket.setEnhancedDescription(ai.map(TicketAiService.Analysis::improvedDescription).orElse(ticket.getDescription()));
        ticket.setAiSummary(ai.map(TicketAiService.Analysis::summary).orElse(""));
        Ticket saved = ticketRepo.save(ticket);
        notifyAdmins("NEW_TICKET", saved);
        return saved;
    }

    public List<Ticket> getAllTickets() { return ticketRepo.findAll(); }
    public Optional<Ticket> getById(Long id) { return ticketRepo.findById(id); }
    public List<Ticket> getByUser(Long userId) { return ticketRepo.findByUserId(userId); }

    public List<Ticket> getWithFilters(TicketStatus status, TicketPriority priority, TicketCategory category) {
        return ticketRepo.findWithFilters(status, priority, category);
    }

    public org.springframework.data.domain.Page<Ticket> getPagedTickets(
            TicketStatus status, TicketPriority priority, TicketCategory category,
            org.springframework.data.domain.Pageable pageable) {
        return ticketRepo.findPagedWithFilters(status, priority, category, pageable);
    }

    public Ticket updateTicket(Long id, Map<String, Object> updates) {
        Ticket ticket = ticketRepo.findById(id)
            .orElseThrow(() -> new RuntimeException("Ticket not found: " + id));
        if (updates.containsKey("status")) {
            TicketStatus s = TicketStatus.valueOf((String) updates.get("status"));
            ticket.setStatus(s);
            if (s == TicketStatus.RESOLVED || s == TicketStatus.CLOSED) ticket.setResolvedAt(LocalDateTime.now());
        }
        if (updates.containsKey("priority")) ticket.setPriority(TicketPriority.valueOf((String) updates.get("priority")));
        if (updates.containsKey("category")) {
            ticket.setCategory(TicketCategory.valueOf((String) updates.get("category")));
            ticket.setDepartment(categorizationService.getDepartment(ticket.getCategory()));
        }
        if (updates.containsKey("assignedToId")) ticket.setAssignedToId(Long.valueOf(updates.get("assignedToId").toString()));
        if (updates.containsKey("assignedToName")) ticket.setAssignedToName((String) updates.get("assignedToName"));
        ticket.setUpdatedAt(LocalDateTime.now());
        Ticket saved = ticketRepo.save(ticket);
        notifyUser(ticket.getUserId(), "TICKET_UPDATED", saved);
        return saved;
    }

    public void deleteTicket(Long id) { ticketRepo.deleteById(id); }

    public TicketResponse addResponse(Long ticketId, TicketResponse response) {
        Ticket ticket = ticketRepo.findById(ticketId)
            .orElseThrow(() -> new RuntimeException("Ticket not found: " + ticketId));
        response.setTicket(ticket);
        response.setCreatedAt(LocalDateTime.now());
        if (response.isStaff() && ticket.getStatus() == TicketStatus.OPEN) {
            ticket.setStatus(TicketStatus.IN_PROGRESS);
            ticketRepo.save(ticket);
        }
        TicketResponse saved = responseRepo.save(response);
        Map<String, Object> msg = new HashMap<>();
        msg.put("ticketId", ticketId);
        msg.put("message", response.getMessage());
        notifyUser(ticket.getUserId(), "NEW_RESPONSE", msg);
        return saved;
    }

    public List<TicketResponse> getResponses(Long ticketId) {
        return responseRepo.findByTicketIdOrderByCreatedAtAsc(ticketId);
    }

    public String regenerateSummary(Long id) {
        Ticket ticket = ticketRepo.findById(id)
            .orElseThrow(() -> new RuntimeException("Ticket not found: " + id));
        String summary = summarizationService.summarize(ticket.getDescription());
        ticket.setAiSummary(summary);
        ticketRepo.save(ticket);
        return summary;
    }

    public String regenerateEnhancement(Long id) {
        Ticket ticket = ticketRepo.findById(id)
            .orElseThrow(() -> new RuntimeException("Ticket not found: " + id));
        String enhanced = enhancementService.enhance(ticket.getTitle(), ticket.getDescription());
        ticket.setEnhancedDescription(enhanced);
        ticketRepo.save(ticket);
        return enhanced;
    }

    public Ticket escalateTicket(Long id) {
        Ticket ticket = ticketRepo.findById(id)
            .orElseThrow(() -> new RuntimeException("Ticket not found: " + id));
        ticket.setEscalated(true);
        ticket.setStatus(TicketStatus.ESCALATED);
        ticket.setPriority(TicketPriority.HIGH);
        ticket.setUpdatedAt(LocalDateTime.now());
        Ticket saved = ticketRepo.save(ticket);
        notifyAdmins("TICKET_ESCALATED", saved);
        notifyUser(ticket.getUserId(), "TICKET_ESCALATED", saved);
        return saved;
    }

    public Map<String, Object> getStatistics() {
        Map<String, Object> stats = new HashMap<>();
        stats.put("total",       ticketRepo.count());
        stats.put("open",        ticketRepo.countByStatus(TicketStatus.OPEN));
        stats.put("inProgress",  ticketRepo.countByStatus(TicketStatus.IN_PROGRESS));
        stats.put("resolved",    ticketRepo.countByStatus(TicketStatus.RESOLVED));
        stats.put("closed",      ticketRepo.countByStatus(TicketStatus.CLOSED));
        stats.put("escalated",   ticketRepo.countByEscalatedTrue());
        stats.put("slaBreached", ticketRepo.countBySlaBreachedTrue());
        stats.put("critical",    ticketRepo.countByPriority(TicketPriority.CRITICAL));
        stats.put("high",        ticketRepo.countByPriority(TicketPriority.HIGH));
        stats.put("todayNew",    ticketRepo.countCreatedSince(LocalDateTime.now().minusDays(1)));
        stats.put("weekNew",     ticketRepo.countCreatedSince(LocalDateTime.now().minusDays(7)));
        return stats;
    }

    @Scheduled(cron = "${support.scheduler.cron:0 0 * * * *}")
    public void runScheduledChecks() { checkSlaBreaches(); autoEscalate(); }

    private void checkSlaBreaches() {
        for (Ticket t : ticketRepo.findSlaBreaching(LocalDateTime.now())) {
            t.setSlaBreached(true);
            t.setUpdatedAt(LocalDateTime.now());
            ticketRepo.save(t);
            notifyAdmins("SLA_BREACHED", t);
            notifyUser(t.getUserId(), "SLA_BREACHED", t);
        }
    }

    private void autoEscalate() {
        for (Ticket t : ticketRepo.findForEscalation(LocalDateTime.now().minusHours(48)))
            escalateTicket(t.getId());
    }

    private LocalDateTime computeSlaDeadline(TicketPriority priority) {
        return switch (priority) {
            case CRITICAL -> LocalDateTime.now().plusHours(slaCritical);
            case HIGH     -> LocalDateTime.now().plusHours(slaHigh);
            case MEDIUM   -> LocalDateTime.now().plusHours(slaMedium);
            case LOW      -> LocalDateTime.now().plusHours(slaLow);
        };
    }

    private void notifyAdmins(String type, Object payload) {
        Map<String, Object> msg = new HashMap<>();
        msg.put("type", type); msg.put("data", payload);
        messagingTemplate.convertAndSend("/topic/support/admin", (Object) msg);
    }

    private void notifyUser(Long userId, String type, Object payload) {
        Map<String, Object> msg = new HashMap<>();
        msg.put("type", type); msg.put("data", payload);
        messagingTemplate.convertAndSendToUser(String.valueOf(userId), "/queue/support", (Object) msg);
    }
}
