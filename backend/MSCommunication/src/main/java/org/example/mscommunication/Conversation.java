package org.example.mscommunication;
import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
public class Conversation {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;


    private Long participant1Id;
    private Long participant2Id;


    private LocalDateTime lastMessageTime;


    public Conversation() {}

    public Conversation(Long participant1Id, Long participant2Id) {
        this.participant1Id = participant1Id;
        this.participant2Id = participant2Id;
        this.lastMessageTime = LocalDateTime.now();
    }

    // Getters et Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Long getParticipant1Id() { return participant1Id; }
    public void setParticipant1Id(Long participant1Id) { this.participant1Id = participant1Id; }
    public Long getParticipant2Id() { return participant2Id; }
    public void setParticipant2Id(Long participant2Id) { this.participant2Id = participant2Id; }
    public LocalDateTime getLastMessageTime() { return lastMessageTime; }
    public void setLastMessageTime(LocalDateTime lastMessageTime) { this.lastMessageTime = lastMessageTime; }
}
