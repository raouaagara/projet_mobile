package org.example.projectmicroservice.Services;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.example.projectmicroservice.Entities.Contract;
import org.example.projectmicroservice.Entities.JobType;
import org.example.projectmicroservice.Entities.Project;
import org.example.projectmicroservice.Entities.Proposal;
import org.example.projectmicroservice.Repositories.ContactRepository;
import org.example.projectmicroservice.Repositories.ProposalRepository;
import org.example.projectmicroservice.Services.ContractAiService.*;
import org.example.projectmicroservice.ai.AiUnavailableException;
import org.example.projectmicroservice.ai.GeminiClient;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDate;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class ContractAiServiceTest {

    @Mock
    private ProposalRepository proposalRepo;
    @Mock
    private ContactRepository contractRepo;
    @Mock
    private GeminiClient gemini;

    @InjectMocks
    private ContractAiService ai;

    @BeforeEach
    void setUp() {
        Project project = Project.builder().id(1L).title("Restaurant app").description("Flutter ordering app")
                .jobType(JobType.FIXED_PRICE).build();
        Proposal proposal = new Proposal();
        proposal.setId(5L);
        proposal.setBidAmount(1200.0);
        proposal.setEstimationEndDate(LocalDate.of(2026, 12, 1));
        proposal.setCoverLetter("I will build the menu, cart and payment.");
        proposal.setProject(project);
        when(proposalRepo.findById(5L)).thenReturn(Optional.of(proposal));

        Contract contract = new Contract();
        contract.setId(9L);
        contract.setProjectTitle("Restaurant app");
        contract.setRate(1200.0);
        contract.setStartDate(LocalDate.of(2026, 11, 1));
        contract.setDeadline(LocalDate.of(2026, 12, 1));
        contract.setTerms("1 Scope: the app.");
        when(contractRepo.findById(9L)).thenReturn(Optional.of(contract));
    }

    private String prompt() {
        ArgumentCaptor<String> prompt = ArgumentCaptor.forClass(String.class);
        verify(gemini).generate(prompt.capture());
        return prompt.getValue();
    }

    @Test
    void termsUseTheProposalAndWorkifyEscrowAndLoseMarkdown() {
        when(gemini.generate(anyString())).thenReturn("**1 Scope**\n# The app.");

        String terms = ai.draftTerms(new TermsRequest(5L, LocalDate.of(2026, 11, 1), "Weekly demo on Friday"));

        assertEquals("1 Scope\nThe app.", terms);
        String p = prompt();
        assertTrue(p.contains("Restaurant app") && p.contains("$1200 for the whole job") && p.contains("2026-12-01"));
        assertTrue(p.contains("I will build the menu") && p.contains("Weekly demo on Friday"));
        assertTrue(p.contains("locked in escrow") && p.contains("Never invent"));
    }

    @Test
    void unknownProposalIs404() {
        when(proposalRepo.findById(77L)).thenReturn(Optional.empty());
        assertThrows(ResponseStatusException.class, () -> ai.draftTerms(new TermsRequest(77L, null, null)));
        verifyNoInteractions(gemini);
    }

    @Test
    void explanationKeepsAtMostFiveAndFourPoints() throws Exception {
        when(gemini.generateJson(anyString())).thenReturn(new ObjectMapper().readTree("""
                {"summary": ["a", "b", "c", "d", "e", "f"], "check": ["x", "", "y", "z", "w", "v"]}"""));

        Explanation e = ai.explain(9L, "FREELANCER");

        assertEquals(5, e.summary().size());
        assertEquals(java.util.List.of("x", "y", "z", "w"), e.check());
    }

    @Test
    void emptyExplanationGivesAClearMessage() throws Exception {
        when(gemini.generateJson(anyString())).thenReturn(new ObjectMapper().readTree("{\"summary\": []}"));
        assertThrows(AiUnavailableException.class, () -> ai.explain(9L, "CLIENT"));
    }

    @Test
    void disputeUsesTheContractFactsAndNeedsAFewWords() {
        when(gemini.generate(anyString())).thenReturn("The app was due on December 1 and was not delivered.");

        String text = ai.draftDispute(new DisputeRequest(9L, "CLIENT", "he never sent anything!!"));

        assertEquals("The app was due on December 1 and was not delivered.", text);
        String p = prompt();
        assertTrue(p.contains("client") && p.contains("deadline 2026-12-01") && p.contains("he never sent anything!!"));
        assertThrows(ResponseStatusException.class, () -> ai.draftDispute(new DisputeRequest(9L, "CLIENT", "bad")));
    }
}
