package org.example.subscriptionmicroservice.Repositories;

import org.example.subscriptionmicroservice.Entities.SpinWheelAttempt;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface SpinWheelAttemptRepository extends JpaRepository<SpinWheelAttempt, Long> {
    List<SpinWheelAttempt> findByUserId(Long userId);
    
    Optional<SpinWheelAttempt> findFirstByUserIdOrderByAttemptDateDesc(Long userId);
    
    boolean existsByUserIdAndAttemptDateAfter(Long userId, LocalDateTime date);
}
