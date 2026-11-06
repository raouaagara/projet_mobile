package org.example.subscriptionmicroservice.Repositories;

import org.example.subscriptionmicroservice.Entities.PlanType;
import org.example.subscriptionmicroservice.Entities.SubscriptionPlan;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface SubscriptionPlanRepository extends JpaRepository<SubscriptionPlan, Long> {

    List<SubscriptionPlan> findByType(PlanType type);

    List<SubscriptionPlan> findByDuration(String duration);
}
