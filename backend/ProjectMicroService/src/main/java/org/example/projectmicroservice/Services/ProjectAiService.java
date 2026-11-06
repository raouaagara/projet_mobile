package org.example.projectmicroservice.Services;

import com.fasterxml.jackson.databind.JsonNode;
import org.example.projectmicroservice.DTO.CompetenceDto;
import org.example.projectmicroservice.Entities.JobType;
import org.example.projectmicroservice.Entities.Project;
import org.example.projectmicroservice.Entities.ProjectCategory;
import org.example.projectmicroservice.Entities.Status;
import org.example.projectmicroservice.OpenFeign.CompetenceClient;
import org.example.projectmicroservice.Repositories.ProjectRepository;
import org.example.projectmicroservice.ai.AiUnavailableException;
import org.example.projectmicroservice.ai.GeminiClient;
import org.example.projectmicroservice.ai.SkillMatchClient;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.stream.IntStream;

/**
 * L'IA du module 2 :
 * - score de correspondance entre les compétences d'un freelancer et les offres (modèle multilingue du service Python) ;
 * - rédaction de la lettre de motivation d'une proposition et de l'annonce d'un projet (Gemini).
 */
@Service
public class ProjectAiService {

    public record JobMatch(Long projectId, int score, List<String> matched, List<String> related, List<String> missing) {}

    public record Candidate(Long freelancerId, List<Long> skillIds) {}

    public record CandidateMatch(Long freelancerId, int score, List<String> matched, List<String> related,
                                 List<String> missing) {}

    public record ProposalDraftRequest(Long projectId, String freelancerName, String bio, List<Long> skillIds,
                                       Double bidAmount, LocalDate estimationEndDate, String notes) {}

    public record ProjectDraftRequest(String idea, String title, ProjectCategory category, JobType jobType,
                                      Double budget) {}

    public record ProjectDraft(String title, String description, String experienceLevel, List<Long> skillIds) {}

    static final List<String> EXPERIENCE_LEVELS = List.of("Entry Level", "Intermediate", "Expert");
    private static final int MAX_DESCRIPTION = 3000;
    private static final int MAX_SUGGESTED_SKILLS = 8;
    private static final double SURE_SKILL = 0.75;

    private final ProjectRepository projectRepo;
    private final CompetenceClient competenceClient;
    private final SkillMatchClient skillMatch;
    private final GeminiClient gemini;

    public ProjectAiService(ProjectRepository projectRepo, CompetenceClient competenceClient,
                            SkillMatchClient skillMatch, GeminiClient gemini) {
        this.projectRepo = projectRepo;
        this.competenceClient = competenceClient;
        this.skillMatch = skillMatch;
        this.gemini = gemini;
    }

    // ── Match score ──────────────────────────────────────────────────

    /** Open projects scored for a freelancer, best first. Empty when the freelancer has no skills yet. */
    public List<JobMatch> matchJobs(List<Long> skillIds) {
        Map<Long, String> names = skillNames();
        List<String> profile = namesOf(skillIds, names);
        List<Project> open = projectRepo.findAll().stream()
                .filter(p -> p.getStatus() == null || p.getStatus() == Status.OPEN)
                .toList();
        if (profile.isEmpty() || open.isEmpty()) return List.of();

        List<SkillMatchClient.Match> scores = skillMatch.match(profile, open.stream().map(p -> job(p, names)).toList());
        return IntStream.range(0, Math.min(open.size(), scores.size()))
                .mapToObj(i -> {
                    SkillMatchClient.Match m = scores.get(i);
                    return new JobMatch(open.get(i).getId(), m.score(), m.matched(), m.related(), m.missing());
                })
                .sorted(Comparator.comparingInt(JobMatch::score).reversed())
                .toList();
    }

