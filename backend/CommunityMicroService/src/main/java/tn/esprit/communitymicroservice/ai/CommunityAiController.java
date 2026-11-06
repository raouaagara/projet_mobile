package tn.esprit.communitymicroservice.ai;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;
import tn.esprit.communitymicroservice.ai.CommunityAi.Pick;
import tn.esprit.communitymicroservice.ai.CommunityAi.PostDraftRequest;
import tn.esprit.communitymicroservice.ai.CommunityAi.Profile;

import java.util.List;
import java.util.Map;

/** IA du module 6, sous des chemins que la passerelle route déjà vers ce service. */
@RestController
public class CommunityAiController {

    private final CommunityAi ai;

    public CommunityAiController(CommunityAi ai) {
        this.ai = ai;
    }

    @PostMapping("/api/groups/ai/recommend")
    public Map<String, List<Pick>> recommend(@RequestBody Profile profile) {
        return Map.of("picks", ai.recommend(profile));
    }

    @PostMapping("/api/posts/ai/draft")
    public Map<String, String> draft(@RequestBody PostDraftRequest request) {
        try {
            return Map.of("text", ai.draftPost(request));
        } catch (IllegalArgumentException e) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, e.getMessage());
        }
    }
}
