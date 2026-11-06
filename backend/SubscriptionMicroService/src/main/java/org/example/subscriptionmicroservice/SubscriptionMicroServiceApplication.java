package org.example.subscriptionmicroservice;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;

@SpringBootApplication
@EnableDiscoveryClient
public class SubscriptionMicroServiceApplication {

    public static void main(String[] args) {
        SpringApplication.run(SubscriptionMicroServiceApplication.class, args);
    }
}
