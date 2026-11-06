package org.example.paiementms.Controllers;

import org.example.paiementms.Entities.Wallet;
import org.example.paiementms.Entities.WalletType;
import org.example.paiementms.Services.payementService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.math.BigDecimal;

import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(PaymentController.class)
class PaymentControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private payementService paymentService;

    @Test
    void shouldReturnWalletDetails() throws Exception {
        Wallet wallet = new Wallet();
        wallet.setUserId(1L);
        wallet.setBalance(new BigDecimal("500.00"));

        when(paymentService.getWalletByUserId(1L)).thenReturn(wallet);

        mockMvc.perform(get("/api/payments/wallet/1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.balance").value(500.00));
    }
}