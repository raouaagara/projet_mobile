package org.example.mscommunication;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/chat")
public class ChatController{

    @Autowired
    private SimpMessagingTemplate messagingTemplate;

    @Autowired
    private MessageRepository messageRepository;

    @Autowired
    private ConversationRepository conversationRepository;

    @Autowired
    private MessageModerator moderator;

    /** Base URL written in attachment links: the gateway, so phones can open them too. */
    @Value("${chat.public-base-url:http://localhost:8085}")
    private String publicBaseUrl;

    /** Tells the sender why their message was not delivered (on /user/{id}/queue/errors). */
    private void rejectToSender(Message chatMessage, MessageModerator.Verdict verdict) {
        Map<String, Object> error = new HashMap<>();
        error.put("error", "Message not sent");
        error.put("reason", verdict.reason());
        error.put("category", verdict.category());
        error.put("conversationId", chatMessage.getConversationId());
        error.put("content", chatMessage.getContent());
        messagingTemplate.convertAndSendToUser(String.valueOf(chatMessage.getSenderId()), "/queue/errors", error);
    }

    /** Lets apps check a message before sending it. Body: {"text": "..."} */
    @PostMapping("/moderate")
    public Map<String, Object> moderate(@RequestBody Map<String, String> body) {
        return moderator.check(body.get("text"))
                .<Map<String, Object>>map(v -> Map.of("allowed", false, "category", v.category(), "reason", v.reason()))
                .orElse(Map.of("allowed", true));
    }

    @MessageMapping("/chat")
    public void processMessage(@Payload Message chatMessage) {
        Optional<MessageModerator.Verdict> verdict = moderator.check(chatMessage.getContent());
        if (verdict.isPresent()) {
            rejectToSender(chatMessage, verdict.get());
            return;
        }
        chatMessage.setTimestamp(LocalDateTime.now());
        chatMessage.setSeen(false);

        // 1. Sauvegarde du message en base de données
        Message savedMsg = messageRepository.save(chatMessage);

        conversationRepository.findById(chatMessage.getConversationId()).ifPresent(conv -> {
            conv.setLastMessageTime(LocalDateTime.now());
            conversationRepository.save(conv);
        });

        // 2. Envoyer au destinataire
        messagingTemplate.convertAndSendToUser(
                String.valueOf(chatMessage.getRecipientId()),
                "/queue/messages",
                savedMsg
        );

        // 3. Renvoyer à l'expéditeur (pour que l'UI récupère l'ID généré par la DB !)
        messagingTemplate.convertAndSendToUser(
                String.valueOf(chatMessage.getSenderId()),
                "/queue/messages",
                savedMsg
        );
    }

    // =======================================================
    // ✏️ UPDATE MESSAGE
    // =======================================================
    @PutMapping("/messages/{id}")
    public ResponseEntity<?> updateMessage(@PathVariable Long id, @RequestBody Map<String, String> payload) {
        Optional<Message> optionalMsg = messageRepository.findById(id);
        if(optionalMsg.isPresent()){
            Optional<MessageModerator.Verdict> verdict = moderator.check(payload.get("content"));
            if (verdict.isPresent()) {
                return ResponseEntity.status(HttpStatus.UNPROCESSABLE_ENTITY)
                        .body(Map.of("error", "Message not saved", "reason", verdict.get().reason()));
            }
            Message msg = optionalMsg.get();
            msg.setContent(payload.get("content"));
            Message updatedMsg = messageRepository.save(msg);

            // Notifier les deux utilisateurs de la mise à jour
            messagingTemplate.convertAndSendToUser(String.valueOf(msg.getRecipientId()), "/queue/updates", updatedMsg);
            messagingTemplate.convertAndSendToUser(String.valueOf(msg.getSenderId()), "/queue/updates", updatedMsg);

            return ResponseEntity.ok(updatedMsg);
        }
        return ResponseEntity.notFound().build();
    }

