package org.example.projectmicroservice.Controllers;

import org.example.projectmicroservice.Services.ContractAiService;
import org.example.projectmicroservice.Services.ContractAiService.DisputeRequest;
import org.example.projectmicroservice.Services.ContractAiService.Explanation;
import org.example.projectmicroservice.Services.ContractAiService.TermsRequest;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/** IA du module 3 : clauses du contrat, explication avant signature, litige clair. */
@RestController
@RequestMapping("/Contract/ai")
public class ContractAiController {

    public record RoleRequest(String role) {}

    private final ContractAiService ai;

    public ContractAiController(ContractAiService ai) {
        this.ai = ai;
    }

    @PostMapping("/terms")
    public Map<String, String> terms(@RequestBody TermsRequest request) {
        return Map.of("terms", ai.draftTerms(request));
    }

    @PostMapping("/{contractId}/explain")
    public Explanation explain(@PathVariable Long contractId, @RequestBody(required = false) RoleRequest request) {
        return ai.explain(contractId, request == null ? null : request.role());
    }

    @PostMapping("/dispute-draft")
    public Map<String, String> disputeDraft(@RequestBody DisputeRequest request) {
        return Map.of("text", ai.draftDispute(request));
    }
}
