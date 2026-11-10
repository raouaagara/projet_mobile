package org.example.ms_competenceandreview.Services.Impl;

import com.fasterxml.jackson.databind.JsonNode;
import org.example.ms_competenceandreview.Entities.Competance;
import org.example.ms_competenceandreview.Repositories.CompetanceRepo;
import org.example.ms_competenceandreview.ai.AiUnavailableException;
import org.example.ms_competenceandreview.ai.GeminiClient;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

/**
 * L'IA du module 1 sur le profil (Gemini) :
 * - écrire la bio « À propos » à partir des compétences et des notes du freelancer ;
 * - un plan d'apprentissage pour les compétences demandées par les offres qui lui correspondent presque.
 */
@Service
public class ProfileAiService {

    public record BioRequest(String firstName, String role, String location, List<Long> skillIds, String notes) {}

    /** {@code skills}: what to learn, with how many open jobs ask for it. */
    public record PlanRequest(List<Long> skillIds, List<SkillDemand> skills) {}

    public record SkillDemand(String name, int jobs) {}

    public record PlanItem(String skill, String why, List<String> steps, int weeks) {}

    /** The user's bio column holds 255 characters. */
    static final int MAX_BIO = 250;
    private static final int MAX_PLAN_SKILLS = 3;

    private final GeminiClient gemini;
    private final CompetanceRepo competanceRepo;

    public ProfileAiService(GeminiClient gemini, CompetanceRepo competanceRepo) {
        this.gemini = gemini;
        this.competanceRepo = competanceRepo;
    }

    public String writeBio(BioRequest req) {
        List<String> skills = skillNames(req.skillIds());
        String notes = req.notes() == null ? "" : req.notes().trim();
        if (skills.isEmpty() && notes.length() < 10) {
            throw new IllegalArgumentException("Add your skills or write a few words about you first.");
        }
        boolean client = "CLIENT".equalsIgnoreCase(req.role());
        String prompt = """
                You write the "About me" text of a profile on Workify, a freelance marketplace.
                Write it for this %s, in the language of the notes (English if there are no notes).

                Rules:
                - First person, one short paragraph, at most 220 characters (hard limit).
                - Use ONLY the facts below. Never invent years of experience, past clients, companies,
                  diplomas, numbers or skills that aren't listed.
                - Say what they do and the main skills, warm and professional. No emojis, no hashtags, no quotes.
                - Return only the text.

                First name: %s
                Location: %s
                Skills: %s
                Notes from them (rewrite them, keep their facts): %s
                """.formatted(client ? "client who hires freelancers" : "freelancer",
                orNone(req.firstName()), orNone(req.location()),
                skills.isEmpty() ? "none listed" : String.join(", ", skills), orNone(notes));
        return fit(gemini.generate(prompt).replace("\"", "").trim());
    }

    public List<PlanItem> learningPlan(PlanRequest req) {
        List<SkillDemand> targets = req.skills() == null ? List.of() : req.skills().stream()
                .filter(s -> s.name() != null && !s.name().isBlank())
                .limit(MAX_PLAN_SKILLS)
                .toList();
        if (targets.isEmpty()) throw new IllegalArgumentException("No skill to plan.");
        List<String> mine = skillNames(req.skillIds());
        StringBuilder wanted = new StringBuilder();
        for (SkillDemand s : targets) {
            wanted.append("- ").append(s.name().trim()).append(" (asked in ").append(s.jobs()).append(" open jobs)\n");
        }
        String prompt = """
                You coach freelancers on Workify, a freelance marketplace. The skills below are asked for in
                open jobs that almost fit this freelancer. Make a short, practical learning plan for each one,
                building on what they already know.

                Return JSON: {"plan": [{"skill": "...", "why": "...", "steps": ["...", "...", "..."], "weeks": 2}]}
                - One item per skill, in the same order, with the skill name exactly as given.
                - why: one sentence linking the skill to what they already know or to the jobs.
                - steps: 3 concrete steps, each under 90 characters (learn X, build a small Y, add it to the profile).
                - weeks: realistic number of weeks part-time, 1 to 12.
                - Name official docs or well-known free resources only; no links, no invented courses.

                They already know: %s
                Skills to learn:
                %s""".formatted(mine.isEmpty() ? "nothing listed yet" : String.join(", ", mine), wanted);

        JsonNode plan = gemini.generateJson(prompt).path("plan");
        List<PlanItem> items = new ArrayList<>();
        for (JsonNode item : plan) {
            String skill = item.path("skill").asText("").trim();
            if (skill.isEmpty()) continue;
            List<String> steps = new ArrayList<>();
            for (JsonNode step : item.path("steps")) {
                if (!step.asText("").isBlank() && steps.size() < 4) steps.add(step.asText().trim());
            }
            int weeks = Math.max(1, Math.min(12, item.path("weeks").asInt(4)));
            items.add(new PlanItem(skill, item.path("why").asText("").trim(), steps, weeks));
        }
        if (items.isEmpty()) throw new AiUnavailableException("The AI gave an empty plan. Try again.");
        return items;
    }

    private List<String> skillNames(List<Long> ids) {
        if (ids == null || ids.isEmpty()) return List.of();
        return competanceRepo.findAllById(ids).stream()
                .map(Competance::getNom)
                .filter(Objects::nonNull)
                .map(String::trim)
                .filter(n -> !n.isEmpty())
                .distinct()
                .toList();
    }

    /** Cuts to the column size, at the end of a sentence (or a word) when possible. */
    static String fit(String text) {
        String t = text.replaceAll("\\s+", " ").trim();
        if (t.length() <= MAX_BIO) return t;
        String cut = t.substring(0, MAX_BIO);
        int sentence = Math.max(cut.lastIndexOf(". "), Math.max(cut.lastIndexOf("! "), cut.lastIndexOf("? ")));
        if (sentence > MAX_BIO / 2) return cut.substring(0, sentence + 1);
        int space = cut.lastIndexOf(' ');
        return (space > 0 ? cut.substring(0, space) : cut).replaceAll("[,;:]$", "") + "…";
    }

    private static String orNone(String s) {
        return s == null || s.isBlank() ? "not given" : s.trim();
    }
}