    /** How well each freelancer who applied fits a project, best first (for the client). */
    public List<CandidateMatch> rankCandidates(Long projectId, List<Candidate> candidates) {
        Project project = project(projectId);
        if (candidates == null || candidates.isEmpty()) return List.of();
        Map<Long, String> names = skillNames();
        SkillMatchClient.Job job = job(project, names);
        List<CandidateMatch> out = new ArrayList<>();
        for (Candidate c : candidates) {
            List<String> profile = namesOf(c.skillIds(), names);
            if (profile.isEmpty()) {
                out.add(new CandidateMatch(c.freelancerId(), 0, List.of(), List.of(), List.of()));
                continue;
            }
            SkillMatchClient.Match m = skillMatch.match(profile, List.of(job)).get(0);
            out.add(new CandidateMatch(c.freelancerId(), m.score(), m.matched(), m.related(), m.missing()));
        }
        out.sort(Comparator.comparingInt(CandidateMatch::score).reversed());
        return out;
    }

    // ── Writing with Gemini ──────────────────────────────────────────

    /** Cover letter of a proposal, from the job and what the freelancer gave. */
    public String draftCoverLetter(ProposalDraftRequest req) {
        Project project = project(req.projectId());
        Map<Long, String> names = skillNamesOrEmpty();
        String prompt = """
                You write cover letters for freelancers who apply to jobs on Workify, a freelance marketplace.
                Write the cover letter of this freelancer's proposal, in the language the job is written in.

                Rules:
                - 80 to 150 words, 2 or 3 short paragraphs, first person, warm and professional.
                - Plain text: no title, no subject line, no markdown, no placeholders such as [Name].
                - Use ONLY the facts below. Never invent experience, past clients, numbers, links or certificates.
                - Show how the freelancer's skills fit what the job needs. Don't claim skills that aren't listed.
                - If a price or a delivery date is given, mention them once near the end.
                - End with one sentence inviting the client to talk, then the freelancer's first name if given.
                - Return only the letter.

                JOB
                Title: %s
                Description: %s
                Required skills: %s
                Type: %s
                Budget: %s

                FREELANCER
                Name: %s
                Skills: %s
                About: %s
                Price offered: %s
                Delivery date: %s
                Notes from the freelancer (use them): %s
                """.formatted(
                text(project.getTitle()),
                cut(project.getDescription()),
                orNone(String.join(", ", namesOf(project.getRequiredCompetenceIds(), names))),
                project.getJobType() == JobType.HOURLY ? "hourly" : "fixed price",
                money(project.getBudget()),
                text(req.freelancerName()),
                orNone(String.join(", ", namesOf(req.skillIds(), names))),
                text(req.bio()),
                req.bidAmount() == null ? "not given"
                        : money(req.bidAmount()) + (project.getJobType() == JobType.HOURLY ? " per hour" : ""),
                req.estimationEndDate() == null ? "not given" : req.estimationEndDate().toString(),
                text(req.notes()));
        return gemini.generate(prompt);
    }

    /** A clear job post from the client's few words, with the skills our model finds in it. */
    public ProjectDraft draftProject(ProjectDraftRequest req) {
        String idea = req.idea() == null ? "" : req.idea().trim();
        String title = req.title() == null ? "" : req.title().trim();
        if (idea.length() + title.length() < 10) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Write a few words about your project first.");
        }
        String prompt = """
                You help clients post jobs on Workify, a freelance marketplace.
                From the client's notes, write a clear job post, in the language of the notes.

                Return JSON: {"title": "...", "description": "...", "experienceLevel": "..."}
                - title: at most 70 characters, says what needs to be built or done.
                - description: 100 to 200 words of plain text (no markdown, no # or *). Short parts separated by
                  a blank line: the goal in one or two sentences; what needs to be done, one task per line starting
                  with "• "; what the client expects to receive.
                - experienceLevel: exactly one of "Entry Level", "Intermediate", "Expert".
                Rules: use ONLY what the notes say, plus the usual tasks of that kind of work. Never invent a company
                name, figures, dates, a deadline or tools/technologies the client didn't name. Don't write the budget.

                Client's notes
                Title: %s
                Idea: %s
                Category: %s
                Type: %s
                """.formatted(orNone(title), orNone(idea),
                req.category() == null ? "not given" : req.category().name().replace('_', ' ').toLowerCase(),
                req.jobType() == JobType.HOURLY ? "hourly" : req.jobType() == null ? "not given" : "fixed price");

