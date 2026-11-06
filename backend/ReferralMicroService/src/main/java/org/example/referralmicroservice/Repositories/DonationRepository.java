package org.example.referralmicroservice.Repositories;

import org.example.referralmicroservice.Entities.Donation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface DonationRepository extends JpaRepository<Donation, Long> {

    // Find donations by donor
    List<Donation> findByDonorIdOrderByCreatedAtDesc(Long donorId);

    // Find donations by recipient
    List<Donation> findByRecipientIdOrderByCreatedAtDesc(Long recipientId);

    // Find donations by status
    List<Donation> findByStatus(Donation.DonationStatus status);

    // Find completed donations
    List<Donation> findByStatusOrderByCompletedAtDesc(Donation.DonationStatus status);

    // Find donations between two users
    List<Donation> findByDonorIdAndRecipientId(Long donorId, Long recipientId);

    // Find recent donations from donor to recipient (for cooldown check)
    List<Donation> findByDonorIdAndRecipientIdAndCreatedAtAfter(
        Long donorId, Long recipientId, LocalDateTime after
    );

    // Find donations without thank you
    List<Donation> findByRecipientIdAndThankYouSentFalseAndStatus(
        Long recipientId, Donation.DonationStatus status
    );

    // Get total donated by user
    @Query("SELECT SUM(d.amount) FROM Donation d WHERE d.donorId = :userId AND d.status = 'COMPLETED'")
    Double getTotalDonatedByUser(Long userId);

    // Get total received by user
    @Query("SELECT SUM(d.amount) FROM Donation d WHERE d.recipientId = :userId AND d.status = 'COMPLETED'")
    Double getTotalReceivedByUser(Long userId);

    // Count donations by user
    @Query("SELECT COUNT(d) FROM Donation d WHERE d.donorId = :userId AND d.status = 'COMPLETED'")
    Long countDonationsByUser(Long userId);

    // Count unique recipients helped by donor
    @Query("SELECT COUNT(DISTINCT d.recipientId) FROM Donation d WHERE d.donorId = :userId AND d.status = 'COMPLETED'")
    Long countUniqueRecipientsHelped(Long userId);

    // Get donations in date range
    List<Donation> findByCreatedAtBetween(LocalDateTime start, LocalDateTime end);

    // Platform statistics
    @Query("SELECT SUM(d.amount) FROM Donation d WHERE d.status = 'COMPLETED'")
    Double getTotalPlatformDonations();

    @Query("SELECT COUNT(d) FROM Donation d WHERE d.status = 'COMPLETED'")
    Long getTotalDonationCount();

    @Query("SELECT AVG(d.amount) FROM Donation d WHERE d.status = 'COMPLETED'")
    Double getAverageDonationAmount();
}
