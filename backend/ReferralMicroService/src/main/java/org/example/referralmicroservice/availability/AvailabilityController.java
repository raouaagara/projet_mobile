package org.example.referralmicroservice.availability;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * Time Zone &amp; Availability Tracker.
 * Freelancers set timezone and slots; clients see when they are reachable.
 * Includes world-view for distributed teams.
 */
@RestController
@RequestMapping("/Referral/availability")
@CrossOrigin(origins = "http://localhost")
public class AvailabilityController {

    @Autowired
    private AvailabilityService availabilityService;

    @Value("${referral.availability.enabled:true}")
    private boolean availabilityEnabled;

    private void checkEnabled() {
        if (!availabilityEnabled) {
            throw new RuntimeException("Availability module is disabled");
        }
    }

    // --- Profile ---

    @GetMapping("/profile/{userId}")
    public AvailabilityProfile getProfileByUserId(@PathVariable Long userId) {
        checkEnabled();
        return availabilityService.getProfileByUserId(userId);
    }

    @GetMapping("/profile/{userId}/or-create")
    public AvailabilityProfile getOrCreateProfile(@PathVariable Long userId,
                                                  @RequestParam(defaultValue = "UTC") String timezone) {
        checkEnabled();
        return availabilityService.getOrCreateProfile(userId, timezone);
    }

    @GetMapping("/profiles")
    public List<AvailabilityProfile> getAllProfiles() {
        checkEnabled();
        return availabilityService.getAllProfiles();
    }

    @GetMapping("/profiles/status/{status}")
    public List<AvailabilityProfile> getProfilesByStatus(@PathVariable AvailabilityStatus status) {
        checkEnabled();
        return availabilityService.getProfilesByStatus(status);
    }

    @GetMapping("/world-view")
    public List<Map<String, Object>> getWorldView() {
        checkEnabled();
        return availabilityService.getWorldView();
    }

    @PostMapping("/profiles")
    public AvailabilityProfile createProfile(@RequestBody AvailabilityProfile profile) {
        checkEnabled();
        return availabilityService.createProfile(profile);
    }

    @PutMapping("/profiles/{id}")
    public AvailabilityProfile updateProfile(@PathVariable Long id, @RequestBody AvailabilityProfile profile) {
        checkEnabled();
        return availabilityService.updateProfile(id, profile);
    }

    @PutMapping("/profiles/heartbeat/{userId}")
    public AvailabilityProfile updateHeartbeat(@PathVariable Long userId) {
        checkEnabled();
        return availabilityService.updateHeartbeat(userId);
    }

    @DeleteMapping("/profiles/{id}")
    public void deleteProfile(@PathVariable Long id) {
        checkEnabled();
        availabilityService.deleteProfile(id);
    }

    // --- Slots ---

    @GetMapping("/profiles/{profileId}/slots")
    public List<AvailableSlot> getSlots(@PathVariable Long profileId) {
        checkEnabled();
        return availabilityService.getSlotsByProfileId(profileId);
    }

    @GetMapping("/users/{userId}/slots")
    public List<AvailableSlot> getSlotsByUserId(@PathVariable Long userId) {
        checkEnabled();
        return availabilityService.getSlotsByUserId(userId);
    }

    @PostMapping("/profiles/{profileId}/slots")
    public AvailableSlot addSlot(@PathVariable Long profileId, @RequestBody AvailableSlot slot) {
        checkEnabled();
        return availabilityService.addSlot(profileId, slot);
    }

    @PutMapping("/slots/{id}")
    public AvailableSlot updateSlot(@PathVariable Long id, @RequestBody AvailableSlot slot) {
        checkEnabled();
        return availabilityService.updateSlot(id, slot);
    }

    @DeleteMapping("/slots/{id}")
    public void deleteSlot(@PathVariable Long id) {
        checkEnabled();
        availabilityService.deleteSlot(id);
    }

    /** Propositions de créneaux compatibles - overlapping slots between users */
    @GetMapping("/compatible-slots")
    public List<Map<String, Object>> findCompatibleSlots(@RequestParam List<Long> userIds) {
        checkEnabled();
        return availabilityService.findCompatibleSlots(userIds);
    }
}

