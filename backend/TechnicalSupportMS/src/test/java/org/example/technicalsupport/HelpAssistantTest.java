package org.example.technicalsupport;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.example.technicalsupport.ai.AiUnavailableException;
import org.example.technicalsupport.ai.GeminiClient;
import org.example.technicalsupport.service.HelpAssistantService;
import org.example.technicalsupport.service.HelpAssistantService.Answer;
import org.example.technicalsupport.service.HelpAssistantService.Turn;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

/** The help assistant answers from the guide and drafts a request when the team must act. Fake Gemini. */
class HelpAssistantTest {

    private String lastPrompt;

    private HelpAssistantService answering(String json) {
        return new HelpAssistantService(new GeminiClient("test-key", "test-model") {
            @Override
            public JsonNode generateJson(String prompt) {
                lastPrompt = prompt;
                try {
                    return new ObjectMapper().readTree(json);
                } catch (Exception e) {
                    throw new IllegalStateException(e);
                }
            }
        });
    }

    @Test
    void answersFromTheGuideWithTheConversation() {
        HelpAssistantService assistant = answering(
                "{\"answer\": \"Open the contract and tap Approve & pay.\", \"needsTicket\": false, \"ticketTitle\": \"x\"}");

        Answer a = assistant.ask("How do I pay the freelancer?", List.of(new Turn("user", "hi"), new Turn("assistant", "Hello!")));

        assertEquals("Open the contract and tap Approve & pay.", a.answer());
        assertFalse(a.needsTicket());
        assertEquals("", a.ticketTitle()); // no ticket fields when no ticket
        assertTrue(lastPrompt.contains("locked in escrow")); // the guide is in the prompt
        assertTrue(lastPrompt.contains("User: hi") && lastPrompt.contains("Assistant: Hello!"));
        assertTrue(lastPrompt.contains("User: How do I pay the freelancer?"));
    }

    @Test
    void draftsTheRequestWhenTheTeamMustAct() {
        HelpAssistantService assistant = answering(
                "{\"answer\": \"The team will check it.\", \"needsTicket\": true, \"ticketTitle\": \"\", \"ticketDescription\": \"\"}");

        Answer a = assistant.ask("My wallet lost 200 dinars after the top up yesterday", List.of());

        assertTrue(a.needsTicket());
        assertEquals("My wallet lost 200 dinars after the top up yesterday", a.ticketTitle()); // filled from the question
        assertEquals("My wallet lost 200 dinars after the top up yesterday", a.ticketDescription());
    }

    @Test
    void needsAQuestionAndAnAnswer() {
        assertThrows(IllegalArgumentException.class, () -> answering("{}").ask(" ", null));
        assertThrows(AiUnavailableException.class, () -> answering("{\"answer\": \"\"}").ask("How do I top up?", null));
    }
}
