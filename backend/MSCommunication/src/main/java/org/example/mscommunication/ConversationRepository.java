package org.example.mscommunication;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface ConversationRepository extends JpaRepository<Conversation, Long> {


    @Query("SELECT c FROM Conversation c WHERE c.participant1Id = :userId OR c.participant2Id = :userId ORDER BY c.lastMessageTime DESC")
    List<Conversation> findConversationsByUserId(@Param("userId") Long userId);

    @Query("SELECT c FROM Conversation c WHERE (c.participant1Id = :user1 AND c.participant2Id = :user2) OR (c.participant1Id = :user2 AND c.participant2Id = :user1)")
    Optional<Conversation> findByParticipants(@Param("user1") Long user1, @Param("user2") Long user2);
    
    long countByParticipant1IdOrParticipant2Id(Long participant1Id, Long participant2Id);
}
