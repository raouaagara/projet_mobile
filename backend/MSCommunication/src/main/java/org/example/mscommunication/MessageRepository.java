package org.example.mscommunication;

import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

public interface MessageRepository extends JpaRepository<Message, Long> {

    List<Message> findByConversationIdOrderByTimestampAsc(Long conversationId);
    
    long countByConversationId(Long conversationId);
    
    List<Message> findByTimestampAfter(LocalDateTime timestamp);
    
    long countByTimestampAfter(LocalDateTime timestamp);
    
    void deleteByConversationId(Long conversationId);
    
    long countBySenderId(Long senderId);
    
    List<Message> findBySenderIdOrderByTimestampDesc(Long senderId);

    Optional<Message> findTopByConversationIdOrderByTimestampDescIdDesc(Long conversationId);

    long countByConversationIdAndRecipientIdAndSeenFalse(Long conversationId, Long recipientId);

    List<Message> findByConversationIdAndRecipientIdAndSeenFalse(Long conversationId, Long recipientId);
}
