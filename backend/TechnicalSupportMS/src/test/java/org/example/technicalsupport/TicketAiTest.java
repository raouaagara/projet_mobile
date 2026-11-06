package org.example.technicalsupport;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.example.technicalsupport.ai.AiExceptionHandler;
import org.example.technicalsupport.ai.AiUnavailableException;
import org.example.technicalsupport.ai.GeminiClient;
import org.example.technicalsupport.controller.TicketController;
import org.example.technicalsupport.entity.TicketCategory;
import org.example.technicalsupport.entity.TicketPriority;
import org.example.technicalsupport.service.TicketAiService;
import org.example.technicalsupport.service.TicketEnhancementService;
import org.example.technicalsupport.service.TicketService;
import org.example.technicalsupport.service.TicketSummarizationService;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.test.util.ReflectionTestUtils;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.mock;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/** Gemini features of the support service, with a fake Gemini (no network). */
class TicketAiTest {

    /** Without a key: like the real client when GEMINI_API_KEY is missing. */
    private static final GeminiClient NO_KEY = new GeminiClient("", "test-model");

    /** Answers with fixed text or JSON. */
    private static GeminiClient answering(String text) {
        return new GeminiClient("test-key", "test-model") {
            @Override
            public String generate(String prompt) {
                return text;
            }

            @Override
            public JsonNode generateJson(String prompt) {
                try {
                    return new ObjectMapper().readTree(text);
                } catch (Exception e) {
                    throw new IllegalStateException(e);
                }
            }
        };
    }

    @Test
    void analysis_withoutKey_isEmptySoKeywordRulesDecide() {
        assertTrue(new TicketAiService(NO_KEY).analyze("Payment", "My money never arrived").isEmpty());
    }

    @Test
    void analysis_readsCategoryPrioritySummaryAndRewrite() {
        var ai = new TicketAiService(answering("""
                {"category": "PAYMENT_ISSUE", "priority": "high", "summary": "Payout missing after approval.",
                 "improvedDescription": "The client approved contract #1 but I haven't been paid."}
                """)).analyze("Payment", "client approve contract 1 but no money").orElseThrow();

        assertEquals(TicketCategory.PAYMENT_ISSUE, ai.category());
        assertEquals(TicketPriority.HIGH, ai.priority());
        assertEquals("Payout missing after approval.", ai.summary());
        assertTrue(ai.improvedDescription().contains("contract #1"));
    }

    @Test
    void analysis_unknownValues_areLeftToTheKeywordRules() {
        var ai = new TicketAiService(answering("{\"category\": \"SOMETHING\", \"priority\": \"URGENT\"}"))
                .analyze("Hi", "A question").orElseThrow();
        assertNull(ai.category());
        assertNull(ai.priority());
    }

    @Test
    void enhance_withoutKey_saysWhyInsteadOfReturningTheSameText() {
        var e = assertThrows(AiUnavailableException.class,
                () -> new TicketEnhancementService(NO_KEY).enhance("Payment", "My money never arrived"));
        assertTrue(e.getMessage().contains("GEMINI_API_KEY"));
    }

    @Test
    void summary_withoutKey_isEmpty() {
        assertEquals("", new TicketSummarizationService(NO_KEY).summarize("My money never arrived"));
    }

    @Test
    void enhanceEndpoint_withoutKey_answers503WithTheMessage() throws Exception {
        TicketController controller = new TicketController();
        ReflectionTestUtils.setField(controller, "ticketService", mock(TicketService.class));
        ReflectionTestUtils.setField(controller, "enhancementService", new TicketEnhancementService(NO_KEY));
        MockMvc mvc = MockMvcBuilders.standaloneSetup(controller).setControllerAdvice(new AiExceptionHandler()).build();

        mvc.perform(post("/api/tickets/enhance-text")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"title\":\"Payment\",\"description\":\"My money never arrived\"}"))
                .andExpect(status().isServiceUnavailable())
                .andExpect(jsonPath("$.message").value(org.hamcrest.Matchers.containsString("GEMINI_API_KEY")));
    }
}
