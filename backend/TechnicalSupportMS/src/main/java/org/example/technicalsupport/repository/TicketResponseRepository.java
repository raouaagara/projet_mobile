package org.example.technicalsupport.repository;

import org.example.technicalsupport.entity.TicketResponse;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface TicketResponseRepository extends JpaRepository<TicketResponse, Long> {
    List<TicketResponse> findByTicketIdOrderByCreatedAtAsc(Long ticketId);
}
