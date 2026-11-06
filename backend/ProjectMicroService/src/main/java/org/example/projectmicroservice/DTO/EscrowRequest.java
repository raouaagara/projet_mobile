package org.example.projectmicroservice.DTO;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
@Data
@NoArgsConstructor


public class EscrowRequest {
    private Long contractId;
    private Long clientId;
    private Long freelancerId;
    private BigDecimal amount;

    public EscrowRequest(Long contractId, Long clientId, Long freelancerId, BigDecimal amount) {
        this.contractId = contractId;
        this.clientId = clientId;
        this.freelancerId = freelancerId;
        this.amount = amount;
    }

    // Getters & Setters
    public Long getContractId() { return contractId; }
    public void setContractId(Long contractId) { this.contractId = contractId; }

    public Long getClientId() { return clientId; }
    public void setClientId(Long clientId) { this.clientId = clientId; }

    public Long getFreelancerId() { return freelancerId; }
    public void setFreelancerId(Long freelancerId) { this.freelancerId = freelancerId; }

    public BigDecimal getAmount() { return amount; }
    public void setAmount(BigDecimal amount) { this.amount = amount; }
}
