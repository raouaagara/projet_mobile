package org.example.subscriptionmicroservice.Repositories;

import org.example.subscriptionmicroservice.Entities.SubscriptionStatus;
import org.example.subscriptionmicroservice.Entities.UserSubscription;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface UserSubscriptionRepository extends JpaRepository<UserSubscription, Long> {

    List<UserSubscription> findByUserId(Long userId);

    Optional<UserSubscription> findByUserIdAndStatus(Long userId, SubscriptionStatus status);

    List<UserSubscription> findByUserIdAndStatusOrderByEndDateDesc(Long userId, SubscriptionStatus status);

    List<UserSubscription> findByStatus(SubscriptionStatus status);
}
