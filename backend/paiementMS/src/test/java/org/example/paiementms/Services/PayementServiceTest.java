package org.example.paiementms.Services;

import org.example.paiementms.Entities.*;
import org.example.paiementms.Repositories.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class PayementServiceTest {

    @Mock private WalletRepository walletRepository;
    @Mock private EscrowRepository escrowRepository;
    @Mock private TransactionRepository transactionRepository;

    @InjectMocks
    private payementService paymentService;

    private Wallet clientWallet;
    private Wallet adminWallet;

    @BeforeEach
    void setUp() {
        clientWallet = Wallet.builder()
                .userId(1L).balance(new BigDecimal("1000.00"))
                .walletType(WalletType.CLIENT).build();

        adminWallet = Wallet.builder()
                .userId(0L).balance(BigDecimal.ZERO)
                .walletType(WalletType.ESCROW).build();
    }

    @Test
    void shouldInitiateEscrowSuccessfully() {
        // Arrange
        BigDecimal amountToLock = new BigDecimal("200.00");
        when(walletRepository.findByUserId(1L)).thenReturn(Optional.of(clientWallet));
        when(walletRepository.findByUserId(2L)).thenReturn(Optional.of(new Wallet()));
        when(walletRepository.findByWalletType(WalletType.ESCROW)).thenReturn(Optional.of(adminWallet));
        when(escrowRepository.save(any(Escrow.class))).thenAnswer(i -> i.getArguments()[0]);

        // Act
        Escrow result = paymentService.initiateEscrow(100L, 1L, 2L, amountToLock);

        // Assert
        assertEquals(EscrowStatus.LOCKED, result.getStatus());
        assertEquals(new BigDecimal("800.00"), clientWallet.getBalance()); // 1000 - 200
        assertEquals(new BigDecimal("200.00"), adminWallet.getBalance()); // 0 + 200
        verify(escrowRepository, times(1)).save(any(Escrow.class));
    }

    @Test
    void shouldThrowExceptionWhenBalanceInsufficient() {
        // Arrange
        BigDecimal expensiveAmount = new BigDecimal("5000.00");
        when(walletRepository.findByUserId(1L)).thenReturn(Optional.of(clientWallet));
        when(walletRepository.findByUserId(2L)).thenReturn(Optional.of(new Wallet()));
        when(walletRepository.findByWalletType(WalletType.ESCROW)).thenReturn(Optional.of(adminWallet));

        // Act & Assert
        assertThrows(RuntimeException.class, () -> {
            paymentService.initiateEscrow(100L, 1L, 2L, expensiveAmount);
        });
    }
}