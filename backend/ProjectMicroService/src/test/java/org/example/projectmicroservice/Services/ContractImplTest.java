package org.example.projectmicroservice.Services;

import org.example.projectmicroservice.Entities.*;
import org.example.projectmicroservice.OpenFeign.PaymentClient;
import org.example.projectmicroservice.Repositories.ContactRepository;
import org.example.projectmicroservice.DTO.EscrowRequest;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class ContractImplTest {

    @Mock
    private ContactRepository contractRepository;

    @Mock
    private PaymentClient paymentClient; // Mocking the Feign Client

    @InjectMocks
    private ContractImpl contractService;

    private Contract testContract;

    @BeforeEach
    void setUp() {
        testContract = new Contract();
        testContract.setId(1L);
        testContract.setStatus(ContractStatut.SENT);
        testContract.setRate(500.0);
        testContract.setClientId(10L);
        testContract.setFreelancerId(20L);
    }

    @Test
    void shouldSuccessfullySignContractAndCallPayment() {
        // Arrange
        when(contractRepository.findById(1L)).thenReturn(Optional.of(testContract));
        when(contractRepository.save(any(Contract.class))).thenReturn(testContract);

        // Act
        Contract result = contractService.freelancerSignContract(1L, "SIG-123", "John Freelancer");

        // Assert
        assertEquals(ContractStatut.ACTIVE, result.getStatus());
        assertEquals("John Freelancer", result.getFreelancerName());

        // Verify that the payment microservice was notified
        verify(paymentClient, times(1)).lockEscrow(any(EscrowRequest.class));
        verify(contractRepository, times(1)).save(any(Contract.class));
    }

    @Test
    void shouldThrowExceptionIfContractNotSent() {
        testContract.setStatus(ContractStatut.ACTIVE);
        when(contractRepository.findById(1L)).thenReturn(Optional.of(testContract));

        assertThrows(RuntimeException.class, () -> {
            contractService.freelancerSignContract(1L, "SIG", "Name");
        });
    }
}