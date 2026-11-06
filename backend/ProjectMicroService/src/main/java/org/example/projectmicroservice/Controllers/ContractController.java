package org.example.projectmicroservice.Controllers;

import org.example.projectmicroservice.Entities.Contract;
import org.example.projectmicroservice.Entities.Notification;
import org.example.projectmicroservice.Repositories.NotificationRepository;
import org.example.projectmicroservice.Services.ContractImpl;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/Contract")
public class ContractController {

    @Autowired
    private ContractImpl contractService;

    @Autowired
    private NotificationRepository notificationRepository;

    @PostMapping("/generate-from-proposal/{proposalId}")
    public ResponseEntity<?> generateContract(
            @PathVariable Long proposalId,
            @RequestBody Map<String, Object> requestData
    ) {
        try {
            String terms = (String) requestData.get("terms");
            String clientName = (String) requestData.get("clientName");
            String clientSignature = (String) requestData.get("clientSignature");
            Long clientId = Long.valueOf(requestData.get("clientId").toString());
            LocalDate startDate = LocalDate.parse((String) requestData.get("startDate"));

            Contract newContract = contractService.generateContractFromProposal(
                    proposalId, terms, clientId, clientName, startDate, clientSignature
            );

            // 🟢 NOTIFICATION AU FREELANCER : Un contrat l'attend !
            if (newContract.getFreelancerId() != null) {
                Notification notif = new Notification();
                notif.setRecipientId(newContract.getFreelancerId()); // Le freelancer
                notif.setProjectId(newContract.getProjectId());
                notif.setMessage("📄 You have a new contract offer from " + clientName + ". Please review and sign it!");
                notificationRepository.save(notif);
            }

            return ResponseEntity.ok(newContract);

        } catch (ResponseStatusException e) {
            throw e;
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.internalServerError().body("Error: " + e.getMessage());
        }
    }

    /** The contract made from a proposal, or 404 if none yet. */
    @GetMapping("/proposal/{proposalId}")
    public ResponseEntity<Contract> getContractByProposal(@PathVariable Long proposalId) {
        return contractService.getContractByProposal(proposalId)
                .map(ResponseEntity::ok)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND,
                        "No contract for this proposal yet"));
    }

    @GetMapping("/client/{clientId}")
    public ResponseEntity<List<Contract>> getClientContracts(@PathVariable Long clientId) {
        List<Contract> contracts = contractService.getContractsByClient(clientId);
        return ResponseEntity.ok(contracts);
    }

    @PostMapping("/create")
    public ResponseEntity<Contract> createContract(@RequestBody Contract contract) {
        Contract newContract = contractService.createContract(contract);
        return new ResponseEntity<>(newContract, HttpStatus.CREATED);
    }

    @GetMapping("/{id}")
    public ResponseEntity<Contract> getContractById(@PathVariable Long id) {
        Contract contract = contractService.getContractById(id);
        return new ResponseEntity<>(contract, HttpStatus.OK);
    }

    @GetMapping("/all")
    public ResponseEntity<List<Contract>> getAllContracts() {
        List<Contract> contracts = contractService.getAllContracts();
        return new ResponseEntity<>(contracts, HttpStatus.OK);
    }

    @GetMapping("/freelancer/{freelancerId}")
    public ResponseEntity<List<Contract>> getFreelancerContracts(@PathVariable Long freelancerId) {
        return ResponseEntity.ok(contractService.getContractsByFreelancer(freelancerId));
    }

    @PutMapping("/{contractId}/sign")
    public ResponseEntity<Contract> signContract(
            @PathVariable Long contractId,
            @RequestBody Map<String, String> payload
    ) {
        // Extract both values from the JSON body
        String signature = payload.get("signature");
        String freelancerName = payload.get("freelancerName");

        // Pass freelancerName to the service
        Contract signedContract = contractService.freelancerSignContract(contractId, signature, freelancerName);

        // Notification Logic
        if (signedContract.getClientId() != null) {
            Notification notif = new Notification();
            notif.setRecipientId(signedContract.getClientId());
            notif.setProjectId(signedContract.getProjectId());
            notif.setMessage("✅ Great news! " + signedContract.getFreelancerName() + " has signed the contract. The project is now ACTIVE!");
            notificationRepository.save(notif);
        }

        return ResponseEntity.ok(signedContract);
    }

    @PutMapping("/{contractId}/reject")
    public ResponseEntity<Contract> rejectContract(@PathVariable Long contractId) {
        Contract rejectedContract = contractService.freelancerRejectContract(contractId);

        if (rejectedContract.getClientId() != null) {
            Notification notif = new Notification();
            notif.setRecipientId(rejectedContract.getClientId()); // Le client
            notif.setProjectId(rejectedContract.getProjectId());
            notif.setMessage("❌ The freelancer has declined your contract offer.");
            notificationRepository.save(notif);
        }

        return ResponseEntity.ok(rejectedContract);
    }

    @PutMapping("/{contractId}/complete")
    public ResponseEntity<?> completeContract(@PathVariable Long contractId) {
        contractService.completeContractAndProject(contractId);
        return ResponseEntity.ok().build();
    }
}