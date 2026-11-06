package org.example.referralmicroservice.availability;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

/**
 * Freelancer time zone and availability profile.
 * One per freelancer; clients see when they are reachable.
 */
@Entity
@Table(name = "availability_profiles", uniqueConstraints = @UniqueConstraint(columnNames = "userId"))
@Data
@NoArgsConstructor
@AllArgsConstructor
public class AvailabilityProfile {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private Long userId;

    /** IANA timezone (e.g. Europe/Paris, America/New_York) */
    @Column(nullable = false, length = 64)
    private String timezone;

    /** UTC offset in minutes for quick display (e.g. +60 for Paris) */
    private Integer timezoneOffsetMinutes;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 32)
    private AvailabilityStatus status = AvailabilityStatus.OFFLINE;

    /** Custom message when status is CUSTOM */
    @Column(length = 200)
    private String customStatusMessage;

    /** Last activity / heartbeat timestamp */
    private Instant lastSeenAt;

    @OneToMany(mappedBy = "profile", cascade = CascadeType.ALL, orphanRemoval = true)
    @JsonIgnore
    private List<AvailableSlot> slots = new ArrayList<>();
}
