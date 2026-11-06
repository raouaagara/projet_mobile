package org.example.projectmicroservice.Services;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.example.projectmicroservice.DTO.CompetenceDto;
import org.example.projectmicroservice.Entities.JobType;
import org.example.projectmicroservice.Entities.Project;
import org.example.projectmicroservice.Entities.Status;
import org.example.projectmicroservice.OpenFeign.CompetenceClient;
import org.example.projectmicroservice.Repositories.ProjectRepository;
import org.example.projectmicroservice.Services.ProjectAiService.*;
import org.example.projectmicroservice.ai.AiUnavailableException;
import org.example.projectmicroservice.ai.GeminiClient;
import org.example.projectmicroservice.ai.SkillMatchClient;
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
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class ProjectAiServiceTest {

    @Mock
    private ProjectRepository projectRepo;
    @Mock
    private CompetenceClient competenceClient;
    @Mock
    private SkillMatchClient skillMatch;
    @Mock
    private GeminiClient gemini;

    @InjectMocks
    private ProjectAiService ai;

    private Project flutterJob;
    private Project apiJob;

    @BeforeEach
    void setUp() {
        when(competenceClient.getAll()).thenReturn(List.of(
                new CompetenceDto(1L, "Flutter", "Mobile"),
                new CompetenceDto(2L, "Firebase", "DevOps & Cloud"),
                new CompetenceDto(3L, "Spring Boot", "Backend frameworks")));
        flutterJob = Project.builder().id(10L).title("Restaurant app").description("Flutter app with Firebase")
                .status(Status.OPEN).jobType(JobType.FIXED_PRICE).budget(800.0)
                .requiredCompetenceIds(List.of(1L)).build();
        apiJob = Project.builder().id(11L).title("Inventory API").description("Spring Boot API")
                .status(Status.OPEN).requiredCompetenceIds(List.of(3L)).build();
        Project closed = Project.builder().id(12L).title("Old job").status(Status.CLOSED).build();
        when(projectRepo.findAll()).thenReturn(List.of(flutterJob, apiJob, closed));
        when(projectRepo.findById(10L)).thenReturn(Optional.of(flutterJob));
    }

    @Test
    void matchScoresOpenJobsWithSkillNamesAndSortsBestFirst() {
        when(skillMatch.match(anyList(), anyList())).thenReturn(List.of(
                new SkillMatchClient.Match(10L, 82, List.of("Flutter"), List.of(), List.of()),
                new SkillMatchClient.Match(11L, 5, List.of(), List.of(), List.of("Spring Boot"))));

        List<JobMatch> matches = ai.matchJobs(List.of(1L, 2L, 99L));

        assertEquals(List.of(10L, 11L), matches.stream().map(JobMatch::projectId).toList());
        assertEquals(82, matches.get(0).score());
        @SuppressWarnings("unchecked")
        ArgumentCaptor<List<SkillMatchClient.Job>> jobs = ArgumentCaptor.forClass(List.class);
        verify(skillMatch).match(eq(List.of("Flutter", "Firebase")), jobs.capture()); // unknown id 99 ignored
        assertEquals(2, jobs.getValue().size()); // the closed job isn't scored
        assertEquals(List.of("Flutter"), jobs.getValue().get(0).requiredSkills());
        assertTrue(jobs.getValue().get(0).text().startsWith("Restaurant app. Flutter app"));
    }

    @Test
    void noSkillsMeansNoRecommendations() {
        assertTrue(ai.matchJobs(List.of()).isEmpty());
        verify(skillMatch, never()).match(anyList(), anyList());
    }

    @Test
    void catalogDownGivesAClearMessage() {
        when(competenceClient.getAll()).thenThrow(new RuntimeException("connection refused"));
        AiUnavailableException e = assertThrows(AiUnavailableException.class, () -> ai.matchJobs(List.of(1L)));
        assertTrue(e.getMessage().contains("skills list"));
    }

    @Test
    void candidatesAreRankedForTheProject() {
        when(skillMatch.match(eq(List.of("Spring Boot")), anyList()))
                .thenReturn(List.of(new SkillMatchClient.Match(10L, 10, List.of(), List.of(), List.of("Flutter"))));
        when(skillMatch.match(eq(List.of("Flutter", "Firebase")), anyList()))
                .thenReturn(List.of(new SkillMatchClient.Match(10L, 90, List.of("Flutter", "Firebase"), List.of(), List.of())));

        List<CandidateMatch> ranked = ai.rankCandidates(10L, List.of(
                new Candidate(7L, List.of(3L)), new Candidate(8L, List.of(1L, 2L)), new Candidate(9L, List.of())));

        assertEquals(List.of(8L, 7L, 9L), ranked.stream().map(CandidateMatch::freelancerId).toList());
        assertEquals(0, ranked.get(2).score()); // no skills: no AI call, score 0
    }

    @Test
    void coverLetterPromptHasTheJobAndOnlyTheFreelancersFacts() {
        when(gemini.generate(anyString())).thenReturn("Hello, I build Flutter apps…");

        String letter = ai.draftCoverLetter(new ProposalDraftRequest(10L, "Sara", "Mobile developer", List.of(1L),
                750.0, LocalDate.of(2026, 12, 1), "I can start Monday"));

        assertEquals("Hello, I build Flutter apps…", letter);
        ArgumentCaptor<String> prompt = ArgumentCaptor.forClass(String.class);
        verify(gemini).generate(prompt.capture());
        String p = prompt.getValue();
        assertTrue(p.contains("Restaurant app") && p.contains("Flutter app with Firebase"));
        assertTrue(p.contains("Name: Sara") && p.contains("Price offered: $750") && p.contains("2026-12-01"));
        assertTrue(p.contains("I can start Monday") && p.contains("Never invent"));
    }

    @Test
    void projectDraftKeepsKnownLevelAndSuggestsSureSkills() throws Exception {
        when(gemini.generateJson(anyString())).thenReturn(new ObjectMapper().readTree(
                "{\"title\":\"Flutter ordering app\",\"description\":\"Build a Flutter app.\",\"experienceLevel\":\"Guru\"}"));
        when(skillMatch.skillsIn(anyString(), anyList())).thenReturn(List.of(
                new SkillMatchClient.FoundSkill(1L, "Flutter", 0.9, "exact"),
                new SkillMatchClient.FoundSkill(2L, "Firebase", 0.6, "semantic"), // unsure: not suggested
                new SkillMatchClient.FoundSkill(null, "Dart", 0.9, "exact")));   // not in the catalog

        ProjectDraft draft = ai.draftProject(new ProjectDraftRequest("app for my restaurant", "", null, null, null));

        assertEquals("Flutter ordering app", draft.title());
        assertEquals("Intermediate", draft.experienceLevel()); // unknown level replaced
        assertEquals(List.of(1L), draft.skillIds());
    }

    @Test
    void projectDraftStillWorksWhenSkillsAiIsOffline() throws Exception {
        when(gemini.generateJson(anyString())).thenReturn(new ObjectMapper().readTree(
                "{\"title\":\"Logo\",\"description\":\"A logo.\",\"experienceLevel\":\"Expert\"}"));
        when(skillMatch.skillsIn(anyString(), anyList())).thenThrow(new AiUnavailableException("offline"));

        ProjectDraft draft = ai.draftProject(new ProjectDraftRequest("a logo for my bakery", null, null, null, null));

        assertEquals("Expert", draft.experienceLevel());
        assertTrue(draft.skillIds().isEmpty());
    }

    @Test
    void projectDraftNeedsAFewWords() {
        assertThrows(ResponseStatusException.class,
                () -> ai.draftProject(new ProjectDraftRequest("app", "", null, null, null)));
        verifyNoInteractions(gemini);
    }
}
