package org.example.referralmicroservice.Repositories;

import org.example.referralmicroservice.Entities.UserWallet;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface UserWalletRepository extends JpaRepository<UserWallet, Long> {

    Optional<UserWallet> findByUserId(Long userId);

    boolean existsByUserId(Long userId);

    // Find top earners
    List<UserWallet> findTop10ByOrderByTotalEarnedDesc();

    // Find top donors
    List<UserWallet> findTop10ByOrderByTotalDonatedDesc();

    // Find top learners (by certifications)
    List<UserWallet> findTop10ByOrderByCertificationsCountDesc();

    // Find users by tier
    List<UserWallet> findByCurrentTier(UserWallet.TierLevel tier);

    // Find users with balance greater than amount
    @Query("SELECT w FROM UserWallet w WHERE w.balance >= :amount")
    List<UserWallet> findUsersWithBalanceGreaterThan(Double amount);

    // Get total platform statistics
    @Query("SELECT SUM(w.totalEarned) FROM UserWallet w")
    Double getTotalEarnedPlatform();

    @Query("SELECT SUM(w.totalDonated) FROM UserWallet w")
    Double getTotalDonatedPlatform();

    @Query("SELECT SUM(w.balance) FROM UserWallet w")
    Double getTotalBalancePlatform();

    @Query("SELECT COUNT(w) FROM UserWallet w WHERE w.totalDonated > 0")
    Long getActiveDonorsCount();
}
