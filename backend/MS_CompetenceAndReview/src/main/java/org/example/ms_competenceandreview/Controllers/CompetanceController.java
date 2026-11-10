package org.example.ms_competenceandreview.Controllers;

import org.example.ms_competenceandreview.Services.Impl.SkillExtractorClient;
import org.example.ms_competenceandreview.Entities.Competance;
import org.example.ms_competenceandreview.Services.Interface.CompetanceService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.net.MalformedURLException;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;

@RestController
@RequestMapping("/Competance")
public class CompetanceController {

    @GetMapping("/download/{filename:.+}")
    public ResponseEntity<Resource> downloadFile(@PathVariable String filename) {
        try {
            // ⚠️ Assure-toi que ce dossier "uploads" existe à la racine de ton projet Java
            Path filePath = Paths.get("uploads").resolve(filename).normalize();
            Resource resource = new UrlResource(filePath.toUri());

            if (resource.exists() || resource.isReadable()) {
                return ResponseEntity.ok()
                        .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + resource.getFilename() + "\"")
                        .body(resource);
            } else {
                throw new RuntimeException("Fichier introuvable : " + filename);
            }
        } catch (MalformedURLException e) {
            throw new RuntimeException("Erreur : " + e.getMessage());
        }
    }

    /** Détail de l'extraction (langue, confiance, extrait du CV) : utile pour afficher pourquoi une compétence a été trouvée. */
    @PostMapping("/ParseCV/details")
    public SkillExtractorClient.ExtractionResponse ParseCVDetails(@RequestParam("file") MultipartFile file) {
        return competanceService.ParseCVDetails(file);
    }

    @PostMapping("/ParseCV")
    public List<Competance> ParseCV(@RequestParam("file") MultipartFile file) {
        return competanceService.ParseCVAndMatchSkills(file);
    }

    @Autowired
    private final CompetanceService competanceService;

    public CompetanceController(CompetanceService competanceService) {
        this.competanceService = competanceService;
    }

    @PostMapping("/AjouterCompetance")
    public ResponseEntity<?> AjouterCompetance(@RequestBody Competance a) {
        System.out.println("\n=========================================");
        System.out.println("🚨 [CONTROLLER] Requête reçue : /AjouterCompetance");
        System.out.println("🚨 [CONTROLLER] Données reçues d'Angular : " + a.toString());

        try {
            Competance saved = competanceService.AjouterCompetance(a);
            System.out.println("✅ [CONTROLLER] Succès ! Compétence ajoutée.");
            System.out.println("=========================================\n");
            return ResponseEntity.ok(saved);

        } catch (Exception e) {
            System.err.println("❌ [CONTROLLER-CRASH] Erreur lors de l'ajout : " + e.getMessage());
            e.printStackTrace(); // Affiche la grosse erreur rouge dans IntelliJ
            System.err.println("=========================================\n");
            // On renvoie l'erreur en texte à Angular !
            return ResponseEntity.internalServerError().body("ERREUR BACKEND : " + e.getMessage());
        }
    }

    @GetMapping("/GetAllCompetance")
    public ResponseEntity<?> GetAllCompetance() {
        System.out.println("\n=========================================");
        System.out.println("🚨 [CONTROLLER] Requête reçue : /GetAllCompetance");

        try {
            List<Competance> list = competanceService.GetAllCompetance();
            System.out.println("✅ [CONTROLLER] Succès ! Nombre de compétences : " + list.size());
            System.out.println("=========================================\n");
            return ResponseEntity.ok(list);

        } catch (Exception e) {
            System.err.println("❌ [CONTROLLER-CRASH] Erreur lors de la récupération : " + e.getMessage());
            e.printStackTrace();
            System.err.println("=========================================\n");
            return ResponseEntity.internalServerError().body("ERREUR BACKEND : " + e.getMessage());
        }
    }

    @PutMapping("/ModifierCompetance") // Changed to PutMapping for updates
    public Competance ModifierCompetance(@RequestBody Competance a) {
        return competanceService.ModifierCompetance(a);
    }

    @DeleteMapping("/SupprimerCompetance/{id}")
    public void SupprimerCompetance(@PathVariable Long id) {
        competanceService.SupprimerCompetance(id);
    }

    @GetMapping("/GetCompetance/{id}")
    public Competance GetCompetance(@PathVariable Long id) {
        return competanceService.GetCompetance(id);
    }
}


