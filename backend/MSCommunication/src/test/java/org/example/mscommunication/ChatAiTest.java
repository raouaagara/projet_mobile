package org.example.mscommunication;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.example.mscommunication.ai.AiModerator;
import org.example.mscommunication.ai.AiUnavailableException;
import org.example.mscommunication.ai.ConversationAi;
import org.example.mscommunication.ai.GeminiClient;
import org.example.mscommunication.ai.SmartReplies;
import org.junit.jupiter.api.Test;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

/** AI moderation (after the word list) and suggested replies, with a fake Gemini (no network). */
class ChatAiTest {

    private final AtomicInteger calls = new AtomicInteger();
    private String lastPrompt;

    private GeminiClient answering(String json) {
        return new GeminiClient("test-key", "test-model") {
            @Override
            public JsonNode generateJson(String prompt) {
                calls.incrementAndGet();
                lastPrompt = prompt;
                try {
                    return new ObjectMapper().readTree(json);
                } catch (Exception e) {
                    throw new IllegalStateException(e);
                }
            }
        };
    }

    private GeminiClient failing() {
        return new GeminiClient("test-key", "test-model") {
            @Override
            public JsonNode generateJson(String prompt) {
                calls.incrementAndGet();
                throw new AiUnavailableException("The AI service can't be reached right now.");
            }
        };
    }

    @Test
    void aiBlocksWhatTheWordListMisses() {
        MessageModerator moderator = new MessageModerator(new AiModerator(answering(
                "{\"category\": \"scam\", \"reason\": \"Keep payments on Workify.\"}")));

        var verdict = moderator.check("Pay me by bank transfer directly, we skip the fees");

        assertEquals("scam", verdict.orElseThrow().category());
        assertEquals("Keep payments on Workify.", verdict.get().reason());
        assertTrue(lastPrompt.contains("we skip the fees"));
    }

    @Test
    void wordListAnswersFirstWithoutCallingTheAi() {
        MessageModerator moderator = new MessageModerator(new AiModerator(answering("{\"category\": \"none\"}")));

        assertEquals("harassment", moderator.check("You are an idiot").orElseThrow().category());
        assertEquals(0, calls.get());
    }

    @Test
    void shortOrAllowedMessagesPassAndVerdictsAreCached() {
        AiModerator ai = new AiModerator(answering("{\"category\": \"none\", \"reason\": \"\"}"));

        assertTrue(ai.check("ok thanks").isEmpty()); // too short to ask
        assertTrue(ai.check("The deadline is too short for this").isEmpty());
        assertTrue(ai.check("The deadline is too short for this").isEmpty());
        assertEquals(1, calls.get());
    }

    @Test
    void aiDownLetsTheMessageThrough() {
        AiModerator ai = new AiModerator(failing());
        assertTrue(ai.check("Can you send the files tomorrow morning?").isEmpty());
        assertTrue(new AiModerator(new GeminiClient("", "m")).check("Can you send the files tomorrow?").isEmpty());
    }

    private static Message message(long sender, String text) {
        Message m = new Message();
        m.setConversationId(3L);
        m.setSenderId(sender);
        m.setContent(text);
        m.setTimestamp(LocalDateTime.now());
        return m;
    }

    @Test
    void repliesFollowTheChatAndAreCleanedUp() {
        MessageRepository repo = mock(MessageRepository.class);
        when(repo.findByConversationIdOrderByTimestampAsc(3L)).thenReturn(List.of(
                message(7, "Hi, can you start on Monday?"), message(2, "Yes, I can.")));
        SmartReplies replies = new SmartReplies(repo, answering(
                "{\"replies\": [\"\\\"Great, see you Monday\\\"\", \"Great, see you Monday\", \"What do you need first?\", \"\", \"I'll send a plan\", \"extra\"]}"));

        List<String> out = replies.suggest(3L, 7L);

        assertEquals(List.of("Great, see you Monday", "What do you need first?", "I'll send a plan"), out);
        assertTrue(lastPrompt.contains("Me: Hi, can you start on Monday?") && lastPrompt.contains("Them: Yes, I can."));
    }

    @Test
    void noMessagesNoSuggestions() {
        MessageRepository repo = mock(MessageRepository.class);
        when(repo.findByConversationIdOrderByTimestampAsc(3L)).thenReturn(List.of());
        assertThrows(IllegalArgumentException.class, () -> new SmartReplies(repo, answering("{}")).suggest(3L, 7L));
    }

    @Test
    void translationKeepsTheMeaningAndIsCached() {
        MessageRepository repo = mock(MessageRepository.class);
        Message m = message(7, "Je t'envoie les maquettes demain");
        m.setId(11L);
        when(repo.findById(11L)).thenReturn(Optional.of(m));
        ConversationAi ai = new ConversationAi(repo, answering(
                "{\"text\": \"I'll send you the mockups tomorrow\", \"from\": \"French\"}"));

        var t = ai.translate(11L, "English");
        ai.translate(11L, "English");

        assertEquals("I'll send you the mockups tomorrow", t.text());
        assertEquals("French", t.from());
        assertEquals(1, calls.get());
        assertTrue(lastPrompt.contains("into English") && lastPrompt.contains("Je t'envoie les maquettes demain"));
    }

    @Test
    void catchUpIsFromMySideAndBounded() {
        MessageRepository repo = mock(MessageRepository.class);
        when(repo.findByConversationIdOrderByTimestampAsc(3L)).thenReturn(List.of(
                message(7, "Can you do it for $500?"), message(2, "Yes, by Friday."), message(7, "Deal, send the plan.")));
        ConversationAi ai = new ConversationAi(repo, answering("""
                {"summary": ["You agreed on the price."], "decisions": ["$500", "Friday"],
                 "todos": [{"who": "THEM", "what": "Send the plan"}, {"who": "me", "what": "Pay on delivery"}, {"who": "me", "what": ""}]}"""));

        var c = ai.catchUp(3L, 7L);

        assertEquals(List.of("You agreed on the price."), c.summary());
        assertEquals(List.of("$500", "Friday"), c.decisions());
        assertEquals(List.of(new ConversationAi.Todo("them", "Send the plan"), new ConversationAi.Todo("me", "Pay on delivery")),
                c.todos());
        assertTrue(lastPrompt.contains("Me: Can you do it for $500?") && lastPrompt.contains("Them: Yes, by Friday."));
    }

    @Test
    void catchUpNeedsAFewMessages() {
        MessageRepository repo = mock(MessageRepository.class);
        when(repo.findByConversationIdOrderByTimestampAsc(3L)).thenReturn(List.of(message(7, "Hi")));
        assertThrows(IllegalArgumentException.class, () -> new ConversationAi(repo, answering("{}")).catchUp(3L, 7L));
    }
}
