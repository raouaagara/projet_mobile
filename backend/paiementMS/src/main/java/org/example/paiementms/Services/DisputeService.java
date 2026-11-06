package org.example.paiementms.Services;

import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.example.paiementms.Entities.Dispute;
import org.example.paiementms.Entities.DisputeStatus;
import org.example.paiementms.Entities.Escrow;
import org.example.paiementms.Entities.EscrowStatus;
import org.example.paiementms.Repositories.DisputeRepository;
import org.example.paiementms.Repositories.EscrowRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class DisputeService {

    private final DisputeRepository disputeRepository;
    private final EscrowRepository escrowRepository;
    private final payementService paymentService;

    @Transactional
    public Dispute raiseDispute(Long contractId, Long raisedByUserId, String reason) {
        Escrow escrow = escrowRepository.findByContractId(contractId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND,
                        "No payment is locked for this contract yet, so there is nothing to dispute."));

        if (escrow.getStatus() == EscrowStatus.RELEASED || escrow.getStatus() == EscrowStatus.REFUNDED) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Cannot dispute a closed escrow.");
        }
        if (escrow.getStatus() == EscrowStatus.DISPUTED) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "A dispute is already open for this contract.");
        }
        if (raisedByUserId == null || (escrow.getClientWallet().getUserId() != raisedByUserId
                && escrow.getFreelancerWallet().getUserId() != raisedByUserId)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN,
                    "Only the client or the freelancer of this contract can open a dispute.");
        }

        Long againstUserId = (escrow.getClientWallet().getUserId() == raisedByUserId) 
                ? escrow.getFreelancerWallet().getUserId() 
                : escrow.getClientWallet().getUserId();

        Dispute dispute = Dispute.builder()
                .escrow(escrow)
                .contractId(contractId)
                .raisedByUserId(raisedByUserId)
                .againstUserId(againstUserId)
                .reason(reason)
                .status(DisputeStatus.OPEN)
                .build();

        escrow.setStatus(EscrowStatus.DISPUTED);
        escrowRepository.save(escrow);

        return disputeRepository.save(dispute);
    }

    /** Disputes a user opened or that were opened against them, newest first. */
    public List<Dispute> getDisputesOfUser(Long userId) {
        return disputeRepository.findByRaisedByUserIdOrAgainstUserIdOrderByCreatedAtDesc(userId, userId);
    }

    public List<Dispute> getAllDisputes() {
        return disputeRepository.findAll();
    }

    public Dispute getDisputeById(Long id) {
        return disputeRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Dispute not found"));
    }

    @Transactional
    public Dispute resolveDispute(Long disputeId, String resolution) {
        Dispute dispute = getDisputeById(disputeId);
        
        if (dispute.getStatus() != DisputeStatus.OPEN && dispute.getStatus() != DisputeStatus.IN_REVIEW) {
            throw new RuntimeException("Dispute is already resolved");
        }

        DisputeStatus resolvedStatus;

        if ("CLIENT".equalsIgnoreCase(resolution)) {
            paymentService.adminRefundToClient(dispute.getEscrow().getId());
            resolvedStatus = DisputeStatus.RESOLVED_CLIENT;
        } else if ("FREELANCER".equalsIgnoreCase(resolution)) {
            paymentService.adminReleaseFullEscrow(dispute.getEscrow().getId());
            resolvedStatus = DisputeStatus.RESOLVED_FREELANCER;
        } else {
            throw new RuntimeException("Invalid resolution type. Must be CLIENT or FREELANCER.");
        }

        LocalDateTime now = LocalDateTime.now();

        // Close the resolved dispute
        dispute.setStatus(resolvedStatus);
        dispute.setResolvedAt(now);
        disputeRepository.save(dispute);

        // Close ALL other open disputes for the same contract
        List<Dispute> siblingDisputes = disputeRepository.findByContractId(dispute.getContractId());
        for (Dispute sibling : siblingDisputes) {
            if (!sibling.getId().equals(dispute.getId())
                    && (sibling.getStatus() == DisputeStatus.OPEN || sibling.getStatus() == DisputeStatus.IN_REVIEW)) {
                sibling.setStatus(resolvedStatus);
                sibling.setResolvedAt(now);
                disputeRepository.save(sibling);
            }
        }

        return dispute;
    }
}
