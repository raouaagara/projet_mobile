package org.example.paiementms.Controllers;


import lombok.RequiredArgsConstructor;
import org.example.paiementms.DTO.EscrowDetailDTO;
import org.example.paiementms.DTO.EscrowRequest;
import org.example.paiementms.Entities.Escrow;
import org.example.paiementms.Entities.Transaction;
import org.example.paiementms.Entities.Wallet;
import org.example.paiementms.Services.payementService; // Fixed typo from your service name
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;


@RestController
@RequestMapping("/api/payments")
@RequiredArgsConstructor
public class PaymentController {

    private final payementService paymentService;

    @PostMapping("/escrow/lock")
    public ResponseEntity<Escrow> lockEscrow(@RequestBody EscrowRequest request) {
        Escrow escrow = paymentService.initiateEscrow(
                request.getContractId(),
                request.getClientId(),
                request.getFreelancerId(),
                request.getAmount()
        );
        return ResponseEntity.ok(escrow);
    }
    @PostMapping("/wallet/create/{userId}")
    public ResponseEntity<Wallet> createWallet(@PathVariable Long userId) {
        return ResponseEntity.ok(paymentService.createWallet(userId));
    }
    @PostMapping("/wallet/create/freelancer/{userId}")
    public ResponseEntity<Wallet> createWalletFreelancer(@PathVariable Long userId) {
        return ResponseEntity.ok(paymentService.createWalletFreelancer(userId));
    }

    @GetMapping("/wallet/{userId}")
    public ResponseEntity<Wallet> getWallet(@PathVariable Long userId) {
        return ResponseEntity.ok(paymentService.getWalletByUserId(userId));
    }

    @GetMapping("/escrow/client/{clientId}")
    public ResponseEntity<List<Escrow>> getClientEscrows(@PathVariable Long clientId) {
        return ResponseEntity.ok(paymentService.getEscrowsByClientId(clientId));
    }
    @GetMapping("/escrow/contract/{contractId}")
    public ResponseEntity<Escrow> getEscrowByContractId(@PathVariable Long contractId) {
        // We call a service method to find the escrow by contract ID
        Escrow escrow = paymentService.getEscrowByContractId(contractId);
        return ResponseEntity.ok(escrow);
    }

    @GetMapping("/transactions/{userId}")
    public ResponseEntity<List<Transaction>> getTransactions(@PathVariable Long userId) {
        return ResponseEntity.ok(paymentService.getTransactionsByUserId(userId));
    }

    @PostMapping("/topup")
    public ResponseEntity<Wallet> topUp(@RequestBody Map<String, Object> payload) {
        Long userId = Long.valueOf(payload.get("userId").toString());
        BigDecimal amount = new BigDecimal(payload.get("amount").toString());
        return ResponseEntity.ok(paymentService.topUpWallet(userId, amount));
    }

    // Get all Escrows for the Admin List
    @GetMapping("/admin/escrows")
    public ResponseEntity<List<EscrowDetailDTO>> getAllEscrows() {
        return ResponseEntity.ok(paymentService.getAllEscrowsWithDetails());
    }

    @PostMapping("/admin/release/{escrowId}")
    public ResponseEntity<Escrow> releaseFunds(@PathVariable Long escrowId) {
        return ResponseEntity.ok(paymentService.adminReleaseFullEscrow(escrowId));
    }

    @PostMapping("/admin/release-partial/{escrowId}")
    public ResponseEntity<Escrow> releasePartialFunds(
            @PathVariable Long escrowId,
            @RequestBody Map<String, BigDecimal> payload) {

        BigDecimal amountToRelease = payload.get("amount");
        return ResponseEntity.ok(paymentService.adminReleasePartialEscrow(escrowId, amountToRelease));
    }
    @PostMapping("/admin/refund/{escrowId}")
    public ResponseEntity<Escrow> refundFunds(@PathVariable Long escrowId) {
        return ResponseEntity.ok(paymentService.adminRefundToClient(escrowId));
    }

    /** Client approves the work: releases the escrow to the freelancer. Body: {"clientId": 2} */
    @PostMapping("/escrow/contract/{contractId}/release")
    public ResponseEntity<Escrow> releaseByClient(@PathVariable Long contractId,
                                                  @RequestBody Map<String, Object> payload) {
        Object clientId = payload.get("clientId");
        return ResponseEntity.ok(paymentService.releaseByClient(contractId,
                clientId == null ? null : Long.valueOf(clientId.toString())));
    }

    @GetMapping("/escrow/freelancer/{freelancerId}")
    public ResponseEntity<List<Escrow>> getFreelancerEscrows(@PathVariable Long freelancerId) {
        return ResponseEntity.ok(paymentService.getEscrowsByFreelancerId(freelancerId));
    }
}
