package org.example.projectmicroservice.Services;

import com.fasterxml.jackson.databind.JsonNode;
import org.example.projectmicroservice.Entities.Contract;
import org.example.projectmicroservice.Entities.JobType;
import org.example.projectmicroservice.Entities.Project;
import org.example.projectmicroservice.Entities.Proposal;
import org.example.projectmicroservice.Repositories.ContactRepository;
import org.example.projectmicroservice.Repositories.ProposalRepository;
import org.example.projectmicroservice.ai.AiUnavailableException;
import org.example.projectmicroservice.ai.GeminiClient;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

/**
 * L'IA du module 3 (Gemini) :
 * - rédiger les clauses d'un contrat à partir de la proposition acceptée ;
 * - expliquer un contrat en mots simples avant de le signer ;
 * - aider à écrire un litige clair et factuel.
 */
@Service
public class ContractAiService {

    public record TermsRequest(Long proposalId, LocalDate startDate, String notes) {}

    public record Explanation(List<String> summary, List<String> check) {}

    public record DisputeRequest(Long contractId, String role, String text) {}

    private static final int MAX_TEXT = 3000;
    static final int MAX_DISPUTE = 1000;

    /** How payment works on Workify, so the AI never describes it differently. */
    private static final String HOW_WORKIFY_PAYS = """
            How payment works on Workify (always describe it this way): when the freelancer signs, the agreed amount
            is taken from the client's wallet and locked in escrow; it is paid to the freelancer when the client
            approves the delivered work. If something goes wrong, either side can open a dispute in the app: the money
            stays in escrow and a Workify admin reviews the case and pays the freelancer, refunds the client, or splits it.""";

    private final ProposalRepository proposalRepo;
    private final ContactRepository contractRepo;
    private final GeminiClient gemini;

    public ContractAiService(ProposalRepository proposalRepo, ContactRepository contractRepo, GeminiClient gemini) {
        this.proposalRepo = proposalRepo;
        this.contractRepo = contractRepo;
        this.gemini = gemini;
    }

    /** Terms for the contract made from an accepted proposal (the client edits them before signing). */
    public String draftTerms(TermsRequest req) {
        if (req.proposalId() == null) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "proposalId is required");
        Proposal proposal = proposalRepo.findById(req.proposalId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Proposal not found"));
        Project project = proposal.getProject();
        boolean hourly = project != null && project.getJobType() == JobType.HOURLY;
        String prompt = """
                You write the terms of a freelance contract on Workify, a freelance marketplace, in the language the
                job is written in. Plain text, numbered sections with a short title each, at most 320 words:
                1 Scope and deliverables, 2 Timeline, 3 Payment, 4 Changes and revisions, 5 Communication,
                6 Ownership of the work, 7 Confidentiality, 8 Problems and disputes.

                Rules:
                - Use ONLY the facts below. Where a detail isn't given (number of revisions, meetings, file formats),
                  write a neutral sentence saying it is agreed in the Workify chat. Never invent numbers, dates,
                  penalties, laws or company names.
                - Scope: describe the deliverables from the job and the freelancer's letter, concretely.
                - Ownership: the client owns the delivered work once it is paid.
                - No title, no signatures block, no markdown symbols (no #, *, **).

                %s

                JOB
                Title: %s
                Description: %s

                ACCEPTED PROPOSAL
                Price: %s
                Start date: %s
                Delivery date: %s
                Freelancer's letter: %s

                Notes from the client (include them): %s
                """.formatted(HOW_WORKIFY_PAYS,
                text(project == null ? null : project.getTitle()),
                cut(project == null ? null : project.getDescription()),
                money(proposal.getBidAmount()) + (hourly ? " per hour" : " for the whole job"),
                req.startDate() == null ? "not given" : req.startDate().toString(),
                proposal.getEstimationEndDate() == null ? "not given" : proposal.getEstimationEndDate().toString(),
                cut(proposal.getCoverLetter()),
                text(req.notes()));
        return gemini.generate(prompt).replaceAll("\\*\\*?|#+ ?", "").trim();
    }

