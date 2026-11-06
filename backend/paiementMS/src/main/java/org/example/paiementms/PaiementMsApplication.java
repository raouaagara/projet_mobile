package org.example.paiementms;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.openfeign.EnableFeignClients;

@SpringBootApplication
@EnableFeignClients
public class PaiementMsApplication {

    public static void main(String[] args) {
        SpringApplication.run(PaiementMsApplication.class, args);
    }

}
