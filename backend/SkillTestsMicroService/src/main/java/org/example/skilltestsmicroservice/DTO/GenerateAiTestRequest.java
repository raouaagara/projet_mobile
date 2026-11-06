package org.example.skilltestsmicroservice.DTO;

import lombok.Data;

@Data
public class GenerateAiTestRequest {
    private Long userId;
    private String category;
    private Boolean hasAiAccess = false;
    private String userName;  // optional, for admin display
}
