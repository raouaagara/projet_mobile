package org.example.paiementms.DTO;

import lombok.Data;
import java.time.LocalDate;

@Data
public class ContractDTO {
    private Long id;
    private String projectTitle;
    private String clientName;
    private String freelancerName;
    private LocalDate startDate;
    private LocalDate deadline;
    private Double rate;
}