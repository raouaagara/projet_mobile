package org.example.projectmicroservice.OpenFeign;

import org.example.projectmicroservice.OpenFeign.FeignConfig;
import org.example.projectmicroservice.DTO.EscrowRequest;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;

@FeignClient(name = "paiement-ms", url = "http://localhost:8088", configuration = FeignConfig.class)
public interface PaymentClient {

    @PostMapping(value = "/api/payments/escrow/lock", consumes = MediaType.APPLICATION_JSON_VALUE)
    void lockEscrow(@RequestBody EscrowRequest payload);


}