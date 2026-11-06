package org.example.ms_competenceandreview.services;

import org.example.ms_competenceandreview.Entities.Competance;
import org.example.ms_competenceandreview.Repositories.CompetanceRepo;
import org.example.ms_competenceandreview.Services.Impl.CatalogSeeder;
import org.example.ms_competenceandreview.Services.Impl.CompetanceServiceImpl;
import org.example.ms_competenceandreview.Services.Impl.DefaultSkillCatalog;
import org.example.ms_competenceandreview.Services.Impl.SkillExtractorClient;
import org.example.ms_competenceandreview.Services.Impl.SkillExtractorClient.ExtractedSkill;
import org.example.ms_competenceandreview.Services.Impl.SkillExtractorClient.ExtractionResponse;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.mock.web.MockMultipartFile;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/** Les compétences trouvées dans un CV doivent toujours revenir avec un id, pour être enregistrées sur le profil. */
@ExtendWith(MockitoExtension.class)
class CvSkillsCatalogTest {

    @Mock
    private CompetanceRepo competanceRepo;

    @Mock
    private SkillExtractorClient skillExtractorClient;

    @Mock
    private DefaultSkillCatalog defaultSkillCatalog;

    @InjectMocks
    private CompetanceServiceImpl competanceService;

    private final MockMultipartFile cv = new MockMultipartFile("file", "cv.pdf", "application/pdf", "%PDF-1.4".getBytes());

    private static Competance competance(long id, String nom) {
        Competance c = new Competance();
        c.setId(id);
        c.setNom(nom);
        return c;
    }

    @Test
    void emptyCatalog_detectedSkillsAreAddedThenMatchedWithIds() throws Exception {
        // Catalogue vide : l'IA utilise son propre lexique, les compétences n'ont pas d'id.
        ExtractionResponse withoutIds = new ExtractionResponse("en", true, List.of(
                new ExtractedSkill(null, "Java", 0.95, "exact", "Java"),
                new ExtractedSkill(null, "Docker", 0.9, "exact", "Docker")), List.of());
        ExtractionResponse withIds = new ExtractionResponse("en", true, List.of(
                new ExtractedSkill(1L, "Java", 0.95, "exact", "Java"),
                new ExtractedSkill(2L, "Docker", 0.9, "exact", "Docker")), List.of());
        List<Competance> afterAdding = List.of(competance(1, "Java"), competance(2, "Docker"));
        when(competanceRepo.findAll()).thenReturn(List.of(), afterAdding);
        when(competanceRepo.findFirstByNomIgnoreCase(anyString())).thenReturn(Optional.empty());
        when(defaultSkillCatalog.categoryOf("Java")).thenReturn("Programming languages");
        when(skillExtractorClient.extract(any(), eq("cv.pdf"), anyList())).thenReturn(withoutIds, withIds);

        ExtractionResponse result = competanceService.ParseCVDetails(cv);

        ArgumentCaptor<Competance> saved = ArgumentCaptor.forClass(Competance.class);
        verify(competanceRepo, times(2)).save(saved.capture());
        assertEquals(List.of("Java", "Docker"), saved.getAllValues().stream().map(Competance::getNom).toList());
        assertEquals("Programming languages", saved.getAllValues().get(0).getCategorie());
        verify(skillExtractorClient).extract(any(), eq("cv.pdf"), eq(afterAdding));
        assertTrue(result.skills().stream().allMatch(s -> s.id() != null));
    }

    @Test
    void skillsMissingFromCatalog_areAddedOnceEvenWithAnotherCase() throws Exception {
        ExtractionResponse first = new ExtractionResponse("fr", true,
                List.of(new ExtractedSkill(1L, "Java", 0.95, "exact", "Java")), List.of("Kubernetes", "figma"));
        ExtractionResponse second = new ExtractionResponse("fr", true, List.of(
                new ExtractedSkill(1L, "Java", 0.95, "exact", "Java"),
                new ExtractedSkill(3L, "Kubernetes", 0.9, "exact", "Kubernetes"),
                new ExtractedSkill(2L, "Figma", 0.9, "exact", "Figma")), List.of());
        when(competanceRepo.findAll()).thenReturn(new ArrayList<>(List.of(competance(1, "Java"), competance(2, "Figma"))));
        when(competanceRepo.findFirstByNomIgnoreCase("Kubernetes")).thenReturn(Optional.empty());
        when(competanceRepo.findFirstByNomIgnoreCase("figma")).thenReturn(Optional.of(competance(2, "Figma")));
        when(skillExtractorClient.extract(any(), anyString(), anyList())).thenReturn(first, second);

        ExtractionResponse result = competanceService.ParseCVDetails(cv);

        ArgumentCaptor<Competance> saved = ArgumentCaptor.forClass(Competance.class);
        verify(competanceRepo, times(1)).save(saved.capture());
        assertEquals("Kubernetes", saved.getValue().getNom());
        assertEquals(3, result.skills().size());
        assertTrue(result.otherSkills().isEmpty());
    }

    @Test
    void everySkillInCatalog_singleDetectionAndNothingAdded() throws Exception {
        ExtractionResponse found = new ExtractionResponse("en", true,
                List.of(new ExtractedSkill(1L, "Java", 0.95, "exact", "Java")), List.of());
        when(competanceRepo.findAll()).thenReturn(List.of(competance(1, "Java")));
        when(skillExtractorClient.extract(any(), anyString(), anyList())).thenReturn(found);

        assertSame(found, competanceService.ParseCVDetails(cv));
        verify(skillExtractorClient, times(1)).extract(any(), anyString(), anyList());
        verify(competanceRepo, never()).save(any());
    }

    @Test
    void seeder_fillsAnEmptyCatalogOnly() throws Exception {
        DefaultSkillCatalog defaults = new DefaultSkillCatalog();
        assertEquals(144, defaults.entries().size());
        assertEquals("Programming languages", defaults.categoryOf("java"));

        when(competanceRepo.count()).thenReturn(0L);
        new CatalogSeeder(competanceRepo, defaults).run(null);
        @SuppressWarnings("unchecked")
        ArgumentCaptor<List<Competance>> seeded = ArgumentCaptor.forClass(List.class);
        verify(competanceRepo).saveAll(seeded.capture());
        assertEquals(144, seeded.getValue().size());

        reset(competanceRepo);
        when(competanceRepo.count()).thenReturn(144L);
        new CatalogSeeder(competanceRepo, defaults).run(null);
        verify(competanceRepo, never()).saveAll(any());
    }
}
