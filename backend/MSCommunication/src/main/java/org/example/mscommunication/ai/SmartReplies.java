package org.example.mscommunication.ai;

import com.fasterxml.jackson.databind.JsonNode;
import org.example.mscommunication.Message;
import org.example.mscommunication.MessageRepository;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

/** Three short replies the user can send next in a conversation, written by Gemini from the last messages. */
@Service
public class SmartReplies {

    static final int HISTORY = 12;
    static final int MAX_REPLY = 120;

    private final MessageRepository messages;
    private final GeminiClient gemini;

    public SmartReplies(MessageRepository messages, GeminiClient gemini) {
        this.messages = messages;
        this.gemini = gemini;
    }

    public List<String> suggest(Long conversationId, Long userId) {
        List<Message> all = messages.findByConversationIdOrderByTimestampAsc(conversationId);
        List<Message> recent = all.subList(Math.max(0, all.size() - HISTORY), all.size()).stream()
                .filter(m -> m.getContent() != null && !m.getContent().isBlank())
                .toList();
        if (recent.isEmpty()) {
            throw new IllegalArgumentException("Send or receive a message first.");
        }
        StringBuilder chat = new StringBuilder();
        for (Message m : recent) {
            String who = m.getSenderId() != null && m.getSenderId().equals(userId) ? "Me" : "Them";
            String text = m.getContent().strip().replaceAll("\\s+", " ");
            chat.append(who).append(": ").append(text.length() > 400 ? text.substring(0, 400) + "…" : text).append('\n');
        }
        String prompt = """
                You suggest replies in a chat between a client and a freelancer on Workify, a freelance marketplace.
                Write 3 different short replies that "Me" could send next, in the language of the last messages.
                Each under 80 characters, natural and professional, no emojis, no quotes. Make them useful: one that
                agrees or confirms, one that asks a practical question, one that moves the work forward.
                Never invent prices, dates or facts that aren't in the chat. Never suggest paying outside Workify.

                Return JSON: {"replies": ["...", "...", "..."]}

                Chat (oldest first):
                %s""".formatted(chat);
        JsonNode json = gemini.generateJson(prompt);
        List<String> replies = new ArrayList<>();
        for (JsonNode r : json.path("replies")) {
            String text = r.asText("").strip().replaceAll("^\"|\"$", "");
            if (text.isEmpty() || replies.contains(text) || replies.size() == 3) continue;
            replies.add(text.length() > MAX_REPLY ? text.substring(0, MAX_REPLY) : text);
        }
        if (replies.isEmpty()) throw new AiUnavailableException("The AI gave no suggestion. Try again.");
        return replies;
    }
}
