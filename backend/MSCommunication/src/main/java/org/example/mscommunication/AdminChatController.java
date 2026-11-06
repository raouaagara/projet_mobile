package org.example.mscommunication;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/chat/admin")
public class AdminChatController {

    @Autowired
    private MessageRepository messageRepository;

    @Autowired
    private ConversationRepository conversationRepository;

    // Get all conversations with statistics
    @GetMapping("/conversations")
    public ResponseEntity<List<Map<String, Object>>> getAllConversations() {
        List<Conversation> conversations = conversationRepository.findAll();
        
        List<Map<String, Object>> result = conversations.stream().map(conv -> {
            Map<String, Object> convData = new HashMap<>();
            convData.put("id", conv.getId());
            convData.put("participant1Id", conv.getParticipant1Id());
            convData.put("participant2Id", conv.getParticipant2Id());
            convData.put("lastMessageTime", conv.getLastMessageTime());
            
            // Count messages
            long messageCount = messageRepository.countByConversationId(conv.getId());
            convData.put("messageCount", messageCount);
            convData.put("status", "active");
            
            return convData;
        }).collect(Collectors.toList());
        
        return ResponseEntity.ok(result);
    }

    // Get statistics
    @GetMapping("/statistics")
    public ResponseEntity<Map<String, Object>> getStatistics() {
        Map<String, Object> stats = new HashMap<>();
        
        // Total conversations
        long totalConversations = conversationRepository.count();
        stats.put("totalConversations", totalConversations);
        
        // Total messages
        long totalMessages = messageRepository.count();
        stats.put("totalMessages", totalMessages);
        
        // Active users (unique senders in last 24 hours)
        LocalDateTime yesterday = LocalDateTime.now().minusDays(1);
        List<Message> recentMessages = messageRepository.findByTimestampAfter(yesterday);
        long activeUsers = recentMessages.stream()
                .map(Message::getSenderId)
                .distinct()
                .count();
        stats.put("activeUsers", activeUsers);
        
        // Today's messages
        LocalDateTime startOfDay = LocalDateTime.now().withHour(0).withMinute(0).withSecond(0);
        long todayMessages = messageRepository.countByTimestampAfter(startOfDay);
        stats.put("todayMessages", todayMessages);
        
        // Week messages
        LocalDateTime weekAgo = LocalDateTime.now().minusWeeks(1);
        long weekMessages = messageRepository.countByTimestampAfter(weekAgo);
        stats.put("weekMessages", weekMessages);
        
        // Month messages
        LocalDateTime monthAgo = LocalDateTime.now().minusMonths(1);
        long monthMessages = messageRepository.countByTimestampAfter(monthAgo);
        stats.put("monthMessages", monthMessages);
        
        return ResponseEntity.ok(stats);
    }

    // Get conversation messages
    @GetMapping("/conversations/{conversationId}/messages")
    public ResponseEntity<List<Message>> getConversationMessages(@PathVariable Long conversationId) {
        List<Message> messages = messageRepository.findByConversationIdOrderByTimestampAsc(conversationId);
        return ResponseEntity.ok(messages);
    }

    // Delete conversation
    @DeleteMapping("/conversations/{conversationId}")
    @Transactional
    public ResponseEntity<?> deleteConversation(@PathVariable Long conversationId) {
        try {
            // Delete all messages first
            messageRepository.deleteByConversationId(conversationId);
            
            // Delete conversation
            conversationRepository.deleteById(conversationId);
            
            Map<String, String> response = new HashMap<>();
            response.put("message", "Conversation deleted successfully");
            response.put("id", conversationId.toString());
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", "Failed to delete conversation");
            error.put("message", e.getMessage());
            return ResponseEntity.internalServerError().body(error);
        }
    }

    // Search conversations
    @GetMapping("/search")
    public ResponseEntity<List<Conversation>> searchConversations(@RequestParam String q) {
        // Simple search implementation
        List<Conversation> allConversations = conversationRepository.findAll();
        
        // Filter by participant IDs containing the query
        List<Conversation> filtered = allConversations.stream()
                .filter(conv -> 
                    String.valueOf(conv.getParticipant1Id()).contains(q) ||
                    String.valueOf(conv.getParticipant2Id()).contains(q)
                )
                .collect(Collectors.toList());
        
        return ResponseEntity.ok(filtered);
    }

    // Filter conversations
    @PostMapping("/filter")
    public ResponseEntity<List<Conversation>> filterConversations(@RequestBody Map<String, Object> filters) {
        List<Conversation> conversations = conversationRepository.findAll();
        
        // Apply filters based on the request
        // This is a simple implementation - extend as needed
        
        return ResponseEntity.ok(conversations);
    }

    // Get user activity
    @GetMapping("/users/{userId}/activity")
    public ResponseEntity<Map<String, Object>> getUserActivity(@PathVariable Long userId) {
        Map<String, Object> activity = new HashMap<>();
        
        // Count messages sent
        long messagesSent = messageRepository.countBySenderId(userId);
        activity.put("messagesSent", messagesSent);
        
        // Count conversations
        long conversationCount = conversationRepository.countByParticipant1IdOrParticipant2Id(userId, userId);
        activity.put("conversationCount", conversationCount);
        
        // Last activity
        List<Message> userMessages = messageRepository.findBySenderIdOrderByTimestampDesc(userId);
        if (!userMessages.isEmpty()) {
            activity.put("lastActivity", userMessages.get(0).getTimestamp());
        }
        
        return ResponseEntity.ok(activity);
    }
}

