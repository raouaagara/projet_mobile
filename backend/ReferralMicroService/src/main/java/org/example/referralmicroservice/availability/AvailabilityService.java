package org.example.referralmicroservice.availability;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@Transactional(readOnly = true)
public class AvailabilityService {

    @Autowired
    private AvailabilityProfileRepository profileRepo;

    @Autowired
    private AvailableSlotRepository slotRepo;

    @Transactional
    public AvailabilityProfile getOrCreateProfile(Long userId, String timezone) {
        return profileRepo.findByUserId(userId)
                .orElseGet(() -> {
                    AvailabilityProfile p = new AvailabilityProfile();
                    p.setUserId(userId);
                    p.setTimezone(timezone != null && !timezone.isBlank() ? timezone : "UTC");
                    p.setStatus(AvailabilityStatus.OFFLINE);
                    return profileRepo.save(p);
                });
    }

    public AvailabilityProfile getProfileByUserId(Long userId) {
        return profileRepo.findByUserId(userId)
                .orElseThrow(() -> new RuntimeException("Availability profile not found for user " + userId));
    }

    public AvailabilityProfile getProfileById(Long id) {
        return profileRepo.findById(id).orElseThrow(() -> new RuntimeException("Availability profile not found"));
    }

    @Transactional
    public AvailabilityProfile createProfile(AvailabilityProfile profile) {
        if (profileRepo.existsByUserId(profile.getUserId())) {
            throw new RuntimeException("Profile already exists for this user");
        }
        return profileRepo.save(profile);
    }

    @Transactional
    public AvailabilityProfile updateProfile(Long id, AvailabilityProfile updates) {
        AvailabilityProfile existing = getProfileById(id);
        if (updates.getTimezone() != null) existing.setTimezone(updates.getTimezone());
        if (updates.getTimezoneOffsetMinutes() != null) existing.setTimezoneOffsetMinutes(updates.getTimezoneOffsetMinutes());
        if (updates.getStatus() != null) existing.setStatus(updates.getStatus());
        if (updates.getCustomStatusMessage() != null) existing.setCustomStatusMessage(updates.getCustomStatusMessage());
        return profileRepo.save(existing);
    }

    @Transactional
    public void deleteProfile(Long id) {
        profileRepo.deleteById(id);
    }

    public List<AvailabilityProfile> getAllProfiles() {
        return profileRepo.findAll();
    }

    public List<AvailabilityProfile> getProfilesByStatus(AvailabilityStatus status) {
        return profileRepo.findByStatus(status);
    }

    /** Update heartbeat / last seen - for "En ligne" status */
    @Transactional
    public AvailabilityProfile updateHeartbeat(Long userId) {
        AvailabilityProfile p = getProfileByUserId(userId);
        p.setLastSeenAt(Instant.now());
        return profileRepo.save(p);
    }

    /** World-view: all profiles with their current status (for world map) */
    public List<Map<String, Object>> getWorldView() {
        return profileRepo.findAll().stream()
                .map(p -> Map.<String, Object>of(
                        "userId", p.getUserId(),
                        "profileId", p.getId(),
                        "timezone", p.getTimezone(),
                        "timezoneOffsetMinutes", p.getTimezoneOffsetMinutes() != null ? p.getTimezoneOffsetMinutes() : 0,
                        "status", p.getStatus().name(),
                        "customStatusMessage", p.getCustomStatusMessage() != null ? p.getCustomStatusMessage() : "",
                        "lastSeenAt", p.getLastSeenAt() != null ? p.getLastSeenAt().toString() : ""
                ))
                .collect(Collectors.toList());
    }

    // --- AvailableSlot CRUD ---

    @Transactional
    public AvailableSlot addSlot(Long profileId, AvailableSlot slot) {
        AvailabilityProfile profile = getProfileById(profileId);
        slot.setProfile(profile);
        return slotRepo.save(slot);
    }

    public List<AvailableSlot> getSlotsByProfileId(Long profileId) {
        return slotRepo.findByProfileId(profileId);
    }

    public List<AvailableSlot> getSlotsByUserId(Long userId) {
        return slotRepo.findByProfile_UserId(userId);
    }

    public AvailableSlot getSlotById(Long id) {
        return slotRepo.findById(id).orElseThrow(() -> new RuntimeException("Slot not found"));
    }

    @Transactional
    public AvailableSlot updateSlot(Long id, AvailableSlot updates) {
        AvailableSlot existing = getSlotById(id);
        if (updates.getDayOfWeek() != null) existing.setDayOfWeek(updates.getDayOfWeek());
        if (updates.getStartTime() != null) existing.setStartTime(updates.getStartTime());
        if (updates.getEndTime() != null) existing.setEndTime(updates.getEndTime());
        return slotRepo.save(existing);
    }

    @Transactional
    public void deleteSlot(Long id) {
        slotRepo.deleteById(id);
    }

    /** Find overlapping slots between multiple users (for "propositions de créneaux compatibles") */
    public List<Map<String, Object>> findCompatibleSlots(List<Long> userIds) {
        if (userIds == null || userIds.isEmpty() || userIds.size() < 2) {
            return List.of();
        }
        // Simple implementation: return slots that share same day and overlapping time for first 2 users
        List<AvailableSlot> slots1 = getSlotsByUserId(userIds.get(0));
        List<AvailableSlot> slots2 = getSlotsByUserId(userIds.get(1));
        return slots1.stream()
                .flatMap(s1 -> slots2.stream()
                        .filter(s2 -> s1.getDayOfWeek() == s2.getDayOfWeek()
                                && s1.getStartTime().isBefore(s2.getEndTime())
                                && s1.getEndTime().isAfter(s2.getStartTime()))
                        .map(s2 -> Map.<String, Object>of(
                                "dayOfWeek", s1.getDayOfWeek().name(),
                                "startTime", s1.getStartTime().isAfter(s2.getStartTime()) ? s1.getStartTime().toString() : s2.getStartTime().toString(),
                                "endTime", s1.getEndTime().isBefore(s2.getEndTime()) ? s1.getEndTime().toString() : s2.getEndTime().toString()
                        )))
                .collect(Collectors.toList());
    }
}