    // =======================================================
    // 🗑️ DELETE MESSAGE
    // =======================================================
    @DeleteMapping("/messages/{id}")
    public ResponseEntity<?> deleteMessage(@PathVariable Long id) {
        Optional<Message> optionalMsg = messageRepository.findById(id);
        if(optionalMsg.isPresent()){
            Message msg = optionalMsg.get();
            messageRepository.deleteById(id);

            // Notifier les deux utilisateurs de la suppression
            Map<String, Object> deletePayload = Map.of(
                    "deletedId", id,
                    "conversationId", msg.getConversationId()
            );

            messagingTemplate.convertAndSendToUser(String.valueOf(msg.getRecipientId()), "/queue/deletes", deletePayload);
            messagingTemplate.convertAndSendToUser(String.valueOf(msg.getSenderId()), "/queue/deletes", deletePayload);

            return ResponseEntity.ok().build();
        }
        return ResponseEntity.notFound().build();
    }
    // =======================================================
    // 😊 UPDATE MESSAGE REACTIONS
    // =======================================================
    @PutMapping("/messages/{id}/reactions")
    public ResponseEntity<?> updateReactions(@PathVariable Long id, @RequestBody String reactions) {
        Optional<Message> optionalMsg = messageRepository.findById(id);
        if(optionalMsg.isPresent()){
            Message msg = optionalMsg.get();
            msg.setReactions(reactions);
            Message updatedMsg = messageRepository.save(msg);

            // Notifier les deux utilisateurs de la mise à jour des réactions
            messagingTemplate.convertAndSendToUser(String.valueOf(msg.getRecipientId()), "/queue/updates", updatedMsg);
            messagingTemplate.convertAndSendToUser(String.valueOf(msg.getSenderId()), "/queue/updates", updatedMsg);

            return ResponseEntity.ok(updatedMsg);
        }
        return ResponseEntity.notFound().build();
    }

    // =======================================================
    // 📥 PARTIE CLASSIQUE (API REST pour l'historique)
    // =======================================================

    @GetMapping("/conversations/{userId}")
    public ResponseEntity<List<Conversation>> getUserConversations(@PathVariable Long userId) {
        return ResponseEntity.ok(conversationRepository.findConversationsByUserId(userId));
    }

    @GetMapping("/messages/{conversationId}")
    public ResponseEntity<List<Message>> getMessages(@PathVariable Long conversationId) {
        return ResponseEntity.ok(messageRepository.findByConversationIdOrderByTimestampAsc(conversationId));
    }

    /**
     * The conversations of a user, newest first, with what a conversation list shows:
     * the other person, the last message and how many messages they haven't read.
     */
    @GetMapping("/conversations/{userId}/summary")
    public ResponseEntity<List<Map<String, Object>>> getConversationSummaries(@PathVariable Long userId) {
        List<Map<String, Object>> result = new ArrayList<>();
        for (Conversation conv : conversationRepository.findConversationsByUserId(userId)) {
            Map<String, Object> item = new HashMap<>();
            item.put("id", conv.getId());
            item.put("participant1Id", conv.getParticipant1Id());
            item.put("participant2Id", conv.getParticipant2Id());
            item.put("otherUserId", userId.equals(conv.getParticipant1Id()) ? conv.getParticipant2Id() : conv.getParticipant1Id());
            item.put("lastMessageTime", conv.getLastMessageTime());
            messageRepository.findTopByConversationIdOrderByTimestampDescIdDesc(conv.getId()).ifPresent(last -> {
                item.put("lastMessage", last.getContent());
                item.put("lastSenderId", last.getSenderId());
            });
            item.put("unreadCount", messageRepository.countByConversationIdAndRecipientIdAndSeenFalse(conv.getId(), userId));
            result.add(item);
        }
        return ResponseEntity.ok(result);
    }

    /** [userId] opened the conversation: their messages are marked read and the other person is told. */
    @PutMapping("/conversations/{conversationId}/read")
    public ResponseEntity<?> markRead(@PathVariable Long conversationId, @RequestParam Long userId) {
        List<Message> unread = messageRepository.findByConversationIdAndRecipientIdAndSeenFalse(conversationId, userId);
        if (unread.isEmpty()) return ResponseEntity.ok(Map.of("updated", 0));
        unread.forEach(m -> m.setSeen(true));
        messageRepository.saveAll(unread);
        Map<String, Object> receipt = Map.of("conversationId", conversationId, "readerId", userId);
        unread.stream().map(Message::getSenderId).distinct().forEach(senderId ->
                messagingTemplate.convertAndSendToUser(String.valueOf(senderId), "/queue/reads", receipt));
        return ResponseEntity.ok(Map.of("updated", unread.size()));
    }

