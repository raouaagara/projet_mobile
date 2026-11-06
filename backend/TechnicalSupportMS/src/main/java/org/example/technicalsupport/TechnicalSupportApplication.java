package org.example.technicalsupport;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class TechnicalSupportApplication {
    public static void main(String[] args) {
        SpringApplication.run(TechnicalSupportApplication.class, args);
    }
}
