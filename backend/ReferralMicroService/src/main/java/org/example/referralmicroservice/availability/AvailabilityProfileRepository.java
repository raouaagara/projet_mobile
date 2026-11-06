package org.example.referralmicroservice.availability;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface AvailabilityProfileRepository extends JpaRepository<AvailabilityProfile, Long> {

    Optional<AvailabilityProfile> findByUserId(Long userId);

    List<AvailabilityProfile> findByStatus(AvailabilityStatus status);

    boolean existsByUserId(Long userId);
}
