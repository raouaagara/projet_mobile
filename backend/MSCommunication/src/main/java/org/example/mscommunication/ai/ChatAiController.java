package org.example.mscommunication.ai;

import org.example.mscommunication.ai.ConversationAi.CatchUp;
import org.example.mscommunication.ai.ConversationAi.Translation;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Map;
import java.util.function.Supplier;

/** IA du module 4 : réponses suggérées, traduction d'un message, résumé d'une conversation. */
@RestController
@RequestMapping("/chat/ai")
public class ChatAiController {

    public record ConversationRequest(Long conversationId, Long userId) {}

    public record TranslateRequest(Long messageId, String language) {}

    private final SmartReplies replies;
    private final ConversationAi conversations;

    public ChatAiController(SmartReplies replies, ConversationAi conversations) {
        this.replies = replies;
        this.conversations = conversations;
    }

    @PostMapping("/replies")
    public Map<String, List<String>> replies(@RequestBody ConversationRequest request) {
        requireConversation(request);
        return badRequestOn(() -> Map.of("replies", replies.suggest(request.conversationId(), request.userId())));
    }

    @PostMapping("/translate")
    public Translation translate(@RequestBody TranslateRequest request) {
        if (request.messageId() == null) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "messageId is required");
        return badRequestOn(() -> conversations.translate(request.messageId(), request.language()));
    }

    @PostMapping("/summary")
    public CatchUp summary(@RequestBody ConversationRequest request) {
        requireConversation(request);
        return badRequestOn(() -> conversations.catchUp(request.conversationId(), request.userId()));
    }

    private static void requireConversation(ConversationRequest request) {
        if (request.conversationId() == null || request.userId() == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "conversationId and userId are required");
        }
    }

    /** A user mistake (no messages yet...) is a 400 with its message, which the app shows. */
    private static <T> T badRequestOn(Supplier<T> call) {
        try {
            return call.get();
        } catch (IllegalArgumentException e) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, e.getMessage());
        }
    }
}
