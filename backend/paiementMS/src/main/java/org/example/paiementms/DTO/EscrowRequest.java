package org.example.paiementms.DTO;

import java.math.BigDecimal;

public class EscrowRequest {
    private Long contractId;
    private Long clientId;
    private Long freelancerId;
    private BigDecimal amount;

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
