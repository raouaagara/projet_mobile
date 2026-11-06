package org.example.paiementms.Entities;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "escrows")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Escrow {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Long getContractId() {
        return contractId;
    }

    public void setContractId(Long contractId) {
        this.contractId = contractId;
    }

    public Wallet getClientWallet() {
        return clientWallet;
    }

    public void setClientWallet(Wallet clientWallet) {
        this.clientWallet = clientWallet;
    }

    public Wallet getFreelancerWallet() {
        return freelancerWallet;
    }

    public void setFreelancerWallet(Wallet freelancerWallet) {
        this.freelancerWallet = freelancerWallet;
    }

    public Wallet getEscrowWallet() {
        return escrowWallet;
    }

    public void setEscrowWallet(Wallet escrowWallet) {
        this.escrowWallet = escrowWallet;
    }

    public BigDecimal getTotalAmount() {
        return totalAmount;
    }

    public void setTotalAmount(BigDecimal totalAmount) {
        this.totalAmount = totalAmount;
    }

    public BigDecimal getReleasedAmount() {
        return releasedAmount;
    }

    public void setReleasedAmount(BigDecimal releasedAmount) {
        this.releasedAmount = releasedAmount;
    }

    public EscrowStatus getStatus() {
        return status;
    }

    public void setStatus(EscrowStatus status) {
        this.status = status;
    }

    public LocalDateTime getLockedAt() {
        return lockedAt;
    }

    public void setLockedAt(LocalDateTime lockedAt) {
        this.lockedAt = lockedAt;
    }

    public LocalDateTime getReleasedAt() {
        return releasedAt;
    }

    public void setReleasedAt(LocalDateTime releasedAt) {
        this.releasedAt = releasedAt;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(LocalDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }

    // Contract ID from contract-service (no FK, microservice pattern)
    @Column(name = "contract_id", nullable = false, unique = true)
    private Long contractId;

    @ManyToOne
    @JoinColumn(name = "client_wallet_id", nullable = false)
    private Wallet clientWallet;

    @ManyToOne
    @JoinColumn(name = "freelancer_wallet_id", nullable = false)
    private Wallet freelancerWallet;

    @ManyToOne
    @JoinColumn(name = "escrow_wallet_id", nullable = false)
    private Wallet escrowWallet;   // system escrow wallet

    @Column(name = "total_amount", nullable = false, precision = 15, scale = 2)
    private BigDecimal totalAmount;

    @Column(name = "released_amount", nullable = false, precision = 15, scale = 2)
    @Builder.Default
    private BigDecimal releasedAmount = BigDecimal.ZERO;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false)
    @Builder.Default
    private EscrowStatus status = EscrowStatus.PENDING;

    @Column(name = "locked_at")
    private LocalDateTime lockedAt;

    @Column(name = "released_at")
    private LocalDateTime releasedAt;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    // Computed: how much is still locked
    public BigDecimal getRemainingAmount() {
        return totalAmount.subtract(releasedAmount);
    }

    public boolean isFullyReleased() {
        return releasedAmount.compareTo(totalAmount) >= 0;
    }
}
