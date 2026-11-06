package tn.esprit.communitymicroservice;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;

@SpringBootApplication
@EnableDiscoveryClient
public class CommunityMicroServiceApplication {

    public static void main(String[] args) {
        SpringApplication.run(CommunityMicroServiceApplication.class, args);
    }

}
