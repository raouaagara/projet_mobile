package org.example.paiementms.Services;

import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.example.paiementms.Clients.ContractClient;
import org.example.paiementms.DTO.ContractDTO;
import org.example.paiementms.DTO.EscrowDetailDTO;
import org.example.paiementms.Entities.*;
        import org.example.paiementms.Repositories.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class payementService {

    private final WalletRepository walletRepository;
    private final EscrowRepository escrowRepository;
    private final TransactionRepository transactionRepository;

    private final ContractClient contractClient;

    @Transactional
    public Wallet createWallet(Long userId) {

        Optional<Wallet> existing = walletRepository.findByUserId(userId);
        if (existing.isPresent()) {
            return existing.get();
        }


        Wallet wallet = new Wallet();
        wallet.setUserId(userId);
        wallet.setBalance(BigDecimal.ZERO);
        wallet.setCurrency("USD");
        wallet.setWalletType(WalletType.CLIENT);
        wallet.setActive(true);


        Wallet savedWallet = walletRepository.saveAndFlush(wallet);


        System.out.println("🟢 SUCCESS: Wallet created for User " + userId + " with ID " + savedWallet.getId());

        return savedWallet;
    }

    @Transactional
    public Wallet createWalletFreelancer(Long userId) {
        Optional<Wallet> existing = walletRepository.findByUserId(userId);
        if (existing.isPresent()) {
            return existing.get();
        }

        Wallet wallet = new Wallet();
        wallet.setUserId(userId);
        wallet.setBalance(BigDecimal.ZERO);
        wallet.setCurrency("USD");
        wallet.setWalletType(WalletType.FREELANCER); // 🟢 Set to FREELANCER
        wallet.setActive(true);

        Wallet savedWallet = walletRepository.saveAndFlush(wallet);
        System.out.println("🟢 SUCCESS: Freelancer Wallet created for User " + userId + " with ID " + savedWallet.getId());
        return savedWallet;
    }
    @Transactional
    public Wallet topUpWallet(Long userId, BigDecimal amount) {
        Wallet wallet = walletRepository.findByUserId(userId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Wallet not found"));
        wallet.credit(amount);

        // Record transaction
        Transaction tx = Transaction.builder()
                .toWallet(wallet)
                .type(TransactionType.TOP_UP)
                .amount(amount)
                .description("Manual Top-up")
                .build();
        transactionRepository.save(tx);

        return walletRepository.save(wallet);
    }

    @Transactional
    public Escrow initiateEscrow(Long contractId, Long clientId, Long freelancerId, BigDecimal amount) {
        // --- LOG START ---
        System.out.println("=================================================");
        System.out.println("PAYMENT ATTEMPT: " + LocalDateTime.now());
        System.out.println("CONTRACT ID    : " + contractId);
        System.out.println("CLIENT ID      : " + clientId);
        System.out.println("FREELANCER ID  : " + freelancerId);
        System.out.println("AMOUNT TO LOCK : " + amount);
        System.out.println("=================================================");

        // 1. Get or AUTO-CREATE Client Wallet
        Wallet clientWallet = walletRepository.findByUserId(clientId)
                .orElseGet(() -> {
                    System.out.println("[LOG] Wallet NOT FOUND for Client " + clientId + ". Creating new wallet with $10,000.");
                    return walletRepository.save(Wallet.builder()
                            .userId(clientId)
                            .balance(new BigDecimal("10000.00"))
                            .currency("USD")
                            .walletType(WalletType.CLIENT)
                            .build());
                });
        System.out.println("[LOG] Client Wallet Found. Current Balance: " + clientWallet.getBalance());

        // 2. Get or AUTO-CREATE Freelancer Wallet
        Wallet freelancerWallet = walletRepository.findByUserId(freelancerId)
                .orElseGet(() -> {
                    System.out.println("[LOG] Wallet NOT FOUND for Freelancer " + freelancerId + ". Creating new empty wallet.");
                    return walletRepository.save(Wallet.builder()
                            .userId(freelancerId)
                            .balance(BigDecimal.ZERO)
                            .currency("USD")
                            .walletType(WalletType.FREELANCER)
                            .build());
                });

        // 3. Get or AUTO-CREATE System Escrow Wallet
        Wallet adminWallet = walletRepository.findByWalletType(WalletType.ESCROW)
                .orElseGet(() -> {
                    System.out.println("[LOG] System Escrow Wallet NOT FOUND. Creating primary Escrow account.");
                    return walletRepository.save(Wallet.builder()
                            .userId(0L)
                            .balance(BigDecimal.ZERO)
                            .currency("USD")
                            .walletType(WalletType.ESCROW)
                            .build());
                });

        // 4. Execution of the Balance Transfer
        try {
            System.out.println("[LOG] Attempting to debit Client Wallet...");
            clientWallet.debit(amount);

            System.out.println("[LOG] Attempting to credit Escrow Wallet...");
            adminWallet.credit(amount);

            System.out.println("[LOG] SUCCESS: Balance transferred to Escrow.");
        } catch (Exception e) {
            System.err.println("[ERROR] Transaction Failed: " + e.getMessage());
            throw e; // Re-throw to trigger @Transactional rollback
        }

        // 5. Create the Escrow record
        Escrow escrow = Escrow.builder()
                .contractId(contractId)
                .clientWallet(clientWallet)
                .freelancerWallet(freelancerWallet)
                .escrowWallet(adminWallet)
                .totalAmount(amount)
                .status(EscrowStatus.LOCKED)
                .lockedAt(LocalDateTime.now())
                .build();

        walletRepository.save(clientWallet);
        walletRepository.save(adminWallet);

        Escrow savedEscrow = escrowRepository.save(escrow);

        // Show the money leaving the client's wallet in their history
        transactionRepository.save(Transaction.builder()
                .fromWallet(clientWallet)
                .toWallet(adminWallet)
                .amount(amount)
                .type(TransactionType.ESCROW_LOCK)
                .description("Payment locked in escrow - Contract #" + contractId)
                .referenceId(contractId)
                .referenceType("CONTRACT")
                .build());
        System.out.println("[LOG] ESCROW RECORD CREATED. ID: " + savedEscrow.getId());
        System.out.println("=================================================");

        return savedEscrow;
    }

    @Transactional
    public void releaseTaskPayment(Long contractId, BigDecimal taskAmount) {
        Escrow escrow = escrowRepository.findByContractId(contractId)
                .orElseThrow(() -> new RuntimeException("Escrow not found"));

        if (escrow.getRemainingAmount().compareTo(taskAmount) < 0) {
            throw new RuntimeException("Insufficient funds in escrow");
        }

        Wallet adminWallet = escrow.getEscrowWallet();
        Wallet freelancerWallet = escrow.getFreelancerWallet();

        // Transfer from Escrow to Freelancer
        adminWallet.debit(taskAmount);
        freelancerWallet.credit(taskAmount);

        escrow.setReleasedAmount(escrow.getReleasedAmount().add(taskAmount));

        if (escrow.isFullyReleased()) {
            escrow.setStatus(EscrowStatus.RELEASED);
            escrow.setReleasedAt(LocalDateTime.now());
        }

        walletRepository.save(adminWallet);
        walletRepository.save(freelancerWallet);
        escrowRepository.save(escrow);
    }

    // Add this inside payementService.java

    public Escrow getEscrowByContractId(Long contractId) {
        return escrowRepository.findByContractId(contractId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND,
                        "No payment is locked for contract " + contractId));
    }

    public Wallet getWalletByUserId(Long userId) {
        return walletRepository.findByUserId(userId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Wallet not found"));
    }

    public List<Escrow> getEscrowsByClientId(Long clientId) {
        return escrowRepository.findByClientWalletUserId(clientId);
    }

    public List<Transaction> getTransactionsByUserId(Long userId) {
        Wallet wallet = getWalletByUserId(userId);
        return transactionRepository.findByToWalletOrFromWalletOrderByCreatedAtDesc(wallet, wallet);
    }

    /**
     * The client approves the delivered work: everything still in escrow goes to the freelancer,
     * then the contract and its project are closed (like an admin release, but checked for the client).
     */
    @Transactional
    public Escrow releaseByClient(Long contractId, Long clientId) {
        Escrow escrow = getEscrowByContractId(contractId);
        if (clientId == null || escrow.getClientWallet().getUserId() != clientId) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN,
                    "Only the client of this contract can release its payment.");
        }
        if (escrow.getStatus() == EscrowStatus.DISPUTED) {
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                    "This contract is in dispute: an admin will decide where the money goes.");
        }
        if (escrow.getStatus() == EscrowStatus.RELEASED || escrow.getStatus() == EscrowStatus.REFUNDED) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "This payment was already released.");
        }
        return releaseRemaining(escrow.getId(), "Payment released by the client - Contract #" + contractId);
    }

    @Transactional
    public Escrow adminReleaseFullEscrow(Long escrowId) {
        return releaseRemaining(escrowId, null);
    }

    /** Pays everything still in escrow to the freelancer and closes the contract. */
    private Escrow releaseRemaining(Long escrowId, String description) {
        Escrow escrow = escrowRepository.findById(escrowId)
                .orElseThrow(() -> new RuntimeException("Escrow Record not found"));

        if (escrow.getStatus() == EscrowStatus.RELEASED || escrow.getStatus() == EscrowStatus.REFUNDED) {
            throw new RuntimeException("Escrow is already closed with status: " + escrow.getStatus());
        }

        BigDecimal remainingAmount = escrow.getRemainingAmount();
        Wallet escrowWallet = escrow.getEscrowWallet();
        Wallet freelancerWallet = escrow.getFreelancerWallet();

        // 1. Physical Balance Transfer
        escrowWallet.debit(remainingAmount);
        freelancerWallet.credit(remainingAmount);

        // 2. Update Escrow Record
        escrow.setReleasedAmount(escrow.getTotalAmount());
        escrow.setStatus(EscrowStatus.RELEASED);
        escrow.setReleasedAt(LocalDateTime.now());

        // 3. Log the Transaction for the Freelancer's History
        Transaction tx = Transaction.builder()
                .fromWallet(escrowWallet)
                .toWallet(freelancerWallet)
                .amount(remainingAmount)
                .type(TransactionType.TASK_PAYOUT) // Matches your Enum
                .description(description != null ? description
                        : "Admin Final Release - Contract #" + escrow.getContractId())
                .referenceId(escrow.getContractId())
                .referenceType("CONTRACT_FINAL")
                .build();

        transactionRepository.save(tx);
        walletRepository.save(escrowWallet);
        walletRepository.save(freelancerWallet);
        escrowRepository.save(escrow);

        // Notify Contract microservice to close the contract
        try {
            contractClient.markAsCompleted(escrow.getContractId());
            System.out.println("[LOG] Contract #" + escrow.getContractId() + " closed after dispute release to freelancer.");
        } catch (Exception e) {
            System.err.println("[ERROR] Could not notify contract service: " + e.getMessage());
        }

        return escrow;
    }

    @Transactional
    public Escrow adminReleasePartialEscrow(Long escrowId, BigDecimal amountToRelease) {
        // 1. Fetch Escrow and validate
        Escrow escrow = escrowRepository.findById(escrowId)
                .orElseThrow(() -> new RuntimeException("Escrow Record not found for ID: " + escrowId));

        if (escrow.getStatus() == EscrowStatus.RELEASED || escrow.getStatus() == EscrowStatus.REFUNDED) {
            throw new RuntimeException("This escrow is already closed.");
        }

        // Ensure we don't release more than what is left
        if (amountToRelease.compareTo(escrow.getRemainingAmount()) > 0) {
            throw new RuntimeException("Cannot release $" + amountToRelease + ". Only $" + escrow.getRemainingAmount() + " remains.");
        }

        // 2. Identify Wallets
        Wallet escrowWallet = escrow.getEscrowWallet();
        Wallet freelancerWallet = escrow.getFreelancerWallet();

        // 3. Physical Money Transfer (In-Memory updates for @Transactional)
        escrowWallet.debit(amountToRelease);
        freelancerWallet.credit(amountToRelease);

        // 4. Update Escrow Progress
        escrow.setReleasedAmount(escrow.getReleasedAmount().add(amountToRelease));

        // 5. Log the Transaction (For History)
        Transaction tx = Transaction.builder()
                .fromWallet(escrowWallet)
                .toWallet(freelancerWallet)
                .amount(amountToRelease)
                .type(TransactionType.TASK_PAYOUT)
                .description("Partial Payment Released - Contract #" + escrow.getContractId())
                .referenceId(escrow.getContractId())
                .referenceType("CONTRACT_PARTIAL")
                .build();

        transactionRepository.save(tx);
        walletRepository.save(escrowWallet);
        walletRepository.save(freelancerWallet);

        // 6. CHECK COMPLETION: If no money is left in Escrow
        if (escrow.getRemainingAmount().compareTo(BigDecimal.ZERO) <= 0) {
            System.out.println("[LOG] Escrow fully paid. Closing Contract #" + escrow.getContractId());

            // Update Local Escrow Status
            escrow.setStatus(EscrowStatus.RELEASED);
            escrow.setReleasedAt(LocalDateTime.now());

            // Notify Project Microservice via Feign Client
            try {
                contractClient.markAsCompleted(escrow.getContractId());
                System.out.println("[LOG] Project Microservice notified: Contract and Project are now CLOSED.");
            } catch (Exception e) {
                // We log the error but don't stop the payment transaction
                System.err.println("[CRITICAL ERROR] Failed to notify Project MS: " + e.getMessage());
            }
        }

        // 7. Save and Return
        return escrowRepository.save(escrow);
    }
    @Transactional
    public Escrow adminRefundToClient(Long escrowId) {
        Escrow escrow = escrowRepository.findById(escrowId)
                .orElseThrow(() -> new RuntimeException("Escrow not found"));

        BigDecimal refundAmount = escrow.getRemainingAmount();
        Wallet escrowWallet = escrow.getEscrowWallet();
        Wallet clientWallet = escrow.getClientWallet();

        escrowWallet.debit(refundAmount);
        clientWallet.credit(refundAmount);

        escrow.setStatus(EscrowStatus.REFUNDED);
        escrow.setReleasedAt(LocalDateTime.now());

        Transaction tx = Transaction.builder()
                .fromWallet(escrowWallet)
                .toWallet(clientWallet)
                .amount(refundAmount)
                .type(TransactionType.REFUND)
                .description("Admin Refund - Dispute Resolution #" + escrow.getContractId())
                .build();

        transactionRepository.save(tx);
        walletRepository.save(escrowWallet);
        walletRepository.save(clientWallet);
        escrowRepository.save(escrow);

        // Notify Contract microservice to mark contract as CANCELLED/COMPLETED
        try {
            contractClient.markAsCompleted(escrow.getContractId());
            System.out.println("[LOG] Contract #" + escrow.getContractId() + " closed after dispute refund.");
        } catch (Exception e) {
            System.err.println("[ERROR] Could not notify contract service: " + e.getMessage());
        }

        return escrow;
    }
    public List<EscrowDetailDTO> getAllEscrowsWithDetails() {
        List<Escrow> escrows = escrowRepository.findAll();

        return escrows.stream().map(escrow -> {
            // Fetch real data from Contract microservice
            ContractDTO contractInfo = null;
            try {
                contractInfo = contractClient.getContractById(escrow.getContractId());
            } catch (Exception e) {
                System.err.println("Feign Error: " + e.getMessage());
            }

            return EscrowDetailDTO.builder()
                    .id(escrow.getId())
                    .contractId(escrow.getContractId())
                    .totalAmount(escrow.getTotalAmount())
                    .releasedAmount(escrow.getReleasedAmount())
                    .remainingAmount(escrow.getRemainingAmount())
                    .status(escrow.getStatus())
                    .lockedAt(escrow.getLockedAt())

                    // Mapping from your Contract Entity
                    .clientName(contractInfo != null ? contractInfo.getClientName() : "N/A")
                    .freelancerName(contractInfo != null ? contractInfo.getFreelancerName() : "N/A")
                    .contractStartDate(contractInfo != null && contractInfo.getStartDate() != null ?
                            contractInfo.getStartDate().toString() : "No Date")
                    .contractEndDate(contractInfo != null && contractInfo.getDeadline() != null ?
                            contractInfo.getDeadline().toString() : "No Deadline")

                    .clientId(escrow.getClientWallet().getUserId())
                    .freelancerId(escrow.getFreelancerWallet().getUserId())
                    .build();
        }).toList();
    }


    public List<Escrow> getEscrowsByFreelancerId(Long freelancerId) {
        return escrowRepository.findByFreelancerWalletUserId(freelancerId);
    }
}