    /** A contract in plain words for the one about to sign it, and what is worth clarifying first. */
    public Explanation explain(Long contractId, String role) {
        Contract contract = contract(contractId);
        boolean freelancer = !"CLIENT".equalsIgnoreCase(role);
        String prompt = """
                Explain this freelance contract to the %s, who is about to rely on it, in simple words and in the
                language of the terms. Be neutral and factual; you are not a lawyer and give no legal advice.

                Return JSON: {"summary": ["...", "..."], "check": ["...", "..."]}
                - summary: 3 to 5 short sentences: what is delivered, by when, for how much, and how they get paid
                  or refunded.
                - check: 0 to 4 short points that are missing or vague in these terms and worth agreeing on in the
                  chat before signing (for example: what counts as "done", how many revisions). Only real gaps of
                  these terms; an empty list if the terms are clear.

                %s

                CONTRACT
                Project: %s
                Price: %s
                Start date: %s
                Deadline: %s
                Terms: %s
                """.formatted(freelancer ? "freelancer" : "client", HOW_WORKIFY_PAYS,
                text(contract.getProjectTitle()), money(contract.getRate()),
                contract.getStartDate() == null ? "not given" : contract.getStartDate().toString(),
                contract.getDeadline() == null ? "not given" : contract.getDeadline().toString(),
                cut(contract.getTerms()));
        JsonNode json = gemini.generateJson(prompt);
        List<String> summary = strings(json.path("summary"), 5);
        if (summary.isEmpty()) throw new AiUnavailableException("The AI gave an empty answer. Try again.");
        return new Explanation(summary, strings(json.path("check"), 4));
    }

    /** The user's dispute rewritten clearly and factually, with the contract's facts. */
    public String draftDispute(DisputeRequest req) {
        Contract contract = contract(req.contractId());
        String draft = req.text() == null ? "" : req.text().trim();
        if (draft.length() < 10) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Write in a few words what went wrong first.");
        }
        boolean client = "CLIENT".equalsIgnoreCase(req.role());
        String prompt = """
                Rewrite this dispute message from the %s of a Workify contract so a neutral admin understands it fast.
                Same language as the message, first person, calm and factual, no insults, at most 120 words.
                Say what was agreed, what happened, and what they ask for (payment, refund or a split) if they said it.
                Use ONLY the facts in the message and the contract below. Never invent dates, amounts, messages or events.
                Return only the rewritten message.

                Contract: %s, price %s, start %s, deadline %s.
                Their message: %s
                """.formatted(client ? "client" : "freelancer", text(contract.getProjectTitle()),
                money(contract.getRate()),
                contract.getStartDate() == null ? "not given" : contract.getStartDate().toString(),
                contract.getDeadline() == null ? "not given" : contract.getDeadline().toString(),
                draft.length() > MAX_TEXT ? draft.substring(0, MAX_TEXT) : draft);
        String text = gemini.generate(prompt).trim();
        return text.length() > MAX_DISPUTE ? text.substring(0, MAX_DISPUTE) : text;
    }

    private Contract contract(Long id) {
        if (id == null) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "contractId is required");
        return contractRepo.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Contract not found"));
    }

    private static List<String> strings(JsonNode array, int max) {
        List<String> out = new ArrayList<>();
        for (JsonNode n : array) {
            String s = n.asText("").trim();
            if (!s.isEmpty() && out.size() < max) out.add(s);
        }
        return out;
    }

    private static String cut(String s) {
        if (s == null || s.isBlank()) return "not given";
        String t = s.trim();
        return t.length() > MAX_TEXT ? t.substring(0, MAX_TEXT) + "…" : t;
    }

    private static String text(String s) {
        return s == null || s.isBlank() ? "not given" : s.trim();
    }

    private static String money(Double amount) {
        if (amount == null || amount <= 0) return "not given";
        return amount % 1 == 0 ? "$" + amount.longValue() : "$" + amount;
    }
}
