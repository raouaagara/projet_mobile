package tn.esprit.communitymicroservice.repositories;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.transaction.annotation.Transactional;
import tn.esprit.communitymicroservice.entities.Event;

import java.util.List;

public interface EventRepository extends JpaRepository<Event, Long> {
    List<Event> findByGroupId(Long groupId);
    
    List<Event> findByClubId(Long clubId);
    
    @Modifying
    @Transactional
    @Query("DELETE FROM Event e WHERE e.group.id = :groupId")
    void deleteByGroupId(@Param("groupId") Long groupId);
    
    @Modifying
    @Transactional
    @Query("DELETE FROM Event e WHERE e.club.id = :clubId")
    void deleteByClubId(@Param("clubId") Long clubId);
}
