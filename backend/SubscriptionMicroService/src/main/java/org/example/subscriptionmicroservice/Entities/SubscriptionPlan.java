package org.example.subscriptionmicroservice.Entities;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "subscription_plans")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class SubscriptionPlan {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String name;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private PlanType type;

    @Column(nullable = false)
    private Double price;

    @Column(nullable = false)
    private String duration; // monthly, yearly

    @Column(length = 1000)
    private String description;

    @Column(length = 2000)
    private String benefits; // JSON or comma-separated list

    private Boolean hasAiCvAccess = false;

    private Integer aiCvLimit; // null = unlimited

    @OneToMany(mappedBy = "plan", cascade = CascadeType.REMOVE)
    @com.fasterxml.jackson.annotation.JsonIgnore
    private java.util.List<UserSubscription> userSubscriptions = new java.util.ArrayList<>();
}
