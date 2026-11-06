package org.example.technicalsupport.repository;

import org.example.technicalsupport.entity.Ticket;
import org.example.technicalsupport.entity.TicketCategory;
import org.example.technicalsupport.entity.TicketPriority;
import org.example.technicalsupport.entity.TicketStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.List;

public interface TicketRepository extends JpaRepository<Ticket, Long> {

    List<Ticket> findByUserId(Long userId);
    List<Ticket> findByStatus(TicketStatus status);
    List<Ticket> findByPriority(TicketPriority priority);
    List<Ticket> findByCategory(TicketCategory category);
    List<Ticket> findByAssignedToId(Long staffId);
    List<Ticket> findByEscalatedTrue();
    List<Ticket> findBySlaBreachedTrue();

    @Query("SELECT t FROM Ticket t WHERE t.status NOT IN ('RESOLVED','CLOSED') AND t.slaDeadline < :now AND t.slaBreached = false")
    List<Ticket> findSlaBreaching(@Param("now") LocalDateTime now);

    @Query("SELECT t FROM Ticket t WHERE t.status NOT IN ('RESOLVED','CLOSED') AND t.createdAt < :threshold AND t.escalated = false")
    List<Ticket> findForEscalation(@Param("threshold") LocalDateTime threshold);

    @Query("SELECT t FROM Ticket t WHERE " +
           "(:status IS NULL OR t.status = :status) AND " +
           "(:priority IS NULL OR t.priority = :priority) AND " +
           "(:category IS NULL OR t.category = :category)")
    List<Ticket> findWithFilters(
        @Param("status") TicketStatus status,
        @Param("priority") TicketPriority priority,
        @Param("category") TicketCategory category
    );

    @Query("SELECT t FROM Ticket t WHERE " +
           "(:status IS NULL OR t.status = :status) AND " +
           "(:priority IS NULL OR t.priority = :priority) AND " +
           "(:category IS NULL OR t.category = :category)")
    Page<Ticket> findPagedWithFilters(
        @Param("status") TicketStatus status,
        @Param("priority") TicketPriority priority,
        @Param("category") TicketCategory category,
        Pageable pageable
    );

    long countByStatus(TicketStatus status);
    long countByPriority(TicketPriority priority);
    long countByEscalatedTrue();
    long countBySlaBreachedTrue();

    @Query("SELECT COUNT(t) FROM Ticket t WHERE t.createdAt >= :since")
    long countCreatedSince(@Param("since") LocalDateTime since);
}
