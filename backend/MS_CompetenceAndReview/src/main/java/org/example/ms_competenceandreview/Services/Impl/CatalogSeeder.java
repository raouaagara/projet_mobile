package org.example.ms_competenceandreview.Services.Impl;

import org.example.ms_competenceandreview.Entities.Competance;
import org.example.ms_competenceandreview.Repositories.CompetanceRepo;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.util.List;

/**
 * Remplit le catalogue de compétences au premier démarrage (base vide : Docker, Codespaces...).
 * Sans catalogue, l'utilisateur n'a rien à choisir et les compétences trouvées dans un CV n'ont pas d'id,
 * donc elles ne peuvent pas être enregistrées sur son profil.
 */
@Component
public class CatalogSeeder implements ApplicationRunner {

    private final CompetanceRepo competanceRepo;
    private final DefaultSkillCatalog defaultCatalog;

    public CatalogSeeder(CompetanceRepo competanceRepo, DefaultSkillCatalog defaultCatalog) {
        this.competanceRepo = competanceRepo;
        this.defaultCatalog = defaultCatalog;
    }

    @Override
    public void run(ApplicationArguments args) {
        if (competanceRepo.count() > 0) return;
        LocalDateTime now = LocalDateTime.now();
        List<Competance> skills = defaultCatalog.entries().stream().map(entry -> {
            Competance c = new Competance();
            c.setNom(entry.name());
            c.setCategorie(entry.category());
            c.setDateCreation(now);
            return c;
        }).toList();
        competanceRepo.saveAll(skills);
        System.out.println("✅ [CATALOGUE] Base vide : " + skills.size() + " compétences ajoutées.");
    }
}
