package org.example.projectmicroservice.Services;

import feign.FeignException;
import jakarta.transaction.Transactional;
import org.example.projectmicroservice.Entities.*;
import org.example.projectmicroservice.OpenFeign.PaymentClient;
import org.example.projectmicroservice.Repositories.ContactRepository;
import org.example.projectmicroservice.Repositories.ProjectRepository;
import org.example.projectmicroservice.Repositories.ProposalRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;
import java.math.BigDecimal;


import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import org.example.projectmicroservice.DTO.EscrowRequest;

@Service
public class ContractImpl implements ContractService{
    @Autowired
    private ContactRepository contractRepository;
    @Autowired
    private ProjectRepository projectRepository;

    @Autowired
    private ProposalRepository proposalRepository;

    public Contract generateContractFromProposal(Long proposalId, String terms, Long clientId, String clientName, LocalDate startDate ,String clientSignature) {

        System.out.println(">>> Génération du contrat pour Proposal ID: " + proposalId);

        Proposal proposal = proposalRepository.findById(proposalId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Proposal not found"));
        if (proposal.getStatus() != StatusProposal.ACCEPTED) {
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                    "Accept this proposal before creating its contract.");
        }
        if (contractRepository.findByProposalId(proposalId).isPresent()) {
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                    "A contract was already created for this proposal.");
        }

        Contract contract = new Contract();

        contract.setProposal(proposal);
        contract.setFreelancerId(proposal.getFreelancerId());
        contract.setRate(proposal.getBidAmount());
        contract.setDeadline(proposal.getEstimationEndDate());

        if (proposal.getProject() != null) {
            contract.setProjectId(proposal.getProject().getId());
            contract.setProjectTitle(proposal.getProject().getTitle());
        } else {
            contract.setProjectId(0L);
            contract.setProjectTitle("Projet Inconnu");
        }

        contract.setClientId(clientId);
        contract.setClientName(clientName);
        contract.setTerms(terms);
        contract.setStartDate(startDate);
        contract.setStatus(ContractStatut.SENT);
        contract.setClientSignature(clientSignature);

        return contractRepository.save(contract);
    }

    @Override
    public List<Contract> getContractsByClient(Long clientId) {
        return contractRepository.findByClientId(clientId);
    }

    @Override
    public Contract createContract(Contract contract) {
        return contractRepository.save(contract);
    }

    @Override
    public Contract getContractById(Long id) {
        return contractRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Contract not found"));
    }

    public Optional<Contract> getContractByProposal(Long proposalId) {
        return contractRepository.findByProposalId(proposalId);
    }

    @Override
    public List<Contract> getAllContracts() {
        return contractRepository.findAll();
    }

    @Override
    public List<Contract> getContractsByFreelancer(Long freelancerId) {
        return contractRepository.findByFreelancerId(freelancerId);
    }

    @Transactional
    public void completeContractAndProject(Long contractId) {
        Contract contract = contractRepository.findById(contractId)
                .orElseThrow(() -> new RuntimeException("Contract not found"));

        // 1. Update Contract Status
        contract.setStatus(ContractStatut.COMPLETED);
        contractRepository.save(contract);

        // 2. Update Project Status
        Project project = projectRepository.findById(contract.getProjectId())
                .orElseThrow(() -> new RuntimeException("Project not found"));
        project.setStatus(Status.CLOSED);
        projectRepository.save(project);
    }

    @Autowired
    private PaymentClient paymentClient;

    @Transactional
    @Override
    public Contract freelancerSignContract(Long contractId, String signature, String freelancerName) {
        System.out.println("[PROJECT-MS] PROCESSING SIGNATURE FOR CONTRACT: " + contractId);

        // 1. Fetch the existing contract
        Contract contract = getContractById(contractId);

        // 2. Security/Status Check
        if (contract.getStatus() != ContractStatut.SENT) {
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                    "This contract can't be signed anymore (status: " + contract.getStatus() + ").");
        }

        // 3. Update the fields
        contract.setFreelancerSignature(signature);
        contract.setFreelancerName(freelancerName); // <-- THE FIX: Saving the name to DB
        contract.setStatus(ContractStatut.ACTIVE);

        // Save early to ensure IDs are ready for the payment call
        Contract savedContract = contractRepository.save(contract);

        // 4. Trigger the Payment/Escrow Microservice
        try {
            EscrowRequest paymentData = new EscrowRequest(
                    savedContract.getId(),
                    savedContract.getClientId(),
                    savedContract.getFreelancerId(),
                    new BigDecimal(savedContract.getRate().toString())
            );

            System.out.println("[PROJECT-MS] LOCKING ESCROW FOR CLIENT: " + savedContract.getClientId());
            paymentClient.lockEscrow(paymentData);

        } catch (Exception e) {
            System.err.println("[PROJECT-MS] PAIEMENT-MS CONNECTION ERROR: " + e.getMessage());
            // We throw an exception here so @Transactional rolls back the signature if payment fails
            String body = e instanceof FeignException fe ? fe.contentUTF8() : "";
            if (body != null && body.contains("Insufficient funds")) {
                throw new ResponseStatusException(HttpStatus.CONFLICT,
                        "The client's wallet doesn't have enough money to fund this contract. "
                                + "Ask the client to top up their wallet, then sign again.");
            }
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE,
                    "The payment could not be locked in escrow, so the contract was not signed. Try again later.");
        }

        return savedContract;
    }


    @Override
    public Contract freelancerRejectContract(Long contractId) {
        Contract contract = getContractById(contractId);
        if (contract.getStatus() != ContractStatut.SENT) {
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                    "This contract can't be declined anymore (status: " + contract.getStatus() + ").");
        }

        contract.setStatus(ContractStatut.REJECTED);
        return contractRepository.save(contract);
    }
}
