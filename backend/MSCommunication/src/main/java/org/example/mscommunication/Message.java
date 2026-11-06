package org.example.mscommunication;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
public class Message {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private Long conversationId;
    private Long senderId;
    private Long recipientId;

    @Column(columnDefinition = "TEXT")
    private String content;

    private LocalDateTime timestamp;


    public Message() {}

    // Getters et Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Long getConversationId() { return conversationId; }
    public void setConversationId(Long conversationId) { this.conversationId = conversationId; }
    public Long getSenderId() { return senderId; }
    public void setSenderId(Long senderId) { this.senderId = senderId; }
    public Long getRecipientId() { return recipientId; }
    public void setRecipientId(Long recipientId) { this.recipientId = recipientId; }
    public String getContent() { return content; }
    public void setContent(String content) { this.content = content; }
    public LocalDateTime getTimestamp() { return timestamp; }
    public void setTimestamp(LocalDateTime timestamp) { this.timestamp = timestamp; }

    @Column(columnDefinition = "TEXT")
    private String reactions;

    /** False until the recipient opens the conversation (null for messages sent before this existed). */
    private Boolean seen;
    public Boolean getSeen() { return seen; }
    public void setSeen(Boolean seen) { this.seen = seen; } // JSON string: {"👍": 2, "❤️": 1}

    public String getReactions() { return reactions; }
    public void setReactions(String reactions) { this.reactions = reactions; }
}