        JsonNode json = gemini.generateJson(prompt);
        String description = json.path("description").asText("").trim();
        if (description.isEmpty()) throw new AiUnavailableException("The AI gave an empty answer. Try again.");
        String newTitle = json.path("title").asText("").trim();
        if (newTitle.isEmpty()) newTitle = title;
        String level = json.path("experienceLevel").asText("");
        if (!EXPERIENCE_LEVELS.contains(level)) level = "Intermediate";
        return new ProjectDraft(newTitle, description, level, suggestedSkills(newTitle + "\n" + description));
    }

    /** Catalog skills found in a job post; none if the skills AI is offline (the post is still useful). */
    private List<Long> suggestedSkills(String text) {
        try {
            List<SkillMatchClient.CatalogSkill> catalog = competenceClient.getAll().stream()
                    .filter(c -> c.id() != null && c.nom() != null && !c.nom().isBlank())
                    .map(c -> new SkillMatchClient.CatalogSkill(c.id(), c.nom()))
                    .toList();
            return skillMatch.skillsIn(text, catalog).stream()
                    .filter(s -> s.id() != null && (!"semantic".equals(s.method()) || s.confidence() >= SURE_SKILL))
                    .map(SkillMatchClient.FoundSkill::id)
                    .distinct()
                    .limit(MAX_SUGGESTED_SKILLS)
                    .toList();
        } catch (Exception e) {
            System.err.println("⚠️ [PROJECT-AI] skills not suggested: " + e.getMessage());
            return List.of();
        }
    }

    // ── Helpers ──────────────────────────────────────────────────────

    private Project project(Long id) {
        if (id == null) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "projectId is required");
        return projectRepo.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Project not found"));
    }

    private SkillMatchClient.Job job(Project p, Map<Long, String> names) {
        String text = text(p.getTitle()) + ". " + (p.getDescription() == null ? "" : cut(p.getDescription()));
        return new SkillMatchClient.Job(p.getId(), text, namesOf(p.getRequiredCompetenceIds(), names));
    }

    /** id → name of every catalog skill. */
    private Map<Long, String> skillNames() {
        try {
            Map<Long, String> names = new LinkedHashMap<>();
            for (CompetenceDto c : competenceClient.getAll()) {
                if (c.id() != null && c.nom() != null && !c.nom().isBlank()) names.put(c.id(), c.nom().trim());
            }
            return names;
        } catch (Exception e) {
            System.err.println("⚠️ [PROJECT-AI] skills catalog unavailable: " + e.getMessage());
            throw new AiUnavailableException("Couldn't load the skills list. Try again in a moment.");
        }
    }

    private Map<Long, String> skillNamesOrEmpty() {
        try {
            return skillNames();
        } catch (AiUnavailableException e) {
            return Map.of();
        }
    }

    private static List<String> namesOf(List<Long> ids, Map<Long, String> names) {
        if (ids == null) return List.of();
        return ids.stream().map(names::get).filter(Objects::nonNull).distinct().toList();
    }

    private static String cut(String s) {
        if (s == null || s.isBlank()) return "not given";
        String t = s.trim();
        return t.length() > MAX_DESCRIPTION ? t.substring(0, MAX_DESCRIPTION) + "…" : t;
    }

    private static String text(String s) {
        return s == null || s.isBlank() ? "not given" : s.trim();
    }

    private static String orNone(String s) {
        return s == null || s.isBlank() ? "not given" : s;
    }

    private static String money(Double amount) {
        if (amount == null || amount <= 0) return "not given";
        return amount % 1 == 0 ? "$" + amount.longValue() : "$" + amount;
    }
}
