package org.example.paiementms.DTO;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.example.paiementms.Entities.EscrowStatus;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class EscrowDetailDTO {
    private Long id;
    private Long contractId;
    private BigDecimal totalAmount;
    private BigDecimal releasedAmount;
    private BigDecimal remainingAmount;
    private EscrowStatus status;
    private LocalDateTime lockedAt;

    // --- ADD THESE FIELDS ---
    private String clientName;
    private String freelancerName;
    private Long clientId;
    private Long freelancerId;
    private String contractStartDate;
    private String contractEndDate;
}