    @PostMapping("/conversation/create")
    public ResponseEntity<Conversation> getOrCreateConversation(@RequestParam Long user1, @RequestParam Long user2) {
        if (user1.equals(user2)) {
            return ResponseEntity.badRequest().build();
        }
        Conversation conv = conversationRepository.findByParticipants(user1, user2)
                .orElseGet(() -> conversationRepository.save(new Conversation(user1, user2)));
        return ResponseEntity.ok(conv);
    }

    // =======================================================
    // 📎 FILE UPLOAD (Images & PDFs)
    // =======================================================
    @PostMapping("/upload")
    public ResponseEntity<?> uploadFile(
            @RequestParam("file") org.springframework.web.multipart.MultipartFile file,
            @RequestParam("conversationId") Long conversationId,
            @RequestParam("senderId") Long senderId,
            @RequestParam("recipientId") Long recipientId,
            @RequestParam("content") String content) {
        
        try {
            Optional<MessageModerator.Verdict> verdict = moderator.check(content);
            if (verdict.isPresent()) {
                return ResponseEntity.status(HttpStatus.UNPROCESSABLE_ENTITY)
                        .body(Map.of("error", "Message not sent", "reason", verdict.get().reason()));
            }
            // Save file to server using absolute path (name cleaned: no folders or odd characters)
            String original = file.getOriginalFilename() == null ? "file" : file.getOriginalFilename();
            String safeName = java.nio.file.Paths.get(original).getFileName().toString().replaceAll("[^A-Za-z0-9._-]", "_");
            String fileName = System.currentTimeMillis() + "_" + safeName;
            String uploadDir = System.getProperty("user.dir") + "/uploads/";
            java.nio.file.Path uploadPath = java.nio.file.Paths.get(uploadDir);
            
            System.out.println("Upload directory: " + uploadDir);
            
            if (!java.nio.file.Files.exists(uploadPath)) {
                java.nio.file.Files.createDirectories(uploadPath);
                System.out.println("Created uploads directory");
            }
            
            java.nio.file.Path filePath = uploadPath.resolve(fileName);
            java.nio.file.Files.copy(file.getInputStream(), filePath, java.nio.file.StandardCopyOption.REPLACE_EXISTING);
            
            // Create message with file URL
            Message chatMessage = new Message();
            chatMessage.setConversationId(conversationId);
            chatMessage.setSenderId(senderId);
            chatMessage.setRecipientId(recipientId);
            chatMessage.setContent(content);
            chatMessage.setTimestamp(LocalDateTime.now());
            chatMessage.setSeen(false);

            // Store file URL in message (you can add a separate field for this)
            String fileUrl = publicBaseUrl + "/uploads/" + fileName;
            chatMessage.setContent(content + " [FILE:" + fileUrl + "]");
            
            Message savedMsg = messageRepository.save(chatMessage);
            
            // Update conversation
            conversationRepository.findById(conversationId).ifPresent(conv -> {
                conv.setLastMessageTime(LocalDateTime.now());
                conversationRepository.save(conv);
            });
            
            // Send to recipient
            messagingTemplate.convertAndSendToUser(
                    String.valueOf(recipientId),
                    "/queue/messages",
                    savedMsg
            );
            
            // Send to sender
            messagingTemplate.convertAndSendToUser(
                    String.valueOf(senderId),
                    "/queue/messages",
                    savedMsg
            );
            
            return ResponseEntity.ok(Map.of(
                "message", "File uploaded successfully",
                "fileUrl", fileUrl,
                "messageId", savedMsg.getId()
            ));
            
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(500).body(Map.of("error", "File upload failed: " + e.getMessage()));
        }
    }
}
