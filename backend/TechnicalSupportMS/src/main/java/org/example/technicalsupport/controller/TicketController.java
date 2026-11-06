package org.example.technicalsupport.controller;

import org.example.technicalsupport.dto.AddResponseRequest;
import org.example.technicalsupport.dto.CreateTicketRequest;
import org.example.technicalsupport.entity.*;
import org.example.technicalsupport.service.TicketService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/tickets")
public class TicketController {

    @Autowired private TicketService ticketService;
    @Autowired private org.example.technicalsupport.service.TicketEnhancementService enhancementService;

    // POST /api/tickets/create
    @PostMapping("/create")
    public ResponseEntity<Ticket> create(@RequestBody CreateTicketRequest req) {
        Ticket ticket = new Ticket();
        ticket.setUserId(req.getUserId());
        ticket.setUserEmail(req.getUserEmail());
        ticket.setUserName(req.getUserName());
        ticket.setTitle(req.getTitle());
        ticket.setDescription(req.getDescription());

        // Set priority if provided
        if (req.getPriority() != null && !req.getPriority().isBlank()) {
            try { ticket.setPriority(TicketPriority.valueOf(req.getPriority())); }
            catch (IllegalArgumentException ignored) {}
        }
        // Set category if provided
        if (req.getCategory() != null && !req.getCategory().isBlank()) {
            try { ticket.setCategory(TicketCategory.valueOf(req.getCategory())); }
            catch (IllegalArgumentException ignored) {}
        }

        return ResponseEntity.status(HttpStatus.CREATED).body(ticketService.createTicket(ticket));
    }

    // GET /api/tickets/all (non-paginated, for dashboard widget)
    @GetMapping("/all")
    public ResponseEntity<List<Ticket>> getAllNonPaged() {
        return ResponseEntity.ok(ticketService.getAllTickets());
    }

    // GET /api/tickets  (admin - all tickets with optional filters + pagination)
    @GetMapping
    public ResponseEntity<?> getAll(
            @RequestParam(required = false) TicketStatus status,
            @RequestParam(required = false) TicketPriority priority,
            @RequestParam(required = false) TicketCategory category,
            @RequestParam(defaultValue = "0")  int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "id") String sortBy,
            @RequestParam(defaultValue = "desc") String sortDir) {

        // Validate sortBy to prevent injection
        java.util.List<String> allowedSort = java.util.List.of("id","createdAt","priority","status","userId");
        if (!allowedSort.contains(sortBy)) sortBy = "id";

        org.springframework.data.domain.Sort sort = sortDir.equalsIgnoreCase("asc")
            ? org.springframework.data.domain.Sort.by(sortBy).ascending()
            : org.springframework.data.domain.Sort.by(sortBy).descending();

        org.springframework.data.domain.Pageable pageable =
            org.springframework.data.domain.PageRequest.of(page, size, sort);

        org.springframework.data.domain.Page<Ticket> result =
            ticketService.getPagedTickets(status, priority, category, pageable);

        java.util.Map<String, Object> response = new java.util.HashMap<>();
        response.put("tickets",      result.getContent());
        response.put("totalItems",   result.getTotalElements());
        response.put("totalPages",   result.getTotalPages());
        response.put("currentPage",  result.getNumber());
        response.put("pageSize",     result.getSize());
        return ResponseEntity.ok(response);
    }

    // GET /api/tickets/{id}
    @GetMapping("/{id}")
    public ResponseEntity<Ticket> getById(@PathVariable Long id) {
        return ticketService.getById(id)
            .map(ResponseEntity::ok)
            .orElse(ResponseEntity.notFound().build());
    }

    // GET /api/tickets/user/{userId}
    @GetMapping("/user/{userId}")
    public ResponseEntity<List<Ticket>> getByUser(@PathVariable Long userId) {
        return ResponseEntity.ok(ticketService.getByUser(userId));
    }

    // PUT /api/tickets/update/{id}
    @PutMapping("/update/{id}")
    public ResponseEntity<Ticket> update(@PathVariable Long id, @RequestBody Map<String, Object> updates) {
        return ResponseEntity.ok(ticketService.updateTicket(id, updates));
    }

    // DELETE /api/tickets/{id}
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        ticketService.deleteTicket(id);
        return ResponseEntity.noContent().build();
    }

    // POST /api/tickets/{id}/responses
    @PostMapping("/{id}/responses")
    public ResponseEntity<TicketResponse> addResponse(
            @PathVariable Long id,
            @RequestBody AddResponseRequest req) {
        TicketResponse response = new TicketResponse();
        response.setResponderId(req.getResponderId());
        response.setResponderName(req.getResponderName());
        response.setStaff(req.isStaff());
        response.setMessage(req.getMessage());
        return ResponseEntity.status(HttpStatus.CREATED).body(ticketService.addResponse(id, response));
    }

    // GET /api/tickets/{id}/responses
    @GetMapping("/{id}/responses")
    public ResponseEntity<List<TicketResponse>> getResponses(@PathVariable Long id) {
        return ResponseEntity.ok(ticketService.getResponses(id));
    }

    // POST /api/tickets/escalate/{id}
    @PostMapping("/escalate/{id}")
    public ResponseEntity<Ticket> escalate(@PathVariable Long id) {
        return ResponseEntity.ok(ticketService.escalateTicket(id));
    }

    // POST /api/tickets/enhance-text  (user enhances before submitting)
    @PostMapping("/enhance-text")
    public ResponseEntity<Map<String, String>> enhanceText(@RequestBody Map<String, String> body) {
        String title = body.getOrDefault("title", "");
        String description = body.getOrDefault("description", "");
        if (description.isBlank()) return ResponseEntity.badRequest().body(Map.of("error", "description required"));
        String enhanced = enhancementService.enhance(title, description);
        return ResponseEntity.ok(Map.of("enhanced", enhanced));
    }

    // POST /api/tickets/{id}/summarize
    @PostMapping("/{id}/summarize")
    public ResponseEntity<Map<String, String>> summarize(@PathVariable Long id) {
        return ticketService.getById(id).map(ticket -> {
            String summary = ticketService.regenerateSummary(id);
            return ResponseEntity.ok(Map.of("aiSummary", summary));
        }).orElse(ResponseEntity.notFound().build());
    }

    // POST /api/tickets/{id}/enhance
    @PostMapping("/{id}/enhance")
    public ResponseEntity<Map<String, String>> enhance(@PathVariable Long id) {
        return ticketService.getById(id).map(ticket -> {
            String enhanced = ticketService.regenerateEnhancement(id);
            return ResponseEntity.ok(Map.of("enhancedDescription", enhanced));
        }).orElse(ResponseEntity.notFound().build());
    }

    // POST /api/tickets/enhance-preview  (user previews enhanced description before submit)
    @PostMapping("/enhance-preview")
    public ResponseEntity<Map<String, String>> enhancePreview(@RequestBody Map<String, String> body) {
        String title       = body.getOrDefault("title", "");
        String description = body.getOrDefault("description", "");
        if (description.isBlank())
            return ResponseEntity.badRequest().body(Map.of("error", "Description is required"));
        String enhanced = enhancementService.enhance(title, description);
        return ResponseEntity.ok(Map.of("enhanced", enhanced));
    }

    // GET /api/tickets/statistics
    @GetMapping("/statistics")
    public ResponseEntity<Map<String, Object>> statistics() {
        return ResponseEntity.ok(ticketService.getStatistics());
    }
}

