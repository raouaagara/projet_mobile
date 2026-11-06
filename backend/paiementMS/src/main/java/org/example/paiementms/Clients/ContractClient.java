package org.example.paiementms.Clients;
import org.example.paiementms.DTO.ContractDTO;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;

@FeignClient(name = "contract-service", url = "http://localhost:8082")
public interface ContractClient {

    @GetMapping("/Contract/{id}")
    ContractDTO getContractById(@PathVariable("id") Long id);

    @PutMapping("/Contract/{contractId}/complete")
    void markAsCompleted(@PathVariable("contractId") Long contractId);
}