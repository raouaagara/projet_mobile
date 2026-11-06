package org.example.paiementms.Controllers;

import lombok.RequiredArgsConstructor;
import org.example.paiementms.Entities.Dispute;
import org.example.paiementms.Services.DisputeService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/disputes")
@RequiredArgsConstructor
public class DisputeController {

    private final DisputeService disputeService;

    @PostMapping("/raise")
    public ResponseEntity<Dispute> raiseDispute(@RequestBody Map<String, Object> payload) {
        Long contractId = Long.valueOf(payload.get("contractId").toString());
        Long raisedByUserId = Long.valueOf(payload.get("raisedByUserId").toString());
        String reason = (String) payload.get("reason");
        
        return ResponseEntity.ok(disputeService.raiseDispute(contractId, raisedByUserId, reason));
    }

    @GetMapping("/user/{userId}")
    public ResponseEntity<List<Dispute>> getUserDisputes(@PathVariable Long userId) {
        return ResponseEntity.ok(disputeService.getDisputesOfUser(userId));
    }

    @GetMapping("/all")
    public ResponseEntity<List<Dispute>> getAllDisputes() {
        return ResponseEntity.ok(disputeService.getAllDisputes());
    }

    @PostMapping("/{id}/resolve")
    public ResponseEntity<Dispute> resolveDispute(@PathVariable Long id, @RequestBody Map<String, String> payload) {
        String resolution = payload.get("resolution"); // "CLIENT" or "FREELANCER"
        return ResponseEntity.ok(disputeService.resolveDispute(id, resolution));
    }
}
