package org.example.referralmicroservice.availability;

import org.springframework.data.jpa.repository.JpaRepository;

import java.time.DayOfWeek;
import java.util.List;

public interface AvailableSlotRepository extends JpaRepository<AvailableSlot, Long> {

    List<AvailableSlot> findByProfileId(Long profileId);

    List<AvailableSlot> findByProfile_UserId(Long userId);

    List<AvailableSlot> findByProfileIdAndDayOfWeek(Long profileId, DayOfWeek dayOfWeek);
}
