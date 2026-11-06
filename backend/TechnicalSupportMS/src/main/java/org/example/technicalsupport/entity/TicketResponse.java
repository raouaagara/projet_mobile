package org.example.technicalsupport.entity;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

@Entity
@Table(name = "ticket_responses")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class TicketResponse {

    private static final DateTimeFormatter FMT = DateTimeFormatter.ISO_LOCAL_DATE_TIME;

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @JsonIgnore
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "ticket_id")
    private Ticket ticket;

    private Long responderId;
    private String responderName;
    private boolean isStaff;

    @Lob
    @Column(columnDefinition = "LONGTEXT")
    private String message;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    public String getCreatedAtStr() { return createdAt != null ? createdAt.format(FMT) : null; }

    // Explicit getter/setter for isStaff to avoid Lombok naming issues
    public boolean isStaff() { return isStaff; }
    public void setStaff(boolean staff) { isStaff = staff; }


    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Ticket getTicket() {
        return ticket;
    }

    public void setTicket(Ticket ticket) {
        this.ticket = ticket;
    }

    public Long getResponderId() {
        return responderId;
    }

    public void setResponderId(Long responderId) {
        this.responderId = responderId;
    }

    public String getResponderName() {
        return responderName;
    }

    public void setResponderName(String responderName) {
        this.responderName = responderName;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
}
