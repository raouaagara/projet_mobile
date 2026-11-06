package org.example.technicalsupport;

import tools.jackson.databind.ObjectMapper;
import org.example.technicalsupport.controller.TicketController;
import org.example.technicalsupport.entity.*;
import org.example.technicalsupport.service.TicketService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.time.LocalDateTime;
import java.util.*;

import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(TicketController.class)
class TicketControllerIntegrationTest {

    @Autowired private MockMvc mockMvc;
    @Autowired private ObjectMapper objectMapper;
    @MockitoBean private TicketService ticketService;
    @MockitoBean private org.example.technicalsupport.service.TicketEnhancementService enhancementService;

    private Ticket buildTicket() {
        return Ticket.builder()
            .id(1L).userId(10L).title("Test Ticket")
            .description("Test description").status(TicketStatus.OPEN)
            .priority(TicketPriority.MEDIUM).category(TicketCategory.TECHNICAL_ISSUE)
            .department("Technical Team").createdAt(LocalDateTime.now())
            .build();
    }

    @Test
    void createTicket_shouldReturn201() throws Exception {
        Ticket ticket = buildTicket();
        when(ticketService.createTicket(any())).thenReturn(ticket);

        Map<String, Object> body = Map.of(
            "userId", 10, "title", "Test Ticket",
            "description", "Test description", "priority", "MEDIUM"
        );

        mockMvc.perform(post("/api/tickets/create")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(body)))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.id").value(1))
            .andExpect(jsonPath("$.status").value("OPEN"));
    }

    @Test
    void getTicketById_shouldReturn200() throws Exception {
        when(ticketService.getById(1L)).thenReturn(Optional.of(buildTicket()));

        mockMvc.perform(get("/api/tickets/1"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.title").value("Test Ticket"));
    }

    @Test
    void getTicketById_shouldReturn404_whenNotFound() throws Exception {
        when(ticketService.getById(99L)).thenReturn(Optional.empty());

        mockMvc.perform(get("/api/tickets/99"))
            .andExpect(status().isNotFound());
    }

    @Test
    void updateTicket_shouldReturn200() throws Exception {
        Ticket updated = buildTicket();
        updated.setStatus(TicketStatus.IN_PROGRESS);
        when(ticketService.updateTicket(eq(1L), any())).thenReturn(updated);

        mockMvc.perform(put("/api/tickets/update/1")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"status\":\"IN_PROGRESS\"}"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.status").value("IN_PROGRESS"));
    }

    @Test
    void deleteTicket_shouldReturn204() throws Exception {
        doNothing().when(ticketService).deleteTicket(1L);

        mockMvc.perform(delete("/api/tickets/1"))
            .andExpect(status().isNoContent());
    }

    @Test
    void escalateTicket_shouldReturn200() throws Exception {
        Ticket escalated = buildTicket();
        escalated.setEscalated(true);
        escalated.setStatus(TicketStatus.ESCALATED);
        when(ticketService.escalateTicket(1L)).thenReturn(escalated);

        mockMvc.perform(post("/api/tickets/escalate/1"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.escalated").value(true))
            .andExpect(jsonPath("$.status").value("ESCALATED"));
    }

    @Test
    void getStatistics_shouldReturn200() throws Exception {
        Map<String, Object> stats = Map.of("total", 5L, "open", 2L, "resolved", 3L);
        when(ticketService.getStatistics()).thenReturn(stats);

        mockMvc.perform(get("/api/tickets/statistics"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.total").value(5));
    }

    @Test
    void summarize_shouldReturn200() throws Exception {
        when(ticketService.getById(1L)).thenReturn(Optional.of(buildTicket()));
        when(ticketService.regenerateSummary(1L)).thenReturn("Short summary.");

        mockMvc.perform(post("/api/tickets/1/summarize"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.aiSummary").value("Short summary."));
    }

    @Test
    void enhance_shouldReturn200() throws Exception {
        when(ticketService.getById(1L)).thenReturn(Optional.of(buildTicket()));
        when(ticketService.regenerateEnhancement(1L)).thenReturn("Enhanced description.");

        mockMvc.perform(post("/api/tickets/1/enhance"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.enhancedDescription").value("Enhanced description."));
    }
}
