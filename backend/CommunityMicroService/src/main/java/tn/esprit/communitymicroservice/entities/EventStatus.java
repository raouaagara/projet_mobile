package tn.esprit.communitymicroservice.entities;

public enum EventStatus {
    PENDING,    // Waiting for admin approval
    APPROVED,   // Approved by admin and visible to users
    REJECTED    // Rejected by admin
}
