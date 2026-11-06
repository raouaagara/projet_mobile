package org.example.ms_competenceandreview.Controllers;

import org.example.ms_competenceandreview.Services.Impl.ProfileAiService;
import org.example.ms_competenceandreview.Services.Impl.ProfileAiService.BioRequest;
import org.example.ms_competenceandreview.Services.Impl.ProfileAiService.PlanItem;
import org.example.ms_competenceandreview.Services.Impl.ProfileAiService.PlanRequest;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Map;

/** IA du profil (module 1) : bio « À propos » et plan d'apprentissage. */
@RestController
@RequestMapping("/Competance/ai")
public class ProfileAiController {

    private final ProfileAiService ai;

    public ProfileAiController(ProfileAiService ai) {
        this.ai = ai;
    }

    @PostMapping("/bio")
    public Map<String, String> bio(@RequestBody BioRequest request) {
        try {
            return Map.of("bio", ai.writeBio(request));
        } catch (IllegalArgumentException e) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, e.getMessage());
        }
    }

    @PostMapping("/learning-plan")
    public Map<String, List<PlanItem>> learningPlan(@RequestBody PlanRequest request) {
        try {
            return Map.of("plan", ai.learningPlan(request));
        } catch (IllegalArgumentException e) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, e.getMessage());
        }
    }
}
