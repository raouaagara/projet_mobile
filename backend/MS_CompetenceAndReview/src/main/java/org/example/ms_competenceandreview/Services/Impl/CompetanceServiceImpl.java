package org.example.ms_competenceandreview.Services.Impl;

import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.text.PDFTextStripper;
import org.example.ms_competenceandreview.Entities.Competance;
import org.example.ms_competenceandreview.Repositories.CompetanceRepo;
import org.example.ms_competenceandreview.Services.Interface.CompetanceService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.text.Normalizer;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Service
public class CompetanceServiceImpl implements CompetanceService {
    @Autowired
    CompetanceRepo  competanceRepo;

    @Override
    public Competance AjouterCompetance(Competance competance) {
        System.out.println("   -> [SERVICE] Tentative de sauvegarde dans MySQL...");
        try {
            Competance result = competanceRepo.save(competance);
            System.out.println("   -> [SERVICE] Sauvegarde MySQL réussie avec ID : " + result.getId());
            return result;
        } catch (Exception e) {
            System.err.println("   -> [SERVICE-CRASH] MySQL a refusé la sauvegarde !");
            throw e; // On renvoie l'erreur au contrôleur
        }
    }

    @Override
    public List<Competance> GetAllCompetance() {
        System.out.println("   -> [SERVICE] Lecture de la table MySQL...");
        try {
            return competanceRepo.findAll();
        } catch (Exception e) {
            System.err.println("   -> [SERVICE-CRASH] MySQL a refusé la lecture !");
            throw e;
        }
    }
    @Override
    public Competance ModifierCompetance(Competance competance) {
        return competanceRepo.save(competance);
    }

    @Override

    public void SupprimerCompetance(Long id) {
        competanceRepo.deleteById(id);
    }

    @Override
    public Competance GetCompetance(Long id) {
        return competanceRepo.findById(id).orElseThrow();
    }


    @Autowired
    SkillExtractorClient skillExtractorClient;

    @Autowired
    DefaultSkillCatalog defaultSkillCatalog;

    @Override
    public List<Competance> ParseCVAndMatchSkills(MultipartFile file) {
        Map<Long, Competance> catalogById = new HashMap<>();
        competanceRepo.findAll().forEach(c -> catalogById.put(c.getId(), c));
        List<Competance> matchedSkills = new ArrayList<>();
        for (SkillExtractorClient.ExtractedSkill skill : ParseCVDetails(file).skills()) {
            Competance c = skill.id() == null ? null : catalogById.get(skill.id());
            if (c != null) matchedSkills.add(c); // déjà trié par confiance
        }
        return matchedSkills;
    }

    /**
     * Compétences du catalogue trouvées dans le CV (FR ou EN), avec confiance et extrait du CV.
     * Utilise le service d'IA SkillExtractorAI ; s'il est indisponible, recherche par mots-clés.
     */
    @Override
    public SkillExtractorClient.ExtractionResponse ParseCVDetails(MultipartFile file) {
        List<Competance> catalog = competanceRepo.findAll();
        byte[] pdf;
        try {
            pdf = file.getBytes();
        } catch (Exception e) {
            System.err.println("Erreur lors de la lecture du fichier : " + e.getMessage());
            return new SkillExtractorClient.ExtractionResponse("unknown", false, List.of(), List.of());
        }
        try {
            SkillExtractorClient.ExtractionResponse result =
                    skillExtractorClient.extract(pdf, file.getOriginalFilename(), catalog);
            // Une compétence trouvée mais absente du catalogue n'a pas d'id : elle ne pourrait pas être
            // enregistrée sur le profil. On l'ajoute au catalogue puis on relance la détection pour avoir les ids.
            if (addMissingSkills(result)) {
                result = skillExtractorClient.extract(pdf, file.getOriginalFilename(), competanceRepo.findAll());
            }
            return result;
        } catch (Exception e) {
            System.err.println("⚠️ [CV] Service IA indisponible, recherche par mots-clés : " + e.getMessage());
            return keywordMatch(pdf, competanceRepo.findAll());
        }
    }

    /**
     * Ajoute au catalogue les compétences du CV qui n'y sont pas encore (sans id, ou listées dans otherSkills).
     * Ce sont des compétences du lexique de l'IA, jamais du texte libre. Renvoie true s'il faut relancer la détection.
     */
    private boolean addMissingSkills(SkillExtractorClient.ExtractionResponse result) {
        Set<String> names = new LinkedHashSet<>();
        if (result.otherSkills() != null) names.addAll(result.otherSkills());
        if (result.skills() != null) {
            for (SkillExtractorClient.ExtractedSkill skill : result.skills()) {
                if (skill.id() == null && skill.name() != null) names.add(skill.name());
            }
        }
        names.removeIf(String::isBlank);
        for (String name : names) {
            if (competanceRepo.findFirstByNomIgnoreCase(name).isPresent()) continue;
            Competance competance = new Competance();
            competance.setNom(name);
            competance.setCategorie(defaultSkillCatalog.categoryOf(name));
            competance.setDateCreation(LocalDateTime.now());
            competanceRepo.save(competance);
            System.out.println("➕ [CV] Compétence ajoutée au catalogue : " + name);
        }
        return !names.isEmpty();
    }

    /** Solution de secours : mots entiers, sans accents ("Java" ne correspond pas à "JavaScript"). */
    private SkillExtractorClient.ExtractionResponse keywordMatch(byte[] pdf, List<Competance> catalog) {
        String text;
        try (PDDocument document = PDDocument.load(pdf)) {
            text = fold(new PDFTextStripper().getText(document));
        } catch (Exception e) {
            System.err.println("Erreur lors de la lecture du PDF : " + e.getMessage());
            return new SkillExtractorClient.ExtractionResponse("unknown", false, List.of(), List.of());
        }
        List<SkillExtractorClient.ExtractedSkill> skills = new ArrayList<>();
        for (Competance c : catalog) {
            String name = c.getNom() == null ? "" : fold(c.getNom()).trim();
            if (name.length() < 3) continue; // "C", "R", "Go" : trop ambigus sans l'IA
            Matcher m = Pattern.compile("(?<![a-z0-9+#])" + Pattern.quote(name) + "(?![a-z0-9+#])").matcher(text);
            if (m.find()) {
                skills.add(new SkillExtractorClient.ExtractedSkill(c.getId(), c.getNom(), 0.7, "keyword", m.group()));
            }
        }
        return new SkillExtractorClient.ExtractionResponse("unknown", false, skills, List.of());
    }

    private static String fold(String s) {
        return Normalizer.normalize(s, Normalizer.Form.NFD).replaceAll("\\p{M}", "").toLowerCase();
    }
}
