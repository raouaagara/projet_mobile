package org.example.subscriptionmicroservice.Repositories;

import org.example.subscriptionmicroservice.Entities.Payment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface PaymentRepository extends JpaRepository<Payment, Long> {

    List<Payment> findByUserSubscription_Id(Long userSubscriptionId);

    boolean existsByTransactionRef(String transactionRef);
}
