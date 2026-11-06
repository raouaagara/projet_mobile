package org.example.projectmicroservice.Controllers;

import org.example.projectmicroservice.Services.ProjectAiService;
import org.example.projectmicroservice.Services.ProjectAiService.Candidate;
import org.example.projectmicroservice.Services.ProjectAiService.CandidateMatch;
import org.example.projectmicroservice.Services.ProjectAiService.JobMatch;
import org.example.projectmicroservice.Services.ProjectAiService.ProjectDraft;
import org.example.projectmicroservice.Services.ProjectAiService.ProjectDraftRequest;
import org.example.projectmicroservice.Services.ProjectAiService.ProposalDraftRequest;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/** IA du module 2 : score de correspondance, lettre de motivation, annonce de projet. */
@RestController
@RequestMapping("/Project/ai")
public class ProjectAiController {

    public record MatchRequest(List<Long> skillIds) {}

    public record CandidatesRequest(List<Candidate> candidates) {}

    private final ProjectAiService ai;

    public ProjectAiController(ProjectAiService ai) {
        this.ai = ai;
    }

    /** Open projects scored for the freelancer's skills, best first. */
    @PostMapping("/match")
    public List<JobMatch> match(@RequestBody MatchRequest request) {
        return ai.matchJobs(request.skillIds());
    }

    /** The freelancers who applied to a project, scored for it, best first. */
    @PostMapping("/{projectId}/candidates")
    public List<CandidateMatch> candidates(@PathVariable Long projectId, @RequestBody CandidatesRequest request) {
        return ai.rankCandidates(projectId, request.candidates());
    }

    @PostMapping("/proposal-draft")
    public Map<String, String> proposalDraft(@RequestBody ProposalDraftRequest request) {
        return Map.of("coverLetter", ai.draftCoverLetter(request));
    }

    @PostMapping("/describe")
    public ProjectDraft describe(@RequestBody ProjectDraftRequest request) {
        return ai.draftProject(request);
    }
}
