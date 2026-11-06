package org.example.referralmicroservice.availability;

/**
 * Status for freelancer availability display.
 * Used for "En ligne", "Disponible demain", etc.
 */
public enum AvailabilityStatus {
    /** Currently online and reachable */
    ONLINE,
    /** Available within configured hours */
    AVAILABLE,
    /** Available tomorrow (next business day) */
    AVAILABLE_TOMORROW,
    /** Offline / not reachable */
    OFFLINE,
    /** Online but do not disturb */
    DO_NOT_DISTURB,
    /** Custom message (e.g. "On vacation") */
    CUSTOM
}
