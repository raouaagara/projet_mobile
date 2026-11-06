package org.example.mscommunication.ai;

import com.fasterxml.jackson.databind.JsonNode;
import org.example.mscommunication.Message;
import org.example.mscommunication.MessageRepository;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/** Reading help in a conversation: translate one message, or catch up on a long chat. */
@Service
public class ConversationAi {

    public record Translation(String text, String from) {}

    /** {@code who}: "me" or "them", from the asking user's side. */
    public record Todo(String who, String what) {}

    public record CatchUp(List<String> summary, List<String> decisions, List<Todo> todos) {}

    static final int CATCH_UP_HISTORY = 60;
    private static final int CACHE_SIZE = 500;

    private final MessageRepository messages;
    private final GeminiClient gemini;

    /** A message doesn't change often: translating it twice into the same language costs one call. */
    private final Map<String, Translation> translations = Collections.synchronizedMap(
            new LinkedHashMap<>(16, 0.75f, true) {
                @Override
                protected boolean removeEldestEntry(Map.Entry<String, Translation> eldest) {
                    return size() > CACHE_SIZE;
                }
            });

    public ConversationAi(MessageRepository messages, GeminiClient gemini) {
        this.messages = messages;
        this.gemini = gemini;
    }

    /** [messageId]'s text in [language] (a name or code: "French", "en", "العربية"...). */
    public Translation translate(Long messageId, String language) {
        Message message = messages.findById(messageId)
                .orElseThrow(() -> new IllegalArgumentException("Message not found."));
        String text = message.getContent() == null ? "" : message.getContent().strip();
        if (text.isEmpty()) throw new IllegalArgumentException("This message has no text to translate.");
        String target = language == null || language.isBlank() ? "English" : language.strip();
        String key = messageId + "|" + target.toLowerCase() + "|" + text.hashCode();
        Translation cached = translations.get(key);
        if (cached != null) return cached;

        String prompt = """
                Translate this chat message into %s. Keep the meaning, tone, names, numbers, dates and links exactly;
                keep emojis. If it is already in %s, return it unchanged.
                Return JSON: {"text": "the translation", "from": "the original language, in English, e.g. French"}

                Message: %s
                """.formatted(target, target, text.length() > 2000 ? text.substring(0, 2000) : text);
        JsonNode json = gemini.generateJson(prompt);
        String translated = json.path("text").asText("").strip();
        if (translated.isEmpty()) throw new AiUnavailableException("The AI gave an empty translation. Try again.");
        Translation result = new Translation(translated, json.path("from").asText("").strip());
        translations.put(key, result);
        return result;
    }

    /** What was said, what was decided, and who has to do what, seen from [userId]'s side. */
    public CatchUp catchUp(Long conversationId, Long userId) {
        List<Message> all = messages.findByConversationIdOrderByTimestampAsc(conversationId);
        List<Message> recent = all.subList(Math.max(0, all.size() - CATCH_UP_HISTORY), all.size()).stream()
                .filter(m -> m.getContent() != null && !m.getContent().isBlank())
                .toList();
        if (recent.size() < 3) throw new IllegalArgumentException("Not enough messages to summarize yet.");
        StringBuilder chat = new StringBuilder();
        for (Message m : recent) {
            String who = userId.equals(m.getSenderId()) ? "Me" : "Them";
            String day = m.getTimestamp() == null ? "" : "[" + m.getTimestamp().toLocalDate() + "] ";
            String text = m.getContent().strip().replaceAll("\\s+", " ");
            chat.append(day).append(who).append(": ").append(text.length() > 500 ? text.substring(0, 500) + "…" : text)
                    .append('\n');
        }
        String prompt = """
                Summarize this chat between a client and a freelancer on Workify for "Me", in the language of the chat.
                Use ONLY what the messages say; never invent prices, dates or promises.

                Return JSON:
                {"summary": ["2 to 4 short sentences: where the work stands"],
                 "decisions": ["what both agreed on: price, deadline, scope, files... (empty list if nothing)"],
                 "todos": [{"who": "me" or "them", "what": "a short action still to do"}]}
                At most 5 decisions and 5 todos.

                Chat (oldest first):
                %s""".formatted(chat);
        JsonNode json = gemini.generateJson(prompt);
        List<String> summary = strings(json.path("summary"), 4);
        if (summary.isEmpty()) throw new AiUnavailableException("The AI gave an empty summary. Try again.");
        List<Todo> todos = new ArrayList<>();
        for (JsonNode t : json.path("todos")) {
            String what = t.path("what").asText("").strip();
            if (what.isEmpty() || todos.size() == 5) continue;
            todos.add(new Todo("me".equalsIgnoreCase(t.path("who").asText("").strip()) ? "me" : "them", what));
        }
        return new CatchUp(summary, strings(json.path("decisions"), 5), todos);
    }

    private static List<String> strings(JsonNode array, int max) {
        List<String> out = new ArrayList<>();
        for (JsonNode n : array) {
            String s = n.asText("").strip();
            if (!s.isEmpty() && out.size() < max) out.add(s);
        }
        return out;
    }
}
