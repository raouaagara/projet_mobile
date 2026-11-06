package org.example.referralmicroservice;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;

@SpringBootApplication
@EnableDiscoveryClient
public class ReferralMicroServiceApplication {
    public static void main(String[] args) {
        SpringApplication.run(ReferralMicroServiceApplication.class, args);
    }
}
