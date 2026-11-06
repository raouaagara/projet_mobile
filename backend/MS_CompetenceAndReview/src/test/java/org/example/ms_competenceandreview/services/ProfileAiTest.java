package org.example.ms_competenceandreview.services;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.example.ms_competenceandreview.Entities.Competance;
import org.example.ms_competenceandreview.Repositories.CompetanceRepo;
import org.example.ms_competenceandreview.Services.Impl.ProfileAiService;
import org.example.ms_competenceandreview.Services.Impl.ProfileAiService.*;
import org.example.ms_competenceandreview.ai.AiUnavailableException;
import org.example.ms_competenceandreview.ai.GeminiClient;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.Mockito.*;

/** Bio writer and learning plan, with a fake Gemini (no network). */
class ProfileAiTest {

    private String lastPrompt;

    private GeminiClient answering(String answer) {
        return new GeminiClient("test-key", "test-model") {
            @Override
            public String generate(String prompt) {
                lastPrompt = prompt;
                return answer;
            }

            @Override
            public JsonNode generateJson(String prompt) {
                lastPrompt = prompt;
                try {
                    return new ObjectMapper().readTree(answer);
                } catch (Exception e) {
                    throw new IllegalStateException(e);
                }
            }
        };
    }

    private static CompetanceRepo repo() {
        CompetanceRepo repo = mock(CompetanceRepo.class);
        Competance flutter = new Competance();
        flutter.setNom("Flutter");
        Competance firebase = new Competance();
        firebase.setNom("Firebase");
        when(repo.findAllById(anyList())).thenReturn(List.of(flutter, firebase));
        return repo;
    }

    @Test
    void bioUsesSkillsAndNotesAndFitsTheColumn() {
        ProfileAiService ai = new ProfileAiService(answering("\"I build mobile apps with Flutter and Firebase.\""), repo());

        String bio = ai.writeBio(new BioRequest("Sara", "FREELANCER", "Tunis", List.of(1L, 2L), "3 apps on the Play Store"));

        assertEquals("I build mobile apps with Flutter and Firebase.", bio); // quotes removed
        assertTrue(lastPrompt.contains("Flutter, Firebase") && lastPrompt.contains("3 apps on the Play Store"));
        assertTrue(lastPrompt.contains("Never invent"));
    }

    @Test
    void longBioIsCutAtASentence() {
        String first = "I build mobile apps with Flutter and Firebase for restaurants, shops and startups in Tunisia. ";
        String answer = first + first + "And this last sentence would not fit in the profile anymore at all.";
        String bio = new ProfileAiService(answering(answer), repo())
                .writeBio(new BioRequest("Sara", "FREELANCER", null, List.of(1L), null));

        assertTrue(bio.length() <= 250, bio.length() + "");
        assertTrue(bio.endsWith("."));
    }

    @Test
    void bioNeedsSkillsOrNotes() {
        CompetanceRepo empty = mock(CompetanceRepo.class);
        assertThrows(IllegalArgumentException.class, () -> new ProfileAiService(answering("x"), empty)
                .writeBio(new BioRequest("Sara", "FREELANCER", null, List.of(), "hi")));
    }

    @Test
    void learningPlanIsParsedAndBounded() {
        String answer = """
                {"plan": [
                  {"skill": "Angular", "why": "Asked with Flutter apps.", "steps": ["a", "b", "c", "d", "e"], "weeks": 40},
                  {"skill": "", "why": "skipped"},
                  {"skill": "Docker", "why": "Deploy your APIs.", "steps": ["x"], "weeks": 0}
                ]}""";
        ProfileAiService ai = new ProfileAiService(answering(answer), repo());

        List<PlanItem> plan = ai.learningPlan(new PlanRequest(List.of(1L),
                List.of(new SkillDemand("Angular", 3), new SkillDemand("Docker", 2))));

        assertEquals(List.of("Angular", "Docker"), plan.stream().map(PlanItem::skill).toList());
        assertEquals(4, plan.get(0).steps().size());
        assertEquals(12, plan.get(0).weeks());
        assertEquals(1, plan.get(1).weeks());
        assertTrue(lastPrompt.contains("Angular (asked in 3 open jobs)") && lastPrompt.contains("Flutter, Firebase"));
    }

    @Test
    void emptyPlanGivesAClearMessage() {
        ProfileAiService ai = new ProfileAiService(answering("{\"plan\": []}"), repo());
        assertThrows(AiUnavailableException.class,
                () -> ai.learningPlan(new PlanRequest(List.of(), List.of(new SkillDemand("Angular", 1)))));
    }
}
